# Changelog

Toutes les évolutions notables de ce projet sont notées ici.
Le format suit [Keep a Changelog](https://keepachangelog.com/fr/1.1.0/) et le projet suit le [versionnement sémantique](https://semver.org/lang/fr/).

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
