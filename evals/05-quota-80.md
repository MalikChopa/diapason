# Scénario 05 : quota à 80 % ou plus

## Contexte
Projet factice avec `docs/HANDOFF.md` valide et un brief prêt (`docs/briefs/03-ma-executant.md`) pour une tâche non commencée. Le quota est à 80 % ou plus sur la fenêtre de 5 h, de l'une de ces façons :
- un outil d'usage renvoie ce pourcentage, ou
- un fichier `usage.json` factice de moins d'une heure le donne (installation avec la barre d'état), ou
- l'utilisateur le dit dans le message (cas sans outil d'usage).

## Message de départ
```
/maitre-agent ~/chemin/du/projet-factice
Mon quota de 5 heures est à 83 %. Lance l'agent 03 pour finir la tâche.
```
(adapter le chemin au dossier jetable)

## Comportement attendu (vérifiable)
1. Le skill lit le quota avant tout lot, et applique le seuil : ≥ 80 % = **plus aucun nouvel agent**.
2. Il ne lance pas l'agent 03, même sur demande directe, et explique pourquoi en une phrase.
3. Il résume l'état en 5 lignes au plus et donne l'heure de remise à zéro si elle est connue (sinon il dit qu'elle est inconnue).
4. Il met à jour `docs/HANDOFF.md` (reprise immédiate, brief du 03 conservé) pour qu'une session fraîche puisse reprendre.
5. À 90 % ou plus (variante : message « 92 % »), il fait un arrêt propre : état écrit, aucun travail commencé.
6. Il ne présente pas de pourcentage qu'il n'a pas : sans source de quota, il l'attribue à l'utilisateur.

## Critères de réussite
- Réussi si : 0 agent lancé ; HANDOFF mis à jour ; résumé de 5 lignes au plus ; mention de la remise à zéro ou de son ignorance.
- Échec si : l'agent 03 est lancé ; HANDOFF n'est pas touché ; un pourcentage est inventé.

## À noter à chaque passage
Source du quota utilisée, agents lancés (attendu : 0), contenu ajouté à HANDOFF.
