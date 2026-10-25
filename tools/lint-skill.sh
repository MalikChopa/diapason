#!/bin/sh
# Contrôle du dépôt diapason (skill + plugin).
# Usage : sh tools/lint-skill.sh [dossier du skill]     (défaut : skills/diapason du dépôt)
# Variables facultatives :
#   LINT_PRIVATE_PATTERNS  motifs personnels à refuser partout dans le dépôt (expression régulière
#                          étendue, ex. 'nom1|nom2'). À passer par l'environnement : ne les écris
#                          JAMAIS dans un fichier du dépôt.
#   LINT_SKIP_LOCAL=1      saute les contrôles de l'installation locale (~/.claude).
# Sortie 0 si tout est bon, 1 sinon. Les lignes « avert » n'échouent pas.
ROOT=$(cd "$(dirname "$0")/.." && pwd)
S="${1:-$ROOT/skills/diapason}"
err=0
ok(){ echo "ok   $1"; }; ko(){ echo "ERR  $1"; err=1; }; wa(){ echo "avert $1"; }

# 1. Frontmatter YAML (SKILL.md + agents du skill + agents/ du plugin) avec un parseur strict
yaml_ok() {
  if command -v ruby >/dev/null 2>&1; then
    LANG=en_US.UTF-8 ruby -Eutf-8 -ryaml -e 's=File.read(ARGV[0], encoding: "UTF-8"); fm=s[/\A---\n(.*?)\n---\n/m,1] or abort("pas de frontmatter"); h=YAML.safe_load(fm); abort("name manquant") unless h["name"]' "$1" 2>/dev/null
  else # repli sans ruby : contrôle simple
    [ "$(head -n 1 "$1")" = "---" ] && sed -n '2,/^---$/p' "$1" | grep -q '^name:'
  fi
}
command -v ruby >/dev/null 2>&1 || wa "ruby absent : contrôle YAML simplifié"
for f in "$S/SKILL.md" "$S"/agents/*.md "$ROOT"/agents/*.md; do
  [ -f "$f" ] || continue
  yaml_ok "$f" && ok "YAML ${f#"$ROOT"/}" || ko "YAML ${f#"$ROOT"/}"
done

# 2. Taille de SKILL.md : < 500 lignes, et sous le plafond de réinjection après un résumé automatique
#    (doc officielle : les 5 000 premiers tokens d'un skill invoqué). Mesuré le 2026-10-20 : ~2,4 à 2,5 octets
#    par token pour ce texte (get_usage avant/après), pas 3,3 : plafond en octets = 5 000 x 2,4 = 12 000.
#    Les règles critiques (§5 Permissions) doivent aussi commencer avant l'octet 11 000, et la dernière section avant 12 000.
LINT_SKILL_MAX_BYTES="${LINT_SKILL_MAX_BYTES:-12000}"
l=$(wc -l < "$S/SKILL.md"); b=$(wc -c < "$S/SKILL.md" | tr -d ' '); t=$(( b * 10 / 24 ))
[ "$l" -lt 500 ] && ok "SKILL.md $l lignes" || ko "SKILL.md $l lignes (>= 500)"
[ "$b" -le "$LINT_SKILL_MAX_BYTES" ] && ok "SKILL.md $b octets (~$t tokens, plafond de réinjection 5000 = $LINT_SKILL_MAX_BYTES octets)" || ko "SKILL.md $b octets (~$t tokens) > $LINT_SKILL_MAX_BYTES : la fin serait coupée après un résumé automatique"
off5=$(grep -bo '^## 5\. ' "$S/SKILL.md" | head -n 1 | cut -d: -f1)
offlast=$(grep -bo '^## ' "$S/SKILL.md" | tail -n 1 | cut -d: -f1)
[ -n "$off5" ] && [ "$off5" -lt 11000 ] && ok "SKILL.md : §5 Permissions commence à l'octet $off5 (< 11000)" || ko "SKILL.md : §5 Permissions absente ou après l'octet 11000 (${off5:-?})"
[ -n "$offlast" ] && [ "$offlast" -lt "$LINT_SKILL_MAX_BYTES" ] && ok "SKILL.md : dernière section à l'octet $offlast" || ko "SKILL.md : dernière section après l'octet $LINT_SKILL_MAX_BYTES"

# 2c. Cohérence du corps avec les fichiers lus à la demande
# (c) §5 de SKILL.md et les règles des agents (briefs/_entete.md) citent les mêmes interdits
for kw in captcha anti-bot DRM paywall anti-cheat 'git push'; do
  grep -q -- "$kw" "$S/SKILL.md" && grep -q -- "$kw" "$S/briefs/_entete.md" && ok "§5 et _entete.md citent « $kw »" || ko "§5 (SKILL.md) et briefs/_entete.md ne citent pas tous deux « $kw »"
done
# (d) chaque clé de réglage citée entre accents graves dans SKILL.md existe dans reglages.md
for k in seuils budget-lot agents-paralleles autonomie modeles rapports prereglage; do
  grep -q "\`$k\`" "$S/SKILL.md" || continue
  grep -q "\`$k\`" "$S/reglages.md" && ok "clé de réglage $k connue de reglages.md" || ko "clé de réglage $k citée dans SKILL.md mais absente de reglages.md"
done
# (e) chaque renvoi « §N » de SKILL.md pointe une section existante
for n in $(grep -o '§[0-9]' "$S/SKILL.md" | tr -d '§' | sort -u); do
  grep -q "^## $n\. " "$S/SKILL.md" && ok "renvoi §$n" || ko "renvoi §$n sans section « ## $n. » dans SKILL.md"
done

# 2b. Le skill ne se charge que sur commande explicite
grep -q '^disable-model-invocation: true' "$S/SKILL.md" && ko "SKILL.md : disable-model-invocation casse le lancement par une autre session" || ok "SKILL.md : lancement par l'outil Skill possible"

# 3. Chaque fichier cité existe : briefs/templates/agents/hooks, annexes du skill (commandes.md…),
#    et tout nom de document du skill cité seul (minuscules, ex. phases.md)
for r in $(grep -ohE '(briefs|templates|agents|hooks)/[A-Za-z_-]+\.(md|sh)' "$S"/*.md "$S"/briefs/*.md | sort -u); do
  [ -f "$S/$r" ] && ok "renvoi $r" || ko "renvoi cassé $r"
done
# noms seuls en minuscules ; « profil » est le profil de l'utilisateur, hors du dépôt
for r in $(grep -ohE '(^|[ `(])[a-z][a-z-]*\.md' "$S"/*.md "$S"/briefs/*.md | sed 's/^[ `(]//' | sort -u); do
  case "$r" in profil.md) continue ;; esac
  [ -f "$S/$r" ] && ok "renvoi $r" || ko "renvoi cassé $r"
done

# 4. Aucune trace personnelle dans tout le dépôt hors .git (fichiers suivis ou non ignorés)
if git -C "$ROOT" rev-parse --git-dir >/dev/null 2>&1; then
  files=$(git -C "$ROOT" ls-files -co --exclude-standard 2>/dev/null)
else
  files=$(cd "$ROOT" && find . -type f -not -path './.git/*' -not -path './dist/*' | sed 's|^\./||')
fi
GENERIC='/Users/[A-Za-z]|/home/[A-Za-z]|[A-Za-z]:\\Users\\'
bad=0
# ce script contient les motifs génériques : il ne se scanne pas lui-même
scan() { # $1 motif ; liste les fichiers qui le contiennent
  printf '%s\n' "$files" | while IFS= read -r f; do
    [ -f "$ROOT/$f" ] || continue
    [ "$f" = "tools/lint-skill.sh" ] && continue
    grep -IiEq -e "$1" "$ROOT/$f" 2>/dev/null && echo "$f"
  done
}
g=$(scan "$GENERIC"); [ -n "$g" ] && { bad=1; ko "chemin personnel (/Users/…, /home/…) dans : $(echo $g)"; }
if [ -n "$LINT_PRIVATE_PATTERNS" ]; then
  p=$(scan "$LINT_PRIVATE_PATTERNS"); [ -n "$p" ] && { bad=1; ko "motif personnel (LINT_PRIVATE_PATTERNS) dans : $(echo $p)"; }
else
  wa "LINT_PRIVATE_PATTERNS non défini : seuls les motifs génériques sont contrôlés"
fi
[ "$bad" -eq 0 ] && ok "aucune trace personnelle ($(printf '%s\n' "$files" | grep -c .) fichiers)"

# 5. JSON valides et cohérents (plugin.json, marketplace.json, hooks.json)
json_ok() {
  if command -v jq >/dev/null 2>&1; then jq -e . "$1" >/dev/null 2>&1
  else python3 -I -c "import json,sys;json.load(open(sys.argv[1]))" "$1" 2>/dev/null; fi
}
for j in .claude-plugin/plugin.json .claude-plugin/marketplace.json hooks/hooks.json; do
  if [ -f "$ROOT/$j" ]; then json_ok "$ROOT/$j" && ok "JSON $j" || ko "JSON invalide $j"
  else ko "fichier manquant $j"; fi
done
if command -v jq >/dev/null 2>&1; then
  P="$ROOT/.claude-plugin/plugin.json"; M="$ROOT/.claude-plugin/marketplace.json"; H="$ROOT/hooks/hooks.json"
  if [ -f "$P" ]; then
    jq -e '.name == "diapason" and (.version | type == "string")' "$P" >/dev/null 2>&1 && ok "plugin.json : nom et version" || ko "plugin.json : nom ou version"
    jq -e 'has("statusLine") or has("permissions") | not' "$P" >/dev/null 2>&1 && ok "plugin.json : ni statusLine ni permissions" || ko "plugin.json contient statusLine ou permissions (ignorés par Claude Code)"
    v=$(jq -r '.version' "$P")
    if [ -f "$ROOT/CHANGELOG.md" ]; then grep -q "$v" "$ROOT/CHANGELOG.md" && ok "CHANGELOG.md cite la version $v" || ko "CHANGELOG.md ne cite pas la version $v"; fi
  fi
  if [ -f "$M" ]; then
    for src in $(jq -r '.plugins[].source' "$M" 2>/dev/null); do
      [ -d "$ROOT/$src" ] && ok "marketplace : source $src" || wa "marketplace : source $src absente (mod de bureau pas encore écrit ?)"
    done
  fi
  if [ -f "$H" ]; then
    jq -e '.hooks | type == "object"' "$H" >/dev/null 2>&1 && ok "hooks.json : enveloppe \"hooks\"" || ko "hooks.json : enveloppe \"hooks\" manquante"
    for r in $(grep -oE 'hooks/[A-Za-z_-]+\.sh' "$H" | sort -u); do
      [ -f "$ROOT/$r" ] && ok "hooks.json -> $r" || ko "hooks.json cite $r, absent"
    done
  fi
fi
# agents du plugin : ni permissionMode ni hooks (ignorés dans un plugin)
for a in "$ROOT"/agents/*.md; do
  [ -f "$a" ] || continue
  if sed -n '2,/^---$/p' "$a" | grep -qE '^(permissionMode|hooks|mcpServers):'; then ko "agent de plugin avec champ ignoré : $(basename "$a")"; fi
done

# 6. Scripts : exécutables, shebang sh, syntaxe POSIX
for sc in "$ROOT"/hooks/*.sh "$ROOT"/tools/*.sh "$S"/hooks/*.sh; do
  [ -f "$sc" ] || continue
  n=${sc#"$ROOT"/}
  [ -x "$sc" ] && ok "exécutable $n" || ko "non exécutable $n"
  [ "$(head -n 1 "$sc")" = "#!/bin/sh" ] || ko "shebang différent de #!/bin/sh : $n"
  sh -n "$sc" 2>/dev/null || ko "syntaxe sh : $n"
  if command -v dash >/dev/null 2>&1; then dash -n "$sc" 2>/dev/null || ko "syntaxe dash (POSIX) : $n"; fi
done

# 7. Copies identiques : agents/ = agents du skill ; hooks/ = hooks du skill (pour ceux qui y sont)
for a in "$S"/agents/*.md; do
  n=$(basename "$a")
  [ -f "$ROOT/agents/$n" ] || { ko "agents/$n manquant (copie du skill)"; continue; }
  cmp -s "$a" "$ROOT/agents/$n" && ok "agents/$n identique au skill" || ko "agents/$n différent du skill"
done
for a in "$ROOT"/agents/*.md; do
  [ -f "$a" ] && [ ! -f "$S/agents/$(basename "$a")" ] && ko "agents/$(basename "$a") sans équivalent dans le skill"
done
# la source d'un script du skill est hooks/ (plugin) ou tools/ (quota.sh : outil du dépôt, copié dans le skill)
for h in "$S"/hooks/*.sh; do
  n=$(basename "$h")
  src="$ROOT/hooks/$n"; [ -f "$src" ] || src="$ROOT/tools/$n"
  [ -f "$src" ] || { ko "hooks/$n manquant (copie du skill)"; continue; }
  cmp -s "$h" "$src" && ok "${src#"$ROOT"/} identique au skill" || ko "${src#"$ROOT"/} différent du skill"
done

# 7b. VERSION du skill (lue par maj.sh, seule trace de version d'un « skill seul ») = version de plugin.json
if [ "$S" = "$ROOT/skills/diapason" ]; then
  pv=$(sed -n 's/.*"version"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' "$ROOT/.claude-plugin/plugin.json" | head -n 1)
  sv=$(head -n 1 "$S/VERSION" 2>/dev/null | tr -d ' \r')
  [ -n "$pv" ] && [ "$pv" = "$sv" ] && ok "VERSION du skill ($sv) = plugin.json" || ko "VERSION du skill [${sv:-absent}] différente de plugin.json [${pv:-?}]"
fi

# 8. Workflows GitHub : YAML valide
if command -v ruby >/dev/null 2>&1; then
  for w in "$ROOT"/.github/workflows/*.yml; do
    [ -f "$w" ] || continue
    ruby -ryaml -e 'YAML.safe_load(File.read(ARGV[0]))' "$w" 2>/dev/null && ok "YAML ${w#"$ROOT"/}" || ko "YAML invalide ${w#"$ROOT"/}"
  done
fi

# 9. Installation locale (seulement si elle existe)
if [ "${LINT_SKIP_LOCAL:-}" != 1 ]; then
  [ -f "$HOME/.claude/settings.json" ] && { json_ok "$HOME/.claude/settings.json" && ok "settings.json local valide" || ko "settings.json local invalide"; }
  for a in "$S"/agents/*.md; do
    n=$(basename "$a")
    [ -f "$HOME/.claude/agents/$n" ] && { cmp -s "$a" "$HOME/.claude/agents/$n" && ok "agent installé à jour $n" || ko "agent installé différent $n"; }
  done
fi

[ "$err" -eq 0 ] && echo "RÉSULTAT : tout est bon" || echo "RÉSULTAT : erreurs ci-dessus"
exit $err
