## 11. References

<!-- Use a consistent citation style throughout. -->

**Uber Engineering**

1. Fu, Y. and Soman, C. (2021) *Real-time Data Infrastructure at Uber*. arXiv:2104.00087.
   Available at: https://arxiv.org/abs/2104.00087. Source for the Kafka and Flink architecture,
   the surge pricing pipeline, the Storm-versus-Flink backpressure recovery comparison, and the
   documented decision to favour freshness over consistency in surge computation.
2. Uber Technologies (2018) *H3: A Hexagonal Hierarchical Geospatial Indexing System*.
   Available at: https://h3geo.org and https://github.com/uber/h3. Source for the resolution
   table, K-ring expansion, and the equidistant-neighbour property of hexagonal cells.
3. High Scalability (2015) *How Uber Scales Their Real-time Market Platform*.
   Available at: https://highscalability.com. Source for DISCO dispatch, Ringpop application-layer
   sharding, the SWIM gossip protocol, and the treatment of driver location as disposable
   in-memory data.
4. Uber Engineering *Designing Schemaless* and *Docstore* blog series.
   Available at: https://www.uber.com/en-GB/blog/engineering/. Source for the 2014 Postgres
   capacity constraint and the Raft-coordinated leader/follower partition model.
5. Cadence Workflow (2024) *Cadence: Fault-Tolerant Stateful Code Platform*.
   Available at: https://github.com/cadence-workflow/cadence. Source for durable trip-lifecycle
   workflows, automatic activity retries, and Saga-style compensation support.

**Grab Engineering**

6. Grab Engineering *Pharos: Searching Nearby Drivers on Road Network at Scale*.
   Available at: https://engineering.grab.com. Source for in-memory K-nearest search by driving
   distance, OpenStreetMap graph partitioning by city and vehicle type, and the rejection of
   straight-line nearest-driver matching.
7. Grab *Inside Grab: How the Allocation System Works*.
   Available at: https://www.grab.com/inside-grab/. Source for geohash-based candidate
   generation, ETA-based narrowing, and the 40-plus factors weighed in final allocation.

**Lyft / Service Mesh**

8. Klein, M. (2018) *Lyft's Envoy: Embracing a Service Mesh*. QCon New York.
   Source for the migration from a PHP monolith to 300-plus microservices, and the observation
   that retry, circuit-breaking, rate-limiting and timeout logic were incompletely and
   inconsistently implemented when left to individual services.
9. Envoy Proxy *Architecture Overview: Outlier Detection and Circuit Breaking*.
   Available at: https://www.envoyproxy.io/docs. Source for the sidecar circuit-breaker and
   zone-aware load-balancing behaviour described in §7.1.

**Patterns**

10. Richardson, C. *Pattern: Saga*. microservices.io.
    Available at: https://microservices.io/patterns/data/saga.html. Source for orchestration
    versus choreography, compensating transactions, and the pivot-transaction concept.
11. Richardson, C. *Pattern: Database per Service*. microservices.io.
    Available at: https://microservices.io/patterns/data/database-per-service.html. Source for
    the data-isolation position taken in §4.5.

**Routing & Map Data**

12. Luxen, D. and Vetter, C. *Open Source Routing Machine (OSRM)*.
    Available at: https://project-osrm.org and https://github.com/Project-OSRM/osrm-backend. Source for the `table` (distance-matrix) endpoint used in §5.8 to compute many-to-one ETAs in
    a single call.
13. OpenStreetMap Foundation *OpenStreetMap planet and regional extracts*.
    Available at: https://www.openstreetmap.org and https://download.geofabrik.de. Source of the
    road-network data underlying the self-hosted `Routing Service`.

**Cost & Infrastructure**

14. Google *Google Maps Platform Pricing*.
    Available at: https://mapsplatform.google.com/pricing/. Source for Routes, Geocoding and
    Dynamic Maps rates, and for the Route Matrix per-element billing model that produces the
    ~64 LKR/ride figure in §8.2. Rates as published and checked 13 September 2026.
15. Amazon Web Services *AWS Pricing, Asia Pacific (Mumbai) ap-south-1*.
    Available at: https://aws.amazon.com/pricing/. Basis for every instance, storage and egress
    figure in §8.3. Checked 13 September 2026.
16. Central Bank of Sri Lanka *Daily Indicative Exchange Rates*.
    Available at: https://www.cbsl.gov.lk. Source for the 328 LKR/USD working rate recorded in
    §8.1 and Appendix A.
17. PostgreSQL Global Development Group *PostgreSQL Documentation: Table Partitioning*.
    Available at: https://www.postgresql.org/docs/current/ddl-partitioning.html. Source for the
    partition-drop archival mechanism in §6.3, and for why `DROP` on a partition is a metadata
    operation rather than a row-wise delete.
