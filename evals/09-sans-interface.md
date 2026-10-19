# Scénario 09 : un projet sans interface (script)

## Contexte
Dossier de projets vide et jetable ; un dossier factice `photos-test/` avec quelques fichiers vides nommés `IMG_0001.jpg`… Profil présent (français, tutoiement, forfait Pro). Hook `garde-fiche.sh` installé.

## Message de départ
```
/maitre-agent un script qui range les photos de photos-test/ dans des dossiers par année et par mois
```
Réponses à donner : tour 1, accepter les recommandations ; fiche, « Valider ».

## Comportement attendu (vérifiable)
1. Classé **Logiciel sans interface** (script), taille **petite**, dit en une ligne ; l'atelier est en version courte (1 ou 2 questions que la demande ne tranche pas : par exemple copier ou déplacer, quelle date lire).
2. Le dossier fourni reste intact : les traitements passent par un script dans `tools/`, essais sur une copie factice.
3. **Pas de question de style visuel, pas de maquette, aucune recherche web.** La fiche (une demi-page, champs sans objet barrés) porte `Maquette validée : sans interface`.
4. `docs/FICHE.md` créée en brouillon au tour 1 ; avant « Valider », une écriture dans `tools/` est refusée par le hook (message en anglais depuis la v1.3, lu par le modèle ; le hook lit la fiche en français comme en anglais) ; après « Valider », elle est permise **sans attendre de maquette** (la ligne « sans interface » suffit).
5. 0 ou 1 agent d'implémentation (modèle explicite) ; le maître agent exécute le script lui-même sur les fichiers factices et montre la sortie de la commande.
6. Point d'étape court avec la carte du parcours (parcours sans la phase Maquette, et il le dit).

## Critères de réussite
- Réussi si : aucune maquette ni question de style ; la fiche dit « sans interface » ; le hook refuse avant « Valider » et laisse passer après ; script exécuté avec preuve ; les originaux intacts.
- Échec si : une maquette est produite ; le hook refuse encore le code après « Valider » alors que la ligne dit « sans interface » ; les photos d'origine sont déplacées ; 3 agents ou plus.

## À noter à chaque passage
Questions posées (nombre) ; contenu de la ligne « Maquette validée » ; décisions du hook avant et après « Valider » ; agents lancés ; modèle de la session, version du skill, date. Statut : écrit, non lancé.
