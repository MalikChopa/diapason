# Handoff: <Project name> (<YYYY-MM-DD>)

Dernière visite : <YYYY-MM-DD HH:MM> (updated at each resume)
Jalon : <current milestone or step, in a few words> (read by the status bar)
Sheet: <draft / validated on YYYY-MM-DD> · Mock-up: <path of the approved mock-up / not yet / no interface>

Reading order: `CLAUDE.md`, this file, `docs/research/INDEX.md`, then <synthesis document>.

## Resuming
- With the skill: `/diapason <absolute project path>`.
- Without the skill: "You are Diapason of this project. Read CLAUDE.md then docs/HANDOFF.md. You steer, you delegate each task to an agent of the right model, you verify yourself before saying it is finished, and you report briefly. Start with 'Reprise immédiate'."

Git: <SHA of the last commit / no git>. Ceiling: **8 KB** (bytes, not lines: `wc -c`). At each milestone, move finished agent rows and done sections to `docs/HANDOFF-archive.md` (created on demand, never read at resume unless needed); "Failed leads and known traps" is never archived.

## User requests (word for word)
- <exact quote, date>

## State ([V] = verified now, with the command; [?] = not re-verified)
- Done: <[V]/[?] …>
- Verified by Diapason: <…>
- Unverified or assumptions: <…>
- Installed, bought, published: <nothing / list>

## Agents lancés
| Agent | Task | Modèle | Work file | Statut | Brief | Coût (tokens · durée · % fenêtre) |
|---|---|---|---|---|---|---|
| <short name> | <task> | <model> | <file> | en cours / terminé / arrêté / à reprendre | `docs/briefs/NN-<agent>.md` | <180 k · 9 min · 6 %, or non mesuré> |

## Failed leads and known traps (never cut this section)
- <what was tried, why it failed>

## Decisions and abandoned leads
- <YYYY-MM-DD>: <decision or abandonment, with the reason>

## Reprise immédiate (in order)
1. Read the quota and apply the thresholds.
2. <next task: agent, model, brief ready in docs/briefs/>
(The re-injection hook after a summary replays only the "en cours" and "à reprendre" rows and this section: keep the immediate resume short.)

## Waiting on the user
- <question: money, installation, publication, account>

## Measured costs
- <agents, tokens, share of quota, duration>

## What does not carry over
Conversation history, running agents, personal memory, private artifact links and external accounts: only the project files count.
