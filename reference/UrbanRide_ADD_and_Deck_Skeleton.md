# UrbanRide — ADD & Deck Skeleton

**Purpose:** Fill-in template for both deliverables. Headings are final; body text is to be written.
**Companion document:** `UrbanRide_Architecture_Brief.md` — every section below cites where to pull content from.
**Deadline:** Midnight, Sunday 13 September 2026 (target submission 10:00pm)

---

## How to use this template

- Each section lists **Owner**, **Source** (section of the research brief), and **What goes here**
- `[[ ... ]]` marks a placeholder to replace
- `⬛ DIAGRAM` marks where a figure must be inserted
- Length guidance is a target, not a rule — but the total ADD should land around 15–20 pages
- **Do not renumber sections.** M5 assembles from these exact headings

---
---

# PART A — ARCHITECTURE DESIGN DOCUMENT

---

## Title page

| Field | Content |
|---|---|
| Title | UrbanRide — Architecture Design Document |
| Subtitle | Scalable Microservices Backend for a Global Ride-Hailing Platform |
| Module | `[[ module code / name ]]` |
| Group | `[[ group name / number ]]` |
| Members | `[[ 5 names + index numbers ]]` |
| Date | 13 September 2026 |

---

## Table of contents

*Auto-generate. Confirm it rebuilds after the final edit — a stale TOC is an easy mark to lose.*

---

## 1. Executive Summary

**Owner:** M1 · **Source:** Brief §1 · **Length:** ~1 page

**What goes here:**
- One paragraph restating the problem and the four constraints (1M rides/day, <500ms, burst tolerance, <10 LKR/ride)
- The three headline findings:
  1. We are ~40–50x smaller than Uber, so we adopt their ideas and reject their implementations
  2. Cloud infrastructure lands at ~0.17 LKR/ride — under 2% of budget
  3. Third-party per-request APIs are the real budget risk (Google Maps ≈ 64 LKR/ride)
- One sentence naming the headline architectural approach: event-driven microservices, H3 geospatial matching, self-hosted routing
- **Do not** open with "we are 65x under budget" — frame per Brief §6.7

---

## 2. Introduction & Scope

**Owner:** M1 · **Length:** ~0.5 page

**2.1 Problem statement** — what UrbanRide is and what the backend must do

**2.2 Scope and assumptions** — state explicitly:
- Single-region deployment with documented multi-region roadmap `[[ confirm team decision ]]`
- Cloud provider and region: `[[ decision ]]`
- **Cost interpretation:** "We interpret the 10 LKR target as cloud infrastructure and platform operating cost, excluding payment processing fees, driver payouts and customer acquisition." *(Brief §6.8)*

**2.3 Out of scope** — mobile app internals, driver onboarding/KYC, fraud ML models, customer support tooling

---

## 3. Requirements & Scale Analysis

**Owner:** M2 · **Source:** Brief §2.1, §3 · **Length:** ~1.5 pages

**3.1 Functional requirements** — brief list of core capabilities

**3.2 Non-functional requirements** — table of the four constraints with targets

**3.3 Derived scale figures** — **this table is load-bearing; every later decision references it**

| Quantity | Derivation | Value |
|---|---|---|
| `[[ fill from Brief §3.1 — full table ]]` | | |

**3.4 Scale comparison to production systems** — the Uber/UrbanRide ratio table (Brief §3.2). This is the justification for every simplification made later, so it must appear early.

**3.5 Key observations** — three short paragraphs:
- Transactional workload is small (~12 writes/sec)
- Location workload is high-operation but low-volume (~3.75 MB/s)
- Implication: correct data structures matter more than large hardware

---

## 4. Domain & Service Decomposition

**Owner:** M1 · **Source:** Brief §5.1, §5.2 · **Length:** ~3 pages · **Rubric: 25%**

**4.1 Bounded contexts** — brief DDD framing; how the domain splits

**4.2 Service catalogue** — the nine services

| Service | Responsibility | Why separate | Data store |
|---|---|---|---|
| `[[ fill from Brief §5.1 ]]` | | | |

**4.3 Decomposition rationale** — call out the non-obvious splits, especially:
- **Location Ingestion vs Driver Service** — opposite write profiles; combining them means paying durable-DB prices for disposable GPS data
- **Billing isolated** — separate blast radius for money

**4.4 Inter-service communication**

| Path | Protocol | Reasoning |
|---|---|---|
| `[[ fill from Brief §5.2 ]]` | | |

State the governing rule explicitly: *synchronous only where the caller cannot proceed without the answer; everything else is an event.*

**4.5 Data ownership & isolation** — database-per-service; no shared schemas; no cross-service joins

⬛ **DIAGRAM 1 — C4 Level 1: System Context**
*Owner: M1. Shows: UrbanRide as one box; external actors = Rider, Driver, Payment Gateway, SMS Provider, Push Notification Service, OpenStreetMap data source. Keep it deliberately simple — this diagram is for non-technical stakeholders.*

⬛ **DIAGRAM 2 — C4 Level 2: Container**
*Owner: M1. Shows: all 9 services + API Gateway + Kafka + Redis + PostgreSQL instances + OSRM + S3. Label every arrow with its protocol (gRPC / REST / WebSocket / Kafka topic). This is the most important diagram in the document.*

---

## 5. Performance & Latency Design

**Owner:** M2 · **Source:** Brief §5.3, §5.3.1, §5.4 · **Length:** ~3.5 pages · **Rubric: 25%**

**5.1 Geospatial indexing strategy**
- Why H3; hexagons vs squares (equidistant neighbours)
- Resolution choice (res-8, ~0.74 km²) and why
- Redis key structure and TTL-based expiry
- K-ring expansion logic

**5.2 Matching query flow** — numbered steps with per-step latency

**5.3 Latency budget**

| Step | Budget |
|---|---|
| `[[ fill from Brief §5.3 ]]` | |
| **Total / headroom to 500ms** | |

*State the headroom explicitly — it means a 2x degradation still meets SLA.*

**5.4 Trade-off: approximation vs exactness** — H3 is pre-computed approximation; boundary drivers may be missed; K-ring(2) mitigates; exact search is O(n) and unaffordable

**5.5 Two-stage matching** — H3 candidate generation → road-network ETA re-ranking. Reference Grab's rejection of straight-line nearest.

**5.6 Write-heavy ingestion path**
- Kafka as decoupling buffer
- Topic design table (topic / producer / consumers / partitions / retention)
- Partition key = H3 cell ID, and why (ordering per geography, windowed aggregation)

**5.7 Backpressure & burst absorption** — *the 5x spike answer.* System degrades in **freshness**, not availability. Contrast with direct-write architecture failure mode.

**5.8 Protecting the Routing/ETA service** — three layers (Brief §5.3.1):
1. OSRM `table` endpoint instead of N× `route` — the big win
2. Grid-snapped cache (H3 res-9 keys), not raw coordinates
3. Haversine fallback

⬛ **DIAGRAM 3 — C4 Level 3: Component (Matching Engine)**
*Owner: M2. Shows internals: request handler → H3 indexer → Redis candidate fetcher → ETA client (with cache + fallback) → ranking module → assignment CAS module. Include the fallback path.*

⬛ **DIAGRAM 4 — Sequence diagram: ride request end-to-end**
*Owner: M2. Rider → Gateway → Matching → Redis → OSRM → Trip → Billing → Notifications. Annotate with the latency budget numbers. Optional but high value — makes the latency argument visual.*

---

## 6. Data Design & Consistency

**Owner:** M3 · **Source:** Brief §5.5, §5.5.1, §5.6, §5.6.1, §5.7 · **Length:** ~3 pages · **Rubric: part of 25%**

**6.1 Storage selection per service**

| Data | Store | Consistency | Reasoning |
|---|---|---|---|
| `[[ fill from Brief §5.5 ]]` | | | |

State the principle: *pick per service; do not uniformly pick one.*

**6.2 CAP positioning** — which services are CP, which are AP, and why. Cite Uber precedent (Ringpop is AP; surge favours freshness over consistency).

**6.3 Storage tiering strategy** *(explicit rubric requirement)*
- Hot / Warm / Cold table
- Volume justification: ~730 GB/year of trip records
- **Mechanism:** monthly partitioning + partition-drop archival to Parquet on S3
- Why not CDC: trip records are immutable; `DROP` is metadata-only vs VACUUM pressure from row-wise `DELETE`

**6.4 Distributed transactions — the Saga pattern** *(explicit rubric requirement)*
- Why a single ACID transaction cannot span services
- Orchestration vs choreography; our hybrid choice and justification
- Trip state machine diagram
- Booking saga steps + compensations table
- Pivot transaction identification
- **Idempotency requirement** — every step keys on `trip_uuid`

**6.5 Concurrency: the double-booking problem** — atomic Redis `SET NX` rather than a DB row lock; loser re-queries. *This is how lock contention is designed out.*

**6.6 Surge quote pinning** — 60-second pinned quote so displayed fare = charged fare

⬛ **DIAGRAM 5 — Trip state machine**
*Owner: M3. States: Requested → Matched → DriverEnRoute → InProgress → Completed, plus Cancelled and PaymentFailed branches.*

⬛ **DIAGRAM 6 — Saga flow with compensations**
*Owner: M3. Happy path across services plus the compensating transactions on failure. Mark the pivot transaction.*

---

## 7. Scalability & Resiliency Blueprint

**Owner:** M3 · **Source:** Brief §5.8 · **Length:** ~2 pages · **Rubric: feeds Panel Defense 15%**

*All four named mechanisms must appear explicitly — the assignment lists them by name.*

**7.1 Circuit breakers** — Envoy sidecar outlier detection; service-mesh layer not application code. Cite Lyft's rationale (identical networking code copy-pasted across services became unmaintainable).

**7.2 Rate limiters** — token bucket per rider/driver/IP at edge; per-service quotas in mesh

**7.3 Backpressure** — Kafka consumer lag → autoscale; bounded queues; load shedding order at the gateway (shed fare estimates before ride requests)

**7.4 Dead-letter queues** — retry with exponential backoff → `.dlq` topic; failed messages never block live traffic

**7.5 Additional patterns** — graceful degradation, timeouts everywhere, bulkheads

**7.6 Failure scenario walkthroughs** — short paragraph each:
- 5x traffic spike
- Redis cluster failure
- Network partition between services
- Spot instance reclaim on connection-holding services

⬛ **DIAGRAM 7 — Resilience layers (optional)**
*Owner: M3. Where each mechanism sits in the request path. Only build if time allows.*

---

## 8. Infrastructure & Cost

**Owner:** M4 · **Source:** Brief §6 (all) · **Length:** ~3.5 pages · **Rubric: 20%**

**8.1 Budget in real terms** — 10 LKR → USD conversion → daily / monthly / annual ceiling. State the FX rate and date used.

**8.2 The third-party API finding** — **lead with this**
- Google Maps per-ride cost table
- The Route Matrix element-billing detail (this is what makes it catastrophic)
- Result: ~64 LKR/ride = 6.4x over budget
- Conclusion: self-hosted routing is mandatory, not an optimization
- Note Grab's precedent (Pharos on OSM graphs)

**8.3 Infrastructure cost model**

| Component | Sizing rationale | Monthly (USD) |
|---|---|---|
| `[[ fill from Brief §6.3 ]]` | | |

**8.4 Instance sizing rationale** *(explicit rubric requirement)* — a short paragraph per major component explaining *why that size*, tied back to the §3.3 scale figures

**8.5 Compute placement: spot vs on-demand**
- What runs on spot and what does not
- **The WebSocket exception** — a service holding 75k persistent connections is not stateless; it runs on-demand. Graceful drain + jittered client reconnect as defence in depth.
- Honest counter-argument: 41% of workloads lose money on spot once interruption costs are counted; our defence is placement discipline

**8.6 Autoscaling triggers** *(explicit rubric requirement)*

| Service | Scale-out trigger | Scale-in | Min/Max |
|---|---|---|---|
| `[[ fill from Brief §6.6 ]]` | | | |

Note the deliberately slow scale-in cooldowns and why (prevents thrashing during oscillating weather demand).

**8.7 Notification cost strategy** — push-first, SMS for login OTP only. Show the contrast: 2 SMS/ride would be 2 LKR/ride = 20% of budget, ~13x all server costs.

**8.8 Result & scenario comparison**

| Scenario | LKR/ride | vs budget |
|---|---|---|
| `[[ fill from Brief §6.5 ]]` | | |

**8.9 Cost-optimization levers summary** — table of lever / application / expected saving

⬛ **DIAGRAM 8 — Cost breakdown chart**
*Owner: M4. Bar or pie of monthly spend by component. Makes the point that routing/egress/tiles dominate, not compute.*

---

## 9. Trade-Off Summary

**Owner:** M3 · **Source:** Brief §7 · **Length:** ~1 page

Single table. **Every row must name a real loss** — architectures without downsides read as wish lists.

| Decision | We chose | We gave up | Why |
|---|---|---|---|
| `[[ fill from Brief §7 — all rows ]]` | | | |

---

## 10. Risks & Future Work

**Owner:** M1 · **Length:** ~0.5 page

**10.1 Key risks** — self-hosted routing ops burden; Redis as single point of matching failure; assumptions requiring validation

**10.2 Future work** — multi-region active-active; ML-based matching (Grab's 40+ factors); traffic-aware ETA; driver preference modelling

---

## 11. References

**Owner:** M5 · **Source:** Brief §11

Use a consistent citation style. Include Uber engineering sources, Grab Pharos, Lyft/Envoy, H3 documentation, Saga pattern references, Google Maps pricing page.

---

## Appendix A — Assumptions Register

**Owner:** M4

Every assumption with its value and status. Anything still unverified must be marked as such rather than presented as fact.

| Assumption | Value | Source / status |
|---|---|---|
| FX rate LKR/USD | `[[ ]]` | `[[ date checked ]]` |
| Average ride duration | `[[ ]]` | Estimated |
| Rides per driver per day | `[[ ]]` | Estimated |
| Bulk SMS rate | `[[ ]]` | `[[ verify with local provider ]]` |
| GPS ping interval | 4s | Industry standard (Uber) |
| Cloud region pricing basis | `[[ ]]` | `[[ date checked ]]` |

---
---

# PART B — PRESENTATION DECK

**Owner:** M5 (build) · **Total: 10 minutes, strict**

**Design rules:**
- Every slide carries **one** idea
- Diagrams get the full slide — do not pair a C4 diagram with bullet text
- Minimal text; the speaker carries the detail
- Numbers on slides **must** match the ADD exactly

---

## Slide plan

| # | Slide title | What goes on it | What the speaker explains | Time |
|---|---|---|---|---|
| **1** | UrbanRide — Architecture Overview | Title, group, members. Optionally the four constraints as small text | Nothing beyond a one-line framing. Do not burn time here | 0:20 |
| **2** | The Numbers That Drive Everything | Scale derivation table (condensed) + the Uber comparison ratios | 1M rides/day → 12 rides/sec, 19k location writes/sec. **We are ~50x smaller than Uber.** This sets up every simplification that follows | 0:50 |
| **3** | System Context | ⬛ **C4 Level 1 diagram**, full slide | Who uses the system, what it depends on externally. Keep it fast — this is orientation, not content | 0:40 |
| **4** | Service Decomposition | 9 services grouped by bounded context; no diagram, just clean grouping | Why these boundaries. Highlight the Location Ingestion vs Driver Service split as the non-obvious one | 1:10 |
| **5** | Container Architecture | ⬛ **C4 Level 2 diagram**, full slide | Walk the request path across the diagram. Name the protocols and why each was chosen | 1:20 |
| **6** | Matching: Sub-Second Geospatial | ⬛ **C4 Level 3 (Matching Engine)** or the sequence diagram + latency budget table | H3 + K-ring → ~30 candidates in 2ms → ETA re-rank. **Total ~210ms against a 500ms budget.** Name the approximation trade-off | 1:30 |
| **7** | Handling the Write Firehose & 5x Spikes | Simple flow: GPS → Kafka → consumers, with the backpressure mechanism annotated | Kafka absorbs the burst; producers never block; lag grows and drains. **Degrades in freshness, not availability.** Cover DLQs and circuit breakers here | 1:15 |
| **8** | Data Consistency & the Saga | Trip state machine + saga compensation table (condensed) | DB-per-service means no distributed ACID. Orchestrated saga with compensations. Idempotency on `trip_uuid`. Mention the CAS-based double-booking fix | 1:00 |
| **9** | **The Cost Trap** | Google Maps per-ride cost table. Big, bold, one number: **64 LKR/ride** | This is the slide that wins the cost section. Naive integration is 6.4x over budget, driven by Route Matrix element billing. Self-hosted OSRM is mandatory | 1:15 |
| **10** | Cost Result | Infrastructure breakdown + scenario comparison table | ~0.17 LKR/ride = under 2% of ceiling. **Frame carefully:** budget is not the binding constraint; vendor API pricing was. Headroom is spent on reliability | 0:50 |
| **11** | Trade-Offs | The trade-off summary table (condensed to ~6 strongest rows) | Every decision named its cost. Close on this — it sets up Q&A well | 0:30 |
| | | | **Total** | **~10:00** |

## Notes on the deck

**Slide 9 is your strongest slide.** It is arithmetic, not assertion, and it demonstrates cost reasoning no other group is likely to have done. Give it the space.

**Slides 3, 5 and 6 carry the C4 requirement.** The rubric names "standardised C4 diagrams" explicitly — all three levels must be visibly present.

**Slide 2 is doing structural work.** It pre-empts "why didn't you use Ringpop / uReplicator / X?" before it is asked, by establishing the scale gap early.

**If you must cut:** merge slides 10 and 11, or cut slide 11 and fold the two strongest trade-offs into the closing remarks. Do not cut 5, 6 or 9.

**Backup slides** (after the end, not counted in the 10 minutes) — build only if time allows:
- Full autoscaling trigger table
- Full trade-off table
- Failure scenario walkthroughs
- Assumptions register

These let you answer a panel question by jumping to a prepared slide, which reads very well.

---

## Pre-submission checklist

**Owner: M1 (content) + M5 (production)**

- [ ] All nine services named identically in text, all diagrams, and deck
- [ ] Every cost figure in the deck matches the ADD
- [ ] All three C4 levels present and labelled as C4
- [ ] All four resilience mechanisms explicitly named: circuit breakers, rate limiters, backpressure, DLQs
- [ ] Saga pattern explicitly named and diagrammed
- [ ] Storage tiering explicitly covered
- [ ] Autoscaling triggers table present
- [ ] Instance sizing rationale present
- [ ] Assumptions register complete; nothing unverified presented as fact
- [ ] TOC regenerated after final edit
- [ ] Exported files opened and visually checked — diagrams not pixelated, tables not broken across pages
- [ ] Both files named per submission requirements
- [ ] Submitted by 10:00pm
