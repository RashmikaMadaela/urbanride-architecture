# Decisions & Canonical Names

**Owner:** M1 · **Status:** Locked as of Sat 12 Sept, kickoff call

This file is the single source of truth for anything the whole team has to agree on.
If something here is wrong, tell M1 — **do not** just change it in your own section.

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
| D1 | Cloud provider | `[[ AWS ]]` | All research and pricing is AWS-based |
| D2 | Region | `[[ ap-south-1 (Mumbai) ]]` | Closest to Sri Lanka; ~10–15% pricier than us-east-1 |
| D3 | Deployment topology | `[[ Single-region ]]` | Multi-region roughly doubles cost for zero marks; documented as future work |
| D4 | C4 Component diagram subject | `[[ Matching Engine ]]` | Most technically interesting; showcases the H3 + ETA two-stage design |
| D5 | Cost scope | Cloud infrastructure only | See wording below |
| D6 | Diagramming tool | `[[ decide at kickoff ]]` | All three C4 diagrams must look visually consistent |

### D5 — exact wording to use

> We interpret the 10 LKR target as cloud infrastructure and platform operating cost,
> excluding payment processing fees, driver payouts, and customer acquisition.

M1 puts this in `add/02-introduction-scope.md`. M4 references it in §8.1.
**Don't paraphrase it differently in two places.**

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
| Avg ride duration | `[[ 20 min ]]` | **Assumed** |
| Peak concurrent online drivers | `[[ ~75,000 ]]` | Derived |
| GPS ping interval | 4 sec | Industry standard (Uber) |
| Peak location writes/sec | `[[ ~19,000 ]]` | Derived |
| Design ceiling | `[[ 25,000 /sec ]]` | +30% headroom |
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