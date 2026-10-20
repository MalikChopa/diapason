#!/bin/sh
# Construit les deux zips de release dans dist/ :
#   dist/majordome-skill-v<version>.zip   le dossier skills/majordome seul (le zip contient « majordome/ »)
#   dist/majordome-plugin-v<version>.zip  le plugin complet (fichiers SUIVIS par git, à la racine du zip ; pense à « git add » les nouveaux), avec bureau/ s'il existe,
#                                            sans .git, dist, .claude, docs/briefs, docs/journal, docs/research, docs/README_AUDIT_*, docs/CRITIQUE_*, docs/chantiers, docs/AMELIORATIONS.md,
#                                            ni CLAUDE.md, docs/HANDOFF.md, docs/HANDOFF-archive.md (fichiers de travail du projet)
# Usage : sh tools/build-release.sh        (version lue dans .claude-plugin/plugin.json)
# Ne publie rien : la publication (gh release create) est une autre étape.
set -eu
ROOT=$(cd "$(dirname "$0")/.." && pwd)
cd "$ROOT"
command -v zip >/dev/null 2>&1 || { echo "ERR zip est absent" >&2; exit 1; }
if command -v jq >/dev/null 2>&1; then
  version=$(jq -r '.version' .claude-plugin/plugin.json)
else
  version=$(sed -n 's/.*"version"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' .claude-plugin/plugin.json | head -n 1)
fi
[ -n "$version" ] && [ "$version" != null ] || { echo "ERR version introuvable dans plugin.json" >&2; exit 1; }
mkdir -p dist
skill_zip="$ROOT/dist/majordome-skill-v$version.zip"
plugin_zip="$ROOT/dist/majordome-plugin-v$version.zip"
rm -f "$skill_zip" "$plugin_zip"

# 1. Le skill seul
(cd skills && zip -q -r -X "$skill_zip" majordome -x '*.DS_Store')

# 2. Le plugin complet : fichiers SUIVIS par git seulement (un .env ou des notes non suivis ne partent jamais), moins les exclusions
if git rev-parse --git-dir >/dev/null 2>&1; then
  list=$(git ls-files)
else
  list=$(find . -type f | sed 's|^\./||')
fi
list=$(printf '%s\n' "$list" | grep -vE '^(\.git/|dist/|\.claude/|docs/briefs/|docs/journal/|docs/research/|docs/README_AUDIT_|docs/CRITIQUE_|docs/chantiers/|docs/AMELIORATIONS\.md$|CLAUDE\.md$|docs/HANDOFF\.md$|docs/HANDOFF-archive\.md$)|(^|/)\.DS_Store$|(^|/)node_modules/' | sort)
printf '%s\n' "$list" | while IFS= read -r f; do [ -f "$f" ] && printf '%s\n' "$f"; done | zip -q -X "$plugin_zip" -@

for z in "$skill_zip" "$plugin_zip"; do
  echo "$(basename "$z") : $(unzip -Z1 "$z" | wc -l | tr -d ' ') fichiers, $(wc -c < "$z" | tr -d ' ') octets"
done
