# Nouveau projet : démarrage, taille, squelette, parcours

## 0. Démarrage
1. **Quota** : lis l'usage (SKILL §6).
2. **Contexte** : regarde dans le profil les « Projets connus » et les « Usages » liés à la demande, et relis le `CLAUDE.md` du projet lié s'il y en a un. Ne devine pas un usage que le profil ou un projet indique déjà.
3. **Taille et parcours** : choisis-les d'après les tableaux ci-dessous. « Petit », « simple », « MVP » ou « démo » dans la demande imposent Petit ou Moyen.
4. **Message de démarrage**, un seul, qui contient :
   - le but en une phrase ;
   - la taille et le parcours ;
   - le dossier (préférence « Dossiers » du profil) ;
   - au plus 2 questions bloquantes, plus la question groupée des lignes « à confirmer » du profil ;
   - tes hypothèses pour le reste (« je pars du principe que… ») ;
   - le coût estimé (SKILL §6).

   Attends la réponse **seulement** s'il y a une question bloquante, un accord à demander (§5 du skill) ou un lot de plus de 30 % de la fenêtre. Sinon, annonce et lance dans le même tour. « go » ou une réponse qui ne tranche pas = choix par défaut. Si l'environnement a son propre mécanisme pour poser une question en fin de tour (boutons, encadré), utilise-le.
   Lignes « à confirmer » du profil : ne pose que celles qui concernent cette tâche.
5. **Dossier** : selon la préférence « Dossiers » du profil, un nouveau dossier sous le dossier de projets, jamais à l'intérieur d'un autre projet (sauf demande). Utilise l'outil de changement de dossier s'il existe (il peut être différé : ToolSearch). Sinon, crée le dossier (mkdir, ou l'équivalent de l'OS) et travaille en chemins absolus. Relis toi-même le `CLAUDE.md` du projet. Dans chaque brief, rappelle de lancer les commandes depuis ce dossier.
6. **Relevé** (si le projet en dépend) : outils et versions utiles. Mets à jour la rubrique « Machine » du profil. Dans le projet, ne note que ce qui sert au projet.
7. **Squelette** : copie depuis `SKILL_DIR/templates/`, en traduisant et en remplissant chaque champ (voir le tableau).
   - Contrôle qu'il ne reste aucun champ vide avec l'outil de recherche, ou avec `grep -rnE '<(…|[[:alpha:]])[^>]*>' CLAUDE.md docs/`. Ignore le code légitime (HTML, génériques).

## Taille
| Taille | Exemples | Agents | Fichiers |
|---|---|---|---|
| **Petit** | question, achat, comparatif, plan court, analyse d'un fichier, petit script | 0 à 2 | Sans agent : le livrable seul (aucun dossier si la réponse tient dans le chat). Dès le premier agent : mini-squelette = `CLAUDE.md` court, `docs/HANDOFF.md`, `docs/briefs/`, plus `docs/research/_BRIEF.md` s'il y a une recherche |
| **Moyen** | MVP d'app, site, outil, jeu court ou démo, décision technique | 1 conception + 0 à 5 recherches + 1 à 3 jalons | squelette Moyen |
| **Gros** | produit complet, jeu complet, multi-plateforme | 6 à 15 recherches, conception + spec + audits, jalons, testeurs | squelette Gros, réparti sur plusieurs sessions |

On peut changer de taille en cours de route : dis-le et note-le.

## Squelette
| Template | Destination | Taille |
|---|---|---|
| `CLAUDE.md` | `CLAUDE.md` (racine du projet) | Moyen, Gros (Petit : version courte si le travail dure) |
| `HANDOFF.md` | `docs/HANDOFF.md` | Moyen, Gros (Petit : si le travail dure) |
| `INDEX.md` | `docs/research/INDEX.md` | dès qu'il y a une recherche |
| `_BRIEF.md` | `docs/research/_BRIEF.md` | dès qu'il y a une recherche |
| `JOURNAL.md` | `docs/JOURNAL.md` | dès le premier jalon |
| `RECOMMANDATION.md` | `docs/RECOMMANDATION.md` | décision, achat |
| `PLAN.md` | `docs/PLAN.md` | plan, organisation, contenu |
| — | `docs/briefs/` | dès le premier agent |
| — | `docs/ARCHITECTURE.md`, `docs/SPEC.md` | écrits par l'agent de conception (Gros ; Moyen : ARCHITECTURE seul) |

## Parcours
Annonce-le en 3 lignes et note-le dans HANDOFF. Saute toute phase inutile, en le disant.

| Type | Parcours |
|---|---|
| **Décision, achat** | Cadrage → Recherche → Vérification → Réponse |
| **Plan** (voyage, démarche, événement, organisation) | Cadrage → Recherche → Plan → Vérification → Réponse |
| **Logiciel** (app, site, outil, script, automatisation) | Cadrage → Recherche → Conception → Audit → Jalons → Tests → Livraison |
| **Jeu ou projet créatif interactif** | Cadrage → Inspiration (si pertinent) → Recherche → Assets → Conception → Spec (Gros) → Audits → Jalons → Tests en joueur → Livraison |
| **Contenu** (document, présentation, vidéo, formation, marque) | Cadrage → Recherche → Plan → Production → Audit → Version finale |
| **Données ou analyse** | Cadrage → Inventaire des données → Nettoyage scripté → Analyse → Audit des chiffres → Rapport |

### Cadrage
- But, public, cibles (plateformes, pays), niveau de finition, contraintes : argent, délai, comptes, légal.
- Prends en compte le profil : niveau, outils possédés, pays et devise (pour les prix, les vendeurs, les lois et les démarches).

### Inspiration (si pertinent : projet visuel ou référence citée)
- Un agent analyse la référence : ce qui la rend réussie. **On s'inspire, on ne copie jamais** : ni noms, ni personnages, ni interface, ni assets, ni texte.
- Une planche (palette en codes hex, formes, ambiance) est publiée en artifact privé si l'environnement le permet. Une copie du fichier reste dans le projet. Les règles qui en sortent vont dans `CLAUDE.md`.

### Recherche
Voir `briefs/recherche.md`. Une recherche par question décisive que tu ne sais pas trancher toi-même.

### Assets et travail de l'utilisateur (si pertinent)
- Les premiers jalons tournent avec des formes ou des assets générés par script. Les vrais assets s'intègrent plus tard sans changer le code.
- Pour ce que Claude ne produit pas seul (images, 3D, voix, musique, vidéo, comptes, actions physiques), propose un outil qui produit **ce type d'asset**, d'abord parmi ceux du profil. Donne des prompts prêts à copier, un par fichier, avec le nom de fichier à donner.
- Les fichiers reçus sont des originaux jamais modifiés. Les scripts de `tools/` les traitent et peuvent tout régénérer. Inventaire mesuré dans `docs/ASSETS.md`, contrôle par un agent. Vérifie la licence commerciale avant toute vente.

### Conception (`briefs/conception.md`)
- Compare 2 ou 3 options sur des critères mesurés, surtout ce qui se teste sans l'utilisateur.
- Choisis et justifie en 3 raisons, avec le prix à payer.
- Découpe en jalons J0…Jn, avec des critères mesurables ; J0 = le plus petit squelette qui tourne.
- Audit : 2 tours au maximum.

### Jalons
- Un agent d'implémentation par jalon, seul écrivain du code.
- `docs/JOURNAL.md` tenu à jour.
- Après chaque jalon, tu vérifies toi-même : build, tests, exécution réelle, au moins une capture ou une sortie regardée.
- Git selon le profil.

### Tests (`briefs/testeur.md`)
- À chaque jalon utilisable, un testeur sur une copie isolée.
- Ses bugs bloquants passent en premier au jalon suivant.
- Si l'utilisateur veut voir : le moyen le plus rapide (commande, URL locale, simulateur, artifact), en 3 lignes.

### Plan
- `docs/PLAN.md` : étapes datées, coût de chacune, total comparé au budget, points critiques vérifiés, liens.
- Dans le chat, 15 lignes maximum : le résumé étape par étape, le total et 3 risques.

### Réponse (décision ou achat)
- Dans le chat, 15 lignes maximum, avec un tableau compact : le choix n°1, 2 alternatives, les prix avec leur date, le vendeur et le pays, 3 raisons et les risques.
- Le détail va dans `docs/RECOMMANDATION.md`.

### Production (contenu)
- Un agent rédige (`briefs/implementation.md`, rôle rédacteur).
- Tu relis, puis un audit au besoin.

### Données
- L'original reste où il est (chemin absolu dans `CLAUDE.md`).
- Scripts dans `tools/`, sorties dans `out/`.
- Rapport dans `docs/RAPPORT.md` : question, méthode, chiffres clés, limites, comment reproduire.
- Audit des chiffres par un autre moyen que celui de l'analyse.

### Livraison (si pertinent)
- Recherche dédiée : plateformes, signature, prix, démarches, obligations légales.
- Avant toute publication, vérifie que le nom est libre (marque) et que les licences sont en règle.
- Publier, envoyer, payer : seulement avec l'accord explicite de l'utilisateur.
