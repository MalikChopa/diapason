# Passation : <Nom du projet> (<AAAA-MM-JJ>)

Dernière visite : <AAAA-MM-JJ HH:MM> (mise à jour à chaque reprise)
Jalon : <jalon ou étape en cours, en quelques mots> (lu par la barre d'état)

Ordre de lecture : `CLAUDE.md`, ce fichier, `docs/research/INDEX.md`, puis <document de synthèse>.

## Reprendre
- Avec le skill : `/maitre-agent <chemin absolu du projet>`.
- Sans le skill : « Tu es le maître agent de ce projet. Lis CLAUDE.md puis docs/HANDOFF.md. Tu pilotes, tu délègues chaque tâche à un agent du modèle adapté, tu vérifies toi-même avant de dire que c'est fini, et tu rends compte court. Commence par "Reprise immédiate". »

Git : <SHA du dernier commit / pas de git>. Longueur visée : moins de 250 lignes ; l'ancienne passation est archivée dans `docs/handoffs/AAAA-MM-JJ.md` au lieu d'être écrasée.

## Demandes de l'utilisateur (mot pour mot)
- <citation exacte, date>

## État ([V] = vérifié maintenant, avec la commande ; [?] = non revérifié)
- Fait : <[V]/[?] …>
- Vérifié par le maître agent : <…>
- Non vérifié ou hypothèses : <…>
- Installé, acheté, publié : <rien / liste>

## Agents lancés
| Agent | Tâche | Modèle | Fichier de travail | Statut | Brief |
|---|---|---|---|---|---|
| <nom court> | <tâche> | <modèle> | <fichier> | en cours / terminé / arrêté / à reprendre | `docs/briefs/NN-<agent>.md` |

## Pistes échouées et pièges connus (ne jamais couper cette section)
- <ce qui a été essayé, pourquoi ça a échoué>

## Décisions et pistes abandonnées
- <AAAA-MM-JJ> : <décision ou abandon, avec la raison>

## Reprise immédiate (dans l'ordre)
1. Lire le quota et appliquer les seuils.
2. <prochaine tâche : agent, modèle, brief prêt dans docs/briefs/>

## En attente de l'utilisateur
- <question : argent, installation, publication, compte>

## Coûts mesurés
- <agents, tokens, part du quota, durée>

## Ce qui ne se transmet pas
L'historique de conversation, les agents en cours, la mémoire personnelle, les liens d'artifacts privés et les comptes externes : seuls les fichiers du projet comptent.
