# Sub-commands of `/maitre-agent`

The first word of the argument decides (case and accents ignored). A sub-command launches no agent and creates no project, except `nouveau` and `reprendre`. `statut` and `diagnostic` change nothing; `reglages` changes only the settings. Profile (SKILL §0): `aide` checks only that it exists, `statut` reads only "Projets connus", `reglages`, `diagnostic` and `reprendre` only the language and tone lines. Answer in the profile's language.

| Command | Alias | Effect |
|---|---|---|
| `aide` | `help`, `?` | explains the skill in 15 lines at most |
| `statut` | `status` | 5 lines per known project |
| `reprendre` | `resume` | project choice with buttons, then resume |
| `profil` | `profile` | shows or edits the profile |
| `reglages` | `settings` | settings table (current value / default), or changes one; presets `econome`, `normal`, `intensif`, and `reset` |
| `diagnostic` | `doctor` | 8 read-only checks of the installation, each "OK / KO + command to fix" (one script) |
| `nouveau <idée>` | `new <idée>` | new project with this idea |

## `aide`
Answer in 15 lines at most, in the language of the user's message, without reading any other skill file or the profile (check only that it exists), following this outline:
1. **What it is for** (2 lines): leading a project of any type (code, research, purchase, analysis, writing) with a main session that steers sub-agents, verifies the decisive facts itself and keeps a handoff that can be resumed any time.
2. **How it works** (4 lines): profile read first; it accompanies you (you decide the form and techs by buttons with a recommendation, you approve a sheet then a mock-up before any code, a checkpoint follows each step); tasks given to agents of the right model, verified by the master agent; quota watched, preset according to your plan (Pro, Max), clean stop at 90%; approval before money, installation, publication, sending, account or deletion.
3. **Sub-commands** (7 lines): the table above, one line per command, plus `/maitre-agent <path>` to resume a specific project.
4. **What is installed here** (2 to 3 lines): check and say yes or no for each item: the `ma-*` agents in `~/.claude/agents/` (or supplied by the plugin), the re-injection hook after a summary, the status bar and notifications (`settings.json` or the plugin's `hooks.json`), the profile `~/.claude/maitre-agent/profil.md` (to check everything: `diagnostic`).
5. **To start** (1 line): `/maitre-agent <your idea>`.

## `statut`
1. Read only the profile's "Projets connus" section (`sed` or `grep` from its heading to the next `## `, not the whole file). For each project that has a path, read from its `docs/HANDOFF.md` the "Dernière visite" line, the "État" and "En attente de l'utilisateur" sections, and from "Agents lancés" only the "en cours" and "à reprendre" rows (`grep -E 'en cours|à reprendre'`), not the whole table.
2. If `~/.claude/maitre-agent/usage.json` exists and is under an hour old, add a quota line at the top (5 h and weekly windows, reset time). Otherwise no quota line: `statut` launches no agent, so it does not call the usage tool (SKILL §6).
3. Give, per project, 5 lines at most: name and path; last visit; where it stands; agents still "en cours"; what is expected from the user. A project without HANDOFF or with a missing folder: one line, "no handoff".
4. Change no file.

## `reprendre`
1. List the known projects that have a `docs/HANDOFF.md`, most recent first ("Dernière visite" line, else file date).
2. Ask a button question (SKILL §7): one button per project, 4 at most, the most recent first, marked "(recommended)" (FR: "(recommandé)"). The other projects remain reachable by free answer.
3. Project chosen: move into its folder if the environment allows, then follow `reprise.md`.

## `profil`
Shows the profile, applies the requested change, and launches no project. If it is missing, follow `profil-modele.md`.

## `reglages` (alias `settings`)
Launches no agent. Read `reglages.md` (the key's line only) only if the user asks what a key does. The script `SKILL_DIR/hooks/reglages.sh` does the checking and writing: you compute nothing. Changes go to the profile's `## Réglages` section, with no other approval (that is the command's purpose).
- **No argument**: run `sh SKILL_DIR/hooks/reglages.sh` and show the table (key, current value, default, source), then one line: "`reglages <key> <value>`, `reglages econome|normal|intensif`, `reglages reset`".
- **`reglages <key> <value…>`**: `sh SKILL_DIR/hooks/reglages.sh set <key> <value…>`, then show its "before" line and its "after" line. "for this project": add `--projet` (writes into the current project's `CLAUDE.md`). Code 1: repeat what it expects, writing nothing. Code 2: no profile, see `profil-modele.md`. For `git push-branche`, first ask for approval with buttons: it is a standing permission to push a working branch.
- **`reglages econome|normal|intensif`**: `sh SKILL_DIR/hooks/reglages.sh preset <name>` (replaces the whole section), then show "before" and "after" and, for `econome`, the extra rules (`reglages.md`).
- **`reglages reset`**: `sh SKILL_DIR/hooks/reglages.sh reset` removes the section (back to defaults).
- If the current project's `CLAUDE.md` overrides the key, the script says so: repeat it.

## `diagnostic` (alias `doctor`)
Read-only: no file changed, no agent, no fix made yourself. Run **one** command, `sh SKILL_DIR/hooks/diagnostic.sh` (no network, never writes), which prints 8 lines `number | check | OK / KO / info / non vérifié | command to fix` and "N KO sur 8". The 8 checks: `jq`; status bar; duplicate skill (copy + plugin); duplicate agents; readable quota; notifications; version; profile. Give the user that table in the profile's language, as is: for each KO the exact command, which the user runs or asks you to run; do not redo the checks yourself. "non vérifié" stays "non vérifié" (never OK by default). Desktop app: no status bar and no `usage.json` is normal (info, not KO).

## `nouveau <idée>`
Treat the rest of the argument as an idea: SKILL §1, "idea" case, then `phases.md`. With no idea after the word, ask for it in one sentence.
