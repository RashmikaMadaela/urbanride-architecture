# UrbanRide — Architecture Design Document

Group submission for **Building Scalable Systems with Microservices**.
**Deadline:** Midnight, Sunday 13 September 2026 · **Target submission: 10:00pm**

---

## Ground rules

1. **Only edit your own file.** The whole point of the split is that nobody's changes overlap.
2. **Commit directly to `main`.** No branches, no pull requests. We do not have time for a PR workflow.
3. **Pull before you push.** `git pull --rebase` then `git push`.
4. **Use the canonical service names** from `add/04-service-decomposition.md`. M1 sets these; nobody deviates.
5. **Do not reformat or renumber sections.** M5 assembles from these exact headings.
6. **Content freeze: Sunday 8:30pm.** Nothing new after that.

---

## Who does what

Replace `[[ name ]]` with actual names before the first commit.

| Member | Role | Tasks | Files to edit |
|---|---|---|---|
| **M1** — `[[ name ]]` | Architecture Lead / Integrator | Set the canonical service names first — everyone else is blocked until this exists. Write the service decomposition and inter-service protocols. Draw C4 Context + Container. Run the final consistency pass across the whole document. | `add/01-executive-summary.md`<br>`add/02-introduction-scope.md`<br>`add/04-service-decomposition.md`<br>`add/10-risks-future.md`<br>`diagrams/c4-01-context.png`<br>`diagrams/c4-02-container.png` |
| **M2** — `[[ name ]]` | Performance & Geospatial | Scale derivation table (§3.3 — every other section references these numbers, so publish them early). H3 matching design, latency budget, Kafka ingestion, backpressure, OSRM protection layers. Draw C4 Component for the Matching Engine. | `add/03-requirements-scale.md`<br>`add/05-performance-latency.md`<br>`diagrams/c4-03-component-matching.png`<br>`diagrams/seq-01-ride-request.png` *(optional)* |
| **M3** — `[[ name ]]` | Data & Resilience | Storage selection, CAP positioning, tiering mechanism, Saga pattern and compensations, double-booking fix, quote pinning. All four resilience mechanisms. Build the trade-off summary table. | `add/06-data-design.md`<br>`add/07-resiliency.md`<br>`add/09-tradeoffs.md`<br>`diagrams/state-01-trip-lifecycle.png`<br>`diagrams/saga-01-booking.png`<br>`diagrams/resilience-01-layers.png` *(optional)* |
| **M4** — `[[ name ]]` | Cost & Infrastructure | Full cost model, Google Maps comparison, instance sizing rationale, autoscaling triggers, spot vs on-demand placement. Verify the unverified figures: FX rate, regional cloud pricing, local bulk SMS rate. Maintain the assumptions register. | `add/08-infrastructure-cost.md`<br>`add/appendix-a-assumptions.md`<br>`diagrams/cost-01-breakdown.png` *(optional)* |
| **M5** — `[[ name ]]` | Deck & Assembly | Build the 10-slide deck in Google Slides. Compile references. Run `build.sh`, fix formatting, export final files. Cross-check that every number on a slide matches the ADD. Open the exported files and visually check them before submission. | `add/11-references.md`<br>`deck/README.md`<br>`build/metadata.yaml`<br>Google Slides *(not in repo)* |

### Dependencies

| | Blocked by | Blocks |
|---|---|---|
| M1 | Nothing — starts first | Everyone |
| M2 | M1's service names | M4, M5 |
| M3 | M1's service names | M5 |
| M4 | M2's scale figures (§3.3) | M5 |
| M5 | Everyone's drafts | Submission |

### Rules

- **Edit only your own files.** The split exists so nobody's changes overlap. A merge conflict means someone edited a file they don't own.
- **M1 has final say** on naming and any conflict. No consensus-seeking at this deadline.
- **M2 → M4 handoff matters:** if M2 changes an assumption (ride duration, ping interval, driver count), M4's entire cost table shifts. Say so out loud when a number moves.
- **Content freeze Sunday 8:30pm.** Anything new after that goes in "future work" or gets dropped.
- **Target submission 10:00pm**, not midnight.

### Jointly owned

Two things fall between chairs unless assigned explicitly:

- **Deck numbers match ADD numbers** → M5 + M1
- **Open the exported PDF/DOCX and look at it** → M5
---

## Diagrams

Export to `diagrams/` as **PNG at 200 DPI minimum** (or SVG). Use these exact filenames — the
section files already reference them:

| File | Owner | Required? |
|---|---|---|
| `c4-01-context.png` | M1 | **Yes** — rubric |
| `c4-02-container.png` | M1 | **Yes** — rubric |
| `c4-03-component-matching.png` | M2 | **Yes** — rubric |
| `state-01-trip-lifecycle.png` | M3 | Strongly recommended |
| `saga-01-booking.png` | M3 | Strongly recommended |
| `seq-01-ride-request.png` | M2 | Optional |
| `resilience-01-layers.png` | M3 | Optional |
| `cost-01-breakdown.png` | M4 | Optional |

Keep the editable source (draw.io `.drawio`, Lucidchart link, etc.) in `diagrams/source/` so
someone else can fix a typo without redrawing.

**Do not spend an hour learning a new diagramming tool today.** draw.io, Lucidchart, or clean
PowerPoint shapes are all fine. The rubric grades whether the diagrams are standard C4, not how
pretty they are.

---

## The deck is NOT in this repo

`.pptx` is a binary blob. Git can store it but cannot merge it — if two people edit it, one loses
their work with no way to resolve.

**Use Google Slides.** Link it in `deck/README.md`. M5 owns it.

---

## Building the final document

```bash
cd build
./build.sh
```

Outputs `build/UrbanRide_ADD.pdf` and `build/UrbanRide_ADD.docx`.

Requires `pandoc` and a LaTeX engine:

```bash
# macOS
brew install pandoc basictex

# Ubuntu / WSL
sudo apt install pandoc texlive-xetex
```

**If pandoc turns into a time sink, abandon it.** Paste the merged markdown into Google Docs,
fix the formatting by hand, and export from there. The build script is a convenience, not a
dependency — do not lose an hour to a LaTeX error at 9pm.

---

## Reference material

`reference/` holds the research brief and the section-by-section skeleton. Read your own section's
source material there before writing. Don't edit these files.

---

## Pre-submission checklist

Owner: M1 (content) + M5 (production)

- [ ] All nine services named identically in text, all diagrams, and deck
- [ ] Every cost figure in the deck matches the ADD
- [ ] All three C4 levels present and labelled as C4
- [ ] All four resilience mechanisms explicitly named: circuit breakers, rate limiters, backpressure, DLQs
- [ ] Saga pattern explicitly named and diagrammed
- [ ] Storage tiering explicitly covered
- [ ] Autoscaling triggers table present
- [ ] Instance sizing rationale present
- [ ] Assumptions register complete; nothing unverified presented as fact
- [ ] TOC regenerated after the final edit
- [ ] Exported files opened and visually checked — diagrams not pixelated, tables not broken across pages
- [ ] Both files named per submission requirements
- [ ] Submitted by 10:00pm
