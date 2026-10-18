# Contribuer à maitre-agent

Merci de ton intérêt. Le projet est petit : un skill Claude Code, cinq agents, quelques scripts `sh` et un mod de bureau.

## Proposer un changement
1. Ouvre une *issue* pour un bug, une idée ou une question, avec un exemple court et reproductible.
2. Pour une modification : fais un fork, crée une branche, puis ouvre une *pull request* qui dit quoi, pourquoi, et comment tu l'as vérifié.
3. Une PR = un sujet. Ne mélange pas correction, nouveauté et mise en forme.

## Avant d'ouvrir une PR
Lance le contrôle du dépôt, il doit finir sans `ERR` :
```sh
LINT_SKIP_LOCAL=1 sh tools/lint-skill.sh
```
`LINT_SKIP_LOCAL=1` saute les contrôles de ton installation locale (`~/.claude`) : sans lui, des agents installés chez toi et différents de ceux du dépôt donneraient une `ERR` qui ne concerne pas ta PR. Pour tester aussi des motifs personnels à refuser, passe-les par l'environnement (`LINT_PRIVATE_PATTERNS='nom1|nom2'`) ; ne les écris jamais dans un fichier du dépôt.
Il vérifie le YAML des agents et du skill, la taille de `SKILL.md`, les renvois entre fichiers, la cohérence du plugin et de la marketplace, la copie des agents et des hooks, et l'absence de traces personnelles. La même commande tourne sur GitHub à chaque push.

Si tu modifies un script de `hooks/`, la copie dans `skills/maitre-agent/hooks/` doit rester identique (le lint le vérifie). Les scripts restent en `sh` POSIX, sans bashisme, et doivent marcher sous macOS et Linux.

## Règle absolue : aucune donnée personnelle
Aucun nom, email, identifiant, chemin absolu vers un dossier personnel (sous macOS, Linux ou Windows), nom de projet privé, capture ou journal de session réel dans le dépôt. Pour les chemins, utilise `~`, `$HOME` ou `${CLAUDE_PLUGIN_ROOT}` ; pour les tests et exemples, des données factices. Le lint refuse les chemins personnels, mais c'est à toi de relire ton diff.

## Honnêteté
Dans la documentation, n'écris « ça marche » que pour ce que tu as essayé, et dis comment. Le reste s'écrit « non testé ».

## In English (short)
- Open an issue first, then a pull request: one topic per PR, say what changed and how you checked it.
- Run `LINT_SKIP_LOCAL=1 sh tools/lint-skill.sh` before pushing; it must print no `ERR` (the variable skips the checks of your local `~/.claude` installation).
- No personal data in the repository (names, emails, home paths, private project names); use dummy data for examples. Say "not tested" when something was not tested.
