# Towns and landscapes — review checkpoint

September 24, 2026. Implementation pass ready for visual review; this does not close campaign expansion, human playtesting or M1 performance validation. No release prepared.

Open `build/landscape-review/index.html`: **26 matched before/after viewpoints across 12 regions and destinations**, captured from the native game at 1280×800. Region filtering, enlargement and before/after switching are included. The architecture gallery remains a separate building/interior review. One original river camera intersected the expanded shop, so that unusable pair was removed rather than presented as a landscape comparison.

| Region | This pass |
| --- | --- |
| Frostmere | Garden/storage edges, foundation gravel, woodland understory, sparse shaped outcrops and conifers; existing refined riverbank retained |
| Wyrmkeep | Asymmetric snowy ridgelines replacing stacked pyramids, finer lane paving, snow patches, storage yards and sparse trees |
| Pinehall | Understory and rock clusters, garden edges, fine lanes, regional cloud sky; all walkable hill shoulders preserved |
| Saltbreak | Broken coastal cliffs, tidal skerries, net-covered stores, clearer road margins, coastal cloud sky and continuous rippling water |
| Sunken Lens | Weathered paving, sand patches, banded rock spurs and warm cloud light around the expedition settlement |
| Amberweald | Forked broadleaf crowns replacing flat disks, copper-colored foliage, mossy outcrops, garden dressing and woodland sky |
| Ember Caldera | Ash/gravel patches, layered basalt spurs, supply dressing, fine pilgrimage road and smoky cloud palette |
| Mirewatch | Reed beds, drowned snags, quiet water ripples and marsh sky around the existing stilt decks |
| Northwatch | Broken snowy peaks, wind-scoured ground patches and supplies outside the siege lane |
| First Threshold | Floor-edge conduit fittings outside the central station aisle |
| Aeralis | Crystal-bearing satellite ledges around existing terraces; mystical sky retained |
| Crucible | Basalt ribs outside foundry platforms; cavern ceiling and embers retained |

The current building footprints, entrances, quest positions, platforms, bridges, encounter rules and save format remain intact. New trees, rocks and substantial stores use simple collision; ground cover and paving are shallow visual details. Placement excludes existing structures, documented walking lanes, quest positions and creature spawn areas. A failed actual-climb test prompted exclusion of new solid props from Pinehall's entire walkable hill shoulders.

Inactive Aeralis/Crucible roots now hide together with their atmosphere so distant islands cannot appear over neighboring regions. Regional skies are cached and the original environment resource is restored on exit. Coastal and marsh water retain existing physical boundaries. Fine ground cover is spatially batched and culled beyond 65 m; silhouettes remain in the main scenery batches. These choices bound the implementation but do not establish M1 performance.

Primary implementation: `scripts/regional_landscape.gd`, `refined_ridges.gd`, `refined_canopy.gd`, `regional_sky.gd`, `regional_water.gd`, and the corresponding regional builders. Native capture fixture: `tests/render_landscape_review.gd`; gallery builder: `tools/build_landscape_review.py`.

All 1,014 checks across 21 suites pass. Validation results and the current-build M5 camera-motion sample are recorded beside the gallery in `validation.json` and `performance.json`. Local HTML asset paths and JavaScript syntax are checked offline; the gallery itself has not been browser-automated.

Native M5 Max / Metal Mobile, 1280×800, 450 m gameplay draw distance: 12 moving-camera samples, each with 2 s warmup and 5 s measurement. p95 frame intervals 8.761–9.658 ms; highest sample: aeralis. Tracked world cuboids: 408560. This is a single current-build camera-motion run with idle game logic, not a paired performance comparison, active combat test or M1 sign-off. Existing river/combat spike investigation remains open.
