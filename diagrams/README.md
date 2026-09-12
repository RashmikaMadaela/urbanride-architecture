# Diagrams

Export here as **PNG at 200 DPI minimum**, or SVG. Use the exact filenames below — the ADD section
files already reference them, so a mismatched name means a broken image in the final PDF.

| File | Owner | Level | Required? |
|---|---|---|---|
| `c4-01-context.png` | M1 | C4 L1 | **Yes** |
| `c4-02-container.png` | M1 | C4 L2 | **Yes** |
| `c4-03-component-matching.png` | M2 | C4 L3 | **Yes** |
| `state-01-trip-lifecycle.png` | M3 | — | Strongly recommended |
| `saga-01-booking.png` | M3 | — | Strongly recommended |
| `seq-01-ride-request.png` | M2 | — | Optional |
| `resilience-01-layers.png` | M3 | — | Optional |
| `cost-01-breakdown.png` | M4 | — | Optional |

Put editable sources in `source/` so someone else can fix a typo without redrawing from scratch.

## C4 conventions

- **Level 1 (Context):** the system as one box, plus external actors and systems. No internals.
- **Level 2 (Container):** deployable units — services, databases, message brokers, caches.
  **Label every arrow with its protocol.**
- **Level 3 (Component):** internals of *one* container. We are doing the Matching Engine.

Include a legend on each diagram. Keep the visual style consistent across all three — differing
shapes and colours between diagrams reads as three people working in isolation, which is exactly
the impression to avoid.
