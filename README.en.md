<div align="center">

# maitre-agent

**One session that drives sub-agents, verifies the facts itself, and leaves a handoff you can resume from at any time.**

English · [Version française](README.md)

[![Latest release](https://img.shields.io/github/v/release/MalikMoussaoui/maitre-agent)](https://github.com/MalikMoussaoui/maitre-agent/releases)
[![MIT license](https://img.shields.io/github/license/MalikMoussaoui/maitre-agent)](LICENSE)
[![Lint](https://img.shields.io/github/actions/workflow/status/MalikMoussaoui/maitre-agent/lint.yml?branch=main&label=lint)](https://github.com/MalikMoussaoui/maitre-agent/actions/workflows/lint.yml)
[![Made with maitre-agent](https://img.shields.io/badge/made%20with-maitre--agent-6f42c1)](#made-with-itself)

</div>

> The skill itself, its prompts, scripts and messages are written in French. This page is a full translation of the French README. Some linked documents (`docs/fabrication.md`, `evals/`, `skills/`) are in French.

## In 3 minutes

**Prerequisites:** macOS or Linux (the scripts are `sh`), [`jq`](https://jqlang.org/) (`brew install jq` or `sudo apt install jq`; without it the counter, notifications and status line stay silent), and Claude Code (CLI 2.1.299 tried).

**1. Install** (one command, route A below):

```sh
claude plugin install maitre-agent --marketplace https://github.com/MalikMoussaoui/maitre-agent
```

This one-command form is the one described by `claude plugin install --help`; it worked with a local path (CLI 2.1.299, throwaway HOME) but was not tried as-is with the GitHub URL. The two-command form was tried successfully from GitHub (same CLI, throwaway HOME, full HTTPS URL): `claude plugin marketplace add https://github.com/MalikMoussaoui/maitre-agent`, then `claude plugin install maitre-agent@maitre-agent`.

**2. Run it**, with an idea (example):

```text
/maitre-agent compare three silent mechanical keyboards under 100 EUR and tell me which one to buy
```

The skill **starts through this command**. Its description tells the model to load it only on an explicit request (see "Command name"). The skill's messages are in French; it answers in the language of your profile.

**3. What it will ask you.** The first time: your profile (autonomy, project folder, language/tone/level, what it must always ask you first), in a single message; answer "défauts" to accept everything. After that: your approval before anything that costs money, installs, publishes, sends, opens an account or deletes; otherwise a single question only if it blocks.

**4. What it costs, in increasing order.** *Small* (a question, a purchase, a small script): 0 to 2 agents, often alone. *Medium*: one design, up to 2 research agents on a Pro plan, milestones one after another. *Large*: several 5-hour windows, announced and to be approved before starting. Measured reference: one research agent is about 209,000 tokens, about 12% of a 5-hour window (a single measurement, Pro plan). The estimated cost is announced before each batch.

## The pitch

`maitre-agent` is a skill for [Claude Code](https://code.claude.com/docs/en/skills). You give it an idea (a script, a purchase to compare, a piece of research, a text) or a project to resume. The main session becomes the "master agent": it reads your profile, splits the work, hands it to sub-agents running the right model, verifies the facts that matter by itself, watches your quota, and writes a handoff file (`HANDOFF.md`).

It is for people who use Claude Code on projects that last longer than one conversation and who want to stay in control: approval is asked before anything that costs money or cannot be undone, and work can resume after a quota cut, in a fresh session, or from another account.

It does not aim for more agents. It aims for the smallest usable result. For a tiny task it works alone.

## The method

```mermaid
flowchart TD
    U(["You: an idea, or a project to resume"]) --> M["Master agent<br/>reads the profile, frames, splits,<br/>delegates with a written brief"]

    M --> A1["ma-chercheur (researcher)<br/>sonnet"]
    M --> A2["ma-concepteur (designer)<br/>opus"]
    M --> A3["ma-executant (implementer)<br/>model chosen by the master"]
    M --> A4["ma-testeur (tester)<br/>sonnet"]
    M --> A5["ma-auditeur (auditor)<br/>sonnet"]

    A1 --> F["Files written by the agents<br/>(the file is the source of truth)"]
    A2 --> F
    A3 --> F
    A4 --> F
    A5 --> F

    F --> V{"Verification by the master<br/>primary source, command, recomputation"}
    V -- "needs fixing<br/>(2 or 3 rounds at most)" --> M
    V -- "verified" --> H["HANDOFF.md<br/>state, agents launched, immediate resume"]
    H --> R["Resume: new session,<br/>other account, other person"]
    R --> M
    H --> U

    Q{{"Quota, the safeguard<br/>70%: no more top-model agent<br/>80%: no new agent<br/>90%: clean stop"}} -.-> M
    Q -.-> H
```

The agents write the big pieces. They never launch other agents. The master agent does the decisive checks itself: "the tests pass" means the output of a command run just now, not an agent's report.

## Features

"Status" column: **used for real** = used while building this repository; **tested** = a trial or automated test, described in the limits; **written** = present and checked by the lint, not yet put to the test.

| Feature | What it does | Status |
|---|---|---|
| Profile | Reads `~/.claude/maitre-agent/profil.md` first (language, level, budget, machine). Creates it in two exchanges at most on first use. Stays on your machine. | used for real (v1.0.0, details not kept) |
| Routing | Idea, project path, file to process, or sub-command: it picks between new project, resume and command. | used for real (v1.0.0, details not kept); sub-command routing: written |
| Proportionality | Aims for the smallest usable result. When unsure between two sizes, it takes the smaller one and says so. | used for real (v1.0.0, details not kept) |
| Delegation by model | Light model for mechanical work, intermediate for research, audit and routine code, most capable for design. The model is always stated explicitly. 5 `ma-*` agents. | used for real |
| Verification | Decisive facts are verified by the master. Required-proof table, audits capped at 2 rounds, code fixes capped at 3 rounds, "3 failures" protocol. | used for real |
| Permissions | Approval asked before money, installs, publishing, sending, accounts, deletion. List of prohibitions (see Safeguards). | written; the `permissions.ask` rules must be installed by hand |
| Quota 70 / 80 / 90% (adjustable) | Default thresholds; setting `seuils`. At 70%, no more top-model agent (design moves to the intermediate model, and it says so); at 80%, it proposes and only launches with your explicit approval, cost announced; at 90%, clean stop. Without a usage tool, it reads the `usage.json` written by the status line, through `hooks/quota.sh` (tier 0, or the threshold reached, or "no measurement"). | stop at 90%: used for real (v1.1.0); `quota.sh`: tested with dummy JSON (`tests/hooks.sh`); the rest: written |
| Handoff | `HANDOFF.md` with [V] verified / [?] not rechecked tags, an "Agents launched" table, an "Immediate resume" section. Files on disk win if HANDOFF is behind. | used for real (one resume after a cut) |
| Sub-commands | `aide` (help), `statut`, `reprendre`, `profil`, `reglages` (or `settings`), `diagnostic` (or `doctor`: 8 read-only checks of the installation), `nouveau`. | written |
| Settings (v1.2) | A `## Réglages` section of the profile (and `## Réglages du projet` in a project's `CLAUDE.md`) sets quota thresholds, batch size, autonomy, models, parallel agents, notifications, status line, git, language, tone, report length. Three presets: `econome` (thrifty), `normal`, `intensif`. See "Settings" below. | script `tools/reglages.sh` and the scripts that read it: tested with dummy JSON (`tests/hooks.sh`); settings applied by the model: written, never seen in a real session |
| Terminal status line | `🧭 <project> · <milestone> · <n> agents · 5 h <x> % (reset HH:MM) · 7 j <y> %`. Also writes the quota to `~/.claude/maitre-agent/usage.json`. | tested with dummy JSON on every push (`tests/hooks.sh`); not seen in a real terminal |
| Desktop mod | The same idea for the Code tab of the Claude desktop app: status line, quota alerts, agent-finished toast. | tested: 38 of 38 tests (including the `seuils` and `notifications` settings); status line and agent-finished toast seen for real (v1.1.x) |
| Notifications | System notification when a `ma-*` agent finishes and at the quota thresholds (70 / 80 / 90% by default), on by default; "Claude is waiting" (permission, idle) **off by default**. The `notifications` setting (`agent+quota`, `tout`, `quota`, `rien`) chooses; without it, the file `~/.claude/maitre-agent/notifications-on` turns "Claude is waiting" on and `notifications-off` turns everything off. macOS and Linux. Quota alerts require the status line (terminal) or the mod (desktop). | macOS command tested for real; scripts tested with dummy JSON (`tests/hooks.sh`); hooks not tested end to end by Claude Code |
| Buttons | Questions go through the environment's question tool (2 to 4 options, the recommended one first, marked "(recommandé)"). Without that tool: a numbered list. | written |
| Chapters | One chapter per phase (framing, research, design, milestones, delivery) if the environment has a chapter tool. Otherwise nothing. | written |
| "Since your last visit" | On every resume, 3 lines: what changed, what is done, what is expected from you. | written |

## Installation

Three routes. Pick **only one**: a skill installed through two routes would load twice.

### Route A: plugin (GitHub marketplace)

In a Claude Code session:

```text
/plugin marketplace add MalikMoussaoui/maitre-agent
/plugin install maitre-agent@maitre-agent
```

For the desktop app (Code tab), also add the mod, which replaces the status line the app does not display:

```text
/plugin install maitre-agent-bureau@maitre-agent
```

From a shell: `claude plugin marketplace add https://github.com/MalikMoussaoui/maitre-agent`, then `claude plugin install maitre-agent@maitre-agent` (form tried successfully from GitHub, CLI 2.1.299, throwaway HOME). The short form `MalikMoussaoui/maitre-agent` was not tried (it may go through SSH). To pin a version: `MalikMoussaoui/maitre-agent#v1.1.1`.

You get: the skill (started only by `/maitre-agent`), the 5 `ma-*` agents, the agent counter, the agent-finished notification, and re-injection of the state after an automatic summary. **The hooks are active in all your Claude Code sessions**, not only when the skill runs: the re-injection does nothing outside a project that has a `docs/HANDOFF.md`, and the "Claude is waiting" notification is off by default. Quota alerts are not part of it: they come from the status line (terminal) or the mod (desktop). What a plugin **cannot** install: the terminal status line and the `permissions.ask` rules (see below). No plugins in cloud sessions.

Size measured with `claude plugin details` (CLI 2.1.299, 2026-10-19, the CLI's estimates): **v1.2.0** about 3.7k tokens when the skill is called, about 252 tokens added permanently to every session (skill and 5 agents). **v1.1.1**, measured again the same day on the repository before the v1.2.0 changes: about 3.6k and about 267 (an earlier measurement had given 257). The detail of the settings lives in `skills/maitre-agent/reglages.md`, read only by the `reglages` command or when a setting is used: it costs nothing to anyone who sets nothing.

### Route B: copy the skill

```sh
git clone https://github.com/MalikMoussaoui/maitre-agent.git
cd maitre-agent
mkdir -p ~/.claude/skills && cp -R skills/maitre-agent ~/.claude/skills/
```

Open a new session. The hooks (agent counter, notifications, re-injection) only come with the plugin; without it, they are copied by hand (`installation.md`, section 5). The 5 agents are to be copied into `~/.claude/agents/` (from `skills/maitre-agent/agents/`); compare before replacing a file of the same name. The details, written so that Claude can apply them with your approval, are in [`skills/maitre-agent/installation.md`](skills/maitre-agent/installation.md) (in French).

### Route C: release zip

On the [releases page](https://github.com/MalikMoussaoui/maitre-agent/releases), two zips (same remark as route B: the skill-only zip brings no hooks):

```sh
# the skill alone (same as route B): the zip contains the maitre-agent/ folder
unzip maitre-agent-skill-v1.1.1.zip -d ~/.claude/skills/

# the full plugin (files at the zip root), to try it out
unzip maitre-agent-plugin-v1.1.1.zip -d maitre-agent-plugin
claude --plugin-dir maitre-agent-plugin
```

### Command name
- Through the plugin: `/maitre-agent:maitre-agent`. The short name `/maitre-agent` also works as long as no other skill takes it.
- Through the copied skill (routes B and C): `/maitre-agent`.
- **Start it with `/maitre-agent`.** The skill can use a good share of a quota window: its description and `when_to_use` limit loading to an explicit request (the command, or a session asking for the method). `disable-model-invocation: true` was ruled out, because it would stop another session from starting it through the Skill tool.

### Manual configuration (optional, with your approval, and merging)

Both settings go in `~/.claude/settings.json`. **Read the file and merge: never overwrite it.**

**Terminal status line** (does not work in the desktop app, see the limits). With the plugin there is no need for `git clone`: the scripts sit in its cache, and you copy them to a stable path (the cache folder changes with every version, so copy again after an update). Path **observed on 2.1.299** after installing from GitHub, not documented: `~/.claude/plugins/cache/maitre-agent/maitre-agent/<version>/hooks/`. Check with `ls`; if several versions are there, replace `*` with the newest:

```sh
mkdir -p ~/.claude/maitre-agent
cp ~/.claude/plugins/cache/maitre-agent/maitre-agent/*/hooks/statusline.sh ~/.claude/maitre-agent/
cp ~/.claude/plugins/cache/maitre-agent/maitre-agent/*/hooks/notify.sh ~/.claude/maitre-agent/
chmod +x ~/.claude/maitre-agent/statusline.sh ~/.claude/maitre-agent/notify.sh
```

Without the plugin (routes B and C), take the same files from `hooks/` in a copy of the repository (`git clone`) or from the plugin zip.
```json
"statusLine": {
  "type": "command",
  "command": "~/.claude/maitre-agent/statusline.sh",
  "refreshInterval": 10
}
```
It needs `jq`. The quota it shows comes from Claude Code (Pro and Max plans, after the session's first reply); without it, the line shows `quota ?`. The milestone shown is the `Jalon : …` line of `docs/HANDOFF.md`. The same script writes the quota to `~/.claude/maitre-agent/usage.json`, which the skill reads to apply its thresholds.

**Ask before risky commands** (`permissions.ask`): a plugin cannot install these.
```json
"permissions": {
  "ask": [
    "Bash(git push *)", "Bash(gh repo create *)", "Bash(gh pr create *)", "Bash(gh release create *)",
    "Bash(npm publish *)", "Bash(rm -rf *)", "Bash(sudo *)", "Bash(brew install *)",
    "Bash(brew uninstall *)", "Bash(kill *)", "Bash(pkill *)", "Bash(killall *)"
  ]
}
```
Adapt the list to your system. These rules also apply to sub-agents.

## Sub-commands

| Command | Alias | Effect |
|---|---|---|
| `/maitre-agent aide` | `help`, `?` | explains the skill in 15 lines at most and says what is installed on your machine |
| `/maitre-agent statut` | `status` | 5 lines at most per known project, changes nothing |
| `/maitre-agent reprendre` | `resume` | offers the known projects as buttons, then resumes the one you pick |
| `/maitre-agent profil` | `profile` | shows or edits your profile, starts no project |
| `/maitre-agent reglages` | `settings` | no argument: the settings table (current value, default, source). `reglages <key> <value>` changes one, `reglages econome` (or `normal`, `intensif`) applies a preset, `reglages reset` goes back to the defaults |
| `/maitre-agent diagnostic` | `doctor` | 8 read-only checks (`jq`, status line, duplicate skill or agents, readable quota, notifications, version, profile), each "OK / KO + command to fix it" |
| `/maitre-agent nouveau <idea>` | `new <idea>` | starts a new project with that idea |
| `/maitre-agent <idea>` | | same thing, it is the default case |
| `/maitre-agent <project path>` | | resumes that project |

With the plugin, use `/maitre-agent:maitre-agent` if the short name is taken. Details: [`skills/maitre-agent/commandes.md`](skills/maitre-agent/commandes.md) (in French).

## Settings

One place: the `## Réglages` section of your profile (`~/.claude/maitre-agent/profil.md`), as `- <key> : <value>` lines. A `## Réglages du projet` section in a project's `CLAUDE.md` overrides the profile for that project, key by key. Section missing, unknown key or invalid value: the default. **Anyone who sets nothing sees no change in behaviour.** The detail of the keys (`skills/maitre-agent/reglages.md`) is read only by the `reglages` command or when a setting is used, and the calculations (thresholds, tiers, reading the profile) are done by scripts, not by the model. Measured extra cost for anyone who does not use it: about 0.1k tokens when the skill is called (3.6k to 3.7k, rounded measurement); the permanent cost goes down (see "Size measured").

| Key | Values | Default | Effect |
|---|---|---|---|
| `seuils` | 3 increasing integers (10 to 99) | `70 80 90` | quota tiers: no more top-model agent, explicit approval, clean stop; also the alerts |
| `budget-lot` | 5 to 100% | `30 %` | batch size above which it asks for your approval |
| `autonomie` | `techniques`, `tout-demander`, `tout-sauf-accords` | `techniques` | what it decides alone |
| `modeles` | `defaut`, `jamais-opus`, `opus-conception-seulement` | `defaut` | which models it may pick |
| `agents-paralleles` | 1 to 5 | `5` | agents at the same time |
| `notifications` | `agent+quota`, `tout`, `quota`, `rien` | `agent+quota` | which notifications |
| `barre` | `projet` `jalon` `agents` `quota` (`cout` optional), in the order you want | `projet jalon agents quota` | the terminal status line |
| `git` | `commit-local`, `aucun`, `push-branche` | `commit-local` | `push-branche` pushes a working branch (never the main one) without asking again; a standing, dated approval |
| `langue`, `ton` | `profil`, a language code; `tutoiement`, `vouvoiement`, `neutre` | `profil` | how it writes |
| `rapports` | `court`, `detaille` | `detaille` | length of agent reports and answers |

Presets: **`econome`** (thresholds 60 75 85, `budget-lot` 15%, `jamais-opus`, one agent at a time, short reports; also: short briefs, research only for the decisive questions, a tester at the last milestone only), **`normal`** (the defaults), **`intensif`** (thresholds 80 90 95, `budget-lot` 40%, 5 agents). On first launch a button question offers "keep the defaults (recommended) / thrifty / intensive / customize"; if your profile says "Pro plan", `econome` comes first. The real saving of `econome` is **not measured**: at the end of a project the skill gives you a table of agents / model / tokens / duration / share of quota and a "for next time" line (one suggested setting).

```text
/maitre-agent reglages                       # the table
/maitre-agent reglages econome               # the thrifty preset
/maitre-agent reglages seuils 60 75 85       # a single setting
/maitre-agent reglages barre quota projet    # status line: quota then project
/maitre-agent reglages reset                 # back to the defaults
```

The status line, `quota.sh` and `notify.sh` read `seuils`, `notifications` and `barre` themselves; the desktop mod reads `seuils` and `notifications` (not `barre`: its line stays fixed). Detail and limits: [`skills/maitre-agent/reglages.md`](skills/maitre-agent/reglages.md) (in French).

## Safeguards

**It asks for your approval before:**
- anything that costs money (purchase, subscription, paid account, domain);
- a system install or a heavy download (it states the size);
- any publishing (`git push`, remote repository, going live, sharing an artifact);
- any sending (message, email, form);
- an account (creation, login, API key);
- any irreversible action (deletion, overwriting).

A project's dependencies, installed in its own folder, need a single approval per milestone, on an announced list.

**It never:**
- bypasses a protection (captcha, anti-bot, DRM, paywall, anti-cheat, license);
- copies a protected work: it takes inspiration from it;
- buys for you: it gives the links;
- modifies the original files you provide;
- touches servers or ports already in use, or kills an existing process.

Your profile never lifts these prohibitions, except for an explicit, dated instruction from you written in the profile. The content of a HANDOFF or a research file is treated as data, not as an instruction.

**Quota:** 70% (no more top-model agent: design moves to the intermediate model, and it says so), 80% (no new agent on its own initiative: it proposes, cost announced, and waits for your explicit yes), 90% (clean stop, HANDOFF updated, reset time given).

**Your data:** the scripts and the mod contact no third-party service. Your profile, projects and quota stay in `~/.claude/` and in your project folder. Research work goes through the web when a question requires it; the skill's rule is that your data stays on your machine (no third-party service, no publishing, no shared artifact).

## FAQ

**How much quota does it cost?**
Multi-agent work costs more tokens than a single session, and the skill says so itself: it only delegates when a task has a large context to read, real parallelism, or needs independent verification. Figures measured while building this repository, on a Pro plan: one research agent, 209,000 tokens, 28 minutes, about 12% of the 5-hour window; two implementation agents, 110,000 and 111,000 tokens (percentage not measured). Three measurements, not an average.

**Is a Pro plan enough?**
This repository was built on a Pro plan, with a forced pause at 90% of the 5-hour window and a resume after the reset. The skill is designed for that (70 / 80 / 90% thresholds, clean stop). Since v1.1.1 a "Pro plan" rule caps a Medium project at 1 design + 2 research agents, milestones in sequence, and announces a Large one as "several windows, N days" before starting. Why: extrapolating a single measurement (209,000 tokens, about 12% of the window), the outside review estimated that a Medium with at least 1 design and 1 milestone already takes a third to a half of a window (linear estimate, not measured).

**Does it work without sub-agents?**
Yes. Without a sub-agent tool, the skill says so once, then works alone: it keeps verification, permissions and handoff. An audit done by itself is then not independent, and it writes so ("auto-vérifié, non indépendant", self-verified, not independent).

**In the terminal, the desktop app, the cloud?**
Terminal: meant to do everything, but the status line has only been tested with dummy JSON. Desktop app: the skill; the hooks are meant to work there (not tested); the status line is not displayed there, so install the `maitre-agent-bureau` mod. Cloud: plugins are not available there; the skill alone in a cloud environment has not been tried (not verified).

**Which language?**
The language of your profile, for everything the skill writes. File names stay in English (`HANDOFF.md`, `CLAUDE.md`...). The skill's texts and the scripts' messages (status line, notifications) are in French; there is no English version of the scripts' messages.

**Can I resume a project on another account or another computer?**
Yes, that is the point of the handoff: only the project's files travel (`CLAUDE.md`, `docs/HANDOFF.md`, `docs/research/`, `docs/briefs/`). The profile used is the one of the person resuming. The skill compares HANDOFF to the disk before relaunching anything.

**How do I turn notifications off?**
The `notifications` setting (`/maitre-agent reglages notifications rien`) turns them all off, or keeps only the quota (`quota`). Without it, the files below decide. By default the "Claude is waiting" notification (permission request, idle) is **off**; the end of a `ma-*` agent and the quota alerts do notify. To turn the first one on, create `~/.claude/maitre-agent/notifications-on`. To turn everything off, create `~/.claude/maitre-agent/notifications-off` (no more notifications from the scripts, quota alerts included; the status line keeps working). The desktop mod has its own toasts, which this file does not turn off. Useful in the desktop app, which already notifies when a task ends. To test without showing anything: environment variable `MAITRE_AGENT_DRY_RUN=1`. To remove everything: uninstall the plugin.

**Are the scripts safe?**
They never block (short timeout, `|| true`, exit code 0). A search through their code finds no network call (`curl`, `wget`...); they write only to `~/.claude/maitre-agent/`. Read them before installing: `hooks/` is about 330 lines of `sh` in total. `tools/reglages.sh` (240 lines), on the other hand, writes the "Réglages" section of the profile (or of the project's `CLAUDE.md` with `--projet`) when you run the `reglages` command. The text they display (milestone, agent report, message) is filtered: control characters (terminal escape sequences) are removed.

## Limits, honestly

- **The terminal status line is not displayed in the desktop app.** A test script declared as `statusLine` was called by none of the 6 following messages (caveat: hot reloading of the project setting is not proven). This matches the public Claude Code issue #41456 (open); #83534 was closed as a duplicate of #41456. Hence the `maitre-agent-bureau` mod, which relies on an early-access API and may break from one version to the next (written for Claude Code 2.1.299).
- **The plugin's hooks have not been tested end to end by Claude Code.** The scripts are tested with dummy JSON on every push (`tests/hooks.sh`, throwaway HOME, no real notification), and the commands in `hooks.json` were run one by one with `sh -c` and the `CLAUDE_PLUGIN_ROOT` variable; the plugin passes `claude plugin validate --strict`. But Claude Code has not yet triggered them in a real session with the plugin installed. An agent you interrupt may not fire `SubagentStop` (not verified): the counter then ignores its files after 5 hours.
- **Notifications:** the macOS command was seen working when run outside the sandbox of Claude's commands. Linux (`notify-send`): not tested.
- **Installation from the GitHub marketplace: tried, with a caveat.** On 2026-10-19 an outside reviewer installed `maitre-agent` and `maitre-agent-bureau` from GitHub in a throwaway HOME (CLI 2.1.299, full HTTPS URL): "Successfully installed", status enabled. Not tried: the short `owner/repo` form, the desktop app, and behaviour in a real session (no authentication in a throwaway HOME).
- **Agent names under the plugin.** Under the plugin the agents are called `maitre-agent:ma-chercheur`. Since v1.1.1 the skill asks for "the exact name shown by the sub-agent tool"; that this resolves in a real session has not been tried (a single real trial is still to do). If the `ma-*` agents are missing it falls back to `general-purpose`, and says so.
- **The GitHub workflows (`lint.yml`, `release.yml`) have been run** and were green on 2026-10-18 (lint and release, release v1.1.0 with its two zips). The v1.1.1 result is only known after its push.
- **The evaluations are written but not yet run**: see [`evals/`](evals/README.md) (in French; their format is not that of `claude plugin eval`). No result is claimed.
- **In the terminal the quota comes from the status line.** The `get_usage` tool is not visible to the model in CLI 2.1.299 (it only shows up as an SDK control request); the skill therefore reads `usage.json` through `hooks/quota.sh`, which assumes the status line is installed (and called: not in the desktop app). Without a valid measurement (under 15 minutes old) it asks you for the percentage.
- **Buttons and chapters depend on the environment.** Without a question tool, the skill asks numbered lists; without a chapter tool, it opens none. The desktop app's chapter tool is not publicly documented.
- **Settings are tested on the scripts and the mod, not on the model.** That the model applies every key (models, autonomy, reports, `econome`) has not been seen in a real session; the saving of `econome` is not measured.
- **Multi-agent costs more** than a single session, and nothing guarantees it is faster. For a small job, the skill stays alone.
- **Only the cases described above are verified.** A line of this README that says neither "tested" nor "used for real" should be read as untested.

## Credits

`maitre-agent` draws on ideas read in these projects and documents. Everything is reworded: no text was copied.

- [obra/superpowers](https://github.com/obra/superpowers) (MIT): the on-disk handoff as a ledger of trust after compaction; codified agent report statuses (done, done with concerns, needs context, blocked); one brief per file instead of pasted text; the model always stated at each launch; the requirement of proof before saying "it's done".
- [OthmanAdi/planning-with-files](https://github.com/OthmanAdi/planning-with-files) (MIT): writing findings to a file as you go; the three-failures protocol (diagnose, try another approach, rethink); a single owner of the plan; the idea that a resume can be tested with a few questions.
- [github/spec-kit](https://github.com/github/spec-kit) (MIT): a "constitution" of non-negotiable principles against which a deliverable is checked, and bounded clarifying questions. The scored audit and the "non-negotiable rules" section that follow from it are planned, not done yet.
- Claude Code documentation: [skills](https://code.claude.com/docs/en/skills), [sub-agents](https://code.claude.com/docs/en/sub-agents), [hooks](https://code.claude.com/docs/en/hooks), [plugins](https://code.claude.com/docs/en/plugins/overview) and [status line](https://code.claude.com/docs/en/statusline). The skill, agent, hook and plugin formats, the quota fields received by the status line, and the command name of a plugin skill come from there.
- Anthropic Engineering, ["How we built our multi-agent research system"](https://www.anthropic.com/engineering/multi-agent-research-system) (2025-06-13): the conductor-and-workers architecture, effort scaled to the question, and the finding that agents use about 4 times more tokens than a chat, and multi-agent systems about 15 times (compared with a plain chat; figures from the article, not measured here).

About twenty other repositories were read during the initial research; only those above directly shaped the result.

## Made with itself

> **This repository was designed, audited and published with the maitre-agent skill itself.**

The story, short, funny and checkable:

- **v1.0.0**: research on about twenty GitHub repositories and on the Claude Code docs, a design, **2 audits** and **1 real test** (per the project brief; details not kept), then a home-made lint. The skill reviewed itself before reviewing anyone else.
- **v1.1.0** was driven by the skill on its own build, with its own agents: one `ma-chercheur` (sonnet, 209,000 tokens), two `ma-executant` (sonnet) for the plugin and the desktop mod, and a third to write this README. The master agent kept the checks that mattered for itself.
- **It stopped exactly when it should.** At 90% of the 5-hour quota, the skill's rule kicked in: clean stop, HANDOFF updated, not one more agent launched. After the reset, the build resumed, HANDOFF up to date.
- **It also tripped over its own feet, and wrote it down.** The master agent overwrote a local settings file without reading it (the opposite of its own rule). A commit meant to contain a piece of research contained none of it, because of a git exclusion. Both are told in the handoff, not hidden.
- **The real tests have admitted limits:** the notification arrived, but not when it was fired from the sandbox; the test script showed that the desktop app does not call the status line, which is how the mod was born.
- **Reviewed by an independent auditor (`ma-auditeur`) on 2026-10-18, corrections applied.**
- **v1.1.1** comes from an outside review of the published repository (15 fixes, 5 modifications, 4 additions, reviewer in read-only mode): filtered status line, a quota the skill can finally read, a "Pro plan" rule, a skill started only by command, a `diagnostic` sub-command, hook tests.
- **v1.2.0** (customizable settings) was requested by the user and written by a `ma-executant` agent.
- **Not done yet:** running the evaluations (`evals/`).

The full story, with the agents, their models, measured costs, decisions and mistakes: [`docs/fabrication.md`](docs/fabrication.md) (in French).

## License

[MIT](LICENSE) © 2026 Chopa. See also [`CONTRIBUTING.md`](CONTRIBUTING.md) and [`CHANGELOG.md`](CHANGELOG.md) (in French).
