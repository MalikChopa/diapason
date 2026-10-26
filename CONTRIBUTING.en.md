# Contributing to Diapason

🇫🇷 [Version française](CONTRIBUTING.md)

Thanks for your interest. The project is small: a Claude Code skill, five sub-agents, a few POSIX `sh` scripts and a desktop mod. To understand how it fits together before changing it, read [ARCHITECTURE.en.md](ARCHITECTURE.en.md).

## Proposing a change
1. Open an *issue* for a bug, an idea or a question, with a short, reproducible example.
2. For a change: fork, create a branch, then open a *pull request* that says what changed, why, and how you checked it.
3. One PR = one topic. Do not mix a fix, a new feature and formatting.

## Repository layout (what must stay in sync)
- `skills/diapason/`: the skill itself. `SKILL.md` holds the rules; the other `.md` files are read on demand (`cadrage.md`, `phases.md`, `reprise.md`, `quota.md`, `reglages.md`, …), with `briefs/` and `templates/` for the agents and the project files.
- `agents/` and `skills/diapason/agents/`: the five `dia-*` agents. The two copies must be **byte-identical** (the plugin uses one, a skill-only install the other).
- `hooks/` (plugin hooks) and `tools/` (scripts of the repository) are the **sources** of the scripts that `skills/diapason/hooks/` carries: after changing one, copy it over (`cp -p`). The lint checks that every copy is identical to its source.
- `tests/hooks.sh`: tests of every script, with dummy JSON, a throwaway `HOME` and no network.
- `evals/`: written scenarios used to check the skill's behaviour in a real session (they are played by hand, not by a script).
- `bureau/`: the desktop-app mod (TypeScript). Its tests run with `claude plugin test bureau`; the shell test suite does not cover it.

## Before opening a PR
Run the repository check; it must end without any `ERR`:
```sh
LINT_SKIP_LOCAL=1 sh tools/lint-skill.sh
```
`LINT_SKIP_LOCAL=1` skips the checks of your local installation (`~/.claude`): without it, agents installed on your machine that differ from the repository's would raise an `ERR` unrelated to your PR. To also reject personal patterns, pass them through the environment (`LINT_PRIVATE_PATTERNS='name1|name2'`); never write them in a file of the repository.
It checks the YAML of the agents and of the skill, the size of `SKILL.md`, the cross-references between files, the consistency of the plugin and the marketplace, the copies of agents and hooks, and the absence of personal traces. The same command runs on GitHub at every push.

Then run the tests, under both shells:
```sh
sh tests/hooks.sh
dash tests/hooks.sh
```
They need `jq` (without it they are skipped with a warning). Both must print `0 échec(s)`. Add a test for every behaviour you change, and check that it fails on the old code.

Scripts stay in POSIX `sh`: no bashisms (`[[ ]]`, arrays, `$((10#08))`), and they must work on macOS and Linux (watch `sed -i`, `date -d` / `date -r`, `mktemp`).

## `SKILL.md` has a hard size ceiling
After an automatic summary, Claude Code gives a skill back only its first 5 000 tokens. So `SKILL.md` is capped at **12 000 bytes** (the lint fails above), with the "Permissions" section before byte 11 000 and the last section before byte 12 000. A new rule must come with the removal or the shortening of another, or go in a side file read on demand. Keep the internal text of the skill in English (cheaper in tokens); everything the user sees is in their profile's language.

## Adding a setting
A setting is a `- key : value` line under `## Réglages` of the user's profile. To add one: `tools/reglages.sh` (the key list, its default, what it expects, its validation), the table of `skills/diapason/reglages.md`, the settings tables of `GUIDE.md` and `GUIDE.en.md`, and tests (accepted forms, refused forms, default). Then copy the script into `skills/diapason/hooks/`. A key that `SKILL.md` cites must exist in `reglages.md` (the lint checks it).

## Version number (maintainer)
A version number changes in two places that must stay equal: `.claude-plugin/plugin.json` and `skills/diapason/VERSION` (read by `maj.sh`, the only trace of its version in a skill-only copy); the desktop mod has its own `bureau/.claude-plugin/plugin.json`. The lint refuses a mismatch. A `v*` tag triggers the release workflow: lint, check that the tag equals the `plugin.json` version, build the two zips (`tools/build-release.sh`), then publish the release with the matching `CHANGELOG.md` section as notes.

## Parsimony review (every version)
Extra instructions have a cost (tokens, attention) and are worth it only if they have proved useful. Before releasing a version:
1. Draw 5 rules from the body of `skills/diapason/SKILL.md`, preferably in the heaviest sections in bytes (write down the seed or the drawing method).
2. For each one, find its origin (CHANGELOG line, incident, research) and its evaluation (`evals/`).
3. With neither origin nor evaluation, propose to remove it or merge it into a neighbouring rule; otherwise keep it.
4. Record the 5 rules examined and the decision for each in the CHANGELOG. Removing a useful rule is the real risk: when in doubt, keep it and write the missing eval.

## Absolute rule: no personal data
No name, email, identifier, absolute path to a personal folder (on macOS, Linux or Windows), private project name, screenshot or real session log in the repository. For paths use `~`, `$HOME` or `${CLAUDE_PLUGIN_ROOT}`; for tests and examples, dummy data. The lint refuses personal paths, but reading your own diff is up to you.

## Honesty
In the documentation, write "it works" only for what you tried, and say how. Write "not tested" for the rest. The same goes for numbers: a count or a size is recomputed by a command, not remembered.
