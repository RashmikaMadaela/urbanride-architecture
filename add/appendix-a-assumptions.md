## Appendix A: Assumptions Register

<!-- OWNER: M4 -->
<!-- Every figure carries its status: Given, Locked, Derived, or Modelling assumption. -->

### Given / locked requirements

| ID | Assumption / Figure | Value | Status | Impact / Verification |
|---|---|---:|---|---|
| G1 | Completed rides/day | 1,000,000 | Given | Drives all monthly and annual volume calculations |
| G2 | Cost ceiling | 10 LKR/ride | Given | Formal scope is cloud infrastructure and platform operating cost only |
| G3 | Demand burst | 5x | Given | Drives peak request rate and headroom |
| G4 | Cloud provider and region | AWS, ap-south-1 (Mumbai) | Locked | Pricing basis for the §8 cost model |
| G5 | Deployment topology | Single-region | Locked | Multi-region is future work; avoids duplicated production cost |

### Derived figures

| ID | Assumption / Figure | Value | Status | Impact / Verification |
|---|---|---:|---|---|
| D1 | Monthly rides | ~30,000,000 | Derived | 1,000,000 x 30 |
| D2 | Annual rides | ~365,000,000 | Derived | 1,000,000 x 365 |
| D3 | Peak concurrent online drivers | ~75,000 | Derived | See §3.3; sizes WebSocket and Redis |
| D4 | Peak location writes | ~19,000/sec; ceiling 25,000/sec | Derived | See §3.3 |
| D5 | Peak location data | ~3.75 MB/sec | Derived | 25,000 events/sec x 150 bytes |
| D6 | Peak active trips | ~30,000 | Derived | See §3.3 |
| D7 | ETA calculations | 30/ride; ~30M/day; ~1,500/sec peak | Derived/modelled | Sizes OSRM and Routing Service |
| D8 | Trip data volume | ~2 GB/day; ~730 GB/year | Derived | Based on 2 KB/trip record |
| D9 | Egress and map traffic | ~15 TB/month outbound; ~18 TB/month map tiles | Derived/modelled | Sizes CDN and egress budget |

### Modelling assumptions

| ID | Assumption / Figure | Value | Status | Impact / Verification |
|---|---|---:|---|---|
| M1 | Average ride duration | ~20 minutes | Assumption | Drives concurrent-trip estimate; validate against product data |
| M2 | Rides per driver per day | ~16 | Modelling assumption | Produces ~60,000 active drivers |
| M3 | GPS ping interval | 4 seconds | Assumption / industry reference | Supports ~19,000 location writes/sec |
| M4 | Location event size | ~150 bytes | Modelling assumption | Produces ~3.75 MB/sec at design ceiling |
| M5 | Trip record size | ~2 KB | Modelling assumption | Produces ~2 GB/day and ~730 GB/year |
| M6 | Outbound data per ride | ~500 KB | Modelling assumption | Softest input to ~15 TB/month egress estimate |
| M7 | Compute mix | 70% spot / 30% on-demand | Modelling assumption | Applies only to interruption-tolerant workloads |
| M8 | EKS worker nodes | ~12 | Sizing estimate | Supports ~50 pods and ~2x spike headroom |
| M9 | Kafka capacity | 3 brokers, RF 3, 24-hour retention | Sizing decision | ~25,000 messages/sec design point; on-demand because stateful |
| M10 | Redis capacity | 3 shards plus replicas | Sizing decision | Supports ~75,000 online drivers and H3 lookup |
| M11 | OTP usage | 500,000 active riders; 1 OTP/rider/month | Modelling assumption | Produces ~500,000 SMS/month |
| M12 | FX rate | 328 LKR/USD, recorded 13 Sep 2026 | Working assumption | Used only for USD-to-LKR conversion; the Central Bank of Sri Lanka indicative rate was 328.5966 on that date. |
