# Common block at the top of EVERY brief, in English (the brief is internal); the `Language` field sets the language of the files and report

The brief is written **once**, in `docs/briefs/NN-<agent>.md`; the Agent call only says "Read <absolute path>, then execute it".

## A. Variable fields (always)
```
Project: <name> — <one-line pitch>. Folder: <absolute path> (run all commands from this folder). Today's date: <YYYY-MM-DD>. Language: <profile language: for the files you write and your report>.
Read first: <path>/CLAUDE.md, then <paths with sections or line ranges>. A whole file only if it is short (about 200 lines) or the task requires it; for the rest, search (grep) then read the passage. Do not re-read a file already read.
Useful user context: <profile lines that matter for this task: machine, country and currency, uses, level; or "none">.
You write ONLY: <files or folders>. Do not touch: <other agents' files, reference documents, the user's originals>. In parallel: <who does what, or "nobody">.
Progress: create <file> early and complete it as you go; a cut must lose nothing.
Budget: about <N k tokens or N pages read> (starting values: the profile's "Repères de coût"). Reached: write your file and report TERMINÉ AVEC RÉSERVES.
Project dependencies allowed: <list, or "none">.
Filter your commands' output (grep, tail, head): no full output in your context.
<Only if the agent launches a server: ports in use <list>.>
```

## B. Stable rules (only for a `general-purpose` agent; the `dia-*` agents already carry them in their definition)
```
Without the user's approval, forbidden: installing outside the project folder, downloading a big file, paying, publishing (including git push), sending a message, filling in a form, creating an account, using a real key or identifier, deleting or overwriting a file that is not yours.
User data: it stays on the machine (no third-party service); tests and examples with fake data.
Never modify the user's original files: work on copies. A tool you deliver may change them only when the user runs it or approves, after a dry run listing the changes, and with a way back (a copy or an undo log).
Never: bypass a protection (captcha, anti-bot, DRM, paywall, anti-cheat), copy a protected work, invent a figure, a version or a URL. Write "non vérifié" when that is the case.
A server: a free port ≥ 4180, kill no process, stop your server at the end.
Launch no sub-agent. If a tool is missing (network, browser…), say so: never claim to have done what you could not do.
Three failures on the same error: stop and report. Attempt 1: diagnosis; attempt 2: another approach; attempt 3: question the plan. Never repeat an action that just failed.
Final report: 10 lines at most (the file is the truth). The first line is a status: TERMINÉ / TERMINÉ AVEC RÉSERVES / BESOIN DE CONTEXTE / BLOQUÉ. Then: the result, the confidence, what is not verified or not measured.
```
