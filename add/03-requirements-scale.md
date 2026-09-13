## 3. Requirements & Scale Analysis

<!-- OWNER: M2 | SOURCE: Brief §2.1, §3 | TARGET: ~1.5 pages -->
<!-- NOTE: §3.3 is load-bearing. Every later section references these numbers. -->

### 3.1 Functional requirements

UrbanRide must support the following core capabilities:

- **Ride requesting:** riders submit pickup and destination coordinates; the system finds and assigns the best-ranked available driver by road-network ETA within 500ms.
- **Real-time driver tracking:** active drivers stream GPS pings every 4 seconds; riders see live driver position updates during en-route and in-progress states.
- **Driver–rider matching:** the Matching Engine selects the optimal available driver using a two-stage geospatial + road-network ranking process.
- **ETA computation:** the Routing Service calculates road-network travel time from each candidate driver to the rider pickup point.
- **Trip lifecycle management:** a ride progresses through defined states (`Requested → Matched → DriverEnRoute → InProgress → Completed`) with compensating transitions to `Cancelled` or `PaymentFailed` on failure.
- **Surge pricing:** per-hexagon demand multipliers are computed in near-real time and applied to fare estimates before driver dispatch.
- **Billing and payment:** fares are calculated on trip completion and processed through a third-party payment gateway with strong consistency guarantees.
- **Notifications:** riders and drivers receive push notifications at key trip state transitions; SMS is reserved for login OTP only (see §8.7).

### 3.2 Non-functional requirements

| Constraint | Target |
|---|---|
| Throughput | 1,000,000 completed rides/day; peak ~60 ride requests/sec; peak ~19,000 driver location writes/sec (design ceiling 25,000/sec, see §3.3) |
| Latency | < 500ms end-to-end for the ride matching transaction (high-frequency path) |
| Burst tolerance | Absorb sudden 5× demand spikes (weather events, concerts) without dropping requests or cascading failures |
| Cost | < 10 LKR per completed ride (cloud infrastructure and platform operating cost only) |

### 3.3 Derived scale figures

<!-- Copy the full derivation table from Brief §3.1 -->

| Quantity | Derivation | Value |
|---|---|---|
| Completed rides/day | Given | **1,000,000** |
| Average ride request rate | 1M ÷ 86,400 s | **~12 /sec** |
| Peak ride request rate | 5× burst assumption | **~60 /sec** |
| Ride duration (assumed) | Typical urban average | ~20 min |
| Total ride-minutes/day | 1M × 20 | 20,000,000 |
| Average concurrent active trips | 20M ÷ 1,440 min | **~14,000** |
| Peak concurrent active trips | ~2× average | **~30,000** |
| Active drivers needed | 1M rides ÷ ~16 rides per driver-day | **~60,000** |
| Peak concurrent online drivers | Including idle drivers | **~75,000** |
| GPS ping interval | Industry standard (Uber uses 4 s) | 4 sec |
| **Peak location writes/sec** | 75,000 ÷ 4 | **~19,000 /sec** |
| Design ceiling (with headroom) | +30% above peak | **25,000 /sec** |
| Location data volume | 25,000/s × ~150 bytes | **~3.75 MB/s** |

### 3.4 Scale comparison to production systems

<!-- The Uber/UrbanRide ratio table from Brief §3.2.
     This justifies every simplification later, so it must appear early. -->

| Metric | Uber | UrbanRide | Ratio |
|---|---|---|---|
| Location updates/sec | 1,000,000+ | ~19,000 | **~53× smaller** |
| Kafka messages/day | Trillions | ~1.6 billion | **~1,000× smaller** |
| Active drivers | ~5,000,000 | ~75,000 | **~66× smaller** |

### 3.5 Key observations

**The transactional workload is small.** At ~12 ride requests per second and ~12 PostgreSQL writes per second to the trip database, the core transactional load is trivially handled by a single well-configured PostgreSQL instance. There is no case for exotic storage or multi-shard write paths for this tier. Saying this plainly is more credible than pretending we need Cassandra.

**The location workload is high-operation but low-volume.** 19,000 writes per second is a large *operation count*, but at ~3.75 MB/s it is a modest *data volume*. The constraint this places on the system is latency and concurrency, not bandwidth or storage. This is why the correct solution is an in-memory data structure (Redis) with no persistence, not a larger database instance. A driver location record that is stale by more than 4 seconds is already superseded by the next ping, so durability is worthless here.

**Data structure choice matters more than hardware scale.** The single most impactful decision in this design is treating driver location as disposable in-memory data, borrowed directly from Uber's production precedent. If a Redis node fails, all driver locations are rebuilt within one GPS ping interval (4 seconds) from re-registrations. This eliminates an entire tier of write-path durability engineering. Combined with H3 hexagonal indexing, which reduces a potential O(n) search across 75,000 drivers to a lookup across 7–19 cells containing tens of candidates, the system achieves sub-500ms matching without exotic hardware.
