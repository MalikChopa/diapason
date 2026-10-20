#!/bin/sh
# Majordome : migration des données de la v1.3. Copie ~/.claude/maitre-agent vers ~/.claude/majordome
# sans rien écraser et sans rien supprimer (l'ancien dossier reste ; le supprimer est le choix de l'utilisateur).
# Condition : ~/.claude/majordome/profil.md absent ET ~/.claude/maitre-agent/profil.md présent.
# Sinon : ne fait rien, n'affiche rien. Sortie 0 ; 1 si une copie échoue. Aucun appel réseau.
OLD="$HOME/.claude/maitre-agent"
NEW="$HOME/.claude/majordome"
[ -f "$NEW/profil.md" ] && exit 0
[ -f "$OLD/profil.md" ] || exit 0
mkdir -p "$NEW" || exit 1
# find + cp -p (POSIX) : « cp -n » n'est pas dans POSIX ; un fichier déjà présent dans le nouveau dossier est gardé tel quel
n=$( (cd "$OLD" && find . -type f) | while IFS= read -r f; do
  if [ ! -e "$NEW/$f" ]; then
    mkdir -p "$NEW/$(dirname "$f")" && cp -p "$OLD/$f" "$NEW/$f" && echo x
  fi
done | wc -l | tr -d ' ')
echo "Données copiées de ~/.claude/maitre-agent vers ~/.claude/majordome ($n fichiers). L'ancien dossier est gardé : tu peux le supprimer quand tu veux."
exit 0
