# Brief : audit indépendant (modèle intermédiaire), en lecture seule

Pour un document qui guide la suite (spec, architecture, synthèse chiffrée, contenu final) ou pour un lot d'assets. 2 tours au maximum. Dans l'en-tête, « Tu écris UNIQUEMENT » = `docs/<X>_AUDIT_<N>.md`.

```
<bloc _entete.md>
Rôle : auditeur indépendant, en lecture seule.
Contexte : <qui a écrit le document, à partir de quoi ; si c'est une révision, quel audit elle corrige>.
À faire :
1. <Révision : pour chaque point de l'audit précédent, verdict OK / partiel / faux, avec la ligne.>
2. Refais tous les calculs et chiffres avec un script (interpréteur isolé si possible, par exemple python3 -I) : <liste>.
3. Cherche les contradictions internes (même valeur citée différemment, exemple qui contredit un tableau) et celles avec <autres documents>.
4. Vérifie 3 à 5 affirmations ou citations contre leurs sources.
5. <Spécifique : faisabilité, sécurité, coût, accessibilité, droits…>
Format : liste numérotée ; chaque point classé bloquant / important / mineur, avec une citation courte et une correction proposée. Puis « Vérifié correct » et « À garder ».
```
