## 2. Introduction & Scope

<!-- OWNER: M1 | SOURCE: Brief §2, §6.8 | TARGET: ~0.5 page -->

### 2.1 Problem statement

<!-- What UrbanRide is and what the backend must do -->

UrbanRide is a ride-hailing platform connecting riders who need a journey with drivers able to
provide one. This document specifies the backend that makes that connection: it must accept a
ride request, identify nearby available drivers, rank them by realistic road-network travel time,
assign exactly one of them, track the resulting trip through to completion, price it, and settle
payment, all while a continuous stream of GPS positions from every online driver keeps the view of
the fleet current.

Four constraints define the engineering problem. The platform must sustain **1,000,000 completed
rides per day**, hold **high-frequency transactions under 500ms**, absorb **sudden demand surges**
of the kind produced by weather and events without loss of availability, and operate at a cost
**below 10 LKR per completed ride**. These are not independent: the cheapest way to meet a latency
target is usually to buy capacity, and the cheapest way to meet a cost target is usually to shed
it. §3 derives what these figures actually mean in requests per second, and every subsequent
design decision is justified against those derived numbers rather than against the headline
figures.

### 2.2 Scope and assumptions

<!-- State explicitly:
     - Single-region deployment with documented multi-region roadmap - decision D3
     - Cloud provider and region - decisions D1, D2
     - Cost interpretation sentence - decision D5, quoted verbatim
-->

This document specifies a **single-region deployment on AWS in `ap-south-1` (Mumbai)**, the region
closest to Sri Lanka. Mumbai carries roughly a 10–15% price premium over `us-east-1`, and the cost
model in §8 is built on Mumbai list prices rather than the cheaper US figures.

Single-region is a deliberate choice rather than an omission. Multi-region active-active roughly
doubles infrastructure cost and introduces cross-region consistency problems that the stated
requirements do not ask us to solve; the migration path is documented as future work in §10.2.

The design assumes drivers report position every 4 seconds, that the average ride lasts
approximately 20 minutes, and that a driver completes roughly 16 rides per working day. These
assumptions propagate into every capacity figure in the document, so each is recorded with its
status (verified, derived, or estimated) in Appendix A. Anything still unverified is marked as
such rather than presented as fact.

On the cost constraint:

> We interpret the 10 LKR target as cloud infrastructure and platform operating cost,
> excluding payment processing fees, driver payouts, and customer acquisition.

This interpretation is stated because the requirement is ambiguous and the ambiguity is material.
Payment processing alone typically runs 2–3% of fare value, which on a 600 LKR fare is 12–18 LKR
per ride, over the entire ceiling before a single server is provisioned. That is a cost of
revenue rather than an architectural decision, and no backend design can remove it. The same
wording is used in §8.1 so the interpretation appears identically wherever it is relied upon.

### 2.3 Out of scope

<!-- Mobile app internals, driver onboarding/KYC, fraud ML, support tooling -->

The following are acknowledged as necessary to a real platform but are not specified here: the
internals of the rider and driver mobile applications, beyond the protocols they speak to the
backend; driver onboarding, background checks and KYC document verification; fraud detection and
risk-scoring models; customer support tooling; and the analytics warehouse and its data models,
which consume the `trip.events` stream but do not shape the transactional architecture. The
machine-learning components that a mature platform would apply to matching and ETA prediction are
also out of scope, and appear in §10.2 as future work.
