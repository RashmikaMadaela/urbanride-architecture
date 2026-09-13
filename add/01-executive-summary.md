## 1. Executive Summary

<!-- OWNER: M1 | SOURCE: Brief §1 | TARGET: ~1 page -->

UrbanRide is a ride-hailing platform whose backend must sustain **1,000,000 completed rides per
day**, hold **high-frequency transactions under 500ms**, absorb **sudden demand surges** from
weather and events without losing availability, and run at **under 10 LKR per completed ride**.
This document specifies an event-driven microservices architecture of ten services that meets all
four, deployed single-region on AWS `ap-south-1`.

Three findings shaped the design, and each is defended in the sections that follow.

**We are roughly fifty times smaller than Uber, so we adopt their ideas and reject their
implementations.** Translating the headline figures into engineering terms gives approximately 12
ride requests per second and 19,000 driver location updates per second (§3.3). Uber handles over a
million location updates per second. That gap is the justification for every simplification in
this document. We take the ideas that transfer: `H3` hexagonal geospatial indexing, treating
driver location as disposable in-memory data, `Kafka` as a decoupling buffer, and dead-letter topics
for poison messages. We decline the machinery built specifically for their scale, such as
Ringpop's custom consistent-hash ring and uReplicator's cross-region `Kafka` replication. Managed
`Redis` handles 19,000 writes per second with headroom; building a distributed in-memory index to
do the same work would add engineering cost and operational risk for no measurable benefit.

**Cloud infrastructure is not the binding constraint.** The modelled infrastructure cost lands at
approximately **0.17 LKR per ride**, under 2% of the ceiling (§8.4). This is not a claim of
efficiency so much as an observation about scale: at 12 transactional writes per second, the
database workload is genuinely small, and the location workload, while high in operation count,
is only about 3.75 MB/s of data. It needs the right data structure, not large hardware. The
practical consequence is that the remaining headroom buys reliability we would otherwise have to
argue for: Multi-AZ on every durable store, generous autoscaling ceilings, and on-demand instances
for every stateful component including WebSocket termination.

**Third-party per-request APIs are the real budget risk.** A naive Google Maps integration costs
approximately **64 LKR per ride, 6.4 times the entire budget**, driven almost entirely by Route
Matrix billing per origin-destination *element* rather than per request, which is ruinous when
ranking 20–30 driver candidates per ride (§8.2). Removing Route Matrix entirely and ranking by
straight-line distance still leaves the design over budget on mapping alone. Self-hosting routing
on OpenStreetMap data is therefore **mandatory rather than an optimisation**, the same conclusion
Grab reached when they built Pharos on OSM graphs. Cost optimisation in this system is not about
shaving instance hours; it is about eliminating per-request vendor pricing from the hot path.
Everything else is rounding error.

**The architecture.** Ten services partitioned by bounded context, each owning its own data store
(§4). Matching is two-stage: an `H3` K-ring lookup in `Redis` reduces the fleet to roughly 30
candidates in about 2ms, and self-hosted `OSRM` then ranks only those candidates by road-network
travel time, capturing most of Grab's allocation quality at a fraction of the build cost. The measured
latency budget totals approximately 210ms against the 500ms target, leaving enough headroom that a
2x degradation still meets the SLA (§5.3). `Kafka` decouples the GPS write firehose from every
consumer, so a 5x demand spike grows consumer lag rather than exhausting connection pools: the
system degrades in **freshness, not availability** (§5.7). Storage is chosen per service rather
than uniformly: strong consistency for trips and money, deliberately disposable in-memory storage
for driver location, and eventual consistency for surge pricing (§6.1). Because no ACID transaction
can span service boundaries, booking runs as an orchestrated Saga with explicit compensating
transactions and idempotency keyed on `trip_uuid` (§6.4). Circuit breakers, rate limiters,
backpressure and dead-letter queues are implemented once at the service-mesh and broker layers
rather than repeated in ten codebases (§7).

Every significant decision in this document names what it gave up. Those losses are collected in
§9.
