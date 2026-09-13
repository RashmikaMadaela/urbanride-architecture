## Appendix A — Assumptions Register

<!-- OWNER: M4 -->
<!-- Anything unverified must be marked as such, not presented as fact.
     This is cheap insurance if a panellist challenges a number. -->

### Given / locked requirements

| ID | Assumption / Figure | Value | Status | Impact / Verification |
|---|---|---:|---|---|
| G1 | Completed rides/day | 1,000,000 | Given | Drives all monthly and annual volume calculations |
| G2 | Cost ceiling | 10 LKR/ride | Given | Formal scope is cloud infrastructure and platform operating cost only |
| G3 | Demand burst | 5x | Given | Drives peak request rate and headroom |
| G4 | Cloud provider and region | AWS, ap-south-1 (Mumbai) | Locked | Verify current AWS regional pricing |
| G5 | Deployment topology | Single-region | Locked | Multi-region is future work; avoids duplicated production cost |

### Derived figures

| ID | Assumption / Figure | Value | Status | Impact / Verification |
|---|---|---:|---|---|
| D1 | Monthly rides | ~30,000,000 | Derived | 1,000,000 x 30 |
| D2 | Annual rides | ~365,000,000 | Derived | 1,000,000 x 365 |
| D3 | Peak concurrent online drivers | ~75,000 | Derived | From M2 §3.3; sizes WebSocket and Redis |
| D4 | Peak location writes | ~19,000/sec; ceiling 25,000/sec | Derived | From M2 §3.3 |
| D5 | Peak location data | ~3.75 MB/sec | Derived | 25,000 events/sec x 150 bytes |
| D6 | Peak active trips | ~30,000 | Derived | From M2 §3.3 |
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
| M12 | FX rate | 328 LKR/USD, recorded 13 Sep 2026 | Working assumption | Used only for USD-to-LKR conversion; CBSL displayed 328.5966 indicative USD/LKR when checked. **VERIFY** current rate before submission. |

### External figures requiring verification

The figures in this section are working estimates for architecture modelling, not vendor quotations. They are subject to change with region, contract, usage and provider pricing. Where authoritative current pricing is available, each figure must be rechecked before final submission; otherwise it remains a model assumption marked **VERIFY**. AWS public pricing pages and the Google Maps pricing list are source references, but the UrbanRide monthly amounts remain workload models unless reproduced in the relevant vendor calculator with the complete workload.

| ID | Assumption / Figure | Value | Status | Source & Notes |
|---|---|---|---|---|
| X1 | AWS ap-south-1 pricing | Working estimate; not a quotation (Monthly USD) | Modelled — VERIFY | Region is locked to ap-south-1; actual amount depends on selected services, instance families, utilization and discounts. Source: [AWS pricing](https://aws.amazon.com/pricing/) and [AWS Pricing Calculator](https://calculator.aws/). |
| X2 | AWS service and data-transfer pricing | Working estimate; not a quotation (Monthly USD) | Modelled — VERIFY | Official rate cards are inputs; complete workload, traffic, storage and observability volumes were not recreated in the calculator. Source: [EC2](https://aws.amazon.com/ec2/pricing/), [S3](https://aws.amazon.com/s3/pricing/), [CloudFront](https://aws.amazon.com/cloudfront/pricing/), [CloudWatch](https://aws.amazon.com/cloudwatch/pricing/). |
| X3 | Compute Route Matrix Essentials and final team comparison scenario | $5 first listed paid tier; ~$0.160/ride team scenario (Per 1,000 elements; per ride scenario) | Verified vendor list price; workload scenario VERIFY | Elements = origins x destinations. The final team comparison uses M3's approved ~$0.194/ride full scenario, reported as ~64 LKR/ride at 328 LKR/USD; this is not a guaranteed vendor bill. Source: [Google Maps global pricing](https://developers.google.com/maps/billing-and-pricing/pricing); [Routes billing](https://developers.google.com/maps/documentation/routes/usage-and-billing); M3 final trade-off figure. |
| X4 | Compute Routes Essentials | $5 first listed paid tier (Per 1,000 requests) | Verified vendor list price; workload tier VERIFY | The UrbanRide scenario assumes 2 requests/ride; this is separate from the vendor rate. Source: [Google Maps global pricing](https://developers.google.com/maps/billing-and-pricing/pricing); [Routes billing](https://developers.google.com/maps/documentation/routes/usage-and-billing). |
| X5 | Geocoding | $5 first listed paid tier (Per 1,000 requests) | Verified vendor list price; workload tier VERIFY | The UrbanRide scenario assumes 2 requests/ride; current account-level tier still requires verification. Source: [Google Maps global pricing](https://developers.google.com/maps/billing-and-pricing/pricing); [Geocoding billing](https://developers.google.com/maps/documentation/geocoding/usage-and-billing). |
| X6 | Dynamic Maps | $7 first listed paid tier (Per 1,000 loads) | Verified vendor list price; workload tier VERIFY | The UrbanRide scenario assumes 2 loads/ride; product usage and account tier must be confirmed. Source: [Google Maps global pricing](https://developers.google.com/maps/billing-and-pricing/pricing). |
| X7 | EKS compute | $975 model (Monthly USD) | Modelled — VERIFY | Approximately 12 nodes and 70% Spot/30% On-Demand; Spot availability, instance mix and utilization are not fixed. Source: [EKS pricing](https://aws.amazon.com/eks/pricing/), [EC2 Spot pricing](https://aws.amazon.com/ec2/spot/pricing/). |
| X8 | Kafka | $540 model (Monthly USD) | Modelled — VERIFY | Three brokers, replication factor 3 and retention are sizing assumptions; managed versus self-managed deployment changes the price. Source: [Amazon MSK pricing](https://aws.amazon.com/msk/pricing/). |
| X9 | Redis | $660 model (Monthly USD) | Modelled — VERIFY | Three shards plus replicas; node family, storage, throughput and Multi-AZ choices require validation. Source: [ElastiCache for Redis pricing](https://aws.amazon.com/elasticache/redis/pricing/). |
| X10 | PostgreSQL | $1,565 model (Monthly USD) | Modelled — VERIFY | Separate Trip Management Service and Billing Service instances; Multi-AZ/replica, instance family, storage, I/O and backup retention are not fully specified for a calculator quotation. Source: [RDS for PostgreSQL pricing](https://aws.amazon.com/rds/postgresql/pricing/). |
| X11 | OSRM | $1,035 model (Monthly USD) | Modelled — VERIFY | Self-hosted OSRM cost depends on road-graph memory, CPU profile, replica count, utilization and scaling behaviour. Source: AWS EC2 and EKS pricing references. |
| X12 | ALB + WebSocket termination | $300 model (Monthly USD) | Modelled — VERIFY | Approximately 75,000 persistent connections; LCU usage, bytes processed and connection duration require measurement. Source: [Elastic Load Balancing pricing](https://aws.amazon.com/elasticloadbalancing/pricing/). |
| X13 | S3 archive, NAT and observability | $810 model (Monthly USD) | Modelled — VERIFY | Archive volume, NAT bytes, logs, metrics and retention are workload-dependent. Source: [S3 pricing](https://aws.amazon.com/s3/pricing/), [CloudWatch pricing](https://aws.amazon.com/cloudwatch/pricing/). |
| X14 | Data egress and CDN | $1,350 and $1,200 models (Monthly USD) | Modelled — VERIFY | Approximately 15 TB outbound and 18 TB map-tile traffic; CDN distribution, cache hit ratio and destination mix require validation. Source: [CloudFront pricing](https://aws.amazon.com/cloudfront/pricing/) and AWS data-transfer pricing. |
| X15 | Local bulk SMS price | ~1 LKR/SMS (Per SMS) | Requires provider quotation | **VERIFY — provider quotation required.** Keep 1 LKR/SMS only as a modelling assumption, not verified vendor pricing. Source: No authoritative public provider tariff confirmed. |
| X16 | OSRM and map-tile operating cost | $1,035 and $1,200 models (Monthly USD) | Modelled — VERIFY | These are not vendor quotations; benchmark the self-hosted road graph and CDN workload before deployment. Source: Architecture model using AWS rate-card references. |
| X17 | USD/LKR conversion | 328 working assumption; CBSL displayed 328.5966 indicative rate (LKR per USD) | Modelled — VERIFY | 328 is retained only as a rounded conversion assumption; recheck the relevant submission-date rate. Source: [Central Bank of Sri Lanka exchange rates](https://www.cbsl.gov.lk/en/rates-and-indicators/exchange-rates). |
