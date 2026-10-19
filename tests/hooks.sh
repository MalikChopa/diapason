#!/bin/sh
# Tests des hooks et scripts (hooks/*.sh, tools/quota.sh) avec des JSON factices.
# HOME factice (dossier temporaire supprimé à la fin), MAITRE_AGENT_DRY_RUN=1 : aucune notification
# réelle, rien n'est écrit dans le vrai ~/.claude. Aucun appel réseau.
# Usage : sh tests/hooks.sh          Sortie 0 si tout passe, 1 sinon. Demande jq (sinon : test sauté, sortie 0).
# Couvre : C5 (séquences d'échappement), C7 (jalon), C8 (texte qui commence par « - », **), C10 (alerte
# unique en parallèle, purge), C13 (HANDOFF = donnée), M1 (notification « bloqué » off par défaut), quota.sh,
# et les réglages de la v1.2 (seuils, notifications, barre, réglages du projet, tools/reglages.sh).
ROOT=$(cd "$(dirname "$0")/.." && pwd)
if ! command -v jq >/dev/null 2>&1; then echo "avert jq absent : tests des hooks sautés"; exit 0; fi

T=$(mktemp -d 2>/dev/null) || { echo "ERR mktemp impossible"; exit 1; }
trap 'rm -rf "$T"' EXIT INT TERM
export HOME="$T/home" MAITRE_AGENT_DRY_RUN=1
BASE="$HOME/.claude/maitre-agent"
mkdir -p "$HOME" "$T/p2/docs"
st() { sh "$ROOT/hooks/statusline.sh" "$@"; }
nt() { sh "$ROOT/hooks/notify.sh" "$@"; }
q() { sh "$ROOT/tools/quota.sh" "$@"; }
rgl() { sh "$ROOT/tools/reglages.sh" "$@"; }
n=0; bad=0
check() { # $1 nom  $2 obtenu  $3 attendu
  n=$((n + 1))
  if [ "$2" = "$3" ]; then echo "ok   $1"; else echo "ERR  $1 : attendu [$3], obtenu [$2]"; bad=$((bad + 1)); fi
}
# vrai (0) si la chaîne ne contient aucun caractère de contrôle C0 ni DEL ni U+009B
clean_of_ctrl() { ! printf '%s' "$1" | LC_ALL=C grep -q "[[:cntrl:]]" && ! printf '%s' "$1" | LC_ALL=C grep -q "$(printf '\302\233')"; }
ago() { # $1 secondes : date au format touch -t (AAAAMMJJhhmm)
  e=$(( $(date +%s) - $1 ))
  if [ "$(uname -s)" = Darwin ]; then date -r "$e" +%Y%m%d%H%M; else date -d "@$e" +%Y%m%d%H%M; fi
}

# --- C5 : séquences d'échappement ----------------------------------------------------------------
printf 'Jalon : J1 \033]0;PWNED\007\033[2J fin\n' > "$T/p2/docs/HANDOFF.md"
out=$(printf '%s\n' '{"cwd":"'"$T"'/p2"}' | st)
if clean_of_ctrl "$out"; then r=propre; else r=sale; fi
check "C5 barre d'état : jalon sans caractère de contrôle" "$r" propre
mkdir -p "$T/$(printf 'q\033[2Jz')"
out=$(printf '%s\n' '{"cwd":"'"$T"'/q\u001b[2Jz\u009bw"}' | st)
if clean_of_ctrl "$out"; then r=propre; else r=sale; fi
check "C5 barre d'état : nom de dossier sans caractère de contrôle (ESC, U+009B)" "$r" propre
out=$(printf '%s\n' '{"agent_type":"ma-x","last_assistant_message":"OK \u001b]0;PWN\u0007\u001b[2J \u009b fin"}' | nt agent)
if clean_of_ctrl "$out"; then r=propre; else r=sale; fi
check "C5 notify.sh agent : sans caractère de contrôle" "$r" propre

# --- C7 : pas de repli sur « Reprise immédiate » ---------------------------------------------------
printf '# T\nJalon : <jalon>\n## Reprise immédiate\n1. Lire le quota et appliquer les seuils.\n' > "$T/p2/docs/HANDOFF.md"
out=$(printf '%s\n' '{"cwd":"'"$T"'/p2"}' | st)
check "C7 gabarit et repli ignorés" "$out" "🧭 p2 · 0 agent · quota ?"
printf '# T\nJalon : **J2** `plugin` en cours\n' > "$T/p2/docs/HANDOFF.md"
out=$(printf '%s\n' '{"cwd":"'"$T"'/p2"}' | st)
check "C7 ligne Jalon lue, ** et accents graves retirés" "$out" "🧭 p2 · J2 plugin en cours · 0 agent · quota ?"

# --- M1 + C8 : notification « bloqué » ------------------------------------------------------------------
out=$(printf '%s\n' '{"message":"-x attend"}' | nt blocked)
check "M1 blocked désactivé par défaut" "$out" ""
mkdir -p "$BASE"; : > "$BASE/notifications-on"
out=$(printf '%s\n' '{"message":"-x attend"}' | nt blocked)
check "M1 blocked actif avec notifications-on ; C8 texte qui commence par «-»" "$out" "[notification] Maître agent : Claude attend | -x attend"
out=$(printf '%s\n' '{"agent_type":"ma-x","last_assistant_message":"- **BLOQUÉ** car il manque X"}' | nt agent)
check "C8 ** retirés" "$out" "[notification] Maître agent : agent terminé | ma-x : BLOQUÉ car il manque X"
: > "$BASE/notifications-off"
out=$(printf '%s\n' '{"message":"x"}' | nt blocked; nt quota "Quota 5 h à 85 %"; printf '%s\n' '{"agent_type":"ma-x","last_assistant_message":"fini"}' | nt agent)
check "M1 notifications-off coupe tout" "$out" ""
rm -f "$BASE/notifications-off" "$BASE/notifications-on"
out=$(nt quota "Quota 5 h à 85 %")
check "M1 quota reste actif par défaut" "$out" "[notification] Maître agent : quota | Quota 5 h à 85 %"
# C8 : le « -- » est bien présent avant le texte dans les deux commandes d'envoi (osascript, notify-send)
if grep -q "'end run' -- \"\$txt\"" "$ROOT/hooks/notify.sh" && grep -q 'notify-send -- ' "$ROOT/hooks/notify.sh"; then r=present; else r=absent; fi
check "C8 « -- » avant le texte (osascript, notify-send)" "$r" present

# --- C10 : alerte unique en parallèle, compteur, purge ---------------------------------------------------
reset=$(( $(date +%s) + 3600 ))
: > "$T/par.out"; i=0
while [ "$i" -lt 12 ]; do
  ( printf '%s\n' '{"session_id":"s'"$i"'","cwd":"'"$T"'/p2","rate_limits":{"five_hour":{"used_percentage":85,"resets_at":'"$reset"'}}}' | st 2>&1 >/dev/null | grep -c 'seuil' >> "$T/par.out" ) &
  i=$((i + 1))
done
wait
check "C10 12 appels simultanés à 85 % : une seule alerte" "$(awk '{s += $1} END {print s + 0}' "$T/par.out")" 1
printf '%s\n' '{"session_id":"c1","agent_id":"a1","agent_type":"general-purpose"}' | sh "$ROOT/hooks/agent-count.sh" start
out=$(printf '%s\n' '{"session_id":"c1","cwd":"'"$T"'/p2"}' | st)
check "C10 le compteur compte aussi un agent hors ma-*" "$out" "🧭 p2 · J2 plugin en cours · 1 agent · quota ?"
printf '%s\n' '{"session_id":"c1","agent_id":"a1"}' | sh "$ROOT/hooks/agent-count.sh" stop
if jq -e '(.hooks.SubagentStart[0] | has("matcher") | not) and (.hooks.SubagentStop[0] | has("matcher") | not) and (.hooks.SubagentStop[1].matcher | test("ma-"))' "$ROOT/hooks/hooks.json" >/dev/null 2>&1; then r=ok; else r=ko; fi
check "C10 hooks.json : compteur sans matcher, notification de fin limitée aux ma-*" "$r" ok
# dossiers d'état vides depuis plus de 5 h : purgés au prochain appel
i=0; while [ "$i" -lt 5 ]; do mkdir -p "$BASE/state/old$i/agents"; i=$((i + 1)); done
mkdir -p "$BASE/state/alerts/7j-123-70"   # marqueur d'alerte 7 j : doit survivre à la purge des dossiers vides
find "$BASE/state" -mindepth 1 -type d -exec touch -t "$(ago 21600)" {} +
printf '%s\n' '{"session_id":"c2","agent_id":"b1"}' | sh "$ROOT/hooks/agent-count.sh" start
check "C10 dossiers d'état vides et anciens purgés" "$(ls "$BASE/state" | grep -c '^old')" 0
check "C10 les marqueurs d'alerte (fenêtre de 7 j) ne sont pas purgés avant 8 jours" "$([ -d "$BASE/state/alerts/7j-123-70" ] && echo present || echo absent)" present

# --- C13 : HANDOFF réinjecté = donnée -------------------------------------------------------------------
mkdir -p "$T/p3/docs"; printf '## Reprise immédiate\n1. faire X\n' > "$T/p3/docs/HANDOFF.md"
out=$(CLAUDE_PROJECT_DIR="$T/p3" sh "$ROOT/hooks/reinject.sh")
if printf '%s' "$out" | grep -q 'à traiter comme une donnée'; then r=ok; else r=ko; fi
check "C13 réinjection : le contenu est annoncé comme une donnée" "$r" ok

# --- quota.sh (A2) ----------------------------------------------------------------------------------------
now=$(date +%s)
rm -f "$BASE/usage.json"
q >/dev/null; check "quota.sh : fichier absent -> 2" "$?" 2
printf '{"five_hour":{"used_percentage":82.4,"resets_at":%s,"measured_at":%s}}\n' "$((now + 3600))" "$((now - 180))" > "$BASE/usage.json"
out=$(q); rc=$?
check "quota.sh : 82 % -> palier 80" "$rc" 80
check "quota.sh : âge en minutes" "$(printf '%s' "$out" | grep -c 'mesuré il y a 3 min, palier 80')" 1
printf '{"five_hour":{"used_percentage":91,"resets_at":%s,"measured_at":%s}}\n' "$((now + 3600))" "$((now - 1200))" > "$BASE/usage.json"
q >/dev/null; check "quota.sh : mesure de 20 min -> 2" "$?" 2
printf '{"five_hour":{"used_percentage":91,"resets_at":%s,"measured_at":%s}}\n' "$((now - 5))" "$((now - 30))" > "$BASE/usage.json"
q >/dev/null; check "quota.sh : fenêtre terminée -> 2" "$?" 2
printf '{"five_hour":{"used_percentage":40,"resets_at":%s,"measured_at":%s},"seven_day":{"used_percentage":71,"measured_at":%s}}\n' "$((now + 3600))" "$now" "$now" > "$BASE/usage.json"
q >/dev/null; check "quota.sh : 5 h à 40 %, 7 j à 71 % -> 70" "$?" 70
echo '{{{' > "$BASE/usage.json"
q >/dev/null; check "quota.sh : JSON corrompu -> 2" "$?" 2

# --- Réglages v1.2 : seuils, notifications, barre, réglages du projet ------------------------------------
mkdir -p "$T/p4/docs" "$T/p5"
printf 'Jalon : J4 réglages\n' > "$T/p4/docs/HANDOFF.md"
printf '# Profil\n\n## Réglages\n- seuils : 60 75 85\n- notifications : agent+quota\n- barre : projet agents quota\n' > "$BASE/profil.md"
alerts() { # $1 pourcentage $2 resets_at $3 dossier : texte des alertes émises (stderr de la barre d'état)
  printf '%s\n' '{"session_id":"r1","cwd":"'"$3"'","rate_limits":{"five_hour":{"used_percentage":'"$1"',"resets_at":'"$2"'}}}' | st 2>&1 >/dev/null
}
R1=$(( $(date +%s) + 7000 ))
out=$(alerts 55 "$R1" "$T/p4"); check "réglages : 55 % sous le premier seuil (60) -> aucune alerte" "$out" ""
out=$(alerts 62 "$R1" "$T/p4"); check "réglages : seuils 60 75 85, 62 % -> alerte à 60 (70 par défaut ne se serait pas déclenché)" "$(printf '%s' "$out" | grep -c 'seuil 60 % franchi')" 1
out=$(alerts 64 "$R1" "$T/p4"); check "réglages : 60 déjà signalé -> pas de doublon" "$out" ""
out=$(alerts 77 "$R1" "$T/p4"); check "réglages : 77 % -> alerte à 75" "$(printf '%s' "$out" | grep -c 'seuil 75 % franchi')" 1
out=$(alerts 88 "$R1" "$T/p4"); check "réglages : 88 % -> alerte à 85" "$(printf '%s' "$out" | grep -c 'seuil 85 % franchi')" 1
out=$(printf '%s\n' '{"cwd":"'"$T"'/p4"}' | st)
check "réglages : barre « projet agents quota » sans jalon" "$out" "🧭 p4 · 0 agent · quota ?"
out=$(printf '%s\n' '{"cwd":"'"$T"'/p4","cost":{"total_cost_usd":1.234}}' | st)
check "réglages : sans « cout » dans la barre, le coût n'apparaît pas" "$out" "🧭 p4 · 0 agent · quota ?"
printf '# Profil\n\n## Réglages\n- barre : quota cout, projet jalon\n' > "$BASE/profil.md"
out=$(printf '%s\n' '{"cwd":"'"$T"'/p4","cost":{"total_cost_usd":1.234}}' | st)
check "réglages : barre dans l'ordre voulu, avec le coût du JSON" "$out" "🧭 quota ? · coût 1.23 \$ · p4 · J4 réglages"
out=$(printf '%s\n' '{"cwd":"'"$T"'/p4"}' | st)
check "réglages : « cout » sans coût dans le JSON -> élément omis" "$out" "🧭 quota ? · p4 · J4 réglages"
printf '# Profil\n\n## Réglages\n- barre : projet banane\n- seuils : 90 80 70\n- notifications : peut-etre\n' > "$BASE/profil.md"
out=$(printf '%s\n' '{"cwd":"'"$T"'/p4"}' | st)
check "réglages : barre invalide -> barre par défaut" "$out" "🧭 p4 · J4 réglages · 0 agent · quota ?"
R2=$(( R1 + 100 ))
out=$(alerts 65 "$R2" "$T/p4"); check "réglages : seuils invalides -> défauts 70 80 90 (65 % : aucune alerte)" "$out" ""
out=$(alerts 72 "$R2" "$T/p4"); check "réglages : seuils invalides -> défauts (72 % : alerte à 70)" "$(printf '%s' "$out" | grep -c 'seuil 70 % franchi')" 1
rm -f "$BASE/profil.md"
R3=$(( R1 + 200 ))
out=$(alerts 72 "$R3" "$T/p4"); check "réglages : profil absent -> défauts (alerte à 70)" "$(printf '%s' "$out" | grep -c 'seuil 70 % franchi')" 1

# notifications : agent+quota | tout | quota | rien
J='{"agent_type":"ma-x","last_assistant_message":"fini","cwd":"'"$T"'/p5"}'
setprof() { printf '# Profil\n\n## Réglages\n- notifications : %s\n' "$1" > "$BASE/profil.md"; }
setprof rien
out=$(printf '%s\n' "$J" | nt agent; printf '%s\n' '{"message":"x"}' | nt blocked; nt quota "Quota 5 h à 85 %")
check "réglages : notifications rien -> aucune notification" "$out" ""
setprof quota
out=$(printf '%s\n' "$J" | nt agent; printf '%s\n' '{"message":"x"}' | nt blocked)
check "réglages : notifications quota -> ni fin d'agent ni « bloqué »" "$out" ""
out=$(nt quota "Quota 5 h à 85 %"); check "réglages : notifications quota -> l'alerte de quota passe" "$out" "[notification] Maître agent : quota | Quota 5 h à 85 %"
setprof agent+quota
out=$(printf '%s\n' "$J" | nt agent); check "réglages : notifications agent+quota -> fin d'agent notifiée" "$out" "[notification] Maître agent : agent terminé | ma-x : fini"
out=$(printf '%s\n' '{"message":"x"}' | nt blocked); check "réglages : notifications agent+quota -> « bloqué » muet" "$out" ""
setprof tout
out=$(printf '%s\n' '{"message":"x"}' | nt blocked); check "réglages : notifications tout -> « bloqué » notifié" "$out" "[notification] Maître agent : Claude attend | x"
: > "$BASE/notifications-off"
out=$(printf '%s\n' "$J" | nt agent); check "réglages : le fichier notifications-off coupe tout, même avec tout" "$out" ""
rm -f "$BASE/notifications-off"
# réglage du projet (CLAUDE.md du dossier du projet, lu dans le cwd du JSON) : prime sur le profil
printf '# P\n\n## Réglages du projet\n- notifications : rien\n- seuils : 40 50 60\n' > "$T/p5/CLAUDE.md"
out=$(printf '%s\n' "$J" | nt agent); check "réglages du projet : notifications rien prime sur le profil (tout)" "$out" ""
R4=$(( R1 + 300 ))
out=$(alerts 45 "$R4" "$T/p5"); check "réglages du projet : notifications rien du projet coupe aussi l'alerte de quota" "$out" ""
mkdir -p "$T/p7"; printf '# P\n\n## Réglages du projet\n- seuils : 40 50 60\n' > "$T/p7/CLAUDE.md"
out=$(alerts 45 "$((R4 + 100))" "$T/p7"); check "réglages du projet : seuils 40 50 60 -> alerte à 40 (45 %)" "$(printf '%s' "$out" | grep -c 'seuil 40 % franchi')" 1
printf '# P\n\n## Réglages du projet\n- notifications : peut-etre\n' > "$T/p5/CLAUDE.md"
out=$(printf '%s\n' "$J" | nt agent); check "réglages du projet : valeur invalide -> retombe sur le profil" "$out" "[notification] Maître agent : agent terminé | ma-x : fini"
rm -f "$T/p5/CLAUDE.md" "$BASE/profil.md"
out=$(printf '%s\n' "$J" | nt agent); check "réglages : sans profil, défaut agent+quota (fin d'agent notifiée)" "$out" "[notification] Maître agent : agent terminé | ma-x : fini"

# quota.sh : seuils du profil, puis du projet, puis arguments
now=$(date +%s)
printf '{"five_hour":{"used_percentage":77,"resets_at":%s,"measured_at":%s}}\n' "$((now + 3600))" "$now" > "$BASE/usage.json"
q >/dev/null; check "quota.sh : sans réglage, 77 % -> palier 70" "$?" 70
printf '# Profil\n\n## Réglages\n- seuils : 60 75 85\n' > "$BASE/profil.md"
q >/dev/null; check "quota.sh : seuils du profil 60 75 85, 77 % -> palier 75" "$?" 75
q 70 80 90 >/dev/null; check "quota.sh : les arguments priment sur le profil -> palier 70" "$?" 70
(cd "$T/p4" && printf '# P\n## Réglages du projet\n- seuils : 20 30 40\n' > CLAUDE.md && sh "$ROOT/tools/quota.sh" >/dev/null); check "quota.sh : seuils du projet 20 30 40 -> palier 40" "$?" 40
rm -f "$T/p4/CLAUDE.md"
printf '# Profil\n\n## Réglages\n- seuils : 5 95 99\n' > "$BASE/profil.md"
q >/dev/null; check "quota.sh : seuils invalides -> défauts (palier 70)" "$?" 70

# tools/reglages.sh : tableau, écriture avant/après, valeurs refusées, préréglages, reset, --projet
printf '# Profil\n\n## Détecté\n- Langue : fr\n\n## Projets connus\n- x : y\n' > "$BASE/profil.md"
out=$(rgl actifs); check "reglages.sh : rien de réglé -> défauts" "$out" "réglages : défauts"
out=$(rgl set seuils 60 75 85); rc=$?
check "reglages.sh set : écrit la ligne, montre avant et après" "$rc|$(printf '%s' "$out" | grep -c '^avant : (ligne absente)$')|$(printf '%s' "$out" | grep -c '^après : - seuils : 60 75 85$')" "0|1|1"
out=$(rgl set seuils 61, 76, 86); check "reglages.sh set : remplace la ligne (avant = ancienne valeur)" "$(printf '%s' "$out" | grep -c '^avant : - seuils : 60 75 85$')" 1
check "reglages.sh set : une seule ligne seuils dans le profil" "$(grep -c '^- seuils' "$BASE/profil.md")" 1
check "reglages.sh set : le reste du profil est intact" "$(grep -c '^- x : y$' "$BASE/profil.md")|$(grep -c '^## Détecté$' "$BASE/profil.md")" "1|1"
rgl set seuils 80 70 90 >/dev/null; check "reglages.sh set : seuils non croissants refusés (rc 1)" "$?" 1
rgl set agents-paralleles 9 >/dev/null; check "reglages.sh set : agents-paralleles 9 refusé" "$?" 1
rgl set couleur rouge >/dev/null; check "reglages.sh set : clé inconnue refusée" "$?" 1
check "reglages.sh : les valeurs refusées n'ont rien écrit" "$(grep -c '^- ' "$BASE/profil.md")" 3
rgl set git push-branche >/dev/null; check "reglages.sh set git push-branche : date de l'accord écrite" "$(grep -c '^- git : push-branche (accordé le [0-9-]*)$' "$BASE/profil.md")" 1
check "reglages.sh : la date entre parenthèses ne gêne pas la lecture" "$(rgl actifs | grep -c '^git : push-branche (profil)$')" 1
rgl set budget-lot 15 >/dev/null; rgl set barre "projet, jalon" >/dev/null
check "reglages.sh : budget-lot et barre normalisés" "$(grep -c '^- budget-lot : 15 %$' "$BASE/profil.md")|$(grep -c '^- barre : projet jalon$' "$BASE/profil.md")" "1|1"
rgl preset econome >/dev/null
check "reglages.sh preset econome : seuils 60 75 85, budget-lot 15 %, jamais-opus, 1 agent, rapports court" "$(sed -n '/^## Réglages$/,$p' "$BASE/profil.md" | tr '\n' ';')" "## Réglages;- prereglage : econome;- seuils : 60 75 85;- budget-lot : 15 %;- modeles : jamais-opus;- agents-paralleles : 1;- rapports : court;"
rgl preset intensif >/dev/null
check "reglages.sh preset intensif : seuils 80 90 95, budget-lot 40 %, 5 agents" "$(sed -n '/^## Réglages$/,$p' "$BASE/profil.md" | tr '\n' ';')" "## Réglages;- prereglage : intensif;- seuils : 80 90 95;- budget-lot : 40 %;- agents-paralleles : 5;"
rgl preset normal >/dev/null
check "reglages.sh preset normal : seul le préréglage reste (défauts)" "$(rgl actifs)" "prereglage : normal (profil)"
rgl preset zen >/dev/null; check "reglages.sh preset inconnu refusé" "$?" 1
rgl reset >/dev/null
check "reglages.sh reset : rubrique retirée, reste du profil intact" "$(grep -c 'Réglages' "$BASE/profil.md")|$(grep -c '^- x : y$' "$BASE/profil.md")" "0|1"
mkdir -p "$T/p6"; printf '# P\n' > "$T/p6/CLAUDE.md"
(cd "$T/p6" && sh "$ROOT/tools/reglages.sh" set --projet notifications rien >/dev/null)
check "reglages.sh set --projet : écrit dans « ## Réglages du projet » du CLAUDE.md" "$(grep -c '^## Réglages du projet$' "$T/p6/CLAUDE.md")|$(grep -c '^- notifications : rien$' "$T/p6/CLAUDE.md")" "1|1"
check "reglages.sh : le projet apparaît comme source" "$(cd "$T/p6" && sh "$ROOT/tools/reglages.sh" actifs)" "notifications : rien (projet)"
rm -f "$BASE/profil.md"; rgl set seuils 60 75 85 >/dev/null; check "reglages.sh set sans profil : refus (rc 2), rien créé" "$?|$([ -e "$BASE/profil.md" ] && echo cree || echo absent)" "2|absent"

# tools/recap.sh : tableau de fin de projet tiré du tableau « Agents lancés » du HANDOFF (rien n'est inventé)
mkdir -p "$T/p8/docs"
cat > "$T/p8/docs/HANDOFF.md" <<'EOT'
# H
## Agents lancés
| Agent | Tâche | Modèle | Fichier de travail | Statut | Brief | Coût (tokens · durée · % fenêtre) |
|---|---|---|---|---|---|---|
| ma-chercheur | rech | sonnet | a.md | terminé | `b` | 180 k · 9 min · 6 % |
| ma-executant | code | sonnet | src | terminé | `b` | 400 k · 20 min |
| ma-testeur | tests | haiku | x | en cours | `b` |  |
| <nom court> | <tâche> | <modèle> | <fichier> | en cours | b | <…> |

## Suite
EOT
out=$(sh "$ROOT/tools/recap.sh" "$T/p8/docs/HANDOFF.md" | tr '\n' ';')
check "recap.sh : tableau agents / modèle / tokens / durée / part du quota, « non mesuré » si absent, gabarit ignoré" "$out" "| Agent | Modèle | Tokens | Durée | Part du quota |;|---|---|---|---|---|;| ma-chercheur | sonnet | 180 k | 9 min | 6 % |;| ma-executant | sonnet | 400 k | 20 min | non mesuré |;| ma-testeur | haiku | non mesuré | non mesuré | non mesuré |;"
sh "$ROOT/tools/recap.sh" "$T/inexistant.md" >/dev/null; check "recap.sh : fichier absent -> 2" "$?" 2

echo "RÉSULTAT : $n vérifications, $bad échec(s)"
[ "$bad" -eq 0 ]
