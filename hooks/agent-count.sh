#!/bin/sh
# Méthode Majordome : compteur d'agents en cours.
# Usage : agent-count.sh start|stop  (JSON du hook SubagentStart / SubagentStop sur l'entrée standard)
# Un fichier par agent_id dans ~/.claude/majordome/state/<session_id>/agents/ ;
# les fichiers de plus de 5 h (la fenêtre de quota) sont purgés, puis les dossiers vides. Jamais bloquant : sort toujours avec 0.
mode="$1"
case "$mode" in start|stop) ;; *) exit 0 ;; esac
[ -t 0 ] && exit 0
command -v jq >/dev/null 2>&1 || exit 0
in=$(cat 2>/dev/null) || in=""
[ -n "$in" ] || exit 0
SEP='|'   # séparateur visible : \001 est mal géré par le bash 3.2 de macOS (sh)
fields=$(printf '%s' "$in" | jq -r '[(.session_id // "" | tostring | gsub("[|]";"_")), (.agent_id // "" | tostring)] | join("|")' 2>/dev/null) || fields=""
IFS="$SEP" read -r sid aid <<EOT
$fields
EOT
# Noms de fichiers sûrs : on ne garde que lettres, chiffres, _ . -
sid=$(printf '%s' "$sid" | tr -c 'A-Za-z0-9_.-' '_')
aid=$(printf '%s' "$aid" | tr -c 'A-Za-z0-9_.-' '_')
case "$sid" in "") exit 0 ;; .*) sid="_$sid" ;; esac
case "$aid" in "") exit 0 ;; .*) aid="_$aid" ;; esac
# Dossier des données : ~/.claude/majordome s'il existe, sinon l'ancien ~/.claude/maitre-agent (v1.3 et avant), sinon ~/.claude/majordome
if [ -d "$HOME/.claude/majordome" ]; then BASE="$HOME/.claude/majordome"
elif [ -d "$HOME/.claude/maitre-agent" ]; then BASE="$HOME/.claude/maitre-agent"
else BASE="$HOME/.claude/majordome"; fi
STATE="$BASE/state"
dir="$STATE/$sid/agents"
umask 077
if [ "$mode" = start ]; then
  mkdir -p "$dir" 2>/dev/null || exit 0
  : > "$dir/$aid" 2>/dev/null || true
else
  rm -f "$dir/$aid" 2>/dev/null || true
fi
# Purge des compteurs de plus de 5 h (agent interrompu sans SubagentStop, session coupée), puis des dossiers vides
[ -d "$STATE" ] && find "$STATE" -path '*/agents/*' -type f -mmin +300 -exec rm -f {} + 2>/dev/null
[ -d "$STATE" ] && find "$STATE" -mindepth 1 -type d -empty -mmin +300 ! -path "$STATE/alerts" ! -path "$STATE/alerts/*" -delete 2>/dev/null
exit 0
