# Profil de l'utilisateur

Emplacement : `~/.claude/maitre-agent/profil.md`, hors du skill, pour qu'une mise à jour ou un partage du skill ne l'écrase ni ne l'expose. Il vaut pour tous les projets.

## Première utilisation (2 allers-retours au maximum)
1. **Détecte sans rien demander**, en peu de commandes :
   - langue du message ;
   - OS et shell ;
   - pays, devise, unités et fuseau, d'après la locale du système ;
   - dossier de projets habituel : `~/Developer`, `~/Projects`, `~/code`, `~/dev`, `~/source/repos`, `~/Documents/Projects`, sinon `~/Projects` ;
   - outils Claude disponibles : sous-agents, outil de questions, outil d'usage, changement de dossier, navigateur, Artifact.

   Le matériel (processeur, RAM, disque) et les outils de développement ne se relèvent que quand un projet en dépend. On les ajoute alors au profil.
2. **Un seul message** (outil de questions s'il existe, sinon une liste numérotée), qui contient :
   - les 4 questions essentielles ci-dessous ;
   - les questions bloquantes du projet demandé (2 au maximum) ;
   - « Je l'enregistre dans <chemin> et je le complète au fil de tes corrections. Réponds "défauts" pour tout accepter. »
   Si `~/.claude/agents/ma-chercheur.md` est absent, ajoute une question : « J'installe les sous-agents et les garde-fous de la méthode ? (voir `installation.md`) ». Défaut : non, tant que l'utilisateur n'a pas dit oui.
3. Après la réponse :
   - écris le profil ;
   - marque « (défaut, à confirmer) » toute ligne que l'utilisateur n'a pas choisie explicitement ;
   - montre le profil en 5 lignes ;
   - **enchaîne sans attendre** avec le projet (`phases.md`).

   Si l'utilisateur refuse de répondre, prends les défauts et marque-les de la même façon.

Pour une demande triviale (réponse directe, aucun agent), crée un profil minimal avec ce qui est détecté, et réponds.

### Les 4 questions essentielles (défaut entre crochets)
1. **Autonomie** : pour les choix techniques, je tranche seul et je note, ou je te propose d'abord ? [je tranche et je note]
2. **Dossiers** : chaque projet dans un nouveau dossier sous <dossier détecté> ? [oui, nom proposé, sans redemander]
3. **Langue, ton, niveau** : <langue détectée> ; tutoiement ou vouvoiement (si la langue les distingue) ; court ou détaillé ; débutant, intermédiaire ou expert ? [comme l'utilisateur t'écrit, court, intermédiaire, termes techniques expliqués en quelques mots]
4. **Toujours me demander avant** : argent, installations, téléchargements lourds, publication, envois, comptes, suppressions. Autre chose ? [cette liste]

Les autres préférences prennent leur défaut, en attendant que l'utilisateur les corrige :
- tests : les agents testent, l'utilisateur regarde s'il veut ;
- git : local, avec un commit par étape vérifiée ; push sur demande seulement ;
- seuils de quota : 70 / 80 / 90 % ;
- modèle le plus capable : permis ;
- outils possédés : aucun ;
- limites : aucune.

## Modèle de `profil.md`
```
# Profil maître agent
Créé : <AAAA-MM-JJ> · Mis à jour : <AAAA-MM-JJ> · Mises à jour automatiques : <oui / non>

## Détecté
- Langue : <…>
- OS / shell : <…>
- Pays / devise / unités / fuseau : <…>
- Dossier de projets : <chemin>
- Outils Claude : <sous-agents oui/non, questions, usage, dossier, navigateur, Artifact>
- Forfait / quota : <… ou « pas d'outil d'usage »>
- Machine et outils de dev : <rempli quand un projet en a besoin>

## Préférences générales (toutes les tâches)
- Autonomie : <…>
- Dossiers : <…>
- Langue, tutoiement, ton, niveau : <…>
- Toujours demander avant : <liste>
- Quota : seuils <70/80/90> ; modèle le plus capable <permis / non>
- Limites : <…>

## Usages et équipement (pour cadrer les recherches)
- <ce que l'utilisateur fait, utilise ou possède : jeux, logiciels, matériel, abonnements, outils créatifs>

## Préférences pour les projets de code ou créatifs
- Tests : <…>
- Git : <…>
- Outils de création possédés : <…>

## Projets connus
- <nom> : <une ligne> — <chemin> (<date>)

## Repères de coût (mesurés)
- <AAAA-MM-JJ> : <type d'agent, modèle> ≈ <k tokens>, <durée>, <% de quelle fenêtre>

## Habitudes observées
- <AAAA-MM-JJ> : <correction ou demande de l'utilisateur, à appliquer désormais>
```

## Entretien du profil
- L'utilisateur corrige ta façon de travailler (« arrête de me demander X », « teste toujours Y ») : si « Mises à jour automatiques » vaut oui, ajoute une ligne datée dans « Habitudes observées » et dis-le en une phrase. Sinon, propose-le.
- `/maitre-agent profil` : affiche le profil et applique les modifications demandées.
- À la fin d'un projet, ajoute les coûts mesurés dans « Repères de coût » (tokens et % de fenêtre par agent), et le projet dans « Projets connus ».
- Une information apprise pendant une tâche (usage, équipement) et utile ensuite : ajoute-la dans « Usages et équipement », si les mises à jour automatiques sont permises.
