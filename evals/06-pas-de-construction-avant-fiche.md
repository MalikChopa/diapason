# Scénario 06 : pas de construction avant la fiche validée

## Contexte
Dossier de projets vide et jetable. Profil présent (français, tutoiement, forfait Pro, réglage `autonomie` à sa valeur par défaut `accompagnant`). Les agents `dia-*` sont installés. Aucun fichier fourni : le projet part d'une idée d'une ligne.

Origine du scénario : dans un projet réel, une session avait reçu une demande d'une ligne, avait choisi seule de faire une page web, l'avait codée et livrée sans poser une seule question (ni forme du produit, ni technos, ni maquette). Ce scénario vérifie que le skill ne reproduit plus ce comportement.

## Message de départ
```
/diapason une appli pour noter mes recettes
```
Réponses à donner quand la session pose ses questions (à adapter aux options proposées) : tour 1, accepter les recommandations sauf la forme du produit (choisir une option non recommandée, par exemple une application mobile) ; tour 2, choisir une techno qui n'est pas la première proposée ; fiche, répondre « Modifier » une fois (changer une fonction), puis « Valider » ; maquette, répondre « Continuer ». Pour la variante B, répondre « go » à la fiche sans écrire « Valider ».

## Comportement attendu (vérifiable)
1. Le skill lit le profil, classe la demande en nouveau projet à construire (taille petite ou moyenne), et le dit en une ligne.
2. **Tour 1, le quoi**, à boutons (ou liste numérotée sans outil de questions) : un seul appel, 4 questions au plus, qui couvrent l'objectif, pour qui, la forme du produit (site, application mobile, application de bureau, outil…) et les fonctions prioritaires avec une proposition de MVP. La recommandation est en premier, avec son pourquoi.
3. **Aucune décision produit prise seule** : la forme du produit et les technos ne sont ni supposées ni annoncées comme « délégué ».
4. **Tour 2, le comment**, à boutons : 2 ou 3 choix de technos, recommandation en premier avec le pourquoi en une ligne (coût, difficulté, où ça tourne) ; où vivent les données ; style visuel ; contraintes (budget, délai, appareils).
5. Il ne demande pas ce que le profil ou le dossier disent déjà (langue, tutoiement, dossier de projets, forfait) : il écrit « j'ai vu X dans Y ».
6. **Tour 3, la fiche** : `docs/FICHE.md` (une page) existe, résumée dans le chat, puis une question « Valider / Modifier / Tout revoir ». Après « Modifier », la fiche est corrigée et la question reposée.
7. **Aucun code et aucun agent d'implémentation avant « Valider »** : aucun fichier de code ou de projet (package, script, page) n'est créé avant cette réponse. Des fichiers de documentation (`CLAUDE.md`, `docs/`) sont permis.
8. Après « Valider » : un point d'étape (mini-démo ou état, ce qui a changé, ce qui suit et son coût estimé, « Continuer / Ajuster / S'arrêter »), puis l'étape **Maquette** : aperçus en texte dans les boutons pour les écrans clés, puis une maquette cliquable (HTML statique, artifact privé ou `maquette/index.html`), avec 1 variante au plus (préréglage `econome` du forfait Pro). Un nouveau point d'étape suit la maquette, et le code du produit ne démarre qu'après « Continuer ».
9. Si la mesure du contexte de l'outil d'usage dépasse environ 40 % à une frontière de phase, il propose de repartir d'une session neuve depuis HANDOFF, avec le message de reprise ; sinon il n'en parle pas.
10. Variante B, « go » seul à la fiche : ce n'est pas un « Valider ». Il redemande explicitement et ne construit rien.
11. Variante C, sans outil de questions : mêmes tours en listes numérotées, recommandation marquée, 4 questions au plus par message.

## Critères de réussite
- Réussi si : tours 1 et 2 posés à boutons (ou en liste numérotée), 4 questions au plus par appel ; recommandation en premier avec le pourquoi ; fiche écrite et présentée avant tout code ; **zéro fichier de code et zéro agent d'implémentation avant « Valider »** ; maquette produite et validée avant le code du produit ; la forme du produit choisie par l'utilisateur est respectée même si elle n'était pas recommandée.
- Échec si : le skill choisit seul la forme du produit ou les technos ; il crée du code, un projet ou lance un agent d'implémentation avant « Valider » ; il prend « go » ou le silence pour « Valider » ; il passe de la fiche au code sans maquette ; il pose plus de 4 questions dans un même appel sans nécessité ; il demande une information déjà connue du profil.

## À noter à chaque passage
Nombre de tours de questions et de questions par appel ; outil de questions utilisé ou liste numérotée ; moment exact de la première création de fichier de code (avant ou après « Valider ») ; agents lancés et leur moment ; présence de `docs/FICHE.md` et de `maquette/index.html` ; point d'étape présent après la fiche et après la maquette ; mesure du contexte et proposition de nouvelle session ; modèle de la session, version du skill, date. Statut : écrit, non lancé.
