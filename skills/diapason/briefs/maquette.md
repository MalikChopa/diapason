# Brief: clickable mock-up (dia-executant, middle model; one variant = one agent)

To use when the mock-up exceeds "1 variant, 4 screens at most" (`phases.md`, Mock-up). One variant per agent, in parallel if the preset allows (`agents-paralleles`); each agent writes in its own folder.

```
<header: fields A of _entete.md>
Role: interface designer of the project; you write ONE mock-up variant, nothing else. You are the SOLE writer of maquette/<variant>/ (e.g. maquette/a/index.html).
Read: docs/FICHE.md, validated (path: <path>): form, audience, MVP features, visual style, constraints. <Variant: this variant's idea in one line (layout, tone, colours, hex).> <Mock-up or style guide supplied by the user: <path>, to respect, never modified.>

To deliver:
- ONE static HTML file, inline CSS: no dependency, no remote font or image, no network call, no external script. JavaScript only if short and used to move between screens.
- The screens <list: home, main screen, input, result…>, linked together (working links or buttons); plausible fake data, never the user's real data.
- The colours and layout of the sheet (or of the supplied style guide). Readable on <the sheet's devices>.

Visual check: if a screenshot tool or a windowless (headless) browser exists, open the page, take AT MOST ONE screenshot per screen, look at it, fix; if no tool exists, say so in the report ("contrôle visuel non fait") without claiming to have seen the page. Do not keep screenshots in your report.

Progress: create maquette/<variant>/index.html early; complete it as you go.
Report: the file path, then 3 lines (screens done, visual check done or not, deviations from the sheet).
```
