# Framing workshop: decide together before building

Read this file for any project **to build**: Medium, Large, and Small as soon as there is something to make (script, page, tool, document, game, analysis). Not for a direct answer, a decision or a purchase with no deliverable to build.

**Read this file by sections** (`grep -n '^## ' cadrage.md`, then `sed`), never whole: this header and "How to ask" at the start, the tool survey and "Tour 1" before the first question, then "Tour 2", "Tour 3" and "Checkpoint" when their turn comes. A Small reads the header, "How to ask" and "Tour 1" only.

**Small**: short version. Tour 1 cut to 1 or 2 questions that neither the request nor the profile settles (**3 to 4 when the Small touches the user's files**: copy or in place, source of a date, name pattern, duplicates); tour 2 only if a form or tech must be chosen; brief sheet in half a page (irrelevant fields struck out); "Approve" stays mandatory.

**Matrix**: as soon as the project type is known, read from `matrice.md` only the table header and the type's row (`grep -n '^| \*\*' matrice.md`, `sed -n '5,6p'`; extra questions, mock-up form, tests, adjustments by size, plan, tools seen and level), plus "Notes" if needed. Project already built without framing: its section "Resuming a project built without framing" describes how to offer the workshop without imposing it.

**Golden rule**: no code and no implementation agent until the user has answered "Approve" (FR: "Valider") to the brief sheet (tour 3). Not on "go", not on a vague answer, not because "they did not answer". This holds on resume too: `docs/FICHE.md` missing or not validated → the workshop restarts where it stopped. **Single exception**: a project built without framing where the user answered "Keep as is" (FR: Garder tel quel) to the offer of `matrice.md`, noted with its date in the project `CLAUDE.md` ("fiche refusée par l'utilisateur le <date>"): it continues without a sheet; product decisions met along the way still go to the user (button question). Research may run during the workshop if it informs a choice (otherwise no research: the workshop suffices).

**Safeguard**: the hook `hooks/garde-fiche.sh` (`installation.md` §6) enforces this rule when installed. It triggers as soon as `docs/FICHE.md` exists with a "Status: …" line (FR: "Statut : …"): that is why the sheet is created in tour 1, as a draft. It does not replace the text above (writes made through Bash are not filtered).

## How to ask the questions
- **Button question tool** (e.g. AskUserQuestion): up to **4 questions per call**, 2 to 4 options each. Where a recommendation makes sense (form, techs, hosting, MVP, approval): the **recommendation first**, followed by "(recommended)" (FR: "(recommandé)"), with **the why in one line** in the option (cost, difficulty, where it runs). A question of taste or fact (language, budget, name, preference, usage) has no recommended option. A "recommended" option never changes the user's configuration (SKILL §7). The user can always answer freely.
- **Without that tool**: numbered list, 4 questions at most per message, same options (a, b, c), recommendation marked "(recommended)" and its why. The user answers "1a, 2c".
- **Never ask what a survey or a file already says** (profile, `CLAUDE.md`, folder, supplied file): write "I saw X in Y" and start from there. One question fewer beats a confirmed question.
- **Accompanying tone**: simple words, a technical term = a few words of explanation, an honest recommendation with its price to pay, alternatives, never imposing. If the user says "choose for me", put your full recommendation in the sheet and still ask "Approve".
- **Grouped questions**: whatever can be asked together is asked together. The 4 questions of a call are independent of each other; an answer that changes what follows waits for the next tour.
- **Chapter** "framing" opened in tour 1 (SKILL §7).

## Tool survey (before tour 1, no question)
Look at what the environment offers: visible tools, and deferred tools (search "mcp" with the tool-search tool if there is one). Note in one line:
- **Connected MCPs** (`mcp__*` tools): design (Figma, Canva…), documents (Notion, Drive…), code (GitHub…), others;
- **Artifact types** offered (e.g. a "Design" type) and whether they are private;
- **built-in browser** (open a local page), **iOS simulator** (if the project is an iPhone app);
- **button question tool**, with preview (`preview`) or not;
- **connector state**: with a tool that gives it (e.g. `session_connectors_status` in the desktop app, may be deferred), list the session's claude.ai connectors and each one's number of tools (see below).

**Connectors**: each active connector loads its tools into the session context (real token gain of disabling one: **non mesuré**). **Nothing is cut by default**: the recommended option is to keep them all. If some look unrelated to the project, add to a question call already planned "Disable some connectors for this project?": **Keep all (recommended)** / Choose the ones to disable (FR: Tout garder (recommandé) / Choisir ceux à couper). On "Choose", list them by name with their number of tools and cut **only the ones the user names**, with the app's tool (`set_session_connector_enabled`), only for the claude.ai connectors listed, never for the app's servers nor a plugin's. Each time, remind that the choice also becomes the default for new sessions and can be switched back on with one click in the settings. In auto mode the automatic permission check may refuse this tool: say so and give the manual path (the + menu, then Connectors). No state tool: propose nothing.

In the tour 1 message, say "I saw X" (one sentence) and **then propose only what exists**. Nothing absent is promised, nothing is called to "test", no account is connected or created. A connected tool that serves what follows (a supplied mock-up to read, a design tool) changes the form-and-style question: see `phases.md` (mock-up scale). Note the survey in `docs/FICHE.md` (section "Next", line "Tools seen").

## Tour 1: the what (one call, 4 questions at most)
**Before asking the questions**: create the project folder if it does not exist (`phases.md`, start step 5) and copy `SKILL_DIR/templates/FICHE.md` to `docs/FICHE.md` with **`Status: draft`** and **`Mock-up approved: not yet`** (FR: `Statut : brouillon`, `Maquette validée : pas encore`; undecided fields: "to decide"). Write it as the answers come.

1. **Goal**: what problem it solves, or what you want to be able to do. Propose a one-sentence reformulation of the request (recommended) and other possible readings.
2. **For whom**: you alone, family or friends, a public. This decides the account, the hosting and the level of finish.
3. **Product form**: website, mobile app, desktop app, command-line tool, extension, document, game… with the recommendation first and why, based on the user's device, usage and level.
4. **Priority features** (multiple choice): 4 proposals at most, with **an MVP proposal** (the smallest useful set) marked recommended; the rest goes into "later".

**The 4 questions of a call are a ceiling, all included**: the grouped "to confirm" question of the profile (SKILL §0) and the "disable connectors?" question (tool survey) count in it. With no room in the tour 1 call (the tour's 4 questions already fill it), they move to tour 2; if tour 2 is full too, they are **not asked** (never a call for them alone): the "to confirm" lines stay "assumption, to confirm" in the sheet, nothing is disabled, and the agents' installation is offered in one line of the start message. Never 5 questions in one call.

**Matrix extra questions** (`matrice.md`) come within the same ceiling. Priority when there is no room: (1) what decides the product (goal, audience, form, features); (2) what decides cost or privacy (accounts, data, hosting, budget); (3) the matrix's extras (devices, offline, controls, assets); (4) style and the rest. What does not fit becomes a stated assumption in the sheet.

## Tour 2: the how (one call, 4 questions at most)
1. **Main techs**: 2 or 3 choices (language or framework, hosting), the recommendation first with the why: **cost, difficulty, where it runs, what must be installed**. Lean on the profile (level, machine, tools owned). Say what is lost with each option.
2. **Where the data lives**: on the device, in a file, with an online service (account, cost, privacy). If it is personal data, say it stays on the machine unless approved.
3. **Visual style**: 2 or 3 leads (plain, colourful, dark…). With the question tool, use each option's preview (`preview`) if it exists: a text mini-mock-up or a palette in hex codes. Otherwise describe in one line.
4. **Constraints**: budget (zero by default, recommended), deadline, devices and browsers to cover, legal and accounts (personal data of other people).

A project without an interface (script, analysis, document) skips the visual style; a project whose form or techs are imposed by a file or a request skips the question concerned, saying so.

## Tour 3: the brief sheet
1. Complete `docs/FICHE.md` (created as a draft in tour 1): every field filled with the answers, one page. What was not decided is written "to decide"; what you took by assumption is written "assumption, to confirm"; nothing is invented.
2. Summarise the sheet in the chat in 10 lines at most and point to the file.
3. Ask a single question, the approval and the checkpoint merged: **Approve and continue (recommended) / Edit / Start over** (FR: Valider et continuer (recommandé) / Modifier / Tout revoir). Put the flow map and the cost of what follows (see "Checkpoint") in the text above the question.
   - **Approve**: the line becomes `Status: validated on YYYY-MM-DD by the user` (FR: `Statut : validée le AAAA-MM-JJ par l'utilisateur`; the text the safeguard reads), decisions copied into `CLAUDE.md` ("user"), then the rest of the flow (`phases.md`) with no second question. Project without screens (script, analysis, document): write `Mock-up approved: no interface` in the sheet (FR: `Maquette validée : sans interface`), saying so; otherwise the line stays "not yet" until the mock-up is approved (the safeguard refuses code until then).
   - **Edit**: ask with buttons which part (goal, features, techs, data, style, constraints), fix the sheet, ask the question again.
   - **Start over**: restart at tour 1 keeping what was good.

## Checkpoint
At the end of the brief sheet, the mock-up and each milestone, before moving on. Start with the **flow map**, a single line drawn from the project type's flow (`phases.md`, "Flow" table, noted in HANDOFF):

`Step 3/8: Mock-up (to approve) · approved: Framing ✔ Research ✔ · left: Design, Audit, Milestones, Tests, Delivery` (Software-with-interface flow; FR: `Étape 3/8 : Maquette (à valider) · validé : Cadrage ✔ Recherche ✔ · reste : Conception, Audit, Jalons, Tests, Livraison`)

N/M counts the phases of the **announced** flow (a skipped phase, stated at the start, is not counted; if the flow changes, say so and recount). Milestones count as one step, with their number: "Milestones (J2/4)". Only what got a "Continue" or "Approve" from the user is marked approved. Then four short items:
1. **Mini-demo**: a screenshot, a command to run or a link (the mock-up, the local page). No demo possible (document, decision): the most useful passage, quoted.
2. **What changed**: 3 lines at most; what was decided or done, what remains an assumption.
3. **What follows and its cost**: the next phase, the number of agents, an order of magnitude in tokens (profile benchmarks, else SKILL §6); never an unmeasured percentage.
4. **One question**: **Continue (recommended) / Adjust / Stop** (FR: Continuer (recommandé) / Ajuster / S'arrêter). Never launch before the answer. After the brief sheet this question is the approval question of tour 3 ("Approve and continue"): never two validations in a row.

Add to this question call, if needed, the session question (SKILL §6): if the context exceeds about 40%, "Continue here / Restart in a fresh session (HANDOFF ready)" (FR: Continuer ici / Repartir en session neuve (HANDOFF prêt)), with the resume message ready (`/diapason <project path>`).

"Adjust": ask what (buttons), fix, return to the checkpoint. "Stop": update HANDOFF and report. Inside an approved milestone, purely technical choices ask nothing more (SKILL §2 and §7).

## Sheet and follow-up
The validated sheet is the project's reference: it goes up into the briefs (path, not a copy). In the "Decisions" table, each row carries the date **the user** decided ("assumption to confirm" otherwise).

**Product decision changed after approval** (form, platform, audience, MVP feature, main tech, data, style, budget, success criteria): you do not continue on momentum.
1. Set the sheet back to `Status: draft (modified on YYYY-MM-DD, to re-approve)` (FR: `Statut : brouillon (modifiée le AAAA-MM-JJ, à re-valider)`). If the screen changes, the "Mock-up approved" line goes back to "not yet (to redo)" (FR: "pas encore (à refaire)").
2. Tell the user in one sentence: the safeguard blocks code again, that is normal.
3. "Edit" path (tour 3): sheet fixed, dated line in "Changes after approval" and in HANDOFF, then "Approve" again. No new implementation agent before. A technical detail (name, secondary library) does not change the status (SKILL §2).
