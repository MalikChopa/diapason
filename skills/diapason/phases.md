# New project: start, size, skeleton, flow

Read by section (`grep -n '^## \|^### ' phases.md`, then `sed`): "0. Start", "Size", "Skeleton", "Flow", then only the subsection of your flow (Inspiration, Assets, Mock-up, Design, Milestones, Tests, Plan, Answer, Production, Data, Delivery and the end-of-project recap are read when their phase comes). A Small reads little more than "0. Start" and "Size".

## 0. Start
1. **Quota**: read usage (SKILL §6) only if at least one agent will run (a Small answer without agent: skip).
2. **Context**: look in the profile at the "Projets connus" and "Usages" related to the request, and re-read the `CLAUDE.md` of the linked project if there is one. Do not guess a usage that the profile or a project already states.
3. **Size and flow**: choose them from the tables below ("Size": criteria and keywords).
4. **Start message**, a single one, containing:
   - the goal in one sentence;
   - the size and the flow;
   - the folder (profile preference "Dossiers");
   - the grouped question of the profile's "to confirm" lines, and the plan's preset if not yet confirmed (`reglages.md`, "Forfait et préréglage");
   - your assumptions for the rest ("I assume that…");
   - the estimated cost (SKILL §6).

   **Project to build** (Medium, Large, and Small as soon as there is something to make): continue in the same turn with tour 1 of `cadrage.md`, and **wait for the answers**. Tour 1's questions replace the "blocking questions"; the limit of 2 does not apply there. Nothing is built before the sheet is validated.
   **Other case** (decision, purchase, plan, direct answer): at most 2 blocking questions, asked in this message. Wait for the answer **only** if there is a blocking question, an approval to ask for (§5 of the skill) or a batch above `budget-lot` (SKILL §3). Otherwise announce and launch in the same turn: "announce and launch" stays valid for these cases and for the technical inside of a validated milestone, never for a product decision (SKILL §2). "go" or an answer that does not settle = default choice, except for "Approve" (a sheet is not validated by default).
   If the environment has its own mechanism for asking a question at the end of a turn (buttons, box), use it. "To confirm" profile lines: ask only those that concern this task.
   **Order**: steps 1 to 5 happen before tour 1 (the message of step 4, then the folder and the draft sheet of step 5, in the same turn); steps 6 and 7 happen after "Approve" on the sheet.
5. **Folder** (created before tour 1's questions: the sheet is placed there as a draft, `cadrage.md`): per the profile preference "Dossiers", a new folder under the projects folder, never inside another project (unless asked). Use the change-folder tool if there is one (may be deferred: ToolSearch). Otherwise create the folder (mkdir, or the OS equivalent) and work with absolute paths. While the project folder is not the current folder, every `reglages.sh` call sets `DIAPASON_PROJECT_DIR=<project folder>` (SKILL §0). Re-read the project's `CLAUDE.md` yourself. In every brief, remind to run commands from this folder.
6. **Survey** (if the project depends on it): useful tools and versions. Update the profile's "Machine" section. In the project, note only what serves the project.
7. **Skeleton**: copy from `SKILL_DIR/templates/`, translating and filling every field (see the table).
   - Check no empty field remains with the search tool, or with `grep -rnE '<(…|[[:alpha:]])[^>]*>' CLAUDE.md docs/`. Ignore legitimate code (HTML, generics).

## Size
| Size | Examples | Agents | Files |
|---|---|---|---|
| **Small** | question, purchase, comparison, short plan, analysis of a file, small script, toy of one screen (to build: framing workshop, short version, written by you after "Approve") | 0 to 2 | No agent: the deliverable alone (no folder if the answer fits in the chat; a script to run again gets a short `CLAUDE.md` and `tools/`). **A purchase or decision without agent creates no project folder and is not added to "Projets connus"**. From the first agent: mini-skeleton = short `CLAUDE.md`, `docs/HANDOFF.md`, `docs/briefs/`, plus `docs/research/_BRIEF.md` if there is research |
| **Medium** | app MVP, site, tool, short game or demo (one level, 2 to 4 screens), technical decision | 1 design + 0 to 5 researches + 1 to 3 milestones | Medium skeleton |
| **Large** | full product, full game, multi-platform | 6 to 15 researches, design + spec + audits, milestones, testers | Large skeleton, spread over several sessions |

**Criteria** (objective; take the largest size that any line reaches; in doubt between two sizes, the smaller, say so):

| | Small | Medium | Large |
|---|---|---|---|
| Screens | 0 to 2 | 3 to 6 | more than 6, or several platforms |
| Data | none, or one local file | one user's data (file, local database) | shared between users with roles or payments |
| Accounts | none | none, or one simple login | roles, several kinds of users |
| Files touched or delivered | 1 to 3 | about a dozen | many, several sessions |

**Keywords** in the request, by meaning in any language: small, simple, quick, mini, toy, script (FR: petit, simple, rapide, mini, jouet, script) point to Small; MVP, demo, prototype (FR: MVP, démo, prototype) cap the size at Medium. A keyword never raises the size.

Size can change along the way: say so and note it.

**Plan and preset** (`reglages.md`: reading `plan.plan`, mapping Pro / Max 5x / Max 20x or API = `econome` / `normal` / `intensif`, written in the `prereglage` line). The preset sets parallel agents, use of the most capable model, researches, audits and mock-up variants (table in `reglages.md`).
- **`econome` (Pro plan)**: a 5 h window does not carry a whole Medium (measured benchmark: 3 researches ≈ 36% of a window, extrapolated from a single measure). **Medium** capped at 1 design + 2 researches; milestones **in sequence**, one batch of agents at a time. **Large** announced up front as "several windows, N days", with the user's approval **before starting** and an up-to-date HANDOFF at each tier of the skill's §6. A hand-written `agents-paralleles` line lifts the parallelism cap (`reglages.md`).
- **`normal`, `intensif`**: the "Size" table applies, with 3 or 4 agents in parallel, or 5.
- In doubt between Medium and Small, take Small.

## Skeleton
| Template | Destination | Size |
|---|---|---|
| `CLAUDE.md` | `CLAUDE.md` (project root) | Medium, Large (Small: short version if the work lasts) |
| `HANDOFF.md` | `docs/HANDOFF.md` | Medium, Large (Small: if the work lasts) |
| `INDEX.md` | `docs/research/INDEX.md` | as soon as there is research |
| `_BRIEF.md` | `docs/research/_BRIEF.md` | as soon as there is research |
| `FICHE.md` | `docs/FICHE.md` | any project to build (created as a draft in tour 1, `cadrage.md`) |
| `JOURNAL.md` | `docs/JOURNAL.md` | from the first milestone |
| `RECOMMANDATION.md` | `docs/RECOMMANDATION.md` | decision, purchase |
| `PLAN.md` | `docs/PLAN.md` | plan, organisation, content |
| — | `docs/briefs/` | from the first agent |
| — | `docs/ARCHITECTURE.md`, `docs/SPEC.md` | written by the design agent (Large; Medium: ARCHITECTURE only) |

## Flow
Announce it in 3 lines and note it in HANDOFF. Skip any useless phase, saying so. **Checkpoint** (`cadrage.md`) after the sheet, after the mock-up and after each milestone; at each phase boundary, check `context.percentUsed` (SKILL §6).

| Type | Flow |
|---|---|
| **Decision, purchase** | Framing → Research → Verification → Answer |
| **Plan** (trip, procedure, event, organisation) | Framing → Research → Plan → Verification → Answer |
| **Small to build** (script, one-screen page or toy) | Short framing (validated sheet) → Build by you → Trial (fake data, dry run if it touches files) → Delivery |
| **Software** (app, site, tool, script, automation) | Framing (workshop, validated sheet) → Research → **Mock-up** (if interface) → Design → Audit → Milestones → Tests → Delivery |
| **Game or interactive creative project** | Framing (workshop, validated sheet) → Inspiration (if relevant) → Research → **Mock-up** (screens, menus, one fixed scene) → Assets → Design → Spec (Large) → Audits → Milestones → Player-style tests → Delivery |
| **Content** (document, presentation, video, course, brand) | Framing → Research → Plan → Production → Audit → Final version |
| **Data or analysis** | Framing → Data inventory → Scripted cleaning → Analysis → Audit of the figures → Report |

### Framing
- **Project to build** (software, game, content, data analysis: any manufactured deliverable): follow `cadrage.md` (tour 1 the what, tour 2 the how, tour 3 the sheet `docs/FICHE.md` to validate). It covers goal, audience, form, features, techs, data, style, constraints (money, deadline, accounts, legal). No code and no implementation agent before "Approve".
- **Decision, purchase, plan**: goal, audience, targets (platforms, countries), level of finish, constraints. At most 2 blocking questions (start, step 4); do not read `cadrage.md` (it excludes decisions and purchases).
- Take the profile into account: level, tools owned, country and currency (for prices, sellers, laws and procedures). Do not ask what it already says.

### Inspiration (if relevant: visual project or cited reference)
- An agent analyses the reference: what makes it successful. **Take inspiration, never copy**: no names, characters, interface, assets or text.
- A board (palette in hex codes, shapes, mood) is published as a private artifact if the environment allows. A copy of the file stays in the project. The rules that come out go into `CLAUDE.md`.

### Research
See `briefs/recherche.md`. One research per decisive question you cannot settle yourself, within the preset's limit; none if the framing workshop suffices.

### Assets and the user's work (if relevant)
- The first milestones run with shapes or assets generated by script. The real assets are integrated later without changing the code.
- For what Claude cannot produce alone (images, 3D, voice, music, video, accounts, physical actions), propose a tool that produces **this type of asset**, first among those in the profile. Give ready-to-copy prompts, one per file, with the file name to use.
- Received files are originals that neither you nor the agents modify (SKILL §5). The scripts in `tools/` process copies and can regenerate everything. Measured inventory in `docs/ASSETS.md`, checked by an agent. Check the commercial licence before any sale.

### Mock-up (if the deliverable has an interface: site, app, visual tool, game)
Between the validated sheet and the design. A script, an automation or a document without screens skips this phase, saying so (and the sheet carries "no interface" in "Mock-up approved"). No product code before approval.

**Mock-up scale**: take the first rung that exists (tool survey, `cadrage.md`) and fits, say "I saw X, I start from there" and why.
- **(a) Mock-up or style guide supplied by the user** (image, PDF, file, Figma link read by a connected MCP): it is the **starting point**. Reading is allowed. Summarise what you keep from it, then ask for the wanted differences. An original stays intact.
- **(b) Connected design tool** (design MCP): reading is allowed. **Writing into the tool needs the user's approval** (account, possible money). Facts read on 2026-10-19 in Figma's official docs (developers.figma.com/docs/figma-mcp-server/write-to-canvas): writing into a Figma file goes through the `use_figma` tool, is in beta, needs a paid Figma plan (Professional or higher) and edit rights, and will become usage-billed. Claude Code's exact support is **not verified at the source**. Without a confirmed paid account: do not offer to write into Figma.
- **(c) Private artifact**: a "Design" type if it exists, otherwise an HTML artifact. Never shared without approval.
- **(d) Static HTML** `maquette/index.html` (step 2 below), opened in the built-in browser.
- **(e) Text preview in the buttons** (step 1): always possible, as a complement or a last resort.

1. **Previews in the buttons**: for the 2 to 4 key screens (home, main screen, input, result), a text wireframe (ASCII) in the `preview` of each option of the question tool, 2 or 3 layouts per screen, the recommendation first with its why. Without a question tool: the wireframes in the chat, numbered options.
2. **Clickable mock-up** (rungs c and d): a single static HTML file (inline CSS, no dependency, no network call, fake data), screens linked together, in the chosen colours and layout. **Who writes it**: a simple mock-up (1 variant, 4 screens at most) is made by you, with at most one check screenshot (screenshots stay in your context for the whole session: cost **non chiffré**). Beyond that (variants, more screens): `ma-executant` (middle model) with `briefs/maquette.md`, **one variant per agent**, in parallel if the preset allows; repeated visual checking is the agent's. Show it as a private artifact if the environment allows, otherwise `maquette/index.html` opened in the built-in browser or, failing that, give the command to open it.
3. **Approval by buttons**: checkpoint (`cadrage.md`) with "Continue (= the mock-up is approved) / Adjust / Stop" (FR: Continuer (= la maquette est validée) / Ajuster / S'arrêter). If there are variants, one more question to choose (variant A / B / mix; FR: variante A / B / mélange). Variants per preset: `econome` 1, `normal` 1 to 2, `intensif` 2 to 3.
4. **The approved mock-up is the reference**: keep it (`maquette/index.html`, or the supplied link or file), note its path in `docs/FICHE.md` (line "Mock-up approved") and in HANDOFF. Implementation and test briefs cite it. A wanted deviation during the milestones = a new, dated approval by the user.

### Design (`briefs/conception.md`)
- Compare 2 or 3 options on measured criteria, especially what can be tested without the user.
- Choose and justify in 3 reasons, with the price to pay.
- Split into milestones J0…Jn, with measurable criteria; J0 = the smallest skeleton that runs.
- Audit: 2 rounds at most.

### Milestones
- One implementation agent per milestone, sole writer of the code. Its brief cites `docs/FICHE.md` and the approved mock-up (paths).
- `docs/JOURNAL.md` kept up to date. Execution choices (structure, secondary libraries, naming) are noted "délégué" in `CLAUDE.md`.
- After each milestone, you verify yourself: build, tests, real run, at least one screenshot or output looked at. Then **checkpoint**: mini-demo, what changed, the next milestone and its estimated cost, "Continue / Adjust / Stop" (FR: Continuer / Ajuster / S'arrêter). Inside a validated milestone, purely technical choices need no checkpoint.
- **Code fixes**: 3 rounds at most per milestone. Rounds 1 and 2: the same agent, resumed by message. Round 3: a new agent on a higher model. Then you decide: blocking (question to the user) or parked (decision, reason and cost if wrong, written in JOURNAL).
- Git per the profile.

### Tests (`briefs/testeur.md`)
- One tester on an isolated copy, comparing with the approved mock-up (`briefs/testeur.md`): at the **last** usable milestone for a Medium, at **each** usable milestone for a Large. For small milestones, you run the tests (SKILL §4, "Proof required"): a tester per milestone doubles the implementation cost.
- Its blocking bugs go first in the next milestone.
- If the user wants to see: the fastest way (command, local URL, simulator, artifact), in 3 lines.

### Plan
- `docs/PLAN.md`: dated steps, the cost of each, total compared with the budget, checked critical points, links.
- In the chat, 15 lines at most: the step-by-step summary, the total and 3 risks.

### Answer (decision or purchase)
- In the chat, 15 lines at most, with a compact table: choice no. 1, 2 alternatives, prices with their date, the seller and the country, 3 reasons and the risks. **Setting `rapports : court`** (`econome`): 8 lines at most, and say what is cut: keep the choice, its price, 2 reasons, 1 risk, the links; the alternatives, the other reasons and the other risks go to the detail.
- The detail goes into `docs/RECOMMANDATION.md` (a Small without project folder: the chat alone, offer the detail on request). If you have no web tool, an agent sources the prices and you write "non vérifié à la source" for what you could not check (SKILL §4).

### Production (content)
- An agent writes (`briefs/implementation.md`, writer role).
- You re-read, then an audit if needed.

### Data
- The original stays where it is (absolute path in `CLAUDE.md`).
- Scripts in `tools/`, outputs in `out/`.
- Report in `docs/RAPPORT.md`: question, method, key figures, limits, how to reproduce.
- Audit of the figures by a different means from the analysis.

### Delivery (if relevant)
- Dedicated research: platforms, signing, prices, procedures, legal obligations.
- Before any publication, check that the name is free (trademark) and that licences are in order.
- Publish, send, pay: only with the user's explicit approval.

### End-of-project recap (as soon as an agent has run, with or without delivery)
1. Fill in the "Coût" column of the "Agents lancés" table of `docs/HANDOFF.md` with what you noted (never an invented figure: "non mesuré").
2. Run `sh SKILL_DIR/hooks/recap.sh` (in the project folder) and give its table as is: agent, model, tokens, duration, share of quota. Below it add a line "Next time:" (FR: "Pour la prochaine fois :") with **a single** recommended setting (rule in `reglages.md`, section "Pour la prochaine fois"), worded as a command: `/diapason reglages <key> <value>`.
3. Carry the measured costs into the profile's "Repères de coût" (`profil-modele.md`).
