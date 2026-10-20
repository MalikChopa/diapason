# Quota: phase boundary and pace

Read from SKILL §6 when you read usage at a phase boundary or before a batch.

## Phase boundary
At the end of the brief sheet, the mock-up or a milestone: if `context.percentUsed` (usage tool) exceeds about 40%, propose at the checkpoint a fresh session from HANDOFF, with the resume message ready. No measure: nothing.

## Pace (5 h window)
If `resets_at` is known (start = reset − 5 h) and the % used exceeds the % of elapsed time by more than 20 points, decide as if the next threshold were reached.

## Weekly window: what to say
Tier from `quota.sh hebdo` (gap to the elapsed share of the week: `seuils-hebdo`; absolute ceilings: `plafonds-hebdo`; see `reglages.md`). Same effects as the 5 h tiers, one sentence each:
- tier 1: "weekly quota at X% (N points ahead), no more most-capable agents";
- tier 2: "weekly quota at X%", batch proposed, wait for a yes;
- tier 3: clean stop, "weekly quota reached, resuming <reset date>".
