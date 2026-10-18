# Sous-commandes de `/maitre-agent`

Le premier mot de l'argument décide (majuscules et accents ignorés). Une sous-commande ne lance aucun agent et ne crée aucun projet, sauf `nouveau` et `reprendre`. `statut` et `diagnostic` ne modifient rien. Le profil (SKILL §0) se lit quand même avant, pour la langue et le tutoiement. Réponds dans la langue du profil.

| Commande | Alias | Effet |
|---|---|---|
| `aide` | `help`, `?` | explique le skill en 15 lignes au plus |
| `statut` | `status` | 5 lignes par projet connu |
| `reprendre` | `resume` | choix du projet en boutons, puis reprise |
| `profil` | `profile` | affiche ou modifie le profil |
| `diagnostic` | `doctor` | 8 contrôles en lecture seule de l'installation, chacun « OK / KO + commande pour corriger » |
| `nouveau <idée>` | `new <idée>` | nouveau projet avec cette idée |

## `aide`
Réponds en 15 lignes au plus, sans lire d'autre fichier du skill, en suivant ce plan :
1. **À quoi ça sert** (2 lignes) : mener un projet de n'importe quel type (code, recherche, achat, analyse, rédaction) avec une session principale qui pilote des sous-agents, vérifie elle-même les faits décisifs et garde une passation qu'on peut reprendre n'importe quand.
2. **Comment il travaille** (4 lignes) : profil de l'utilisateur lu en premier ; découpage en tâches, chacune confiée à un agent du modèle adapté (léger, intermédiaire, le plus capable) ; vérification par le maître agent (source primaire, commande, recalcul) ; quota surveillé, avec arrêt propre à 90 % ; accord demandé avant argent, installation, publication, envoi, compte ou suppression.
3. **Sous-commandes** (6 lignes) : le tableau ci-dessus, une ligne par commande, plus `/maitre-agent <chemin>` pour reprendre un projet précis.
4. **Ce qui est installé ici** (2 à 3 lignes) : vérifie et dis oui ou non pour chaque élément : les agents `ma-*` dans `~/.claude/agents/` (ou fournis par le plugin), le hook de réinjection après résumé, la barre d'état et les notifications (`settings.json` ou `hooks.json` du plugin), le profil `~/.claude/maitre-agent/profil.md` (pour tout contrôler : `diagnostic`).
5. **Pour commencer** (1 ligne) : `/maitre-agent <ton idée>`.

## `statut`
1. Lis la rubrique « Projets connus » du profil. Pour chaque projet qui a un chemin, lis son `docs/HANDOFF.md` (sections « État », « Agents lancés », « En attente de l'utilisateur ») et la ligne « Dernière visite ».
2. Si `~/.claude/maitre-agent/usage.json` existe et a moins d'une heure, ajoute en tête une ligne de quota (fenêtre de 5 h et hebdomadaire, heure de remise à zéro). Sinon, lis l'outil d'usage s'il existe.
3. Rends, par projet, 5 lignes au plus : nom et chemin ; dernière visite ; où il en est ; agents encore « en cours » ; ce qu'on attend de l'utilisateur. Un projet sans HANDOFF ou au dossier absent : une ligne, « pas de passation ».
4. Ne modifie aucun fichier.

## `reprendre`
1. Liste les projets connus qui ont un `docs/HANDOFF.md`, du plus récent au plus ancien (ligne « Dernière visite », sinon date du fichier).
2. Pose une question à boutons (SKILL §7) : un bouton par projet, 4 au maximum, le plus récent en premier, marqué « (recommandé) ». Les autres projets restent accessibles par la réponse libre.
3. Projet choisi : place-toi dans son dossier si l'environnement le permet, puis suis `reprise.md`.

## `profil`
Affiche le profil, applique la modification demandée, et ne lance aucun projet. S'il est absent, suis `profil-modele.md`.

## `diagnostic` (alias `doctor`)
En lecture seule : aucun fichier modifié, aucun agent, aucune correction faite toi-même. Lance les 8 contrôles ci-dessous (commandes courtes, sans réseau) et rends un tableau : numéro, contrôle, **OK** ou **KO** (ou **info** quand rien n'est faux), et pour chaque KO la commande exacte à lancer, que l'utilisateur lance ou te demande de lancer. Termine par une phrase : « N KO sur 8 ». `SKILL_DIR` = dossier du skill.

| # | Contrôle | OK si | Sinon, pour corriger |
|---|---|---|---|
| 1 | `jq` | `command -v jq` trouve quelque chose | macOS `brew install jq` ; Debian/Ubuntu `sudo apt install jq` (sans lui : compteur, notifications et barre d'état muets) |
| 2 | barre d'état | `jq -e .statusLine ~/.claude/settings.json` réussit et le script cité est exécutable | ajoute le bloc `statusLine` de `installation.md` §4 ; `chmod +x ~/.claude/maitre-agent/statusline.sh`. App de bureau : la barre n'y est pas affichée, installe `maitre-agent-bureau` (info, pas KO) |
| 3 | skill en double | pas à la fois `~/.claude/skills/maitre-agent/SKILL.md` **et** le plugin `maitre-agent` (vois `claude plugin list` si la commande existe, sinon la liste des skills de la session) | garde une seule voie : `rm -r ~/.claude/skills/maitre-agent` (copie) ou `claude plugin uninstall maitre-agent` |
| 4 | agents en double | pas de `~/.claude/agents/ma-*.md` quand le plugin fournit les agents (`maitre-agent:ma-*` dans l'outil de sous-agents) | `rm ~/.claude/agents/ma-*.md` si le plugin est gardé |
| 5 | quota lisible | `sh SKILL_DIR/hooks/quota.sh` sort avec 0, 70, 80 ou 90 (pas 2) | barre d'état non installée, ou plus appelée depuis 15 min (app de bureau : normal, le mod affiche le quota mais n'écrit pas `usage.json`) ; voir `installation.md` §4 |
| 6 | notifications | info : dis si `~/.claude/maitre-agent/notifications-off` (tout coupé) ou `notifications-on` (notification « bloqué » active) existe ; par défaut, seules la fin d'agent et les alertes de quota notifient | `touch` / `rm` du fichier voulu |
| 7 | version | info : version du plugin (`claude plugin list`) ou du skill copié (`SKILL_DIR/../../.claude-plugin/plugin.json` s'il existe, sinon « inconnue ») ; la dernière version publiée n'est pas vérifiée (pas de réseau) | `claude plugin update maitre-agent@maitre-agent` |
| 8 | profil | `~/.claude/maitre-agent/profil.md` existe | `/maitre-agent profil` le crée |

Un contrôle impossible (commande absente, par exemple `claude` hors du PATH) se note « non vérifié » avec la raison : jamais OK par défaut.

## `nouveau <idée>`
Traite le reste de l'argument comme une idée : SKILL §1, cas « idée », puis `phases.md`. Sans idée après le mot, demande-la en une phrase.
