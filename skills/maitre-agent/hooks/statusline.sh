#!/bin/sh
# Méthode maître agent : barre d'état (statusLine) du terminal.
# Entrée : JSON de la barre d'état sur l'entrée standard. Sortie : une ligne
#   🧭 <projet> · <jalon> · <n> agents · 5 h <x> % (reset HH:MM) · 7 j <y> %
# - projet : nom du dossier courant (.workspace.current_dir, sinon .cwd, sinon $PWD)
# - jalon  : ligne « Jalon : … » de docs/HANDOFF.md (comme le mod de bureau), 40 caractères au plus.
#            Rien si la ligne manque, est vide ou garde le gabarit « <…> ». Pas de repli sur une autre
#            ligne : « Reprise immédiate » commence souvent par une phrase fixe qui ne dit rien du jalon.
#            Ce texte vient d'un fichier du projet (peut-être non fiable) : les caractères de contrôle
#            (ESC, BEL, C1…) sont retirés avant l'affichage.
# - n      : nombre de fichiers du compteur de la session (voir agent-count.sh)
# - quota  : rate_limits.five_hour / seven_day ; « quota ? » si le JSON n'en contient pas.
# Effets de bord : écrit ~/.claude/maitre-agent/usage.json (jamais écrasé par du vide) et
# lance les alertes 70 / 80 / 90 % une seule fois par seuil et par resets_at.
# Jamais bloquant : sort toujours avec 0.
BASE="$HOME/.claude/maitre-agent"
SELF_DIR=$(dirname "$0" 2>/dev/null) || SELF_DIR=.
if [ -t 0 ]; then in="{}"; else in=$(cat 2>/dev/null) || in="{}"; fi
[ -n "$in" ] || in="{}"

if ! command -v jq >/dev/null 2>&1; then
  printf '🧭 maitre-agent · jq absent · quota ?\n'
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
    (.workspace.current_dir // .cwd // "" | tostring)
  ] | join("|")' 2>/dev/null) || fields=""
IFS="$SEP" read -r sid p5 p5raw r5 p7 p7raw r7 dir <<EOT
$fields
EOT
[ -n "$dir" ] || dir="$PWD"
proj=$(basename "$dir" 2>/dev/null) || proj="$dir"

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
    printf '%s\n' "$new" > "$BASE/usage.json.tmp.$$" 2>/dev/null && mv -f "$BASE/usage.json.tmp.$$" "$BASE/usage.json" 2>/dev/null
    rm -f "$BASE/usage.json.tmp.$$" 2>/dev/null
  fi
fi

# --- Alertes 70 / 80 / 90 % : une fois par seuil et par resets_at ----------------------------
# Si plusieurs seuils sont franchis d'un coup, une seule alerte (le plus haut) et les plus bas sont marqués faits.
alerte() { # $1 nom de fenêtre (5h|7j)  $2 pourcentage entier  $3 resets_at  $4 libellé
  [ -n "$2" ] || return 0
  key=$(printf '%s' "${3:-0}" | tr -c '0-9' '_')
  ad="$BASE/state/alerts"
  top=0
  for s in 70 80 90; do
    if [ "$2" -ge "$s" ] 2>/dev/null && [ ! -e "$ad/$1-$key-$s" ]; then top=$s; fi
  done
  [ "$top" -gt 0 ] || return 0
  mkdir -p "$ad" 2>/dev/null || return 0
  # Verrou atomique : mkdir réussit pour un seul appel. Deux sessions qui franchissent le seuil en même
  # temps n'envoient qu'une alerte ; l'autre voit le dossier existant et s'arrête.
  mkdir "$ad/$1-$key-$top" 2>/dev/null || return 0
  for s in 70 80 90; do [ "$s" -lt "$top" ] && mkdir "$ad/$1-$key-$s" 2>/dev/null; done
  h=$(hhmm "$3"); extra=""; [ -n "$h" ] && extra=" (reset $h)"
  nt=""
  for c in "$SELF_DIR/notify.sh" "$BASE/notify.sh" "$BASE/hooks/notify.sh"; do [ -f "$c" ] && { nt="$c"; break; }; done
  [ -n "$nt" ] && sh "$nt" quota "Quota $4 à $2 %$extra : seuil $top % franchi." >&2
}
alerte 5h "$p5" "$r5" "5 h"
alerte 7j "$p7" "$r7" "7 j"
# Purge des marqueurs d'alerte de plus de 8 jours (fichiers d'une ancienne version ou dossiers vides)
[ -d "$BASE/state/alerts" ] && find "$BASE/state/alerts" -mindepth 1 -mtime +8 -delete 2>/dev/null
# Purge des dossiers d'état vides depuis plus de 5 h (sessions finies)
[ -d "$BASE/state" ] && find "$BASE/state" -mindepth 1 -type d -empty -mmin +300 ! -path "$BASE/state/alerts" ! -path "$BASE/state/alerts/*" -delete 2>/dev/null

# --- Sortie -----------------------------------------------------------------------------------
if [ -n "$jalon" ]; then
  printf '🧭 %s · %s · %s · %s\n' "$proj" "$jalon" "$agents" "$quota"
else
  printf '🧭 %s · %s · %s\n' "$proj" "$agents" "$quota"
fi
exit 0
