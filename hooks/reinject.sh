#!/bin/sh
# Méthode maître agent : après un résumé automatique (compact) ou une reprise (resume),
# réinjecte les sections « Agents lancés » et « Reprise immédiate » de docs/HANDOFF.md, si le projet en a un.
dir="${CLAUDE_PROJECT_DIR:-$PWD}"
f="$dir/docs/HANDOFF.md"
[ -f "$f" ] || exit 0
echo "[maître agent] Rappel automatique depuis $f : relis HANDOFF et le disque avant de relancer quoi que ce soit."
awk '/^## /{p=($0 ~ /Agents lanc|Reprise imm/)} p' "$f" | head -60
