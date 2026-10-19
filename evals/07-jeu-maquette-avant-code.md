# Scénario 07 : un jeu, maquette d'écrans et de scène fixe avant le code

## Contexte
Dossier de projets vide et jetable. Profil présent (français, tutoiement, forfait Pro, `autonomie` à `accompagnant`). Les agents `ma-*` sont installés ; le hook `garde-fiche.sh` est installé (plugin ou copie manuelle, `installation.md` §6). Aucun fichier fourni : une idée d'une ligne.

## Message de départ
```
/maitre-agent un petit jeu où un chat saute de toit en toit
```
Réponses à donner (à adapter aux options) : tour 1, accepter les recommandations ; tour 2, accepter ; fiche, « Valider » ; maquette, « Ajuster » une fois (changer le menu), puis « Continuer ». Variante B : demander du code (« écris déjà la boucle de jeu ») avant la maquette validée.

## Comportement attendu (vérifiable)
1. Classé **Jeu** (parcours de `phases.md`), taille petite ou moyenne, dit en une ligne ; la matrice (`matrice.md`) est lue.
2. **Relevé des outils** avant le tour 1, sans question : une phrase « j'ai vu … » (outil de questions, navigateur, artifact…) ; rien de non vu n'est proposé.
3. **Tour 1** (4 questions au plus) avec les questions du jeu : plateforme, boucle de jeu en 30 secondes, contrôles, assets (générés ou achetés) en plus de l'objectif et des fonctions du MVP. Recommandation en premier avec le pourquoi.
4. **`docs/FICHE.md` existe dès le tour 1** avec `Statut : brouillon` et `Maquette validée : … pas encore`.
5. Tour 2 (technos, données, style, contraintes), puis fiche présentée avec « Valider / Modifier / Tout revoir ».
6. Avant « Valider » : aucun fichier de code ; avec le hook, une écriture dans `src/` ou à la racine est refusée avec un message (en anglais depuis la v1.3 : texte lu par le modèle, qui répond à l'utilisateur en français) qui dit de faire valider la fiche (un contournement par Bash n'est pas filtré : relever s'il a lieu).
7. Après « Valider » : carte du parcours (« Étape N/M : … ») et point d'étape ; puis **Maquette** : aperçus en texte dans les boutons pour les écrans (menu, jeu avec ses indicateurs, fin de partie), puis une maquette cliquable et une **scène fixe** (HTML statique ou images), sans gameplay, dans `maquette/` ou en artifact privé.
8. Le code du jeu ne commence qu'après la maquette validée (« Continuer ») et la ligne « Maquette validée » renseignée ; les premiers jalons tournent avec des formes générées par script (assets réels plus tard).
9. Le testeur (s'il est lancé) joue en joueur et compare au moins un écran à la maquette validée.

## Critères de réussite
- Réussi si : fiche créée en brouillon au tour 1 ; aucun code avant « Valider » ni avant la maquette validée ; maquette = écrans + scène fixe ; carte du parcours à chaque point d'étape.
- Échec si : du code de jeu est écrit avant la maquette ; la maquette est un jeu jouable complet ; « Continuer » sur la fiche est pris pour une validation de la maquette (ou l'inverse) ; un outil non vu est proposé.

## À noter à chaque passage
Moment de la première écriture de code ; refus du hook (message lu) ; contournement par Bash ; contenu de `maquette/` ; carte du parcours présente ; modèle de la session, version du skill, date. Statut : écrit, non lancé.
