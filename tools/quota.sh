#!/bin/sh
# Méthode maître agent : lit le quota dans ~/.claude/maitre-agent/usage.json (écrit par la barre d'état
# ou par une copie de ce fichier) et conclut le palier, pour que le modèle n'ait pas à calculer.
# Usage : sh quota.sh [seuil1 seuil2 seuil3]
#   Sans argument, les seuils sont ceux du réglage `seuils` (ligne « - seuils : 60 75 85 » de la rubrique
#   « ## Réglages » du profil, surchargée par « ## Réglages du projet » du CLAUDE.md du dossier courant ou de
#   MAITRE_AGENT_PROJECT_DIR) ; absent ou invalide : 70 80 90. Voir skills/maitre-agent/reglages.md.
# Sortie : une ligne par fenêtre utilisable, par exemple
#   5h 62 % reset 14:20, mesuré il y a 3 min, palier 0
# Code de sortie :
#   0               tous les paliers à 0 (sous le premier seuil)
#   seuil atteint   le plus haut seuil atteint par une fenêtre (70, 80 ou 90 par défaut ; 1er, 2e ou 3e seuil réglé)
#   2               aucune mesure utilisable : fichier absent, jq absent, mesure de plus de 15 min,
#                   ou fenêtre déjà terminée (resets_at dans le passé). Le modèle ne doit alors
#                   inventer aucun pourcentage : il demande à l'utilisateur.
# Variables pour les tests : QUOTA_NOW (secondes epoch à la place de l'heure actuelle),
#   QUOTA_FILE (autre fichier que ~/.claude/maitre-agent/usage.json).
# Lecture seule : ne modifie rien, aucun appel réseau.
f="${QUOTA_FILE:-$HOME/.claude/maitre-agent/usage.json}"
BASE="$HOME/.claude/maitre-agent"
PROJ="${MAITRE_AGENT_PROJECT_DIR:-$PWD}"
rg() { # $1 fichier  $2 titre de la rubrique  $3 clé -> valeur (sans commentaire entre parenthèses)
  [ -f "$1" ] || return 0
  awk -v t="$2" -v k="$3" '
    /^#+[ \t]/ { if ($0 ~ /^##[ \t]/) { s = $0; sub(/^##[ \t]+/, "", s); sub(/[ \t\r]+$/, "", s); on = (s == t) } else if ($0 ~ /^#[ \t]/) on = 0; next }
    on && /^[ \t]*[-*][ \t]+/ { l = $0; sub(/^[ \t]*[-*][ \t]+/, "", l); i = index(l, ":")
      if (i > 1) { n = substr(l, 1, i - 1); gsub(/[ \t*`]+/, "", n)
        if (tolower(n) == k) { v = substr(l, i + 1); sub(/^[ \t*`]+/, "", v); sub(/[ \t\r*`]+$/, "", v); sub(/[ \t]*\(.*\)$/, "", v); print v; exit } } }' "$1" 2>/dev/null
}
ok_seuils() { set -- $1; [ "$#" -eq 3 ] || return 1; for x in "$1" "$2" "$3"; do case "$x" in ""|*[!0-9]*) return 1 ;; esac; done
  [ "$1" -ge 10 ] && [ "$1" -lt "$2" ] && [ "$2" -lt "$3" ] && [ "$3" -le 99 ]; }
if [ "$#" -eq 0 ]; then
  set -- 70 80 90
  for _s in "$PROJ/CLAUDE.md|Réglages du projet" "$BASE/profil.md|Réglages"; do
    _v=$(rg "${_s%%|*}" "${_s#*|}" seuils | tr ',/' '  ')
    set -f; set -- $_v; set +f
    if ok_seuils "$*"; then break; fi
    set -- 70 80 90
  done
fi
s1="${1:-70}"; s2="${2:-80}"; s3="${3:-90}"
for n in "$s1" "$s2" "$s3"; do
  case "$n" in ""|*[!0-9]*) echo "usage : quota.sh [seuil1 seuil2 seuil3] (entiers)" >&2; exit 2 ;; esac
done
command -v jq >/dev/null 2>&1 || { echo "quota inconnu : jq est absent (installe jq)"; exit 2; }
[ -f "$f" ] || { echo "quota inconnu : usage.json absent (la barre d'état ne l'a jamais écrit)"; exit 2; }
now="${QUOTA_NOW:-$(date +%s 2>/dev/null)}"
case "$now" in ""|*[!0-9]*) echo "quota inconnu : heure illisible"; exit 2 ;; esac

hhmm() {
  case "$1" in ""|*[!0-9]*) return 0 ;; esac
  if [ "$(uname -s 2>/dev/null)" = Darwin ]; then date -r "$1" +%H:%M 2>/dev/null; else date -d "@$1" +%H:%M 2>/dev/null; fi
}

best=0; usable=0; stale=0
for w in five_hour seven_day; do
  # « pct | resets_at | measured_at » ; vide si la fenêtre est absente
  row=$(jq -r --arg w "$w" '.[$w] | select(type == "object") | [ (.used_percentage // "" | if type == "number" then (. + 0.5 | floor | tostring) else "" end), (.resets_at // "" | tostring), (.measured_at // "" | tostring) ] | join("|")' "$f" 2>/dev/null) || row=""
  [ -n "$row" ] || continue
  IFS='|' read -r pct rst mes <<EOT
$row
EOT
  case "$w" in five_hour) lbl="5h" ;; *) lbl="7j" ;; esac
  case "$pct" in ""|*[!0-9]*) continue ;; esac
  case "$mes" in ""|*[!0-9]*) stale=1; continue ;; esac
  age=$(( now - mes ))
  # mesure du futur (horloge déréglée) ou de plus de 15 min : inutilisable
  if [ "$age" -lt -60 ] || [ "$age" -gt 900 ]; then stale=1; continue; fi
  [ "$age" -lt 0 ] && age=0
  # fenêtre terminée : le pourcentage mesuré ne vaut plus
  case "$rst" in *[!0-9]*) rst="" ;; esac
  if [ -n "$rst" ] && [ "$rst" -le "$now" ]; then stale=1; continue; fi
  pal=0
  [ "$pct" -ge "$s1" ] && pal=$s1
  [ "$pct" -ge "$s2" ] && pal=$s2
  [ "$pct" -ge "$s3" ] && pal=$s3
  h=$(hhmm "$rst"); r=""; [ -n "$h" ] && r=" reset $h,"
  echo "$lbl $pct %$r mesuré il y a $(( age / 60 )) min, palier $pal"
  usable=$(( usable + 1 ))
  [ "$pal" -gt "$best" ] && best=$pal
done

if [ "$usable" -eq 0 ]; then
  if [ "$stale" -eq 1 ]; then echo "quota inconnu : mesure de plus de 15 min ou fenêtre terminée (la barre d'état ne tourne plus ?)"
  else echo "quota inconnu : aucune fenêtre dans usage.json"; fi
  exit 2
fi
exit "$best"
