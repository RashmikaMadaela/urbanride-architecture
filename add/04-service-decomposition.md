## 4. Domain & Service Decomposition

<!-- OWNER: M1 | SOURCE: Brief §5.1, §5.2 | TARGET: ~3 pages | RUBRIC: 25% -->

### 4.1 Bounded contexts

[[ WRITE HERE ]]

### 4.2 Service catalogue

<!-- Copy from Brief §5.1. THESE NAMES ARE CANONICAL - everyone uses them verbatim. -->

| Service | Responsibility | Why separate | Data store |
|---|---|---|---|
| | | | |

### 4.3 Decomposition rationale

<!-- Call out the non-obvious splits:
     - Location Ingestion vs Driver Service (opposite write profiles)
     - Billing isolated (separate blast radius) -->

[[ WRITE HERE ]]

### 4.4 Inter-service communication

| Path | Protocol | Reasoning |
|---|---|---|
| | | |

<!-- State the governing rule: synchronous only where the caller cannot proceed
     without the answer; everything else is an event. -->

### 4.5 Data ownership & isolation

<!-- Database-per-service; no shared schemas; no cross-service joins -->

[[ WRITE HERE ]]

---

![C4 Level 1 - System Context](../diagrams/c4-01-context.png)

**Figure 1 — C4 Level 1: System Context.** [[ caption ]]

<!-- DIAGRAM 1 | OWNER: M1 | FILE: diagrams/c4-01-context.png
     Shows: UrbanRide as one box; external actors = Rider, Driver, Payment Gateway,
     SMS Provider, Push Notification Service, OpenStreetMap data source.
     Keep deliberately simple - this is for non-technical stakeholders. -->

---

![C4 Level 2 - Container](../diagrams/c4-02-container.png)

**Figure 2 — C4 Level 2: Container.** [[ caption ]]

<!-- DIAGRAM 2 | OWNER: M1 | FILE: diagrams/c4-02-container.png
     Shows: all 9 services + API Gateway + Kafka + Redis + PostgreSQL + OSRM + S3.
     LABEL EVERY ARROW with its protocol (gRPC / REST / WebSocket / Kafka topic).
     This is the most important diagram in the document. -->
