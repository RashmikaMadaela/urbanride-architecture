## 3. Requirements & Scale Analysis

<!-- OWNER: M2 | SOURCE: Brief §2.1, §3 | TARGET: ~1.5 pages -->
<!-- NOTE: §3.3 is load-bearing. Every later section references these numbers. -->

### 3.1 Functional requirements

[[ WRITE HERE ]]

### 3.2 Non-functional requirements

| Constraint | Target |
|---|---|
| Throughput | |
| Latency | |
| Burst tolerance | |
| Cost | |

### 3.3 Derived scale figures

<!-- Copy the full derivation table from Brief §3.1 -->

| Quantity | Derivation | Value |
|---|---|---|
| | | |

### 3.4 Scale comparison to production systems

<!-- The Uber/UrbanRide ratio table from Brief §3.2.
     This justifies every simplification later, so it must appear early. -->

| | Uber | UrbanRide | Ratio |
|---|---|---|---|
| | | | |

### 3.5 Key observations

<!-- Three short paragraphs:
     - Transactional workload is small (~12 writes/sec)
     - Location workload is high-operation, low-volume (~3.75 MB/s)
     - Implication: correct data structures matter more than large hardware -->

[[ WRITE HERE ]]
