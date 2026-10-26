# Quota: phase boundary and pace

Read from SKILL §6 when you read usage, at a phase boundary or before a batch.

## Reading usage
Order: (1) terminal with the status bar: `sh SKILL_DIR/hooks/quota.sh` reads `usage.json` and exits with the tier (0, or the threshold reached; 2 = no measure, over 15 min old or window over: invent nothing), then the usage tool if code 2; desktop app (no `usage.json`): the usage tool directly (`get_usage`, may be deferred: ToolSearch); (2) else the percentage the user gives (the profile notes it).
Weekly figures from the usage tool: never compute, run `sh SKILL_DIR/hooks/quota.sh hebdo <used %> <resetsAt>` (used % written `12.5` or `12,5`; ISO date or epoch; exits with the tier 0 to 3: here 2 = tier 2, not "no measure"; 4 = unreadable input).

## Tier 2+ read at project start (5 h or weekly)
Say so BEFORE the workshop and offer "frame now, agents after the reset"; note the reset time in HANDOFF. Your own work uses the quota too: keep it lean.

## Batch cost
Tokens (the profile's "Repères de coût"; else research 100 to 300 k, design or implementation 300 to 500 k) and % of the 5 h window with the profile's ratio (none: "non mesuré"). Weekly share: "non mesuré" unless the profile holds a measured ratio. Note each agent's real costs in HANDOFF and the profile. No usage measure: ask the percentage before a batch of more than 3 agents.

## Phase boundary
At the end of the brief sheet, the mock-up or a milestone: if `context.percentUsed` (usage tool) exceeds about 40%, propose at the checkpoint a fresh session from HANDOFF, with the resume message ready. No measure: nothing.

## Pace (5 h window)
If `resets_at` is known (start = reset − 5 h) and the % used exceeds the % of elapsed time by more than 20 points, decide as if the next threshold were reached.

## Weekly window: what to say
Tier from `quota.sh hebdo` (gap to the elapsed share of the week: `seuils-hebdo`; absolute ceilings: `plafonds-hebdo`; see `reglages.md`). Same effects as the 5 h tiers, one sentence each:
- tier 1: "weekly quota at X% (N points ahead), no more most-capable agents";
- tier 2: "weekly quota at X%", batch proposed, wait for a yes;
- tier 3: clean stop, "weekly quota reached, resuming <reset date>".
