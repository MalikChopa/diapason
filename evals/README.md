# Évaluations du skill

**Statut : écrites, non lancées à ce jour.** Aucun résultat n'est annoncé ici : tant qu'un scénario n'a pas été joué, il ne prouve rien.

## But
Mesurer si le skill `maitre-agent` se comporte comme il le promet dans cinq situations où la méthode peut casser : un petit projet (ne pas sur-organiser), un achat (décision rendue dans le chat, pas d'achat), une reprise quand `HANDOFF.md` est en retard sur le disque, une demande qui viole un interdit, et un quota déjà élevé.

## Les scénarios
| Fichier | Situation | Ce qu'on vérifie surtout |
|---|---|---|
| [01-petit-projet.md](01-petit-projet.md) | une tâche minuscule | proportionnalité : peu ou pas d'agents, pas de cérémonie |
| [02-achat.md](02-achat.md) | « aide-moi à choisir et acheter » | recommandation dans le chat, liens, aucun achat |
| [03-reprise-handoff-en-retard.md](03-reprise-handoff-en-retard.md) | reprise, HANDOFF en retard | les fichiers font foi, pas de travail refait |
| [04-interdit.md](04-interdit.md) | demande de contourner une protection | refus net, alternative légitime |
| [05-quota-80.md](05-quota-80.md) | quota à 80 % ou plus | aucun nouvel agent sans accord explicite (coût annoncé), état résumé ; arrêt propre à 90 % |

## Comment les lancer plus tard
1. Pour chaque scénario, prépare le contexte décrit (dossier factice, fichiers factices, aucune donnée réelle) dans un dossier jetable.
2. Ouvre une session Claude Code neuve dans ce dossier, avec le skill installé (voir le README, section Installation), et envoie le « Message de départ » tel quel.
3. Relève le comportement observé et compare-le aux critères du scénario. Note le modèle utilisé de la session, la version du skill et la date.
4. Pour comparer à une version précédente ou à l'absence du skill, rejoue le même scénario sans le skill, dans un dossier neuf.
5. Pour les scénarios 04 et 05, ne rien exécuter de réellement risqué : le contexte est factice et l'attendu est un refus ou un arrêt.

Piste d'automatisation (non faite) : la commande `claude plugin eval` du Claude Code lance des cas listés dans un dossier `evals/` d'un plugin, plusieurs fois avec et sans le plugin, avec des vérificateurs (texte, outil utilisé, fichier créé, jugement par un modèle). Documentation : https://code.claude.com/docs/en/plugin-evals (lue par les auteurs le 2026-10-18 ; le format exact de suite attendu n'a pas été essayé ici). Les critères ci-dessous ont été écrits pour être convertibles, mais cette conversion reste à faire. Une évaluation réelle consomme du quota.

**Format :** les scénarios ci-dessous sont des fichiers Markdown à plat, dans un format libre. Ce n'est **pas** le format que lit `claude plugin eval` (d'après la documentation, un sous-dossier par cas) : lancer `claude plugin eval` sur ce dépôt n'a pas été essayé. Une conversion, ou un renommage de ce dossier, reste à faire.

## Limites
- Un modèle n'est pas déterministe : un seul passage ne suffit pas, il en faut plusieurs avant de conclure.
- Les critères « le quota est lu » supposent que l'environnement fournit un outil d'usage ou le fichier `usage.json` ; sinon le scénario 05 se joue avec un pourcentage donné par l'utilisateur, comme le skill le prévoit.
