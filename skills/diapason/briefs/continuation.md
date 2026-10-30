# Brief: continuation of interrupted work (same model as the original agent)

An agent cut by `maxTurns` can be resumed as it is with `SendMessage` (its partial output and context are kept: no new brief needed). Use the brief below when it was cut otherwise, or lost (quota window, session closed): a fresh agent reads the file, which is the truth.

```
<header: fields A of _entete.md>
Role: you resume work interrupted by a cut. The file <path> already exists: READ IT ENTIRELY FIRST.
What is done: <summary of what the file contains>.
What is missing: <sections, questions, criteria or steps not done>.
Do not rewrite what is done, except for an obvious error (flag it). Complete in the same format and style.
Original instruction, for reference: <original brief, taken from HANDOFF or rebuilt>.
```
