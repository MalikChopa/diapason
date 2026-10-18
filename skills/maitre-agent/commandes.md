# Sous-commandes de `/maitre-agent`

Le premier mot de l'argument décide (majuscules et accents ignorés). Une sous-commande ne lance aucun agent et ne crée aucun projet, sauf `nouveau` et `reprendre`. Le profil (SKILL §0) se lit quand même avant, pour la langue et le tutoiement. Réponds dans la langue du profil.

| Commande | Alias | Effet |
|---|---|---|
| `aide` | `help`, `?` | explique le skill en 15 lignes au plus |
| `statut` | `status` | 5 lignes par projet connu |
| `reprendre` | `resume` | choix du projet en boutons, puis reprise |
| `profil` | `profile` | affiche ou modifie le profil |
| `nouveau <idée>` | `new <idée>` | nouveau projet avec cette idée |

## `aide`
Réponds en 15 lignes au plus, sans lire d'autre fichier du skill, en suivant ce plan :
1. **À quoi ça sert** (2 lignes) : mener un projet de n'importe quel type (code, recherche, achat, analyse, rédaction) avec une session principale qui pilote des sous-agents, vérifie elle-même les faits décisifs et garde une passation qu'on peut reprendre n'importe quand.
2. **Comment il travaille** (4 lignes) : profil de l'utilisateur lu en premier ; découpage en tâches, chacune confiée à un agent du modèle adapté (léger, intermédiaire, le plus capable) ; vérification par le maître agent (source primaire, commande, recalcul) ; quota surveillé, avec arrêt propre à 90 % ; accord demandé avant argent, installation, publication, envoi, compte ou suppression.
3. **Sous-commandes** (5 lignes) : le tableau ci-dessus, une ligne par commande, plus `/maitre-agent <chemin>` pour reprendre un projet précis.
4. **Ce qui est installé ici** (2 à 3 lignes) : vérifie et dis oui ou non pour chaque élément : les agents `ma-*` dans `~/.claude/agents/` (ou fournis par le plugin), le hook de réinjection après résumé, la barre d'état et les notifications (`settings.json` ou `hooks.json` du plugin), le profil `~/.claude/maitre-agent/profil.md`.
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

## `nouveau <idée>`
Traite le reste de l'argument comme une idée : SKILL §1, cas « idée », puis `phases.md`. Sans idée après le mot, demande-la en une phrase.
