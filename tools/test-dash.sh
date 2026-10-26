#!/bin/sh
# Lance tests/hooks.sh avec dash comme « sh » des scripts testés (celui d'un runner Debian ou Ubuntu).
# Pourquoi : « dash tests/hooks.sh » ne change que l'interpréteur de la suite ; les scripts qu'elle lance par « sh <script> »
# tournent avec le sh du système (bash en mode POSIX sur macOS), qui accepte des choses que dash refuse ou traite autrement
# (par exemple une redirection ratée sur « : » arrête dash avec le code 2). Ici un lien « sh -> dash » passe en tête du PATH.
# Usage : sh tools/test-dash.sh      Sortie : celle de tests/hooks.sh (0 si tout passe). Écrit seulement dans un dossier temporaire.
ROOT=$(cd "$(dirname "$0")/.." && pwd)
D=$(command -v dash) || { echo "avert dash est absent : test sauté"; exit 0; }
T=$(mktemp -d 2>/dev/null) || { echo "ERR mktemp impossible"; exit 1; }
trap 'rm -rf "$T"' EXIT INT TERM
ln -s "$D" "$T/sh" || { echo "ERR lien impossible"; exit 1; }
PATH="$T:$PATH" "$T/sh" "$ROOT/tests/hooks.sh"
