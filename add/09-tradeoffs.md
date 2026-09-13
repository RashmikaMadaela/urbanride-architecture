## 9. Trade-Off Summary

<!-- OWNER: M3 | SOURCE: Brief §7 | TARGET: ~1 page -->
<!-- EVERY ROW MUST NAME A REAL LOSS.
     Architectures without downsides read as wish lists. -->

| Decision | We chose | We gave up | Why |
|---|---|---|---|
| Driver location durability | In-memory Redis without persistence | Location loss on node failure | Drivers re-ping within 4 seconds; durable storage would pay heavily for data that becomes stale quickly. |
| Surge consistency | AP and freshness-first | Exact multiplier consistency | Late events do not improve a current estimate; availability is more useful than a perfect snapshot. |
| Billing consistency | CP PostgreSQL | Availability during a partition | Failing a payment is safer than double charging. |
| Matching algorithm | H3 K-ring approximation | Guaranteed nearest driver | O(1)-style cell lookups avoid an O(n) scan over all drivers. |
| Match quality | H3 candidates then ETA ranking | A full road-network spatial index | This keeps most of the quality at a fraction of the build and operating cost. |
| Saga coordination | Orchestration for booking | Looser coupling of pure choreography | Central state and explicit compensations make failures diagnosable. |
| Dispatch sharding | Managed Redis | Uber-style Ringpop | The custom system is not justified at roughly 19,000 location updates/sec. |
| Compute placement | 70% spot for stateless work | Interruption-free capacity there | Savings are useful, while stateful systems stay on-demand. |
| Routing | Self-hosted OSRM on OSM | Google's traffic-aware accuracy and lower operations burden | Vendor routing would cost about 64 LKR/ride; self-hosting is required by the budget. |
| Notification Service | Push-first, SMS for OTP only | Reachability when the app is closed | Two SMS messages per ride would consume 20% of the budget |
| Fare quoting | 60-second pinned quote | Protection from adverse surge movement during the window | Riders must see the same fare they are charged. |
