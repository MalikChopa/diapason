#!/bin/sh
# Méthode maître agent : notification système, jamais bloquante.
# Usage : notify.sh agent|blocked|quota [texte]
#   agent   : fin d'un sous-agent (JSON de SubagentStop sur l'entrée standard) -> « nom : statut »
#   blocked : hook Notification (permission_prompt, idle_prompt) -> le message reçu
#   quota   : texte donné en argument (alertes de quota de statusline.sh)
# Réglage `notifications` (voir skills/maitre-agent/reglages.md), ligne « - notifications : … » de la rubrique
# « ## Réglages » du profil, surchargée par « ## Réglages du projet » du CLAUDE.md du dossier du projet
# (MAITRE_AGENT_PROJECT_DIR, sinon le champ cwd du JSON reçu, sinon CLAUDE_PROJECT_DIR, sinon le dossier courant) :
#   agent+quota (défaut) : fin d'agent et alertes de quota  |  tout : en plus « Claude attend »
#   quota : alertes de quota seulement                      |  rien : aucune notification
# Sans réglage valide, les fichiers d'avant la v1.2 décident : ~/.claude/maitre-agent/notifications-on
# active « Claude attend » (comme `tout`). Le fichier notifications-off coupe tout, toujours.
# Test sans notifier : MAITRE_AGENT_DRY_RUN=1 (affiche au lieu de notifier).
kind="$1"
[ "$#" -gt 0 ] && shift
txt="$*"
case "$kind" in agent|blocked|quota) ;; *) exit 0 ;; esac
BASE="$HOME/.claude/maitre-agent"
# L'entrée standard (JSON du hook) est lue une fois ; le hook n'a rien à dire si on s'arrête avant.
in=""
if [ "$kind" != quota ] && [ ! -t 0 ]; then in=$(cat 2>/dev/null) || in=""; fi
[ -e "$BASE/notifications-off" ] && exit 0

# --- Réglage `notifications` : projet puis profil, repli sur les fichiers historiques ------------------------
PROJ="${MAITRE_AGENT_PROJECT_DIR:-}"
if [ -z "$PROJ" ] && [ -n "$in" ] && command -v jq >/dev/null 2>&1; then PROJ=$(printf '%s' "$in" | jq -r '.cwd // empty' 2>/dev/null) || PROJ=""; fi
[ -n "$PROJ" ] || PROJ="${CLAUDE_PROJECT_DIR:-$PWD}"
rg() { # $1 fichier  $2 titre de la rubrique  $3 clé -> valeur (sans commentaire entre parenthèses)
  [ -f "$1" ] || return 0
  awk -v t="$2" -v k="$3" '
    /^#+[ \t]/ { if ($0 ~ /^##[ \t]/) { s = $0; sub(/^##[ \t]+/, "", s); sub(/[ \t\r]+$/, "", s); on = (s == t) } else if ($0 ~ /^#[ \t]/) on = 0; next }
    on && /^[ \t]*[-*][ \t]+/ { l = $0; sub(/^[ \t]*[-*][ \t]+/, "", l); i = index(l, ":")
      if (i > 1) { n = substr(l, 1, i - 1); gsub(/[ \t*`]+/, "", n)
        if (tolower(n) == k) { v = substr(l, i + 1); sub(/^[ \t*`]+/, "", v); sub(/[ \t\r*`]+$/, "", v); sub(/[ \t]*\(.*\)$/, "", v); print v; exit } } }' "$1" 2>/dev/null
}
mode=""
for _s in "$PROJ/CLAUDE.md|Réglages du projet" "$BASE/profil.md|Réglages"; do
  _v=$(rg "${_s%%|*}" "${_s#*|}" notifications)
  case "$_v" in agent+quota|tout|quota|rien) mode="$_v"; break ;; esac
done
if [ -z "$mode" ]; then if [ -e "$BASE/notifications-on" ]; then mode=tout; else mode="agent+quota"; fi; fi
case "$kind:$mode" in
  *:rien|agent:quota|blocked:quota|blocked:agent+quota) exit 0 ;;
esac

# Le texte peut venir d'un message libre ou d'un rapport d'agent : on retire les caractères de contrôle
# (séquences d'échappement), les ** du markdown, et on coupe à 80 caractères (jq compte en caractères).
cut80() { printf '%s' "$1" | tr '\r\n\t' '   ' | tr -d '\000-\037\177' | jq -Rrs 'gsub("[\\x{80}-\\x{9f}]";" ") | gsub("[*][*]";"") | if length > 80 then .[0:79] + "…" else . end' 2>/dev/null; }

title="Maître agent"
case "$kind" in
  agent)
    title="Maître agent : agent terminé"
    if [ -z "$txt" ] && [ -n "$in" ] && command -v jq >/dev/null 2>&1; then
      # nom = agent_type sans le préfixe de plugin ; un agent interne (type vide) ne notifie pas
      txt=$(printf '%s' "$in" | jq -r '
        ((.agent_type // "") | sub("^.*:";"")) as $n
        | ((.last_assistant_message // "") | split("\n") | map(select(test("\\S"))) | (.[0] // "") | sub("^[#>*\\s-]+";"") | sub("\\s+$";"")) as $s
        | if $n == "" then "" elif $s == "" then $n else $n + " : " + $s end' 2>/dev/null) || txt=""
    fi
    ;;
  blocked)
    title="Maître agent : Claude attend"
    if [ -z "$txt" ] && [ -n "$in" ] && command -v jq >/dev/null 2>&1; then
      txt=$(printf '%s' "$in" | jq -r '.message // ""' 2>/dev/null) || txt=""
    fi
    [ -n "$txt" ] || txt="Claude attend ta réponse."
    ;;
  quota)
    title="Maître agent : quota"
    ;;
esac
[ -n "$txt" ] || exit 0
if command -v jq >/dev/null 2>&1; then
  c=$(cut80 "$txt"); [ -n "$c" ] && txt="$c"
else
  txt=$(printf '%s' "$txt" | tr '\r\n\t' '   ' | tr -d '\000-\037\177')
fi

if [ "${MAITRE_AGENT_DRY_RUN:-}" = 1 ]; then
  printf '[notification] %s | %s\n' "$title" "$txt"
  exit 0
fi
# Le texte passe en argument d'AppleScript (jamais collé dans le script) : pas d'injection.
case "$(uname -s 2>/dev/null)" in
  Darwin)
    command -v osascript >/dev/null 2>&1 && \
      ( osascript -e 'on run argv' -e 'display notification (item 1 of argv) with title (item 2 of argv)' -e 'end run' -- "$txt" "$title" >/dev/null 2>&1 & )
    ;;
  Linux)
    command -v notify-send >/dev/null 2>&1 && \
      ( notify-send -- "$title" "$txt" >/dev/null 2>&1 & )
    ;;
esac
exit 0
