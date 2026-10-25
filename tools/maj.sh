#!/bin/sh
# Méthode Diapason : dit s'il existe une version plus récente que celle installée.
# Usage : sh maj.sh [--force | --reprise]
#   (rien)     silencieux, sauf si une version plus récente existe et n'a pas encore été annoncée
#              (une fois par version, rappel au bout de 7 jours)
#   --reprise  pour le hook de reprise : au plus une fois par 24 h
#   --force    ignore le cache, affiche toujours une ligne d'état (même si le réglage est coupé)
# Réseau : au plus une requête GET par jour vers l'API des releases GitHub du dépôt (api.github.com, par identifiant de dépôt), 3 s
# maximum, sans aucune donnée envoyée. En cas d'échec, silence et nouvel essai 6 h plus tard.
# Coupé par la ligne « - verif-maj : non » de « ## Réglages » du profil, ou par DIAPASON_VERIF_MAJ=non.
# Écrit seulement son cache `maj.cache` dans le dossier des données. N'installe ni ne télécharge rien.
# Seul un numéro de version (chiffres et points) vient du réseau : aucun autre texte distant n'est affiché.
# Variable pour les tests : DIAPASON_MAJ_URL (une URL file:// convient). Sortie toujours 0.
mode="${1:-}"
if [ -d "$HOME/.claude/diapason" ]; then BASE="$HOME/.claude/diapason"
elif [ -d "$HOME/.claude/majordome" ]; then BASE="$HOME/.claude/majordome"
elif [ -d "$HOME/.claude/maitre-agent" ]; then BASE="$HOME/.claude/maitre-agent"
else BASE="$HOME/.claude/diapason"; fi
PROFIL="${DIAPASON_PROFIL:-$BASE/profil.md}"
C="$BASE/maj.cache"
SELF=$(cd "$(dirname "$0")" 2>/dev/null && pwd) || exit 0
REPO="https://github.com/MalikChopa/diapason"
# Les releases sont lues par l'identifiant numérique du dépôt, pas par son nom : un changement de nom de compte
# (le compte GitHub a été renommé le 2026-10-25) ne casse pas le contrôle, alors que l'ancienne
# adresse répond par une redirection 301 que curl ne suit pas sans -L.
REPO_API="https://api.github.com/repositories/1424866806/releases/latest"

if [ "$mode" != --force ]; then
  [ "${DIAPASON_VERIF_MAJ:-}" = non ] && exit 0
  grep -q '^- verif-maj : *non' "$PROFIL" 2>/dev/null && exit 0
fi

isver() { printf '%s' "$1" | grep -Eq '^[0-9]+\.[0-9]+\.[0-9]+$'; }
num() { case "$1" in ''|*[!0-9]*) echo 0 ;; *) echo "$1" ;; esac; }
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

get() { sed -n "s/^$1=//p" "$C" 2>/dev/null | head -n 1; }
now=$(date +%s)
last=$(get derniere); isver "$last" || last=""
next=$(num "$(get prochain)"); ann_v=$(get annonce_v); ann_t=$(num "$(get annonce_t)"); rap_t=$(num "$(get rappel_t)")
save() {
  mkdir -p "$BASE" 2>/dev/null || return 0
  { echo "derniere=$last"; echo "prochain=$next"; echo "annonce_v=$ann_v"; echo "annonce_t=$ann_t"; echo "rappel_t=$rap_t"; } > "$C.tmp.$$" 2>/dev/null \
    && mv "$C.tmp.$$" "$C" 2>/dev/null || rm -f "$C.tmp.$$" 2>/dev/null
}

if [ "$mode" = --force ] || [ "$now" -ge "$next" ]; then
  tag=""
  if command -v curl >/dev/null 2>&1; then
    body=$(curl -fsSL -m 3 -A diapason-maj -H 'Accept: application/vnd.github+json' \
      "${DIAPASON_MAJ_URL:-$REPO_API}" 2>/dev/null) \
      && tag=$(printf '%s\n' "$body" | sed -n 's/.*"tag_name"[[:space:]]*:[[:space:]]*"v\{0,1\}\([0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*\)".*/\1/p' | head -n 1)
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

case "$mode" in
  --reprise) [ $((now - rap_t)) -ge 86400 ] || exit 0; rap_t=$now ;;
  --force) ;;
  *) if [ "$ann_v" = "$last" ] && [ $((now - ann_t)) -lt 604800 ]; then exit 0; fi; ann_v=$last; ann_t=$now ;;
esac
[ "$mode" = --force ] || save

case "$SELF" in
  */plugins/cache/*|*/plugins/marketplaces/*) how="plugin : claude plugin update diapason@diapason" ;;
  *) how="copie du skill : télécharger diapason-skill-v$last.zip sur $REPO/releases/latest puis le dézipper dans ~/.claude/skills/ (installation.md §8 si les agents ou les hooks changent)" ;;
esac
echo "[diapason] Version $last disponible (installée : $cur). Mise à jour, $how. Changements : $REPO/blob/main/CHANGELOG.md"
exit 0
