# User profile

Location: `~/.claude/majordome/profil.md`, outside the skill, so that a skill update or sharing neither overwrites nor exposes it. It applies to all projects.

## First use (2 question calls at most)
1. **Detect without asking anything**, in few commands:
   - language of the message;
   - OS and shell;
   - country, currency, units and time zone, from the system locale;
   - usual projects folder: `~/Developer`, `~/Projects`, `~/code`, `~/dev`, `~/source/repos`, `~/Documents/Projects`, else `~/Projects`;
   - Claude tools available: sub-agents, question tool, usage tool, folder change, browser, Artifact;
   - plan: field `plan.plan` of the usage tool (`reglages.md`, "Forfait et préréglage").

   Hardware (processor, RAM, disk) and development tools are surveyed only when a project depends on them. They are then added to the profile.
2. **First question call** (question tool if there is one, 4 questions at most; otherwise a numbered list):
   - the first essential questions below (accompaniment, level, answer length);
   - **Preset**: the one matching the detected plan first, followed by "(recommended)" (FR: "(recommandé)") and a sentence on what it changes, then the others, then "customise". Plan not detected: the plan question goes first and the preset question moves to the second call (5 questions are never in one call);
   - as text, **written before the question call** (the call ends the turn): "I will always ask you before: money, installations, heavy downloads, publication, sending, accounts, deletions. Tell me if you want to add to it. I save it in <path> and complete it as you correct me. Answer "defaults" to accept everything." (user-visible text: in the profile language)

   The requested project's questions are not part of it: they come right after, in tour 1 of `cadrage.md`. If the `ma-*` agents are in neither `~/.claude/agents/` nor the sub-agent tool's list (nor in the form `majordome:ma-*`, supplied by the plugin), say in one line of the start message that the sub-agents and safeguards can be installed (`installation.md`) if the user wants; nothing is installed without a yes. If they are supplied by the plugin, do not ask it.
3. After the answer:
   - write the profile;
   - write the "Réglages" section: `sh SKILL_DIR/hooks/reglages.sh preset <économe → econome | normal | intensif>`; "customise": show `sh SKILL_DIR/hooks/reglages.sh`, ask which keys to change and apply them with `set` (detail: `reglages.md`);
   - if the chosen accompaniment is not `accompagnant`: `sh SKILL_DIR/hooks/reglages.sh set autonomie <value>`;
   - note the plan in the "Forfait / quota" line;
   - mark "(défaut, à confirmer)" only a line taken without the user having seen it (a value detected but never shown, a refused answer); **never** a line the user just chose or accepted with "defaults"; at most one re-confirmation later (SKILL §0);
   - show the profile in 5 lines;
   - **continue without waiting** with the project (`phases.md`).

   If the user refuses to answer, take the defaults (the detected plan's preset, else `normal`) and mark them "(défaut, à confirmer)".

For a trivial request (direct answer, no agent), create a minimal profile with what is detected, and answer.

### The essential questions (default in brackets; the last is announced as text)
Language and informal/formal address are **detected from the user's message** (no question).
1. **Accompaniment** (setting `autonomie`): you always decide the product form, the features, the main techs and the style, and you see a mock-up before the code. For the rest (technical details), I accompany you: I decide and explain in one line (`accompagnant`); I decide without explaining (`techniques`); I ask you everything (`tout-demander`); I decide everything except the approvals (`tout-sauf-accords`)? [accompagnant]
2. **Level**: beginner, intermediate or expert? [intermediate, technical terms explained in a few words]. **Answer length**: short or detailed? [short]. (Two questions, one axis each; no recommended option.)
3. **Folders**: not asked, announced in the text: each project in a new folder under <detected folder>, name proposed without asking again; the user corrects if wanted.
4. **Always ask me before**: money, installations, heavy downloads, publication, sending, accounts, deletions. Anything else? [this list; announced as text rather than asked as a button, see above]

The other preferences take their default, until the user corrects them:
- tests: agents test, the user looks if they want;
- git: local, with a commit per verified step; push on request only;
- quota thresholds: 70 / 80 / 90% for the 5 h window, weekly tiers 20 / 40 / 60 points or 85 / 92 / 97% ("Réglages" section: `seuils`, `seuils-hebdo`, `plafonds-hebdo`);
- most capable model: allowed;
- tools owned: none;
- limits: none.

## `profil.md` template
Write it in the profile language, headings included, but the names in brackets stay in French in every language (`statut`, `reprise.md` and the scripts search them); the heading `## Réglages` stays as is (a script reads it).
```
# Profil majordome
Created: <YYYY-MM-DD> · Updated: <YYYY-MM-DD> · Automatic updates: <yes / no; default "no", the majordome proposes the update>

## Detected
- Language: <…>
- OS / shell: <…>
- Country / currency / units / time zone: <…>
- Projects folder: <path>
- Claude tools: <sub-agents yes/no, questions, usage, folder, browser, Artifact>
- Plan / quota (Forfait / quota): <plan (Pro, Max, API…) if known; quota source: usage tool, the status bar's `usage.json`, or "no measure">
- Machine and dev tools (Machine): <filled when a project needs it>

## General preferences (all tasks)
- Autonomy: <accompagnant / techniques / tout-demander / tout-sauf-accords; the `autonomie` setting is authoritative>
- Folders: <…>
- Language, formality, tone, level: <…>
- Always ask before: <list>
- Quota: most capable model <allowed / not>; thresholds and other settings: "Réglages" section below
- Limits: <…>

## Réglages
- (written by `reglages.sh` at first use; keys in `reglages.md`, e.g. `- seuils : 70 80 90`)

## Uses and equipment (Usages et équipement; to frame researches)
- <what the user does, uses or owns: games, software, hardware, subscriptions, creative tools>

## Preferences for code or creative projects
- Tests: <…>
- Git: <…>
- Creative tools owned: <…>

## Known projects (Projets connus)
- <name>: <one line> — <path> (<date>)

## Cost benchmarks, measured (Repères de coût)
- <YYYY-MM-DD>: <agent type, model> ≈ <k tokens>, <duration>, <% of which window>
- Example (measured 2026-10-20, Pro plan, a single measure): one sonnet agent of ≈ 150 k tokens ≈ 10 points of the 5 h window and ≈ 2 points of the weekly window. A ratio like this one is what lets the majordome announce a batch in % (SKILL §6); without it, tokens only.

## Observed habits (Habitudes observées)
- <YYYY-MM-DD>: <user correction or request, to apply from now on>
```

## Keeping the profile (bounded)
- **Ceilings per section**, so that reading it does not grow with use: "Repères de coût" 8 lines, "Projets connus" 15, "Habitudes observées" 15, "Usages et équipement" 15. Past the ceiling, merge or remove the **oldest** line (costs: keep one median line per agent type plus the latest ones; projects: the most recent, the oldest dropped; habits: no duplicates, a new line that repeats an old one replaces it). Say so in one sentence.
- **Read only the useful sections** when the task needs a few of them (`grep -n '^## ' <profile>`, then `sed -n '<from>,<to>p'`): a decision or purchase reads the equipment, a resume reads "Projets connus" and "Réglages", `statut` reads "Projets connus" alone. The whole file only for `profil`, the first use and a survey redo.
- The user corrects your way of working ("stop asking me X", "always test Y"): if "Automatic updates" is yes, add a dated line in "Habitudes observées" and say so in one sentence. Otherwise, propose it.
- `/majordome profil`: shows the profile and applies the requested changes.
- At the end of a project, add the measured costs to "Repères de coût" (tokens and % of window per agent), and the project to "Projets connus" (not a Small purchase or decision without agent).
- Information learned during a task (usage, equipment) and useful afterwards: add it to "Usages et équipement", if automatic updates are allowed.
