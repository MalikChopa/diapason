#!/bin/sh
# Méthode Diapason : sous-commande `diagnostic`. 8 vérifications de l'installation, en lecture seule
# (rien n'est écrit, aucun appel réseau). Sortie : une ligne par vérification
#   <n> | <vérification> | OK / KO / info / non vérifié | <commande pour corriger, si KO>
# puis « N KO sur 8 ». Code de sortie : 0 (même s'il y a des KO : c'est un rapport).
# Le modèle recopie ce tableau dans la langue du profil ; il ne refait aucune des vérifications.
# Dossier des données : ~/.claude/diapason s'il existe, sinon l'ancien ~/.claude/majordome (v1.4), sinon ~/.claude/maitre-agent (v1.3 et avant), sinon ~/.claude/diapason
if [ -d "$HOME/.claude/diapason" ]; then BASE="$HOME/.claude/diapason"
elif [ -d "$HOME/.claude/majordome" ]; then BASE="$HOME/.claude/majordome"
elif [ -d "$HOME/.claude/maitre-agent" ]; then BASE="$HOME/.claude/maitre-agent"
else BASE="$HOME/.claude/diapason"; fi
SELF_DIR=$(cd "$(dirname "$0")" 2>/dev/null && pwd) || SELF_DIR=.
ko=0
row() { # $1 n  $2 vérification  $3 état  $4 correction
  printf '%s | %s | %s | %s\n' "$1" "$2" "$3" "${4:--}"
  [ "$3" = KO ] && ko=$((ko + 1))
}
HAS_JQ=0; command -v jq >/dev/null 2>&1 && HAS_JQ=1

# plugin installé ? (oui / non / inconnu) ; version éventuelle
PLUG=inconnu; PV=""
if command -v claude >/dev/null 2>&1; then
  pl=$(claude plugin list 2>/dev/null | head -n 40)
  if printf '%s' "$pl" | grep -q 'diapason'; then PLUG=oui; PV=$(printf '%s\n' "$pl" | grep -A3 'diapason' | sed -n 's/.*[Vv]ersion:*[[:space:]]*\([0-9][0-9.]*\).*/\1/p' | head -n 1)
  else PLUG=non; fi
fi

# 1. jq
if [ "$HAS_JQ" -eq 1 ]; then row 1 "jq" OK
else row 1 "jq (sans lui : compteur, notifications et barre d'état muets)" KO "macOS : brew install jq ; Debian/Ubuntu : sudo apt install jq"; fi

# 2. barre d'état
S="$HOME/.claude/settings.json"
if [ "$HAS_JQ" -eq 0 ]; then row 2 "barre d'état" "non vérifié" "jq absent"
elif [ -f "$S" ] && jq -e .statusLine "$S" >/dev/null 2>&1; then
  cmd=$(jq -r '.statusLine.command // ""' "$S" 2>/dev/null)
  sc=$(printf '%s' "$cmd" | awk '{print $1}'); case "$sc" in "~"*) sc="$HOME${sc#\~}" ;; esac
  if [ -n "$sc" ] && [ -x "$sc" ]; then
    case "$sc" in
      */.claude/majordome/*|*/.claude/maitre-agent/*) row 2 "barre d'état ($sc) : copie d'un ancien dossier (majordome ou maitre-agent), qui écrit usage.json là-bas" info "cp ~/.claude/skills/diapason/hooks/statusline.sh ~/.claude/diapason/ puis change le chemin du bloc statusLine (installation.md §4)" ;;
      *) row 2 "barre d'état ($sc)" OK ;;
    esac
  else row 2 "barre d'état : le script nommé n'est pas exécutable ou introuvable" KO "chmod +x ~/.claude/diapason/statusline.sh"; fi
else row 2 "barre d'état absente de settings.json (application de bureau : elle n'y est pas affichée, installer diapason-bureau)" info "bloc statusLine de installation.md §4 pour le terminal"; fi

# 3. skill en double (copie + plugin)
if [ -f "$HOME/.claude/skills/diapason/SKILL.md" ]; then
  case "$PLUG" in
    oui) row 3 "skill en double : copie ~/.claude/skills/diapason ET plugin" KO "rm -r ~/.claude/skills/diapason   (ou : claude plugin uninstall diapason)" ;;
    non) row 3 "skill en double" OK ;;
    *) row 3 "skill en double : copie présente, plugin non vérifiable (commande claude absente du PATH)" "non vérifié" ;;
  esac
elif [ -f "$HOME/.claude/skills/majordome/SKILL.md" ]; then
  row 3 "ancien skill majordome encore installé (/majordome, v1.4)" info "installe diapason (installation.md), puis : rm -r ~/.claude/skills/majordome"
elif [ -f "$HOME/.claude/skills/maitre-agent/SKILL.md" ]; then
  row 3 "ancien skill maitre-agent encore installé (/maitre-agent, v1.3 ou avant)" info "installe diapason (installation.md), puis : rm -r ~/.claude/skills/maitre-agent"
else row 3 "skill en double" OK; fi

# 4. agents en double (~/.claude/agents/ma-*.md ET agents du plugin)
set -- "$HOME"/.claude/agents/ma-*.md
if [ -f "$1" ]; then
  case "$PLUG" in
    oui) row 4 "agents en double : ~/.claude/agents/ma-*.md ET agents du plugin" KO "rm ~/.claude/agents/ma-*.md   (si le plugin est gardé)" ;;
    non) row 4 "agents en double" OK ;;
    *) row 4 "agents en double : copies présentes, plugin non vérifiable (commande claude absente du PATH)" "non vérifié" ;;
  esac
else row 4 "agents en double" OK; fi

# 5. quota lisible
Q=""; for c in "$SELF_DIR/quota.sh" "$SELF_DIR/../tools/quota.sh"; do [ -f "$c" ] && { Q="$c"; break; }; done
if [ -z "$Q" ]; then row 5 "quota lisible" "non vérifié" "quota.sh introuvable à côté de ce script"
else
  sh "$Q" >/dev/null 2>&1; qrc=$?
  if [ "$qrc" -ne 2 ]; then row 5 "quota lisible par usage.json (code $qrc)" OK
  elif [ ! -f "$BASE/usage.json" ]; then row 5 "usage.json absent : le quota ne se lit pas par script (application de bureau : normal, il vient de l'outil get_usage ; terminal : barre d'état non installée)" info "terminal : installation.md §4"
  else row 5 "usage.json présent mais de plus de 15 min ou fenêtre terminée : la barre d'état ne tourne plus ?" KO "relancer une session avec la barre d'état : installation.md §4"; fi
fi

# 6. notifications (information)
nset=""; for c in "$SELF_DIR/reglages.sh" "$SELF_DIR/../tools/reglages.sh"; do
  [ -f "$c" ] && { nset=$(sh "$c" actifs 2>/dev/null | grep '^notifications' | head -n 1); break; }
done
if [ -n "$nset" ]; then row 6 "notifications : réglage $nset" info
elif [ -e "$BASE/notifications-off" ]; then row 6 "notifications : toutes coupées (fichier notifications-off)" info
elif [ -e "$BASE/notifications-on" ]; then row 6 "notifications : fin d'agent, alertes de quota et notification « bloqué » (fichier notifications-on)" info
else row 6 "notifications : défaut (fin d'agent et alertes de quota)" info; fi

# 7. version (information ; la dernière version publiée n'est pas vérifiée : pas de réseau)
V=""
if [ -n "$PV" ]; then V="plugin $PV"
else
  for pj in "$SELF_DIR/../../../.claude-plugin/plugin.json" "$SELF_DIR/../.claude-plugin/plugin.json"; do
    [ -f "$pj" ] && [ "$HAS_JQ" -eq 1 ] && { V="skill copié $(jq -r '.version // empty' "$pj" 2>/dev/null)"; break; }
  done
  [ -n "$V" ] || V="inconnue"
fi
row 7 "version : $V (dernière version publiée non vérifiée, pas de réseau)" info "claude plugin update diapason@diapason"

# 8. profil
if [ -f "$BASE/profil.md" ]; then row 8 "profil" OK; else row 8 "profil absent" KO "/diapason profil"; fi

echo "$ko KO sur 8"
exit 0
