#!/bin/sh
# Tests des hooks et scripts (hooks/*.sh, tools/quota.sh) avec des JSON factices.
# HOME factice (dossier temporaire supprimé à la fin), MAITRE_AGENT_DRY_RUN=1 : aucune notification
# réelle, rien n'est écrit dans le vrai ~/.claude. Aucun appel réseau.
# Usage : sh tests/hooks.sh          Sortie 0 si tout passe, 1 sinon. Demande jq (sinon : test sauté, sortie 0).
# Couvre : C5 (séquences d'échappement), C7 (jalon), C8 (texte qui commence par « - », **), C10 (alerte
# unique en parallèle, purge), C13 (HANDOFF = donnée), M1 (notification « bloqué » off par défaut), quota.sh.
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

echo "RÉSULTAT : $n vérifications, $bad échec(s)"
[ "$bad" -eq 0 ]
