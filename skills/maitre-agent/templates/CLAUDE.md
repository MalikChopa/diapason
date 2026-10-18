# <Nom du projet>

But : <une ou deux phrases>. Taille : <petit / moyen / gros>. Parcours : <type, cf. phases>.
Langue de travail : <langue du profil>. (Ne copie du profil que ce dont le projet a besoin : ni nom, ni chemin personnel, ni matériel détaillé si le dépôt peut être partagé.)

## Machine ou cibles (relevé du <AAAA-MM-JJ>)
- <OS, processeur, RAM, disque ; outils et versions utiles au projet — ou plateformes visées>

## Contraintes
- <budget, délai, comptes, légal, ce qu'il ne faut pas risquer>

## Contenu du dossier
- `docs/HANDOFF.md` : état, agents lancés, reprise. **À lire en premier.**
- `docs/research/` : recherches ; `INDEX.md` d'abord.
- `docs/briefs/` : consignes envoyées aux agents (pour la reprise).
- <`docs/ARCHITECTURE.md`, `docs/SPEC.md`, `docs/JOURNAL.md`, `docs/PLAN.md`, `docs/RECOMMANDATION.md`, `docs/RAPPORT.md`, `docs/ASSETS.md`, `tools/` : selon le projet>

## Décisions (datées)
- <AAAA-MM-JJ> : <décision> (<utilisateur / délégué>)

## Règles du projet
- Méthode « maître agent » : la session principale pilote, délègue, vérifie. Un agent = une tâche = ses fichiers ; jamais deux écrivains sur les mêmes fichiers.
- Ne jamais annoncer comme fait ce qui n'est pas mesuré ou sourcé.
- Toujours demander à l'utilisateur avant : <liste du profil>.
- Données de l'utilisateur : restent sur la machine ; tests avec des données factices.
- Jamais : contourner une protection, copier une œuvre protégée, mettre un secret ou une donnée personnelle réelle dans le projet, modifier les originaux fournis.
- <règles propres au projet : palette, budgets, conventions, ports réservés…>
- Quota : géré par le maître agent seulement (seuils <70/80/90> %). Les agents n'ont rien à faire de ce côté, sauf écrire leur avancement au fil de l'eau.
