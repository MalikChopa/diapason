#!/bin/sh
# Méthode Diapason : barre d'état (statusLine) du terminal.
# Entrée : JSON de la barre d'état sur l'entrée standard. Sortie : une ligne
#   🛎️ <projet> · <jalon> · <n> agents · 5 h <x> % (reset HH:MM) · 7 j <y> %
# - projet : nom du dossier courant (.workspace.current_dir, sinon .cwd, sinon $PWD)
# - jalon  : ligne « Jalon : … » de docs/HANDOFF.md (comme le mod de bureau), 40 caractères au plus.
#            Rien si la ligne manque, est vide ou garde le gabarit « <…> ». Pas de repli sur une autre
#            ligne : « Reprise immédiate » commence souvent par une phrase fixe qui ne dit rien du jalon.
#            Ce texte vient d'un fichier du projet (peut-être non fiable) : les caractères de contrôle
#            (ESC, BEL, C1…) sont retirés avant l'affichage.
# - n      : nombre de fichiers du compteur de la session (voir agent-count.sh)
# - quota  : rate_limits.five_hour / seven_day ; « quota ? » si le JSON n'en contient pas.
# Réglages (voir skills/diapason/reglages.md) : lignes « - clé : valeur » de la rubrique « ## Réglages » du
# profil, surchargées par « ## Réglages du projet » du CLAUDE.md du dossier courant. Lus ici : `barre` (éléments
# et ordre : projet jalon agents quota, et cout si le JSON donne cost.total_cost_usd), `seuils` (3 entiers,
# fenêtre de 5 h seulement), `seuils-hebdo` et `plafonds-hebdo` (3 entiers chacun, fenêtre de 7 j).
# Absents ou illisibles : barre « projet jalon agents quota », seuils 70 80 90, seuils-hebdo 20 40 60,
# plafonds-hebdo 85 92 97.
# Effets de bord : écrit ~/.claude/diapason/usage.json (jamais écrasé par du vide) et
# lance les alertes de quota une seule fois par seuil et par resets_at : fenêtre de 5 h aux seuils du réglage
# (70 / 80 / 90 % par défaut) ; fenêtre de 7 j aux paliers 1 à 3 de la variante C (écart de rythme ou plafond,
# même calcul que `quota.sh hebdo`, recopié ici car la barre peut être installée seule : un test compare les deux).
# Les nombres des réglages sont lus en décimal (« 08 20 40 » vaut 8 20 40). Un pourcentage ou une remise du JSON qui n'est pas
# un nombre sensible (0 à 100 pour le pourcentage ; 1e300, négatif, géant) est traité comme absent.
# Jamais bloquant : sort toujours avec 0.
# Dossier des données : ~/.claude/diapason s'il existe, sinon l'ancien ~/.claude/majordome (v1.4), sinon ~/.claude/maitre-agent (v1.3 et avant), sinon ~/.claude/diapason
if [ -d "$HOME/.claude/diapason" ]; then BASE="$HOME/.claude/diapason"
elif [ -d "$HOME/.claude/majordome" ]; then BASE="$HOME/.claude/majordome"
elif [ -d "$HOME/.claude/maitre-agent" ]; then BASE="$HOME/.claude/maitre-agent"
else BASE="$HOME/.claude/diapason"; fi
SELF_DIR=$(dirname "$0" 2>/dev/null) || SELF_DIR=.
if [ -t 0 ]; then in="{}"; else in=$(cat 2>/dev/null) || in="{}"; fi
[ -n "$in" ] || in="{}"

if ! command -v jq >/dev/null 2>&1; then
  printf '🛎️ diapason · jq absent · quota ?\n'
  exit 0
fi

SEP='|'   # séparateur visible : \001 est mal géré par le bash 3.2 de macOS (sh)
fields=$(printf '%s' "$in" | jq -r '
  def pct: (numbers | (. + 0.5 | floor | tostring)) // "";
  def raw: (numbers | tostring) // "";
  [ (.session_id // "" | tostring | gsub("[|]";"_")),
    (.rate_limits.five_hour.used_percentage | pct),
    (.rate_limits.five_hour.used_percentage | raw),
    (.rate_limits.five_hour.resets_at | raw),
    (.rate_limits.seven_day.used_percentage | pct),
    (.rate_limits.seven_day.used_percentage | raw),
    (.rate_limits.seven_day.resets_at | raw),
    (.cost.total_cost_usd | raw),
    (.workspace.current_dir // .cwd // "" | tostring)
  ] | join("|")' 2>/dev/null) || fields=""
IFS="$SEP" read -r sid p5 p5raw r5 p7 p7raw r7 costraw dir <<EOT
$fields
EOT
[ -n "$dir" ] || dir="$PWD"
# Valeurs extrêmes (1e300, négatif, géant) : traitées comme absentes, la barre s'affiche quand même
okp() { case "$1" in ""|*[!0-9]*|????*) return 1 ;; esac; [ "$1" -le 100 ]; }
okr() { case "$1" in ""|*[!0-9]*) return 1 ;; esac; [ "${#1}" -le 15 ]; }
okp "$p5" || { p5=""; p5raw=""; }
okp "$p7" || { p7=""; p7raw=""; }
okr "$r5" || r5=""
okr "$r7" || r7=""
proj=$(basename "$dir" 2>/dev/null) || proj="$dir"

# --- Réglages : projet (CLAUDE.md du dossier courant) puis profil ; première valeur valide, sinon défaut --
PROJ="$dir"
rg() { # $1 fichier  $2 titre de la rubrique  $3 clé -> valeur (sans commentaire entre parenthèses)
  [ -f "$1" ] || return 0
  awk -v t="$2" -v k="$3" '
    /^#+[ \t]/ { if ($0 ~ /^##[ \t]/) { s = $0; sub(/^##[ \t]+/, "", s); sub(/[ \t\r]+$/, "", s); on = (s == t) } else if ($0 ~ /^#[ \t]/) on = 0; next }
    on && /^[ \t]*[-*][ \t]+/ { l = $0; sub(/^[ \t]*[-*][ \t]+/, "", l); i = index(l, ":")
      if (i > 1) { n = substr(l, 1, i - 1); gsub(/[ \t*`]+/, "", n)
        if (tolower(n) == k) { v = substr(l, i + 1); sub(/^[ \t*`]+/, "", v); sub(/[ \t\r*`]+$/, "", v); sub(/[ \t]*\(.*\)$/, "", v); print v; exit } } }' "$1" 2>/dev/null
}
dec() { _d="$1"; while :; do case "$_d" in 0?*) _d="${_d#0}" ;; *) break ;; esac; done; printf '%s' "$_d"; }
setting() { # $1 clé  $2 fonction de contrôle  $3 « num » si la valeur est faite d'entiers (zéros de tête retirés : $(( 08 )) est une erreur en sh)
           # -> première valeur valide (projet puis profil) ; « , » et « / » valent un espace
  _k="$1"; _f="$2"; _num="${3:-}"
  for _s in "$PROJ/CLAUDE.md|Réglages du projet" "$BASE/profil.md|Réglages"; do
    _v=$(rg "${_s%%|*}" "${_s#*|}" "$_k" | tr ',/' '  ')
    set -f; set -- $_v; set +f; _v="$*"
    if [ -n "$_v" ] && "$_f" "$_v"; then
      if [ "$_num" = num ]; then set -- $_v; printf '%s %s %s' "$(dec "$1")" "$(dec "$2")" "$(dec "$3")"; else printf '%s' "$_v"; fi
      return 0
    fi
  done
  return 1
}
ok_seuils() { set -- $1; [ "$#" -eq 3 ] || return 1; for x in "$1" "$2" "$3"; do case "$x" in ""|*[!0-9]*|????*) return 1 ;; esac; done
  [ "$1" -ge 10 ] && [ "$1" -lt "$2" ] && [ "$2" -lt "$3" ] && [ "$3" -le 99 ]; }
ok_barre() { b=" "; for w in $1; do case "$w" in projet|jalon|agents|quota|cout) ;; *) return 1 ;; esac
  case "$b" in *" $w "*) return 1 ;; esac; b="$b$w "; done; [ "$b" != " " ]; }
ok_trio() { set -- $1; [ "$#" -eq 3 ] || return 1; for x in "$1" "$2" "$3"; do case "$x" in ""|*[!0-9]*|????*) return 1 ;; esac; done
  [ "$1" -ge 1 ] && [ "$1" -lt "$2" ] && [ "$2" -lt "$3" ] && [ "$3" -le 99 ]; }
SEUILS=$(setting seuils ok_seuils num) || SEUILS="70 80 90"
SEUILS_H=$(setting seuils-hebdo ok_trio num) || SEUILS_H="20 40 60"
PLAFONDS_H=$(setting plafonds-hebdo ok_trio num) || PLAFONDS_H="85 92 97"
BARRE=$(setting barre ok_barre) || BARRE="projet jalon agents quota"

# Texte venant du JSON ou d'un fichier du projet : on retire les caractères de contrôle, qui pourraient
# être des séquences d'échappement du terminal (titre de fenêtre, effacement d'écran, presse-papiers…).
# tr retire C0 et DEL (octets 0-31 et 127), jq retire les C1 (U+0080 à U+009F).
clean() { printf '%s' "$1" | tr -d '\000-\037\177' | jq -Rrs 'gsub("[\\x{80}-\\x{9f}]";"")' 2>/dev/null; }
proj=$(clean "$proj")

# --- Jalon : ligne « Jalon : » de docs/HANDOFF.md ------------------------------------------
jalon=""
f="$dir/docs/HANDOFF.md"
if [ -f "$f" ]; then
  line=$(sed -n 's/^Jalon :[[:space:]]*//p' "$f" 2>/dev/null | head -n 1) || line=""
  case "$line" in "<"*) line="" ;; esac
  if [ -n "$line" ]; then
    jalon=$(printf '%s' "$line" | sed -e 's/\*\*//g' -e 's/`//g' | tr -d '\000-\037\177' \
      | jq -Rrs 'gsub("[\\x{80}-\\x{9f}]";"") | if length > 40 then .[0:39] + "…" else . end' 2>/dev/null) || jalon=""
  fi
fi

# --- Agents en cours -------------------------------------------------------------------------
n=0
sidsafe=$(printf '%s' "$sid" | tr -c 'A-Za-z0-9_.-' '_')
case "$sidsafe" in
  "") ;;
  *) case "$sidsafe" in .*) sidsafe="_$sidsafe" ;; esac
     ad="$BASE/state/$sidsafe/agents"
     [ -d "$ad" ] && n=$(( $(find "$ad" -type f -mmin -300 2>/dev/null | wc -l) + 0 )) ;;
esac
if [ "$n" -le 1 ]; then agents="$n agent"; else agents="$n agents"; fi

# --- Heure de remise à zéro (macOS : date -r, Linux : date -d) ------------------------------
hhmm() {
  case "$1" in ""|*[!0-9]*) return 0 ;; esac
  if [ "$(uname -s 2>/dev/null)" = Darwin ]; then date -r "$1" +%H:%M 2>/dev/null; else date -d "@$1" +%H:%M 2>/dev/null; fi
}

# --- Quota : affichage ------------------------------------------------------------------------
if [ -z "$p5" ] && [ -z "$p7" ]; then
  quota="quota ?"
else
  if [ -n "$p5" ]; then
    q5="5 h $p5 %"; h5=$(hhmm "$r5"); [ -n "$h5" ] && q5="$q5 (reset $h5)"
  else
    q5="5 h ?"
  fi
  quota="$q5"
  [ -n "$p7" ] && quota="$quota · 7 j $p7 %"
fi

# --- usage.json : seulement les fenêtres présentes, les autres gardent leur dernière valeur ---
now=$(date +%s 2>/dev/null) || now=0
if [ -n "$p5raw" ] || [ -n "$p7raw" ]; then
  umask 077
  mkdir -p "$BASE" 2>/dev/null
  old='{}'
  [ -f "$BASE/usage.json" ] && { old=$(jq -c 'if type=="object" then . else {} end' "$BASE/usage.json" 2>/dev/null) || old='{}'; [ -n "$old" ] || old='{}'; }
  new=$(jq -n -c --argjson old "$old" --argjson now "$now" \
    --arg p5 "$p5raw" --arg r5 "$r5" --arg p7 "$p7raw" --arg r7 "$r7" '
    def win($p; $r): {used_percentage: ($p | tonumber)}
      + (if $r != "" then {resets_at: ($r | tonumber)} else {} end) + {measured_at: $now};
    $old
    + (if $p5 != "" then {five_hour: win($p5; $r5)} else {} end)
    + (if $p7 != "" then {seven_day: win($p7; $r7)} else {} end)
    + {updated_at: ($now | todate)}' 2>/dev/null) || new=""
  if [ -n "$new" ]; then
    { printf '%s\n' "$new" > "$BASE/usage.json.tmp.$$"; } 2>/dev/null && mv -f "$BASE/usage.json.tmp.$$" "$BASE/usage.json" 2>/dev/null
    rm -f "$BASE/usage.json.tmp.$$" 2>/dev/null
  fi
fi

# --- Alertes de quota (seuils du réglage, 70 / 80 / 90 % par défaut) : une fois par seuil et par resets_at ----------------------------
# Si plusieurs seuils sont franchis d'un coup, une seule alerte (le plus haut) et les plus bas sont marqués faits.
alerte() { # $1 nom de fenêtre (5h|7j)  $2 pourcentage entier  $3 resets_at  $4 libellé
  [ -n "$2" ] || return 0
  key=$(printf '%s' "${3:-0}" | tr -c '0-9' '_')
  ad="$BASE/state/alerts"
  # Le seuil visé est le plus haut franchi (SEUILS est croissant), qu'il soit déjà marqué ou non : un appel
  # qui arrive pendant que l'autre marque encore les seuils plus bas ne doit pas viser un seuil plus bas.
  top=0
  for s in $SEUILS; do
    if [ "$2" -ge "$s" ] 2>/dev/null; then top=$s; fi
  done
  [ "$top" -gt 0 ] || return 0
  mkdir -p "$ad" 2>/dev/null || return 0
  # Verrou atomique : mkdir réussit pour un seul appel. Deux sessions qui franchissent le seuil en même
  # temps n'envoient qu'une alerte ; l'autre voit le dossier existant et s'arrête.
  mkdir "$ad/$1-$key-$top" 2>/dev/null || return 0
  for s in $SEUILS; do [ "$s" -lt "$top" ] && mkdir "$ad/$1-$key-$s" 2>/dev/null; done
  h=$(hhmm "$3"); extra=""; [ -n "$h" ] && extra=" (reset $h)"
  nt=""
  for c in "$SELF_DIR/notify.sh" "$BASE/notify.sh" "$BASE/hooks/notify.sh"; do [ -f "$c" ] && { nt="$c"; break; }; done
  [ -n "$nt" ] && DIAPASON_PROJECT_DIR="$dir" sh "$nt" quota "Quota $4 à $2 %$extra : seuil $top % franchi." >&2
}
alerte 5h "$p5" "$r5" "5 h"
# Fenêtre de 7 j : palier 0 à 3 = le plus haut du palier d'écart (utilisé % - écoulé % >= seuils-hebdo) et du
# palier de plafond (utilisé % >= plafonds-hebdo) ; palier 3 aussi si utilisé >= 90 % et projection >= 300 %.
# Plafonds seuls si la remise est inconnue, passée, à plus de 7 j, à moins de 12 h, ou si moins de 10 % est écoulé.
palier_h() { # $1 pourcentage entier  $2 resets_at -> PH (0 à 3), PH_ECART (texte, vide si plafonds seuls)
  set -- "$1" "$2" $SEUILS_H $PLAFONDS_H
  _u=$1; _r=$2; PH=0; PH_ECART=""
  [ "$_u" -ge "$6" ] && PH=1
  [ "$_u" -ge "$7" ] && PH=2
  [ "$_u" -ge "$8" ] && PH=3
  case "$_r" in ""|*[!0-9]*) return 0 ;; esac
  [ "$_r" -gt "$now" ] || return 0
  _W=604800; _rest=$(( _r - now ))
  [ "$_rest" -le "$_W" ] && [ "$_rest" -ge 43200 ] || return 0
  _el=$(( _W - _rest ))
  [ $(( _el * 10 )) -ge "$_W" ] || return 0
  _d=$(( _u * _W - _el * 100 )); _ep=0
  [ "$_d" -ge $(( $3 * _W )) ] && _ep=1
  [ "$_d" -ge $(( $4 * _W )) ] && _ep=2
  [ "$_d" -ge $(( $5 * _W )) ] && _ep=3
  _pj=$(( (_u * _W + _el / 2) / _el ))
  [ "$_u" -ge 90 ] && [ "$_pj" -ge 300 ] && _ep=3
  if [ "$_d" -ge 0 ]; then _ec="+$(( (_d + _W / 2) / _W ))"; else _ec="-$(( (_W / 2 - _d) / _W ))"; fi
  PH_ECART=", écart $_ec points"
  [ "$_ep" -gt "$PH" ] && PH=$_ep
  return 0
}
alerte_h() { # $1 pourcentage entier  $2 resets_at : une alerte par palier et par remise (le plus haut non encore notifié)
  [ -n "$1" ] || return 0
  palier_h "$1" "$2"
  [ "$PH" -gt 0 ] || return 0
  key=$(printf '%s' "${2:-0}" | tr -c '0-9' '_')
  ad="$BASE/state/alerts"; top=$PH; pp=1   # palier visé = le plus haut atteint, même raison que dans alerte
  mkdir -p "$ad" 2>/dev/null || return 0
  mkdir "$ad/7j-$key-p$top" 2>/dev/null || return 0
  pp=1; while [ "$pp" -lt "$top" ]; do mkdir "$ad/7j-$key-p$pp" 2>/dev/null; pp=$(( pp + 1 )); done
  h=$(hhmm "$2"); extra=""; [ -n "$h" ] && extra=" (remise $h)"
  nt=""
  for c in "$SELF_DIR/notify.sh" "$BASE/notify.sh" "$BASE/hooks/notify.sh"; do [ -f "$c" ] && { nt="$c"; break; }; done
  [ -n "$nt" ] && DIAPASON_PROJECT_DIR="$dir" sh "$nt" quota "Quota 7 j à $1 %$extra : palier $top sur 3$PH_ECART." >&2
}
alerte_h "$p7" "$r7"
# Purge des marqueurs d'alerte de plus de 8 jours (fichiers d'une ancienne version ou dossiers vides)
[ -d "$BASE/state/alerts" ] && find "$BASE/state/alerts" -mindepth 1 -mtime +8 -delete 2>/dev/null
# Purge des dossiers d'état vides depuis plus de 5 h (sessions finies)
[ -d "$BASE/state" ] && find "$BASE/state" -mindepth 1 -type d -empty -mmin +300 ! -path "$BASE/state/alerts" ! -path "$BASE/state/alerts/*" -delete 2>/dev/null

# --- Coût de la session (seulement si le JSON le donne et si `cout` est dans la barre) ---------------
cost=""
case "$costraw" in ""|*[!0-9.]*) ;; *) cost=$(LC_ALL=C awk -v c="$costraw" 'BEGIN { printf "coût %.2f $", c }' 2>/dev/null) ;; esac

# --- Sortie : les éléments de `barre`, dans l'ordre voulu, séparés par « · » -------------------------
out=""
for w in $BARRE; do
  case "$w" in
    projet) piece="$proj" ;;
    jalon) piece="$jalon" ;;
    agents) piece="$agents" ;;
    quota) piece="$quota" ;;
    cout) piece="$cost" ;;
    *) piece="" ;;
  esac
  [ -n "$piece" ] && out="${out:+$out · }$piece"
done
printf '🛎️ %s\n' "$out"
exit 0
