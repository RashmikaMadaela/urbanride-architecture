## 10. Risks & Future Work

<!-- OWNER: M1 | TARGET: ~0.5 page -->

### 10.1 Key risks

<!-- Self-hosted routing ops burden; Redis as single point of matching failure;
     assumptions requiring validation -->

**Self-hosted routing is our largest risk.** Running `OSRM` on OpenStreetMap data is the decision
that brings the platform inside the cost ceiling, since the commercial alternative is roughly 64 LKR
per ride against a 10 LKR budget (§8.2), but it transfers real work onto us. We own the OSM
extract pipeline, the graph rebuild schedule, the quality of the underlying map data in our
operating region, and any traffic modelling we choose to add. A commercial provider would absorb
all of that. The mitigation is that a routing failure degrades rather than stops the service: the
`Matching Engine` falls back to haversine distance ranking if `Routing Service` breaches its 100ms
timeout (§5.8), so match quality drops while matching itself continues. The residual risk is
quality, not availability, and it is worth accepting for a two-order-of-magnitude cost difference.

**`Redis` is the single point of failure for new matching.** The geospatial index lives in memory
without persistence, so if the `Redis` cluster is lost entirely, no new rides can be matched until
it is restored. This should be stated plainly rather than minimised. Three things bound the
impact: the cluster is replicated with automatic failover across availability zones; trips already
in progress are unaffected because their state lives in `PostgreSQL`, not `Redis`; and the index
rebuilds itself within one 4-second ping interval as drivers re-register, because it is derived
data rather than a system of record. This is the same reasoning Uber applies to its own location
index, and it is why the index is designed to be rebuildable rather than durable.

**Several load-bearing figures are estimates rather than measurements.** Average ride duration,
rides per driver per day, outbound data volume per ride, and the LKR/USD exchange rate all feed
the capacity and cost models, and none comes from a running system. Appendix A records each with
its status. The exchange rate and the local bulk SMS rate are the two that most directly move the
cost result and should be re-verified before the figures are relied upon commercially. The
architecture is not sensitive to moderate error in these, because the infrastructure result sits at
roughly 1.7% of the ceiling and even a large proportional error does not change the conclusion,
but the specific numbers would move.

**Operational maturity is assumed, not demonstrated.** The design leans on `Envoy`, `Kafka`,
`Flink` and `OSRM`, which is a broad surface for a team to run well. Adopting the service mesh
rather than hand-rolling resilience in each service (§7.1) reduces the code we maintain, but it
does not reduce the operational knowledge required.

### 10.2 Future work

<!-- Multi-region active-active; ML-based matching (Grab's 40+ factors);
     traffic-aware ETA; driver preference modelling -->

**Multi-region active-active.** Deployment is single-region by decision (§2.2). The natural
progression is a second region serving a distinct geography with independent `Redis` and `Kafka`
clusters, since driver location and matching are inherently local and shard cleanly by geography.
The difficult part is the financial and trip data, which is where cross-region consistency has to
be confronted; the likely answer is regional ownership of trip records with asynchronous
replication for reporting, rather than global strong consistency.

**Richer matching.** The current design ranks candidates by road-network ETA alone. Grab weighs
over 40 factors, including which booking types a driver has historically accepted or declined. The
two-stage structure already in place accommodates this directly: the `H3` K-ring stage produces
the candidate set, and the ranking stage can incorporate additional signals without any change to
candidate generation.

**Traffic-aware ETA.** `OSRM` currently routes over static road-network speeds. Historical
speed profiles derived from our own completed trips would improve ETA accuracy, and the
`trip.events` stream already carries the necessary data.

**Driver preference and supply positioning.** Modelling where drivers prefer to work, and
repositioning idle supply toward predicted demand, reduces both rider wait time and unpaid driver
mileage. This depends on the demand signal that `Surge Pricing Service` already computes per `H3`
cell.

**Cost-model validation under real load.** Every figure in §8 derives from list prices and sizing
heuristics. The first production month would replace the estimates with measurements, and the
outbound data volume per ride, the softest assumption in the model, is the one most worth
measuring first.
