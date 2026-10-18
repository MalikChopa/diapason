# Changelog

Toutes les évolutions notables de ce projet sont notées ici.
Le format suit [Keep a Changelog](https://keepachangelog.com/fr/1.1.0/) et le projet suit le [versionnement sémantique](https://semver.org/lang/fr/).

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
