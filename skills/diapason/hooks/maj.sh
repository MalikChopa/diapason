#!/bin/sh
# Méthode Diapason : dit s'il existe une version plus récente que celle installée.
# Usage : sh maj.sh [--force | --reprise]
#   (rien)     silencieux, sauf si une version plus récente existe et n'a pas encore été annoncée
#              (une fois par version, rappel au bout de 7 jours)
#   --reprise  pour le hook de reprise : au plus une fois par 24 h
#   --force    ignore le cache (et le réécrit), affiche toujours une ligne d'état (même si le réglage est coupé)
# Une seule annonce, tous modes confondus, par 24 h tant que la version ne change pas (un verrou « maj.cache.lock »,
# créé par mkdir, protège la lecture, l'annonce et l'écriture du cache : 6 lancements simultanés n'annoncent qu'une fois).
# Réseau : au plus une requête par jour, une de plus toutes les 6 h après un échec, vers l'API des releases GitHub du dépôt
# (api.github.com, par identifiant de dépôt), 3 s maximum, https seulement (redirections comprises), réponse bornée à 200 ko,
# sans aucune donnée envoyée (GitHub voit seulement ton adresse IP et le nom « diapason-maj »).
# Cache `maj.cache` ignoré s'il fait plus de 2 ko, si un horodatage n'est pas un nombre, si « prochain » est à plus de 2 jours
# dans le futur ou « annonce_t » dans le futur (horloge qui a reculé) : le contrôle est alors refait et les horodatages remis à zéro.
# Coupé par la ligne « - verif-maj : non » (puces -, * ou +, espaces ou gras, majuscules tolérés ; aussi off, no, false, 0) de la rubrique
# « ## Réglages » du profil, ou par DIAPASON_VERIF_MAJ=non (mêmes valeurs). La rubrique « ## Réglages du projet » du CLAUDE.md du projet
# (DIAPASON_PROJECT_DIR, sinon le dossier courant) a le dernier mot : `non` y coupe, `oui` y rallume même si le profil dit non.
# Écrit seulement son cache `maj.cache` dans le dossier des données. N'installe ni ne télécharge rien.
# Dossier non inscriptible : rien ne peut être mémorisé, donc ni requête ni annonce (sauf avec --force).
# Seul un numéro de version (chiffres et points) vient du réseau : aucun autre texte distant n'est affiché.
# Variable pour les tests : DIAPASON_MAJ_URL (une URL file:// convient). Sortie toujours 0.
mode="${1:-}"
if [ -d "$HOME/.claude/diapason" ]; then BASE="$HOME/.claude/diapason"
elif [ -d "$HOME/.claude/majordome" ]; then BASE="$HOME/.claude/majordome"
elif [ -d "$HOME/.claude/maitre-agent" ]; then BASE="$HOME/.claude/maitre-agent"
else BASE="$HOME/.claude/diapason"; fi
PROFIL="${DIAPASON_PROFIL:-$BASE/profil.md}"
DIAPASON_PROJECT_DIR="${DIAPASON_PROJECT_DIR:-${MAJORDOME_PROJECT_DIR:-${MAITRE_AGENT_PROJECT_DIR:-}}}"
CMD="${DIAPASON_PROJECT_DIR:-$PWD}/CLAUDE.md"
C="$BASE/maj.cache"
SELF=$(cd "$(dirname "$0")" 2>/dev/null && pwd) || exit 0
REPO="https://github.com/MalikChopa/diapason"
# Les releases sont lues par l'identifiant numérique du dépôt, pas par son nom : un changement de nom de compte
# (le compte GitHub a été renommé le 2026-10-25) ne casse pas le contrôle, alors que l'ancienne
# adresse répond par une redirection 301 que curl ne suit pas sans -L.
REPO_API="https://api.github.com/repositories/1424866806/releases/latest"

# rv <fichier> <titre> <clé> <repli> : valeur de « - clé : valeur » (puce -, * ou + facultative, espaces ou gras, casse libre)
# dans la rubrique « ## titre » ; repli=1 : si le fichier n'a pas du tout cette rubrique, la ligne est cherchée partout.
rv() {
  [ -f "$1" ] || return 0
  awk -v t="$2" -v k="$3" -v rep="$4" '
    function val(l,   i, n, v) {
      sub(/^[ \t]*[-*+][ \t]+/, "", l); i = index(l, ":"); if (i < 2) return ""
      n = substr(l, 1, i - 1); gsub(/[ \t*`]+/, "", n); if (tolower(n) != k) return ""
      v = substr(l, i + 1); sub(/^[ \t*`]+/, "", v); sub(/[ \t\r*`]+$/, "", v); sub(/[ \t]*\(.*\)$/, "", v); v = tolower(v)
      return (v == "") ? "?" : v }
    /^#+[ \t]/ { if ($0 ~ /^##[ \t]/) { s = $0; sub(/^##[ \t]+/, "", s); sub(/[ \t\r]+$/, "", s); on = (s == t); if (on) has = 1 } else if ($0 ~ /^#[ \t]/) on = 0; next }
    { v = val($0); if (v == "") next
      if (on && sec == "") sec = v
      if (any == "") any = v }
    END { if (sec != "") print sec; else if (rep == 1 && !has && any != "") print any }' "$1" 2>/dev/null
}
is_off() { case "$1" in non|no|off|false|0) return 0 ;; esac; return 1; }
is_on() { case "$1" in oui|yes|on|true|1) return 0 ;; esac; return 1; }

if [ "$mode" != --force ]; then
  ev=$(printf '%s' "${DIAPASON_VERIF_MAJ:-}" | tr 'A-Z' 'a-z' | tr -d ' \t\r')
  is_off "$ev" && exit 0
  pv=$(rv "$CMD" "Réglages du projet" verif-maj 0)
  if is_off "$pv"; then exit 0
  elif ! is_on "$pv"; then
    gv=$(rv "$PROFIL" "Réglages" verif-maj 1)
    is_off "$gv" && exit 0
  fi
fi

isver() { printf '%s' "$1" | grep -Eq '^[0-9]{1,4}\.[0-9]{1,4}\.[0-9]{1,4}$'; }
# num : entier de 12 chiffres au plus (sinon 0)
num() { case "$1" in ''|*[!0-9]*) echo 0 ;; *) [ "${#1}" -le 12 ] && echo "$1" || echo 0 ;; esac; }
newer() { # vrai si $1 > $2 (x.y.z)
  a1=${1%%.*}; r=${1#*.}; a2=${r%%.*}; a3=${r#*.}
  b1=${2%%.*}; r=${2#*.}; b2=${r%%.*}; b3=${r#*.}
  [ "$a1" -gt "$b1" ] && return 0; [ "$a1" -lt "$b1" ] && return 1
  [ "$a2" -gt "$b2" ] && return 0; [ "$a2" -lt "$b2" ] && return 1
  [ "$a3" -gt "$b3" ]
}

# version installée : fichier VERSION du skill (le zip « skill seul » n'a pas de plugin.json)
cur=""
[ -f "$SELF/../VERSION" ] && cur=$(head -n 1 "$SELF/../VERSION" | tr -d ' \r')
isver "$cur" || cur=""
if [ -z "$cur" ]; then
  [ "$mode" = --force ] && echo "diapason : version installée inconnue (fichier VERSION absent du skill)"
  exit 0
fi

# --- verrou (mkdir) autour de « lire le cache, décider, annoncer, écrire le cache » -------------------------------
LOCK=""
lock_release() { [ -n "$LOCK" ] && rm -rf "$LOCK" 2>/dev/null; LOCK=""; }
# lock_steal <dossier> : retire un verrou jugé abandonné. Un seul « voleur » à la fois (verrou « .steal » par mkdir) et il RELIT
# l'âge du verrou une fois seul : un verrou neuf pris entre-temps par un autre n'est jamais emporté
lock_steal() {
  [ -n "$(find "$1.steal" -prune -mmin +1 2>/dev/null)" ] && rm -rf "$1.steal" 2>/dev/null
  mkdir "$1.steal" 2>/dev/null || return 0
  _ts=$(cat "$1/t" 2>/dev/null); case "$_ts" in ""|*[!0-9]*) _ts="" ;; esac
  _nw=$(date +%s)
  if [ -n "$_ts" ]; then
    { [ $((_nw - _ts)) -gt 30 ] || [ $((_ts - _nw)) -gt 5 ]; } && rm -rf "$1" 2>/dev/null
  else
    [ -n "$(find "$1" -prune -mmin +1 2>/dev/null)" ] && rm -rf "$1" 2>/dev/null
  fi
  rm -rf "$1.steal" 2>/dev/null
  return 0
}
# lock_take : 0 pris ; 1 occupé (après 5 s) ; 2 dossier non inscriptible. Un verrou de plus de 30 s est jugé abandonné.
lock_take() {
  _l="$C.lock"; _t0=$(date +%s)
  mkdir -p "$BASE" 2>/dev/null
  while ! mkdir "$_l" 2>/dev/null; do
    [ -d "$_l" ] || return 2
    _ts=$(cat "$_l/t" 2>/dev/null)
    case "$_ts" in ""|*[!0-9]*) _ts="" ;; esac
    _nw=$(date +%s)
    if [ -n "$_ts" ]; then { [ $((_nw - _ts)) -gt 30 ] || [ $((_ts - _nw)) -gt 5 ]; } && { lock_steal "$_l"; continue; }
    else [ -n "$(find "$_l" -prune -mmin +1 2>/dev/null)" ] && { lock_steal "$_l"; continue; }
    fi
    [ $((_nw - _t0)) -ge 5 ] && return 1
    sleep 0.05 2>/dev/null || sleep 1
  done
  { date +%s > "$_l/t"; } 2>/dev/null
  LOCK="$_l"
  return 0
}
trap lock_release EXIT
trap 'lock_release; exit 0' HUP INT TERM
lock_take; lrc=$?
if [ "$lrc" -ne 0 ] && [ "$mode" != --force ]; then exit 0; fi   # occupé ou non inscriptible : pas de requête, pas d'annonce

# --- cache : lu sous le verrou ; ignoré s'il est trop gros, illisible ou d'une horloge qui a reculé ------------------
now=$(date +%s)
last=""; next=0; ann_v=""; ann_t=0
get() { sed -n "s/^$1=//p" "$C" 2>/dev/null | head -n 1; }
if [ -f "$C" ]; then
  sz=$(wc -c < "$C" 2>/dev/null | tr -d ' \t')
  case "$sz" in ''|*[!0-9]*) sz=999999 ;; esac
  if [ "$sz" -le 2048 ]; then
    r_next=$(get prochain); r_ann=$(get annonce_t); ok=1
    for x in "$r_next" "$r_ann"; do
      case "$x" in "") ;; *[!0-9]*) ok=0 ;; *) [ "${#x}" -le 12 ] || ok=0 ;; esac
    done
    if [ "$ok" -eq 1 ]; then
      next=$(num "$r_next"); ann_t=$(num "$r_ann")
      # horloge qui a reculé : « prochain » à plus de 2 jours ou une annonce dans le futur
      if [ "$next" -gt $((now + 172800)) ] || [ "$ann_t" -gt "$now" ]; then next=0; ann_t=0
      else last=$(get derniere); isver "$last" || last=""; ann_v=$(get annonce_v); isver "$ann_v" || ann_v=""; fi
    fi
  fi
fi
save() {
  [ "$lrc" -eq 0 ] || return 0
  mkdir -p "$BASE" 2>/dev/null || return 0
  { { echo "derniere=$last"; echo "prochain=$next"; echo "annonce_v=$ann_v"; echo "annonce_t=$ann_t"; } > "$C.tmp.$$"; } 2>/dev/null \
    && mv "$C.tmp.$$" "$C" 2>/dev/null || rm -f "$C.tmp.$$" 2>/dev/null
}

if [ "$mode" = --force ] || [ "$now" -ge "$next" ]; then
  tag=""
  if command -v curl >/dev/null 2>&1; then
    if [ -n "${DIAPASON_MAJ_URL:-}" ]; then
      body=$(curl -fsSL -m 3 -A diapason-maj -H 'Accept: application/vnd.github+json' "$DIAPASON_MAJ_URL" 2>/dev/null) || body=""
    else
      body=$(curl -fsSL -m 3 --proto '=https' --proto-redir '=https' --max-filesize 200000 -A diapason-maj -H 'Accept: application/vnd.github+json' "$REPO_API" 2>/dev/null) || body=""
    fi
    # le PREMIER « tag_name », en début de ligne (JSON mis en forme, ou objet sur une ligne)
    tag=$(printf '%s\n' "$body" | sed -n '/^[[:space:]{]*"tag_name"/{p;q;}' \
      | sed -n 's/^[[:space:]{]*"tag_name"[[:space:]]*:[[:space:]]*"v\{0,1\}\([0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*\)".*/\1/p')
  fi
  if isver "$tag"; then last="$tag"; next=$((now + 86400)); else next=$((now + 21600)); fi
  save
fi

if [ -z "$last" ]; then
  [ "$mode" = --force ] && echo "diapason $cur : dernière version publiée inconnue (pas de réseau, ou limite de l'API GitHub atteinte)"
  exit 0
fi
if ! newer "$last" "$cur"; then
  [ "$mode" = --force ] && echo "diapason $cur : à jour (dernière version publiée : $last)"
  exit 0
fi

# une seule annonce par 24 h, tous modes confondus, tant que la version annoncée ne change pas
case "$mode" in
  --reprise) if [ "$ann_v" = "$last" ] && [ $((now - ann_t)) -lt 86400 ]; then exit 0; fi; ann_v=$last; ann_t=$now ;;
  --force) ;;
  *) if [ "$ann_v" = "$last" ] && [ $((now - ann_t)) -lt 604800 ]; then exit 0; fi; ann_v=$last; ann_t=$now ;;
esac
[ "$mode" = --force ] || save

case "$SELF" in
  */plugins/cache/*|*/plugins/marketplaces/*) how="plugin : claude plugin update diapason@diapason" ;;
  *) how="copie du skill : télécharger diapason-skill-v$last.zip sur $REPO/releases/latest puis le dézipper dans ~/.claude/skills/ (installation.md §1 et §6 si les agents ou le garde-fou changent)" ;;
esac
echo "[diapason] Version $last disponible (installée : $cur). Mise à jour, $how. Changements : $REPO/blob/main/CHANGELOG.md"
exit 0
