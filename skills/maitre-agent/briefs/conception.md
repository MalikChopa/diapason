# Brief: design, synthesis or fix (most capable model; middle for a simple fix)

## Design or synthesis mode
```
<header: fields A of _entete.md>
Role: <architect / spec author / synthesis author>.
Inputs: docs/research/INDEX.md and the files <NN…> (launch no new research; if information is missing, note it in "Open points").
Profile and constraints: <what matters: user's level, budget, platforms, autonomy>.
Produce <docs/ARCHITECTURE.md | docs/SPEC.md | docs/PLAN.md | docs/RECOMMANDATION.md> with:
- the decision at the top (3 reasons, the price to pay);
- the options discarded and why;
- <for software: milestones J0…Jn, each with measurable criteria and how to measure them; J0 = the smallest skeleton that runs>
- <for a spec: numeric values, concrete scenarios, edge cases, stable parameter identifiers>
- the risks and the open points.
Target size: <N> words at most. No padding.
```

## Fix mode (after an audit)
```
<header: fields A of _entete.md>
Role: fixer. Sole writer of <document>.
Apply the points of <docs/X_AUDIT_N.md> classed blocking and important. For each point: fix it, or explain why you do not.
Add at the end of the document a corrections log: point number, line, what changed.
Change no parameter identifier, nor anything the audit does not target.
```
