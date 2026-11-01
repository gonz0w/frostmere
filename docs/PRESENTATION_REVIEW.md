# Presentation review · September 24, 2026

Roadmap #4 now has a presentation implementation and M5 verification pass ready for review. M1 validation, extended human play, subjective audio approval and the remaining frame-time investigation stay open. No release was made.

Open [the local review](../build/presentation-review/index.html) for native opening, camera, effects and dialogue views, nine existing original synth scores, 32 sound cues and an actual engine recording of the opening.

## Changes

- Rebuilt the distant opening beast with a layered trunk, articulated head/jaw, swept horns, cheek ridges, muzzle, teeth and claws. Added fractured cliff faces and ice lips. Existing story, timing, skip and village handoff remain intact.
- Batched static opening scenery by material and shared its repeated materials. Hid the combat stats panel during the noncombat prelude and made subtitles proportional to the viewport; captures cover 1280×800 and 800×600.
- Important sound cues can replace lower-priority sounds in the bounded 12-voice effects pool. Footsteps cannot evict the reveal or other critical cues.
- Ground-slam debris reuses two immutable mesh/material resources across bursts while retaining independent fragment motion.
- Reviewed existing Edda, Rook and Mereth dialogue presentation and provided current music/effects for listening review. This pass did not rewrite the campaign or recompose the scores.

## Evidence and limits

259 assertions passed across nine targeted suites: dark intro 35, presentation 14, audio 38, spatial audio 12, ground slam 7, monster effects 23, mage/projectiles 57, combat 46, creature executions 27. The separate intro-preview startup/isolation/handoff fixture also passed. Native capture and lifecycle evidence is linked in the gallery directory.

The four realm group-combat samples use the actual player camera, real enemy AI and scripted player attacks against enlarged enemy health. Both adds and each boss produced windups. M5 Max / Metal Mobile / 1280×800 p95 frame intervals: Aeralis first person 9.683 ms, third person 9.618 ms; Crucible first person 9.110 ms, third person 9.111 ms. These short stationary encounters do not establish campaign balance or M1 performance. See [group results](../build/presentation-review/group-performance.json).

Repeated river/village movement and Rimefang AI samples had p95 intervals of 9.431–9.541 ms. One first-pass Rimefang frame reached 31.841 ms; the repeated sample peaked at 10.642 ms. GPU timestamps were unavailable. The rare spike remains unresolved. See [timing traces](../build/presentation-review/visual-timing.json).

Legacy visual/realm benchmark cameras used the engine's 4000 m default; those fixtures now explicitly use the game's 450 m distance. This is a measurement correction, not evidence of a runtime optimization or a comparable speedup over those earlier reports.

All 41 source WAV files were non-silent 16-bit PCM with no full-scale clipped samples. The audio audit does not replace listening review. Camera screenshots freeze actors for readability; active-combat evidence comes from the separate benchmark. Test profiles disable character and atlas persistence. Offline gallery assets and JavaScript are checked; browser interaction is not automated.

The native lifecycle stress run completed 120 measured cycles plus three warmups in 198.707 seconds, rebuilding the opening and traveling through Pinehall, Wyrmkeep, Crucible, Aeralis and home each cycle. It exercised effect pause, travel cancellation and expiry. Settled counts stayed at 17,976 nodes, zero orphans and 137 resources; Godot static allocator usage rose from 420.969 to 421.500 MiB (about 0.53 MiB, including retained report samples). This is allocator usage, not RSS/VRAM, and a short lifecycle test rather than hours-long active play. Native review captures/audio ran concurrently during part of this lifecycle run; its elapsed time is not a performance benchmark. See [lifecycle results](../build/presentation-review/lifecycle.json).

Review contains 18 views (13 presentation captures, four effects views and one pre-change opening reference). Native engine audio recording: 13.42 seconds, PCM16 peak 11,370, no clipping.
