#!/bin/sh
# Méthode maître agent : lit, vérifie et écrit les réglages (détail des clés : skills/maitre-agent/reglages.md).
# Les réglages sont des lignes « - clé : valeur » sous « ## Réglages » dans ~/.claude/maitre-agent/profil.md ;
# la rubrique « ## Réglages du projet » du CLAUDE.md du projet (MAITRE_AGENT_PROJECT_DIR, sinon le dossier
# courant) les surcharge pour ce projet. Une valeur absente ou invalide vaut le défaut.
# Usage :
#   reglages.sh                          tableau : clé | valeur en vigueur | défaut | source
#   reglages.sh actifs                   seulement ce qui diffère du défaut (« réglages : défauts » si rien)
#   reglages.sh set [--projet] <clé> <valeur…>   vérifie, écrit la ligne, montre « avant » et « après »
#   reglages.sh preset econome|normal|intensif   écrit le préréglage dans le profil
#   reglages.sh reset                    retire la rubrique « ## Réglages » du profil (retour aux défauts)
# Sortie : 0 fait ; 1 clé ou valeur invalide (rien n'est écrit) ; 2 fichier à modifier absent (rien n'est écrit).
# Écrit seulement le profil (ou le CLAUDE.md avec --projet), jamais ailleurs. Aucun appel réseau.
BASE="$HOME/.claude/maitre-agent"
PROFIL="${MAITRE_AGENT_PROFIL:-$BASE/profil.md}"
PROJ="${MAITRE_AGENT_PROJECT_DIR:-$PWD}"
CMD="$PROJ/CLAUDE.md"
T_PROFIL="Réglages"
T_PROJET="Réglages du projet"
KEYS="seuils budget-lot autonomie modeles agents-paralleles notifications barre git langue ton rapports prereglage"

default_of() {
  case "$1" in
    seuils) echo "70 80 90" ;;
    budget-lot) echo "30 %" ;;
    autonomie) echo "techniques" ;;
    modeles) echo "defaut" ;;
    agents-paralleles) echo "5" ;;
    notifications) echo "agent+quota" ;;
    barre) echo "projet jalon agents quota" ;;
    git) echo "commit-local" ;;
    langue|ton) echo "profil" ;;
    rapports) echo "detaille" ;;
    prereglage) echo "-" ;;
  esac
}
expect_of() {
  case "$1" in
    seuils) echo "3 entiers croissants de 10 à 99, par exemple 70 80 90" ;;
    budget-lot) echo "un pourcentage de 5 à 100, par exemple 30 %" ;;
    autonomie) echo "techniques | tout-demander | tout-sauf-accords" ;;
    modeles) echo "defaut | jamais-opus | opus-conception-seulement" ;;
    agents-paralleles) echo "un entier de 1 à 5" ;;
    notifications) echo "agent+quota | tout | quota | rien" ;;
    barre) echo "des mots parmi projet jalon agents quota cout, sans doublon" ;;
    git) echo "commit-local | aucun | push-branche" ;;
    langue) echo "profil, ou un code de langue (fr, en, es, pt-BR…)" ;;
    ton) echo "profil | tutoiement | vouvoiement | neutre" ;;
    rapports) echo "court | detaille" ;;
    prereglage) echo "econome | normal | intensif | personnalise" ;;
  esac
}
is_int() { case "$1" in ""|*[!0-9]*) return 1 ;; esac; return 0; }
# norm <clé> <valeur…> : écrit la valeur normalisée, sort avec 1 si elle est invalide
norm() {
  _k="$1"; shift
  case "$_k" in
    seuils)
      set -f; set -- $(printf '%s' "$*" | tr ',/' '  '); set +f
      [ "$#" -eq 3 ] || return 1
      for _x in "$1" "$2" "$3"; do is_int "$_x" || return 1; done
      [ "$1" -ge 10 ] && [ "$1" -lt "$2" ] && [ "$2" -lt "$3" ] && [ "$3" -le 99 ] || return 1
      echo "$1 $2 $3" ;;
    budget-lot)
      _n=$(printf '%s' "$*" | tr -d ' %'); is_int "$_n" || return 1
      [ "$_n" -ge 5 ] && [ "$_n" -le 100 ] || return 1
      echo "$_n %" ;;
    agents-paralleles)
      _n=$(printf '%s' "$*" | tr -d ' '); is_int "$_n" || return 1
      [ "$_n" -ge 1 ] && [ "$_n" -le 5 ] || return 1
      echo "$_n" ;;
    barre)
      set -f; set -- $(printf '%s' "$*" | tr ',' ' '); set +f
      _b=" "
      for _w in "$@"; do
        case "$_w" in projet|jalon|agents|quota|cout) ;; *) return 1 ;; esac
        case "$_b" in *" $_w "*) return 1 ;; esac
        _b="$_b$_w "
      done
      [ "$_b" != " " ] || return 1
      echo "$*" ;;
    langue)
      _v=$(printf '%s' "$*" | tr -d ' ')
      printf '%s' "$_v" | grep -Eq '^(profil|[a-z]{2,3}(-[A-Za-z]{2,4})?)$' || return 1
      echo "$_v" ;;
    *)
      _v=$(printf '%s' "$*" | tr -d ' ' | tr 'A-Z' 'a-z')
      case "$_k:$_v" in
        autonomie:techniques|autonomie:tout-demander|autonomie:tout-sauf-accords) echo "$_v" ;;
        modeles:defaut|modeles:jamais-opus|modeles:opus-conception-seulement) echo "$_v" ;;
        modeles:défaut) echo defaut ;;
        notifications:agent+quota|notifications:tout|notifications:quota|notifications:rien) echo "$_v" ;;
        git:commit-local|git:aucun|git:push-branche) echo "$_v" ;;
        ton:profil|ton:tutoiement|ton:vouvoiement|ton:neutre) echo "$_v" ;;
        rapports:court|rapports:detaille) echo "$_v" ;;
        rapports:détaillé|rapports:détaille|rapports:detaillé) echo detaille ;;
        prereglage:econome|prereglage:normal|prereglage:intensif|prereglage:personnalise) echo "$_v" ;;
        prereglage:économe) echo econome ;;
        prereglage:personnalisé) echo personnalise ;;
        *) return 1 ;;
      esac ;;
  esac
}
valid_key() { for _k in $KEYS; do [ "$_k" = "$1" ] && return 0; done; return 1; }

# rg <fichier> <titre> <clé> : valeur brute (sans commentaire entre parenthèses) ; vide si absente
rg() {
  [ -f "$1" ] || return 0
  awk -v t="$2" -v k="$3" '
    /^#+[ \t]/ { if ($0 ~ /^##[ \t]/) { s = $0; sub(/^##[ \t]+/, "", s); sub(/[ \t\r]+$/, "", s); on = (s == t) } else if ($0 ~ /^#[ \t]/) on = 0; next }
    on && /^[ \t]*[-*][ \t]+/ { l = $0; sub(/^[ \t]*[-*][ \t]+/, "", l); i = index(l, ":")
      if (i > 1) { n = substr(l, 1, i - 1); gsub(/[ \t*`]+/, "", n)
        if (tolower(n) == k) { v = substr(l, i + 1); sub(/^[ \t*`]+/, "", v); sub(/[ \t\r*`]+$/, "", v); sub(/[ \t]*\(.*\)$/, "", v); print v; exit } } }' "$1" 2>/dev/null
}
# lignes « - clé : valeur » de la rubrique, telles qu'écrites
section_lines() {
  [ -f "$1" ] || return 0
  awk -v t="$2" '
    /^#+[ \t]/ { if ($0 ~ /^##[ \t]/) { s = $0; sub(/^##[ \t]+/, "", s); sub(/[ \t\r]+$/, "", s); on = (s == t) } else if ($0 ~ /^#[ \t]/) on = 0; next }
    on && /^[ \t]*[-*][ \t]+/ { print }' "$1" 2>/dev/null
}
# valeur en vigueur : écrit « valeur|source » (projet, profil ou défaut)
effective() {
  _raw=$(rg "$CMD" "$T_PROJET" "$1")
  if [ -n "$_raw" ] && _n=$(norm "$1" "$_raw"); then echo "$_n|projet"; return 0; fi
  _raw2=$(rg "$PROFIL" "$T_PROFIL" "$1")
  if [ -n "$_raw2" ] && _n=$(norm "$1" "$_raw2"); then echo "$_n|profil"; return 0; fi
  _d=$(default_of "$1")
  if [ -n "$_raw$_raw2" ]; then echo "$_d|défaut (valeur invalide ignorée)"; else echo "$_d|défaut"; fi
}

# put <fichier> <titre> <clé> <ligne> : remplace la ligne de la clé dans la rubrique, ou l'ajoute à sa fin
# (rubrique créée à la fin du fichier si elle manque). Réécrit via un fichier temporaire.
put() {
  _tmp="$1.tmp.$$"
  awk -v t="$2" -v k="$3" -v nl="$4" '
    function release(   i) { for (i = 0; i < nb; i++) print ""; nb = 0 }
    function close_sec() { if (sec) { if (!done) { print nl; done = 1 } release() } sec = 0 }
    BEGIN { sec = 0; done = 0; seen = 0; nb = 0 }
    sec && /^[ \t\r]*$/ { nb++; next }
    /^#+[ \t]/ && ($0 ~ /^##[ \t]/ || $0 ~ /^#[ \t]/) {
      close_sec()
      if ($0 ~ /^##[ \t]/) { s = $0; sub(/^##[ \t]+/, "", s); sub(/[ \t\r]+$/, "", s); if (s == t) { sec = 1; seen = 1 } }
      print; next }
    sec && !done && /^[ \t]*[-*][ \t]+/ {
      l = $0; sub(/^[ \t]*[-*][ \t]+/, "", l); i = index(l, ":")
      if (i > 1) { n = substr(l, 1, i - 1); gsub(/[ \t*`]+/, "", n)
        if (tolower(n) == k) { release(); print nl; done = 1; next } } }
    { if (sec) release(); print }
    END { close_sec(); if (!seen) { print ""; print "## " t; print nl } }' "$1" > "$_tmp" 2>/dev/null
  if [ -s "$_tmp" ]; then cat "$_tmp" > "$1" 2>/dev/null; _rc=$?; else _rc=1; fi
  rm -f "$_tmp"
  return "$_rc"
}
# drop <fichier> <titre> : retire toute la rubrique
drop() {
  _tmp="$1.tmp.$$"
  awk -v t="$2" '
    function release(   i) { for (i = 0; i < nb; i++) print ""; nb = 0 }
    /^#+[ \t]/ { if ($0 ~ /^##[ \t]/) { s = $0; sub(/^##[ \t]+/, "", s); sub(/[ \t\r]+$/, "", s); skip = (s == t) } else if ($0 ~ /^#[ \t]/) skip = 0 }
    /^[ \t\r]*$/ { if (!skip) nb++; next }
    !skip { release(); print }' "$1" > "$_tmp" 2>/dev/null
  if [ -s "$_tmp" ]; then cat "$_tmp" > "$1" 2>/dev/null; _rc=$?; else _rc=1; fi
  rm -f "$_tmp"
  return "$_rc"
}
need_profil() { [ -f "$PROFIL" ] && [ -w "$PROFIL" ] || { echo "profil absent ou illisible ($PROFIL) : crée-le d'abord (première utilisation du skill)"; exit 2; }; }
show_section() { _l=$(section_lines "$1" "$2"); if [ -n "$_l" ]; then printf '%s\n' "$_l" | sed 's/^/  /'; else echo "  (rubrique absente)"; fi; }

cmd="${1:-}"
[ "$#" -gt 0 ] && shift
case "$cmd" in
  ""|show)
    printf '%s\n' "clé | valeur en vigueur | défaut | source"
    for k in $KEYS; do
      e=$(effective "$k"); printf '%s | %s | %s | %s\n' "$k" "${e%%|*}" "$(default_of "$k")" "${e#*|}"
    done ;;
  actifs)
    n=0
    for k in $KEYS; do
      e=$(effective "$k"); v="${e%%|*}"; s="${e#*|}"
      case "$s" in défaut*) continue ;; esac
      [ "$v" = "$(default_of "$k")" ] && continue
      echo "$k : $v ($s)"; n=$((n + 1))
    done
    [ "$n" -gt 0 ] || echo "réglages : défauts" ;;
  set)
    file="$PROFIL"; title="$T_PROFIL"; label="profil"
    if [ "${1:-}" = "--projet" ]; then file="$CMD"; title="$T_PROJET"; label="CLAUDE.md du projet"; shift; fi
    key=$(printf '%s' "${1:-}" | tr 'A-Z' 'a-z'); [ "$#" -gt 0 ] && shift
    valid_key "$key" || { echo "clé inconnue : « $key ». Clés : $KEYS"; exit 1; }
    [ "$#" -gt 0 ] || { echo "valeur manquante pour $key. Attendu : $(expect_of "$key")"; exit 1; }
    val=$(norm "$key" "$*") || { echo "valeur invalide pour $key : « $* ». Attendu : $(expect_of "$key")"; exit 1; }
    [ -f "$file" ] && [ -w "$file" ] || { echo "$label absent ou illisible ($file) : rien écrit"; exit 2; }
    written="$val"
    [ "$key" = git ] && [ "$val" = push-branche ] && written="push-branche (accordé le $(date +%F))"
    before=$(section_lines "$file" "$title" | awk -v k="$key" '{ l = $0; sub(/^[ \t]*[-*][ \t]+/, "", l); i = index(l, ":"); n = substr(l, 1, i - 1); gsub(/[ \t*`]+/, "", n); if (tolower(n) == k) { print; exit } }')
    put "$file" "$title" "$key" "- $key : $written" || { echo "écriture impossible dans $file : rien changé"; exit 2; }
    echo "$label : $file"
    echo "avant : ${before:-(ligne absente)}"
    echo "après : - $key : $written"
    if [ "$label" = profil ]; then
      pv=$(rg "$CMD" "$T_PROJET" "$key")
      [ -n "$pv" ] && echo "attention : le CLAUDE.md de ce projet surcharge $key ($pv) ; ce projet ne verra pas ce changement"
    fi
    exit 0 ;;
  preset)
    p=$(printf '%s' "${1:-}" | tr 'A-Z' 'a-z')
    need_profil
    case "$p" in
      econome|économe) p=econome; lines="seuils|60 75 85
budget-lot|15 %
modeles|jamais-opus
agents-paralleles|1
rapports|court" ;;
      normal) lines="" ;;
      intensif) lines="seuils|80 90 95
budget-lot|40 %
agents-paralleles|5" ;;
      *) echo "préréglage inconnu : « ${1:-} ». Attendu : econome | normal | intensif"; exit 1 ;;
    esac
    echo "avant :"; show_section "$PROFIL" "$T_PROFIL"
    drop "$PROFIL" "$T_PROFIL" || { echo "écriture impossible : rien changé"; exit 2; }
    put "$PROFIL" "$T_PROFIL" prereglage "- prereglage : $p" || { echo "écriture impossible"; exit 2; }
    printf '%s\n' "$lines" | while IFS='|' read -r k v; do
      [ -n "$k" ] && put "$PROFIL" "$T_PROFIL" "$k" "- $k : $v"
    done
    echo "après :"; show_section "$PROFIL" "$T_PROFIL"
    exit 0 ;;
  reset)
    need_profil
    echo "avant :"; show_section "$PROFIL" "$T_PROFIL"
    drop "$PROFIL" "$T_PROFIL" || { echo "écriture impossible : rien changé"; exit 2; }
    echo "après : rubrique « $T_PROFIL » retirée (défauts)"
    exit 0 ;;
  *)
    echo "usage : reglages.sh [actifs | set [--projet] <clé> <valeur> | preset econome|normal|intensif | reset]"
    exit 1 ;;
esac
exit 0
