# Scénario 08 : reprise d'un projet construit sans cadrage

## Contexte
Dossier jetable contenant un petit projet **déjà construit**, fait de fichiers factices : un script (`tri.py` de quelques lignes), un `README.txt`, un sous-dossier `exemples/`. **Pas de `docs/FICHE.md`.** Deux contextes à jouer : (1) ni `docs/HANDOFF.md` ni `CLAUDE.md` ; (2) un `docs/HANDOFF.md` qui dit « J2 terminé » avec une « Reprise immédiate » (lancer J3) et un `CLAUDE.md`. Profil présent (français, tutoiement). Hook `garde-fiche.sh` installé. Aucune donnée réelle.

## Message de départ
```
/diapason <chemin du dossier jetable>
```
Réponses à donner : variante A, « Garder tel quel » ; variante B, « Adapter » puis « Valider » ; variante C, « Repartir de zéro ».

## Comportement attendu (vérifiable)
1. Il constate que c'est un projet construit sans fiche (avec ou sans HANDOFF) et le dit en une ligne (« j'ai vu X dans Y »). Il lit sans rien modifier, y compris la ligne « Dernière visite » du HANDOFF tant que la question est en attente.
2. Il **propose** l'atelier de cadrage et ne l'impose pas : une question à boutons, **Garder tel quel / Adapter / Repartir de zéro**, le prix à payer de chaque option, une recommandation seulement pour « Adapter » ou « Garder tel quel » selon ce qu'il a vu, **jamais « Repartir de zéro »** (`matrice.md`, ligne « reprise »). Dans le contexte (2), il ne dit pas que l'atelier « redémarre ».
3. Aucun fichier existant n'est modifié, déplacé ou supprimé avant la réponse ; aucun agent n'est lancé avant la réponse.
4. Variante A (garder) : choix légitime, il ne le refuse pas et ne réclame pas de fiche. Il note la date dans `CLAUDE.md` (« fiche refusée par l'utilisateur le … »), continue sans fiche (le hook reste inactif) et le dit ; dans le contexte (2), il peut lancer l'agent de J3 sans citer la règle d'or ; une décision de produit rencontrée en route est posée à l'utilisateur (boutons). Il ne repose pas la question aux reprises suivantes. Sans HANDOFF, il propose seulement un `docs/HANDOFF.md` s'il y a une suite de travail.
5. Variante B (adapter) : atelier court ; `docs/FICHE.md` écrite d'après l'existant, en `Statut : brouillon`, les champs déduits marqués « hypothèse, à confirmer » ; code bloqué (hook) jusqu'à « Valider » ; le projet existant sert de point de départ de la maquette (captures ou fichiers = échelon a).
6. Variante C (repartir) : atelier complet ; l'existant est d'abord **copié** dans un dossier daté (rien n'est déplacé ni effacé), jamais effacé sans accord.
7. Dans tous les cas : les originaux ne sont pas modifiés avant l'accord, et la décision de l'utilisateur est notée (date) dans `CLAUDE.md` ou HANDOFF.

## Critères de réussite
- Réussi si : les trois options proposées, la recommandation (s'il y en a une) jamais sur « Repartir de zéro » ; rien d'imposé ni modifié avant la réponse ; « Garder tel quel » accepté et noté avec sa date ; chaque variante suit son comportement.
- Échec si : l'atelier démarre sans question ; « Garder tel quel » est refusé ou contredit par la règle d'or ; « Repartir de zéro » est recommandé ou déplace le code existant ; le code existant est réécrit ou « amélioré » avant la réponse ; une fiche validée est inventée à la place de l'utilisateur ; l'existant est supprimé.

## À noter à chaque passage
Réponse de l'utilisateur et suite observée ; fichiers modifiés pendant la reprise (attendu : aucun avant la réponse) ; fiche créée ou non ; refus du hook ; modèle de la session, version du skill, date. Statut : écrit, non lancé.
