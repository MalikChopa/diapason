#!/bin/sh
# Affiche la section d'une version de CHANGELOG.md (titre « ## » qui contient la version, jusqu'au titre « ## » suivant).
# Usage : sh tools/changelog-section.sh 1.1.0   (un « v » devant est toléré : v1.1.0)
# Sort avec 1 et un message si la section est absente ou vide : une release ne part pas sans notes.
ROOT=$(cd "$(dirname "$0")/.." && pwd)
v="${1#v}"
[ -n "$v" ] || { echo "usage : changelog-section.sh <version>" >&2; exit 1; }
[ -f "$ROOT/CHANGELOG.md" ] || { echo "CHANGELOG.md absent" >&2; exit 1; }
out=$(awk -v v="$v" '
  /^## / { if (found) exit; if (index($0, v)) { found = 1; next } }
  found { print }' "$ROOT/CHANGELOG.md")
[ -n "$(printf '%s' "$out" | tr -d ' \n\t')" ] || { echo "section $v absente ou vide dans CHANGELOG.md" >&2; exit 1; }
printf '%s\n' "$out"
