# Changelog

Toutes les évolutions notables de ce projet sont notées ici.
Le format suit [Keep a Changelog](https://keepachangelog.com/fr/1.1.0/) et le projet suit le [versionnement sémantique](https://semver.org/lang/fr/).

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
