# Settings (Réglages)

**Single reading rule**, always by section or line (`grep -n '^## '` then `sed`, or `grep` on the key's name), never the whole file: (1) at start or resume, when `sh SKILL_DIR/hooks/reglages.sh actifs` (run in the project folder, or with `DIAPASON_PROJECT_DIR=<folder>` while the project is not the current folder) prints something other than "réglages : défauts": only the lines of the active keys in "The keys", plus "What each preset sets" if `prereglage` is active; (2) to choose the plan's preset: only "Plan and preset"; (3) sub-command `reglages` (`commandes.md`): only the line of a key the user asks about. Whoever sets nothing never reads this file; neither does a Small without agent, nor you right after writing a preset yourself.

## Where and how
- Profile: section `## Réglages` of `~/.claude/diapason/profil.md`, one line `- <key> : <value>` per setting. A trailing comment in parentheses is ignored.
- Project: section `## Réglages du projet` of the project's `CLAUDE.md`, same format. It **overrides the profile** for this project, key by key. Read it on resume (`reprise.md`) and at start (`phases.md`): that is what `reglages.sh actifs` does.
- Missing, unreadable or invalid (unknown key, value outside the list): the value below it (profile, then default). Nothing changes for whoever sets nothing.
- **The scripts do the work, not you**: `hooks/reglages.sh` (in `SKILL_DIR`) checks, writes and displays; the status bar, `quota.sh` and `notify.sh` read `seuils`, `seuils-hebdo`, `plafonds-hebdo`, `notifications` and `barre` themselves; the desktop mod reads `seuils` and `notifications`. You apply the other keys from the table.
- Read: `sh SKILL_DIR/hooks/reglages.sh` (table key, value in force, default, source). Write: `sh SKILL_DIR/hooks/reglages.sh set [--projet] <key> <value>`, `preset econome|normal|intensif`, `reset`. It shows "before" and "after". No profile (code 2): create it first (`profil-modele.md`).

## The keys
| Key | Values | Default | Effect |
|---|---|---|---|
| `seuils` | 3 increasing integers, 10 to 99 | `70 80 90` | **5 h window only.** 1st threshold: no more agents of the most capable model; 2nd: propose the batch and wait for a yes (SKILL §6); 3rd: clean stop. Also the alerts of the status bar and the mod, and the tier of `quota.sh` for that window |
| `seuils-hebdo` | 3 increasing integers, 1 to 99 | `20 40 60` | **weekly window**: gaps in points (used % − elapsed % of the week) that give tiers 1, 2, 3 (same effects as the 3 thresholds above) |
| `plafonds-hebdo` | 3 increasing integers, 1 to 99 | `85 92 97` | **weekly window**: absolute percentages that give tiers 1, 2, 3. Weekly tier = the higher of the gap tier and the ceiling tier; tier 3 also at ≥ 90% with a projection ≥ 300%. Under 12 h from the reset, under 10% of the week elapsed, or reset unknown: ceilings only (computed by `quota.sh`, `quota.sh hebdo` and the status bar alerts) |
| `budget-lot` | 5 to 100% | `30 %` | batch size (share of the 5 h window) above which you ask for approval (SKILL §3, §7). No quota measure: more than 3 agents, or more than `agents-paralleles` if it is smaller |
| `autonomie` | `accompagnant`, `techniques`, `tout-demander`, `tout-sauf-accords` | `accompagnant` | covers only **execution decisions** (SKILL §2); product decisions always stay the user's. `accompagnant`: you decide the execution, note "délégué" and explain it in one line at the checkpoint (choice, why, alternative); ask only if the choice changes cost, deadline or usage. `techniques` (former default, still valid): you decide and note, without explaining. `tout-demander`: button question before every execution choice too. `tout-sauf-accords`: you decide all execution without announcing it; the workshop is condensed (tours 1 and 2 grouped, sheet pre-filled with your recommendations) but the sheet still has to be validated. No value covers the approvals of §5 |
| `modeles` | `defaut`, `jamais-opus`, `opus-conception-seulement`, `opus-avec-audits` | `defaut` (light / middle / most capable, SKILL §3) | `jamais-opus`: never the most capable model, design moves to the middle one. `opus-conception-seulement`: the most capable for design, architecture and specification only; code and the rest at the middle model at most. `defaut`: plus the product core. `opus-avec-audits`: plus the audits. Say so once |
| `agents-paralleles` | 1 to 5 | `5` | agents at the same time. `1`: everything in sequence. The presets write 2 / 4 / 5. The "Forfait et préréglage" rule of `phases.md` stays a ceiling as long as this setting is not written |
| `notifications` | `agent+quota`, `tout`, `quota`, `rien` | `agent+quota` | `tout`: plus "Claude is waiting". `quota`: quota alerts only. `rien`: none. Without this setting, the files `notifications-on` / `notifications-off` (folder `~/.claude/diapason/`) decide as before; `notifications-off` cuts everything, always |
| `barre` | words among `projet` `jalon` `agents` `quota` `cout`, in the wanted order | `projet jalon agents quota` | elements of the **terminal** status bar. `cout` adds "cost 0.42 $" if the bar's JSON gives `cost.total_cost_usd`, otherwise nothing. The desktop app does not call the status bar: the mod keeps its fixed line |
| `git` | `commit-local`, `aucun`, `push-branche` | `commit-local` | `commit-local`: `git init` and a commit per verified step, no push. `aucun`: no git. `push-branche`: you may push a working branch to an **already existing** remote repo, never the main branch nor `--force`, without asking again. It is a standing approval: ask for it with buttons, the command writes the date. Creating a repo, publishing a release: always ask |
| `langue` | `profil` or a code (`fr`, `en`, `pt-BR`…) | `profil` | language of everything you write |
| `ton` | `profil`, `tutoiement`, `vouvoiement`, `neutre` | `profil` | how to address the user |
| `rapports` | `court`, `detaille` | `detaille` | `court`: agent report of 5 lines at most (write it in the brief in place of "10 lines"), your reports and decision answers of 8 lines at most. `detaille`: the skill's rules (10 lines, 15 for a decision) |
| `prereglage` | `econome`, `normal`, `intensif`, `personnalise` | none | written by `reglages.sh preset`; a starting point, a key written beside it overrides it. When a key is set by hand to a value different from the preset's, the script writes `personnalise`: the preset's extra rules (below) then stop applying, only the written keys count. Each preset also adds rules (below). The v1.3 spec calls the middle preset "standard": its name stays `normal` |

## Presets
| Preset | Written by `reglages.sh preset` |
|---|---|
| `econome` | `seuils 60 75 85`, `seuils-hebdo 15 30 45`, `plafonds-hebdo 80 90 95`, `budget-lot 15 %`, `modeles opus-conception-seulement`, `agents-paralleles 2`, `rapports court` |
| `normal` | `agents-paralleles 4`, the rest at defaults (weekly: `20 40 60` / `85 92 97`) |
| `intensif` | `seuils 80 90 95`, `seuils-hebdo 30 50 70`, `plafonds-hebdo 90 95 98`, `budget-lot 40 %`, `modeles opus-avec-audits`, `agents-paralleles 5` |

A preset replaces the section but **keeps the `autonomie` line** (it is not a quota setting). After a preset, `reglages.sh set autonomie <value>` fixes the choice of the profile's question no. 1.

## What each preset sets
The keys above are read by the scripts. The rest of the table is applied by you, from the `prereglage` line (v1.3 design setting, **non mesuré** in use).

| | `econome` (Pro) | `normal` (Max 5x) | `intensif` (Max 20x, API) |
|---|---|---|---|
| Parallel agents | 1 or 2 (2 only for two independent, short tasks) | 3 or 4 | 5 |
| Most capable model | design, architecture, specification only | + the product core | + the audits |
| Research | a single one grouping the decisive questions, 2 at most (Medium); no research if the workshop suffices | 4 at most (Medium) | "Size" table of `phases.md` |
| Audit | 1 round | 2 rounds | 2 rounds, with two independent auditors for what is published |
| Mock-up variants | 1 | 1 to 2 | 2 to 3 |
| Tester | at the last milestone only, even for a Large; at the other milestones you test | rule of `phases.md` (Tests) | rule of `phases.md` (Tests) |

Rules of `econome`, in addition:
- **short briefs**: after the header, the mission in 15 lines at most; paths, not content; strictly useful profile lines;
- **short reports** (key `rapports`);
- no comfort research, "Inspiration" phase skipped unless asked;
- earlier alerts (60 / 75 / 85% for 5 h; weekly gaps 15 / 30 / 45 points, ceilings 80 / 90 / 95%) and approval asked from 15% of the window per batch;
- checkpoints stay complete (they are what prevents coding the wrong thing, hence paying twice).

**Order of magnitude: non mesuré.** Each agent avoided removes a cost that the skill's benchmarks (SKILL §6, not measured by this version) put at 100 to 500 k tokens; the project's only measure is "3 researches ≈ 36% of a 5 h window" (`phases.md`, a single measure). A project's real count is read in the end-of-project recap (`phases.md`, Delivery).

## Plan and preset (Forfait et préréglage)
At first launch, then at each launch where the profile has no `prereglage` line, read the plan from the usage tool (`get_usage`, may be deferred: ToolSearch), field `plan.plan`:

| What `plan.plan` returns | Preset offered |
|---|---|
| `Pro` (observed 2026-10-19) | `econome` |
| contains `Max` **and** `20` | `intensif` |
| contains `Max`, without `20` | `normal` |
| `status: not_applicable` (API key) | `intensif` |
| other value, missing field or no usage tool | ask once, with buttons (Pro / Max 5x / Max 20x / API) |

The Max values are **not verified** (only "Pro" was seen): the table recognises whatever contains "Max", and a surprising value is asked, not guessed. Offer the preset with buttons (your lean first, the others as alternatives), **confirmed once**, write it with `reglages.sh preset`, then note the plan in the profile's "Forfait / quota" line. If a `prereglage` is already written, do not ask again: propose a change only if `plan.plan` no longer matches the profile's "Forfait" line.

## Next time (Pour la prochaine fois)
In the end-of-project recap, propose **a single** setting: more economical if quota went past the 2nd threshold or if an agent went past 40% of the window; wider (`intensif`, or a larger `agents-paralleles`) if quota stayed under the 1st threshold and no batch was delayed. Otherwise: "keep your settings".

## Sub-command `reglages`
See `commandes.md`.
