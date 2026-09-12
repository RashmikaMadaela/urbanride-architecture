## 5. Performance & Latency Design

<!-- OWNER: M2 | SOURCE: Brief §5.3, §5.3.1, §5.4 | TARGET: ~3.5 pages | RUBRIC: 25% -->

### 5.1 Geospatial indexing strategy

<!-- Why H3; hexagons vs squares (equidistant neighbours);
     resolution choice (res-8, ~0.74 km2) and why;
     Redis key structure and TTL-based expiry; K-ring expansion logic -->

[[ WRITE HERE ]]

### 5.2 Matching query flow

<!-- Numbered steps with per-step latency -->

[[ WRITE HERE ]]

### 5.3 Latency budget

| Step | Budget |
|---|---|
| | |
| **Total** | |
| **Headroom to 500ms** | |

<!-- State the headroom explicitly - a 2x degradation still meets SLA. -->

### 5.4 Trade-off: approximation vs exactness

[[ WRITE HERE ]]

### 5.5 Two-stage matching

<!-- H3 candidate generation -> road-network ETA re-ranking.
     Reference Grab's rejection of straight-line nearest. -->

[[ WRITE HERE ]]

### 5.6 Write-heavy ingestion path

| Topic | Producer | Consumers | Partitions | Retention |
|---|---|---|---|---|
| | | | | |

<!-- Partition key = H3 cell ID, and why (ordering per geography, windowed aggregation) -->

### 5.7 Backpressure & burst absorption

<!-- THE 5x SPIKE ANSWER. System degrades in FRESHNESS, not availability.
     Contrast with direct-write architecture failure mode. -->

[[ WRITE HERE ]]

### 5.8 Protecting the Routing/ETA service

<!-- Three layers from Brief §5.3.1:
     1. OSRM `table` endpoint instead of Nx `route` - the big win
     2. Grid-snapped cache (H3 res-9 keys), NOT raw coordinates
     3. Haversine fallback -->

[[ WRITE HERE ]]

---

![C4 Level 3 - Matching Engine Component](../diagrams/c4-03-component-matching.png)

**Figure 3 — C4 Level 3: Component view of the Matching Engine.** [[ caption ]]

<!-- DIAGRAM 3 | OWNER: M2 | FILE: diagrams/c4-03-component-matching.png
     Internals: request handler -> H3 indexer -> Redis candidate fetcher ->
     ETA client (with cache + fallback) -> ranking module -> assignment CAS module.
     Include the fallback path. -->

---

![Ride request sequence](../diagrams/seq-01-ride-request.png)

**Figure 4 — End-to-end ride request sequence.** [[ caption ]]

<!-- DIAGRAM 4 (OPTIONAL - cut first if short on time) | OWNER: M2
     FILE: diagrams/seq-01-ride-request.png
     Rider -> Gateway -> Matching -> Redis -> OSRM -> Trip -> Billing -> Notifications.
     Annotate with latency budget numbers. -->
