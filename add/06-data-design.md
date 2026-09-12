## 6. Data Design & Consistency

<!-- OWNER: M3 | SOURCE: Brief §5.5, §5.5.1, §5.6, §5.6.1, §5.7 -->
<!-- TARGET: ~3 pages | RUBRIC: part of 25% -->

### 6.1 Storage selection per service

| Data | Store | Consistency | Reasoning |
|---|---|---|---|
| | | | |

<!-- State the principle: pick per service; do not uniformly pick one. -->

### 6.2 CAP positioning

<!-- Which services are CP, which are AP, and why.
     Cite Uber precedent: Ringpop is AP; surge favours freshness over consistency. -->

[[ WRITE HERE ]]

### 6.3 Storage tiering strategy

<!-- EXPLICIT RUBRIC REQUIREMENT -->

| Tier | Contents | Store | Access pattern | Cost |
|---|---|---|---|---|
| | | | | |

<!-- Volume justification: ~730 GB/year of trip records.
     MECHANISM: monthly partitioning + partition-drop archival to Parquet on S3.
     Why not CDC: trip records are immutable; DROP is metadata-only vs
     VACUUM pressure from row-wise DELETE. -->

[[ WRITE HERE ]]

### 6.4 Distributed transactions — the Saga pattern

<!-- EXPLICIT RUBRIC REQUIREMENT -->
<!-- Why single ACID cannot span services; orchestration vs choreography and our
     hybrid choice; booking saga steps + compensations; pivot transaction;
     idempotency on trip_uuid -->

[[ WRITE HERE ]]

| # | Step | Service | Compensation on failure |
|---|---|---|---|
| | | | |

### 6.5 Concurrency: the double-booking problem

<!-- Atomic Redis SET NX rather than a DB row lock; loser re-queries.
     This is how lock contention is designed out. -->

[[ WRITE HERE ]]

### 6.6 Surge quote pinning

<!-- 60-second pinned quote so displayed fare = charged fare -->

[[ WRITE HERE ]]

---

![Trip state machine](../diagrams/state-01-trip-lifecycle.png)

**Figure 5 — Trip lifecycle state machine.** [[ caption ]]

<!-- DIAGRAM 5 | OWNER: M3 | FILE: diagrams/state-01-trip-lifecycle.png
     Requested -> Matched -> DriverEnRoute -> InProgress -> Completed,
     plus Cancelled and PaymentFailed branches. -->

---

![Booking saga with compensations](../diagrams/saga-01-booking.png)

**Figure 6 — Booking saga and compensating transactions.** [[ caption ]]

<!-- DIAGRAM 6 | OWNER: M3 | FILE: diagrams/saga-01-booking.png
     Happy path across services plus compensations on failure.
     Mark the pivot transaction. -->
