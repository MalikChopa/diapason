#!/bin/sh
# Méthode maître agent : lit le quota dans ~/.claude/maitre-agent/usage.json (écrit par la barre d'état
# ou par une copie de ce fichier) et conclut le palier, pour que le modèle n'ait pas à calculer.
# Usage : sh quota.sh [seuil1 seuil2 seuil3]
#         sh quota.sh hebdo <utilisé %> [<resetsAt : date ISO 8601 ou epoch>]
#   Sans argument, les seuils de la fenêtre de 5 h sont ceux du réglage `seuils` (ligne « - seuils : 60 75 85 »
#   de la rubrique « ## Réglages » du profil, surchargée par « ## Réglages du projet » du CLAUDE.md du dossier
#   courant ou de MAITRE_AGENT_PROJECT_DIR) ; absent ou invalide : 70 80 90. `seuils` ne vaut QUE pour la
#   fenêtre de 5 h. La fenêtre hebdomadaire (7 j) a ses propres règles (variante C de docs/research/04) :
#     écart = utilisé % - écoulé % de la semaine (7 j avant la remise) ; projection = utilisé / écoulé x 100.
#     Palier d'écart : écart >= 1er, 2e, 3e nombre de `seuils-hebdo` (défaut 20 40 60 points).
#     Palier de plafond : utilisé >= 1er, 2e, 3e nombre de `plafonds-hebdo` (défaut 85 92 97 %).
#     Palier hebdo = le plus haut des deux ; palier 3 aussi si utilisé >= 90 et projection >= 300 %.
#     Plafonds seuls (pas de rythme) si : remise absente, passée, illisible ou à plus de 7 j ; remise dans moins
#     de 12 h ; moins de 10 % de la semaine écoulée.
#   `hebdo` : même calcul pour des chiffres donnés à la main (par exemple ceux de l'outil get_usage) ; le modèle
#   passe les valeurs au script, il ne calcule pas. Pas de jq ni de usage.json nécessaires.
# Sortie : une ligne par fenêtre utilisable, par exemple
#   5h 62 % reset 14:20, mesuré il y a 3 min, palier 0
#   7j 69 % reset lun 00:00 écart +32 proj 187 %, mesuré il y a 3 min, palier 1
#   7j 69 % reset dim 14:20 écart +32 proj 187 %, palier 1                (mode hebdo)
# Code de sortie, mode usage.json :
#   0               tous les paliers à 0
#   seuil atteint   le plus haut palier d'une fenêtre, écrit comme le seuil de `seuils` du même rang
#                   (70, 80 ou 90 par défaut : palier 1, 2 ou 3, pour la fenêtre de 5 h comme pour l'hebdo)
#   2               aucune mesure utilisable : fichier absent, jq absent, mesure de plus de 15 min,
#                   ou fenêtre déjà terminée (resets_at dans le passé). Le modèle ne doit alors
#                   inventer aucun pourcentage : il demande à l'utilisateur.
# Code de sortie, mode hebdo : le palier lui-même, 0 à 3 ; 4 = pourcentage illisible (rien n'est calculé).
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
ok_trio() { set -- $1; [ "$#" -eq 3 ] || return 1; for x in "$1" "$2" "$3"; do case "$x" in ""|*[!0-9]*) return 1 ;; esac; done
  [ "$1" -ge 1 ] && [ "$1" -lt "$2" ] && [ "$2" -lt "$3" ] && [ "$3" -le 99 ]; }
hset() { # $1 clé  $2 défaut -> trio valide (projet, puis profil, puis défaut)
  _hk="$1"; _hd="$2"
  for _s in "$PROJ/CLAUDE.md|Réglages du projet" "$BASE/profil.md|Réglages"; do
    _v=$(rg "${_s%%|*}" "${_s#*|}" "$_hk" | tr ',/' '  ')
    set -f; set -- $_v; set +f
    if ok_trio "$*"; then echo "$*"; return 0; fi
  done
  echo "$_hd"
}
W=604800   # une semaine, en secondes
# to_epoch <epoch ou date ISO 8601> : écrit des secondes epoch, ou rien si illisible
to_epoch() {
  case "$1" in
    "") return 0 ;;
    *[!0-9]*) ;;
    *) _e="$1"; [ "${#_e}" -ge 12 ] && _e=$(( _e / 1000 )); echo "$_e"; return 0 ;;
  esac
  if [ "$(uname -s 2>/dev/null)" = Darwin ]; then
    _i=$(printf '%s' "$1" | sed -e 's/\.[0-9]*//' -e 's/Z$/+0000/' -e 's/\([+-][0-9][0-9]\):\([0-9][0-9]\)$/\1\2/')
    date -j -f "%Y-%m-%dT%H:%M:%S%z" "$_i" +%s 2>/dev/null || date -j -f "%Y-%m-%dT%H:%M:%S" "$_i" +%s 2>/dev/null
  else
    date -d "$1" +%s 2>/dev/null
  fi
}
jour() { # $1 epoch -> « lun 00:00 »
  if [ "$(uname -s 2>/dev/null)" = Darwin ]; then _d=$(date -r "$1" "+%u %H:%M" 2>/dev/null); else _d=$(date -d "@$1" "+%u %H:%M" 2>/dev/null); fi
  [ -n "$_d" ] || return 0
  case "${_d%% *}" in 1) _j=lun ;; 2) _j=mar ;; 3) _j=mer ;; 4) _j=jeu ;; 5) _j=ven ;; 6) _j=sam ;; 7) _j=dim ;; *) _j="" ;; esac
  echo "$_j ${_d#* }"
}
# hebdo_eval <utilisé % entier> <resets_at epoch ou vide> <maintenant> : fixe H_PAL (0 à 3) et H_TXT
hebdo_eval() {
  _u="$1"; _r="$2"; _n="$3"
  set -- $(hset seuils-hebdo "20 40 60"); e1=$1; e2=$2; e3=$3
  set -- $(hset plafonds-hebdo "85 92 97"); c1=$1; c2=$2; c3=$3
  cp=0
  [ "$_u" -ge "$c1" ] && cp=1
  [ "$_u" -ge "$c2" ] && cp=2
  [ "$_u" -ge "$c3" ] && cp=3
  ep=0; H_TXT=""; why=""
  if [ -z "$_r" ]; then why="remise inconnue"
  elif [ "$_r" -le "$_n" ]; then why="remise passée"
  else
    reste=$(( _r - _n ))
    jr=$(jour "$_r"); [ -n "$jr" ] && H_TXT=" reset $jr"
    if [ "$reste" -gt "$W" ]; then why="remise à plus de 7 j"
    elif [ "$reste" -lt 43200 ]; then why="remise dans moins de 12 h"
    else
      el=$(( W - reste ))
      if [ $(( el * 10 )) -lt "$W" ]; then why="moins de 10 % de la semaine écoulée"
      else
        d=$(( _u * W - el * 100 ))
        [ "$d" -ge $(( e1 * W )) ] && ep=1
        [ "$d" -ge $(( e2 * W )) ] && ep=2
        [ "$d" -ge $(( e3 * W )) ] && ep=3
        if [ "$d" -ge 0 ]; then ec=$(( (d + W / 2) / W )); sg="+"; else ec=$(( (W / 2 - d) / W )); sg="-"; fi
        pj=$(( (_u * W + el / 2) / el ))
        [ "$_u" -ge 90 ] && [ "$pj" -ge 300 ] && ep=3
        H_TXT="$H_TXT écart $sg$ec proj $pj %"
      fi
    fi
  fi
  [ -n "$why" ] && H_TXT="$H_TXT (plafonds seuls : $why)"
  H_PAL=$cp; [ "$ep" -gt "$H_PAL" ] && H_PAL=$ep
  return 0
}
# --- mode hebdo : chiffres donnés à la main --------------------------------------------------------------
if [ "${1:-}" = hebdo ]; then
  u=$(printf '%s' "${2:-}" | tr -d ' %,' )
  case "$u" in
    ""|.*|*[!0-9.]*|*.*.*) echo "usage : quota.sh hebdo <utilisé %> [<resetsAt ISO 8601 ou epoch>]"; exit 4 ;;
  esac
  case "$u" in *.*) fr=${u#*.}; u=${u%%.*}; case "$fr" in [5-9]*) u=$(( u + 1 )) ;; esac ;; esac
  [ -n "$u" ] || u=0
  [ "$u" -gt 100 ] && u=100
  now="${QUOTA_NOW:-$(date +%s 2>/dev/null)}"
  case "$now" in ""|*[!0-9]*) echo "quota inconnu : heure illisible"; exit 4 ;; esac
  rst=$(to_epoch "${3:-}"); case "$rst" in *[!0-9]*) rst="" ;; esac
  hebdo_eval "$u" "$rst" "$now"
  [ -z "$rst" ] && [ -n "${3:-}" ] && H_TXT=$(printf '%s' "$H_TXT" | sed 's/remise inconnue/remise illisible/')
  echo "7j $u %$H_TXT, palier $H_PAL"
  exit "$H_PAL"
fi
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
  if [ "$w" = seven_day ]; then
    # fenêtre hebdomadaire : écart de rythme et plafonds (hebdo_eval), pas `seuils`
    hebdo_eval "$pct" "$rst" "$now"
    echo "$lbl $pct %$H_TXT, mesuré il y a $(( age / 60 )) min, palier $H_PAL"
    case "$H_PAL" in 1) pal=$s1 ;; 2) pal=$s2 ;; 3) pal=$s3 ;; *) pal=0 ;; esac
  else
    pal=0
    [ "$pct" -ge "$s1" ] && pal=$s1
    [ "$pct" -ge "$s2" ] && pal=$s2
    [ "$pct" -ge "$s3" ] && pal=$s3
    h=$(hhmm "$rst"); r=""; [ -n "$h" ] && r=" reset $h,"
    echo "$lbl $pct %$r mesuré il y a $(( age / 60 )) min, palier $pal"
  fi
  usable=$(( usable + 1 ))
  [ "$pal" -gt "$best" ] && best=$pal
done

if [ "$usable" -eq 0 ]; then
  if [ "$stale" -eq 1 ]; then echo "quota inconnu : mesure de plus de 15 min ou fenêtre terminée (la barre d'état ne tourne plus ?)"
  else echo "quota inconnu : aucune fenêtre dans usage.json"; fi
  exit 2
fi
exit "$best"
