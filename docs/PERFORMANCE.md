> Historical development record. Live work moved to [GitHub Issues](https://github.com/gonz0w/frostmere/issues) on November 1, 2026. Earlier counts, priorities, unchecked lists and build links below are retained as dated evidence, not current assignments. See [project policy](../PROJECT.md).

# Regional performance baseline

Native development build: Apple M5 Max (Apple9), 4.7.2-stable (official), mobile / metal, viewport (1280, 800). VSync enabled. 357,464 batched world blocks.

| Fixed view | Frames | Median ms | p95 ms | p99 ms | Draw calls (last frame) | Godot static memory MiB |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| Frostmere | 601 | 8.31 | 9.29 | 9.36 | 2443 | 360.2 |
| Pinehall | 600 | 8.33 | 8.70 | 8.82 | 183 | 360.8 |
| Wyrmkeep | 601 | 8.32 | 8.91 | 9.00 | 1532 | 363.5 |

Each fixed view: 2 s warmup, 5 s wall-clock frame intervals. Idle world logic, player movement/input disabled, audio silent. One development-build run; not a moving/combat or M1 benchmark. Static memory is Godot allocator usage, not total process RAM or VRAM.

All three median intervals are near 8.33 ms (120 FPS). With VSync enabled this measures paced delivery, not uncapped rendering headroom. These are separate fixed views with different visible content; draw-call counts alone do not establish a bottleneck. The process-time monitor in the JSON is an engine-reported frame metric, not a CPU-only profiler.

## Repeat the sample

From the project root:

```sh
.tools/Godot.app/Contents/MacOS/Godot --path . --script tools/benchmark_regions.gd -- --capture
```

The fixture requires a native renderer, verifies isolated character/atlas persistence, samples each view after a two-second warmup for five seconds, and writes `build/region-performance.json`. Run serially, with comparable resolution, VSync and background workload. It does not package a release or read/write the regular character save.

Remaining performance work: moving/combat workloads, longer sessions, profiling town draw calls, and measurements on the M1 baseline machine. No pre-change comparison was run, so this establishes a current baseline rather than quantifying the cost of the recent polish.


## Moving-view and active-combat samples

Same M5 Max / Mobile Metal configuration, (1280, 800) viewport, VSync enabled. Separate run from the fixed-view baseline.

| Scenario | Frames | Median ms | p95 ms | p99 ms | Last-frame draw calls | Godot static memory MiB |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| Colossus Active | 1414 | 8.68 | 10.43 | 11.93 | 4130 | 373.6 |
| Pinehall Moving | 941 | 8.36 | 9.71 | 12.13 | 4511 | 372.4 |

2 s warmup per scenario. Pinehall: 8 s scripted moving camera, stationary player. Colossus: 12 s orbiting camera, actual enemy AI against a stationary invulnerable target, no player attacks; authored cooldowns retained. Audio silent. Frame intervals use wall clock. Static memory is Godot allocator usage, not RSS/VRAM. One development-build run, not M1 or human gameplay validation.

Observed 2 actual Colossus debris events across warmup and measurement; the harness asserts at least two. Both p95 values were below 16.67 ms (a 60 FPS frame budget), but a percentile does not guarantee every frame meets it. Different camera angles explain why these draw-call snapshots differ from the stationary views; no bottleneck or per-feature cost is established by this run.

```sh
.tools/Godot.app/Contents/MacOS/Godot --path . --script tools/benchmark_activity.gd -- --capture
```

Output: `build/activity-performance.json`. This reuses the regional timing sampler with optional camera animation and scenario durations. Remaining work includes multi-enemy/player-attack workloads, UI/audio interactions, longer sessions, profiling and M1 runs.


## Repeated region/effect lifecycle stress

A native M5 Max run completed in 51.82 seconds, including three warmup cycles and 30 measured cycles. Each cycle visits Pinehall, Wyrmkeep, Crucible, Aeralis and home, creating four effects and checking pause hiding, travel cancellation and natural expiry. This exercises 120 effect instances during measured cycles (plus 12 during warmup).

| Settled metric | After warmup | After 30 cycles |
| --- | ---: | ---: |
| Nodes | 15,568 | 15,568 |
| Orphan nodes | 0 | 0 |
| Loaded resources | 106 | 106 |
| Godot static memory MiB | 365.04 | 365.41 |

All measured cycles retained identical settled node, orphan and resource counts. Static memory rose by 0.37 MiB. The report itself accumulates samples, and allocator/cache behavior may affect memory readings; this is not a leak-free guarantee.

```sh
.tools/Godot.app/Contents/MacOS/Godot --path . --script tools/soak_region_lifecycle.gd -- --capture
```

Output: `build/region-lifecycle.json`. Native isolated profile, three warmup cycles then 30 measured cycles through Pinehall, Wyrmkeep, Crucible, Aeralis and home. Four effects spawned per cycle; pause, travel cancellation and natural expiry checked. Enemy attacks disabled to isolate lifecycle counts. Static memory is Godot allocator usage, not RSS/VRAM. This short stress run does not establish hours-long save/session stability. This fixture does not exercise disk save/load, inventory growth, player combat or hours-long sessions. Those checks and M1 hardware validation remain open.


## Visual-polish frame diagnostics and HUD cleanup

The moving river/Rimefang spikes recorded in `build/visual-polish-performance.json` remain open. `tools/benchmark_visual_timing.gd` now runs the same paired scenarios while retaining an unsorted per-frame trace, draw-call distributions and viewport CPU/GPU render timings. GPU counters returned only zero on this Metal run: this means **unavailable timing**, not zero GPU cost. Process/physics monitors refresh less often than frames and GPU results may be delayed; trace columns are observations, not synchronized profiling spans.

Run the diagnostic serially, with no other benchmark or test process:

```sh
.tools/Godot.app/Contents/MacOS/Godot --path . --script tools/benchmark_visual_timing.gd -- --capture --report=visual-polish-timing
```

Optional `--no-shadows` and `--no-vsync` controls are isolated experiments. Use distinct `--report=` names to preserve comparisons. Neither modifies project settings or the normal save. Production shadows and VSync remain unchanged. Full traces go to JSON; console output omits them.

Four development runs are retained in the linked report: instrumented baseline, shadows disabled, VSync disabled, and normal settings after HUD cleanup. The first two preceded the HUD change; the unpaced run already includes it, so that comparison does not isolate VSync alone. The earliest unpaced JSON records the startup VSync value, before the fixture disabled it; the finalized tool switches mode before report creation and records actual mode per sample. See the measured results (local `build/visual-polish-timing-report.md`).

The HUD now builds objective/vital strings locally and assigns the finished strings once, avoiding intermediate empty and partial label updates each frame. Quest priority, resource values, spell costs and interaction timing remain unchanged. Campaign guidance (21) and mage/projectile/HUD (57) checks pass, 78 total. This is an avoidable UI-work cleanup, not a demonstrated fix for the rendering spikes.

Neither the shadow experiment nor the unpaced experiment eliminated the spikes consistently. Per-viewport CPU rendering is only part of the frame; the missing GPU measurement prevents a reliable GPU/CPU bottleneck attribution. Next profiling should collect usable GPU/frame-presentation data and test representative batch/culling changes against identical views, preserving detail. M1 validation, crowded player combat and longer sessions remain required.


## Refined destination guardians — September 24, 2026

Native Apple M5 Max / Godot 4.7.2 / Mobile Metal, 1280 × 800, VSync enabled. Each realm: 2 s warmup plus 8 s orbit, actual AI against a stationary invulnerable player, no player attacks, silent audio, isolated saves. One current-build run, not a before/after optimization comparison.

| Realm | Median ms | p95 ms | p99 ms | Last-frame draws | Observed windups |
| --- | ---: | ---: | ---: | ---: | ---: |
| aeralis | 11.88 | 13.69 | 15.22 | 5620 | 3 |
| crucible | 16.34 | 21.41 | 22.16 | 8245 | 2 |

Crucible p95 exceeds the 16.67 ms 60 FPS budget. This arena still needs optimization; these measurements do not identify a bottleneck, establish a regression, or clear M1. Both runs observed real attack windups, including warmup. Do not interpret viewport frame timing as the boss model cost alone. The arena, other actors, world and HUD are included. No GPU attribution is claimed.

Repeat with `tools/benchmark_realm_bosses.gd -- --capture` using the local Godot runner. Raw results: `build/refined-realm-boss-performance.json`. The gallery reports 383 cuboids in 42 model batches for the Maw and 437 in 40 for Prismwing; these counts exclude the rest of the scene.

## Regional building construction — September 24, 2026

`tools/benchmark_buildings.gd` retains four fixed-view samples in `build/building-review/performance.json`. Native M5 Max / Metal Mobile, normal shadows, isolated profile, idle world logic. After 2 s warmup, each view records 5 s of wall-clock frame intervals. Street/interior/Wyrmkeep/Pinehall p95 values are 8.399 / 8.396 / 8.341 / 8.331 ms. These are single-run stationary results and do not close the existing moving river/combat stutter investigation or establish M1 behavior. Total static world cuboids: 331498, including 85483 from the consolidated 25 house/hall builders. No direct before/after timing claim.


## Regional landscape review — September 24, 2026

Native M5 Max / Metal Mobile, 1280×800, 450 m gameplay draw distance: 12 moving-camera samples, each with 2 s warmup and 5 s measurement. p95 frame intervals 8.761–9.658 ms; highest sample: aeralis. Tracked world cuboids: 408560. This is a single current-build camera-motion run with idle game logic, not a paired performance comparison, active combat test or M1 sign-off. Existing river/combat spike investigation remains open. See `build/landscape-review/performance.json` and `tools/benchmark_landscape.gd`.

## Presentation and active realm groups — September 24, 2026

See [PRESENTATION_REVIEW.md](PRESENTATION_REVIEW.md) and `build/presentation-review/group-performance.json`. Actual player cameras, 450 m draw distance, real AI and scripted player attacks: four M5 samples, 2 s warmup and 8 s measurement each, p95 9.110–9.683 ms. All bosses and adds produced windups. Enlarged health retains the group; this is not a balance or human-play test.

Repeated river/village/Rimefang traces are in `build/presentation-review/visual-timing.json`: p95 9.431–9.541 ms; one first-pass Rimefang frame reached 31.841 ms. GPU timing is unavailable and the spike remains open. Legacy visual-polish and realm-boss fixtures now use the actual 450 m gameplay camera distance instead of the default 4000 m; do not interpret this setup correction as runtime speedup. Opening scenery is material-batched and ground-slam bursts share immutable meshes, but isolated gains have not been measured. M1 and extended play remain required.
