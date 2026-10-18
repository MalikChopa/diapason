#!/bin/sh
# Méthode maître agent : notification système, jamais bloquante.
# Usage : notify.sh agent|blocked|quota [texte]
#   agent   : fin d'un sous-agent (JSON de SubagentStop sur l'entrée standard) -> « nom : statut »
#   blocked : hook Notification (permission_prompt, idle_prompt) -> le message reçu
#   quota   : texte donné en argument (alertes 70 / 80 / 90 % de statusline.sh)
# Désactivable : fichier ~/.claude/maitre-agent/notifications-off
# Test sans notifier : MAITRE_AGENT_DRY_RUN=1 (affiche au lieu de notifier).
kind="$1"
[ "$#" -gt 0 ] && shift
txt="$*"
case "$kind" in agent|blocked|quota) ;; *) exit 0 ;; esac
[ -e "$HOME/.claude/maitre-agent/notifications-off" ] && exit 0

# 80 caractères au plus (jq compte en caractères, pas en octets)
cut80() { printf '%s' "$1" | jq -Rrs 'gsub("[\r\n]+";" ") | if length > 80 then .[0:79] + "…" else . end' 2>/dev/null; }

title="Maître agent"
case "$kind" in
  agent)
    title="Maître agent : agent terminé"
    if [ -z "$txt" ] && [ ! -t 0 ] && command -v jq >/dev/null 2>&1; then
      in=$(cat 2>/dev/null) || in=""
      # nom = agent_type sans le préfixe de plugin ; un agent interne (type vide) ne notifie pas
      txt=$(printf '%s' "$in" | jq -r '
        ((.agent_type // "") | sub("^.*:";"")) as $n
        | ((.last_assistant_message // "") | split("\n") | map(select(test("\\S"))) | (.[0] // "") | sub("^[#>*\\s-]+";"") | sub("\\s+$";"")) as $s
        | if $n == "" then "" elif $s == "" then $n else $n + " : " + $s end' 2>/dev/null) || txt=""
    fi
    ;;
  blocked)
    title="Maître agent : Claude attend"
    if [ -z "$txt" ] && [ ! -t 0 ] && command -v jq >/dev/null 2>&1; then
      in=$(cat 2>/dev/null) || in=""
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
fi

if [ "${MAITRE_AGENT_DRY_RUN:-}" = 1 ]; then
  printf '[notification] %s | %s\n' "$title" "$txt"
  exit 0
fi
# Le texte passe en argument d'AppleScript (jamais collé dans le script) : pas d'injection.
case "$(uname -s 2>/dev/null)" in
  Darwin)
    command -v osascript >/dev/null 2>&1 && \
      ( osascript -e 'on run argv' -e 'display notification (item 1 of argv) with title (item 2 of argv)' -e 'end run' "$txt" "$title" >/dev/null 2>&1 & )
    ;;
  Linux)
    command -v notify-send >/dev/null 2>&1 && \
      ( notify-send "$title" "$txt" >/dev/null 2>&1 & )
    ;;
esac
exit 0
