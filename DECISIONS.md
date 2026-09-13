# Decisions & Canonical Names

**Owner:** M1 · **Status:** Locked as of Sat 12 Sept, kickoff call

This file is the single source of truth for anything the whole team has to agree on.
If something here is wrong, tell M1. **Do not** just change it in your own section.

---

## Canonical service names

**Use these strings verbatim.** In prose, in diagrams, in slides, in table headers.
If your diagram says "Trip Service" and the text says "Trip Management Service",
the panel notices, and it reads as five people who never spoke to each other.

| # | Service name | Owner of its description |
|---|---|---|
| 1 | `API Gateway` | M1 |
| 2 | `Rider Service` | M1 |
| 3 | `Driver Service` | M1 |
| 4 | `Location Ingestion Service` | M1 / M2 |
| 5 | `Matching Engine` | M2 |
| 6 | `Routing Service` | M2 |
| 7 | `Trip Management Service` | M3 |
| 8 | `Surge Pricing Service` | M3 |
| 9 | `Billing Service` | M3 |
| 10 | `Notification Service` | M3 |

**Ten services, not nine.** Routing is separate because self-hosted OSRM is one of our
strongest cost arguments and it needs to be visible on the container diagram.

### Infrastructure component names

| Component | Write it as |
|---|---|
| Message broker | `Kafka` |
| Geospatial cache / in-memory store | `Redis` |
| Relational DB | `PostgreSQL` (not "Postgres", not "psql") |
| Object storage | `S3` |
| Service mesh sidecar | `Envoy` |
| Geospatial index | `H3` |
| Routing engine | `OSRM` |

---

## Locked decisions

| # | Decision | Choice | Rationale |
|---|---|---|---|
| D1 | Cloud provider | AWS | All research and pricing is AWS-based |
| D2 | Region | ap-south-1 (Mumbai) | Closest to Sri Lanka; ~10–15% pricier than us-east-1 |
| D3 | Deployment topology | Single-region | Multi-region roughly doubles cost for zero marks; documented as future work |
| D4 | C4 Component diagram subject | Matching Engine | Most technically interesting; showcases the H3 + ETA two-stage design |
| D5 | Cost scope | Cloud infrastructure only | See wording below |
| D6 | Diagramming tool | Graphviz `.dot` | Sources in `diagrams/source/`, rendered to PNG at 200 DPI. Three diagrams already exist in this format, and a mixed toolchain would break the visual consistency `diagrams/README.md` requires |

### D5: exact wording to use

> We interpret the 10 LKR target as cloud infrastructure and platform operating cost,
> excluding payment processing fees, driver payouts, and customer acquisition.

M1 puts this in `add/02-introduction-scope.md`. M4 references it in §8.1.
**Don't paraphrase it differently in two places.**

### D6: how to render a diagram

```bash
dot -Tpng -Gdpi=200 diagrams/source/<name>.dot -o diagrams/<name>.png
```

Install with `sudo apt install graphviz`. Copy the `graph`/`node`/`edge` attribute block from an
existing `.dot` file rather than inventing a new palette. Commit the `.dot` source next to the PNG.

---

## Name drift found in committed work

Caught during the M1 consistency pass on Sun 13 Sept. These strings are **wrong**. They came from
the research brief, which predates the canonical list above. Fix them in place; do not introduce
a second spelling.

| Wrong string | Canonical | Where it appears | Owner |
|---|---|---|---|
| `Billing & Payments` | `Billing Service` | `diagrams/source/saga-01-booking.dot` | M3 |
| `Notifications` | `Notification Service` | `diagrams/source/saga-01-booking.dot`, `add/05-performance-latency.md` | M3, M2 |
| `API Gateway / Edge` | `API Gateway` | `diagrams/source/resilience-01-layers.dot` | M3 |
| `Trip Management` | `Trip Management Service` | `add/06-data-design.md`, `add/07-resiliency.md` | M3 |
| `Routing/ETA`, `Routing / ETA` | `Routing Service` | `add/05-performance-latency.md`, `add/07-resiliency.md` | M2, M3 |
| `Location Ingestion` | `Location Ingestion Service` | `add/06-data-design.md` | M3 |
| `Surge Pricing` | `Surge Pricing Service` | `add/06-data-design.md` | M3 |
| "nine services" | "ten services" | `README.md` checklist | M1 |

Re-render any `.dot` you edit, because the PNG is what the panel sees.

---

## Shared numbers

M2 owns these (they live in `add/03-requirements-scale.md` §3.3). M4's entire cost model
is derived from them.

**If any of these change, M2 tells M4 and M1 in the group chat immediately.**

| Figure | Value | Status |
|---|---|---|
| Completed rides/day | 1,000,000 | Given |
| Avg ride request rate | ~12 /sec | Derived |
| Peak ride request rate | ~60 /sec | Derived |
| Avg ride duration | 20 min | **Assumed** |
| Peak concurrent online drivers | ~75,000 | Derived |
| GPS ping interval | 4 sec | Industry standard (Uber) |
| Peak location writes/sec | ~19,000 | Derived |
| Design ceiling | 25,000 /sec | +30% headroom |
| FX rate LKR/USD | `[[ M4 to verify ]]` | ⚠️ Unverified |
| Bulk SMS rate (LKR) | `[[ M4 to verify ]]` | ⚠️ Unverified |

---

## Still open

| # | Question | Who decides | By when |
|---|---|---|---|
| O1 | `[[ ... ]]` | | |

Move anything resolved up into "Locked decisions" and delete the row.

---

## Change log

| When | What changed | Who |
|---|---|---|
| Sat 12 Sept | Initial decisions locked at kickoff | M1 |
| Sun 13 Sept | D6 locked: Graphviz `.dot` at 200 DPI. Derived shared numbers unwrapped; FX rate and SMS rate still open for M4 | M1 |
| Sun 13 Sept | Name drift from the research brief recorded (see section above). M3 and M2 to fix in their own files | M1 |
| Sun 13 Sept 18:30 | **Name drift resolved by M1** under the final-say rule. All eight canonical names now used verbatim in every section and every diagram. M3's and M2's `.dot` sources were edited and re-rendered; M2's §5.8 heading and M3's §7.5 prose corrected. Nothing was rewritten beyond the name strings | M1 |
| Sun 13 Sept 18:30 | §3.1 said push notifications "with SMS fallback" at trip state transitions, contradicting §8.7, §9 and §4.2 (SMS is OTP-only, and per-ride SMS would cost 2 LKR/ride = 20% of budget). Corrected to OTP-only with a pointer to §8.7 | M1 |
| Sun 13 Sept 18:30 | M2's `c4-03-component-matching.dot` and `seq-01-ride-request.dot` were committed but never rendered, and `c4-03` is rubric-required. Both rendered to PNG at 200 DPI from M2's unmodified sources | M1 |
| Sun 13 Sept 18:30 | §11 references drafted by M1 to unblock assembly. **M5 must verify every URL resolves** before submission | M1 |