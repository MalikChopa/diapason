# Brief : conception, synthèse ou correction (modèle le plus capable ; intermédiaire pour une correction simple)

## Mode conception ou synthèse
```
<bloc _entete.md>
Rôle : <architecte / auteur de la spécification / auteur de la synthèse>.
Entrées : docs/research/INDEX.md et les fichiers <NN…> (ne relance pas de recherche ; si une information manque, note-la dans « Points ouverts »).
Profil et contraintes : <ce qui compte : niveau de l'utilisateur, budget, plateformes, autonomie>.
Produis <docs/ARCHITECTURE.md | docs/SPEC.md | docs/PLAN.md | docs/RECOMMANDATION.md> avec :
- la décision en tête (3 raisons, le prix à payer) ;
- les options écartées et pourquoi ;
- <pour du logiciel : jalons J0…Jn, chacun avec des critères mesurables et la façon de les mesurer ; J0 = le plus petit squelette qui tourne>
- <pour une spec : valeurs chiffrées, scénarios concrets, cas limites, identifiants de paramètres stables>
- les risques et les points ouverts.
Taille visée : <N> mots au maximum. Pas de remplissage.
```

## Mode correction (après un audit)
```
<bloc _entete.md>
Rôle : correcteur. Seul écrivain de <document>.
Applique les points de <docs/X_AUDIT_N.md> classés bloquant et important. Pour chaque point : corrige, ou explique pourquoi tu ne corriges pas.
Ajoute en fin de document un « Journal des corrections » : numéro du point, ligne, ce qui a changé.
Ne change aucun identifiant de paramètre, ni rien qui n'est pas visé par l'audit.
```
