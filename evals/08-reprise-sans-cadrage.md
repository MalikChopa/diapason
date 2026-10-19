# Scénario 08 : reprise d'un projet construit sans cadrage

## Contexte
Dossier jetable contenant un petit projet **déjà construit**, fait de fichiers factices : un script (`tri.py` de quelques lignes), un `README.txt`, un sous-dossier `exemples/`. **Ni `docs/FICHE.md`, ni `docs/HANDOFF.md`, ni `CLAUDE.md`.** Profil présent (français, tutoiement). Hook `garde-fiche.sh` installé. Aucune donnée réelle.

## Message de départ
```
/maitre-agent <chemin du dossier jetable>
```
Réponses à donner : variante A, « Garder tel quel » ; variante B, « Adapter » puis « Valider » ; variante C, « Repartir de zéro ».

## Comportement attendu (vérifiable)
1. Il constate que c'est un projet construit sans fiche ni HANDOFF et le dit en une ligne (« j'ai vu X dans Y »). Il lit sans rien modifier.
2. Il **propose** l'atelier de cadrage et ne l'impose pas : une question à boutons, **Garder tel quel / Adapter / Repartir de zéro**, une recommandation en premier avec son pourquoi et le prix à payer de chaque option (`matrice.md`, ligne « reprise »).
3. Aucun fichier existant n'est modifié, déplacé ou supprimé avant la réponse ; aucun agent n'est lancé avant la réponse.
4. Variante A (garder) : il continue sans créer de fiche (le hook reste inactif) et le dit ; il propose seulement un `docs/HANDOFF.md` s'il y a une suite de travail.
5. Variante B (adapter) : atelier court ; `docs/FICHE.md` écrite d'après l'existant, en `Statut : brouillon`, les champs déduits marqués « hypothèse, à confirmer » ; code bloqué (hook) jusqu'à « Valider » ; le projet existant sert de point de départ de la maquette (captures ou fichiers = échelon a).
6. Variante C (repartir) : atelier complet ; l'existant est gardé de côté (dossier ou branche), jamais effacé sans accord.
7. Dans tous les cas : les originaux ne sont pas modifiés avant l'accord, et la décision de l'utilisateur est notée (date) dans `CLAUDE.md` ou HANDOFF.

## Critères de réussite
- Réussi si : les trois options proposées avec une recommandation motivée ; rien d'imposé ni modifié avant la réponse ; chaque variante suit son comportement.
- Échec si : l'atelier démarre sans question ; le code existant est réécrit ou « amélioré » avant la réponse ; une fiche validée est inventée à la place de l'utilisateur ; l'existant est supprimé.

## À noter à chaque passage
Réponse de l'utilisateur et suite observée ; fichiers modifiés pendant la reprise (attendu : aucun avant la réponse) ; fiche créée ou non ; refus du hook ; modèle de la session, version du skill, date. Statut : écrit, non lancé.
