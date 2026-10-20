#!/bin/sh
# Méthode Majordome : récap de fin de projet, tiré du tableau « Agents lancés » de docs/HANDOFF.md.
# Usage : sh recap.sh [chemin du HANDOFF.md]      (défaut : docs/HANDOFF.md du dossier courant)
# Sortie : un tableau Agent | Modèle | Tokens | Durée | Part du quota, une ligne par agent.
# La colonne « Coût » du tableau du HANDOFF contient « <tokens> · <durée> · <part de la fenêtre> »
# (par exemple « 180 k · 9 min · 6 % ») ; une valeur absente ou à remplir s'affiche « non mesuré ».
# Rien n'est calculé ni deviné. Lecture seule. Sortie 0, ou 2 si le fichier ou le tableau manque.
f="${1:-docs/HANDOFF.md}"
[ -f "$f" ] || { echo "recap : $f absent"; exit 2; }
out=$(awk -F'|' '
  function trim(x) { sub(/^[ \t]+/, "", x); sub(/[ \t\r]+$/, "", x); return x }
  function val(x) { x = trim(x); if (x == "" || x ~ /^</) return "non mesuré"; return x }
  /^##[ \t]/ { on = ($0 ~ /^##[ \t]+Agents lancés/); hdr = 0; next }
  on && /^[ \t]*\|/ {
    if (!hdr) {
      for (i = 2; i < NF; i++) { c = trim($i); if (c == "Agent") a = i; else if (c == "Modèle") m = i; else if (c ~ /^Coût/) k = i }
      hdr = 1; next
    }
    if ($0 ~ /^[ \t]*\|[-: |\t]+$/) next
    name = trim($a); if (name == "" || name ~ /^</) next
    t = "non mesuré"; d = "non mesuré"; q = "non mesuré"
    if (k > 0) {
      n = split($k, p, "·")
      if (n >= 1) t = val(p[1]); if (n >= 2) d = val(p[2]); if (n >= 3) q = val(p[3])
      if (n == 1 && t ~ /^non mesuré/) { d = "non mesuré"; q = "non mesuré" }
    }
    model = (m > 0) ? val($m) : "non mesuré"
    print "| " name " | " model " | " t " | " d " | " q " |"
    rows++
  }
  END { if (rows == 0) exit 3 }' "$f" 2>/dev/null) || { echo "recap : pas de ligne d'agent dans le tableau « Agents lancés » de $f"; exit 2; }
printf '%s\n' "| Agent | Modèle | Tokens | Durée | Part du quota |" "|---|---|---|---|---|"
printf '%s\n' "$out"
exit 0
