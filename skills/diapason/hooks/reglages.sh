#!/bin/sh
# Méthode Diapason : lit, vérifie et écrit les réglages (détail des clés : skills/diapason/reglages.md).
# Les réglages sont des lignes « - clé : valeur » sous « ## Réglages » dans ~/.claude/diapason/profil.md ;
# la rubrique « ## Réglages du projet » du CLAUDE.md du projet (DIAPASON_PROJECT_DIR, sinon le dossier
# courant) les surcharge pour ce projet. Une valeur absente ou invalide vaut le défaut.
# Usage :
#   reglages.sh                          tableau : clé | valeur en vigueur | défaut | source
#   reglages.sh actifs                   seulement ce qui diffère du défaut (« réglages : défauts » si rien)
#   reglages.sh set [--projet] <clé> <valeur…>   vérifie, écrit la ligne, montre « avant » et « après »
#   reglages.sh preset econome|normal|intensif   écrit le préréglage dans le profil
#   reglages.sh reset                    retire la rubrique « ## Réglages » du profil (retour aux défauts)
# Sortie : 0 fait ; 1 clé ou valeur invalide (rien n'est écrit) ; 2 fichier à modifier absent (rien n'est écrit).
# Écrit seulement le profil (ou le CLAUDE.md avec --projet), jamais ailleurs. Aucun appel réseau.
# Dossier des données : ~/.claude/diapason s'il existe, sinon l'ancien ~/.claude/majordome (v1.4), sinon ~/.claude/maitre-agent (v1.3 et avant), sinon ~/.claude/diapason
if [ -d "$HOME/.claude/diapason" ]; then BASE="$HOME/.claude/diapason"
elif [ -d "$HOME/.claude/majordome" ]; then BASE="$HOME/.claude/majordome"
elif [ -d "$HOME/.claude/maitre-agent" ]; then BASE="$HOME/.claude/maitre-agent"
else BASE="$HOME/.claude/diapason"; fi
# Anciens noms des variables : MAJORDOME_* (v1.4) et MAITRE_AGENT_* (v1.3) restent lus
DIAPASON_PROJECT_DIR="${DIAPASON_PROJECT_DIR:-${MAJORDOME_PROJECT_DIR:-${MAITRE_AGENT_PROJECT_DIR:-}}}"
PROFIL="${DIAPASON_PROFIL:-${MAJORDOME_PROFIL:-${MAITRE_AGENT_PROFIL:-$BASE/profil.md}}}"
PROJ="${DIAPASON_PROJECT_DIR:-$PWD}"
CMD="$PROJ/CLAUDE.md"
T_PROFIL="Réglages"
T_PROJET="Réglages du projet"
KEYS="seuils seuils-hebdo plafonds-hebdo budget-lot autonomie modeles agents-paralleles notifications barre git langue ton rapports verif-maj prereglage"

default_of() {
  case "$1" in
    seuils) echo "70 80 90" ;;
    seuils-hebdo) echo "20 40 60" ;;
    plafonds-hebdo) echo "85 92 97" ;;
    budget-lot) echo "30 %" ;;
    autonomie) echo "accompagnant" ;;
    modeles) echo "defaut" ;;
    agents-paralleles) echo "5" ;;
    notifications) echo "agent+quota" ;;
    barre) echo "projet jalon agents quota" ;;
    git) echo "commit-local" ;;
    langue|ton) echo "profil" ;;
    rapports) echo "detaille" ;;
    verif-maj) echo "oui" ;;
    prereglage) echo "-" ;;
  esac
}
expect_of() {
  case "$1" in
    seuils) echo "3 entiers croissants de 10 à 99 (fenêtre de 5 h seulement), par exemple 70 80 90" ;;
    seuils-hebdo) echo "3 entiers croissants de 1 à 99 (écarts en points, fenêtre hebdomadaire), par exemple 20 40 60" ;;
    plafonds-hebdo) echo "3 entiers croissants de 1 à 99 (pourcentages absolus, fenêtre hebdomadaire), par exemple 85 92 97" ;;
    budget-lot) echo "un pourcentage de 5 à 100, par exemple 30 %" ;;
    autonomie) echo "accompagnant | techniques | tout-demander | tout-sauf-accords" ;;
    modeles) echo "defaut | jamais-opus | opus-conception-seulement | opus-avec-audits" ;;
    agents-paralleles) echo "un entier de 1 à 5" ;;
    notifications) echo "agent+quota | tout | quota | rien" ;;
    barre) echo "des mots parmi projet jalon agents quota cout, sans doublon" ;;
    git) echo "commit-local | aucun | push-branche" ;;
    langue) echo "profil, ou un code de langue (fr, en, es, pt-BR…)" ;;
    ton) echo "profil | tutoiement | vouvoiement | neutre" ;;
    rapports) echo "court | detaille" ;;
    verif-maj) echo "oui | non" ;;
    prereglage) echo "econome | normal | intensif | personnalise" ;;
  esac
}
# valeur qu'écrit (ou laisse au défaut) un préréglage pour une clé de quota ; vide si la clé n'est pas liée aux préréglages
preset_val() { # $1 préréglage  $2 clé
  case "$2" in seuils|seuils-hebdo|plafonds-hebdo|budget-lot|modeles|agents-paralleles|rapports) ;; *) return 0 ;; esac
  case "$1:$2" in
    econome:seuils) echo "60 75 85" ;;
    econome:seuils-hebdo) echo "15 30 45" ;;
    econome:plafonds-hebdo) echo "80 90 95" ;;
    econome:budget-lot) echo "15 %" ;;
    econome:modeles) echo "opus-conception-seulement" ;;
    econome:agents-paralleles) echo "2" ;;
    econome:rapports) echo "court" ;;
    normal:agents-paralleles) echo "4" ;;
    intensif:seuils) echo "80 90 95" ;;
    intensif:seuils-hebdo) echo "30 50 70" ;;
    intensif:plafonds-hebdo) echo "90 95 98" ;;
    intensif:budget-lot) echo "40 %" ;;
    intensif:modeles) echo "opus-avec-audits" ;;
    intensif:agents-paralleles) echo "5" ;;
    *) default_of "$2" ;;
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
    seuils-hebdo|plafonds-hebdo)
      set -f; set -- $(printf '%s' "$*" | tr ',/' '  '); set +f
      [ "$#" -eq 3 ] || return 1
      for _x in "$1" "$2" "$3"; do is_int "$_x" || return 1; done
      [ "$1" -ge 1 ] && [ "$1" -lt "$2" ] && [ "$2" -lt "$3" ] && [ "$3" -le 99 ] || return 1
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
        autonomie:accompagnant|autonomie:techniques|autonomie:tout-demander|autonomie:tout-sauf-accords) echo "$_v" ;;
        modeles:defaut|modeles:jamais-opus|modeles:opus-conception-seulement|modeles:opus-avec-audits) echo "$_v" ;;
        modeles:défaut) echo defaut ;;
        notifications:agent+quota|notifications:tout|notifications:quota|notifications:rien) echo "$_v" ;;
        git:commit-local|git:aucun|git:push-branche) echo "$_v" ;;
        ton:profil|ton:tutoiement|ton:vouvoiement|ton:neutre) echo "$_v" ;;
        rapports:court|rapports:detaille) echo "$_v" ;;
        verif-maj:oui|verif-maj:non) echo "$_v" ;;
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
    # une clé de quota réglée à la main, différente de celle du préréglage : le préréglage devient « personnalise »
    if [ "$label" = profil ] && [ "$key" != prereglage ]; then
      cur=$(rg "$PROFIL" "$T_PROFIL" prereglage)
      case "$cur" in
        econome|normal|intensif)
          pv=$(preset_val "$cur" "$key")
          if [ -n "$pv" ] && [ "$pv" != "$val" ]; then
            put "$file" "$title" prereglage "- prereglage : personnalise" && echo "prereglage : $cur -> personnalise (les règles propres au préréglage ne s'appliquent plus, seules les clés écrites comptent)"
          fi ;;
      esac
    fi
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
modeles|opus-conception-seulement
agents-paralleles|2
rapports|court
seuils-hebdo|15 30 45
plafonds-hebdo|80 90 95" ;;
      normal) lines="agents-paralleles|4" ;;
      intensif) lines="seuils|80 90 95
budget-lot|40 %
modeles|opus-avec-audits
agents-paralleles|5
seuils-hebdo|30 50 70
plafonds-hebdo|90 95 98" ;;
      *) echo "préréglage inconnu : « ${1:-} ». Attendu : econome | normal | intensif"; exit 1 ;;
    esac
    echo "avant :"; show_section "$PROFIL" "$T_PROFIL"
    # le choix d'autonomie n'est pas un réglage de quota : un préréglage ne l'efface pas
    keep=$(rg "$PROFIL" "$T_PROFIL" autonomie); keep=$(norm autonomie "$keep" 2>/dev/null)
    drop "$PROFIL" "$T_PROFIL" || { echo "écriture impossible : rien changé"; exit 2; }
    put "$PROFIL" "$T_PROFIL" prereglage "- prereglage : $p" || { echo "écriture impossible"; exit 2; }
    printf '%s\n' "$lines" | while IFS='|' read -r k v; do
      [ -n "$k" ] && put "$PROFIL" "$T_PROFIL" "$k" "- $k : $v"
    done
    [ -n "$keep" ] && put "$PROFIL" "$T_PROFIL" autonomie "- autonomie : $keep"
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
