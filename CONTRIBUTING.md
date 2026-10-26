# Contribuer à Diapason

🇬🇧 [English version](CONTRIBUTING.en.md)

Merci de ton intérêt. Le projet est petit : un skill Claude Code, cinq agents, quelques scripts `sh` POSIX et un mod de bureau. Pour comprendre comment les pièces s'emboîtent avant de modifier quoi que ce soit, lis [ARCHITECTURE.md](ARCHITECTURE.md).

## Proposer un changement
1. Ouvre une *issue* pour un bug, une idée ou une question, avec un exemple court et reproductible.
2. Pour une modification : fais un fork, crée une branche, puis ouvre une *pull request* qui dit quoi, pourquoi, et comment tu l'as vérifié.
3. Une PR = un sujet. Ne mélange pas correction, nouveauté et mise en forme.

## Organisation du dépôt (ce qui doit rester synchronisé)
- `skills/diapason/` : le skill lui-même. `SKILL.md` porte les règles ; les autres `.md` sont lus à la demande (`cadrage.md`, `phases.md`, `reprise.md`, `quota.md`, `reglages.md`, …), avec `briefs/` et `templates/` pour les agents et les fichiers de projet.
- `agents/` et `skills/diapason/agents/` : les cinq agents `dia-*`. Les deux copies doivent être **identiques à l'octet près** (le plugin utilise l'une, une installation « skill seul » l'autre).
- `hooks/` (hooks du plugin) et `tools/` (scripts du dépôt) sont les **sources** des scripts que porte `skills/diapason/hooks/` : après en avoir modifié un, recopie-le (`cp -p`). Le lint vérifie que chaque copie est identique à sa source.
- `tests/hooks.sh` : tests de tous les scripts, avec des JSON factices, un `HOME` jetable et aucun appel réseau.
- `evals/` : scénarios écrits pour vérifier le comportement du skill dans une vraie session (ils se jouent à la main, pas par un script).
- `bureau/` : le mod pour l'app de bureau (TypeScript). Ses tests se lancent avec `claude plugin test bureau` ; la suite de tests shell ne le couvre pas.

## Avant d'ouvrir une PR
Lance le contrôle du dépôt, il doit finir sans `ERR` :
```sh
LINT_SKIP_LOCAL=1 sh tools/lint-skill.sh
```
`LINT_SKIP_LOCAL=1` saute les contrôles de ton installation locale (`~/.claude`) : sans lui, des agents installés chez toi et différents de ceux du dépôt donneraient une `ERR` qui ne concerne pas ta PR. Pour tester aussi des motifs personnels à refuser, passe-les par l'environnement (`LINT_PRIVATE_PATTERNS='nom1|nom2'`) ; ne les écris jamais dans un fichier du dépôt.
Il vérifie le YAML des agents et du skill, la taille de `SKILL.md`, les renvois entre fichiers, la cohérence du plugin et de la marketplace, la copie des agents et des hooks, et l'absence de traces personnelles. La même commande tourne sur GitHub à chaque push.

Puis lance les tests, sous les deux interpréteurs :
```sh
sh tests/hooks.sh
sh tools/test-dash.sh
```
Ils demandent `jq` (sans lui, ils sont sautés avec un avertissement). Les deux doivent afficher `0 échec(s)`. Le second compte : `dash tests/hooks.sh` ne change que l'interpréteur qui lance la suite, alors que les scripts testés tournent avec le `sh` du système (bash sur macOS, dash sur Debian et Ubuntu, donc sur le runner GitHub). `tools/test-dash.sh` met un lien `sh -> dash` en tête du `PATH`, ce que fait réellement la CI. Un défaut de cette espèce (une redirection ratée sur `:` arrête dash avec le code 2) passait sur macOS et n'a été vu que par la CI. Ajoute un test pour chaque comportement que tu modifies, et vérifie qu'il échoue sur l'ancien code.

Les scripts restent en `sh` POSIX : pas de bashisme (`[[ ]]`, tableaux, `$((10#08))`), et ils doivent marcher sous macOS et Linux (attention à `sed -i`, `date -d` / `date -r`, `mktemp`).

## `SKILL.md` a un plafond de taille strict
Après un résumé automatique, Claude Code ne rend à un skill que ses 5 000 premiers tokens. `SKILL.md` est donc plafonné à **12 000 octets** (le lint échoue au-delà), avec la section « Permissions » avant l'octet 11 000 et la dernière section avant l'octet 12 000. Une règle nouvelle doit venir avec le retrait ou le raccourcissement d'une autre, ou aller dans un fichier annexe lu à la demande. Le texte interne du skill reste en anglais (moins cher en tokens) ; tout ce que voit l'utilisateur est dans la langue de son profil.

## Ajouter un réglage
Un réglage est une ligne `- clé : valeur` sous `## Réglages` du profil de l'utilisateur. Pour en ajouter un : `tools/reglages.sh` (la liste des clés, son défaut, ce qu'il attend, sa validation), le tableau de `skills/diapason/reglages.md`, les tableaux de réglages de `GUIDE.md` et `GUIDE.en.md`, et des tests (formes acceptées, formes refusées, défaut). Puis recopie le script dans `skills/diapason/hooks/`. Une clé que cite `SKILL.md` doit exister dans `reglages.md` (le lint le vérifie).

## Numéro de version (mainteneur)
Un numéro de version se change à deux endroits qui doivent rester égaux : `.claude-plugin/plugin.json` et `skills/diapason/VERSION` (lue par `maj.sh`, seule trace de version d'une copie « skill seul ») ; le mod de bureau a son propre `bureau/.claude-plugin/plugin.json`. Le lint refuse s'ils diffèrent. Un tag `v*` lance le workflow de release : lint, vérification que le tag égale la version de `plugin.json`, construction des deux zips (`tools/build-release.sh`), puis publication de la release avec la section correspondante du `CHANGELOG.md` comme notes.

## Revue de parcimonie (à chaque version)
Des consignes en plus ont un coût (tokens, attention) et ne valent que si elles ont servi. Avant de publier une version :
1. Tire 5 règles du corps de `skills/diapason/SKILL.md`, de préférence dans les sections les plus lourdes en octets (note la graine ou la méthode du tirage).
2. Pour chacune, retrouve son origine (ligne du CHANGELOG, incident, recherche) et son évaluation (`evals/`).
3. Sans origine ni évaluation, propose de la retirer ou de la fusionner dans une règle voisine ; sinon garde-la.
4. Note dans le CHANGELOG les 5 règles examinées et la décision pour chacune. Retirer une règle utile est le vrai risque : en cas de doute, garde et écris l'éval manquante.

## Règle absolue : aucune donnée personnelle
Aucun nom, email, identifiant, chemin absolu vers un dossier personnel (sous macOS, Linux ou Windows), nom de projet privé, capture ou journal de session réel dans le dépôt. Pour les chemins, utilise `~`, `$HOME` ou `${CLAUDE_PLUGIN_ROOT}` ; pour les tests et exemples, des données factices. Le lint refuse les chemins personnels, mais c'est à toi de relire ton diff.

## Honnêteté
Dans la documentation, n'écris « ça marche » que pour ce que tu as essayé, et dis comment. Le reste s'écrit « non testé ». Pareil pour les chiffres : un nombre ou une taille se recalcule par une commande, il ne se retient pas de mémoire.
