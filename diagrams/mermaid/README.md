# Mermaid sources for redrawing in Lucidchart

These are the seven ADD diagrams expressed as Mermaid, for importing into Lucidchart and
restyling by hand. They carry the same content as the Graphviz `.dot` sources in
`diagrams/source/`: same canonical service names, same protocol labels, same numbers.

Every file here has been validated by rendering it with `mermaid-cli` 11.17, so the syntax
parses. Preview or tweak at <https://mermaid.live> before importing if you want.

| File | Replaces | Mermaid diagram type |
|---|---|---|
| `c4-01-context.mmd` | `c4-01-context.png` | `flowchart TB` |
| `c4-02-container.mmd` | `c4-02-container.png` | `flowchart TB` |
| `c4-03-component-matching.mmd` | `c4-03-component-matching.png` | `flowchart TB` |
| `seq-01-ride-request.mmd` | `seq-01-ride-request.png` | `sequenceDiagram` |
| `state-01-trip-lifecycle.mmd` | `state-01-trip-lifecycle.png` | `stateDiagram-v2` |
| `saga-01-booking.mmd` | `saga-01-booking.png` | `flowchart LR` |
| `resilience-01-layers.mmd` | `resilience-01-layers.png` | `flowchart LR` |

`cost-01-breakdown.png` is not here. It is a bar chart rather than a diagram, and Mermaid has no
stable chart type for it. Rebuild it in Lucidchart's native chart tool or in a spreadsheet.

## Simplified versions

The container, component and resilience diagrams were the three dense ones, so they are
deliberately sparser than the Graphviz originals. The structure is unchanged; what was cut is
label verbosity:

- **Node labels** are names only, or a name plus one short qualifier.
- **Edge labels** are protocols only. Detail such as timeouts, TTLs, partition counts, cache keys
  and fallback conditions now lives only in the prose that already stated it, in sections 4.4,
  5.2, 5.6, 6.1 and 7.
- The container diagram keeps all ten services and every data store, because that is what a C4
  container diagram is for, but drops the Push and SMS providers, which already appear on the
  context diagram at Figure 1.

Two things must survive any further trimming, since both are explicit marking criteria: every
edge on the container diagram carries a protocol, and the resilience diagram names all four
mechanisms (rate limiting, circuit breakers, backpressure, dead-letter topics).

## One Mermaid gotcha worth knowing

A comment line containing only `%%` breaks the parser. It is read as the opening of a
`%%{ ... }%%` directive block, which then swallows everything up to the diagram declaration.
Keep some text after the `%%` on every comment line.

## Why flowchart rather than Mermaid's C4 syntax

Mermaid does have dedicated `C4Context` / `C4Container` / `C4Component` diagram types. They are
still marked experimental upstream and are not reliably supported by third-party importers, so
the three C4 diagrams here use plain `flowchart` instead. Nothing is lost: the boundaries are
`subgraph` blocks, the element types are carried by `classDef` colours, and the
`[Person]` / `[Software System]` / `[Container]` annotations are written into the node labels
the way the C4 notation expects.

## Palette

`classDef` lines at the bottom of each file encode the palette the current PNGs use. An importer
may drop them, in which case apply these by hand so all seven diagrams stay consistent:

| Role | Fill | Stroke |
|---|---|---|
| Person / client app | `#E2F2E8` | `#2E6B43` |
| System in scope, edge, broker, pivot | `#FFF1CC` | `#9A6A00` |
| Service / component / durable store | `#E8F1FA` | `#24557A` |
| Volatile store, compensation, degraded path | `#FCE8E6` | `#A33A32` |
| External system | `#EFEFEF` | `#5A5A5A` |

`diagrams/README.md` explains why a consistent visual style across all the diagrams matters.

## Putting a redrawn diagram back into the ADD

1. Export from Lucidchart as **PNG at 200 DPI minimum**, or SVG.
2. Save it into `diagrams/` under its **existing filename** (the table above). The section files
   reference those paths, so a renamed file becomes a broken image in the PDF.
3. Rebuild and check the result:

   ```bash
   cd build && ./build.sh
   ```

   The script reports any diagram reference that fails to resolve.
4. Open `build/UrbanRide_ADD.pdf` and look at the figure. Diagrams are placed at full text
   width, so anything much taller than it is wide becomes unreadable in print. Landscape or
   roughly square proportions work best.

## If you switch away from Graphviz

Decision **D6** in `DECISIONS.md` records Graphviz as the diagramming tool, and
`diagrams/source/` holds the `.dot` files. If Lucidchart becomes the source of truth for a
diagram, update D6 and note which diagrams moved, so nobody edits the stale `.dot` and
re-renders over a redrawn PNG.
