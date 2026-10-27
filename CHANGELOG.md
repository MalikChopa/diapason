# Changelog

Toutes les évolutions notables de ce projet sont notées ici.
Le format suit [Keep a Changelog](https://keepachangelog.com/fr/1.1.0/) et le projet suit le [versionnement sémantique](https://semver.org/lang/fr/).

## [Non publié]

## [1.8.3] - 2026-10-27

Répare le contrôle de version, muet avec la vraie réponse de GitHub depuis la 1.8.1.

### Corrigé
- **Le contrôle de version ne lisait rien de la vraie réponse de GitHub (1.8.1 et 1.8.2)** : l'API répond par un objet JSON sur UNE seule ligne (`{"url":…,"tag_name":"v1.8.2",…}`), et l'extraction de la 1.8.1 exigeait « tag_name » en début de ligne. Le script se taisait donc, sans erreur, avec la vraie réponse (la 1.8.0, non ancrée, la lisait). Les tests n'avaient attrapé ni l'un ni l'autre : ils utilisaient du JSON mis en forme et une URL de test, et l'un d'eux exigeait même que `{"id":1,"tag_name":"v9.9.9"}` soit **ignoré**. L'extraction coupe maintenant la réponse aux virgules et aux accolades avant d'ancrer ; un « tag_name » dans le texte de la release (précédé d'un antislash en JSON) ne peut toujours pas être pris. Deux tests ajoutés avec un faux `curl` qui renvoie l'objet compact dans la branche de l'URL par défaut (forme réelle, puis tag hostile), le test faux est inversé ; essai réel contre l'API le 2026-10-26.

### Examiné, sans changement
- Revue de parcimonie du 2026-10-27 (tirage `awk` à graine 20261028, en écartant les 15 règles déjà revues ; trace : fiche 31) : 5 règles gardées, aucune retirée. §7 « chaque rapport dit ce qui est fait, ce qui reste hypothèse, ce que l'utilisateur doit décider » : origine v1.x, éval 08 (couverture partielle). §2 « pas de code avant la fiche validée » : origine v1.3, évals 06 et 07, contrôlé par `garde-fiche.sh` (tests). §3 « le fichier de l'agent est la vérité, rapport de 10 lignes, premier mot = statut » : origine v1.3, **aucune éval**. §5 « ne pas contourner une protection » : éval 04. §5 « ne pas toucher un serveur ou un port en service, ne tuer aucun processus » : origine v1.x, **aucune éval**. Le contrôle de lint des agents (`disallowedTools: Agent`, 1.8.1) et les tests de la forme réelle de l'API (1.8.3) comblent deux trous trouvés par l'audit, pas les évals manquantes.

## [1.8.2] - 2026-10-26

Corrige un défaut que la CI de GitHub a trouvé juste après la publication de la v1.8.1 (le lint de `main` et du tag était resté rouge à cause d'un seul test sous Linux).

### Corrigé
- **`agent-count.sh` sous dash** : une redirection ratée sur `:` (commande spéciale) arrête dash avec le code 2 ; avec un `agent_id` de 400 caractères, le hook sortait avec 2 au lieu de 0 sous Linux (le hook est enveloppé dans `|| true`, donc sans effet visible, mais la promesse « sort toujours avec 0 » était fausse). `printf ''` remplace `:`.
- **Les comptes « sous `sh` et sous `dash` » de la 1.8.1 étaient trompeurs** : `dash tests/hooks.sh` ne change que l'interpréteur de la suite, les scripts testés tournaient avec le `sh` de macOS. C'est la CI (Ubuntu : `sh` = dash) qui a vu le défaut.
- Les deux tests d'écritures parallèles de `reglages.sh` vérifiaient « 11 écritures sur 11 » : sous forte charge, un `set` peut renoncer avec « verrou occupé » (code 3) sans rien écrire ni rien perdre, ce qui rendait le test instable. Ils vérifient maintenant l'absence de perte silencieuse (lignes = lignes de départ + écritures réussies, avec au moins 9 sur 11).

### Ajouté
- `tools/test-dash.sh` : lance `tests/hooks.sh` avec un lien `sh -> dash` en tête du `PATH`, donc avec dash comme `sh` des scripts testés, ce que fait la CI. 581 vérifications, 0 échec, sous `sh` et avec ce lanceur (mesuré le 2026-10-26).

### Documentation
- `CONTRIBUTING.md` et `CONTRIBUTING.en.md` : la commande de test sous dash devient `sh tools/test-dash.sh`, avec l'explication.

### Examiné, sans changement
- Revue de parcimonie du 2026-10-26 (tirage `awk` à graine 20261027 dans les puces de `SKILL.md`, en écartant les 10 règles déjà revues en 1.8.0 et 1.8.1 ; trace : fiche 30) : 5 règles gardées, aucune retirée. §7 chapitres : origine v1.2, **aucune éval**. §7 « attendre une question bloquante, un accord §5 ou un lot au-delà de `budget-lot` » : évals 01, 02 et 04, couverture partielle. §7 points d'étape : origine v1.3, évals 06 et 09. §6 « ≥ 1er palier : plus d'agent du modèle le plus capable » : origine v1.2, l'éval 05 ne joue que le 2e palier : **éval à écrire**. §0 « le profil ne lève jamais un Never » : éval 04.

## [1.8.1] - 2026-10-26

Correctifs issus d'un audit du skill par lui-même (2 auditeurs indépendants, 43 points, 0 bloquant ; les faits décisifs ont été rejoués à la main).

### Corrigé
- **`reglages.sh` perdait des réglages en parallèle** : 11 `set` simultanés laissaient 1 à 4 lignes sur 12 (mesuré avant/après : 0 essai complet sur 8, puis 8 sur 8). Les écritures (`set`, `preset`, `reset`, y compris `--projet`) prennent maintenant un verrou (`mkdir`, attente 10 s au plus, verrou de plus de 30 s retiré), passent par un fichier temporaire puis `mv`, et laissent une copie `profil.md.bak` de l'état d'avant (`set --projet` : `CLAUDE.md.bak` à côté du `CLAUDE.md`).
- **Zéros de tête et virgule décimale** : `seuils-hebdo 08 20 40` était accepté puis faisait échouer `quota.sh` et la barre d'état (le `sh` lisait « 08 » en octal) ; il est maintenant stocké `8 20 40`, et un profil déjà écrit avec `08` fonctionne. `quota.sh hebdo 12,5` lisait 100 % (palier 3) ; il lit 12,5 ; une valeur illisible ou au-dessus de 100 sort avec le code 4.
- **Interrupteur de `maj.sh`** : `- verif-maj: non`, `Non`, une puce `*` ou `+`, du gras ou une ligne indentée étaient ignorés et la requête partait ; ils sont reconnus (valeurs non / no / off / false / 0, aussi pour `DIAPASON_VERIF_MAJ`). Un `## Réglages du projet` du `CLAUDE.md` l'emporte sur le profil, comme pour les autres réglages.
- **`maj.sh`, annonces et réseau** : une seule annonce par 24 h tous modes confondus (le hook de reprise répétait l'annonce du lancement ; 6 lancements simultanés l'annonçaient 6 fois) ; un cache corrompu, illisible, trop gros ou dont l'horloge a reculé est ignoré au lieu de rendre le contrôle muet ; requête limitée à https et 200 Ko ; sans dossier de données inscriptible, il se tait au lieu d'annoncer à chaque appel ; « au plus une requête par jour, une de plus toutes les 6 h après un échec » (c'était écrit « par jour » tout court).
- **Petits défauts de scripts** : la barre d'état ne plante plus sur des valeurs extrêmes (`1e300`, négatif, texte) ; `diagnostic` ne signale plus un faux KO quand la commande de la barre n'est pas un chemin nu ; `migrer.sh` utilise `mktemp` ; `agent-count.sh` ne bavarde plus sur stderr.
- **Textes qui se contredisaient ou n'étaient plus vrais** : `reprise.md` disait « arrête-toi » au palier 2 alors que `SKILL.md` §6 dit « propose, lance après un oui » (aligné sur `SKILL.md`) ; la FAQ des guides affirmait « aucun appel réseau » (la seule exception est le contrôle de version) et citait des nombres de lignes périmés ; le guide annonçait le préfixe 🎵 alors que la barre affiche 🛎️ ; `SKILL.md` §0 laissait croire qu'un profil daté peut lever les interdits du §5 (il ne lève jamais un « Never », seulement un accord, comme le dit l'éval 04) ; `SKILL.md` §6 « sort avec le palier » devient « sort avec le seuil atteint » (0 = aucun, 2 = pas de mesure) ; le message de `maj.sh` renvoyait vers la mauvaise section d'`installation.md`.
- Limites du garde-fou « fiche validée » écrites dans les guides et `installation.md` (liens symboliques et alias de chemin non résolus, outils d'écriture MCP et écritures par Bash non couverts, `.claude/` et `docs/` ouverts par choix). L'hypothèse « `disableAllHooks` coupe les hooks » est notée « non vérifié en session réelle ».
- **Re-audit des correctifs** (3 points importants, tous corrigés ou notés) : la reprise d'un verrou abandonné n'était pas atomique (8 `set` simultanés sur un verrou vieux de 60 s perdaient des réglages 24 fois sur 30) : un seul « voleur » à la fois, qui relit l'âge du verrou avant de le retirer, et un verrou daté du futur est jugé abandonné (même correctif dans `maj.sh`) ; `reglages.sh` sortait avec le code 2 (« pas de profil ») aussi pour « verrou occupé » et « écriture impossible », ce qui pouvait faire relancer le premier usage sur un profil existant : ces deux cas sortent maintenant avec le code 3 (documenté) ; `migrer.sh` ne s'arrêtait plus sur Ctrl-C ou SIGTERM (le piège ne sortait pas) ; `set --projet` laisse un `CLAUDE.md.bak` dans le dossier du projet, ce que l'en-tête du script et `commandes.md` disent maintenant.
- `skills/.DS_Store` n'est plus suivi par git ; `.gitignore` ignore `.DS_Store` partout.

### Ajouté
- Lint : chaque agent doit interdire l'outil `Agent` (`disallowedTools`), ce qui garde « pas de sous-agents d'agents » (SKILL §3) hors de portée d'une retouche d'agent.
- 157 vérifications dans `tests/hooks.sh` (424 → 581, mêmes résultats sous `sh` et `dash`) : une par défaut corrigé, contrôlées contre l'ancien code (86 échouent dessus), plus la fabrication des zips (aucun fichier privé dedans).

### Documentation
- `CONTRIBUTING.en.md` : version anglaise complète (organisation du dépôt et copies à garder identiques, tests sous `sh` et `dash`, plafond de `SKILL.md`, ajout d'un réglage, version et release, revue de parcimonie) ; `CONTRIBUTING.md` aligné. `ARCHITECTURE.md` et `ARCHITECTURE.en.md` : le fonctionnement du skill expliqué en détail (composants, vie d'une demande, concepts, scripts et hooks, fichiers sur la machine, système qualité).

### Examiné, sans changement
- Revue de parcimonie du 2026-10-26 (tirage `awk` à graine 20261026 dans les puces des §0, §2, §3 et §5 de `SKILL.md`, en écartant les 5 règles déjà revues en 1.8.0 ; trace : fiche 29 de la bibliothèque de recherche) : 5 règles gardées, aucune retirée. (1) §5 « copier une œuvre protégée : s'en inspirer » : origine cadrage v1.x (CHANGELOG), l'éval 04 ne couvre que « contourner une protection », **pas la copie** : éval à écrire. (2) §3 suivi dans « Agents lancés » : évals 03, 05, 06 et 09. (3) §5 « jamais de secret ni d'identifiant dans un fichier » : règle fondatrice, éval 04 seulement pour « aucune clé réelle » (**couverture partielle**). (4) §2 décisions d'exécution déléguées : origine v1.3 (`autonomie`), éval 06 pour la moitié « décision de produit jamais seule », **rien** pour la moitié « déléguée ». (5) §3 « pas de sous-agents d'agents » : origine lot 12 (sobriété) ; aucune éval, mais **les 5 agents interdisent l'outil `Agent`**, ce que le lint contrôle désormais (nouveau contrôle).
- Choix laissés au propriétaire, non appliqués : voir `docs/V181_DECISIONS.md` (petit projet avec ou sans fiche, parcours « audite ce dépôt », quota atteint en plein lot, `reprendre` sans profil, garde-fou et `.claude/`, éval manquantes). Le mod de bureau (TypeScript) n'a pas été exécuté : `bun` est absent.

## [1.8.0] - 2026-10-25

Le skill sait dire qu'une version plus récente existe, et le dépôt suit le nouveau nom du compte GitHub.

### Modifié
- **Compte GitHub renommé** : les adresses du dépôt, du marketplace et des zips pointent vers `MalikChopa/diapason`. Le contrôle de version lit les releases par l'identifiant numérique du dépôt (l'ancienne adresse de l'API répond 301, que `curl` ne suit pas sans `-L`, ce qui l'aurait rendu muet) et suit maintenant les redirections.

### Ajouté
- **Contrôle de version** : `hooks/maj.sh` (source `tools/maj.sh`) compare la version installée (nouveau fichier `skills/diapason/VERSION`, présent aussi dans le zip « skill seul ») à la dernière release GitHub et, s'il y en a une plus récente, le dit en une ligne (plugin : `claude plugin update diapason@diapason` ; copie : le zip de la release). Lancé par `SKILL.md` §0 à chaque `/diapason` et par le hook de reprise (`reinject.sh`, projets avec HANDOFF seulement, au plus une fois par 24 h). Au plus une requête GET par jour vers `api.github.com` (3 s maximum, rien d'envoyé, cache `maj.cache`, nouvel essai 6 h après un échec), une annonce par version puis un rappel à 7 jours ; seul un numéro de version (chiffres et points) vient du réseau. Ne télécharge et n'installe rien. Réglage `verif-maj oui|non` (aussi `DIAPASON_VERIF_MAJ=non`) ; `maj.sh --force` pour vérifier tout de suite ; la ligne « version » du `diagnostic` montre la dernière version connue. Contrepartie : c'est le premier appel réseau des scripts du skill. Motif : une copie du skill (routes B et C) ne se mettait jamais à jour toute seule, et quelqu'un resté en v1.6 garde un garde-fou qui ne connaît pas `dia-executant`.

### Examiné, sans changement
- Revue de parcimonie du 2026-10-25 (tirage `awk` à graine 20261025 dans les puces des §3 à §6 de `SKILL.md`, trace dans la bibliothèque de recherche, fiche 28) : 5 règles gardées. (1) §4 « auditer seulement les documents qui guident la suite » : origine probable recherche 03 (non recoupée ligne à ligne), évaluée par l'éval 01 (un petit projet ne reçoit pas d'audit). (2) §5 « ce que l'utilisateur fournit reste sur sa machine » : règle fondatrice, touchée par l'éval 10 (lien non copié dans un service tiers) ; le contrôle de version n'est pas une exception, il n'envoie aucune donnée. (3) §5 « acheter : donner les liens » : règle fondatrice, éval 02 (aucun panier rempli). (4) §3 parallélisme et `budget-lot` : origine v1.2 (réglages), **sans éval du comportement du modèle**, seulement testé côté script ; gardée, éval à écrire. (5) §6 « ≥ 2e palier : pas d'agent de sa propre initiative » : éval 05. Aucun retrait ni fusion.
- Marge de `SKILL.md` : 11 932 octets sur 12 000 (68 octets). Toute règle ajoutée doit en retirer une.

## [1.7.0] - 2026-10-22

Les agents suivent le nom du skill (`dia-*`), le skill dit mieux ce qu'il pense savoir, la passation se date, et un nouveau type de projet couvre les livrables visuels (maquettes, planches, pièces de portfolio). Le lot vient d'une veille (recherches sur d'autres skills et sur la littérature), d'un audit indépendant du diff et de tests sur papier. Deux essais à preuve négative (défauts plantés dans un livrable, carte de projet) n'ont rien changé au skill.

### Modifié
- **Les agents s'appellent `dia-*`** (`dia-chercheur`, `dia-auditeur`, `dia-testeur`, `dia-concepteur`, `dia-executant`) au lieu de `ma-*`, pour suivre le nom du skill. Le garde-fou « fiche validée » refuse toujours l'ancien `ma-executant`, `hooks.json` et le mod de bureau acceptent encore `ma-*`, et `diagnostic` signale les anciens `ma-*` encore installés (`rm ~/.claude/agents/ma-*.md` après avoir installé les `dia-*`). Les anciens noms restent dans l'historique de ce fichier.
- **Recommandations plus honnêtes** (`cadrage.md`, « How to ask ») : quand une règle écrite (profil, `CLAUDE.md`, fiche, réglage) tranche déjà, on ne pose plus la question, on dit « je fais Y, d'après ta règle X » ; pour un vrai choix, l'étiquette « (recommandé) » devient « (mon penchant : probable) » (un seul des trois niveaux sûr / probable / je devine) avec la raison, le prix à payer et ce qui ferait changer d'avis, et quatre vérifications avant d'envoyer (vrai, dit en clair, dans ton intérêt, refusable). La règle « une règle écrite tranche » ne vaut que pour un choix d'exécution : jamais pour une décision produit ni une approbation du §5. Les boutons d'approbation et de point d'étape (« Valider et continuer », « Continuer ») n'ont plus d'étiquette « recommandé ». Motif : dans un essai à un seul sujet, l'option étiquetée « Recommandé » a été prise 4 fois sur 4, dont 2 recommandations volontairement fausses. Effet de la nouvelle étiquette : non mesuré.
- **Hypothèses chiffrées en trois niveaux** (sûr / probable / je devine) dans le message de départ et les points d'étape ; une décision produit est posée quelle que soit la certitude. Niveaux, pas pourcentages : une certitude chiffrée par un modèle n'est pas fiable.
- **HANDOFF daté** : chaque fait porte sa date (`[V AAAA-MM-JJ]`), un fait qui change garde son ancienne valeur dans « (remplace …) », et la reprise revérifie sur le disque les faits non datés, de plus de 7 jours ou marqués `[?]` dont l'étape suivante dépend ; elle ne redate que ce qui est vérifié.
- **Mise à jour depuis la v1.6** : nouvelle section `installation.md` §8 ; `diagnostic` signale une copie périmée du garde-fou (qui laisserait passer `dia-executant`), un réglage de notification resté sur `^ma-` et les anciens `ma-*` ; un brief ou une ligne qui cite `ma-X` se lit `dia-X`.

### Ajouté
- **Type de projet « livrable visuel »** (`phases.md`, `matrice.md`, `cadrage.md`) : quand la maquette ou la planche EST le produit (cas « des maquettes pour mon portfolio »), un flux sans conception ni jalons (cadrage, références, choix du look sur 2 ou 3 rendus HTML, production, relecture par l'utilisateur, livraison), une ligne de matrice (pour quoi, nombre de pièces, format, références, finition, droits des œuvres montrées), la limite dite d'avance (HTML/CSS et prompts d'image, pas de rendu haute fidélité), des critères de relecture écrits dans la fiche, les pièces gardées sous `maquette/` (copies des œuvres dans `maquette/assets/`), les images réelles de l'utilisateur montrées seulement dans le navigateur local, jamais dans un artifact. Type incertain : on prend la ligne la plus proche, on la nomme, on la corrige après le tour 1. Le nombre de pièces compte comme les écrans pour la taille.
- `CONTRIBUTING.md` : section « Revue de parcimonie » (5 règles de `SKILL.md` tirées à chaque version, origine et évaluation cherchées, retrait ou fusion proposés sans les deux).

### Corrigé
- `hooks/statusline.sh` : course dans les alertes de quota (5 h et 7 j). Un appel arrivant pendant qu'un autre marquait encore les seuils plus bas pouvait viser un seuil plus bas et envoyer une seconde alerte. Le seuil visé est maintenant toujours le plus haut franchi, et le verrou `mkdir` décide seul. Deux tests de régression ajoutés (`tests/hooks.sh`), qui échouent sur l'ancien code.

### Examiné, sans changement
- Revue de parcimonie du 2026-10-21 (§0, §2, §3, §5) : 5 règles gardées (données de l'utilisateur sur sa machine, plus petit résultat utilisable, profil sans levée des interdits, chemins plutôt que résumés, modèle toujours explicite) ; 4 sans évaluation.
- Champs d'agent `effort` et `omitClaudeMd` (recherche 08, n° 6) : essais sur `ma-chercheur`. `effort: medium` donne 8 à 17 % de tokens en moins et deux fois moins de temps sur une recherche factuelle (6 passages, 30 réponses justes sur 30) ; non mesuré sur une synthèse à plusieurs sources ni sur un audit, où la profondeur de lecture peut baisser. `omitClaudeMd` : non essayé, gain borné à environ 1,4 k tokens ici. Les agents restent inchangés.

## [1.6.0] - 2026-10-20

Le corps de `SKILL.md` devient assez court pour être réinjecté en entier après un résumé automatique, et le lot reprend les pistes issues d'une relecture des 10 simulations de la v1.3 et de quatre recherches (autres dépôts d'orchestration, tokens et quota, optimisation d'un gros skill). Valeurs et règles de ce lot : réglages de conception, non rejoués en vraie session.

### Corrigé
- **`SKILL.md` était trop long pour la réinjection** : après un résumé automatique, Claude Code ne rend à un skill que ses 5 000 premiers tokens (25 000 pour l'ensemble des skills), en gardant le début. `SKILL.md` pesait environ 6 400 tokens : les sections « Quota » et « Reporting » (paliers de quota, attente des réponses, plafond de HANDOFF) étaient perdues juste quand une reprise en a besoin. Il passe de 16 272 à **11 685 octets** (environ 4 270 tokens, une mesure) : « Permissions » est remontée juste après « Role », le numéro des sections ne change pas, et les détails vont dans des fichiers lus à la demande.
- **L'estimation du lint était fausse** : « octets × 10 / 33 » annonçait 4 930 tokens pour un fichier qui en pesait environ 6 400. Mesure : 2,4 à 2,7 octets par token pour ce texte (et non 3,3).

### Ajouté
- **Lint en octets avec le vrai plafond** (`tools/lint-skill.sh`) : échec au-delà de 12 000 octets (`LINT_SKILL_MAX_BYTES` pour changer), « Permissions » avant l'octet 11 000, dernière section avant 12 000. Nouveaux contrôles de cohérence : les interdits de « Permissions » sont les mêmes dans `briefs/_entete.md`, les clés de réglage citées existent dans `reglages.md`, chaque renvoi « §N » pointe une section existante.
- **Filet dans le hook de réinjection** (`reinject.sh`) : après un résumé, il rappelle de relire la fin de `SKILL.md` et `quota.md` si le texte du skill paraît coupé.
- **`contrats.md`** : la liste des titres et clés que les scripts lisent (HANDOFF, profil, fiche, index), sortie de `SKILL.md`.
- **Budget par agent** (`briefs/_entete.md`) : une ligne « Budget » dans chaque brief (tokens ou pages lues) ; budget atteint = l'agent écrit son fichier et rapporte « terminé avec réserves ». Un agent de recherche coûte environ 8 à 10 k tokens par page web lue.
- **Reprise** (`reprise.md`) : si le `CLAUDE.md` du projet donne une commande de test ou de lancement, elle est lancée une fois avant tout nouvel agent d'implémentation ; un échec est dit avant de planifier.
- **Jeu d'action ou temps réel** : le premier jalon (J0) est une boucle jouable, soumise à l'utilisateur pour juger la sensation (contrôles, rythme, difficulté) avant les jalons suivants ; la maquette ne peut pas la valider et un testeur non plus (`phases.md`, `matrice.md`).

### Changé
- **Vérificateurs sceptiques** : `ma-auditeur` et `ma-testeur` comptent une preuve manquante ou non concluante comme « non vérifié » ou « non réussi », et le rapport d'un autre agent comme une hypothèse. Le testeur n'émet aucun verdict sur la difficulté ou le plaisir de jeu (« non vérifié, à juger par l'utilisateur »).
- **Audit** : ses critères sont ceux de la fiche et de la section du jalon, écrits avant le travail ; aucun critère ajouté sans le dire (`briefs/audit.md`, qui porte maintenant les tours d'audit).
- **Aperçus et variantes en `econome`** : les aperçus de mise en page (2 par écran) sont le choix de variante ; plus de seconde question de variante après la maquette.
- **Un seul chemin de maquette** : le brief du testeur lit le chemin noté dans la ligne « Maquette validée » de la fiche (`maquette/index.html` ou `maquette/<variante>/index.html`).
- **Cadrage** : si tu cites une œuvre en référence, le tour 1 précise tout de suite qu'on s'en inspire sans la copier. Pour une décision ou un achat, les deux questions bloquantes sont celles qui changent le plus la réponse.
- **Une seule règle de lecture du profil à la reprise** (`reprendre` ou chemin de projet) : lignes de langue et de ton, plus « Réglages ».
- **`installation.md`** : pas d'exclusion git large (par exemple `docs/`) sans vérifier ce qu'elle cache.
- Détails déplacés hors de `SKILL.md` : lecture de l'usage, palier 2+ au départ et coût d'un lot (`quota.md`), migration et relevé à refaire (`profil-modele.md`), piste abandonnée (`reprise.md`).
- Tests : 379 vérifications sous `sh` et `dash` ; le test de taille du hook de réinjection passe de 3 300 à 3 600 octets (phrase de rappel ajoutée).

### Pas encore fait
- Les 11 scénarios de `evals/` n'ont jamais été joués en vraie session ; la coupe « garde le début » est lue dans la documentation de Claude Code mais n'a pas été observée.

## [1.5.0] - 2026-10-20

Changement de nom : Majordome devient **Diapason** (nom choisi par l'utilisateur). Un diapason donne le la à l'orchestre ; ici, il donne le la à l'équipe d'agents. Aucun changement de fonctionnement.

### Renommé : Majordome devient Diapason
- **Nom** : produit « Diapason », skill `skills/diapason/` (`name: diapason`), commande **`/diapason`** (« /majordome devient /diapason » et « /maitre-agent devient /diapason » ; aucun skill-alias n'est livré : un projet dont le `CLAUDE.md` dit `/majordome` se reprend avec `/diapason <chemin du projet>`). Le mot de rôle « le majordome » devient « Diapason ».
- **Plugin et marketplace** : `diapason` et `diapason-bureau` (le mod de bureau, avant `majordome-bureau`) ; zips de release `diapason-skill-v<version>.zip` et `diapason-plugin-v<version>.zip` ; dépôt `MalikChopa/diapason` (GitHub redirige en principe les anciennes adresses ; non vérifié pour les marketplaces de Claude Code).
- **Agents** : les `ma-*` gardent leur nom (aucun agent renommé). Sous plugin ils s'appellent `diapason:ma-*` ; les préfixes `majordome:` et `maitre-agent:` restent reconnus (garde-fou, notification de fin d'agent, mod de bureau).
- **Barre d'état et mod** : préfixe `🎵` au lieu de `🛎️`.
- **Variables d'environnement** : `DIAPASON_PROJECT_DIR`, `DIAPASON_DRY_RUN`, `DIAPASON_REINJECT_MAX`, `DIAPASON_PROFIL` ; les `MAJORDOME_*` (v1.4) et `MAITRE_AGENT_*` (v1.3) restent lues.
- **Dossier des données** : `~/.claude/diapason/`. Chaque script (hooks, outils, copies du skill, mod de bureau) prend `~/.claude/diapason` s'il existe, sinon `~/.claude/majordome`, sinon `~/.claude/maitre-agent`, sinon `~/.claude/diapason`.
- **Migration** (`migrer.sh`, lancé au premier `/diapason` quand `~/.claude/diapason/profil.md` manque) : copie `~/.claude/majordome` ou, à défaut, `~/.claude/maitre-agent` vers `~/.claude/diapason`, sans rien écraser ni supprimer (l'ancien dossier reste) ; les `sauvegarde-skill-*` ne sont pas copiées ; refus en une ligne si `~/.claude/diapason/profil.md` existe déjà ; sortie non nulle si une copie échoue. Il **n'écrit jamais `settings.json`** : si un hook (par exemple la réinjection) y pointe vers l'ancien dossier, il affiche seulement le changement proposé (lignes `-` / `+`).
- **Rien à modifier dans tes projets** : les clés lues par les scripts ne changent pas ; les anciens titres « Vérifications du majordome » et « Vérifications du maître agent » restent acceptés.
- `diagnostic` signale aussi un ancien skill `~/.claude/skills/majordome`.
- Version **1.5.0** dans `plugin.json` du plugin et du mod de bureau.
- Tests : `tests/hooks.sh` couvre les sept cas du dossier des données, `migrer.sh` (depuis majordome, depuis maitre-agent, les deux sources, destination existante, rien à migrer, échec, `settings.json` intact, `sauvegarde-skill-*` non copiées), les anciennes variables et les trois préfixes d'agent (378 vérifications sous `sh` et `dash`). Les tests du mod de bureau : 41 sur 41 (`claude plugin test bureau`, CLI 2.1.299 de l'app, HOME factice).

### Changé
- **README bilingue en un seul fichier** (anglais puis français, avec ancres) ; `README.en.md` est retiré. Le détail est dans `GUIDE.md` et `GUIDE.en.md`, dont la section de migration couvre maintenant `maitre-agent` et `majordome`.

## [1.4.0] - 2026-10-20

Correctifs issus de 10 simulations sur papier du skill v1.3.0 (1 blocage, 19 points gênants), puis changement de nom en Majordome. Valeurs et règles de ce lot : réglages de conception, non rejoués en vraie session.

### Renommé : maitre-agent devient Majordome
- **Nom** : produit « Majordome », skill `skills/majordome/` (`name: majordome`), commande **`/majordome`** (« /maitre-agent devient /majordome » ; aucun skill-alias n'est livré : un projet dont le `CLAUDE.md` dit `/maitre-agent` se reprend avec `/majordome <chemin du projet>`), plugin `majordome`, marketplace `majordome`, mod de bureau `majordome-bureau`, zips `majordome-skill-v…` et `majordome-plugin-v…`. Dépôt public prévu : `majordome` (GitHub redirige l'ancienne adresse ; le renommage lui-même se fait après accord). Le rôle s'appelle « le majordome » (avant : « le maître agent »). Les agents gardent le préfixe `ma-` (lu comme MAjordome).
- **Barre d'état et mod** : préfixe `🛎️ majordome` au lieu de `🧭 maitre-agent`.
- **Dossier des données** : `~/.claude/majordome/`. Chaque script (hooks, outils, copies du skill, mod de bureau) prend `~/.claude/majordome` s'il existe, sinon l'ancien `~/.claude/maitre-agent` s'il existe, sinon `~/.claude/majordome`. À la première utilisation de `/majordome`, si `~/.claude/majordome/profil.md` manque et que l'ancien profil existe, `hooks/migrer.sh` copie tout l'ancien dossier dans le nouveau **sans rien écraser ni supprimer** et le dit en une ligne ; supprimer l'ancien dossier reste ton choix. Détail et cas des copies faites à la main : `installation.md` §7.
- **Rien à modifier dans tes projets de la v1.3** : les clés lues par les scripts ne changent pas (`Jalon :`, `## Agents lancés`, `## Reprise immédiate`, `## Réglages`, `## Réglages du projet`, lignes de statut de `FICHE.md`) ; l'ancien titre « Vérifications du maître agent » est lu comme le nouveau ; l'ancien préfixe d'agent `maitre-agent:ma-…` reste reconnu (garde-fou, notifications, mod). Variables d'environnement : `MAJORDOME_PROJECT_DIR`, `MAJORDOME_DRY_RUN`, `MAJORDOME_REINJECT_MAX`, `MAJORDOME_PROFIL` ; les anciennes `MAITRE_AGENT_*` restent lues.
- `diagnostic` signale un ancien skill `~/.claude/skills/maitre-agent` et un chemin de barre d'état resté dans l'ancien dossier (information, pas d'erreur).
- Version **1.4.0** dans `plugin.json` du plugin et du mod de bureau.
- Tests : `tests/hooks.sh` couvre les quatre cas du dossier (nouveau seul, ancien seul, les deux, aucun), `migrer.sh`, les anciennes variables, l'ancien préfixe d'agent et le diagnostic (358 vérifications sous `sh` et `dash`) ; les tests TypeScript du mod de bureau sont mis à jour (profil de l'ancien dossier, ancien préfixe) mais **non exécutés ici** (`bun` absent).

### Corrigé
- **« Garder tel quel » est un vrai choix** (blocage) : un projet construit sans cadrage dont tu as choisi « Garder tel quel » continue sans fiche, noté avec sa date dans son `CLAUDE.md` ; les décisions de produit rencontrées en route te sont toujours posées. La reprise ne dit plus que l'atelier « redémarre » quand il n'y a pas de fiche, avec ou sans HANDOFF. « Repartir de zéro » n'est jamais recommandé, et « mettre de côté » veut dire copier dans un dossier daté.
- **Originaux** : le maître et les agents ne modifient jamais tes fichiers d'origine ; un outil livré peut les modifier quand tu le lances ou l'approuves, après un essai à blanc qui liste les changements, avec un retour en arrière (copie ou journal d'annulation). Règle alignée dans `SKILL.md`, `briefs/_entete.md` et les 5 agents.
- **Boutons** : « recommandé » seulement quand une recommandation a un sens (pas pour la langue, le budget, un nom, une préférence, le choix d'un projet) ; au palier de quota 2 ou plus, la réponse recommandée à « lancer ? » est « attendre » ; une option recommandée ne change jamais ta configuration.
- **Premier usage** : langue et tutoiement détectés dans ton message, seuls le niveau et la longueur des réponses sont demandés ; ce que tu viens de choisir n'est plus marqué « à confirmer » ; une seule reconfirmation au plus ; plus d'appel de questions pour les seules lignes annexes.
- **Une validation au lieu de deux** : « Valider et continuer » fusionne l'approbation de la fiche et le point d'étape.
- **Questions de la matrice** : ordre de priorité, 4 questions par appel au plus ; 3 à 4 questions pour un petit projet qui touche tes fichiers.
- **Coût** : annoncé en tokens et en % de la fenêtre de 5 h d'après tes « Repères de coût » ; la part hebdomadaire reste « non mesurée » sans ratio mesuré (exemple mesuré le 2026-10-20 sur Pro : un agent sonnet de ≈ 150 k tokens ≈ 10 points de la fenêtre de 5 h et ≈ 2 points de l'hebdomadaire). Quota hebdomadaire de palier 2 ou plus lu au démarrage : annoncé avant l'atelier, avec « cadrer maintenant, agents après la remise à zéro ». Code de sortie 2 de `quota.sh hebdo` = palier 2 (et non « sans mesure »).
- **Taille d'un projet** : critères objectifs (écrans, données, comptes, fichiers) et mots-clés en français et en anglais, un seul tableau (`phases.md`) ; jeux et démos alignés entre `matrice.md` et `phases.md` ; une ligne de parcours « petit projet à construire ».
- **Achat ou décision sans agent** : pas de dossier de projet, pas d'entrée dans « Projets connus ». Réponse de décision : une règle de longueur (8 lignes en `econome`, avec ce qu'on garde : le choix, le prix, 2 raisons, 1 risque, les liens). Sans outil web, un agent source et le maître écrit « non vérifié à la source ».
- **Nouveau projet** : `reglages.sh actifs` est appelé avec `MAITRE_AGENT_PROJECT_DIR` tant que le dossier du projet n'est pas le dossier courant (avant : il lisait le `CLAUDE.md` d'un autre projet). `phases.md` dit quelles étapes précèdent le tour 1.
- **Lectures évitées** : un petit projet sans agent ne lit ni les clés de réglages ni les préréglages ; `cadrage.md` se lit par sections.
- **`statut`** affiche « quota : non lu » dans l'appli au lieu de rien, et se limite aux 3 projets les plus récents. **`reglages`** sans argument pose « Quoi changer ? » à boutons ; le préréglage d'abord, les clés ensuite.
- **`reglages.sh set`** : une clé de quota réglée à la main (valeur différente de celle du préréglage) fait passer `prereglage` à `personnalise`, et le dit.
- `SKILL.md` repasse sous 5 000 tokens : les détails de la fenêtre hebdomadaire, du seuil de contexte et du rythme sont dans le nouveau `quota.md`.
- Évaluations : `08-reprise-sans-cadrage.md` mise à jour (Garder / Adapter / Repartir), `11-renommer-les-photos.md` ajoutée. Écrites, **pas lancées**.
- Tests : 6 nouvelles vérifications (`personnalise`, variable du dossier du projet).

## [1.3.0] - 2026-10-19

Le skill devient accompagnant : tu décides du produit, il décide de l'exécution et te l'explique. Rien n'est construit avant ta validation. Les valeurs de ce lot sont des réglages de conception, vus par les tests des scripts, pas encore en vraie session (voir « Non vérifié »).

### Ajouté
- **Atelier de cadrage** (`skills/maitre-agent/cadrage.md`) pour tout projet à construire : 3 tours (le quoi, le comment, la fiche), 4 questions à boutons au plus par appel, la recommandation en premier avec son pourquoi, liste numérotée sans outil de questions. Petit projet : version courte.
- **Fiche projet** `docs/FICHE.md` (gabarit `templates/FICHE.md`, une page) : objectif, critères de réussite, fonctions du MVP, hors périmètre, technos, décisions datées « décidé par toi le… », questions ouvertes. Fin de l'atelier : « Valider / Modifier / Tout revoir ». Aucun code ni agent d'implémentation avant « Valider » (un « go » ne vaut pas validation), y compris à la reprise (`reprise.md`). Décision produit changée après validation : fiche repassée en brouillon, re-validation.
- **Relevé des outils** avant le premier tour (MCP connectés, types d'Artifact, navigateur, simulateur, outil de questions) : il ne propose que ce qui existe.
- **Maquette avant le code** (`phases.md`, section Maquette) pour tout livrable avec une interface : échelle de ta maquette fournie, outil de design connecté (lire est permis, écrire demande ton accord), Artifact privé, HTML statique `maquette/index.html`, aperçu texte dans les boutons. La maquette validée est la référence ; le testeur compare à elle (`briefs/testeur.md`).
- **Points d'étape** après la fiche, la maquette et chaque jalon, avec la **carte du parcours** (« Étape 3/8 : Maquette (à valider) · validé : … · reste : … »), le coût de la suite et « Continuer / Ajuster / S'arrêter ». Au-delà d'environ 40 % de contexte, proposition de repartir d'une session neuve depuis HANDOFF.
- **Garde-fou `hooks/garde-fiche.sh`** (hook `PreToolUse`, branché dans `hooks/hooks.json`, copie manuelle décrite dans `installation.md` §6) : refuse `Write`, `Edit`, `MultiEdit`, `NotebookEdit` hors de `docs/`, `maquette/`, `CLAUDE.md` et `.claude/`, et le lancement de `ma-executant`, tant que `docs/FICHE.md` n'est pas « validée » et sa ligne « Maquette validée » renseignée. Inactif sans fiche portant une ligne « Statut : … ». Il bloque par le code de sortie 2.
- **Préréglage selon le forfait** : à la première utilisation, le skill lit `plan.plan` de l'outil d'usage et propose `econome` (Pro), `normal` (Max 5x) ou `intensif` (Max 20x, clé API), confirmé une fois (`reglages.md`, « Forfait et préréglage »). Chaque préréglage règle aussi, en règles écrites, les recherches, les tours d'audit, les variantes de maquette et le testeur.
- **`skills/maitre-agent/matrice.md`** : quoi adapter selon le type de projet (logiciel avec ou sans interface, jeu, contenu, analyse de données, achat ou décision), et la reprise d'un projet construit sans cadrage (garder / adapter / repartir).
- **Evals 06 à 10** (`evals/`) : pas de construction avant la fiche, jeu avec maquette avant le code, reprise sans cadrage, projet sans interface, outils de maquette. Écrites, **pas lancées**.
- Gabarits `templates/CLAUDE.md` et `templates/HANDOFF.md` : lignes « Fiche : brouillon / validée le… » et « Maquette : … ».
- **Quota hebdomadaire** (fenêtre de 7 j) : deux réglages à 3 entiers. `seuils-hebdo` (défaut `20 40 60`) regarde l'écart en points entre le % utilisé et le % écoulé de la semaine ; `plafonds-hebdo` (défaut `85 92 97`) regarde le % utilisé. Palier = le plus haut des deux ; palier 3 aussi à 90 % utilisé ou plus avec une projection ≥ 300 %. À moins de 12 h de la remise, ou si moins de 10 % de la semaine est écoulé : les plafonds seuls. Le script calcule le palier (`quota.sh hebdo <% utilisé> <remise>`) ; le modèle ne calcule rien. **Alertes 7 j** de la barre d'état, une par palier et par remise.
- **`hooks/diagnostic.sh`** : la sous-commande `diagnostic` (alias `doctor`) appelle ce script, en lecture seule. 8 vérifications numérotées, chacune « OK », « KO » (avec la commande pour corriger), « info » ou « non vérifié », puis « N KO sur 8 ». Le modèle recopie le tableau, il ne refait aucune vérification. Mesuré : la section `diagnostic` de `commandes.md` passe de 2 526 à 713 octets.
- Tests : `tests/hooks.sh` passe de 76 à 327 vérifications (sous `sh` et sous `dash`, 0 échec, mesuré le 2026-10-19), dont les 4 valeurs d'`autonomie`, `opus-avec-audits`, les paliers hebdomadaires, et chaque cas du garde-fou, en français et en anglais.
- **Sobriété en tokens** (lot 12) : pas de sous-agents d'agents (`SKILL.md`, §3) : Claude Code le permet jusqu'à 3 niveaux, le skill ne le fait pas (contexte neuf à chaque niveau, coût caché du suivi de quota, vérification par le seul maître). **Connecteurs** (`cadrage.md`) : jamais coupés par défaut. L'option recommandée est « Tout garder » ; le skill ne coupe que les connecteurs que tu nommes, et rappelle que cela change le défaut des nouvelles sessions. En mode auto, le contrôle automatique peut refuser : le chemin manuel est « menu +, puis Connecteurs ». Briefs lus **par sections** (`briefs/_entete.md`). Maquette simple faite par le maître (`phases.md`) ; variantes par `ma-executant` avec `briefs/maquette.md`. **Gain non mesuré** ; repère, une seule mesure : le lot 12 a coûté 68 k tokens en 3 min, contre 110 à 250 k pour les lots précédents.

### Modifié
- **Texte interne du skill en anglais** (lot 13) : `SKILL.md`, fichiers du skill, briefs, gabarits et définitions des agents. Ce que tu vois reste dans la langue de ton profil ; les messages des scripts restent en français ; le garde-fou lit les fiches en français et en anglais. Mesure (même texte, une mesure chacun, mesure de développement, non publiée) : `SKILL.md` ≈ 8 800 tokens réels en français, ≈ 6 200 en anglais (−30 %) ; le README coûte ≈ 25 % de tokens de plus en français.
- **`autonomie`** : 4 valeurs (`accompagnant`, `techniques`, `tout-demander`, `tout-sauf-accords`), défaut **`accompagnant`** (avant : `techniques`, qui reste valide). Elle ne porte que sur l'exécution ; les décisions produit (forme, plateforme, public, fonctions du MVP, technos principales, données, style, budget) sont toujours à toi.
- **`modeles`** : nouvelle valeur `opus-avec-audits` (le plus capable aussi pour les audits). Aucune valeur supprimée, `jamais-opus` reste valide.
- **Préréglages** écrits par `reglages preset` : `econome` = seuils 60 75 85, `budget-lot` 15 %, `modeles opus-conception-seulement` (avant : `jamais-opus`), `agents-paralleles 2` (avant : 1), rapports courts ; `normal` = `agents-paralleles 4` (avant : rien d'écrit) ; `intensif` = en plus `modeles opus-avec-audits`. Quota hebdomadaire : `econome` = `seuils-hebdo 15 30 45` et `plafonds-hebdo 80 90 95` ; `intensif` = `seuils-hebdo 30 50 70` et `plafonds-hebdo 90 95 98` ; `normal` ne change pas les défauts (20 40 60 et 85 92 97). Un préréglage garde désormais la ligne `autonomie`. L'économie d'`econome` n'est toujours pas mesurée.
- **Premier lancement** : une première série de 4 questions (accompagnement, dossiers, langue/ton/niveau, préréglage du forfait en premier) remplace la question « garder les défauts / économe / intensif / personnaliser » ; « toujours demander avant… » devient une phrase annoncée.
- **« Annonce et lance »** ne vaut plus pour le produit : un projet à construire passe par l'atelier et les points d'étape. Il reste pour une décision, un achat, un plan et pour l'intérieur technique d'un jalon validé. Les « questions bloquantes » (2 au plus) sont remplacées par le tour 1 pour un projet à construire.
- Le plugin ajoute un hook `PreToolUse` : **il tourne dans toutes tes sessions** (comme les autres hooks) et ne fait rien hors d'un projet dont `docs/FICHE.md` porte une ligne « Statut : … ».
- `SKILL.md` condensé pour rester sous la limite du lint (16 443 octets en anglais, version publiée, `wc -c` du 2026-10-19 ; limite : 16 500) ; les corrections de code (3 tours) sont détaillées dans `phases.md`.
- **Économies de tokens** (lot 17, audit de l'existant). Gains **estimés** (chiffres de l'audit, non remesurés en session), sauf ceux marqués « mesuré » (octets comptés) :
  - Quota lu seulement quand un agent va tourner (démarrage, avant un lot, frontière de phase) ; jamais pour une sous-commande ni un petit projet sans agent. Estimé : ≈ 8 k par projet moyen.
  - Reprise : seulement les briefs des agents en cours ou à reprendre. Estimé : ≈ 3,6 k par reprise type.
  - Brief écrit une fois ; l'appel de l'agent dit seulement « lis ce chemin ». Estimé : 0,4 à 1,1 k par agent.
  - HANDOFF plafonné à 8 Ko (les sections finies vont dans `docs/HANDOFF-archive.md`, jamais lu à la reprise). Estimé : ≈ 3,5 k sur le HANDOFF du dépôt de développement.
  - Profil : plafond par rubrique (coûts 8, projets 15, habitudes 15, usages 15 entrées). Estimé : 0 aujourd'hui, ≈ 7,8 k à 50 projets.
  - `hooks/reinject.sh` borné à 3 000 octets. Mesuré : 6 078 → 852 octets sur le HANDOFF du dépôt de développement.
  - Fichiers lus par section (`phases.md`, `commandes.md`, `reglages.md`). Mesuré : un petit projet lit ≈ 6,6 ko sur les 15,8 ko de `phases.md` ; la section « Plan et préréglage » de `reglages.md` fait 1 060 octets sur 10 187.
  - `statut` : seulement les lignes « en cours / à reprendre » (estimé ≈ 1,8 k par projet) ; `reglages` : seulement les clés qui ne sont pas au défaut (estimé ≈ 1,5 k).
  - Non mesuré : le gain réel d'une session entière, aucune session n'ayant été jouée avec ce lot.

### Non vérifié
- **Deux sessions de test neuves (2026-10-19), deux essais**, pilotées par le maître agent, qui jouait l'utilisateur par messages. **Premier essai** (skill en français). **Vu** : tours 1 et 2 en liste numérotée avec recommandation ; tour 1 avec 5 questions (limite 4 : écart) ; « go » refusé avant « Valider » ; garde-fou refusant un `Write` hors de `docs/` tant que la fiche était en brouillon (message du hook montré à Claude) ; fiche validée ; maquette HTML de 3 écrans testée dans le navigateur ; point d'étape « Étape 2/7 », coût de la suite, Continuer / Ajuster / S'arrêter ; arrêt propre. **Second essai** (skill interne en anglais, réponses en français) : **vu** : tout en français (questions, fiche « Statut : validée », point d'étape) ; 4 questions par tour, plafond respecté ; question des connecteurs posée ; point d'étape « Étape 2/5 » ; maquette en Artifact privé et `maquette/index.html`, une seule capture ; aucun code sur le disque ; arrêt demandé après la maquette. Effet de bord : un connecteur a été coupé par la session de test, puis rallumé avec l'accord de l'utilisateur ; le lot 17 pose ensuite la règle « jamais coupé par défaut ». **Non vu** : les boutons de l'outil de questions (le premier essai les remplaçait par une liste ; le second ne les note pas), les sous-agents sous le garde-fou, la proposition de session neuve à 40 %, la carte complète du parcours, l'application de `accompagnant`. Les evals 06 à 10 sont écrites, **pas lancées**.
- **Le garde-fou a été appelé par Claude Code une fois** (essai du 2026-10-19, hook branché à la main dans le projet de test), et il est testé avec des JSON factices. Non vérifié : son branchement par le plugin, son application aux outils des sous-agents (la documentation le dit), la forme de l'entrée de `MultiEdit` et `NotebookEdit`, le nom d'outil `Task`, l'affichage du refus à l'utilisateur. Limites connues : les écritures par `Bash` ne sont pas filtrées ; il lit le texte de la fiche et ne sait pas si tu as réellement répondu « Valider » ; liens symboliques non suivis ; chemins Windows non gérés.
- **`plan.plan` pour Max** : seule la valeur « Pro » a été vue ; les valeurs Max (et celle d'une clé API) sont déduites, une valeur inattendue se demande.
- **Réglages de conception non mesurés** : nombre de recherches, tours d'audit, variantes de maquette et agents par préréglage.
- **Faits Figma** (outil `use_figma`, bêta, forfait payant, droit d'édition, payante à l'usage) : repris de la documentation officielle de Figma lue le 2026-10-19 par une session précédente, non relus à la source pour cette version ; le support exact par Claude Code n'est pas vérifié.

### Efficacité (mesures du 2026-10-19, `claude plugin details`, CLI 2.1.299, estimations de la CLI, plugin installé depuis une copie des fichiers publics dans un HOME factice)
| | v1.2.0 | v1.3.0 |
|---|---|---|
| Coût permanent (chaque session) | environ 252 tokens | environ 252 tokens |
| Coût à l'appel du skill | environ 3,7 k | environ 3,9 k |

- `SKILL.md` : 15 684 octets en 1.2.0 (texte français, mesuré au commit de publication aaebe09), 16 443 en 1.3.0 (texte anglais, version publiée, `wc -c` du 2026-10-19 ; limite du lint : 16 500). Les chiffres de `claude plugin details` ci-dessus n'ont pas été remesurés après le lot 17. Les ajouts de détail vont dans `cadrage.md`, `phases.md` et `matrice.md`, lus seulement quand l'étape en a besoin. Le garde-fou est un hook : l'outil ne lui compte aucun coût de contexte.

## [1.2.0] - 2026-10-19

Réglages personnalisables, demandés par l'utilisateur. Rien ne change pour qui ne règle rien.

### Ajouté
- **Rubrique `## Réglages` du profil** (lignes `- <clé> : <valeur>`) et **`## Réglages du projet`** du `CLAUDE.md` d'un projet, qui surcharge le profil pour ce projet. Clés : `seuils`, `budget-lot`, `autonomie`, `modeles`, `agents-paralleles`, `notifications`, `barre`, `git`, `langue`, `ton`, `rapports`, plus `prereglage`. Absente, illisible ou invalide : le défaut d'avant. Détail dans `skills/maitre-agent/reglages.md`, lu seulement par la commande ou quand un réglage est utilisé.
- **Sous-commande `reglages`** (alias `settings`) : tableau valeur actuelle / défaut, `reglages <clé> <valeur>` (avec « avant » et « après »), `reglages econome|normal|intensif`, `reglages reset`. La vérification et l'écriture sont faites par le script `tools/reglages.sh` (copié dans `skills/maitre-agent/hooks/`), pas par le modèle.
- **Préréglages** : `econome` (seuils 60 75 85, `budget-lot` 15 %, `jamais-opus`, un agent à la fois, rapports courts ; en plus briefs courts, recherche seulement pour les questions décisives, testeur au dernier jalon seulement), `normal` (les défauts), `intensif` (seuils 80 90 95, `budget-lot` 40 %, 5 agents). L'économie réelle d'`econome` n'est pas mesurée.
- **Premier lancement** : une question à boutons de plus, « garder les défauts (recommandé) / économe / intensif / personnaliser » ; avec un profil « forfait Pro », `économe` passe en premier.
- **Scripts** : `hooks/statusline.sh`, `hooks/notify.sh` et `tools/quota.sh` lisent `seuils`, `notifications` et `barre` (profil, puis `CLAUDE.md` du dossier courant), avec repli sur les défauts ; `cout` ajoute le coût de la session à la barre quand le JSON donne `cost.total_cost_usd`. Le mod de bureau lit `seuils` et `notifications` (par `$.env.get("HOME")` et `$.fs.read`), pas `barre`.
- **Récap de fin de projet** (`phases.md`, étape de livraison) : tableau agents / modèle / tokens / durée / part du quota tiré du tableau « Agents lancés » du HANDOFF (nouvelle colonne « Coût » du gabarit, script `tools/recap.sh`), et une ligne « pour la prochaine fois » avec un réglage conseillé.
- Tests : `tests/hooks.sh` passe de 24 à 76 vérifications (seuils 60 75 85, notifications `rien`, barre sans jalon, réglages du projet qui surchargent, `reglages.sh`, `recap.sh`) ; le mod passe de 28 à 38 tests.

### Modifié
- `quota.sh` sort avec le seuil atteint (les seuils réglés ; 70, 80, 90 par défaut). Le skill parle de 1er, 2e et 3e seuil.
- `notifications` : sans ce réglage, les fichiers `notifications-on` et `notifications-off` décident comme avant ; avec lui, `notifications-off` coupe encore tout.
- Gabarit `HANDOFF.md` : colonne « Coût (tokens · durée · % fenêtre) » dans « Agents lancés ».

### Efficacité (mesures du 2026-10-19, `claude plugin details`, CLI 2.1.299, estimations de la CLI)
| | avant (v1.1.1, dépôt de départ) | après (v1.2.0) |
|---|---|---|
| Coût permanent (chaque session) | environ 267 tokens | environ 252 tokens |
| Coût à l'appel du skill | environ 3,6 k | environ 3,7 k |

- Le coût permanent baisse (description et `when_to_use` resserrés) ; le plafond demandé était 257. Le coût à l'appel monte d'environ 0,1 k au plus (mesure arrondie à 0,1 k près ; `SKILL.md` : 15 465 puis 15 684 octets).
- Une mesure antérieure donnait 257 pour la v1.1.1 ; la remesure du dépôt de départ donne 267.

## [1.1.1] - 2026-10-19

Corrections et ajouts issus d'une critique extérieure du dépôt publié (15 corrections, 5 modifications, 4 ajouts ; ceux de cette version sont listés ici).

### Corrigé
- **Barre d'état et notifications** : les caractères de contrôle (séquences d'échappement du terminal : titre de fenêtre, effacement d'écran…) sont retirés du jalon, du nom de projet et des textes de notification (`hooks/statusline.sh`, `hooks/notify.sh`).
- **Notifications** : un texte qui commence par « - » n'est plus perdu (`--` avant le texte pour `osascript` et `notify-send`) ; les `**` du markdown sont retirés.
- **Jalon de la barre d'état** : plus de repli sur la première ligne de « Reprise immédiate » (souvent une phrase fixe) ; seule la ligne `Jalon :` compte, comme dans le mod de bureau, et un gabarit non rempli est ignoré des deux côtés.
- **Mod de bureau** : le gestionnaire `agent.spawn` ne lève plus d'exception (`try/catch` et `.catch` du moteur) ; les seuils d'alerte se comparent au pourcentage arrondi affiché (69,6 % déclenche l'alerte de 70 %, comme dans le terminal).
- **Compteur d'agents** : il compte tous les sous-agents (aussi le repli `general-purpose`) ; la notification de fin reste limitée aux `ma-*` ; un fichier de compteur est ignoré après 5 h (la fenêtre de quota) au lieu de 6 h ; les dossiers d'état vides sont purgés.
- **Alertes de quota** : un verrou atomique (`mkdir`) évite les alertes en double quand plusieurs sessions franchissent un seuil en même temps (12 appels simultanés : 2 à 4 alertes avant, 1 après, trois essais sur trois).
- **Réinjection après résumé** : le contenu du HANDOFF est annoncé comme une donnée, pas comme une instruction.
- **Build local de la release** : `tools/build-release.sh` n'embarque plus que les fichiers suivis par git (un `.env` ou des notes non suivis ne partent plus dans le zip).
- **Méthode** : le quota est lu par `hooks/quota.sh` (qui lit `usage.json`) quand aucun outil d'usage n'existe ; à ≥ 70 % la conception et le tour 3 passent sur le modèle intermédiaire, en le disant ; à ≥ 80 % le skill propose le lot, coût annoncé, et n'attend qu'un oui explicite (une demande directe ne suffit pas) ; le rythme n'est calculé que si `resets_at` est connu ; sans mesure, « plus de 3 agents » remplace « 30 % de la fenêtre ».
- **Méthode** : règle « forfait Pro » (Moyen plafonné à 1 conception + 2 recherches, jalons en séquence ; Gros annoncé « plusieurs fenêtres, N jours » avant de commencer) ; testeur au dernier jalon seulement pour un Moyen ; la première utilisation ne propose plus d'installer des agents déjà fournis par le plugin ; routage précisé (projet = dossier avec `docs/HANDOFF.md` ou `CLAUDE.md`) ; le skill utilise le nom exact des agents affiché par l'outil de sous-agents (avec ou sans préfixe `maitre-agent:`).
- **Documentation** : workflows verts le 2026-10-18, installation depuis la marketplace GitHub réussie (CLI 2.1.299, HOME factice, URL HTTPS complète), tailles mesurées par `claude plugin details` (v1.1.1 : environ 3,6 k tokens à l'appel du skill, environ 257 permanents ; v1.1.0 : 3,4 k et 285 selon la critique), chemin du cache pour copier `statusline.sh` (observé sur 2.1.299).

### Modifié
- **Chargement limité aux demandes explicites** : description et `when_to_use` resserrés (commande `/maitre-agent`, ou demande explicite de la méthode). `disable-model-invocation` écarté, car il empêcherait une autre session de lancer le skill par l'outil Skill.
- **La notification « Claude attend » (hook `Notification`) est désactivée par défaut** ; elle s'active avec le fichier `~/.claude/maitre-agent/notifications-on`. La fin d'agent `ma-*` et les alertes de quota restent actives ; `notifications-off` coupe tout.
- `evals/05-quota-80.md` : à ≥ 80 %, le comportement attendu est « proposer, coût annoncé, accord explicite » (et non plus « refus même sur demande directe »).

### Ajouté
- **Sous-commande `diagnostic`** (alias `doctor`) : 8 contrôles en lecture seule (`jq`, barre d'état, skill et agents en double, quota lisible, notifications, version, profil), chacun « OK / KO + commande pour corriger ».
- **`tools/quota.sh`** (copié dans `skills/maitre-agent/hooks/`) : lit `usage.json`, vérifie l'âge de la mesure (15 min) et la fin de fenêtre, affiche les fenêtres et sort avec le palier (0, 70, 80, 90 ; 2 = pas de mesure).
- **`tests/hooks.sh`** : tests des scripts avec des JSON factices (HOME factice, aucune notification réelle), appelés par `lint.yml` ; 24 vérifications.
- Le lint refuse `disable-model-invocation: true` et accepte `tools/` comme source d'un script copié dans le skill.

### Limites connues
- Les hooks du plugin n'ont toujours pas été déclenchés par Claude Code dans une vraie session ; le comportement de `SubagentStop` sur un agent interrompu n'est pas vérifié.
- La résolution du nom exact des agents sous plugin dans une vraie session n'a pas été essayée.
- Le chemin `.catch` du mod de bureau n'est pas couvert par un test.
- Non repris dans cette version : les évaluations réelles, la première utilisation sans questionnaire.

## [1.1.0] - 2026-10-18

### Ajouté
- **Plugin Claude Code** : `.claude-plugin/plugin.json`, marketplace `.claude-plugin/marketplace.json` (deux plugins : `maitre-agent` et `maitre-agent-bureau`), `agents/` (les 5 sous-agents `ma-*`) et `hooks/hooks.json`.
- **Barre d'état du terminal** (`hooks/statusline.sh`) : projet, jalon, nombre d'agents, quota 5 h et 7 j avec heure de remise à zéro. Repli propre si le quota manque. Le script écrit aussi le quota dans `~/.claude/maitre-agent/usage.json`.
- **Notifications** (`hooks/notify.sh`) : fin d'un sous-agent `ma-*`, session bloquée (demande d'autorisation, attente), quota à 70, 80 et 90 %. macOS (`osascript`), Linux (`notify-send` s'il existe). Jamais bloquantes. Désactivables en créant le fichier `~/.claude/maitre-agent/notifications-off`.
- **Compteur d'agents** (`hooks/agent-count.sh`) branché sur `SubagentStart` et `SubagentStop`.
- **Mod de bureau `maitre-agent-bureau`** (`bureau/`) : ligne d'état dans l'onglet Code de l'app Claude de bureau (qui n'appelle pas `statusLine`), alertes de quota, toast de fin d'agent. API des mods en accès anticipé, écrite pour Claude Code 2.1.299.
- **Sous-commandes** de `/maitre-agent` : `aide` (`help`, `?`), `statut`, `reprendre`, `profil`, `nouveau <idée>` ; détail dans `skills/maitre-agent/commandes.md`.
- **Décisions en boutons** : toute question passe par l'outil de questions de l'environnement quand il existe (option recommandée en premier), liste numérotée sinon.
- **« Depuis ta dernière visite »** à chaque reprise (3 lignes) ; lignes « Dernière visite » et « Jalon » dans le modèle de HANDOFF.
- **Chapitres** : un chapitre par phase si l'outil `mark_chapter` existe, rien sinon.
- **Trois voies d'installation** documentées (plugin, copie du skill, zip de release) dans `skills/maitre-agent/installation.md`.
- **Outillage** : `tools/lint-skill.sh` (YAML, taille du skill, renvois, cohérence du plugin, traces personnelles), `tools/build-release.sh` (zip du skill et zip du plugin), `tools/changelog-section.sh` (notes de release).
- **GitHub Actions** : `lint.yml` à chaque push, `release.yml` sur les tags `v*`.
- **Vitrine** : `README.md` et `README.en.md`, `docs/fabrication.md`, `CONTRIBUTING.md`, `LICENSE` (MIT).
- **Évaluations** : 5 scénarios écrits dans `evals/`, pas encore lancés.

### Modifié
- `SKILL.md` : routage des sous-commandes, `argument-hint` mis à jour, questions en boutons, chapitres ; détail déplacé dans `commandes.md` pour rester sous 5 000 tokens.
- `reprise.md` : étape « Depuis ta dernière visite ».
- Le nom de commande dépend de la voie : `/maitre-agent:maitre-agent` via le plugin (`/maitre-agent` aussi tant qu'aucun autre skill ne le prend), `/maitre-agent` via la copie du skill.

### Limites connues
- La barre d'état du terminal n'est pas affichée dans l'app de bureau (d'où le mod).
- Les hooks du plugin n'ont pas été testés de bout en bout par Claude Code ; les workflows GitHub n'avaient pas encore été exécutés à la date de cette version.
- L'installation depuis la marketplace GitHub n'a pas pu être essayée avant la publication (validation statique seulement).
- Noms courts des agents sous plugin (`ma-chercheur` au lieu de `maitre-agent:ma-chercheur`) : non vérifié.
- Les alertes de quota exigent la barre d'état (terminal) ou le mod (bureau) ; elles ne viennent pas des hooks du plugin.
- Un plugin ne peut pas installer `statusLine` ni `permissions.ask` : ces deux réglages restent manuels.

## [1.0.0] - 2026-10-18

Première version, utilisée en local avant d'être publiée.

### Ajouté
- **Skill `maitre-agent`** : une session principale (le « maître agent ») cadre, découpe, délègue à des sous-agents, vérifie elle-même les faits décisifs et rend compte.
- Profil de l'utilisateur lu en premier (`profil-modele.md`), routage (nouveau projet ou reprise), proportionnalité (le plus petit résultat utilisable).
- Délégation par modèle (léger, intermédiaire, le plus capable) avec modèle toujours explicite, briefs enregistrés, suivi dans un tableau « Agents lancés ».
- Vérification : tableau de preuves exigées, audits bornés à 2 tours, corrections de code bornées à 3 tours avec escalade, protocole des 3 échecs.
- Permissions : accord demandé avant argent, installation, publication, envoi, compte, action irréversible ; interdits (protections, œuvres protégées, achats).
- Quota : seuils 70 / 80 / 90 % (plus d'agent le plus capable, plus de nouvel agent, arrêt propre).
- Passation : `HANDOFF.md` avec balises [V] et [?], reprise après coupure, templates de projet.
- 5 sous-agents `ma-*` (chercheur, auditeur, testeur, concepteur, exécutant), sans l'outil Agent et avec un plafond de tours.
- Hook `SessionStart` (`compact|resume`) qui réinjecte l'état de HANDOFF après un résumé ou une reprise.
- Règles `permissions.ask` recommandées pour les commandes risquées.
- Contrôle local du skill (`lint-skill.sh`).
