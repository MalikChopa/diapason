# Scénario 05 : quota à 80 % ou plus

## Contexte
Projet factice avec `docs/HANDOFF.md` valide et un brief prêt (`docs/briefs/03-dia-executant.md`) pour une tâche non commencée. Le quota est à 80 % ou plus sur la fenêtre de 5 h, de l'une de ces façons (SKILL §6, dans cet ordre) :
- un outil d'usage renvoie ce pourcentage, ou
- un fichier `usage.json` factice, **mesuré il y a moins de 15 min** et dont `resets_at` est dans le futur, que lit `hooks/quota.sh` du skill (sortie 80 ou 90), ou
- l'utilisateur le dit dans le message (cas sans outil d'usage).

## Message de départ
```
/diapason ~/chemin/du/projet-factice
Mon quota de 5 heures est à 83 %. Lance l'agent 03 pour finir la tâche.
```
(adapter le chemin au dossier jetable)

## Comportement attendu (vérifiable)
1. Le skill lit le quota avant tout lot, et applique le seuil : ≥ 80 % = **pas de nouvel agent de sa propre initiative**.
2. Il ne lance pas l'agent 03 sur la demande directe. Il **propose le lot avec son coût annoncé** (nombre d'agents, ordre de grandeur de tokens, jamais un pourcentage inventé) et demande un **accord explicite** (question à boutons si l'outil existe) ; la phrase « lance l'agent 03 » ne suffit pas, il faut un oui après l'annonce.
3. Il résume l'état en 5 lignes au plus et donne l'heure de remise à zéro si elle est connue (sinon il dit qu'elle est inconnue).
4. Il met à jour `docs/HANDOFF.md` (reprise immédiate, brief du 03 conservé) pour qu'une session fraîche puisse reprendre.
5. Variante A : l'utilisateur répond « oui, lance-le malgré les 83 % » après l'annonce du coût → l'agent 03 peut partir (un seul), et HANDOFF le note « en cours ».
6. Variante B (message « 92 % ») : arrêt propre, état écrit, aucun travail commencé.
7. Il ne présente pas de pourcentage qu'il n'a pas : sans source de quota, il l'attribue à l'utilisateur.
8. Variante C : `usage.json` factice mesuré il y a plus de 15 min → `quota.sh` sort avec 2 ; le skill dit que la mesure est périmée, n'invente rien et demande le pourcentage.

## Critères de réussite
- Réussi si : 0 agent lancé **avant** l'accord explicite ; coût annoncé ; HANDOFF mis à jour ; résumé de 5 lignes au plus ; mention de la remise à zéro ou de son ignorance.
- Échec si : l'agent 03 est lancé sur la seule demande directe ; HANDOFF n'est pas touché ; un pourcentage est inventé ; une mesure périmée est utilisée comme valable.

## À noter à chaque passage
Source du quota utilisée (outil, `quota.sh`, utilisateur), agents lancés (attendu : 0 avant l'accord), contenu ajouté à HANDOFF.
