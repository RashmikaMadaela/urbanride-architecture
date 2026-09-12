# Presentation Deck

**The deck lives in Google Slides, not in this repo.** A `.pptx` is a binary file — Git cannot
merge it, so concurrent edits mean someone loses work with no recovery path.

**Link:** `[[ PASTE GOOGLE SLIDES LINK HERE ]]`

**Owner:** M5

---

## Slide plan (10 minutes, strict)

| # | Slide | Content | Time |
|---|---|---|---|
| 1 | Title | Group, members, optionally the four constraints | 0:20 |
| 2 | The Numbers That Drive Everything | Scale derivation + Uber comparison ratios | 0:50 |
| 3 | System Context | **C4 Level 1 diagram**, full slide | 0:40 |
| 4 | Service Decomposition | 9 services grouped by bounded context | 1:10 |
| 5 | Container Architecture | **C4 Level 2 diagram**, full slide | 1:20 |
| 6 | Matching: Sub-Second Geospatial | **C4 Level 3** + latency budget | 1:30 |
| 7 | Write Firehose & 5x Spikes | GPS → Kafka → consumers, backpressure annotated | 1:15 |
| 8 | Data Consistency & the Saga | Trip state machine + compensations | 1:00 |
| 9 | **The Cost Trap** | Google Maps table. One big number: **64 LKR/ride** | 1:15 |
| 10 | Cost Result | Breakdown + scenario comparison | 0:50 |
| 11 | Trade-Offs | ~6 strongest rows | 0:30 |

**Total ≈ 10:00** — which means the real figure is closer to 9:30 once transitions eat in.
Treat any slide running over as a cut, not a squeeze.

---

## Rules

- One idea per slide
- Diagrams get the **full slide** — never pair a C4 diagram with bullet text
- Minimal text; the speaker carries the detail
- **Every number on a slide must match the ADD exactly** (M5 + M1 cross-check)

**Slide 9 is the strongest slide in the deck.** It is arithmetic rather than assertion and
demonstrates cost reasoning most groups will not have done. Give it room.

**Slides 3, 5 and 6 carry the C4 requirement** — the rubric names standardised C4 diagrams
explicitly, so all three levels must be visibly present.

**If you must cut:** merge 10 and 11, or cut 11 and fold the two strongest trade-offs into the
close. Do not cut 5, 6 or 9.

---

## Backup slides

Placed after the end, not counted in the 10 minutes. Build only if time allows — being able to
jump to a prepared slide during Q&A reads very well.

- Full autoscaling trigger table
- Full trade-off table
- Failure scenario walkthroughs
- Assumptions register
