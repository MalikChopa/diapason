#!/bin/sh
# Méthode Diapason : garde-fou PreToolUse « pas de construction avant la fiche validée ».
# Entrée : le JSON du hook PreToolUse sur l'entrée standard (tool_name, tool_input, cwd ; doc officielle
#   https://code.claude.com/docs/en/hooks, relue le 2026-10-19). Blocage : sortie 2, le message sur stderr
#   est la raison montrée à Claude (« A hook that blocks by exiting 2 routes the same way as "deny" »).
#   Ne pas ajouter « || true » à la commande du hook : cela avalerait le blocage.
# Actif seulement si docs/FICHE.md existe dans le dossier du projet (CLAUDE_PROJECT_DIR, sinon le cwd du JSON)
#   ET porte une ligne « Statut : … » ou « Status: … ». Sinon : tout passe (anciens projets, autres fiches, JSON vide ou cassé, jq absent).
# La fiche est lue en français ET en anglais (le texte interne du skill est en anglais depuis la v1.3, la fiche est écrite dans la
#   langue du profil) : Statut/Status ; validée/validated/approved ; « Maquette validée »/« Mock-up approved » ; « pas encore »/
#   « not yet » ; « sans interface »/« no interface » (tout ce qui n'est ni vide, ni un gabarit « <…>, ni « pas encore »/« not yet » est permis).
# Le message de refus (lu par le modèle, pas par l'utilisateur) est en anglais court.
# - Fiche non « validée » : refuse Write / Edit / MultiEdit / NotebookEdit hors de docs/, maquette/, CLAUDE.md,
#   .claude/ et hors du dossier du projet ; refuse aussi l'agent d'implémentation (dia-executant, avec ou sans
#   préfixe « diapason: » ou, avant la v1.5, « majordome: » ou « maitre-agent: »).
# - Fiche validée mais ligne « Maquette validée » à « pas encore » : mêmes écritures refusées (« sans interface »,
#   un chemin ou un lien = permis). L'agent d'implémentation reste permis : il peut écrire la maquette dans maquette/.
# Limites : les écritures faites par Bash ne sont pas filtrées ; les liens symboliques ne sont pas suivis ; le hook
#   ne sait pas si l'utilisateur a vraiment dit « Valider » (il lit le texte de la fiche) ; qu'il s'applique aussi aux
#   outils d'un sous-agent est dit par la doc mais n'est pas vérifié en vraie session. Les agents d'un autre type
#   (general-purpose…) ne sont pas refusés à leur lancement, seulement leurs écritures.
# Sans dépendance autre que jq (comme les autres hooks), POSIX (sh, dash).
[ -t 0 ] && exit 0
command -v jq >/dev/null 2>&1 || exit 0
in=$(cat 2>/dev/null) || in=""
[ -n "$in" ] || exit 0
fields=$(printf '%s' "$in" | jq -r '
  def s: (. // "" | tostring | gsub("[\\r\\n]"; " "));
  [(.tool_name | s), (.tool_input.subagent_type | s), (.cwd | s), (.tool_input.file_path // .tool_input.notebook_path | s)] | .[]' 2>/dev/null) || exit 0
{ IFS= read -r tool; IFS= read -r sub; IFS= read -r cwd; IFS= read -r path; } <<EOT
$fields
EOT
case "$tool" in
  Write|Edit|MultiEdit|NotebookEdit) kind=file ;;
  Agent|Task) kind=agent ;;
  *) exit 0 ;;
esac
# Dossier du projet : CLAUDE_PROJECT_DIR, sinon le cwd du JSON. Si la session a démarré dans un dossier parent et
# que la fiche vient d'être créée dans un sous-dossier (cd), le cwd du JSON est essayé aussi.
PROJ=""
for d in "${CLAUDE_PROJECT_DIR:-}" "$cwd"; do
  [ -n "$d" ] && [ -f "$d/docs/FICHE.md" ] && { PROJ="$d"; break; }
done
[ -n "$PROJ" ] || exit 0
FICHE="$PROJ/docs/FICHE.md"

# État de la fiche : « statut maquette » avec statut = aucun|brouillon|validee, maquette = aucune|pas|ok
etat=$(awk '
  { l = tolower($0); sub(/\r$/, "", l) }
  st == "" && l ~ /^[ \t*_#>-]*(statut|status)[ \t*_]*:/ {
    v = l; sub(/^[^:]*:[ \t*_`]*/, "", v)
    st = (v ~ /^(valid|approved)/) ? "validee" : "brouillon"
  }
  ma == "" && l ~ /^[ \t*_#>-]*(maquette[ \t]+valid|mock-?up[ \t]+(valid|approved))/ {
    if (index(l, ":") == 0) v = ""; else { v = l; sub(/^[^:]*:[ \t*_`]*/, "", v) }
    ma = (v == "" || v ~ /^</ || v ~ /^(pas encore|not yet)/) ? "pas" : "ok"
  }
  END { print (st == "" ? "aucun" : st) " " (ma == "" ? "aucune" : ma) }' "$FICHE" 2>/dev/null) || exit 0
statut=${etat% *}; maquette=${etat#* }
[ "$statut" = aucun ] && exit 0                       # pas une fiche du skill : on ne s'en mêle pas
if [ "$statut" = validee ] && [ "$maquette" != pas ]; then exit 0; fi

# Raison du refus (le texte est lu par Claude : anglais court, ce qu'il faut faire)
if [ "$statut" != validee ]; then
  raison="The project sheet (docs/FICHE.md) is not validated yet (status: draft). Build nothing before it is. Finish the framing workshop with the user (cadrage.md), present the sheet and have them answer \"Approve\" (FR: \"Valider\"). Do not change the status yourself: only the user validates."
else
  raison="The sheet is validated, but not the mock-up (docs/FICHE.md, line \"Mock-up approved\" / \"Maquette validée\": not yet). Show the mock-up to the user and have it approved (\"Continue\" / \"Continuer\"), then write its path on that line. Project without screens: write \"no interface\" / \"sans interface\" on that line, with the user's approval."
fi

if [ "$kind" = agent ]; then
  sub="${sub#maitre-agent:}"   # ancien préfixe du plugin (v1.3)
  sub="${sub#majordome:}"      # ancien préfixe du plugin (v1.4)
  case "${sub#diapason:}" in
    dia-executant|ma-executant)   # ma-executant : ancien nom (avant la v1.7), toujours refusé
      # la maquette peut être écrite par l'agent d'implémentation : permis tant que la fiche est validée
      [ "$statut" = validee ] && exit 0
      printf '%s\n' "diapason safeguard: launching the implementation agent (dia-executant) is refused. $raison" >&2
      exit 2 ;;
    *) exit 0 ;;
  esac
fi

# Écriture de fichier : seuls docs/, maquette/, CLAUDE.md, .claude/ et ce qui est hors du projet restent ouverts
[ -n "$path" ] || exit 0
norm() { # chemin -> chemin absolu sans « . », « .. » ni « // »
  printf '%s\n' "$1" | awk -F/ '{
    n = 0
    for (i = 1; i <= NF; i++) { c = $i; if (c == "" || c == ".") continue; if (c == "..") { if (n > 0) n--; continue }; a[++n] = c }
    o = ""; for (i = 1; i <= n; i++) o = o "/" a[i]
    print (o == "" ? "/" : o) }'
}
case "$path" in /*) ;; *) path="${cwd:-$PROJ}/$path" ;; esac
P=$(norm "$PROJ"); F=$(norm "$path")
case "$F" in
  "$P"/*) ;;
  *) exit 0 ;;                                          # hors du dossier du projet (profil, autre projet…) : permis
esac
rel=${F#"$P"/}
case "$rel" in
  docs/*|maquette/*|CLAUDE.md|.claude/*) exit 0 ;;
esac
rel=$(printf '%s' "$rel" | tr -d '\000-\037\177')
printf '%s\n' "diapason safeguard: writing to \"$rel\" is refused. $raison Only docs/, maquette/, CLAUDE.md and .claude/ stay open for writing." >&2
exit 2
