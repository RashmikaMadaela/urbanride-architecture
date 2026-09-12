# UrbanRide — Architecture Research & Design Brief

**Status:** Working document / initial direction for team review
**Prepared:** 12 September 2026
**Submission deadline:** Midnight, Sunday 13 September 2026
**Audience:** Project team members

---

## 0. How to use this document

This is **not** the final Architecture Design Document (ADD). It is the research and reasoning that the ADD should be built on top of. It captures:

- What the assignment actually asks for, mapped to the grading rubric
- The scale analysis that drives every technical decision
- How Uber, Grab and Lyft solved these problems in production
- What we propose to adopt, what we propose to reject, and why
- A costed infrastructure model against the 10 LKR/ride constraint
- Prepared answers for the Panel Q&A

**Sections 7 and 8 need team decisions.** Please read those and come with opinions.

Everything here is an estimate built from published sources and standard sizing heuristics. Numbers marked ⚠️ should be verified before they go in the final submission.

---

## 1. Executive summary

We are designing a ride-hailing backend for 1M completed rides/day, sub-500ms matching latency, 5x burst tolerance, and a cost ceiling of 10 LKR per completed ride.

**Three findings shape the entire design:**

**Finding 1 — We are roughly 40x smaller than Uber.** Uber handles over 1 million driver location updates per second. We need about 19,000/sec. This means copying Uber's architecture wholesale would be serious over-engineering. Our strongest position with the panel is to show we understood *why* each Uber component exists and deliberately simplified where our scale doesn't justify it.

**Finding 2 — Cloud infrastructure is not the budget risk.** Our modelled infrastructure cost lands around **0.17 LKR per ride — about 1.7% of the 10 LKR ceiling.** At 12 rides/sec, the transactional workload is genuinely small.

**Finding 3 — Third-party per-request APIs are the budget risk.** A naive Google Maps integration costs approximately **64 LKR per ride — 6.4x over the entire budget**, driven almost entirely by Route Matrix element-based billing when ranking driver candidates. Self-hosting routing on OpenStreetMap data is therefore **mandatory, not an optimization.**

**Our headline argument to the panel:** cost optimization in this system is not about shaving instance hours. It is about eliminating per-request vendor pricing from the hot path. Everything else is rounding error.

---

## 2. What the assignment requires

### 2.1 The constraints

| Constraint | Target |
|---|---|
| Throughput | 1,000,000 completed rides/day |
| Latency | < 500ms for high-frequency transactions |
| Burst tolerance | Absorb sudden surges (weather, events) — panel will test 5x |
| Cost | < 10 LKR per completed ride |

### 2.2 Required deliverables

**1. Architecture Design Document (ADD)**
- Domain & service decomposition, including inter-service protocols (gRPC vs REST vs WebSockets)
- C4 model diagrams — Context, Container, Component levels
- Scalability & resiliency blueprint — circuit breakers, rate limiters, backpressure, dead-letter queues
- Infrastructure & cost breakdown — resource usage, instance sizing rationale, autoscaling triggers, storage tiering

**2. Presentation deck** — strictly 10 minutes, followed by 10 minutes of panel Q&A

### 2.3 Rubric mapping — where the marks are

| Category | Weight | What they want | Where we cover it |
|---|---|---|---|
| Microservice & Data Design | 25% | Bounded contexts, DB isolation, Saga pattern | §5.1, §5.5, §5.6 |
| Performance & Latency | 25% | Geospatial querying, caching, write-heavy ingestion | §5.3, §5.4 |
| Cost Optimization | 20% | Autoscaling, spot instances, data tiering | §6 |
| Presentation Clarity | 15% | C4 diagrams, 10-min adherence | To be built |
| Panel Defense | 15% | Fault tolerance, CAP trade-offs | §9 |

**Note:** Microservice/Data Design and Performance/Latency together are 50% of the grade. These deserve the most depth in the ADD.

---

## 3. Scale analysis — the numbers that drive everything

Every design decision below traces back to these figures. **Put this table in the deck.** It's the difference between a design and a wish list.

### 3.1 Derivation

| Quantity | Derivation | Value |
|---|---|---|
| Completed rides/day | Given | 1,000,000 |
| Average ride request rate | 1M ÷ 86,400s | **~12 /sec** |
| Peak ride request rate | 5x burst assumption | **~60 /sec** |
| Ride duration (assumed) | Typical urban average ⚠️ | ~20 min |
| Total ride-minutes/day | 1M × 20 | 20,000,000 |
| Average concurrent active trips | 20M ÷ 1,440 min | **~14,000** |
| Peak concurrent active trips | ~2x average | **~30,000** |
| Active drivers needed | 1M rides ÷ ~16 rides per driver-day | **~60,000** |
| Peak concurrent online drivers | Incl. idle drivers | **~75,000** |
| GPS ping interval | Industry standard (Uber uses 4s) | 4 sec |
| **Peak location writes/sec** | 75,000 ÷ 4 | **~19,000 /sec** |
| Design ceiling (headroom) | +30% | **25,000 /sec** |
| Location data volume | 25,000/s × ~150 bytes | **~3.75 MB/s** |

### 3.2 What this tells us

**The transactional workload is small.** 12 writes/sec to the trip database is nothing. A single well-configured PostgreSQL instance handles this with enormous headroom. We should say this out loud rather than pretending we need exotic storage.

**The location workload sounds large but isn't.** 19,000 writes/sec is a lot of *operations* but only 3.75 MB/s of *data*. It needs the right data structure (in-memory), not enormous hardware.

**The comparison that frames our whole approach:**

| | Uber | UrbanRide | Ratio |
|---|---|---|---|
| Location updates/sec | 1,000,000+ | ~19,000 | **~53x smaller** |
| Kafka messages/day | Trillions | ~1.6 billion | **~1000x smaller** |
| Drivers | ~5,000,000 | ~75,000 | **~66x smaller** |

This is the justification for every simplification we make. It is also our best answer to "why didn't you use X?"

---

## 4. Research — how the production systems work

### 4.1 Uber

**Geospatial indexing: S2, then H3**

Uber originally used Google's S2 library, which divides map data into tiny cells each with a unique ID, making it easy to spread data across a distributed system. They later built and open-sourced **H3**, which partitions the Earth into hexagonal cells at multiple resolutions, encoding each cell as a compact 64-bit identifier. Each parent hexagon subdivides into 7 children.

The matching query in practice:
1. Convert rider coordinates to an H3 index (resolution 8, cells ~0.74 km²)
2. Compute K-Ring(1) → 7 hexagonal cells
3. Look up all drivers in those cells from Redis
4. If insufficient candidates, expand to K-Ring(2) → 19 cells

The effect: instead of computing distance to every driver, only a handful of cells are consulted — **millions of comparisons reduced to dozens.**

**Why hexagons beat squares** (likely panel question): all six neighbours of a hexagon are equidistant from the centre. A square grid has 4 edge-neighbours and 4 diagonal-neighbours at different distances, so "expand the search radius" is a non-uniform operation.

**Dispatch (DISCO)**

DISCO's stated goals: reduce extra driving, minimise waiting time, minimise overall ETA. The cell ID doubles as the **sharding key** — driver locations are updated using cell ID as shard key, and cell responsibilities are distributed across servers via consistent hashing. Candidates are then passed to an ETA service that computes distance **by the road network, not geographically**, and the ETA-sorted list is returned.

**Ringpop**

Because dispatch is stateful, stateless scaling doesn't work. Uber built **Ringpop**: a consistent hash ring with a gossip protocol (SWIM), implementing application-layer sharding. In CAP terms **Ringpop is an AP system, trading consistency for availability.** Every node is externally equivalent — a request lands on any healthy node, which forwards it to the correct node via hash ring lookup.

> **Critical design detail worth stealing:** the driver location index lives **entirely in memory with no persistence**. If a node crashes, drivers simply re-register their locations within 4 seconds. Uber treats driver location as *disposable data*.

**Streaming (Kafka)**

Kafka is the transport for streaming data to both batch and real-time systems, propagating event data from rider and driver apps. On failure handling: after retries, messages are published to a **dead letter topic**, where they can be purged or retried on demand — so unprocessed messages remain separate and cannot impede live traffic.

Their stream-processor choice is worth citing for our backpressure section: **Storm** performed poorly under backpressure with a large backlog, taking *several hours* to recover, whereas **Flink** took *20 minutes*. Spark consumed 5–10x more memory for equivalent workloads.

**Surge pricing — the clearest CAP trade-off in the system**

Surge is a streaming pipeline computing pricing multipliers **per hexagon-area geofence** over a time window. It ingests from Kafka, runs an ML algorithm in Flink, and writes results to a key-value store for fast lookup.

The documented trade-off: surge pricing **favours data freshness and availability over data consistency**. Late-arriving messages simply do not contribute to the computation. This is reflected in configuration — the Kafka cluster is tuned for **higher throughput but not lossless guarantee**.

*This is the single best example in the whole system of deliberately choosing to lose data. Memorise it for the Q&A.*

**Storage (Schemaless / Docstore)**

Uber's in-house databases are built on MySQL, spanning thousands of clusters and tens of petabytes. Architecture: a stateless query engine, a stateful storage engine, and a control plane. Data is sharded across partitions, each with one leader and two followers coordinated via **Raft** for strong consistency.

Origin story worth citing: in early 2014 they were running out of database space due to trip growth and realised the infrastructure would fail by year-end because they couldn't store enough trip data in a single Postgres instance. *Note this was a **capacity** problem, not a throughput problem — which is why our tiering strategy matters more than our write path.*

**Trip lifecycle (Cadence)**

Uber built **Cadence**, an open-source workflow orchestration engine providing durable state persistence and automatic retries until success or timeout. The trip runs as a long-lived workflow instance with deterministic state transitions: `requested → matched → arriving → on-trip → completed`. It has built-in support for exponential activity retries and **simplifies coding of compensation logic** — i.e. it is effectively a Saga orchestrator.

### 4.2 Grab — the closest analogue to our scale and market

Grab operates at **more than 3 million rides per day** in Southeast Asia — same order of magnitude as our target, in cost-sensitive markets comparable to ours.

**They explicitly reject "nearest driver wins."** Grab locates driver-partners and passengers via geohashes, then narrows the candidate list by **estimated time of arrival**, and further matches based on the types of bookings drivers tend to accept or decline. **Over 40 factors** are weighed in the final allocation.

**Pharos** — their newer system — is a scalable in-memory solution supporting real-time K-nearest search **by driving distance or ETA**, using **OpenStreetMap graphs** to represent road networks, partitioned by city and vehicle type (a motorbike's road network differs from a car's). Graph partitions load at service start and driver spatial data is held in memory in distributed fashion.

The problem they were solving: vehicles move at over 20 m/s, so the two nearest drivers to a pickup point change continuously — requiring constant tracking at high update frequency.

> **Two takeaways for us:** (1) straight-line nearest is often wrong — a driver 200m away across a river is worse than one 800m away on the same road; (2) Grab self-hosts routing on OSM. That second point turns out to be the difference between passing and failing our budget (see §6.2).

### 4.3 Lyft — the service mesh lesson

Lyft's value to us is about what goes wrong *after* you have microservices.

Their earlier architecture was AWS ELB, a PHP/Apache monolith, and MongoDB. Moving to microservices introduced: multiple languages and frameworks, many protocols, **inconsistent observability** across metrics/tracing/logging, and — critically — **retry, circuit breaking, rate limiting and timeout capabilities that were not completely implemented.**

The root problem: every service needed identical networking code, and copy-pasting it into each service became a maintenance nightmare. Their solution was **Envoy** — extract networking entirely from application code into a dedicated infrastructure layer. Envoy provides eventually-consistent service discovery, **circuit breakers, retries, and zone-aware load balancing**. They scaled this to **300+ microservices**.

> **This directly solves a rubric requirement.** Our ADD needs circuit breakers and rate limiters. Rather than describing them service-by-service, we implement them **once at the service-mesh layer** via Envoy sidecars. Cleaner design, less code, and a citable production precedent.

### 4.4 Saga pattern (cross-industry)

Each microservice owns its own database, so a single ACID transaction cannot span them. A Saga breaks the distributed transaction into a sequence of local transactions, each committing in its own service and publishing an event that triggers the next. On failure, **compensating transactions** undo completed steps. It trades atomic isolation for **availability and eventual consistency**.

Two coordination styles:
- **Choreography** — decentralised; each service listens for events and independently triggers the next action
- **Orchestration** — centralised; one orchestrator invokes services and handles compensation. Simplifies debugging through centralised flow management, but the orchestrator can become a bottleneck if poorly designed

**Non-negotiable implementation detail:** duplicate events, delayed delivery and retries are *normal* in distributed systems, so **every saga participant must be idempotent.**

---

## 5. Our proposed architecture

### 5.1 Service decomposition

Nine services, mapped to bounded contexts. Each owns its own data store.

| Service | Owns | Why it is separate | Data store |
|---|---|---|---|
| **API Gateway / Edge** | Auth, rate limiting, routing, WebSocket termination | Single enforcement point for rate limits and authn | — |
| **Rider Service** | Rider accounts, ride requests | Different scaling profile from drivers | PostgreSQL |
| **Driver Service** | Driver profiles, online/offline state, vehicle data | Slow-changing durable data | PostgreSQL |
| **Location Ingestion** | GPS ping firehose → geo-index | Extreme write volume, zero durability requirement | Redis (no persistence) |
| **Matching Engine** | Driver ↔ rider assignment | Latency-critical, CPU-bound, stateful | Redis (reads) |
| **Routing / ETA** | Road-network travel time | Isolated CPU/RAM-heavy workload | In-memory OSM graph |
| **Trip Management** | Trip lifecycle state machine, saga orchestration | Source of truth for a ride; needs consistency | PostgreSQL |
| **Surge Pricing** | Per-hexagon demand multipliers | Async, tolerates staleness | Redis + Flink state |
| **Billing & Payments** | Fares, payment gateway integration | Money requires strong consistency + isolated blast radius | PostgreSQL (separate instance) |
| **Notifications** | Push, SMS fallback | Low frequency, bursty | Serverless, no DB |

**The decomposition decision most worth defending:** splitting **Location Ingestion** from **Driver Service**. They look like the same domain but have opposite profiles — one is ~19,000 writes/sec of disposable data, the other is a few hundred writes/sec of durable data. Combining them means paying durable-database prices for throwaway GPS pings. Call this out explicitly in the presentation.

### 5.2 Inter-service communication protocols

The assignment asks specifically about gRPC vs REST vs WebSockets. Our position:

| Path | Protocol | Reasoning |
|---|---|---|
| Driver app → Location Ingestion | **WebSocket** (binary/protobuf) | Persistent connection avoids per-request TCP/TLS handshake at 19k msg/sec; also carries dispatch offers back down |
| Rider app → API Gateway | **REST/HTTPS** + WebSocket for trip updates | REST for request/response simplicity; WebSocket for live driver position |
| Service → Service (synchronous) | **gRPC** | Binary protobuf, HTTP/2 multiplexing, generated type-safe stubs. Matters on the Matching → Routing path where we make ~30 calls inside a 500ms budget |
| Service → Service (asynchronous) | **Kafka events** | Anything not on the latency-critical path: billing, notifications, analytics, surge input |
| External (payment gateway) | REST | Not our choice — vendor dictated |

**Rule of thumb we applied:** synchronous only when the caller genuinely cannot proceed without the answer. Everything else is an event. This is what makes the 5x spike survivable.

### 5.3 Geospatial design — H3 + Redis

**Adopted from Uber:**
- H3 indexing at resolution 8 (~0.74 km² cells)
- K-ring expansion for widening search
- **In-memory, non-durable treatment of driver location** — the single highest-value idea we're borrowing

**Rejected from Uber:**
- Ringpop and a custom distributed in-memory index. Justified at 1M updates/sec; unjustifiable at our 19k/sec, where managed Redis handles it with headroom. Building it would cost engineering time and operational risk for zero benefit.

**Implementation:**

```
Key:   geo:h3:8928308280fffff        (H3 res-8 cell ID)
Value: SET of driver_ids
TTL:   30 seconds                     (stale drivers self-evict)

Also:  driver:{id}:loc  →  {lat, lng, heading, updated_at}   TTL 30s
       driver:{id}:assignment  →  trip_id                     TTL 30s
```

**Matching query flow:**
1. Rider lat/lng → H3 index (in-process, ~microseconds)
2. K-ring(1) → 7 cell IDs
3. Redis pipelined `SMEMBERS` across 7 cells → ~10–50 candidate driver IDs (**~2ms**)
4. If < 5 candidates, expand to K-ring(2) → 19 cells and retry
5. Send candidates to Routing/ETA service for road-network ranking (**~50ms**)
6. Return top candidate

**Latency budget (target < 500ms):**

| Step | Budget |
|---|---|
| Gateway auth + routing | 20ms |
| H3 computation | < 1ms |
| Redis candidate fetch | 5ms |
| ETA ranking (~30 candidates) | 80ms |
| Surge multiplier lookup | 5ms |
| Trip record write | 30ms |
| Assignment CAS + dispatch | 20ms |
| Network + serialisation overhead | 50ms |
| **Total** | **~210ms** |
| **Headroom to 500ms** | **~290ms** |

*Having explicit headroom is a strong Q&A position — it means a 2x latency degradation still meets SLA.*

**Trade-off to state:** H3 is a pre-computed approximation. A driver just across a hexagon boundary may be nearer than one inside our ring but excluded. We accept this because K-ring(2) expansion catches most cases, and the alternative — distance to every driver — is O(n) and unaffordable.

**Grab's refinement, applied selectively:** we do NOT build a full road-network spatial index like Pharos — too much to build. Instead, **two-stage matching**: H3 gives ~30 candidates in ~2ms, then road-network ETA ranks only those 30. We get most of Grab's allocation quality at a fraction of the complexity.

#### 5.3.1 Protecting the Routing/ETA service (three layers)

OSRM is CPU-bound and sits on the latency-critical path, so it is our most load-sensitive component. Three defences, in order of value:

**Layer 1 — Use OSRM's `table` service, not N× `route` calls.**
Our dominant routing load is not the rider's A→B route (1M/day); it is the **~30 driver→pickup ETAs per ride request (~30M/day)**. OSRM's `table` (distance-matrix) endpoint computes many-to-one in a single call, sharing graph traversal across all origins. Replacing 30 individual `route` calls with one `table` call is worth roughly an order of magnitude on this path — far more than caching. *This is the optimization that matters most.*

**Layer 2 — Grid-snapped Redis cache in front of OSRM.**
Naive caching on raw coordinates would have a **near-zero hit rate**, because lat/lng are continuous — two riders at the same stadium are metres apart, so exact-match keys always miss. The cache only works if we **snap to a grid before keying**:

```
Key:   route:{origin H3 res-9 cell}:{dest H3 res-9 cell}
Value: {duration_sec, distance_m}
TTL:   5 minutes
```

Now the stadium/airport scenario collapses thousands of near-identical queries into a handful of cell pairs. Frame this as **spike protection for the event scenario**, not baseline necessity — see the load note below.

**Layer 3 — Haversine fallback.**
If OSRM is unavailable or breaching its 100ms timeout, fall back to straight-line ranking. Match quality degrades; availability does not.

**Honest load note for the Q&A:** at ~1,500 ETA queries/sec peak against OSRM nodes doing thousands/sec each, we are **not obviously bottlenecked at baseline**. The caching layer is insurance against the geographically-concentrated spike (stadium empties, flight lands), which is exactly the case a panel will raise. Say it that way rather than claiming a bottleneck that the arithmetic does not support.

### 5.4 Ingestion & streaming — Kafka

**Adopted from Uber:** Kafka as the decoupling buffer between GPS writes and downstream consumers; dead-letter topics for poison messages; independent consumer group scaling.

**Rejected from Uber:** uReplicator, Chaperone, uForwarder, multi-region active-active Kafka. All exist because Uber runs trillions of messages across global regions. We have a handful of topics at ~25k msg/sec — a **3-broker cluster**.

**Topic design:**

| Topic | Producer | Consumers | Partitions | Retention |
|---|---|---|---|---|
| `driver.location` | Location Ingestion | Geo-indexer, Surge aggregator | 24 | 1 hour |
| `trip.events` | Trip Management | Billing, Notifications, Analytics | 12 | 7 days |
| `trip.events.dlq` | Failed consumers | Manual/automated retry | 3 | 30 days |
| `billing.events` | Billing | Analytics, Reconciliation | 6 | 30 days |

Partition key for `driver.location` is the **H3 cell ID**, so all updates for a geography land on the same partition — preserving ordering per area and enabling stateful windowed aggregation in the surge pipeline.

**The backpressure story (answers the 5x spike question):**

When demand spikes, Kafka absorbs the burst. Producers never block. Consumer lag grows, autoscaling adds consumers, lag drains. **The system degrades in freshness, not in availability.**

Contrast with a direct-write architecture: a 5x spike means database lock contention, connection pool exhaustion, and cascading timeouts across services.

This single mechanism answers two rubric items — burst handling and backpressure — so it deserves a slide of its own.

### 5.5 Data storage & tiering

**Principle: pick per service, do not uniformly pick one.**

| Data | Store | Consistency | Reasoning |
|---|---|---|---|
| Trip records | PostgreSQL (Multi-AZ) | **Strong (CP)** | Source of truth; only ~12 writes/sec — boring is correct here |
| Billing / payments | PostgreSQL, separate instance | **Strong (CP)** | Money must never double-charge; isolated blast radius |
| Driver location | Redis, no persistence | **None (AP)** | Rebuilt in ~4s from driver pings. Uber's precedent applies directly |
| Surge multipliers | Redis | **Eventual (AP)** | Stale-by-seconds pricing is acceptable; unavailable pricing is not |
| Driver/rider profiles | PostgreSQL + read replica | Strong | Low volume, read-heavy |
| Completed trip history | **Tiered** — see below | — | Volume problem, not throughput problem |

**Storage tiering strategy** (explicitly required by the rubric):

| Tier | Contents | Store | Access pattern | Cost |
|---|---|---|---|---|
| **Hot** | Last 90 days | PostgreSQL | Frequent — support, disputes, active receipts | Highest |
| **Warm** | 90 days – 1 year | S3 Standard-IA, Parquet | Occasional — analytics, reporting | Low |
| **Cold** | > 1 year | S3 Glacier Instant | Rare — legal, audit | Minimal |

**Why this matters:** 1M rides/day × ~2KB = ~2 GB/day = **~730 GB/year of trip records**. Keeping all of it in a hot Multi-AZ Postgres instance is pure waste — it is written once and almost never read after the first week.

#### 5.5.1 Tiering mechanism — how data actually moves

Postgres → S3 is **not** a native database feature, so we must name the mechanism rather than hand-wave it.

**Our choice: native table partitioning with partition-drop archival.**

1. Partition the `trips` table by month (`trips_2026_09`, `trips_2026_10`, …)
2. A nightly job exports any partition older than 90 days to **Parquet on S3**
3. Verify the export, then `DROP TABLE` the partition

**Why partition-drop rather than CDC:** completed trip records are **immutable** — written once, never updated. Change Data Capture (Debezium et al.) exists to stream *changes*; streaming change events for rows that never change solves a problem we do not have, and adds a Kafka Connect cluster to operate.

The decisive advantage is deletion cost. Removing ~60M rows with ordinary `DELETE` generates enormous dead-tuple churn and VACUUM pressure on the primary. **Dropping a partition is an instant metadata operation — effectively free, with zero impact on live traffic.** That is the whole reason to partition in the first place.

**Where CDC *is* appropriate:** feeding the analytics warehouse, not archival. And since Trip Management already publishes to the `trip.events` Kafka topic, the warehouse can simply consume that existing stream — so we likely need no CDC tooling at all.

**Summary: partition-drop for archival tiering; existing Kafka event stream for analytics.** S3 lifecycle policies then handle Warm → Cold transitions automatically.

### 5.6 Trip lifecycle & the Saga

**Our choice: orchestration for the booking saga, choreography for downstream reactions.**

Justification: the booking flow has real compensations (unassign driver, void payment authorisation, notify rider) and we must be able to answer *"what state is trip X in right now?"* — much harder with pure choreography. But downstream reactions (update analytics, send receipt, credit driver earnings) are naturally choreographed off the `TripCompleted` event.

**Trip state machine:**

```
Requested ──► Matched ──► DriverEnRoute ──► InProgress ──► Completed
    │            │              │                │
    └────────────┴──────────────┴────────────────┴──► Cancelled
                                                 └──► PaymentFailed
```

**Booking saga steps and compensations:**

| # | Step | Service | Compensation on failure |
|---|---|---|---|
| 1 | Create trip record (`Requested`) | Trip Mgmt | Mark `Cancelled` |
| 2 | Reserve driver (atomic CAS) | Matching | Release driver assignment |
| 3 | Authorise payment method | Billing | Void authorisation |
| 4 | Confirm trip (`Matched`) | Trip Mgmt | Revert to `Requested`, re-match |
| 5 | Notify rider + driver | Notifications | None needed (idempotent, informational) |

Step 3 is the **pivot transaction** — after payment authorisation succeeds, the saga is committed forward rather than rolled back where possible.

**Idempotency requirement:** every step keys on `trip_uuid`. Re-delivery of any event must be a no-op, not a duplicate action. Without this, retries create double charges.

#### 5.6.1 Surge quote pinning

Surge pricing is **AP** — multipliers are recomputed continuously and may change between the moment a rider sees a fare estimate and the moment they tap confirm. Left unhandled, the rider is charged a different price from the one displayed. That is a support ticket and a trust problem, not merely a technical inconsistency.

**Mechanism: pinned quotes.**

```
1. Fare estimate  → generate quote_id, embed surge multiplier, TTL 60s
2. Store in Redis:  quote:{quote_id} → {multiplier, base_fare, expires_at}
3. Booking request carries quote_id
4. Billing honours the pinned multiplier even if live surge has moved
5. Expired quote → re-quote before confirming
```

Riders get price certainty; our exposure to adverse surge movement is bounded at 60 seconds.

**Note on the load argument:** a surge cache is sometimes justified as protecting the state store from request volume. **At our scale that argument does not hold** — we peak at ~60 ride requests/sec, ~300/sec in a 5x spike, against a Redis node handling ~100,000 ops/sec. That is noise, not pressure. The real justifications for pinning are **quote correctness** (above) and a marginal **latency** saving of one round trip inside the 500ms budget. Use those reasons in the room; a panellist who does the arithmetic will catch the load claim.

### 5.7 The double-booking problem

We expect the panel to ask: *"Two riders request simultaneously and the matching engine offers the same driver to both. What happens?"*

**Our answer:** the geo-index is a **candidate source, not a reservation system**. Assignment goes through a single atomic compare-and-set on the driver's state:

```
SET driver:123:assignment <trip_id> NX EX 30
```

Only one caller wins. The loser transparently re-queries and takes the next candidate. **This avoids a database row lock entirely**, which is precisely how we dodge lock contention under load — one of the edge cases the panel is briefed to test.

### 5.8 Resiliency blueprint

All four required mechanisms, mapped to where they live:

| Mechanism | Implementation | Where |
|---|---|---|
| **Circuit breakers** | Envoy sidecar outlier detection — eject failing upstreams after N consecutive 5xx | Service mesh (all inter-service calls) |
| **Rate limiters** | Token bucket per rider/driver/IP at the edge; per-service quotas in mesh | API Gateway + Envoy |
| **Backpressure** | Kafka consumer lag → autoscale consumers; bounded queues; load shedding at gateway when lag exceeds threshold | Kafka + HPA |
| **Dead-letter queues** | After N retries with exponential backoff, publish to `.dlq` topic for manual/automated reprocessing | Kafka (following Uber's pattern) |

**Additional patterns:**
- **Graceful degradation:** if the Routing/ETA service is unavailable, fall back to straight-line (haversine) ranking. Match quality drops; availability does not.
- **Timeouts everywhere:** no unbounded calls. Matching → Routing has a hard 100ms timeout.
- **Bulkheads:** separate connection pools per downstream, so a slow Billing service cannot exhaust the Trip service's threads.

---

## 6. Cost model & budget compliance

### 6.1 The budget in real terms

At **~328 LKR/USD** (verified 12 Sep 2026 ⚠️ *rate moves — re-check before submission*):

| | Value |
|---|---|
| Budget per ride | 10 LKR = **$0.0305** |
| Daily budget | 1M × $0.0305 = **$30,500/day** |
| Monthly budget | **~$915,000/month** |
| Annual budget | **~$11.1M/year** |

### 6.2 THE critical finding — third-party routing APIs

Published Google Maps Platform rates: Routes **$5 per 1,000**, Dynamic Maps **$7 per 1,000**, Geocoding **$5 per 1,000**. Critically, **Route Matrix bills per origin-destination element, not per request** — 2 origins × 3 destinations = 6 billable elements.

**Cost per ride using Google Maps:**

| Call | Volume/ride | Rate | Cost/ride |
|---|---|---|---|
| Route Matrix (rank 20 driver candidates) | 20 elements | $0.008/element | **$0.160** |
| Routes (fare estimate + navigation) | 2 | $5/1K | $0.010 |
| Geocoding (pickup + destination) | 2 | $5/1K | $0.010 |
| Dynamic Maps loads | 2 | $7/1K | $0.014 |
| **Total** | | | **$0.194** |

**$0.194 = ~64 LKR per ride. That is 6.4x our entire budget, from a single vendor.**

Even deleting Route Matrix entirely and ranking by straight-line distance leaves us at ~$0.034 = **11 LKR/ride — still over budget on maps alone.**

**Conclusion: self-hosting routing (OSRM or Valhalla on OpenStreetMap data) is mandatory, not an optimization.** Note this is exactly the path Grab took with Pharos and OSM graphs. They did not build that for fun.

**This table belongs on a slide.** It is the most defensible cost-optimization argument we have, because it is arithmetic rather than assertion.

### 6.3 Infrastructure cost model

| Component | Sizing rationale | Monthly (USD) |
|---|---|---|
| Kafka — 3 brokers, on-demand | 25k msg/s × 150B = ~4 MB/s; ×3 replication; 24h retention. Stateful → never spot | $540 |
| Redis cluster — 3 shards + replicas | Geo-index is only ~25 MB; throughput-bound not size-bound | $660 |
| EKS compute — ~12 nodes, 70% spot | ~50 pods peak across services, 2x spike headroom | $975 |
| **Self-hosted routing (OSRM)** | 30M ETA queries/day; OSM graph held in RAM | $1,035 |
| RDS PostgreSQL — Trip + Billing + replica | Only ~12 writes/sec; Multi-AZ for durability not throughput | $1,565 |
| Map tiles — self-hosted vector + CDN | ~18 TB/month, heavily cacheable | $1,200 |
| Data egress | ~500 KB outbound per ride → ~15 TB/month | $1,350 |
| ALB + WebSocket termination | 75k persistent connections | $300 |
| Observability, S3 archive, NAT, misc | | $810 |
| **Production subtotal** | | **$8,435** |
| Non-production (dev + staging @ ~25%) | | $2,100 |
| Analytics warehouse + ML training | Surge model, ETA model | $2,500 |
| Backups / DR | | $500 |
| **TOTAL** | | **~$13,535/month** |

**Plus SMS (OTP only):**

Design decision: **push notifications for everything; SMS strictly for login OTP.** This matches common practice in the Sri Lankan market. Because OTP is per *session* rather than per *ride*, it barely registers per-ride:

- Assume ~500,000 monthly active riders, ~1 login OTP each per month
- At ~1 LKR per bulk SMS ⚠️ *verify with a local provider*
- 500,000 LKR/month ÷ 30M rides = **~0.017 LKR/ride**

*Contrast: had we sent 2 SMS per ride, that would be 2 LKR/ride — 20% of the entire budget, and 13x more than all our servers combined. Worth mentioning in the deck as a cost trap we avoided.*

### 6.4 Result

| | Value |
|---|---|
| Monthly infrastructure | ~$13,535 |
| Rides per month | 30,000,000 |
| Cost per ride (infra) | $0.00045 = **0.148 LKR** |
| Cost per ride (+ SMS) | **~0.17 LKR** |
| **Budget** | **10.00 LKR** |
| **Utilisation** | **~1.7% of ceiling** |

### 6.5 Scenario comparison

| Scenario | LKR/ride | vs budget |
|---|---|---|
| Google Maps, full integration | 63.6 | ❌ **6.4x over** |
| Google Maps, no Route Matrix | 11.2 | ❌ **1.1x over** |
| Self-hosted + 2 SMS per ride | 2.15 | ✅ 21% of budget |
| **Self-hosted + OTP-only SMS (our design)** | **0.17** | ✅ **1.7% of budget** |

The spread between worst and best case is **over 370x**, driven almost entirely by two decisions that are not about servers at all.

### 6.6 Cost-optimization mechanisms (rubric requirement)

| Lever | Our application | Expected saving |
|---|---|---|
| **Spot instances** | 70% of the *genuinely* stateless tier: REST API pods, matching workers, Kafka consumers, OSRM replicas, batch jobs | 60–90% discount vs on-demand; typically 50–70% realised on migrated workloads |
| **On-demand floor** | Kafka brokers, Redis, databases, ingress, **and the WebSocket termination tier** — see §6.6.1 | — |
| **Serverless** | Notifications, receipt generation, scheduled reports — genuinely low-frequency paths | Pay-per-invocation |
| **Autoscaling** | HPA on CPU + Kafka consumer lag; cluster autoscaler (Karpenter) for nodes | 20–40% on diurnal patterns |
| **Data tiering** | Hot 90d → Warm S3-IA → Cold Glacier | ~90% on aged data |
| **Eliminate per-request vendor pricing** | Self-hosted OSRM + vector tiles | **~99.8% vs Google Maps** |

**Honest counter-argument we should be ready for:** spot is not free money. One 2026 study tracking 12,000 interruptions found **41% of workloads lost money on spot** once interruption-recovery costs were included. Our defence is workload-placement discipline — nothing stateful ever runs on spot, and everything on spot handles SIGTERM gracefully within the 2-minute reclaim notice.

#### 6.6.1 Spot instances vs. persistent WebSockets — a correction

**An earlier draft of this design placed WebSocket termination in the "stateless, 70% spot" tier. That was wrong, and it is worth stating plainly because a panel can spot the contradiction unprompted: a service holding 75,000 persistent connections is not stateless. The connection *is* state.**

**Why draining alone does not fix it.** If WebSocket termination runs on ~4 nodes at 70% spot, losing one spot node drops **~19,000 connections simultaneously**. Even with perfect draining, every one of those clients reconnects within seconds — a thundering herd against the remaining nodes, precisely when there are fewer of them. Draining converts an abrupt failure into an orderly one; it does not remove the reconnection storm.

**Fix 1 — Placement (the primary fix).** Move the WebSocket termination tier to **on-demand**. It is a small slice of the fleet (~$150–200/month at our sizing) against ~98% budget headroom. Spending ~1.5% of the budget to eliminate an entire class of failure is straightforwardly correct — and saying so is itself a strong cost-reasoning answer: *"we had the headroom, so we bought stability where connection churn was expensive."*

**Fix 2 — Graceful drain (defence in depth).** On-demand nodes are still replaced during deploys and scaling events, so draining is required regardless:

| Step | Action |
|---|---|
| Capacity Rebalance signal | AWS flags elevated interruption risk *before* the 2-minute notice — begin proactive drain early |
| SIGTERM received | Stop accepting new connections; deregister from load balancer target group |
| Notify clients | Send `reconnect` control frame with **jittered backoff window** |
| Drain | Allow ~90s of the 120s notice for clients to migrate |
| Terminate | Close remaining sockets |

**Jitter is not optional.** Without randomised backoff, every disconnected client reconnects at the same instant and we have synchronised the herd rather than dispersed it.

**Fix 3 — Client-side resilience (where this is really solved).** Driver and rider apps need reconnect-with-exponential-backoff as standard behaviour anyway, because **mobile networks drop connections constantly** — tunnels, cell handovers, backgrounding. A spot reclaim is simply one more cause of a disconnect the client already handles. This reframing matters in the Q&A: it moves the issue from "infrastructure hazard we overlooked" to "normal operating condition our protocol already tolerates."

**Autoscaling triggers (rubric requirement):**

| Service | Scale-out trigger | Scale-in | Min/Max |
|---|---|---|---|
| Location Ingestion | CPU > 60% OR WS connections > 20k/pod | CPU < 30% for 10 min | 4 / 20 |
| Matching Engine | p99 latency > 200ms OR CPU > 65% | CPU < 30% for 10 min | 4 / 24 |
| Kafka consumers | Consumer lag > 10,000 msgs | Lag < 1,000 for 5 min | 3 / 30 |
| Routing/ETA | CPU > 70% | CPU < 35% for 15 min | 2 / 12 |
| Trip/Billing | CPU > 70% | CPU < 35% | 3 / 12 |

Note the deliberately slow scale-in (10–15 min cooldowns) — this prevents thrashing during the oscillating demand typical of weather events.

### 6.7 How to present the headroom — IMPORTANT

**Do not say "we are 65x under budget" as a victory.** A sharp panellist reads that as *"you under-sized and don't know it."*

**Say this instead:**

> "We modelled the infrastructure and found that at 1M rides/day, cloud compute and storage land around 0.17 LKR per ride — under 2% of the ceiling. The budget is not the binding constraint; latency and burst absorption are. What *would* break the budget is third-party API dependency: a naive Google Maps integration costs 64 LKR per ride, over 6x the limit. So our cost-optimization work targeted eliminating per-request vendor pricing from the hot path rather than shaving instance hours."

Then add the corollary: **the remaining headroom buys reliability we would otherwise have to argue for.** Multi-AZ everywhere, generous autoscaling ceilings, on-demand for all stateful components, warm standby for the 5x spike — all affordable. We are not cost-constrained; we are free to over-provision for resilience. This converts an awkward number into a design justification.

### 6.8 Scope ambiguity to flag

"Cost per completed ride below 10 LKR" does not specify inclusions. If it means **cloud infrastructure**, we pass comfortably. If it is meant to include **payment gateway fees** (typically 2–3% of fare — on a 600 LKR fare that is 12–18 LKR/ride), the target is unachievable by *any* architecture, because that is a cost of revenue, not an engineering decision.

**Recommended wording for the ADD:**

> *"We interpret the 10 LKR target as cloud infrastructure and platform operating cost, excluding payment processing fees, driver payouts, and customer acquisition."*

This protects us either way and shows we noticed the ambiguity.

---

## 7. Trade-off summary — the Q&A defence slide

If we build one slide that wins the Q&A, this is it. **Every row names a real loss.** Architectures with no downsides are wish lists, and panels reward candidates who name their costs.

| Decision | We chose | We gave up | Why |
|---|---|---|---|
| Driver location durability | In-memory only, no persistence | Data loss on node crash | Drivers re-ping within 4s; durability would cost ~10x for data stale in seconds |
| Surge pricing consistency | **AP** — freshness over correctness | Exact consistency | Late messages do not improve the answer; stale pricing beats no pricing |
| Billing consistency | **CP** — strong consistency | Availability during partition | Money must not double-charge; better to fail than be wrong |
| Matching algorithm | H3 K-ring approximation | Guaranteed-nearest driver | Exact search is O(n) over all drivers; approximation is O(1) lookups |
| Match quality | Two-stage: H3 then ETA re-rank on ~30 | Full road-network spatial index (Pharos) | ~80% of the quality at ~10% of the build cost |
| Saga coordination | Orchestration for booking | Some coupling to orchestrator | Debuggability and clear compensation paths outweigh architectural purity |
| Dispatch sharding | Managed Redis | Ringpop / custom consistent hashing | Justified at 1M updates/sec; over-engineering at our 19k/sec |
| Compute | 70% spot, 30% on-demand | Interruption risk on stateless tier | 50–70% savings; stateful never on spot |
| Routing | Self-hosted OSRM | Google's traffic-aware accuracy, ops burden of running it | 64 LKR/ride → 0.03 LKR/ride. Not optional |
| Notifications | Push-first, SMS for OTP only | Reachability when app is closed | 2 SMS/ride would consume 20% of the entire budget |
| WebSocket tier placement | On-demand, not spot | ~$150–200/month of spot savings | 19,000 simultaneous disconnects per reclaimed node; headroom makes this trivially worth buying |
| Route caching | Grid-snapped (H3 res-9) keys | Exactness — two nearby origins share a cached result | Raw-coordinate keys have a near-zero hit rate; snapping is what makes the cache function at all |
| Archival mechanism | Partition-drop | Real-time archival granularity | `DROP` is a metadata operation; row-wise `DELETE` of 60M rows creates VACUUM pressure on the primary |
| Fare quoting | Pinned 60s quote | Exposure to adverse surge movement within the window | Rider price certainty; being charged differently from the displayed estimate destroys trust |

---

## 8. Panel Q&A preparation

The brief says the panel will test **database lock contention, network partitions, geo-index cache invalidation, and sudden 5x traffic spikes**. Prepared answers:

**Q: "Sudden 5x traffic spike — what happens?"**
Kafka absorbs the write burst; producers never block. Consumer lag grows, HPA scales consumers on lag threshold, lag drains. Matching capacity scales on p99 latency. The system degrades in *freshness* (surge multipliers a few seconds stale), not in *availability*. Load shedding at the gateway is the last resort, and it sheds fare-estimate requests before ride requests.

**Q: "Database lock contention?"**
Largely designed out. The trip DB sees only ~12 writes/sec, and driver assignment never touches a database row lock — it is an atomic Redis `SET NX`. Each service owns its own database, so there is no cross-service locking at all.

**Q: "Network partition between matching engine and trip database?"**
Matching continues optimistically (it reads Redis), but trip creation fails fast via circuit breaker and the rider receives a clear "please retry" rather than a hung request. Availability for reads, fail-fast for writes. We do not queue writes blindly, because a rider waiting on a ghost trip is worse than a clean error.

**Q: "Geo-index cache invalidation?"**
We do not invalidate — we expire. Every driver entry carries a 30-second TTL and is refreshed every 4 seconds by the driver's own ping. A stale driver disappears automatically. There is no invalidation logic to get wrong, which is deliberate.

**Q: "Redis goes down entirely?"**
New matching stops — that is a genuine outage for new rides, and we should say so rather than pretend otherwise. Mitigations: Redis replicated with automatic failover across AZs; in-flight trips are unaffected because they live in PostgreSQL, not Redis; and rebuild is fast because drivers re-register within seconds. This is precisely why Uber treats the index as rebuildable rather than durable.

**Q: "CAP theorem — where do you sit?"**
Per service, deliberately. **CP** for Trip Management and Billing (correctness over availability — money and trip state). **AP** for Location, Surge, and Matching candidates (availability over consistency — a slightly stale driver position is fine, no driver positions is not). Citing that Uber's own Ringpop is an AP system, and that their surge pipeline explicitly favours freshness over consistency, gives this precedent.

**Q: "Why not just use Uber's architecture?"**
Because we are ~50x smaller. Uber handles 1M+ location updates/sec; we handle ~19k. Ringpop, uReplicator and Chaperone all exist to solve problems that appear at their scale and not ours. Adopting them would add operational risk and engineering cost for zero benefit. We took their *ideas* — H3, disposable location data, Kafka decoupling, DLQs — and rejected their *implementations*.

**Q: "What is your single biggest risk?"**
Self-hosted routing. It is the right economic decision by two orders of magnitude, but it means we own OSM data pipelines, graph rebuilds, and traffic modelling that Google would otherwise handle. Mitigation: haversine fallback ranking so a routing outage degrades match quality instead of stopping matching.

**Q: "You run on spot instances but hold persistent WebSocket connections. What happens on a reclaim?"**
The WebSocket termination tier does **not** run on spot — it is on-demand, because a service holding 75,000 connections is not stateless. Spot is used for genuinely stateless work: REST pods, matching workers, Kafka consumers, OSRM replicas. For the on-demand tier we still drain gracefully on SIGTERM with jittered client reconnect, and we act on Capacity Rebalance signals ahead of the 2-minute notice. Underneath all of that, the mobile clients implement reconnect-with-backoff regardless, because cell handovers and backgrounding drop connections far more often than infrastructure does. *(Full reasoning in §6.6.1.)*

**Q: "OSRM is CPU-bound. What protects it during a 5x spike?"**
Three layers. First, we use OSRM's `table` endpoint so 30 candidate ETAs cost one call rather than thirty — that is the big win, since candidate ranking is 30M queries/day against 1M rider routes. Second, a Redis cache keyed on **H3 res-9 grid cells rather than raw coordinates**, which is what makes it effective for the stadium scenario — exact coordinate keys would essentially never hit. Third, haversine fallback if OSRM breaches its 100ms timeout. Worth noting the baseline is ~1,500 queries/sec against nodes doing thousands each, so this is spike insurance rather than a standing bottleneck.

**Q: "How does data actually move from Postgres to S3?"**
Native monthly table partitioning. A nightly job exports partitions older than 90 days to Parquet on S3, verifies, then drops the partition. We deliberately avoid CDC here — trip records are immutable, so streaming change events for rows that never change adds a Kafka Connect cluster for no benefit. The decisive factor is that `DROP TABLE` on a partition is an instant metadata operation, whereas deleting 60M rows conventionally would generate severe VACUUM pressure on the primary. CDC would be appropriate for the analytics warehouse, but we already publish `trip.events` to Kafka, so the warehouse consumes that instead.

**Q: "Surge is eventually consistent. Doesn't the rider get charged a different price than they were quoted?"**
Not with pinned quotes. The fare estimate generates a `quote_id` with the multiplier embedded and a 60-second TTL; booking carries that ID and Billing honours the pinned multiplier even if live surge has moved. Riders get price certainty and our exposure is bounded to 60 seconds. We do *not* justify this as protecting Redis from load — at ~300 requests/sec in a spike against a node doing ~100,000 ops/sec, load is not the issue.

---

### 8.1 A note on handling the panel

Several review suggestions we received arrived with plausible-sounding justifications that did not survive checking the arithmetic or the tool's actual purpose — a surge cache framed as relieving load that is nowhere near loaded, CDC proposed for immutable data, coordinate caching that would never hit.

This is the same failure mode as the Google Maps trap, inverted. **If a panel question assumes a bottleneck, check the premise before accepting it.** A strong response looks like:

> *"At our request rate that works out to roughly 300 operations per second, so that isn't actually the binding constraint — but here's what is, and here's how we handle it."*

This demonstrates exactly what the rubric rewards under Panel Defense: reasoning under questioning, rather than reflexive agreement.

---

## 9. Open questions — TEAM INPUT NEEDED

Please come to the next sync with a view on these:

1. **Cloud provider** — AWS assumed throughout. If we switch to GCP or Azure the numbers shift ~10–15% but nothing structural changes. Any preference or lecturer expectation?
2. **Region** — ap-south-1 (Mumbai) is the natural choice for Sri Lanka; roughly 10–15% pricier than us-east-1. Confirm before finalising the cost table.
3. **"Global platform" interpretation** — the brief says "global ride-hailing platform" but the cost target is in LKR. Do we design single-region with multi-region as a roadmap item, or multi-region from day one? *Recommendation: single-region with documented multi-region path — multi-region active-active would roughly double the cost for no marks.*
4. **Scope of the 10 LKR** — see §6.8. Worth a quick email to the lecturer if there is time.
5. **Which C4 Component diagram?** — we only need one at Component level. *Recommendation: the Matching Engine, since it is the most technically interesting and showcases the H3 + ETA two-stage design.*
6. **Verify locally:** bulk SMS rate from a Sri Lankan provider (Dialog/Mobitel/Hutch bulk APIs).

---

## 10. Work split & timeline

**Deadline: midnight, Sunday 13 September 2026.** This is tight.

| Workstream | Deliverable | Suggested owner |
|---|---|---|
| C4 Context diagram | UrbanRide + external actors (riders, drivers, payment gateway, map data) | |
| C4 Container diagram | 9 services + Kafka + Redis + databases + gateway | |
| C4 Component diagram | Matching Engine internals | |
| ADD §1–2 — Domain & service decomposition | From §5.1, §5.2 of this doc | |
| ADD §3 — Scalability & resiliency | From §5.4, §5.8 | |
| ADD §4 — Infrastructure & cost | From §6 | |
| Presentation deck (10 min strict) | ~10–12 slides | |
| Q&A prep + rehearsal | From §7, §8 | All |

**Suggested 10-minute deck structure:**

| Slide | Content | Time |
|---|---|---|
| 1 | Title + the scale numbers (§3.1) | 0:30 |
| 2 | C4 Context | 0:45 |
| 3 | Service decomposition + bounded contexts | 1:15 |
| 4 | C4 Container | 1:15 |
| 5 | Matching flow + latency budget (§5.3) | 1:30 |
| 6 | Write path + backpressure story (§5.4) | 1:15 |
| 7 | Saga + trip lifecycle (§5.6) | 1:00 |
| 8 | **Cost: the Google Maps table** (§6.2) | 1:15 |
| 9 | Cost breakdown + result (§6.3–6.4) | 0:45 |
| 10 | Trade-off summary (§7) | 0:30 |

*Rehearse with a timer. The rubric gives 15% to presentation clarity and explicitly names 10-minute adherence.*

---

## 11. Sources

**Uber**
- Real-time Data Infrastructure at Uber (arXiv 2104.00087) — Kafka, Flink, surge pipeline, CAP trade-offs
- H3 geospatial indexing system — h3geo.org, github.com/uber/h3
- How Uber Scales Their Real-time Market Platform (High Scalability) — DISCO, Ringpop, SWIM
- Designing Schemaless / Docstore blog series (uber.com/blog)
- Cadence workflow orchestration — github.com/cadence-workflow

**Grab**
- Pharos: Searching Nearby Drivers on Road Network at Scale (engineering.grab.com)
- Grab allocation and matching factors (grab.com/inside-grab)

**Lyft**
- Lyft's Envoy: Embracing a Service Mesh (Matt Klein, QCon NY 2018)
- envoyproxy.io

**Patterns & cost**
- Saga pattern — microservices.io, Temporal, Conduktor references
- Google Maps Platform pricing (2026 published rates)
- Kubernetes spot instance cost benchmarks (2026)

---

*Prepared as an initial direction document. All cost figures are estimates from published list prices and standard sizing heuristics, not measurements from a running system. Items marked ⚠️ require verification before final submission.*
