## 7. Scalability & Resiliency Blueprint

<!-- OWNER: M3 | SOURCE: Brief §5.8 | TARGET: ~2 pages -->
<!-- ALL FOUR named mechanisms must appear - the assignment lists them by name. -->

### 7.1 Circuit breakers

<!-- Envoy sidecar outlier detection; service-mesh layer not application code.
     Cite Lyft rationale: identical networking code copy-pasted across services
     became unmaintainable. -->

[[ WRITE HERE ]]

### 7.2 Rate limiters

<!-- Token bucket per rider/driver/IP at edge; per-service quotas in mesh -->

[[ WRITE HERE ]]

### 7.3 Backpressure

<!-- Kafka consumer lag -> autoscale; bounded queues;
     load shedding order (shed fare estimates before ride requests) -->

[[ WRITE HERE ]]

### 7.4 Dead-letter queues

<!-- Retry with exponential backoff -> .dlq topic;
     failed messages never block live traffic -->

[[ WRITE HERE ]]

### 7.5 Additional patterns

<!-- Graceful degradation, timeouts everywhere, bulkheads -->

[[ WRITE HERE ]]

### 7.6 Failure scenario walkthroughs

<!-- Short paragraph each -->

**5x traffic spike.** [[ WRITE HERE ]]

**Redis cluster failure.** [[ WRITE HERE ]]

**Network partition between services.** [[ WRITE HERE ]]

**Spot instance reclaim on connection-holding services.** [[ WRITE HERE ]]

<!-- DIAGRAM 7 (OPTIONAL - build only if time allows) | OWNER: M3
     FILE: diagrams/resilience-01-layers.png
     Where each mechanism sits in the request path. -->
