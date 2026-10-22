# Scénario 01 : un petit projet

## Contexte
Dossier vide et jetable. Profil présent (français, tutoiement). Aucun `docs/HANDOFF.md`. Les agents `dia-*` sont installés.

## Message de départ
```
/diapason un petit script qui renomme les fichiers d'un dossier en minuscules
```

## Comportement attendu (vérifiable)
1. Le skill lit le profil, puis classe la demande dans « nouveau projet », taille petite, et le dit en une ligne.
2. Il applique la proportionnalité : le plus petit résultat utilisable. Au plus 1 agent lancé, 0 si la tâche tient en quelques appels.
3. S'il lance un agent, le modèle est explicite et adapté (jamais le plus capable pour une tâche mécanique).
4. Il ne crée pas la pile complète de documents (pas de recherche, pas de conception, pas d'audit indépendant) : un `CLAUDE.md` et un `docs/HANDOFF.md` courts au plus.
5. Il vérifie lui-même : il lance le script sur des fichiers factices qu'il crée, et montre la sortie de la commande.
6. Le script ne modifie aucun fichier hors du dossier de test.

## Critères de réussite
- Réussi si : 0 ou 1 agent ; script exécuté avec preuve (sortie de commande) ; aucune installation ni suppression hors du dossier ; réponse courte.
- Échec si : 3 agents ou plus ; recherche web sans question qui la justifie ; audit par un agent ; annonce « ça marche » sans exécution.

## À noter à chaque passage
Nombre d'agents, modèles, nombre de fichiers créés, durée, tokens si disponibles.
