# Comment maitre-agent s'est fabriqué

> Le skill s'appelle **Diapason** depuis la v1.5 (2026-10-20) ; il a été `maitre-agent` jusqu'à la v1.3, puis Majordome en v1.4. Ce récit garde l'ancien nom, celui de l'époque.

Ce skill promet de piloter un projet avec des agents, de tout vérifier et de laisser une passation reprenable. Il aurait été gênant de le fabriquer autrement. Voici comment ça s'est passé, avec ce qui est mesuré, ce qui ne l'est pas, et ce qui s'est mal passé.

Les chiffres viennent des journaux de travail de l'époque. Quand un chiffre manque, c'est qu'il n'a pas été mesuré.

## v1.0.0 : le skill, avant le dépôt (2026-10-18)

**Recherche d'abord.** Avant d'écrire une ligne, une session a épluché ce qui existe : une vingtaine de dépôts GitHub de méthodes pour agents (dont superpowers, planning-with-files et spec-kit, cités dans le README) et la documentation de Claude Code sur les skills, les sous-agents, les hooks et les plugins. Le résultat n'est pas une copie : c'est une liste d'idées à adapter, chacune avec sa source. On y trouve par exemple le registre sur disque qui survit à la compaction, les quatre statuts de rapport d'un agent et le protocole des trois échecs.

**Conception.** Le skill tient en un `SKILL.md` court (environ 3,6 k tokens à l'appel et 257 tokens permanents en v1.1.1, mesurés par `claude plugin details`) et des fichiers lus seulement quand l'étape en a besoin : phases, reprise, briefs, templates. Il y a cinq agents `ma-*`, chacun avec son modèle : chercheur, auditeur et testeur sur le modèle intermédiaire, concepteur sur le plus capable, exécutant sur le modèle qu'on lui demande.

**Deux audits et un test réel.** La version 1.0.0 est passée par deux audits et un essai en conditions réelles. Le détail de ce qu'ils ont trouvé n'est pas conservé dans les notes qui ont servi à écrire ce document : il n'est donc pas raconté ici, et on ne le romance pas. Un lint local (`lint-skill.sh`) contrôlait le YAML, la taille du skill et les renvois entre fichiers. Tout était vert ce jour-là.

Une limite de cette version : le déclenchement du hook de reprise n'avait pas été observé en conditions réelles. Il fallait pour cela une nouvelle session et un résumé automatique.

## v1.1.0 : ce chantier, piloté par le skill lui-même

Le cahier des charges : barre d'état, notifications, sous-commandes, boutons, récap « depuis ta dernière visite », chapitres, plugin, dépôt public. Le skill a été lancé sur son propre chantier, avec ses propres agents.

| Agent | Modèle | Tâche | Coût mesuré |
|---|---|---|---|
| 01 `ma-chercheur` | sonnet | doc officielle : statusLine, hooks, plugins, validation, releases | 209 k tokens, 28 min, environ 12 % de la fenêtre de 5 h |
| 02 `ma-executant` | sonnet | plugin, scripts de barre d'état et de notifications, lint, workflows | 110 k tokens, 22 min |
| 03 `ma-executant` | sonnet | mod de bureau | 111 k tokens, 5 min |
| 04 `ma-executant` | sonnet | cette vitrine (README, évaluations, ce texte) | non mesuré |

Le maître agent a fait lui-même les petites tâches (sous-commandes, boutons, récap) et les vérifications décisives. Le travail a commencé en début de soirée ; à environ 22 h, le quota de 5 heures était à 90 % : c'est la règle du skill, l'arrêt a donc été propre. HANDOFF mis à jour, plus aucun agent lancé. Le quota est reparti de zéro à 22 h 41, et le chantier a repris depuis le fichier de passation, comme prévu pour n'importe quel lecteur.

### Les décisions qui ont compté
- **Le mod de bureau.** L'utilisateur travaille surtout dans l'onglet Code de l'app Claude de bureau. Un script témoin déclaré en `statusLine` n'y a été appelé par aucun des 6 messages suivants (réserve : le rechargement à chaud du réglage du projet n'est pas prouvé), ce qui concorde avec le ticket public #41456 (#83534 a été fermé comme doublon). La barre d'état du terminal n'est donc pas affichée au bureau. Plutôt que d'attendre, le chantier a ajouté un second plugin, `maitre-agent-bureau`, qui utilise l'API des « mods » de Claude Code 2.1.299 (en accès anticipé). Résultat vérifié en réel : la ligne d'état s'est affichée près du champ de saisie, la validation stricte passe et 25 tests sur 25 passent. Un test de mutation (seuils d'alerte volontairement réduits) a bien fait échouer 5 tests.
- **Une publication par historique propre.** Les briefs et les journaux de travail contiennent des chemins personnels. Ils ne sont pas dans le dépôt public, qui est publié depuis un historique propre.
- **La notification, testée pour de vrai.** Une notification macOS par `osascript` arrive quand elle est lancée hors du bac à sable des commandes de l'agent, et rien ne s'affiche depuis le bac à sable, alors que la commande répond « succès ». Moralité : un code de retour à zéro ne prouve pas qu'on a vu quelque chose. Le toast de fin du premier agent n'avait d'ailleurs pas été remarqué ; celui d'un mini-agent lancé pour l'occasion, si.

### Les erreurs, et ce qu'on en retient
- **Un fichier de réglages local écrasé sans être lu.** Pour le test de la barre d'état, le maître agent a écrit dans le fichier de réglages local du projet sans le lire d'abord. L'ancien contenu, probablement des autorisations « toujours permettre » de la session, est perdu ; le fichier vaut maintenant `{}`. Leçon : lire avant d'écrire, toujours. Le skill demande déjà un accord pour toute action irréversible (suppression, écrasement) : le maître agent ne s'est pas appliqué sa propre règle, et l'a noté dans la passation.
- **Une exclusion git qui cachait les recherches.** Un commit censé enregistrer la recherche 01 n'a enregistré que la passation : une règle d'exclusion écartait les fichiers de recherche. Le travail existait sur le disque, pas dans l'historique. L'historique git montre le correctif environ 27 minutes plus tard. Leçon : on vérifie ce qui est réellement enregistré (`git show --stat`), pas ce qu'on croit avoir enregistré.
- **Un séparateur qui plaît à un shell et pas à l'autre.** Un caractère de contrôle utilisé comme séparateur dans le script de barre d'état marchait sous un interpréteur et pas sous le `sh` de macOS (bash 3.2). Remplacé par `|`, puis vérifié sous les deux interpréteurs. Leçon : les scripts doivent tourner partout, donc on les teste partout.
- **Un lint rouge sur le dépôt réel.** Le contrôle des traces personnelles a protesté contre des chemins dans les briefs et dans des fixtures de tests. C'est exactement son rôle ; la solution a été de sortir les documents de travail de la liste publique.

### Ce qui n'est pas encore démontré
Les hooks du plugin n'ont pas été exécutés de bout en bout par Claude Code ; les workflows GitHub n'ont pas encore tourné ; les cinq évaluations de `evals/` sont écrites mais pas lancées ; l'installation depuis la marketplace n'a pas pu être essayée avant la publication. Le README a été relu par un auditeur indépendant (`ma-auditeur`) le 2026-10-18, corrections appliquées. Le README liste ces limites : un dépôt qui se vante d'être honnête doit l'être.

## v1.3.0 : le skill devient accompagnant (2026-10-19)

Le déclencheur : sur un vrai projet, la session avait choisi seule de faire une page web et avait codé sans poser de question. Le chantier a donc ajouté un atelier de cadrage à boutons, une fiche à valider, une maquette avant le code, des points d'étape et un hook qui refuse d'écrire du code tant que la fiche n'est pas validée (détail dans `CHANGELOG.md` et dans le README, section « Comment il travaille avec toi »).

Trois agents `ma-executant` (sonnet), pilotés par le maître agent :

| Agent | Tâche | Coût mesuré |
|---|---|---|
| 09 | autonomie `accompagnant`, atelier de cadrage, fiche, maquette, points d'étape, préréglages selon le forfait | 197 k tokens, 14 min |
| 10 | relevé des outils, échelle de maquette, hook `garde-fiche.sh`, fiche complète, carte du parcours, matrice et 4 evals | 156 k tokens, 12 min |
| 11 | README FR/EN, CHANGELOG, versions | non mesuré |

Ce qui est mesuré : les tests des scripts passent de 76 à 200 vérifications (sous `sh` et `dash`, 0 échec) ; une contre-épreuve, avec un garde-fou qui laisse tout passer, fait échouer 32 vérifications, donc les tests voient bien le blocage. Ce qui ne l'est pas : le skill n'a pas encore tourné sur ce nouveau parcours en vraie session, le hook n'a pas été appelé par Claude Code lui-même, et les evals 06 à 10 sont écrites mais pas jouées. `SKILL.md` frôle sa limite de taille (16 443 octets pour 16 500, `wc -c` du 2026-10-19) : tout détail nouveau doit aller dans les fichiers lus à la demande.

Lots de sobriété et d'anglais, après la v1.3.0 (2026-10-19) : lot 12 (pas de sous-agents d'agents, connecteurs proposés à la coupe, briefs lus par sections, maquette par le maître : 68 k tokens en 3 min, une mesure, gain non mesuré) ; lot 13 (texte interne du skill en anglais : `SKILL.md` ≈ 8 800 → ≈ 6 200 tokens réels, −30 %, une mesure).

Lots 15 à 17, après le second essai réel (2026-10-19) : audit des gaspillages de tokens (lot 15, ma-auditeur, 99 k tokens, 6 min) ; recherche sur le quota hebdomadaire (lot 16, ma-chercheur, 69 k tokens, 5 min ; la variante C est retenue) ; corrections de l'audit, quota hebdomadaire, diagnostic et connecteurs (lot 17, ma-executant, 201 k tokens, 67 min ; 327 vérifications sous `sh` et `dash`, 0 échec).

## La leçon qui revient partout
Séparer celui qui fait de celui qui vérifie, écrire l'état dans un fichier plutôt que dans sa tête, et ne rien annoncer qu'on n'a pas vu : ce sont les trois règles du skill, et ce sont celles qui ont rattrapé ses propres erreurs.
