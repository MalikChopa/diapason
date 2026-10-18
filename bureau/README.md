# maitre-agent-bureau

Mod pour l'app Claude de bureau (onglet Code). L'app n'appelle pas `statusLine` : ce mod donne par un autre chemin (les « function hooks » de Claude Code 2.1.299, API en accès anticipé) ce que la barre d'état du terminal affiche. Rien ne sort de la machine.

## Ce qu'il fait
1. **Ligne d'état** (`$.ui.status`), mise à jour à chaque changement de quota, au lancement d'un sous-agent et à la fin de chaque tour :
   `🧭 <projet> · <n> agents · 5 h <x> % (reset HH:MM) · 7 j <y> %`
   Le projet est le nom du dossier de la session. Sans quota connu : `quota ?`. Si `docs/HANDOFF.md` contient une ligne `Jalon : <texte>`, le jalon (40 caractères au plus) s'ajoute après le projet.
2. **Alertes de quota** : toast, et notification système si le canal existe (`$.ui.notify`), quand une fenêtre passe 70, 80 ou 90 %. Une fois par seuil et par fenêtre ; l'état est gardé dans le store du mod, donc aussi entre deux sessions.
3. **Fin d'un sous-agent `ma-*`** (ou `maitre-agent:ma-*`) : toast avec son nom et la première ligne de son rapport (le statut), 80 caractères au plus.

## Installer
Une fois le dépôt publié, dans l'app de bureau : le menu **+** puis **Plugins** permet d'ajouter un plugin des marketplaces déjà configurées ; comment y ajouter une source GitHub n'est pas documenté (non vérifié). Repli : déclarer la marketplace dans `~/.claude/settings.json` avec `"extraKnownMarketplaces": { "maitre-agent": { "source": { "source": "github", "repo": "MalikMoussaoui/maitre-agent" } } }`, puis ajouter le plugin `maitre-agent-bureau`. En terminal : `claude plugin install maitre-agent-bureau --marketplace MalikMoussaoui/maitre-agent`.

Pour essayer depuis un dossier local, sans installer : mettre le chemin absolu du dossier `bureau/` dans la variable `CLAUDE_CODE_PLUGIN_DIRS` (bloc `env` de `~/.claude/settings.json`) ; avec `CLAUDE_CODE_PLUGIN_DIR_WATCH=1`, un fichier enregistré recharge le mod à chaud.

## Vérifier
```sh
claude plugin validate bureau --strict
claude plugin test bureau
```
Les tests ne dessinent rien à l'écran : ils remplacent l'affichage par des enregistreurs et utilisent des données factices.

## Limites
- L'API des mods est en accès anticipé et peut changer d'une version à l'autre ; le mod est écrit pour Claude Code 2.1.299.
- L'API n'a pas d'événement « sous-agent terminé » : le mod écoute la fin du tour du sous-agent (`turn.complete` d'un `agentId`). Un agent relancé par un message donne un nouveau toast.
- Le nombre d'agents compte ceux qui sont `pending`, `running` ou `waiting` ; un agent `idle` n'est pas compté.
- `$.ui.notify` passe par le canal de notification du terminal de la personne ; dans l'onglet Code, son effet n'est pas vérifié (le toast, lui, est toujours émis).
- Le jalon vient d'une ligne `Jalon : ...` seulement ; sans elle, rien n'est affiché.
- Les alertes ne se répètent pas dans une même fenêtre ; elles repartent à zéro quand la date de reset change de plus de 30 minutes ou que le pourcentage retombe sous le seuil déjà signalé.
- Ligne d'état vue en réel dans l'onglet Code le 2026-10-18 (mod chargé à chaud depuis un dossier local), ainsi qu'un toast de fin d'agent ; l'effet de `$.ui.notify` dans l'onglet Code n'est pas vérifié. Les tests automatiques, eux, passent par le moteur, pas par l'écran.
