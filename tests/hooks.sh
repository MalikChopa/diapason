#!/bin/sh
# Tests des hooks et scripts (hooks/*.sh, tools/quota.sh) avec des JSON factices.
# HOME factice (dossier temporaire supprimé à la fin), DIAPASON_DRY_RUN=1 : aucune notification
# réelle, rien n'est écrit dans le vrai ~/.claude. Aucun appel réseau.
# Usage : sh tests/hooks.sh          Sortie 0 si tout passe, 1 sinon. Demande jq (sinon : test sauté, sortie 0).
# Couvre : C5 (séquences d'échappement), C7 (jalon), C8 (texte qui commence par « - », **), C10 (alerte
# unique en parallèle, purge), C13 (HANDOFF = donnée), M1 (notification « bloqué » off par défaut), quota.sh,
# les réglages de la v1.2 (seuils, notifications, barre, réglages du projet, tools/reglages.sh)
# et ceux de la v1.3 (autonomie accompagnant, modeles opus-avec-audits, préréglages).
ROOT=$(cd "$(dirname "$0")/.." && pwd)
if ! command -v jq >/dev/null 2>&1; then echo "avert jq absent : tests des hooks sautés"; exit 0; fi

T=$(mktemp -d 2>/dev/null) || { echo "ERR mktemp impossible"; exit 1; }
trap 'rm -rf "$T"' EXIT INT TERM
export HOME="$T/home" DIAPASON_DRY_RUN=1
BASE="$HOME/.claude/diapason"
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
out=$(printf '%s\n' '{"agent_type":"dia-x","last_assistant_message":"OK \u001b]0;PWN\u0007\u001b[2J \u009b fin"}' | nt agent)
if clean_of_ctrl "$out"; then r=propre; else r=sale; fi
check "C5 notify.sh agent : sans caractère de contrôle" "$r" propre

# --- C7 : pas de repli sur « Reprise immédiate » ---------------------------------------------------
printf '# T\nJalon : <jalon>\n## Reprise immédiate\n1. Lire le quota et appliquer les seuils.\n' > "$T/p2/docs/HANDOFF.md"
out=$(printf '%s\n' '{"cwd":"'"$T"'/p2"}' | st)
check "C7 gabarit et repli ignorés" "$out" "🛎️ p2 · 0 agent · quota ?"
printf '# T\nJalon : **J2** `plugin` en cours\n' > "$T/p2/docs/HANDOFF.md"
out=$(printf '%s\n' '{"cwd":"'"$T"'/p2"}' | st)
check "C7 ligne Jalon lue, ** et accents graves retirés" "$out" "🛎️ p2 · J2 plugin en cours · 0 agent · quota ?"

# --- M1 + C8 : notification « bloqué » ------------------------------------------------------------------
out=$(printf '%s\n' '{"message":"-x attend"}' | nt blocked)
check "M1 blocked désactivé par défaut" "$out" ""
mkdir -p "$BASE"; : > "$BASE/notifications-on"
out=$(printf '%s\n' '{"message":"-x attend"}' | nt blocked)
check "M1 blocked actif avec notifications-on ; C8 texte qui commence par «-»" "$out" "[notification] Diapason : Claude attend | -x attend"
out=$(printf '%s\n' '{"agent_type":"dia-x","last_assistant_message":"- **BLOQUÉ** car il manque X"}' | nt agent)
check "C8 ** retirés" "$out" "[notification] Diapason : agent terminé | dia-x : BLOQUÉ car il manque X"
: > "$BASE/notifications-off"
out=$(printf '%s\n' '{"message":"x"}' | nt blocked; nt quota "Quota 5 h à 85 %"; printf '%s\n' '{"agent_type":"dia-x","last_assistant_message":"fini"}' | nt agent)
check "M1 notifications-off coupe tout" "$out" ""
rm -f "$BASE/notifications-off" "$BASE/notifications-on"
out=$(nt quota "Quota 5 h à 85 %")
check "M1 quota reste actif par défaut" "$out" "[notification] Diapason : quota | Quota 5 h à 85 %"
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
# État intermédiaire d'un autre appel (seuil haut déjà verrouillé, seuils bas pas encore marqués) : aucune alerte de plus
reset2=$(( reset + 11 )); mkdir -p "$BASE/state/alerts/5h-$reset2-80"
out=$(printf '%s\n' '{"session_id":"r1","cwd":"'"$T"'/p2","rate_limits":{"five_hour":{"used_percentage":85,"resets_at":'"$reset2"'}}}' | st 2>&1 >/dev/null | grep -c 'seuil')
check "C10 5 h : seuil 80 verrouillé, 70 pas encore marqué : aucune alerte de plus" "$out" 0
reset3=$(( $(date +%s) + 302400 )); mkdir -p "$BASE/state/alerts/7j-$reset3-p2"
out=$(printf '%s\n' '{"session_id":"r2","cwd":"'"$T"'/p2","rate_limits":{"seven_day":{"used_percentage":90,"resets_at":'"$reset3"'}}}' | st 2>&1 >/dev/null | grep -c 'palier')
check "C10 7 j : palier 2 verrouillé, palier 1 pas encore marqué : aucune alerte de plus" "$out" 0
printf '%s\n' '{"session_id":"c1","agent_id":"a1","agent_type":"general-purpose"}' | sh "$ROOT/hooks/agent-count.sh" start
out=$(printf '%s\n' '{"session_id":"c1","cwd":"'"$T"'/p2"}' | st)
check "C10 le compteur compte aussi un agent hors dia-*" "$out" "🛎️ p2 · J2 plugin en cours · 1 agent · quota ?"
printf '%s\n' '{"session_id":"c1","agent_id":"a1"}' | sh "$ROOT/hooks/agent-count.sh" stop
if jq -e '(.hooks.SubagentStart[0] | has("matcher") | not) and (.hooks.SubagentStop[0] | has("matcher") | not) and (.hooks.SubagentStop[1].matcher | contains("(dia|ma)-"))' "$ROOT/hooks/hooks.json" >/dev/null 2>&1; then r=ok; else r=ko; fi
check "C10 hooks.json : compteur sans matcher, notification de fin limitée aux dia-*" "$r" ok
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
q >/dev/null; check "quota.sh v1.3 : 5 h à 40 %, 7 j à 71 % sans remise : sous le plafond de 85 % -> 0 (avant : 70, seuils de 5 h appliqués à l'hebdo)" "$?" 0
printf '{"five_hour":{"used_percentage":40,"resets_at":%s,"measured_at":%s},"seven_day":{"used_percentage":86,"measured_at":%s}}\n' "$((now + 3600))" "$now" "$now" > "$BASE/usage.json"
out=$(q); rc=$?
check "quota.sh v1.3 : 7 j à 86 % sans remise : plafond 85 -> palier 1, code 70" "$rc|$(printf '%s' "$out" | grep -c '^7j 86 % (plafonds seuls : remise inconnue), mesuré il y a 0 min, palier 1$')" "70|1"
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
check "réglages : barre « projet agents quota » sans jalon" "$out" "🛎️ p4 · 0 agent · quota ?"
out=$(printf '%s\n' '{"cwd":"'"$T"'/p4","cost":{"total_cost_usd":1.234}}' | st)
check "réglages : sans « cout » dans la barre, le coût n'apparaît pas" "$out" "🛎️ p4 · 0 agent · quota ?"
printf '# Profil\n\n## Réglages\n- barre : quota cout, projet jalon\n' > "$BASE/profil.md"
out=$(printf '%s\n' '{"cwd":"'"$T"'/p4","cost":{"total_cost_usd":1.234}}' | st)
check "réglages : barre dans l'ordre voulu, avec le coût du JSON" "$out" "🛎️ quota ? · coût 1.23 \$ · p4 · J4 réglages"
out=$(printf '%s\n' '{"cwd":"'"$T"'/p4"}' | st)
check "réglages : « cout » sans coût dans le JSON -> élément omis" "$out" "🛎️ quota ? · p4 · J4 réglages"
printf '# Profil\n\n## Réglages\n- barre : projet banane\n- seuils : 90 80 70\n- notifications : peut-etre\n' > "$BASE/profil.md"
out=$(printf '%s\n' '{"cwd":"'"$T"'/p4"}' | st)
check "réglages : barre invalide -> barre par défaut" "$out" "🛎️ p4 · J4 réglages · 0 agent · quota ?"
R2=$(( R1 + 100 ))
out=$(alerts 65 "$R2" "$T/p4"); check "réglages : seuils invalides -> défauts 70 80 90 (65 % : aucune alerte)" "$out" ""
out=$(alerts 72 "$R2" "$T/p4"); check "réglages : seuils invalides -> défauts (72 % : alerte à 70)" "$(printf '%s' "$out" | grep -c 'seuil 70 % franchi')" 1
rm -f "$BASE/profil.md"
R3=$(( R1 + 200 ))
out=$(alerts 72 "$R3" "$T/p4"); check "réglages : profil absent -> défauts (alerte à 70)" "$(printf '%s' "$out" | grep -c 'seuil 70 % franchi')" 1

# notifications : agent+quota | tout | quota | rien
J='{"agent_type":"dia-x","last_assistant_message":"fini","cwd":"'"$T"'/p5"}'
setprof() { printf '# Profil\n\n## Réglages\n- notifications : %s\n' "$1" > "$BASE/profil.md"; }
setprof rien
out=$(printf '%s\n' "$J" | nt agent; printf '%s\n' '{"message":"x"}' | nt blocked; nt quota "Quota 5 h à 85 %")
check "réglages : notifications rien -> aucune notification" "$out" ""
setprof quota
out=$(printf '%s\n' "$J" | nt agent; printf '%s\n' '{"message":"x"}' | nt blocked)
check "réglages : notifications quota -> ni fin d'agent ni « bloqué »" "$out" ""
out=$(nt quota "Quota 5 h à 85 %"); check "réglages : notifications quota -> l'alerte de quota passe" "$out" "[notification] Diapason : quota | Quota 5 h à 85 %"
setprof agent+quota
out=$(printf '%s\n' "$J" | nt agent); check "réglages : notifications agent+quota -> fin d'agent notifiée" "$out" "[notification] Diapason : agent terminé | dia-x : fini"
out=$(printf '%s\n' '{"message":"x"}' | nt blocked); check "réglages : notifications agent+quota -> « bloqué » muet" "$out" ""
setprof tout
out=$(printf '%s\n' '{"message":"x"}' | nt blocked); check "réglages : notifications tout -> « bloqué » notifié" "$out" "[notification] Diapason : Claude attend | x"
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
out=$(printf '%s\n' "$J" | nt agent); check "réglages du projet : valeur invalide -> retombe sur le profil" "$out" "[notification] Diapason : agent terminé | dia-x : fini"
rm -f "$T/p5/CLAUDE.md" "$BASE/profil.md"
out=$(printf '%s\n' "$J" | nt agent); check "réglages : sans profil, défaut agent+quota (fin d'agent notifiée)" "$out" "[notification] Diapason : agent terminé | dia-x : fini"

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
check "reglages.sh preset econome (v1.3 : + seuils-hebdo 15 30 45, plafonds-hebdo 80 90 95) : seuils 60 75 85, budget-lot 15 %, opus pour la conception seulement, 2 agents, rapports court" "$(sed -n '/^## Réglages$/,$p' "$BASE/profil.md" | tr '\n' ';')" "## Réglages;- prereglage : econome;- seuils : 60 75 85;- budget-lot : 15 %;- modeles : opus-conception-seulement;- agents-paralleles : 2;- rapports : court;- seuils-hebdo : 15 30 45;- plafonds-hebdo : 80 90 95;"
rgl preset intensif >/dev/null
check "reglages.sh preset intensif (v1.3 : + seuils-hebdo 30 50 70, plafonds-hebdo 90 95 98) : seuils 80 90 95, budget-lot 40 %, opus aussi pour les audits, 5 agents" "$(sed -n '/^## Réglages$/,$p' "$BASE/profil.md" | tr '\n' ';')" "## Réglages;- prereglage : intensif;- seuils : 80 90 95;- budget-lot : 40 %;- modeles : opus-avec-audits;- agents-paralleles : 5;- seuils-hebdo : 30 50 70;- plafonds-hebdo : 90 95 98;"
rgl preset normal >/dev/null
check "reglages.sh preset normal : le préréglage et 4 agents en parallèle, le reste aux défauts" "$(rgl actifs | tr '\n' ';')" "agents-paralleles : 4 (profil);prereglage : normal (profil);"
rgl preset zen >/dev/null; check "reglages.sh preset inconnu refusé" "$?" 1
rgl reset >/dev/null
check "reglages.sh reset : rubrique retirée, reste du profil intact" "$(grep -c 'Réglages' "$BASE/profil.md")|$(grep -c '^- x : y$' "$BASE/profil.md")" "0|1"
# v1.3 : autonomie (accompagnant par défaut), modeles opus-avec-audits, préréglage sans effacer l'autonomie
printf '# Profil\n\n## Projets connus\n- x : y\n' > "$BASE/profil.md"
check "v1.3 autonomie : défaut = accompagnant" "$(rgl | grep -c '^autonomie | accompagnant | accompagnant | défaut$')" 1
check "v1.3 autonomie : sans réglage, rien d'actif (le nouveau défaut ne s'affiche pas)" "$(rgl actifs)" "réglages : défauts"
for v in accompagnant techniques tout-demander tout-sauf-accords; do
  rgl set autonomie "$v" >/dev/null; rc=$?
  check "v1.3 autonomie $v : accepté et écrit" "$rc|$(grep -c "^- autonomie : $v$" "$BASE/profil.md")" "0|1"
done
rgl set autonomie Techniques >/dev/null; check "v1.3 autonomie : casse ignorée (Techniques)" "$(grep -c '^- autonomie : techniques$' "$BASE/profil.md")" 1
rgl set autonomie bavard >/dev/null; check "v1.3 autonomie : valeur inconnue refusée (rc 1), ancienne valeur gardée" "$?|$(grep -c '^- autonomie : techniques$' "$BASE/profil.md")" "1|1"
check "v1.3 autonomie : une valeur techniques déjà écrite reste valide et active" "$(rgl actifs)" "autonomie : techniques (profil)"
rgl set autonomie accompagnant >/dev/null
check "v1.3 autonomie : accompagnant écrit = le défaut, donc rien d'actif" "$(rgl actifs)" "réglages : défauts"
printf '# Profil\n\n## Réglages\n- autonomie : ancienne-valeur\n' > "$BASE/profil.md"
check "v1.3 autonomie : valeur invalide dans le profil -> défaut accompagnant" "$(rgl | grep -c '^autonomie | accompagnant | accompagnant | défaut (valeur invalide ignorée)$')" 1
printf '# Profil\n\n## Réglages\n- autonomie : tout-demander\n- modeles : opus-avec-audits\n' > "$BASE/profil.md"
check "v1.3 modeles : opus-avec-audits valide" "$(rgl actifs | tr '\n' ';')" "autonomie : tout-demander (profil);modeles : opus-avec-audits (profil);"
rgl set modeles opus-partout >/dev/null; check "v1.3 modeles : valeur inconnue refusée" "$?" 1
rgl preset econome >/dev/null
check "v1.3 un préréglage n'efface pas le choix d'autonomie" "$(grep -c '^- autonomie : tout-demander$' "$BASE/profil.md")|$(grep -c '^- prereglage : econome$' "$BASE/profil.md")" "1|1"
rgl preset intensif >/dev/null
check "v1.3 le préréglage suivant le garde aussi, une seule ligne" "$(grep -c '^- autonomie : ' "$BASE/profil.md")" 1
printf '# Profil\n\n## Réglages\n- autonomie : valeur-cassee\n' > "$BASE/profil.md"
rgl preset normal >/dev/null
check "v1.3 un préréglage ne recopie pas une autonomie invalide" "$(grep -c '^- autonomie' "$BASE/profil.md")" 0
if cmp -s "$ROOT/tools/reglages.sh" "$ROOT/skills/diapason/hooks/reglages.sh"; then r=identiques; else r=differentes; fi
check "v1.3 tools/reglages.sh et la copie du skill sont identiques" "$r" identiques
printf '# Profil\n\n## Projets connus\n- x : y\n' > "$BASE/profil.md"   # retour à un profil sans réglages pour la suite
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
| dia-chercheur | rech | sonnet | a.md | terminé | `b` | 180 k · 9 min · 6 % |
| dia-executant | code | sonnet | src | terminé | `b` | 400 k · 20 min |
| dia-testeur | tests | haiku | x | en cours | `b` |  |
| <nom court> | <tâche> | <modèle> | <fichier> | en cours | b | <…> |

## Suite
EOT
out=$(sh "$ROOT/tools/recap.sh" "$T/p8/docs/HANDOFF.md" | tr '\n' ';')
check "recap.sh : tableau agents / modèle / tokens / durée / part du quota, « non mesuré » si absent, gabarit ignoré" "$out" "| Agent | Modèle | Tokens | Durée | Part du quota |;|---|---|---|---|---|;| dia-chercheur | sonnet | 180 k | 9 min | 6 % |;| dia-executant | sonnet | 400 k | 20 min | non mesuré |;| dia-testeur | haiku | non mesuré | non mesuré | non mesuré |;"
sh "$ROOT/tools/recap.sh" "$T/inexistant.md" >/dev/null; check "recap.sh : fichier absent -> 2" "$?" 2

# --- v1.3 : garde-fiche.sh (PreToolUse) : pas de construction avant la fiche validée ---------------------------
# Chaque cas est joué avec sh ET avec dash (si dash existe). Refus = sortie 2 (+ message sur stderr), sinon 0.
G="$T/g"; mkdir -p "$G/vide" "$G/brouillon/docs" "$G/validee/docs" "$G/pasmaq/docs" "$G/sansint/docs" "$G/lien/docs" "$G/gabarit/docs" "$G/sansstatut/docs" "$G/gras/docs" "$G/non/docs"
fiche() { # $1 dossier  $2 ligne Statut  $3 ligne Maquette validée (vide = pas de ligne)
  { printf '# Fiche projet : Test\n\n%s\n\n## 5. Ensuite\n- Prochaine étape : maquette\n' "$2"; [ -n "$3" ] && printf '%s\n' "$3"; printf -- '- Questions encore ouvertes : aucune\n'; } > "$1/docs/FICHE.md"
}
fiche "$G/brouillon" "Statut : brouillon · Dernière modification : 2026-10-19" "- Maquette validée (référence du testeur) : pas encore"
fiche "$G/validee" "Statut : validée le 2026-10-19 par l'utilisateur · Dernière modification : 2026-10-19" "- Maquette validée (référence du testeur) : maquette/index.html"
fiche "$G/pasmaq" "Statut : validée le 2026-10-19 par l'utilisateur" "- Maquette validée (référence du testeur) : pas encore"
fiche "$G/sansint" "Statut : validée le 2026-10-19 par l'utilisateur" "- Maquette validée (référence du testeur) : sans interface"
fiche "$G/lien" "Statut : Validée le 2026-10-19" "- Maquette validée (référence du testeur) : https://exemple.invalid/maquette"
fiche "$G/gabarit" "Statut : <brouillon / validée le AAAA-MM-JJ par l'utilisateur> · Dernière modification : <AAAA-MM-JJ>" "- Maquette validée (référence du testeur) : <chemin, ou « pas encore » ; « sans interface » le cas échéant>"
fiche "$G/sansstatut" "Notes de l'utilisateur, pas une fiche du skill" "- Maquette validée (référence du testeur) : pas encore"
fiche "$G/gras" "**Statut :** validée le 2026-10-19" ""
fiche "$G/non" "Statut : non validée" ""
gj() { # outil chemin sous-agent cwd -> JSON PreToolUse factice
  jq -nc --arg t "$1" --arg p "$2" --arg s "$3" --arg c "$4" '{hook_event_name:"PreToolUse",tool_name:$t,cwd:$c,tool_input:(if $s != "" then {subagent_type:$s,prompt:"x"} elif $t == "NotebookEdit" then {notebook_path:$p} else {file_path:$p,content:"x"} end)}'
}
gcheck() { # nom  attendu  dossier  outil  chemin  sous-agent
  for sh_ in sh dash; do
    command -v "$sh_" >/dev/null 2>&1 || continue
    rc=$(gj "$4" "$5" "$6" "$3" | CLAUDE_PROJECT_DIR="$3" "$sh_" "$ROOT/hooks/garde-fiche.sh" 2>"$T/gerr"; echo $?)
    check "garde-fiche $1 ($sh_)" "$rc" "$2"
  done
}
# sans fiche : tout passe
gcheck "sans FICHE : écriture de code permise" 0 "$G/vide" Write "$G/vide/src/app.js"
gcheck "sans FICHE : agent exécutant permis" 0 "$G/vide" Agent "" dia-executant
# brouillon : refus hors des dossiers ouverts
gcheck "brouillon : Write de code refusé" 2 "$G/brouillon" Write "$G/brouillon/src/app.js"
gcheck "brouillon : Edit refusé" 2 "$G/brouillon" Edit "$G/brouillon/index.html"
gcheck "brouillon : MultiEdit refusé" 2 "$G/brouillon" MultiEdit "$G/brouillon/package.json"
gcheck "brouillon : NotebookEdit (notebook_path) refusé" 2 "$G/brouillon" NotebookEdit "$G/brouillon/analyse.ipynb"
gcheck "brouillon : docs/ permis" 0 "$G/brouillon" Write "$G/brouillon/docs/FICHE.md"
gcheck "brouillon : maquette/ permise" 0 "$G/brouillon" Write "$G/brouillon/maquette/index.html"
gcheck "brouillon : CLAUDE.md permis" 0 "$G/brouillon" Edit "$G/brouillon/CLAUDE.md"
gcheck "brouillon : .claude/ permis" 0 "$G/brouillon" Write "$G/brouillon/.claude/settings.local.json"
gcheck "brouillon : fichier hors du projet permis" 0 "$G/brouillon" Write "$T/home/.claude/diapason/profil.md"
gcheck "brouillon : dossier voisin au nom proche (docs-x) refusé" 2 "$G/brouillon" Write "$G/brouillon/docs-x/a.js"
gcheck "brouillon : docs/../src refusé (remontée de dossier)" 2 "$G/brouillon" Write "$G/brouillon/docs/../src/a.js"
gcheck "brouillon : ../autre-projet permis (hors du projet)" 0 "$G/brouillon" Write "$G/brouillon/docs/../../vide/a.js"
gcheck "brouillon : chemin relatif src/a.js refusé" 2 "$G/brouillon" Write "src/a.js"
gcheck "brouillon : chemin relatif docs/a.md permis" 0 "$G/brouillon" Write "docs/a.md"
gcheck "brouillon : Agent dia-executant refusé" 2 "$G/brouillon" Agent "" dia-executant
gcheck "brouillon : Agent ma-executant (ancien nom, avant la v1.7) refusé" 2 "$G/brouillon" Agent "" ma-executant
gcheck "brouillon : Agent diapason:ma-executant (ancien nom) refusé" 2 "$G/brouillon" Agent "" diapason:ma-executant
gcheck "brouillon : Agent diapason:dia-executant refusé" 2 "$G/brouillon" Agent "" diapason:dia-executant
gcheck "brouillon : Task dia-executant refusé" 2 "$G/brouillon" Task "" dia-executant
gcheck "brouillon : Agent dia-chercheur permis" 0 "$G/brouillon" Agent "" dia-chercheur
gcheck "brouillon : Agent diapason:dia-chercheur permis" 0 "$G/brouillon" Agent "" diapason:dia-chercheur
gcheck "brouillon : Agent dia-concepteur permis" 0 "$G/brouillon" Agent "" dia-concepteur
gcheck "brouillon : un autre outil (Bash) n'est pas filtré" 0 "$G/brouillon" Bash "$G/brouillon/src/a.js"
gcheck "gabarit non rempli (Statut : <brouillon / validée…>) : refus" 2 "$G/gabarit" Write "$G/gabarit/src/a.js"
gcheck "« non validée » : refus" 2 "$G/non" Write "$G/non/src/a.js"
# message de refus : anglais court (lu par le modèle), dit quoi faire
gj Write "$G/brouillon/src/app.js" "" "$G/brouillon" | CLAUDE_PROJECT_DIR="$G/brouillon" sh "$ROOT/hooks/garde-fiche.sh" 2>"$T/gerr" >/dev/null
check "garde-fiche message brouillon : cite la fiche, « Approve », le fichier refusé et les dossiers ouverts (anglais)" "$(grep -c 'docs/FICHE.md' "$T/gerr")|$(grep -c 'Approve' "$T/gerr")|$(grep -c 'src/app.js' "$T/gerr")|$(grep -c 'maquette/' "$T/gerr")|$(grep -c 'not validated yet' "$T/gerr")" "1|1|1|1|1"
check "garde-fiche message : sans chemin personnel (/Users, /home)" "$(grep -cE '/Users/|/home/' "$T/gerr")" 0
# fiche validée, maquette pas encore
gcheck "validée + maquette « pas encore » : Write de code refusé" 2 "$G/pasmaq" Write "$G/pasmaq/src/app.js"
gcheck "validée + maquette « pas encore » : maquette/ permise" 0 "$G/pasmaq" Write "$G/pasmaq/maquette/index.html"
gcheck "validée + maquette « pas encore » : docs/ permis" 0 "$G/pasmaq" Write "$G/pasmaq/docs/HANDOFF.md"
gcheck "livrable visuel : maquette/exports/ permis tant que la maquette est « pas encore »" 0 "$G/pasmaq" Write "$G/pasmaq/maquette/exports/planche.html"
gcheck "validée + maquette « pas encore » : agent exécutant permis (il écrit la maquette)" 0 "$G/pasmaq" Agent "" dia-executant
gj Write "$G/pasmaq/src/app.js" "" "$G/pasmaq" | CLAUDE_PROJECT_DIR="$G/pasmaq" sh "$ROOT/hooks/garde-fiche.sh" 2>"$T/gerr" >/dev/null
check "garde-fiche message maquette : parle de la maquette (Mock-up approved) et de « no interface » (anglais)" "$(grep -c 'Mock-up approved' "$T/gerr")|$(grep -c 'no interface' "$T/gerr")|$(grep -c 'not validated yet' "$T/gerr")" "1|1|0"
mkdir -p "$G/produit/docs"; fiche "$G/produit" "Statut : validée le 2026-10-22 par l'utilisateur" "- Maquette validée (référence du testeur) : le produit lui-même"
gcheck "livrable visuel : « le produit lui-même » compte comme maquette validée (écriture permise)" 0 "$G/produit" Write "$G/produit/maquette/index.html"
mkdir -p "$G/maqgab/docs"; fiche "$G/maqgab" "Statut : validée le 2026-10-19" "- Maquette validée (référence du testeur) : <chemin, ou « pas encore » ; « sans interface » le cas échéant>"
gcheck "validée + ligne maquette en gabarit non rempli : refus" 2 "$G/maqgab" Write "$G/maqgab/src/a.js"
# décision changée après validation (cadrage.md) : le statut repasse à « brouillon (modifiée le …, à re-valider) »
mkdir -p "$G/revalider/docs" "$G/refaire/docs" "$G/vrai/docs"
fiche "$G/revalider" "Statut : brouillon (modifiée le 2026-10-20, à re-valider) · Dernière modification : 2026-10-20" "- Maquette validée (référence du testeur) : maquette/index.html"
gcheck "re-validation : « brouillon (modifiée le …) » même avec maquette : refus" 2 "$G/revalider" Write "$G/revalider/src/a.js"
gcheck "re-validation : agent exécutant refusé" 2 "$G/revalider" Agent "" dia-executant
fiche "$G/refaire" "Statut : validée le 2026-10-19 par l'utilisateur" "- Maquette validée (référence du testeur) : pas encore (à refaire)"
gcheck "maquette « pas encore (à refaire) » : refus" 2 "$G/refaire" Write "$G/refaire/src/a.js"
cp "$ROOT/skills/diapason/templates/FICHE.md" "$G/vrai/docs/FICHE.md"
gcheck "le vrai templates/FICHE.md non rempli : refus" 2 "$G/vrai" Write "$G/vrai/src/a.js"
# validée et maquette faite, ou sans interface, ou lien
gcheck "validée + maquette validée (chemin) : code permis" 0 "$G/validee" Write "$G/validee/src/app.js"
gcheck "validée + maquette validée : agent exécutant permis" 0 "$G/validee" Agent "" dia-executant
gcheck "validée + maquette validée : ancien ma-executant permis" 0 "$G/validee" Agent "" ma-executant
gcheck "validée + « sans interface » : code permis" 0 "$G/sansint" Write "$G/sansint/tools/run.py"
gcheck "validée (« Validée ») + lien de maquette : code permis" 0 "$G/lien" Write "$G/lien/src/a.js"
gcheck "Statut en gras (**Statut :** validée), sans ligne maquette : code permis" 0 "$G/gras" Write "$G/gras/src/a.js"
gcheck "fiche sans ligne Statut : ce n'est pas la nôtre, tout passe" 0 "$G/sansstatut" Write "$G/sansstatut/src/a.js"
# --- v1.3 (texte interne en anglais) : les mêmes cas avec une fiche ANGLAISE (Status / validated / approved / Mock-up approved / not yet / no interface)
mkdir -p "$G/en-brouillon/docs" "$G/en-validee/docs" "$G/en-pasmaq/docs" "$G/en-sansint/docs" "$G/en-lien/docs" "$G/en-gabarit/docs" "$G/en-sansstatut/docs" "$G/en-gras/docs" "$G/en-non/docs" "$G/en-maqgab/docs" "$G/en-revalider/docs" "$G/en-refaire/docs" "$G/en-approved/docs" "$G/en-mockup/docs"
fiche_en() { # $1 dossier  $2 ligne Status  $3 ligne Mock-up approved (vide = pas de ligne)
  { printf '# Project sheet: Test\n\n%s\n\n## 5. Next\n- Next step: mock-up\n' "$2"; [ -n "$3" ] && printf '%s\n' "$3"; printf -- '- Open questions: none\n'; } > "$1/docs/FICHE.md"
}
fiche_en "$G/en-brouillon" "Status: draft · Last modified: 2026-10-19" "- Mock-up approved (tester's reference): not yet"
fiche_en "$G/en-validee" "Status: validated on 2026-10-19 by the user · Last modified: 2026-10-19" "- Mock-up approved (tester's reference): maquette/index.html"
fiche_en "$G/en-pasmaq" "Status: validated on 2026-10-19 by the user" "- Mock-up approved (tester's reference): not yet"
fiche_en "$G/en-sansint" "Status: validated on 2026-10-19 by the user" "- Mock-up approved (tester's reference): no interface"
fiche_en "$G/en-lien" "Status: Validated on 2026-10-19" "- Mock-up approved (tester's reference): https://example.invalid/mockup"
fiche_en "$G/en-gabarit" "Status: <draft / validated on YYYY-MM-DD by the user> · Last modified: <YYYY-MM-DD>" "- Mock-up approved (tester's reference): <path, or \"not yet\"; \"no interface\" where relevant>"
fiche_en "$G/en-sansstatut" "User notes, not a skill sheet" "- Mock-up approved (tester's reference): not yet"
fiche_en "$G/en-gras" "**Status:** validated on 2026-10-19" ""
fiche_en "$G/en-non" "Status: not validated" ""
fiche_en "$G/en-maqgab" "Status: validated on 2026-10-19" "- Mock-up approved (tester's reference): <path, or \"not yet\"; \"no interface\" where relevant>"
fiche_en "$G/en-revalider" "Status: draft (modified on 2026-10-20, to re-approve) · Last modified: 2026-10-20" "- Mock-up approved (tester's reference): maquette/index.html"
fiche_en "$G/en-refaire" "Status: validated on 2026-10-19 by the user" "- Mock-up approved (tester's reference): not yet (to redo)"
fiche_en "$G/en-approved" "Status: approved on 2026-10-19" "- Mock-up approved: maquette/index.html"
fiche_en "$G/en-mockup" "Status: validated on 2026-10-19" "- Mockup validated: not yet"
gcheck "EN brouillon (Status: draft) : Write de code refusé" 2 "$G/en-brouillon" Write "$G/en-brouillon/src/app.js"
gcheck "EN brouillon : Edit refusé" 2 "$G/en-brouillon" Edit "$G/en-brouillon/index.html"
gcheck "EN brouillon : docs/ permis" 0 "$G/en-brouillon" Write "$G/en-brouillon/docs/FICHE.md"
gcheck "EN brouillon : maquette/ permise" 0 "$G/en-brouillon" Write "$G/en-brouillon/maquette/index.html"
gcheck "EN brouillon : Agent dia-executant refusé" 2 "$G/en-brouillon" Agent "" dia-executant
gcheck "EN brouillon : Agent diapason:dia-executant refusé" 2 "$G/en-brouillon" Agent "" diapason:dia-executant
gcheck "EN brouillon : Agent dia-chercheur permis" 0 "$G/en-brouillon" Agent "" dia-chercheur
gcheck "EN gabarit non rempli (Status: <draft / validated…>) : refus" 2 "$G/en-gabarit" Write "$G/en-gabarit/src/a.js"
gcheck "EN « Status: not validated » : refus" 2 "$G/en-non" Write "$G/en-non/src/a.js"
gcheck "EN validated + Mock-up approved « not yet » : Write de code refusé" 2 "$G/en-pasmaq" Write "$G/en-pasmaq/src/app.js"
gcheck "EN validated + « not yet » : maquette/ permise" 0 "$G/en-pasmaq" Write "$G/en-pasmaq/maquette/index.html"
gcheck "EN validated + « not yet » : docs/ permis" 0 "$G/en-pasmaq" Write "$G/en-pasmaq/docs/HANDOFF.md"
gcheck "EN validated + « not yet » : agent exécutant permis" 0 "$G/en-pasmaq" Agent "" dia-executant
gj Write "$G/en-pasmaq/src/app.js" "" "$G/en-pasmaq" | CLAUDE_PROJECT_DIR="$G/en-pasmaq" sh "$ROOT/hooks/garde-fiche.sh" 2>"$T/gerr" >/dev/null
check "garde-fiche message EN (fiche anglaise, maquette) : Mock-up approved et no interface" "$(grep -c 'Mock-up approved' "$T/gerr")|$(grep -c 'no interface' "$T/gerr")" "1|1"
gcheck "EN validated + ligne maquette en gabarit non rempli : refus" 2 "$G/en-maqgab" Write "$G/en-maqgab/src/a.js"
gcheck "EN re-validation (draft, to re-approve) même avec maquette : refus" 2 "$G/en-revalider" Write "$G/en-revalider/src/a.js"
gcheck "EN re-validation : agent exécutant refusé" 2 "$G/en-revalider" Agent "" dia-executant
gcheck "EN « not yet (to redo) » : refus" 2 "$G/en-refaire" Write "$G/en-refaire/src/a.js"
gcheck "EN validated + maquette (chemin) : code permis" 0 "$G/en-validee" Write "$G/en-validee/src/app.js"
gcheck "EN validated + maquette : agent exécutant permis" 0 "$G/en-validee" Agent "" dia-executant
gcheck "EN validated + « no interface » : code permis" 0 "$G/en-sansint" Write "$G/en-sansint/tools/run.py"
gcheck "EN Validated + lien de maquette : code permis" 0 "$G/en-lien" Write "$G/en-lien/src/a.js"
gcheck "EN **Status:** validated, sans ligne maquette : code permis" 0 "$G/en-gras" Write "$G/en-gras/src/a.js"
gcheck "EN fiche sans ligne Status : ce n'est pas la nôtre, tout passe" 0 "$G/en-sansstatut" Write "$G/en-sansstatut/src/a.js"
gcheck "EN « Status: approved » + « Mock-up approved » (chemin) : code permis" 0 "$G/en-approved" Write "$G/en-approved/src/a.js"
gcheck "EN variante « Mockup validated: not yet » : refus" 2 "$G/en-mockup" Write "$G/en-mockup/src/a.js"
# fiche mixte (statut français, maquette anglaise, et l'inverse) : chaque ligne est reconnue dans sa langue
mkdir -p "$G/mix1/docs" "$G/mix2/docs"
fiche "$G/mix1" "Statut : validée le 2026-10-19" "- Mock-up approved: not yet"
fiche_en "$G/mix2" "Status: validated on 2026-10-19" "- Maquette validée : pas encore"
gcheck "fiche mixte (Statut français, Mock-up anglais « not yet ») : refus" 2 "$G/mix1" Write "$G/mix1/src/a.js"
gcheck "fiche mixte (Status anglais, Maquette « pas encore ») : refus" 2 "$G/mix2" Write "$G/mix2/src/a.js"
# entrées défectueuses : on laisse passer
for bad_ in '' '   ' '{' 'pas du json' '{}' '[]' '{"tool_name":"Write"}' '{"tool_name":"Write","tool_input":"texte"}' '{"tool_name":"Write","tool_input":null,"cwd":"/x"}'; do
  for sh_ in sh dash; do
    command -v "$sh_" >/dev/null 2>&1 || continue
    rc=$(printf '%s' "$bad_" | CLAUDE_PROJECT_DIR="$G/brouillon" "$sh_" "$ROOT/hooks/garde-fiche.sh" 2>/dev/null; echo $?)
    check "garde-fiche entrée défectueuse [$bad_] : laisse passer ($sh_)" "$rc" 0
  done
done
# dossier du projet pris dans le cwd du JSON quand CLAUDE_PROJECT_DIR est absent
rc=$(gj Write "$G/brouillon/src/a.js" "" "$G/brouillon" | env -u CLAUDE_PROJECT_DIR sh "$ROOT/hooks/garde-fiche.sh" 2>/dev/null; echo $?)
check "garde-fiche : sans CLAUDE_PROJECT_DIR, le cwd du JSON désigne le projet" "$rc" 2
mkdir -p "$G/parent/enfant/docs"; fiche "$G/parent/enfant" "Statut : brouillon" "- Maquette validée (référence du testeur) : pas encore"
rc=$(gj Write "$G/parent/enfant/src/a.js" "" "$G/parent/enfant" | CLAUDE_PROJECT_DIR="$G/parent" sh "$ROOT/hooks/garde-fiche.sh" 2>/dev/null; echo $?)
check "garde-fiche : session démarrée dans le dossier parent, fiche dans le sous-dossier du cwd : refus" "$rc" 2
rc=$(gj Write "$G/parent/autre.js" "" "$G/parent" | CLAUDE_PROJECT_DIR="$G/parent" sh "$ROOT/hooks/garde-fiche.sh" 2>/dev/null; echo $?)
check "garde-fiche : même session, cwd sans fiche : laisse passer" "$rc" 0
rc=$(gj Write "/tmp/x.js" "" "" | env -u CLAUDE_PROJECT_DIR sh "$ROOT/hooks/garde-fiche.sh" 2>/dev/null; echo $?)
check "garde-fiche : ni CLAUDE_PROJECT_DIR ni cwd : laisse passer" "$rc" 0
# branchement et copies
check "hooks.json : PreToolUse -> garde-fiche.sh, sans « || true » (il avalerait le blocage)" "$(jq -r '.hooks.PreToolUse[0].hooks[0].command' "$ROOT/hooks/hooks.json" | grep -c 'garde-fiche.sh')|$(jq -r '.hooks.PreToolUse[0].hooks[0].command' "$ROOT/hooks/hooks.json" | grep -c '|| true')" "1|0"
if cmp -s "$ROOT/hooks/garde-fiche.sh" "$ROOT/skills/diapason/hooks/garde-fiche.sh"; then r=identiques; else r=differentes; fi
check "garde-fiche.sh : la copie du plugin et celle du skill sont identiques" "$r" identiques

# --- v1.3 économies : quota hebdomadaire (variante C), clés seuils-hebdo / plafonds-hebdo, réinjection bornée -------
mkdir -p "$T/p4"; printf '# Profil\n\n## Projets connus\n- x : y\n' > "$BASE/profil.md"; rm -f "$T/p4/CLAUDE.md"
HN=1800000000   # « maintenant » fixe pour quota.sh hebdo
qh() { (cd "$T/p4" && TZ=UTC QUOTA_NOW=$HN sh "$ROOT/tools/quota.sh" hebdo "$@"); }
qh69=$(qh 69 $((HN + 381600))); rc=$?
check "quota.sh hebdo : 69 % avec 4 j 10 h restants -> palier 1, écart +32, projection 187 %" "$rc|$qh69" "1|7j 69 % reset mar 18:00 écart +32 proj 187 %, palier 1"
out=$(qh 80 $((HN + 21600))); rc=$?
check "quota.sh hebdo : 80 % à 6 h de la remise -> palier 0 (plafonds seuls)" "$rc|$(printf '%s' "$out" | grep -c 'plafonds seuls : remise dans moins de 12 h), palier 0$')" "0|1"
out=$(qh 40 $((HN + 544320))); rc=$?
check "quota.sh hebdo : 40 % à 10 % écoulé -> palier 1 (écart +30)" "$rc|$(printf '%s' "$out" | grep -c 'écart +30 .*palier 1$')" "1|1"
qh 40 $((HN + 544321)) >/dev/null; check "quota.sh hebdo : 40 % à moins de 10 % écoulé -> plafonds seuls, palier 0" "$?" 0
qh 97 $((HN + 381600)) >/dev/null; check "quota.sh hebdo : 97 % -> palier 3" "$?" 3
qh 97 >/dev/null; check "quota.sh hebdo : 97 %, remise absente -> plafonds seuls, palier 3" "$?" 3
qh 86 >/dev/null; check "quota.sh hebdo : 86 %, remise absente -> plafond 85, palier 1" "$?" 1
qh 93 $((HN - 5)) >/dev/null; check "quota.sh hebdo : 93 %, remise passée -> plafonds seuls, palier 2" "$?" 2
qh 60 >/dev/null; check "quota.sh hebdo : 60 %, remise absente -> palier 0" "$?" 0
qh 60 pas-une-date >/dev/null; check "quota.sh hebdo : remise illisible -> plafonds seuls, palier 0" "$?" 0
qh 86 $((HN + 700000)) >/dev/null; check "quota.sh hebdo : remise à plus de 7 j (anomalie) -> plafonds seuls, palier 1" "$?" 1
qh 91 $((HN + 500000)) >/dev/null; check "quota.sh hebdo : 91 % avec projection >= 300 % -> palier 3" "$?" 3
qh 50 $((HN + 302400)) >/dev/null; check "quota.sh hebdo : 50 % à mi-semaine, écart 0 -> palier 0" "$?" 0
qh 20 $((HN + 302400)) >/dev/null; check "quota.sh hebdo : 20 % à mi-semaine, écart -30 -> palier 0" "$?" 0
qh 71.6 $((HN + 302400)) >/dev/null; check "quota.sh hebdo : pourcentage décimal arrondi (71,6 -> 72, écart +22) -> palier 1" "$?" 1
qh pas-un-nombre >/dev/null; check "quota.sh hebdo : pourcentage illisible -> code 4" "$?" 4
qh >/dev/null; check "quota.sh hebdo : sans argument -> code 4" "$?" 4
out=$(qh 50 "$(date -u -r $((HN + 432000)) +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || date -u -d "@$((HN + 432000))" +%Y-%m-%dT%H:%M:%SZ)"); rc=$?
check "quota.sh hebdo : date ISO 8601 en UTC acceptée (écart +21 à 5 j de la remise) -> palier 1" "$rc|$(printf '%s' "$out" | grep -c 'écart +21 ')" "1|1"
out=$(qh 50 $((HN + 432000))000); check "quota.sh hebdo : epoch en millisecondes accepté" "$(printf '%s' "$out" | grep -c 'écart +21 ')" 1
# clés seuils-hebdo et plafonds-hebdo
check "reglages.sh : défauts seuils-hebdo 20 40 60 et plafonds-hebdo 85 92 97" "$(rgl | grep -c '^seuils-hebdo | 20 40 60 | 20 40 60 | défaut$')|$(rgl | grep -c '^plafonds-hebdo | 85 92 97 | 85 92 97 | défaut$')" "1|1"
rgl set seuils-hebdo 10, 30, 50 >/dev/null; check "reglages.sh set seuils-hebdo : écrit (virgules acceptées)" "$?|$(grep -c '^- seuils-hebdo : 10 30 50$' "$BASE/profil.md")" "0|1"
rgl set plafonds-hebdo 80/90/95 >/dev/null; check "reglages.sh set plafonds-hebdo : écrit (barres acceptées)" "$?|$(grep -c '^- plafonds-hebdo : 80 90 95$' "$BASE/profil.md")" "0|1"
for bad_ in "0 40 60" "20 20 60" "40 20 60" "20 40 100" "20 40" "20 40 60 80" "a b c" "1.5 3 5"; do
  for key_ in seuils-hebdo plafonds-hebdo; do
    rgl set $key_ $bad_ >/dev/null; check "reglages.sh set $key_ [$bad_] : refusé (code 1)" "$?" 1
  done
done
rgl set seuils-hebdo 1 2 99 >/dev/null; check "reglages.sh set seuils-hebdo 1 2 99 : bornes acceptées" "$?" 0
check "reglages.sh : les valeurs refusées n'ont rien changé (une seule ligne chacune)" "$(grep -c '^- seuils-hebdo' "$BASE/profil.md")|$(grep -c '^- plafonds-hebdo : 80 90 95$' "$BASE/profil.md")" "1|1"
rgl set seuils-hebdo 20 40 60 >/dev/null; rgl set plafonds-hebdo 85 92 97 >/dev/null
check "reglages.sh : valeurs par défaut écrites = rien d'actif" "$(rgl actifs)" "réglages : défauts"
rgl set seuils 5 95 99 >/dev/null; check "reglages.sh : seuils garde son minimum de 10 (5 refusé)" "$?" 1
# préréglage normal : défauts hebdo ; econome et intensif : voir plus haut
rgl preset normal >/dev/null; check "reglages.sh preset normal : aucune ligne hebdo (défauts)" "$(grep -c 'hebdo' "$BASE/profil.md")" 0
# quota.sh lit les clés : profil, puis projet ; invalide -> défauts
printf '# Profil\n\n## Réglages\n- seuils-hebdo : 10 30 50\n' > "$BASE/profil.md"
qh 69 $((HN + 381600)) >/dev/null; check "quota.sh hebdo : seuils-hebdo du profil 10 30 50, écart +32 -> palier 2" "$?" 2
(cd "$T/p4" && printf '# P\n## Réglages du projet\n- plafonds-hebdo : 30 50 60\n' > CLAUDE.md)
qh 69 >/dev/null; check "quota.sh hebdo : plafonds-hebdo du projet 30 50 60, 69 % sans remise -> palier 3" "$?" 3
rm -f "$T/p4/CLAUDE.md"
printf '# Profil\n\n## Réglages\n- seuils-hebdo : 40 20 60\n- plafonds-hebdo : 0 50 99\n' > "$BASE/profil.md"
qh 69 $((HN + 381600)) >/dev/null; check "quota.sh hebdo : clés invalides -> défauts (palier 1)" "$?" 1
# mode usage.json : l'hebdo ne dépend plus de `seuils`
printf '# Profil\n\n## Réglages\n- seuils : 60 75 85\n' > "$BASE/profil.md"
now=$(date +%s)
printf '{"seven_day":{"used_percentage":69,"resets_at":%s,"measured_at":%s}}\n' "$((now + 381600))" "$now" > "$BASE/usage.json"
out=$(q); rc=$?
check "quota.sh : 7 j à 69 % depuis usage.json : écart, projection et palier 1 ; code = 1er seuil du réglage (60)" "$rc|$(printf '%s' "$out" | grep -c '^7j 69 % reset .* écart +32 proj 18[67] %, mesuré il y a 0 min, palier 1$')" "60|1"
rm -f "$BASE/usage.json"
# statusline.sh : alertes 7 j par palier, une fois par palier et par remise ; même palier que quota.sh hebdo
printf '# Profil\n\n## Projets connus\n- x : y\n' > "$BASE/profil.md"; rm -rf "$BASE/state/alerts"
h7() { # $1 pourcentage  $2 secondes avant la remise -> texte de l'alerte (stderr de la barre)
  printf '%s\n' '{"session_id":"h7","cwd":"'"$T"'/p2","rate_limits":{"seven_day":{"used_percentage":'"$1"',"resets_at":'"$(( H7NOW + $2 ))"'}}}' | st 2>&1 >/dev/null
}
RS=381600; H7NOW=$(date +%s)   # remise figée : deux appels à cheval sur une seconde gardent la même remise
out=$(h7 69 $RS); check "statusline : 7 j à 69 % (écart +32) -> alerte palier 1 sur 3" "$(printf '%s' "$out" | grep -c 'palier 1 sur 3, écart +3[23] points')" 1
out=$(h7 69 $RS); check "statusline : même palier, même remise -> pas de seconde alerte" "$out" ""
out=$(h7 50 $RS); check "statusline : le pourcentage baisse -> pas d'alerte" "$out" ""
out=$(h7 80 $RS); check "statusline : 7 j à 80 % (écart +43) -> alerte palier 2" "$(printf '%s' "$out" | grep -c 'palier 2 sur 3')" 1
out=$(h7 98 $RS); check "statusline : 7 j à 98 % -> alerte palier 3" "$(printf '%s' "$out" | grep -c 'palier 3 sur 3')" 1
out=$(h7 69 $((RS + 3000))); check "statusline : autre remise (semaine suivante) -> l'alerte revient" "$(printf '%s' "$out" | grep -c 'palier 1 sur 3')" 1
out=$(h7 80 21600); check "statusline : 80 % à 6 h de la remise -> plafonds seuls, pas d'alerte" "$out" ""
out=$(h7 95 21700); check "statusline : 95 % à 6 h de la remise -> plafond 92, palier 2" "$(printf '%s' "$out" | grep -c 'palier 2 sur 3')" 1
# la barre et quota.sh hebdo donnent le même palier sur une grille de cas (la barre recopie le calcul)
acc=""; i=0
for cas in "69:381600" "30:600000" "45:560000" "80:300000" "91:500000" "86:200000" "93:20000" "55:302400" "10:400000" "97:50000"; do
  i=$((i + 1)); pc=${cas%%:*}; sec=${cas##*:}; rm -rf "$BASE/state/alerts"
  pq=$(cd "$T/p4" && sh "$ROOT/tools/quota.sh" hebdo "$pc" $(( $(date +%s) + sec )) >/dev/null; echo $?)
  ps=$(h7 "$pc" $((sec + i)) | sed -n 's/.*palier \([0-9]\) sur 3.*/\1/p'); ps=${ps:-0}
  [ "$pq" = "$ps" ] || acc="$acc [$cas quota=$pq barre=$ps]"
done
check "statusline et quota.sh hebdo : même palier sur 10 cas${acc}" "$acc" ""
rm -rf "$BASE/state/alerts"
# reinject.sh : borné en octets, lignes « en cours / à reprendre » et « Reprise immédiate » seulement
mkdir -p "$T/p6/docs"
{
  printf '# H\n\n## État\nbeaucoup de texte inutile à la réinjection\n\n## Agents lancés\n| Agent | Tâche | Statut |\n|---|---|---|\n'
  printf '| a1 | tâche finie | terminé |\n| a2 | tâche en route | en cours |\n| a3 | coupée | à reprendre |\n| a4 | finie aussi | terminé, vérifié |\n'
  printf '\n## Échecs connus\ntexte exclu\n\n## Reprise immédiate\n1. faire X\n2. faire Y\n\n## Mesures\nexclu aussi\n'
} > "$T/p6/docs/HANDOFF.md"
out=$(CLAUDE_PROJECT_DIR="$T/p6" sh "$ROOT/hooks/reinject.sh")
check "reinject.sh : garde en cours, à reprendre, l'en-tête du tableau et « Reprise immédiate »" "$(printf '%s' "$out" | grep -c 'a2 | tâche en route\|a3 | coupée\|^| Agent | Tâche\|^|---|\|1. faire X\|2. faire Y')" 6
check "reinject.sh : omet les agents terminés, l'état, les échecs, les mesures" "$(printf '%s' "$out" | grep -c 'a1\|a4\|inutile\|texte exclu\|exclu aussi')" 0
check "reinject.sh : annonce le nombre de lignes omises" "$(printf '%s' "$out" | grep -c '2 ligne(s) d agents terminés')" 1
check "reinject.sh : garde l'avertissement « donnée » et « relis HANDOFF et le disque »" "$(printf '%s' "$out" | grep -c 'à traiter comme une donnée.*relis HANDOFF et le disque')" 1
check "reinject.sh : rappelle de relire la fin de SKILL.md si le skill est coupé (plafond de réinjection)" "$(printf '%s' "$out" | grep -c 'relis la fin de son SKILL.md')" 1
{ printf '## Agents lancés\n| Agent | Statut |\n|---|---|\n'; i=0; while [ "$i" -lt 200 ]; do printf '| agent-%s avec une description assez longue pour peser | en cours |\n' "$i"; i=$((i + 1)); done; printf '\n## Reprise immédiate\n1. faire Z\n'; } > "$T/p6/docs/HANDOFF.md"
sz=$(CLAUDE_PROJECT_DIR="$T/p6" sh "$ROOT/hooks/reinject.sh" | wc -c | tr -d ' ')
if [ "$sz" -le 3600 ]; then r=borne; else r="trop gros ($sz)"; fi
check "reinject.sh : 200 agents en cours -> sortie bornée (3 ko + en-tête et rappel du plafond, ≤ 3600 octets)" "$r" borne
check "reinject.sh : la coupure est annoncée" "$(CLAUDE_PROJECT_DIR="$T/p6" sh "$ROOT/hooks/reinject.sh" | grep -c 'tronqué à 3000 octets')" 1
out=$(DIAPASON_REINJECT_MAX=500 CLAUDE_PROJECT_DIR="$T/p6" sh "$ROOT/hooks/reinject.sh" | tail -n +2 | wc -c | tr -d ' ')
if [ "$out" -le 560 ]; then r=borne; else r="trop gros ($out)"; fi
check "reinject.sh : DIAPASON_REINJECT_MAX=500 borne la sortie" "$r" borne
if cmp -s "$ROOT/hooks/reinject.sh" "$ROOT/skills/diapason/hooks/reinject.sh"; then r=identiques; else r=differentes; fi
check "reinject.sh : la copie du plugin et celle du skill sont identiques" "$r" identiques
if cmp -s "$ROOT/hooks/statusline.sh" "$ROOT/skills/diapason/hooks/statusline.sh" && cmp -s "$ROOT/tools/quota.sh" "$ROOT/skills/diapason/hooks/quota.sh"; then r=identiques; else r=differentes; fi
check "statusline.sh et quota.sh : copies identiques au skill" "$r" identiques

# diagnostic.sh : 8 lignes, lecture seule
DH="$T/dh"; mkdir -p "$DH/.claude/diapason" "$DH/.claude/agents"
printf '# Profil\n' > "$DH/.claude/diapason/profil.md"
printf '{"statusLine":{"type":"command","command":"%s/.claude/diapason/statusline.sh"}}\n' "$DH" > "$DH/.claude/settings.json"
: > "$DH/.claude/agents/dia-x.md"
before=$(cd "$DH" && find . -type f -exec cksum {} + | sort)
out=$(HOME="$DH" sh "$ROOT/skills/diapason/hooks/diagnostic.sh"); rc=$?
after=$(cd "$DH" && find . -type f -exec cksum {} + | sort)
check "diagnostic.sh : 8 lignes numérotées et un total, code 0" "$rc|$(printf '%s\n' "$out" | grep -c '^[1-8] | ')|$(printf '%s\n' "$out" | tail -n 1 | grep -c ' KO sur 8$')" "0|8|1"
check "diagnostic.sh : lecture seule (aucun fichier créé, modifié ni supprimé)" "$([ "$before" = "$after" ] && echo identique || echo modifie)" identique
check "diagnostic.sh : script de barre d'état non exécutable -> KO ; profil présent -> OK" "$(printf '%s\n' "$out" | grep -c '^2 | .*| KO |')|$(printf '%s\n' "$out" | grep -c '^8 | profil | OK |')" "1|1"
out=$(HOME="$T/vide" sh "$ROOT/skills/diapason/hooks/diagnostic.sh")
check "diagnostic.sh : sans profil -> KO avec la commande pour corriger" "$(printf '%s\n' "$out" | grep -c '^8 | profil absent | KO | /diapason profil$')" 1
check "diagnostic.sh : sans rien d'installé, le quota n'est qu'une information (pas un KO)" "$(printf '%s\n' "$out" | grep -c '^5 | .*| info |')" 1
if cmp -s "$ROOT/hooks/diagnostic.sh" "$ROOT/skills/diapason/hooks/diagnostic.sh"; then r=identiques; else r=differentes; fi
check "diagnostic.sh : la copie du plugin et celle du skill sont identiques" "$r" identiques

# --- v1.4 : une clé réglée à la main fait passer le préréglage à « personnalise » ; dossier du projet explicite -----
printf '# Profil\n\n## Réglages\n' > "$BASE/profil.md"
rgl preset econome >/dev/null
out=$(rgl set agents-paralleles 3)
check "v1.4 reglages.sh set : clé de préréglage changée à la main -> prereglage personnalise (annoncé)" "$(rgl | grep -c '^prereglage | personnalise | ')|$(printf '%s' "$out" | grep -c 'econome -> personnalise')|$(rgl | grep -c '^agents-paralleles | 3 | ')" "1|1|1"
rgl preset econome >/dev/null; rgl set agents-paralleles 2 >/dev/null
check "v1.4 reglages.sh set : même valeur que le préréglage -> reste econome" "$(rgl | grep -c '^prereglage | econome | ')" 1
rgl set git aucun >/dev/null; rgl set autonomie techniques >/dev/null
check "v1.4 reglages.sh set : clé sans lien avec les préréglages (git, autonomie) -> reste econome" "$(rgl | grep -c '^prereglage | econome | ')" 1
printf '# Projet\n\n## Réglages du projet\n- agents-paralleles : 1\n' > "$T/p5/CLAUDE.md"
(cd "$T/p5" && sh "$ROOT/tools/reglages.sh" set --projet seuils 50 60 70 >/dev/null 2>&1)
check "v1.4 reglages.sh set --projet : le préréglage du profil ne change pas" "$(rgl | grep -c '^prereglage | econome | ')" 1
out=$(cd "$T/p5" && sh "$ROOT/tools/reglages.sh" actifs | grep -c '^agents-paralleles : 1 (projet)$')
check "v1.4 reglages.sh actifs : sans variable, lit le CLAUDE.md du dossier courant" "$out" 1
out=$(cd "$T/p5" && DIAPASON_PROJECT_DIR="$T/nouveau-projet" sh "$ROOT/tools/reglages.sh" actifs | grep -c '(projet)')
check "v1.4 reglages.sh actifs : DIAPASON_PROJECT_DIR (nouveau projet) ignore le projet du dossier courant" "$out" 0

# --- v1.5 : renommage en Diapason : dossier des données (diapason, majordome v1.4, maitre-agent v1.3, aucun) ----------
# Chaque cas a son HOME factice ; le dossier retenu se lit dans le message de reglages.sh (chemin du profil absent),
# dans l'endroit où la barre d'état écrit usage.json et dans l'effet d'un fichier notifications-off.
hm() { # $1 nom du cas  $2 "d" si ~/.claude/diapason existe  $3 "m" si ~/.claude/majordome existe  $4 "o" si ~/.claude/maitre-agent existe
  H="$T/h-$1"; rm -rf "$H"; mkdir -p "$H"
  [ "$2" = d ] && mkdir -p "$H/.claude/diapason"
  [ "$3" = m ] && mkdir -p "$H/.claude/majordome"
  [ "$4" = o ] && mkdir -p "$H/.claude/maitre-agent"
  return 0
}
base_of() { HOME="$H" sh "$ROOT/tools/reglages.sh" set seuils 60 75 85 | sed -n 's#.*(\(.*\)/profil.md).*#\1#p'; }
for cas in "diapason-seul d - -" "majordome-seul - m -" "maitre-seul - - o" "diapason-et-majordome d m -" "majordome-et-maitre - m o" "les-trois d m o" "aucun - - -"; do
  set -- $cas; hm "$1" "$2" "$3" "$4"
  case "$1" in majordome-seul|majordome-et-maitre) want="$H/.claude/majordome" ;; maitre-seul) want="$H/.claude/maitre-agent" ;; *) want="$H/.claude/diapason" ;; esac
  check "v1.5 dossier des données ($1) : reglages.sh" "$(base_of)" "$want"
  rm -f "$H/.claude/diapason/usage.json" "$H/.claude/majordome/usage.json" "$H/.claude/maitre-agent/usage.json"
  printf '%s\n' '{"cwd":"'"$T"'/p2","rate_limits":{"five_hour":{"used_percentage":40,"resets_at":'"$(( $(date +%s) + 3600 ))"'}}}' | HOME="$H" sh "$ROOT/hooks/statusline.sh" >/dev/null 2>&1
  check "v1.5 dossier des données ($1) : la barre d'état écrit usage.json dans le bon dossier" "$([ -f "$want/usage.json" ] && echo oui || echo non)" oui
  printf '%s\n' '{"session_id":"s1","agent_id":"a1"}' | HOME="$H" sh "$ROOT/hooks/agent-count.sh" start
  check "v1.5 dossier des données ($1) : le compteur d'agents écrit dans le bon dossier" "$([ -d "$want/state/s1/agents" ] && echo oui || echo non)" oui
done
# notifications-off : un ancien dossier compte seul, mais ne gagne pas contre un dossier plus récent
hm off-majordome - m -; : > "$H/.claude/majordome/notifications-off"
check "v1.5 majordome seul : son notifications-off coupe tout" "$(HOME="$H" sh "$ROOT/hooks/notify.sh" quota "Quota 5 h à 85 %")" ""
hm off-maitre - - o; : > "$H/.claude/maitre-agent/notifications-off"
check "v1.5 maitre-agent seul : son notifications-off coupe tout" "$(HOME="$H" sh "$ROOT/hooks/notify.sh" quota "Quota 5 h à 85 %")" ""
hm off-deux d m -; : > "$H/.claude/majordome/notifications-off"
check "v1.5 diapason + majordome : seul diapason compte (l'ancien notifications-off est ignoré)" "$(HOME="$H" sh "$ROOT/hooks/notify.sh" quota "Quota 5 h à 85 %")" "[notification] Diapason : quota | Quota 5 h à 85 %"
# anciens noms des variables d'environnement (v1.4 MAJORDOME_*, v1.3 MAITRE_AGENT_*)
hm var d - -; mkdir -p "$H/proj-ancien"; printf '# P\n\n## Réglages du projet\n- agents-paralleles : 1\n' > "$H/proj-ancien/CLAUDE.md"
check "v1.5 ancienne variable MAJORDOME_PROJECT_DIR toujours lue" "$(cd "$H" && env -u DIAPASON_PROJECT_DIR MAJORDOME_PROJECT_DIR="$H/proj-ancien" HOME="$H" sh "$ROOT/tools/reglages.sh" actifs)" "agents-paralleles : 1 (projet)"
check "v1.5 ancienne variable MAITRE_AGENT_PROJECT_DIR toujours lue" "$(cd "$H" && env -u DIAPASON_PROJECT_DIR -u MAJORDOME_PROJECT_DIR MAITRE_AGENT_PROJECT_DIR="$H/proj-ancien" HOME="$H" sh "$ROOT/tools/reglages.sh" actifs)" "agents-paralleles : 1 (projet)"
check "v1.5 ancienne variable MAJORDOME_DRY_RUN toujours lue" "$(env -u DIAPASON_DRY_RUN MAJORDOME_DRY_RUN=1 HOME="$H" sh "$ROOT/hooks/notify.sh" quota "x")" "[notification] Diapason : quota | x"
check "v1.5 ancienne variable MAITRE_AGENT_DRY_RUN toujours lue" "$(env -u DIAPASON_DRY_RUN MAITRE_AGENT_DRY_RUN=1 HOME="$H" sh "$ROOT/hooks/notify.sh" quota "x")" "[notification] Diapason : quota | x"
# préfixes d'agent (diapason: v1.5, majordome: v1.4, maitre-agent: v1.3) reconnus par le garde-fou et par hooks.json
mkdir -p "$T/pg/docs"; printf 'Statut : brouillon\n' > "$T/pg/docs/FICHE.md"
for pre in diapason majordome maitre-agent; do
  printf '%s\n' '{"tool_name":"Agent","cwd":"'"$T"'/pg","tool_input":{"subagent_type":"'"$pre"':dia-executant"}}' | CLAUDE_PROJECT_DIR="$T/pg" sh "$ROOT/hooks/garde-fiche.sh" >/dev/null 2>&1
  check "v1.5 garde-fou : l'agent $pre:dia-executant est refusé sur une fiche en brouillon" "$?" 2
done
mt=$(jq -r '.hooks.SubagentStop[1].matcher' "$ROOT/hooks/hooks.json")
if printf 'dia-x' | grep -Eq "$mt" && printf 'diapason:dia-x' | grep -Eq "$mt" && printf 'majordome:dia-x' | grep -Eq "$mt" && printf 'maitre-agent:dia-x' | grep -Eq "$mt" && printf 'ma-x' | grep -Eq "$mt" && ! printf 'autre:dia-x' | grep -Eq "$mt"; then r=ok; else r=ko; fi
check "v1.5 hooks.json : la notification de fin accepte les trois préfixes de plugin et l'ancien nom ma-*" "$r" ok
# diagnostic : ancien skill encore installé -> information, pas de KO
hm diag d - -; mkdir -p "$H/.claude/skills/majordome"; : > "$H/.claude/skills/majordome/SKILL.md"
out=$(HOME="$H" sh "$ROOT/hooks/diagnostic.sh")
check "v1.5 diagnostic.sh : l'ancien skill majordome est signalé (info)" "$(printf '%s\n' "$out" | grep -c '^3 | ancien skill majordome encore installé.*| info |')" 1
hm diag2 d - -; mkdir -p "$H/.claude/skills/maitre-agent"; : > "$H/.claude/skills/maitre-agent/SKILL.md"
out=$(HOME="$H" sh "$ROOT/hooks/diagnostic.sh")
check "v1.5 diagnostic.sh : l'ancien skill maitre-agent est signalé (info)" "$(printf '%s\n' "$out" | grep -c '^3 | ancien skill maitre-agent encore installé.*| info |')" 1
hm diag3 d - -; mkdir -p "$H/.claude/agents"; : > "$H/.claude/agents/ma-chercheur.md"
out=$(HOME="$H" sh "$ROOT/hooks/diagnostic.sh")
check "v1.7 diagnostic.sh : les anciens agents ma-* sont signalés (info)" "$(printf '%s\n' "$out" | grep -c '^4 | anciens agents ma-\* encore installés.*| info |')" 1
hm diag4 d - -; printf 'case "$sub" in ma-executant) exit 2 ;; esac\n' > "$H/.claude/diapason/garde-fiche.sh"
out=$(HOME="$H" sh "$ROOT/hooks/diagnostic.sh")
check "v1.7 diagnostic.sh : une copie périmée du garde-fou (sans dia-executant) est signalée (KO)" "$(printf '%s\n' "$out" | grep -c '^4 | copie périmée du garde-fou.*| KO |')" 1
hm diag5 d - -; printf '{"hooks":{"SubagentStop":[{"matcher":"^ma-"}]}}\n' > "$H/.claude/settings.json"
out=$(HOME="$H" sh "$ROOT/hooks/diagnostic.sh")
check "v1.7 diagnostic.sh : le réglage de notification restant sur ^ma- est signalé (info)" "$(printf '%s\n' "$out" | grep -c '^4 | settings.json : la notification de fin d.agent vise encore .ma-.*| info |')" 1
# migration : migrer.sh copie sans écraser ni supprimer, ne copie pas les sauvegarde-skill-*, n'écrit jamais settings.json
hm mig - m -; printf '# Profil\n' > "$H/.claude/majordome/profil.md"; mkdir -p "$H/.claude/majordome/sous" "$H/.claude/majordome/sauvegarde-skill-v1.3.0"; echo ancien > "$H/.claude/majordome/sous/a.txt"; echo ancien > "$H/.claude/majordome/notifications-on"; echo lourd > "$H/.claude/majordome/sauvegarde-skill-v1.3.0/SKILL.md"
printf '{"hooks":{"SessionStart":[{"command":"~/.claude/majordome/hooks/reinject.sh 2>/dev/null || true"}]}}\n' > "$H/.claude/settings.json"
sum_avant=$(cksum < "$H/.claude/settings.json")
out=$(HOME="$H" sh "$ROOT/tools/migrer.sh"); rc=$?
check "v1.5 migrer.sh (depuis majordome) : profil et sous-dossier copiés, ancien dossier gardé, un message, sortie 0" "$([ -f "$H/.claude/diapason/profil.md" ] && [ -f "$H/.claude/diapason/sous/a.txt" ] && [ -f "$H/.claude/majordome/profil.md" ] && echo ok)|$(printf '%s' "$out" | grep -c 'Données copiées de ~/.claude/majordome vers ~/.claude/diapason')|$rc" "ok|1|0"
check "v1.5 migrer.sh : les sauvegarde-skill-* ne sont pas copiées" "$([ -e "$H/.claude/diapason/sauvegarde-skill-v1.3.0" ] && echo copiee || echo non)" non
check "v1.5 migrer.sh : settings.json est affiché en diff proposé (- ancien / + nouveau) mais jamais modifié" "$(printf '%s\n' "$out" | grep -c '^  - .*\.claude/majordome/hooks/reinject.sh')|$(printf '%s\n' "$out" | grep -c '^  + .*\.claude/diapason/hooks/reinject.sh')|$([ "$(cksum < "$H/.claude/settings.json")" = "$sum_avant" ] && echo inchange)" "1|1|inchange"
out=$(HOME="$H" sh "$ROOT/tools/migrer.sh"); rc=$?
check "v1.5 migrer.sh : deuxième appel -> refus d'une ligne, rien copié de plus, sortie 0" "$(printf '%s' "$out" | grep -c '^Rien copié')|$rc" "1|0"
hm mig-o - - o; printf '# Profil ancien\n' > "$H/.claude/maitre-agent/profil.md"; mkdir -p "$H/.claude/maitre-agent/sous"; echo ancien > "$H/.claude/maitre-agent/sous/a.txt"
out=$(HOME="$H" sh "$ROOT/tools/migrer.sh"); rc=$?
check "v1.5 migrer.sh (depuis maitre-agent, à défaut de majordome) : copié, ancien dossier gardé" "$([ -f "$H/.claude/diapason/sous/a.txt" ] && [ -f "$H/.claude/maitre-agent/sous/a.txt" ] && echo ok)|$(printf '%s' "$out" | grep -c 'Données copiées de ~/.claude/maitre-agent')|$rc" "ok|1|0"
hm mig-mo - m o; printf '# Profil majordome\n' > "$H/.claude/majordome/profil.md"; printf '# Profil maitre-agent\n' > "$H/.claude/maitre-agent/profil.md"
HOME="$H" sh "$ROOT/tools/migrer.sh" >/dev/null
check "v1.5 migrer.sh : les deux sources présentes -> majordome (plus récent) est la source" "$(cat "$H/.claude/diapason/profil.md")" "# Profil majordome"
hm mig2 d m -; printf '# Ancien\n' > "$H/.claude/majordome/profil.md"; echo ancien > "$H/.claude/majordome/x.txt"; echo nouveau > "$H/.claude/diapason/x.txt"
HOME="$H" sh "$ROOT/tools/migrer.sh" >/dev/null
check "v1.5 migrer.sh : un fichier déjà présent dans le nouveau dossier n'est pas écrasé" "$(cat "$H/.claude/diapason/x.txt")|$([ -f "$H/.claude/diapason/profil.md" ] && echo copie)" "nouveau|copie"
hm mig3 d m o; printf '# Ancien\n' > "$H/.claude/majordome/profil.md"; printf '# Nouveau\n' > "$H/.claude/diapason/profil.md"; echo ancien > "$H/.claude/majordome/y.txt"
out=$(HOME="$H" sh "$ROOT/tools/migrer.sh"); rc=$?
check "v1.5 migrer.sh : un profil déjà présent dans diapason -> refus, rien copié ni écrasé, sortie 0" "$(printf '%s' "$out" | grep -c '^Rien copié')|$rc|$(cat "$H/.claude/diapason/profil.md")|$([ -e "$H/.claude/diapason/y.txt" ] && echo copie || echo rien)" "1|0|# Nouveau|rien"
hm mig4 - - -
out=$(HOME="$H" sh "$ROOT/tools/migrer.sh"); rc=$?
check "v1.5 migrer.sh : rien à migrer -> silence, sortie 0, rien créé" "$out|$rc|$([ -e "$H/.claude/diapason" ] && echo cree || echo rien)" "|0|rien"
hm mig5 - m -; printf '# Profil\n' > "$H/.claude/majordome/profil.md"; : > "$H/.claude/diapason"
out=$(HOME="$H" sh "$ROOT/tools/migrer.sh" 2>&1); rc=$?
check "v1.5 migrer.sh : échec (destination impossible à créer) -> sortie non nulle et message, ancien dossier intact" "$([ "$rc" -ne 0 ] && echo non-nul)|$(printf '%s' "$out" | grep -c 'Échec')|$([ -f "$H/.claude/majordome/profil.md" ] && echo intact)" "non-nul|1|intact"
cmp -s "$ROOT/tools/migrer.sh" "$ROOT/skills/diapason/hooks/migrer.sh" && r=identiques || r=differentes
check "v1.5 migrer.sh : la copie du skill et la source sont identiques" "$r" identiques

echo "RÉSULTAT : $n vérifications, $bad échec(s)"
[ "$bad" -eq 0 ]
