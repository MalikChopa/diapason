# Réglages

Lis ce fichier **seulement** pour la sous-commande `reglages`, ou quand `sh SKILL_DIR/hooks/reglages.sh actifs` (lancé depuis le dossier du projet) affiche autre chose que « réglages : défauts ». Qui ne règle rien ne le lit jamais.

## Où et comment
- Profil : rubrique `## Réglages` de `~/.claude/maitre-agent/profil.md`, une ligne `- <clé> : <valeur>` par réglage. Un commentaire entre parenthèses en fin de ligne est ignoré.
- Projet : rubrique `## Réglages du projet` du `CLAUDE.md` du projet, même format. Elle **surcharge le profil** pour ce projet, clé par clé. Lis-la à la reprise (`reprise.md`) et au démarrage (`phases.md`) : c'est ce que fait `reglages.sh actifs`.
- Absente, illisible ou invalide (clé inconnue, valeur hors liste) : la valeur du dessous (profil, puis défaut). Rien ne change pour qui ne règle rien.
- **Les scripts font le travail, pas toi** : `hooks/reglages.sh` (dans `SKILL_DIR`) vérifie, écrit et affiche ; la barre d'état, `quota.sh` et `notify.sh` lisent eux-mêmes `seuils`, `notifications` et `barre` ; le mod de bureau lit `seuils` et `notifications`. Toi, tu appliques les autres clés d'après le tableau.
- Lire : `sh SKILL_DIR/hooks/reglages.sh` (tableau clé, valeur en vigueur, défaut, source). Écrire : `sh SKILL_DIR/hooks/reglages.sh set [--projet] <clé> <valeur>`, `preset econome|normal|intensif`, `reset`. Il montre « avant » et « après ». Sans profil (code 2), crée-le d'abord (`profil-modele.md`).

## Les clés
| Clé | Valeurs | Défaut | Effet |
|---|---|---|---|
| `seuils` | 3 entiers croissants, 10 à 99 | `70 80 90` | 1er seuil : plus d'agent du modèle le plus capable ; 2e : proposer le lot et attendre un oui (SKILL §6) ; 3e : arrêt propre. Aussi les alertes de la barre d'état et du mod, et le palier de `quota.sh` |
| `budget-lot` | 5 à 100 % | `30 %` | taille de lot (part de la fenêtre de 5 h) au-delà de laquelle tu demandes l'accord (SKILL §3, §7). Sans mesure du quota : plus de 3 agents, ou plus de `agents-paralleles` s'il est plus petit |
| `autonomie` | `techniques`, `tout-demander`, `tout-sauf-accords` | `techniques` | `techniques` : tu tranches les choix techniques et tu notes (ligne « Autonomie » du profil). `tout-demander` : question à boutons avant chaque choix (outil, méthode, critères). `tout-sauf-accords` : tu tranches tout, sauf les accords du §5 et les questions bloquantes |
| `modeles` | `defaut`, `jamais-opus`, `opus-conception-seulement` | `defaut` (léger / intermédiaire / le plus capable, SKILL §3) | `jamais-opus` : jamais le modèle le plus capable, la conception passe sur l'intermédiaire. `opus-conception-seulement` : le plus capable pour la conception, l'architecture et la spécification seulement ; code et reste au plus intermédiaire. Dis-le une fois |
| `agents-paralleles` | 1 à 5 | `5` | agents en même temps. `1` : tout en séquence. La règle « forfait Pro » de `phases.md` reste un plafond tant que ce réglage n'est pas écrit |
| `notifications` | `agent+quota`, `tout`, `quota`, `rien` | `agent+quota` | `tout` : en plus « Claude attend ». `quota` : alertes de quota seulement. `rien` : aucune. Sans ce réglage, les fichiers `notifications-on` / `notifications-off` (dossier `~/.claude/maitre-agent/`) décident comme avant ; `notifications-off` coupe tout, toujours |
| `barre` | mots parmi `projet` `jalon` `agents` `quota` `cout`, dans l'ordre voulu | `projet jalon agents quota` | éléments de la barre d'état du **terminal**. `cout` ajoute « coût 0.42 $ » si le JSON de la barre donne `cost.total_cost_usd`, sinon rien. L'app de bureau n'appelle pas la barre d'état : le mod garde sa ligne fixe |
| `git` | `commit-local`, `aucun`, `push-branche` | `commit-local` | `commit-local` : `git init` et un commit par étape vérifiée, aucun push. `aucun` : pas de git. `push-branche` : tu peux pousser une branche de travail vers un dépôt distant **déjà existant**, jamais la branche principale ni `--force`, sans redemander. C'est un accord permanent : demande-le en boutons, la commande écrit la date. Créer un dépôt, publier une release : toujours demander |
| `langue` | `profil` ou un code (`fr`, `en`, `pt-BR`…) | `profil` | langue de tout ce que tu écris |
| `ton` | `profil`, `tutoiement`, `vouvoiement`, `neutre` | `profil` | façon de s'adresser à l'utilisateur |
| `rapports` | `court`, `detaille` | `detaille` | `court` : rapport d'agent de 5 lignes au plus (écris-le dans le brief à la place de « 10 lignes »), tes comptes rendus et réponses de décision de 8 lignes au plus. `detaille` : règles du skill (10 lignes, 15 pour une décision) |
| `prereglage` | `econome`, `normal`, `intensif`, `personnalise` | aucun | écrit par `reglages.sh preset` ; point de départ, une clé écrite à côté le surcharge. Seul `econome` ajoute des règles (plus bas) |

## Préréglages
| Préréglage | Écrit |
|---|---|
| `econome` | `seuils 60 75 85`, `budget-lot 15 %`, `modeles jamais-opus`, `agents-paralleles 1`, `rapports court` |
| `normal` | rien d'autre que `prereglage : normal` : les défauts |
| `intensif` | `seuils 80 90 95`, `budget-lot 40 %`, `agents-paralleles 5` |

## Ce que change `econome`
Pensé pour le forfait Pro. Tant que `prereglage : econome` figure dans la rubrique :
- un seul agent à la fois, jamais le modèle le plus capable (clés ci-dessus) ;
- **briefs courts** : après l'en-tête, la mission en 15 lignes au plus ; des chemins, pas du contenu ; les lignes du profil strictement utiles ;
- **rapports courts** (clé `rapports`) ;
- **recherche seulement pour les questions décisives** : une seule recherche qui regroupe celles-ci, jamais de recherche de confort, phase « Inspiration » sautée sauf demande ;
- **testeur au dernier jalon seulement**, même pour un Gros ; les autres jalons, c'est toi qui testes (SKILL §4, « Preuves exigées ») ;
- alertes plus tôt (60 / 75 / 85 %) et accord demandé dès 15 % de la fenêtre par lot.

**Ordre de grandeur : non mesuré.** Chaque agent évité retire un coût que les repères du skill (SKILL §6, non mesurés par cette version) chiffrent de 100 à 500 k tokens ; la seule mesure du projet est « 3 recherches ≈ 36 % d'une fenêtre de 5 h » (`phases.md`, une seule mesure). Le compte réel d'un projet économe se lit dans le récap de fin de projet (`phases.md`, Livraison) ; compare-le à un projet comparable pour savoir ce que ça a vraiment économisé.

## Pour la prochaine fois
Dans le récap de fin de projet, propose **un seul** réglage : plus économe si le quota a dépassé le 2e seuil ou si un agent a dépassé 40 % de la fenêtre ; plus large (`intensif`, ou `agents-paralleles` plus grand) si le quota est resté sous le 1er seuil et qu'aucun lot n'a été retardé. Sinon : « garde tes réglages ».

## Sous-commande `reglages`
Voir `commandes.md`.
