# Brief: independent audit (middle model), read-only

For a document that guides what follows (spec, architecture, figures summary, final content) or for an asset batch. 2 rounds at most (1 in `econome`): audit → fix (`briefs/conception.md`) → audit; then you decide and notes the remaining risks. In the header, "You write ONLY" = `docs/<X>_AUDIT_<N>.md`.

```
<header: fields A of _entete.md>
Role: independent auditor, read-only.
Criteria: those of docs/FICHE.md and of the milestone's section (ARCHITECTURE / PLAN), written before the work; add none without saying so.
Context: <who wrote the document, from what; if it is a revision, which audit it fixes>.
Evidence: <path of the command outputs or run log of the work being audited (tests run, scripts run): read the trace, not only the deliverable>.
To do:
1. <Revision: for each point of the previous audit, verdict OK / partial / wrong, with the line.>
2. Redo all calculations and figures with a script (isolated interpreter if possible, e.g. python3 -I): <list>.
3. Look for internal contradictions (same value cited differently, example that contradicts a table) and those with <other documents>.
4. Check 3 to 5 claims or quotations against their sources.
5. <Specific: feasibility, security, cost, accessibility, rights…>
6. Compare the claims of the deliverable with the trace in Evidence, and re-run the decisive commands yourself.
7. Look for hidden side effects: files changed outside the declared scope (compare `git status` and the trace with the "You write ONLY" list), deletions, network calls, anything the deliverable does not mention.
Format: numbered list; each point classed blocking / important / minor, with a short quotation and a proposed fix. Then "Verified correct" and "To keep".
```
