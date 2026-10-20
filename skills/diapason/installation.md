# Installation: three routes, then optional settings

Only with the user's explicit approval: this is persistent configuration. Read the existing files first and merge, never overwrite.

## 0. Choose a route
| Route | What you get | What it does not do |
|---|---|---|
| A. Plugin (GitHub marketplace) | skill (launched only by `/diapason`), 5 `ma-*` agents, agent counter, agent-end notifications, re-injection after a summary, "validated sheet" safeguard (§6); updates by version | no status bar and no `permissions.ask` (see §4 and §2) |
| B. Skill copy | the skill alone in `~/.claude/skills/`; everything else by hand (§1 to §5) | nothing automatic |
| C. Release zip | `diapason-skill-v<version>.zip` (skill alone, like B) or `diapason-plugin-v<version>.zip` (full plugin) | same as A or B depending on the zip |

### Route A: plugin
- In a session: `/plugin marketplace add MalikMoussaoui/diapason`, then `/plugin install diapason@diapason`. In one go: `/plugin install diapason --marketplace MalikMoussaoui/diapason` (Claude Code 2.1.275 or later).
- In a shell: `claude plugin marketplace add MalikMoussaoui/diapason`, then `claude plugin install diapason@diapason`. To pin a version: `MalikMoussaoui/diapason#v1.1.0`.
- Desktop app: + > Plugins > Add plugin, on the marketplaces already configured. How to add a GitHub source there is not documented (non vérifié); fallback, in `~/.claude/settings.json`, `"extraKnownMarketplaces": { "diapason": { "source": { "source": "github", "repo": "MalikMoussaoui/diapason" } } }`.
- No plugins in cloud sessions.
- The plugin's hooks are active as soon as it loads, in all sessions (see §3 to avoid a duplicate, §5 for notifications). Prerequisites of the hooks and scripts: macOS or Linux, and `jq`.

### Route B: skill copy
- From a copy of the repo: `cp -R skills/diapason ~/.claude/skills/` (folder `~/.claude/skills/diapason/` with `SKILL.md` inside). New session afterwards.

### Route C: release zip
- The repo's releases page. Skill alone: `unzip diapason-skill-v<version>.zip -d ~/.claude/skills/` (the zip contains the `diapason/` folder). Full plugin (files at the zip root): `unzip diapason-plugin-v<version>.zip -d diapason-plugin`, then `claude --plugin-dir diapason-plugin` to try it, or give the zip URL to `--plugin-url` (expected zip layout: non vérifié).

### Command name
- Via the plugin: `/diapason:diapason`. The short name `/diapason` also works as long as no other skill takes it.
- Via the skill copy (routes B and C): `/diapason`.
- A personal skill and a plugin skill of the same name both load: do not install the skill by both routes.

## 1. Sub-agents (`SKILL_DIR/agents/` → `~/.claude/agents/`), routes B and C only
- `ma-chercheur` (middle), `ma-auditeur` (middle, read-only except its file), `ma-testeur` (middle), `ma-concepteur` (most capable), `ma-executant` (inherits the requested model).
- In common: no Agent tool (no nested sub-agents), a turn ceiling, and the stable rules of `briefs/_entete.md` in the body.
- Copy them into `~/.claude/agents/`. If a file of the same name already exists, compare it and ask before replacing it.
- They are available in new sessions. With the plugin, they are called `diapason:ma-chercheur`, etc., and are already supplied: do not copy them as well.
- A plugin agent ignores `permissionMode` and `hooks` (official doc): these agents have none.

## 2. Ask before risky commands (`~/.claude/settings.json`, `permissions.ask`)
`Bash(git push *)`, `Bash(gh repo create *)`, `Bash(gh pr create *)`, `Bash(gh release create *)`, `Bash(npm publish *)`, `Bash(rm -rf *)`, `Bash(sudo *)`, `Bash(brew install *)`, `Bash(brew uninstall *)`, `Bash(kill *)`, `Bash(pkill *)`, `Bash(killall *)`.
Adapt the list to the OS (e.g. `winget install`, `apt install`). These rules also apply to sub-agents.
A plugin cannot install `permissions`: it is always a manual copy, even with route A. Show the diff before writing.

## 3. Resume reminder (hook `SessionStart`, matcher `compact|resume`)
- Copy `SKILL_DIR/hooks/reinject.sh` into `~/.claude/diapason/hooks/` and make it executable. Hook command: `~/.claude/diapason/hooks/reinject.sh 2>/dev/null || true`, timeout 10.
- After an automatic summary or a resume, the script re-injects the "Agents lancés" and "Reprise immédiate" sections of `docs/HANDOFF.md`. Without HANDOFF, it does nothing.
- **One place only: in `settings.json` OR in the plugin, not both.** The plugin already brings this hook; if it is also in `settings.json`, it runs twice. With route A, skip this paragraph.
- POSIX script (macOS, Linux, Git Bash); on Windows without bash, write the PowerShell equivalent.

## 4. Status bar (`statusLine`): by hand, even with the plugin
A plugin cannot supply `statusLine` (only `agent` and `subagentStatusLine` are honoured in its `settings.json`).
1. Copy `SKILL_DIR/hooks/statusline.sh` and `SKILL_DIR/hooks/notify.sh` into `~/.claude/diapason/` (created if needed) and make them executable. With the plugin, the skill is already in its cache: `cp ~/.claude/plugins/cache/majordome/majordome/*/hooks/statusline.sh ~/.claude/plugins/cache/majordome/majordome/*/hooks/notify.sh ~/.claude/diapason/` (path **observed on 2.1.299** with the v1.3 names, `.../maitre-agent/maitre-agent/<version>/hooks/`; with the Diapason names it should be `.../diapason/diapason/<version>/hooks/`, non vérifié; undocumented, so check with `ls`). It changes with each version, hence the copy: redo it after an update.
2. Add to `~/.claude/settings.json`, after showing the diff:
```json
"statusLine": {
  "type": "command",
  "command": "~/.claude/diapason/statusline.sh",
  "refreshInterval": 10
}
```
3. It displays: `🛎️ <project> · <milestone> · <n> agents · 5 h <x> % (reset HH:MM) · 7 j <y> %`. Milestone: the `Jalon : …` line of `docs/HANDOFF.md` (like the desktop mod), 40 characters; without that line, nothing. Control characters in the text read are removed. Without quota in the JSON received (unlimited plan, before the first reply): `quota ?`.
4. The same script writes `~/.claude/diapason/usage.json` (never overwritten with an empty one) and sends an alert once per tier and per reset: 5 h window at the `seuils` thresholds (70, 80, 90% by default); weekly window by pace, `seuils-hebdo` gap (20, 40, 60 points) or `plafonds-hebdo` cap (85, 92, 97%), see `reglages.md`. No hook receives the quota: without the status bar, no alert. **The skill reads this file** through `SKILL_DIR/hooks/quota.sh` (SKILL §6: a measure is valid if under 15 min old and the window is not over). This script is in the skill folder, so a skill copy (routes B and C) finds it too; its source is the repo's `tools/quota.sh`. Test: `sh ~/.claude/skills/diapason/hooks/quota.sh; echo $?` (0, or the tier reached; 2 = no usable measure). Weekly figures from a usage tool: `sh ~/.claude/skills/diapason/hooks/quota.sh hebdo <used %> <resetsAt>`.
   Settings (`reglages.md`): these scripts read `seuils`, `notifications` and `barre` themselves in `~/.claude/diapason/profil.md`, then in the "Réglages du projet" section of the current folder's `CLAUDE.md`. Nothing more to install; without these lines, the defaults above.
5. Without the plugin, the agent counter needs the hooks (§5); otherwise it stays at `0 agent`.
6. **Desktop app (Code tab): the status bar is not displayed** (tickets anthropics/claude-code#41456 and #83534; a witness script declared as `statusLine` was not called in a local test on 2026-10-18). Install instead the `diapason-bureau` plugin from the same marketplace: `/plugin install diapason-bureau@diapason` (see the repo's `bureau/` folder). The hooks (§5) also work on the desktop.

## 5. Agent counter and notifications (hooks): only without the plugin
The plugin brings them (`hooks/hooks.json`). Without the plugin, copy `SKILL_DIR/hooks/agent-count.sh` into `~/.claude/diapason/`, make it executable, then merge into `~/.claude/settings.json` (diff shown first):
```json
"hooks": {
  "SubagentStart": [{ "hooks": [{ "type": "command", "command": "~/.claude/diapason/agent-count.sh start || true", "timeout": 5 }] }],
  "SubagentStop": [
    { "hooks": [{ "type": "command", "command": "~/.claude/diapason/agent-count.sh stop || true", "timeout": 5 }] },
    { "matcher": "^ma-", "hooks": [{ "type": "command", "command": "~/.claude/diapason/notify.sh agent || true", "timeout": 10 }] }],
  "Notification": [{ "matcher": "permission_prompt|idle_prompt", "hooks": [{ "type": "command", "command": "~/.claude/diapason/notify.sh blocked || true", "timeout": 10 }] }]
}
```
- The counter counts **all** sub-agents (also the `general-purpose` fallback); only the end notification is limited to `ma-*`.
- Notifications: `osascript` on macOS, `notify-send` on Linux if present, nothing elsewhere. **`ma-*` agent end and quota alerts: on by default. "Claude is waiting" notification (hook `Notification`): off by default**, as it would fire in all sessions; to enable it, create `~/.claude/diapason/notifications-on` (or set `notifications : tout`). To cut everything: create `~/.claude/diapason/notifications-off` (cuts all, always; or set `notifications : rien`; useful on the desktop, where the app already notifies a task's end: possible duplicate). To test without displaying anything: `DIAPASON_DRY_RUN=1`.
- None of these scripts blocks: short timeout, `|| true`, exit 0. They need `jq`.
- The counters live in `~/.claude/diapason/state/` and are purged after 5 h (the quota window), empty folders included.

## 6. "Validated sheet" safeguard (hook `PreToolUse`)
What it does: if `docs/FICHE.md` exists in the project folder **and** carries a "Status: …" line (FR: "Statut : …"; both languages are read), it refuses to write code (`Write`, `Edit`, `MultiEdit`, `NotebookEdit`) and to launch the implementation agent `ma-executant` as long as the status is not "validated" (FR: "validée"). Once the sheet is validated, it still refuses code writing as long as the "Mock-up approved" line (FR: "Maquette validée") says "not yet" (FR: "pas encore") ("no interface" (FR: "sans interface"), a path or a link = allowed). Still open for writing: `docs/`, `maquette/`, `CLAUDE.md`, `.claude/` and any file outside the project. Without a sheet (projects from before v1.3), it does nothing. The refusal message says what to do (finish the workshop, have the sheet or the mock-up approved).
- **With the plugin (route A)**: already wired in `hooks/hooks.json`. Nothing to do.
- **Without the plugin**: copy `SKILL_DIR/hooks/garde-fiche.sh` into `~/.claude/diapason/` (make it executable), then merge into `~/.claude/settings.json` (diff shown first):
```json
"hooks": {
  "PreToolUse": [{ "matcher": "Write|Edit|MultiEdit|NotebookEdit|Agent|Task", "hooks": [{ "type": "command", "command": "~/.claude/diapason/garde-fiche.sh", "timeout": 5 }] }]
}
```
- **No `|| true` at the end of the command**, unlike the other hooks: blocking goes through exit code 2 (official hooks doc, read 2026-10-19: "A hook that blocks by exiting 2 routes the same way as "deny": Claude sees the stderr message as the denial reason"); `|| true` would erase it. One place only: plugin OR `settings.json`, not both.
- It needs `jq`; without `jq`, it lets everything through.
- **Limits, honestly**: (1) writes made through `Bash` (`echo > file`, `sed -i`, a script) are not filtered; (2) it reads the sheet's text, it does not know whether the user really answered "Approve": a model that wrote "validated" itself would get past it (the skill forbids it); (3) symbolic links are not followed; (4) the doc says the hooks of a plugin or of `settings.json` also run for sub-agents' tools, but **I did not verify it in a real session**; (5) agents of another type (`general-purpose`…) are not refused at launch, only their writes; (6) the exact input shape of `MultiEdit` and `NotebookEdit` is not verified at the source.
- To switch it off: remove the `PreToolUse` block from `settings.json`. With the plugin, the doc read does not say how to switch off a single hook (non vérifié): disable the plugin, or use route B.
- Test (fake data): `mkdir -p /tmp/t/docs && printf 'Status: draft\n' > /tmp/t/docs/FICHE.md && echo '{"tool_name":"Write","cwd":"/tmp/t","tool_input":{"file_path":"/tmp/t/src/a.js"}}' | CLAUDE_PROJECT_DIR=/tmp/t sh ~/.claude/diapason/garde-fiche.sh; echo $?` prints the message then `2`.

## 7. Upgrading from v1.3 or v1.4 (the skill was called maitre-agent, then majordome)
- **Command**: `/maitre-agent` (v1.3) and `/majordome` (v1.4) become `/diapason`; no alias skill is shipped. A project whose `CLAUDE.md` says `/maitre-agent` or `/majordome` resumes with `/diapason <project path>`. The agents keep their `ma-*` names.
- **Data folder**: the new one is `~/.claude/diapason/`. Every script uses it if it exists, else `~/.claude/majordome/` (v1.4), else `~/.claude/maitre-agent/` (v1.3), else the new one. At the first `/diapason`, if `~/.claude/diapason/profil.md` is missing and an old profile exists, `hooks/migrer.sh` copies the old folder (`majordome`, else `maitre-agent`) into the new one **without overwriting anything and without deleting anything** (profile, usage, state, notification switches); the `sauvegarde-skill-*` folders are not copied. It refuses to run if `~/.claude/diapason/profil.md` already exists, exits non-zero if a copy fails, and tells the user in one line. Deleting the old folder afterwards is their choice, never done by the skill.
- **`settings.json` is never written by the script.** If a hook there points into the old folder (typically `~/.claude/majordome/hooks/reinject.sh`), `migrer.sh` only prints the proposed lines (`-` old, `+` new): show that diff to the user and edit only after approval.
- **Old copies**: the status bar, `notify.sh` and the other scripts that you copied by hand into the old folder (and named in `settings.json`) keep working but write in the old folder; to switch, copy the new scripts (§3 to §6) into `~/.claude/diapason/` and change the paths in `settings.json` (diff shown first). `/diapason diagnostic` flags an old status-bar path and an old `~/.claude/skills/majordome` or `~/.claude/skills/maitre-agent`.
- **Plugin**: uninstall `majordome@majordome` (or `maitre-agent@maitre-agent`), install `diapason@diapason` (and `diapason-bureau@diapason` on the desktop, replacing `majordome-bureau`). The old repo URLs are expected to redirect after the rename (GitHub behaviour; not verified for Claude Code marketplaces).
- **Environment variables**: `DIAPASON_PROJECT_DIR`, `DIAPASON_DRY_RUN`, `DIAPASON_REINJECT_MAX`, `DIAPASON_PROFIL` replace the `MAJORDOME_*` (v1.4) and `MAITRE_AGENT_*` (v1.3) ones, which are still read.
