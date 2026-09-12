## 8. Infrastructure & Cost

<!-- OWNER: M4 | SOURCE: Brief §6 (all) | TARGET: ~3.5 pages | RUBRIC: 20% -->

### 8.1 Budget in real terms

<!-- 10 LKR -> USD -> daily / monthly / annual ceiling.
     STATE THE FX RATE AND THE DATE IT WAS CHECKED. -->

[[ WRITE HERE ]]

### 8.2 The third-party API finding

<!-- LEAD WITH THIS - it is the strongest cost argument in the document -->

| Call | Volume/ride | Rate | Cost/ride |
|---|---|---|---|
| | | | |

<!-- The Route Matrix element-billing detail is what makes it catastrophic.
     Result: ~64 LKR/ride = 6.4x over budget.
     Conclusion: self-hosted routing is mandatory, not an optimization.
     Note Grab's precedent (Pharos on OSM graphs). -->

[[ WRITE HERE ]]

### 8.3 Infrastructure cost model

| Component | Sizing rationale | Monthly (USD) |
|---|---|---|
| | | |
| **TOTAL** | | |

### 8.4 Instance sizing rationale

<!-- EXPLICIT RUBRIC REQUIREMENT
     Short paragraph per major component explaining WHY THAT SIZE,
     tied back to the §3.3 scale figures. -->

[[ WRITE HERE ]]

### 8.5 Compute placement: spot vs on-demand

<!-- What runs on spot and what does not.
     THE WEBSOCKET EXCEPTION: a service holding 75k persistent connections is not
     stateless; it runs on-demand. Graceful drain + jittered client reconnect as
     defence in depth.
     Honest counter-argument: 41% of workloads lose money on spot once interruption
     costs are counted; our defence is placement discipline. -->

[[ WRITE HERE ]]

### 8.6 Autoscaling triggers

<!-- EXPLICIT RUBRIC REQUIREMENT -->

| Service | Scale-out trigger | Scale-in | Min/Max |
|---|---|---|---|
| | | | |

<!-- Note the deliberately slow scale-in cooldowns and why
     (prevents thrashing during oscillating weather demand). -->

### 8.7 Notification cost strategy

<!-- Push-first, SMS for login OTP only.
     Contrast: 2 SMS/ride = 2 LKR/ride = 20% of budget, ~13x all server costs. -->

[[ WRITE HERE ]]

### 8.8 Result & scenario comparison

| Scenario | LKR/ride | vs budget |
|---|---|---|
| | | |

### 8.9 Cost-optimization levers summary

| Lever | Our application | Expected saving |
|---|---|---|
| | | |

---

![Monthly cost breakdown](../diagrams/cost-01-breakdown.png)

**Figure 8 — Monthly infrastructure spend by component.** [[ caption ]]

<!-- DIAGRAM 8 | OWNER: M4 | FILE: diagrams/cost-01-breakdown.png
     Bar or pie of monthly spend. Makes the point that routing/egress/tiles
     dominate, not compute. -->
