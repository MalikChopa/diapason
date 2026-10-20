#!/bin/sh
# Diapason : migration des données vers ~/.claude/diapason, depuis ~/.claude/majordome (v1.4) ou, à défaut,
# depuis ~/.claude/maitre-agent (v1.3 et avant). Copie sans rien écraser et sans rien supprimer : l'ancien dossier
# reste (le supprimer est le choix de l'utilisateur). Les sauvegarde-skill-* (copies du skill, lourdes) ne sont pas copiées.
# Ne modifie JAMAIS ~/.claude/settings.json : si un hook y pointe vers l'ancien dossier, le script affiche seulement
# le changement proposé (lignes « - » / « + »).
# - Aucun ancien profil.md (ni majordome ni maitre-agent) : ne fait rien, n'affiche rien, sortie 0.
# - ~/.claude/diapason/profil.md existe déjà : refuse de copier, le dit en une ligne, sortie 0 (rien n'est écrasé).
# - Une copie échoue : sortie 1 (les fichiers déjà copiés restent, les autres sont à refaire).
# Aucun appel réseau.
CLAUDE="$HOME/.claude"
NEW="$CLAUDE/diapason"
SRC=""
for d in majordome maitre-agent; do
  if [ -f "$CLAUDE/$d/profil.md" ]; then SRC="$d"; break; fi
done
[ -n "$SRC" ] || exit 0
OLD="$CLAUDE/$SRC"
if [ -f "$NEW/profil.md" ]; then
  echo "Rien copié : ~/.claude/diapason/profil.md existe déjà (le script n'écrase rien). L'ancien dossier ~/.claude/$SRC est intact."
  exit 0
fi
mkdir -p "$NEW" || { echo "Échec : impossible de créer ~/.claude/diapason." >&2; exit 1; }
LIST="${TMPDIR:-/tmp}/diapason-migrer.$$"
trap 'rm -f "$LIST"' EXIT HUP INT TERM
# find + cp -p (POSIX) : « cp -n » n'est pas dans POSIX ; un fichier déjà présent dans le nouveau dossier est gardé tel quel
(cd "$OLD" && find . -path './sauvegarde-skill-*' -prune -o -type f -print) > "$LIST" || { echo "Échec : lecture de ~/.claude/$SRC impossible." >&2; exit 1; }
n=0; fail=0
while IFS= read -r f; do
  if [ ! -e "$NEW/$f" ]; then
    if mkdir -p "$NEW/$(dirname "$f")" && cp -p "$OLD/$f" "$NEW/$f"; then n=$((n + 1)); else fail=$((fail + 1)); echo "Échec de copie : $f" >&2; fi
  fi
done < "$LIST"
[ "$fail" -eq 0 ] || { echo "Migration incomplète : $fail fichier(s) non copié(s), $n copié(s). Rien n'a été supprimé." >&2; exit 1; }
echo "Données copiées de ~/.claude/$SRC vers ~/.claude/diapason ($n fichiers ; les sauvegarde-skill-* ne sont pas copiées). L'ancien dossier est gardé : tu peux le supprimer quand tu veux. Les scripts copiés (hooks/, tools/) sont d'anciennes versions : recopie ceux de Diapason (installation.md, §3 à §6)."
S="$CLAUDE/settings.json"
if [ -f "$S" ] && grep -q "\.claude/$SRC/" "$S"; then
  echo "settings.json n'est PAS modifié. Changement proposé (à appliquer toi-même, ou à faire valider) :"
  grep -n "\.claude/$SRC/" "$S" | while IFS= read -r l; do
    num=${l%%:*}; txt=${l#*:}
    echo "  ligne $num"
    echo "  - $txt"
    echo "  + $(printf '%s' "$txt" | sed "s#\\.claude/$SRC/#.claude/diapason/#g")"
  done
fi
exit 0
