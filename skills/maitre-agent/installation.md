# Installation : trois voies, puis réglages facultatifs

Seulement avec l'accord explicite de l'utilisateur : c'est de la configuration persistante. Lis d'abord les fichiers existants et fusionne, sans jamais écraser.

## 0. Choisir une voie
| Voie | Ce que tu obtiens | Ce qu'elle ne fait pas |
|---|---|---|
| A. Plugin (marketplace GitHub) | skill (lancé seulement par `/maitre-agent`), 5 agents `ma-*`, compteur d'agents, notifications de fin d'agent, réinjection après résumé ; mises à jour par version | pas de barre d'état ni de `permissions.ask` (voir §4 et §2) |
| B. Copie du skill | le skill seul dans `~/.claude/skills/` ; tout le reste à la main (§1 à §5) | rien d'automatique |
| C. Zip de release | `maitre-agent-skill-v<version>.zip` (skill seul, comme B) ou `maitre-agent-plugin-v<version>.zip` (plugin complet) | idem A ou B selon le zip |

### Voie A : plugin
- Dans une session : `/plugin marketplace add MalikMoussaoui/maitre-agent`, puis `/plugin install maitre-agent@maitre-agent`. En une fois : `/plugin install maitre-agent --marketplace MalikMoussaoui/maitre-agent` (Claude Code 2.1.275 ou plus).
- En shell : `claude plugin marketplace add MalikMoussaoui/maitre-agent`, puis `claude plugin install maitre-agent@maitre-agent`. Pour épingler une version : `MalikMoussaoui/maitre-agent#v1.1.0`.
- App de bureau : + > Plugins > Add plugin, sur les marketplaces déjà configurées. Comment y ajouter une source GitHub n'est pas documenté (non vérifié) : repli, dans `~/.claude/settings.json`, `"extraKnownMarketplaces": { "maitre-agent": { "source": { "source": "github", "repo": "MalikMoussaoui/maitre-agent" } } }`.
- Pas de plugins dans les sessions cloud.
- Les hooks du plugin sont actifs dès son chargement, dans toutes les sessions (voir §3 pour éviter un doublon, §5 pour les notifications). Prérequis des hooks et des scripts : macOS ou Linux, et `jq`.

### Voie B : copie du skill
- Depuis une copie du dépôt : `cp -R skills/maitre-agent ~/.claude/skills/` (dossier `~/.claude/skills/maitre-agent/` avec `SKILL.md` dedans). Nouvelle session ensuite.

### Voie C : zip de release
- Page des releases du dépôt. Skill seul : `unzip maitre-agent-skill-v<version>.zip -d ~/.claude/skills/` (le zip contient le dossier `maitre-agent/`). Plugin complet (les fichiers sont à la racine du zip) : `unzip maitre-agent-plugin-v<version>.zip -d maitre-agent-plugin`, puis `claude --plugin-dir maitre-agent-plugin` pour l'essayer, ou donne l'URL du zip à `--plugin-url` (disposition attendue du zip : non vérifié).

### Nom de la commande
- Via le plugin : `/maitre-agent:maitre-agent`. Le nom court `/maitre-agent` marche aussi tant qu'aucun autre skill ne le prend.
- Via la copie du skill (voies B et C) : `/maitre-agent`.
- Un skill personnel et un skill de plugin de même nom se chargent tous les deux : n'installe pas le skill par les deux voies.

## 1. Sous-agents (`SKILL_DIR/agents/` → `~/.claude/agents/`), voies B et C seulement
- `ma-chercheur` (intermédiaire), `ma-auditeur` (intermédiaire, lecture seule sauf son fichier), `ma-testeur` (intermédiaire), `ma-concepteur` (le plus capable), `ma-executant` (hérite du modèle demandé).
- Points communs : sans l'outil Agent (pas de sous-agents imbriqués), un plafond de tours, et les règles stables de `briefs/_entete.md` dans le corps.
- Copie-les dans `~/.claude/agents/`. Si un fichier du même nom existe déjà, compare-le et demande avant de le remplacer.
- Ils sont disponibles dans les nouvelles sessions. Avec le plugin, ils s'appellent `maitre-agent:ma-chercheur`, etc., et sont déjà fournis : ne les copie pas en plus.
- Un agent de plugin ignore `permissionMode` et `hooks` (doc officielle) : ces agents n'en ont pas.

## 2. Demander avant les commandes risquées (`~/.claude/settings.json`, `permissions.ask`)
`Bash(git push *)`, `Bash(gh repo create *)`, `Bash(gh pr create *)`, `Bash(gh release create *)`, `Bash(npm publish *)`, `Bash(rm -rf *)`, `Bash(sudo *)`, `Bash(brew install *)`, `Bash(brew uninstall *)`, `Bash(kill *)`, `Bash(pkill *)`, `Bash(killall *)`.
Adapte la liste à l'OS (par exemple `winget install`, `apt install`). Ces règles valent aussi pour les sous-agents.
Un plugin ne peut pas installer de `permissions` : c'est toujours une copie à la main, même avec la voie A. Montre le diff avant d'écrire.

## 3. Rappel de reprise (hook `SessionStart`, matcher `compact|resume`)
- Copie `SKILL_DIR/hooks/reinject.sh` dans `~/.claude/maitre-agent/hooks/` et rends-le exécutable. Commande du hook : `~/.claude/maitre-agent/hooks/reinject.sh 2>/dev/null || true`, timeout 10.
- Après un résumé automatique ou une reprise, le script réinjecte les sections « Agents lancés » et « Reprise immédiate » de `docs/HANDOFF.md`. Sans HANDOFF, il ne fait rien.
- **Un seul endroit : dans `settings.json` OU dans le plugin, pas les deux.** Le plugin apporte déjà ce hook ; s'il est aussi dans `settings.json`, il s'exécute deux fois. Avec la voie A, saute ce paragraphe.
- Script POSIX (macOS, Linux, Git Bash) ; sous Windows sans bash, écris l'équivalent PowerShell.

## 4. Barre d'état (`statusLine`) : à la main, même avec le plugin
Un plugin ne peut pas fournir `statusLine` (seuls `agent` et `subagentStatusLine` sont pris en compte dans son `settings.json`).
1. Copie `SKILL_DIR/hooks/statusline.sh` et `SKILL_DIR/hooks/notify.sh` dans `~/.claude/maitre-agent/` (créé si besoin) et rends-les exécutables. Avec le plugin, le skill est déjà dans son cache : `cp ~/.claude/plugins/cache/maitre-agent/maitre-agent/*/hooks/statusline.sh ~/.claude/plugins/cache/maitre-agent/maitre-agent/*/hooks/notify.sh ~/.claude/maitre-agent/` (chemin **observé sur 2.1.299** après installation, `.../maitre-agent/maitre-agent/<version>/hooks/` ; non documenté, donc à vérifier avec `ls`). Il change à chaque version, d'où la copie : refais-la après une mise à jour.
2. Ajoute dans `~/.claude/settings.json`, après avoir montré le diff :
```json
"statusLine": {
  "type": "command",
  "command": "~/.claude/maitre-agent/statusline.sh",
  "refreshInterval": 10
}
```
3. Elle affiche : `🧭 <projet> · <jalon> · <n> agents · 5 h <x> % (reset HH:MM) · 7 j <y> %`. Jalon : la ligne `Jalon : …` de `docs/HANDOFF.md` (comme le mod de bureau), 40 caractères ; sans cette ligne, rien. Les caractères de contrôle du texte lu sont retirés. Sans quota dans le JSON reçu (forfait sans limite, avant la première réponse) : `quota ?`.
4. Le même script écrit `~/.claude/maitre-agent/usage.json` (jamais écrasé par du vide) et envoie une alerte aux seuils du réglage `seuils` (70, 80 et 90 % par défaut ; une fois par seuil et par remise à zéro). Aucun hook ne reçoit le quota : sans la barre d'état, pas d'alerte. **Le skill lit ce fichier** par `SKILL_DIR/hooks/quota.sh` (SKILL §6 : mesure valable si elle a moins de 15 min et si la fenêtre n'est pas terminée). Ce script est dans le dossier du skill, donc une copie du skill (voies B et C) le trouve aussi ; sa source est `tools/quota.sh` du dépôt. Test : `sh ~/.claude/skills/maitre-agent/hooks/quota.sh; echo $?` (0, ou le seuil atteint : 70, 80, 90 par défaut ; 2 = pas de mesure utilisable).
   Réglages (`reglages.md`) : ces scripts lisent eux-mêmes `seuils`, `notifications` et `barre` dans `~/.claude/maitre-agent/profil.md`, puis dans la rubrique « Réglages du projet » du `CLAUDE.md` du dossier courant. Rien à installer de plus ; sans ces lignes, les défauts ci-dessus.
5. Sans le plugin, le compteur d'agents a besoin des hooks (§5) ; sinon il reste à `0 agent`.
6. **App de bureau (onglet Code) : la barre d'état n'est pas affichée** (tickets anthropics/claude-code#41456 et #83534 ; un script témoin déclaré en `statusLine` n'a pas été appelé lors d'un test local du 2026-10-18). Installe à la place le plugin `maitre-agent-bureau` de la même marketplace : `/plugin install maitre-agent-bureau@maitre-agent` (voir le dossier `bureau/` du dépôt). Les hooks (§5) marchent aussi au bureau.

## 5. Compteur d'agents et notifications (hooks) : seulement sans le plugin
Le plugin les apporte (`hooks/hooks.json`). Sans plugin, copie `SKILL_DIR/hooks/agent-count.sh` dans `~/.claude/maitre-agent/`, rends-le exécutable, puis fusionne dans `~/.claude/settings.json` (diff montré avant) :
```json
"hooks": {
  "SubagentStart": [{ "hooks": [{ "type": "command", "command": "~/.claude/maitre-agent/agent-count.sh start || true", "timeout": 5 }] }],
  "SubagentStop": [
    { "hooks": [{ "type": "command", "command": "~/.claude/maitre-agent/agent-count.sh stop || true", "timeout": 5 }] },
    { "matcher": "^ma-", "hooks": [{ "type": "command", "command": "~/.claude/maitre-agent/notify.sh agent || true", "timeout": 10 }] }],
  "Notification": [{ "matcher": "permission_prompt|idle_prompt", "hooks": [{ "type": "command", "command": "~/.claude/maitre-agent/notify.sh blocked || true", "timeout": 10 }] }]
}
```
- Le compteur compte **tous** les sous-agents (aussi le repli `general-purpose`) ; seule la notification de fin est limitée aux `ma-*`.
- Notifications : `osascript` sous macOS, `notify-send` sous Linux s'il existe, rien ailleurs. **Fin d'agent `ma-*` et alertes de quota : actives par défaut. Notification « Claude attend » (hook `Notification`) : désactivée par défaut**, car elle se déclencherait dans toutes les sessions ; pour l'activer, crée `~/.claude/maitre-agent/notifications-on` (ou règle `notifications : tout`). Pour tout couper : crée `~/.claude/maitre-agent/notifications-off` (coupe tout, toujours ; ou règle `notifications : rien` ; utile au bureau, où l'app notifie déjà la fin d'une tâche : doublon possible). Pour tester sans rien afficher : `MAITRE_AGENT_DRY_RUN=1`.
- Aucun de ces scripts ne bloque : timeout court, `|| true`, sortie 0. Ils ont besoin de `jq`.
- Les compteurs vivent dans `~/.claude/maitre-agent/state/` et sont purgés après 5 h (la fenêtre de quota), dossiers vides compris.

## Vérification
- Frontmatter YAML valide pour chaque agent.
- JSON valide pour `settings.json`.
- Test du script de réinjection avec un faux HANDOFF ; test de la barre d'état en lui envoyant un JSON factice : `echo '{"cwd":"."}' | ~/.claude/maitre-agent/statusline.sh`.
- Plugin : `claude plugin validate <dossier> --strict` (ou `/plugin validate` en session).
- Note l'installation et sa date dans le profil (« Outils Claude »).
