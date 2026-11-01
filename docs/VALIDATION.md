> Historical development record. Live work moved to [GitHub Issues](https://github.com/gonz0w/frostmere/issues) on November 1, 2026. Earlier counts, priorities, unchecked lists and build links below are retained as dated evidence, not current assignments. See [project policy](../PROJECT.md).

# First prototype validation — September 8, 2026

Engine: official Godot 4.7.2 stable, native Apple Silicon.

## Automated runtime checks

`tests/smoke.gd`: 15 checks passed, no failures.

- Batched world builds (19,909 environment cuboids).
- Player settles on ground.
- Third-person startup.
- First-person avatar hiding and camera retraction.
- Third-person avatar and camera restoration.
- Jump departure and landing.
- Forward movement.
- Sprint drains stamina.
- Pausing stops movement.
- Full bridge crossing without jumping.
- Doorway and interior floor traversal without jumping.
- Wall collision.
- Return to safe spawn.
- Ruin discovery.

The jump departure and landing are separate checks; the list groups them above.

## Render validation

Inspected an engine-generated screenshot. Fixed overexposure, incomplete gables, floating tree tips, and camera framing. Rendered using native Metal, Mobile renderer. The initial materials and procedural forms remain an early art pass, not a reproduction of the concept image's final fidelity.

## Performance sample

Apple M5 Max (Apple9), 1280×800 window, development runtime, stationary starting camera. Eight-second sample after two-second warmup: 965 rendered frames, median 8.33 ms, p95 8.33 ms. Display-paced at approximately 120 FPS. No M1 measurements yet; no worst-case movement or long-duration profiling yet.

## Current limits

No combat, NPC AI, functional crafting, inventory, quest state, audio, or persistent saving. Inspect interactions at the forge and ruin are descriptive messages. The map is finite and the distant fortress is scenery. The launcher runs the source project with the local engine; a signed distributable Mac app is a later packaging step.

## Finer voxel revision — September 8, 2026

Halved terrain-cell, roof-course, foliage-layer, mountain-column, mountain-height-step, and bridge-course spacing while retaining object dimensions and collision. Added world-space pixel textures, masonry/plank relief, cobbles, branch clusters, armor scales, and fur tufts. Static geometry now uses material batches per 24 m spatial region for visibility culling.

All 15 existing runtime checks passed after the main refinement. Final shoreline and bridge geometry adjustments did not change their collision. Final combined capture and benchmark ran without script errors: 143,825 environment cuboids, Apple M5 Max, Mobile/Metal, 1280×800, 950 frames in the sample, median and p95 8.33 ms. Brief stationary sample only; M1 remains untested. Inspected the final screenshot against the saved before image and approved concept.

## Character and equipment revision — September 8, 2026

- Existing scene/movement smoke checks: 15 passed after integrating attribute-dependent stamina and speed. The sprint assertion now measures drain relative to the character's current stamina instead of assuming a fixed 100-point pool.
- `tests/characters.gd`: 36 checks passed, covering catalog integrity, slot and two-hand rules, dual wielding, gear bonuses, point limits/refunds, weight effects, mixed loadouts, atomic save roundtrip, malformed/invalid saves, all 64 ancestry/playstyle starters, and all ancestry/weapon model builds.
- `tests/character_ui.gd`: 17 checks passed, covering C/Escape navigation, pause-overlay exclusion, populated equipment lists, search, actual button/picker signal wiring, appearance updates, two-hand UI rules, and first-person state after gear changes. Automated runs do not touch the real profile.
- Inspected `build/character-armory.png`, `build/character-gallery.png` (all eight ancestry/armor families), and `build/first-person-gear.png` from actual Metal renders. Fixed an empty-search compatibility-list bug and adjusted first-person hand placement/shield-back detail.

Total: 68 automated assertions passed. Character-screen changes have not been benchmarked on the M1; previous performance samples predate this milestone. Combat and trading effects are not claimed as tested or implemented.

## World atlas and survey revision — September 8, 2026

- `tests/atlas.gd`: 42 assertions passed. Validated all regional marker positions, catalog references, reciprocal faction relations, road endpoints, acyclic quest prerequisites, rejection of planned travel/quests, objective ordering, manual-vs-quest waypoint labels, save/reload and invalid-save rejection, coordinate transforms, zoom bounds, marker selection, journal filters, overlay switching, pause/proximity guards and the complete E/bridge/E survey flow through the actual scene.
- `tests/character_ui.gd`: all 17 assertions passed with the map integrated.
- `tests/smoke.gd`: all 15 movement/camera assertions passed.
- Inspected final native Metal captures `build/world-map.png` and `build/local-map.png`. Refined fjord coastline and map labeling; corrected the local river projection to match x=10..18 and added the scene’s actual tree positions.

74 assertions were run and passed in this revision. The regional atlas is an authored plan: 47 quest entries, new regions and faction initiations remain unimplemented. The Oldwatch Survey is the one new playable quest. No continent traversal, faction joining or NPC behavior is claimed as tested.

## Collection and crafting revision — September 8, 2026

`tests/crafting.gd`: 133 checks passed. Includes every one of the 94 recipes, ownership, unique-copy upgrades, live attribute effects, gem gating/extraction, salvage protections, learned formulas, one-time chests, renewable cooldowns, atomic save round trips, legacy dual-wield migration, invalid-save rejection, actual forge/enchant buttons, workstation distance checks, world gathering, potion use/no-waste behavior, and I/M/Escape overlay transitions.

Existing scene/movement (15), character (36), character UI (17), and atlas (42) checks passed with ownership-aware fixtures and the forge workshop close step added to the survey test. The initial unlimited catalog test fixtures now explicitly create their owned test items; production equipment requires ownership.

Inspected real 1280×800 Mobile/Metal renders of the workshop, enchanting screen, and south-trail gathering props on Apple M5 Max. Screenshots: `build/workshop.png`, `build/enchanting.png`, `build/crafting-world.png`. Automated rendering does not alter the real character profile. Earlier sections describe historical milestones; crafting, inventory and character/atlas persistence are now implemented. M1 performance and complete economy balancing remain unmeasured.

## Oldwatch combat and adventure revision — September 8, 2026

46 combat/adventure checks passed, including actual smith and loot interactions, quest acceptance and one-time supplies, locked rewards, melee reach/facing/cooldown/stamina, wall occlusion, directional blocking and guard breaks, pause safety, arrow and spell costs, swept projectile hits, hostile projectile occlusion, F healing, live melee/archer/mage windups and attacks, walking through both chamber doors, boss rewards, unique-weapon tempering/crafting, hidden chest claims, surface return, atomic adventure/inventory persistence, invalid progress rejection and death recovery.

Regression suites passed: scene/movement 15, character 36, character UI 17, crafting 135 (now 96 recipes / 84 equipment designs), atlas 42. Combined: 291 checks. Test fixtures that teleport physics bodies explicitly allow transforms to synchronize before testing AI. Headless tests and isolated render modes do not touch real user progress.

Inspected native Mobile/Metal renders at 1280×800: `build/edda-quest.png`, `build/oldwatch-arena.png`, and `build/oldwatch-map.png`. Replaced a camera-obstructing exit label with a physical door; proximity HUD still provides exit guidance. This is functional prototype validation, not an M1 performance benchmark or a full human playtest/balance pass. Audio, navigation around unseen obstacles, randomized loot and advanced combat remain future work.

## Shops and building detail revision — September 8, 2026

33 shop checks passed: exact gold/stock transfers, insufficient gold and stock, invalid quantities, equipped/favorited sale protection, preservation of unique upgraded items in buyback, duplicate-sale/buyback prevention, merchant purse limits, stack resale, Presence pricing, commerce save/load and legacy migration, walking through all three shop entrances, actual purchase button, proximity recheck and menu transitions.

All existing suites also passed: movement 15, characters 36, character UI 17, crafting 135, atlas 42, combat 46. Total: 324 assertions. Runtime logs checked for script errors as well as assertion failures. The small house's previously low door header now admits the player. Visual QA inspected native Mobile/Metal renders of facades, interior furnishings and the trading screen, and corrected hidden floorboards and a disconnected chimney stack.

The approved concept was inspected directly as reference. New geometry stays batched; M1 performance and economy balance are not claimed tested. Merchant stock/purses are finite with no automatic restocking. Earlier sections record historical scope and block counts.

## Realm chapter slices — September 8, 2026

Added Aeralis and the much later Crucible, with normal story gates and explicitly isolated playable previews. Regression suites: movement 15, characters 36, character UI 17, crafting 151, atlas 42, combat 46, shops 33. New realm suite: 38 checks. Combined: **378 assertions**. Logs checked for script errors as well as failures.

Realm checks exercise real scene geometry and bridge joins, progression locks and preview refusal for persistent profiles, both new spell costs/projectiles, automatic held-trigger gunfire and ammo, forging rounds, unique guardian rewards, home-world portability, backward-compatible saves, invalid spells, local map behavior, falling and death recovery. Character and atlas persistence are both disabled in preview sessions. Rendering was inspected using native Mobile/Metal viewport captures on Apple M5 Max: Aeralis arrival and map, Crucible arrival and first-person weapon. Capture windows needed foreground launch on this host; stalled tool-owned attempts were stopped and rerun sequentially.

The 152,810 block log is the existing base-world batch count, not a count of all separate character/dungeon/realm geometry. No new frame-time benchmark or M1 validation was performed. These are playable small realm slices; their earlier campaign prerequisites and full-sized chapter content remain future work.

## Stonewake — September 8, 2026

The first main chapter now runs after Oldwatch's reward: keeper conversation, three inscription puzzles, persistent restored wards, destination echoes, return dialogue and a protected named pendant. `tests/stonewake.gd`: **32 assertions passed**. Existing suites passed unchanged: movement 15, characters 36, character UI 17, crafting 151, atlas 42, combat 46, shops 33, realms 38. Total: **410 assertions**.

Checks include actual dialogue buttons, prerequisite/reward locks, all three physical ward approaches, wrong answers without material loss, remote-input rejection, one-time restoration and rewards, an active survey sharing the relic interaction, journal completion, mid-quest and complete save round trips, invalid duplicate wards, legacy defaults and later realm gates remaining closed. The test's floor checks allow physics to settle after teleporting fixtures. Runtime logs were inspected for script errors. Native Metal renders verified keeper/rune dialogue layout, map markers and the watchstone echoes. Story preview explicitly disables both save systems; its setup is separate from normal progression. No new performance benchmark was taken.

## Wyrmkeep and the Iron Pact — September 8, 2026

Added the mountain town, independent council resolution, two optional rival clan memberships, initiation and first promotion, six clan gear designs, two formulas and two merchants. New `tests/mountain.gd`: **74 assertions passed**. Regression results: movement 15, characters 36, character UI 17, crafting 157, atlas 42, combat 46, shops 33, realms 38, Stonewake 32. Total: **490 assertions**.

The town suite walks through all five building entrances, hits a reaver through player melee, completes the council and all three policy choices, proves membership stays optional, exercises both mutually exclusive clans and their exact costs, rejects duplicate/remote/premature actions, forges advanced patterns, trades in town, verifies return/death, reloads progress and rejects an invalid rank. An initial regression failure was an accidental broad test-count edit changing expected ruby consumption; it was corrected to 99 and crafting reran with all 157 checks passing. Runtime logs were inspected for script errors.

Native Metal renders verified the town, map, raid and oath screen. An oversized return label was corrected, snow-scene objective contrast improved, and more detail added to the market and outpost. The renderer also asserted that the interactive preview disables character and atlas persistence. No fresh performance benchmark or M1 measurement was made. Travel is an authored pass transition; faction capstones, resignation, repeatable missions and restocking remain future work.

## Pinehall and The Missing Atlas — September 8, 2026

Added the forest settlement, ruined archive, custody choice, three relics and three forging recipes. `tests/archive.gd`: **52 assertions passed**. Regression suites: movement 15, characters 36, character UI 17, crafting 160, atlas 42, combat 46, shops 33, realms 38, Stonewake 32, mountain 74. Combined: **545 assertions**, with logs checked for script errors.

Archive checks exercise the Stonewake gate, all three house entrances and both dungeon doorways, both faction outcomes, proximity and duplicate guards, rare caches, protected atlas evidence, exclusive patterns, reputation and save migration. Equipment tests use real melee attacks and projectiles: stamina-on-kill excludes corpse and spell hits, chain lightning spends magicka and respects cooldown, two-jump limit, diminishing damage, walls and range; healing armor respects maximum health and loses its bonus when removed. Relic crafting and save round trips pass.

Native Metal viewport captures verified Pinehall arrival, detailed archive masonry, recipient dialogue and the local map. The render script asserts that both preview save systems are disabled. The archive suite passed again after the final geometry and relic visual changes. No new M1 performance measurement was taken. Subsequent story chapters, faction membership for these two orders and renewable component sources remain future work.

## Original chiptune score and interaction audio — September 8, 2026

Six original 32-bar music loops and seventeen synthesized effects now play through a two-voice crossfade director and bounded twelve-voice effects pool. `tests/audio.gd`: **34 assertions passed**, covering all loop assets, realm/battle selection, repeated-state stability, fade completion, cooldowns, volume muting/clamping, slider callbacks, equipment confirmation, preview-safe settings, visible enemy engagement and post-combat release. A dungeon fixture initially used local instead of global enemy coordinates; correcting the fixture made the engagement test pass. A test-only inferred array type was made explicit.

All prior suites passed: smoke 15, characters 36, character UI 17, crafting 160, atlas 42, combat 46, shops 33, realms 38, Stonewake 32, mountain 74, archive 52. Together with audio: **579 assertions**. Logs were inspected for script errors, not only exit codes.

A native Mobile/Metal run on the M5 Max recorded actual engine output (16-bit peak 15,609) and captured the pause menu with all three volume sliders visible. Offline PCM checks verify non-clipping source peaks and matching zero-valued loop endpoints after the final three-millisecond fade refinement. This verifies asset integrity and native playback; musical taste and the final loudness balance remain playtest judgments. No new M1 performance benchmark was performed.

## The Wreck on the Black Shore — September 8, 2026

Added Saltbreak, a sea cave, the Wayfarer wreck, six raiders/sentinels and the Hull Warden, two system repairs, protected recorder/core progress, two exclusive core outcomes and three salvage-restoration paths. Five equipment designs bring the catalog to 113 and recipes to 126. `tests/shore.gd`: **65 assertions passed**. Existing results: smoke 15, characters 36, character UI 17, crafting 165, atlas 42, combat 46, shops 33, realms 38, Stonewake 32, mountain 74, archive 52, audio 34. Total: **649 assertions**.

The coastal suite physically traverses all three house entrances, both cave ends, the locked/open bulkhead and the interior doorway. It checks acceptance, ordered pump/relay repairs, wrong answers without material loss, remote/repeated action guards, melee damage, cache and guardian loot, all three identifications/restorations, tempering without a second broken part, rare high-rank temper costs, the actual forge UI, both permanent core choices, visible destination changes, exclusive patterns, return rewards, save/load, invalid choice rejection and legacy defaults. Actual combat death restores vitals and exits the coast; surf recovery preserves progress; departing restores the original environment; later realm gates remain closed.

Initial compilation caught a variable using the reserved word `signal`; it was renamed. Existing tests with explicit catalog totals were updated for five new designs, two additional chest pieces and two additional main-hand weapons. After those intentional fixture changes all suites passed; logs were checked for script errors as well as failure counts.

Native Mobile/Metal captures verified the settlement, dock, sea cave, segmented wreck, core choice, navigation chart, lit beacon, identification text and local map. The renderer verifies that the isolated post-atlas preview disables both saves and that its initialized character passes save validation. Map label spacing and the wreck/cliff silhouettes were refined after inspection. Environment batches now log 254,245 blocks, excluding separately built actors and earlier separate dungeon/realm geometry. No M1 performance benchmark or timed 20–30-minute human playthrough was performed; pacing and encounter balance remain playtest work.

## The Sky Below the Sand — September 8, 2026

Added the Sunken Lens expedition camp, circular observatory, three rotating mirrors with visible beams, material-based lens restoration, a protected guardian vault, star-chart report, three solar gear designs and the learned Sunlance spell. `tests/lens.gd`: **55 assertions passed**. Existing checks passed: smoke 15, characters 36, character UI 17, crafting 168, atlas 42, combat 46, shops 33, realms 38, Stonewake 32, mountain 74, archive 52, audio 34, shore 65. Total: **707 assertions**.

New checks cover camp/observatory access, closed/open vault collision, guardian invulnerability before restoration, mirror acceptance/proximity/rotation rules, beam endpoints, exact and missing-material costs, one-time caches/activation/rewards, locked solved mirrors, actual Sunlance casting/cost/cooldown, two distinct targets, damage falloff, solid wall blocking and ordinary projectile behavior. They also verify forging, protected chart recovery, complete and legacy save loading, rejection of invalid activated alignments, map state, combat death and late realm gates.

Save tests caught JSON-decoded rotation values comparing differently inside dictionaries. The loader now validates their integer range and normalizes them to integers before applying state, matching the existing approach for numeric progress fields. Native preview validation initially stopped on that issue; its test-only window was closed and the corrected run completed. The final chapter suite passed all 55 checks with no script errors.

Native Mobile/Metal captures verified the camp, observatory entrance, mirror dialogue, active lens and local map. Dome/ring segments were made more continuous and beam emitters raised above the walking camera. Preview initialization asserts both save systems are disabled and its character passes save/load validation. Environment batches log 276,440 blocks, excluding separate actor and earlier dungeon/realm geometry. No timed human pacing study or new M1 benchmark was performed. The remaining woodland, Choir and convergence chapters still precede the space expedition.

## Pacts Beneath the Roots — September 8, 2026

Added and passed `tests/roots.gd`: 85 integration assertions covering Stonewake gating, both lodge doorways and the shrine route, root defender dependencies, exact herb/water costs, missing materials, proximity checks, one-time caches and loot, protected/active boss states, both permanent pact branches, exclusive patterns, world dressing, protected memory, reward duplication, high-rank tempering costs, actual potion healing and stamina-on-kill, save/load and malformed-state rejection, legacy defaults, stations, chapter switching, death recovery and preserved later realm gates.

Existing suites passed: smoke 15, characters 36, character UI 17, crafting 171, atlas 42, combat 46, shops 33, realms 38, Stonewake 32, mountain 74, archive 52, audio 34, shore 65 and lens 55. Including roots, **795 assertions passed with no failures**. Godot logs were checked for script errors in addition to exit status.

Native Mobile/Metal renders on the M5 Max verified arrival, the hollow-tree shrine, proposal and permanent-choice dialogues, both restoration variants and the local map. The first art pass was revised with interior trees, a larger crown, bark ribs, finer undergrowth and clearer map labels. Captures are `build/stag-shrine-*.png`. Preview initialization verifies that both save systems are disabled and its temporary character round-trips through save validation. Environment batches log **307,117 blocks**, excluding separate actors, dynamic plants and earlier separate dungeon/realm geometry. No timed human pacing study or new M1 performance benchmark was performed. Coven rank quests, Choir and convergence work remain future chapters before the space expedition.

## A Song Through the Stone — September 8, 2026

Added and passed `tests/choir.gd`: 70 assertions covering council gating without membership, lodge/aisle traversal, side and end barriers around decorative lava, the physical receiver gate, dormant guardian protection, acceptance/proximity checks, wrong-note resets, correct sequence and visible feedback, three distinct sound pitches, partial-song persistence, exact repair costs, missing supplies, one-time caches/loot/evidence/rewards, all three forge patterns and rare-material tempering, completed saves, malformed-state rejection, legacy migration, local map, stations, cross-chapter transitions, death and later realm gates.

Existing suites passed: smoke 15, characters 36, character UI 17, crafting 174, atlas 42, combat 46, shops 33, realms 38, Stonewake 32, mountain 74, archive 52, audio 34, shore 65, lens 55 and roots 85. Including Choir, **868 assertions passed with no failures**. All 16 suite logs were inspected for errors and completion markers, not just process exit codes.

Native Mobile/Metal renders on M5 Max verified the pilgrim camp, sanctuary, resonator dialogue, opened vault and local map in `build/ember-caldera-*.png`. The isolated preview asserts both character and atlas persistence are disabled and its post-council fixture passes save/load validation. Final scene construction reports **324,085 environment blocks**, excluding separate actor and dynamic geometry. No timed human pacing study or new M1 benchmark was performed. The Roads Converge and space expedition remain future work; Ashen Choir membership/rank quests remain outlines.

## The Roads Converge — September 8, 2026

Added and passed `tests/convergence.gd`: 74 assertions covering each of four required branches, entry without membership, physical arrival/lodge/boardwalk connections, marsh-fall recovery, dormant targeting/music exclusion, evidence proximity and duplication, all four woodland/harbor outcome combinations, recipe discovery and the actual enabled workshop craft button, exact resource costs, one-time supplies and installation, awakened combat roster, calibration prerequisites, rewards and tempering, preparation/completion save round-trips, seven invalid-state cases, legacy defaults, map, stations, cross-chapter travel, death and preserved later realm gates.

Existing suites passed: smoke 15, characters 36, character UI 17, crafting 177, atlas 42, combat 46, shops 33, realms 38, Stonewake 32, mountain 74, archive 52, audio 34, shore 65, lens 55, roots 85 and Choir 70. Including convergence, **945 assertions passed with no failures**. All 17 logs were inspected for completion and errors.

Native Mobile/Metal captures verified the Mirewatch arrival deck, briefing and outcome text, northern calibration platform, regulator forge menu, completed return beacon and local map. Artifacts: `build/mirewatch-*.png`. Preview initialization verifies both character and atlas persistence are disabled and the completed-branch fixture passes save validation. Environment batching reports **330,695 blocks**, excluding separate actors and dynamic geometry. No timed human pacing study or new M1 benchmark was performed. The actual First Threshold expedition remains unbuilt; this chapter completes its preparation without unlocking Aeralis or the Crucible early.

## Beyond the First Threshold — September 8, 2026

Added and passed `tests/threshold.gd`: 60 assertions covering the physical Sunken Lens vault approach and story gate, station arrival and airlock traversal, sealed/open command shutter, protected command security, ordered power/life-support repairs, one-time equipment/salvage, a real rifle projectile hit, separate ammunition pools, configured firing interval/cooldown, ordinary-material ammunition forging, portable gunfire at home, rare-material tempering, protected archive, completion only through the return beacon, save migration/corruption rejection, map/stations, normal Aeralis entry/attunement/guardian loot/return completion, persistence of that campaign chain and preserved Crucible prerequisites.

Existing suites passed: smoke 15, characters 36, character UI 17, crafting 181, atlas 42, combat 46, shops 33, realms 38, Stonewake 32, mountain 74, archive 52, audio 37, shore 65, lens 55, roots 85, Choir 70 and convergence 74. Including threshold, **1,012 assertions passed with no failures** across 18 suites. The first audio pass caught loops shorter than the existing 45-second minimum; they were extended to 32 bars and the audio suite rerun successfully.

Native Mobile/Metal captures verified the station airlock, engineer dialogue, security corridor, first-person observation window, map and physical departure gate inside the observatory vault. `build/threshold-*.png` contains these renders. Preview initialization verifies both save systems are disabled, its prerequisite fixture passes save validation, and completed observatory security remains defeated. The observation capture was corrected to avoid an artificial third-person camera overlap with a fixture enemy. Added equipment racks/status strips and kept the departure gate inside the actual vault wall boundary. Final environment batching reports **336,753 blocks**, excluding separate actor/dynamic geometry.

Station exploration/battle loops are original deterministic synth compositions at 88/136 BPM, 87.273/56.471 seconds, with measured peak 0.78 and full-file stereo loop regions. Existing effects and music remain unchanged. Full audio regeneration includes the station extension and merges the manifest. All 25 WAVs total about 51 MB. New M1 benchmarking and timed human pacing tests remain outstanding. The Crucible still requires the unbuilt Winter Siege and Broken Seal chapters; normal Aeralis progression is now connected.


## Winter Siege — September 8, 2026

Added a 55-assertion integration suite covering the Aeralis gate, physical supply-road interaction and fort arrival, gate traversal, dormant wave visibility/collision/damage protection, phased combat, single-claim supplies and loot, exact repair costs and atomic insufficient-material handling, both defense effects, revisits, order recovery, rewards, forging and high-rank tempering, save round-trips, eight malformed-save cases, older-save defaults, cross-chapter travel, local-map status and combat death. All 55 passed.

The 18 existing suites passed without failures (crafting increased from 181 to 183 checks for the two new recipes). Combined with Winter Siege, **1,069 assertions passed across 19 suites**. Inspected logs for runtime errors as well as completion markers. The first siege test caught the command satchel overlapping the boss's loot interaction; separating their positions resolved it.

Native Mobile/Metal rendering on the M5 Max completed seven captures in `build/winter-*.png`: arrival, briefing, scouts, main assault, victory, forge and map. Inspected images, then added a northern ridgeline, fort gateway, masonry, banners, supplies and weapon racks to improve the initially bare courtyard. The final native preview fixture passed save validation with both persistence systems disabled. Final environment batching reports **348,650 blocks**, excluding separate actor/dynamic geometry. No timed human pacing or M1 benchmark was performed.


## The Broken Seal — September 8, 2026

Added 58 integration assertions covering the Winter Siege gate, physical service lift, arrival floor and arch traversal, dormant defender visibility/collision/damage guards, assigned valve defenders, inner progression, single-claim supplies and loot, recipe unlocking, actual forge-button crafting at exact cost, insufficient-material atomicity, boss and crafted-ward binding prerequisites, report rewards, amulet forging/tempering, save round-trips, nine malformed-save cases, older-save defaults, local map and combat death. The suite also enters the Crucible through the actual northern crossing without preview bypass, attunes, defeats and loots its guardian, returns home and saves Last Furnace completion.

All 19 prior regression suites passed. Crafting increased from 183 to 185 assertions for the two new recipes. Including the new suite, **1,129 assertions passed across 20 suites**, with no errors in the final logs. The initial test harness used the wrong workshop action property and was corrected to use the actual action container. The reward amulet was given 2 base armor so its stated tempering path has a mechanical effect.

Eight native Mobile/Metal renders in `build/seal-*.png` cover arrival, briefing, inner works, forge, guardian, report, crossing and map. Inspected the rendered images and added deck seams, rivets and masonry. Corrected the duplicated emissive material color so restored containment glows teal rather than retaining the source material's yellow emission. The preview fixture passed save validation with character and atlas persistence disabled. Final environment batching reports **351,014 blocks**, excluding separate actors and dynamic geometry. No new M1 benchmark or timed human pacing study was performed.


## Last Furnace ending — September 9, 2026

Added 56 ending integration assertions covering physical console proximity, all-defender and Warden-relic prerequisites, visible and single-use shutdown, return-gate proximity, persistent engine state, automatic homecoming, each of the three heirloom choices, duplicate-claim protection, shared pattern unlocks, forging and rare-material tempering, atomic save round-trips, five malformed ending records, both completed and unfinished legacy-save migrations, earlier-choice chronicle text, Escape, revisiting the book, continued travel and noninterrupting completed return trips.

All 20 existing suites passed; crafting increased from 185 to 188 checks for the three Dawnforged recipes. The realm test now completes through the arrival-gate location, and the underworks-to-Crucible test includes the shutdown and homecoming. Combined results: **1,188 passing assertions across 21 suites**, no errors in the final logs.

Six native Mobile/Metal captures in `build/ending-*.png` verify the live/stopped engine, homecoming, prior-choice chronicle, selected heirloom and home-world book. Reward buttons show base damage and scaling bonuses; the reward summary stays outside the scrollable story text. Character and atlas persistence are disabled in the preview and its initial save fixture validates. Static environment batching reports 351,016 blocks, excluding separately batched realm geometry and dynamic actors. No new M1 benchmark or timed human pacing study was performed.


## Full session resume — September 9, 2026

Added 73 integration checks covering capture and exact grounded restoration across fourteen area types, current resources/camera, nearby surviving enemy health, atomic character/session round-trip, six malformed records, old saves, falling/obstructed-position fallbacks, unavailable-region gates, death transitions and preview isolation. All 22 regression suites passed with **1,261 assertions** and no errors in their final logs.

Native Mobile/Metal renders `build/session-resumed.png` and `build/session-pause.png` verify the restored Northwatch position, reduced resources, first-person view and save controls. A separate copied project configuration with custom user directory `SkyrimCraft-Session-QA` exercised actual persistent save and automatic restore across two native processes. The first uncontrolled check was disturbed by live movement; the harness now disables physical input and player physics. The controlled relaunch reported matching `(2, 0.17, 12)` coordinates and verified health, magicka, stamina and camera, ending with `SESSION_BOOT_RESTORED`. The regular character profile was not used for this test.

Session snapshots omit inactive home-world dungeon actors. Scene-authored entrances are retained if a saved position lacks a safe floor/clearance. Projectiles, open menus and attack timers are intentionally not serialized. This implements resume for the current profile; multiple slots remain future work. No new M1 performance benchmark was performed.


## Use-based skills and perks — September 9, 2026

Added 42 checks for XP thresholds and caps, shared points, perk eligibility and duplicate purchases, damage/resource/crafting effects, save round-trips, malformed records, legacy crafting XP migration, real melee and projectile hits, corpse/miss rejection, and skill-menu controls and purchases. All 23 suites passed: **1,303 assertions**, with no errors in final regression logs.

Five native Mobile/Metal captures in `build/skills-*.png` cover initial progression, unlocked melee perks, a purchased perk, crafting and magic. The isolated render fixture validates save/load and does not use the regular character profile. Loaded JSON XP values are normalized to integers. Combat level-up saves occur after defeat handling to avoid capturing a living actor with zero health. No new M1 benchmark or timed human progression study was performed.

## Timed parries and guard recovery — September 9, 2026

Added 20 integration checks covering fresh guard timing, actual enemy melee attacks, eight-stamina damage prevention, stagger/windup cancellation, held-button and rapid-tap cooldown behavior, late/rear/projectile hits, exhausted guards, recovery lockout, menus, incompatible weapons, attack animations, boss recovery and corpse rejection. All 23 previous suites also passed: **1,323 assertions across 24 suites**, no errors in the final logs.

The isolated native Mobile/Metal fixture `tests/render_parry.gd` produced `build/parry-combat.png`, inspected for the successful-parry message, cyan stagger feedback and the new control hint. Regular character and atlas persistence were disabled. No M1 performance run or human combat-balance study was performed; the timing values are an initial tuning pass.

## Weapon critical hits — September 9, 2026

Added 19 checks for deterministic percentage rolls and the 35% cap, 1.5x weapon damage, ordinary hits, boss mitigation, magic exclusion, pause/corpse guards, overkill XP, actual melee swings, bow impact, in-flight stat changes, firearm ammunition and hostile-projectile exclusion. All 24 previous suites passed. Combined result: **1,342 assertions across 25 suites**, with no errors in the final test logs.

Native Mobile/Metal capture `build/critical-combat.png` verifies the Critical! damage message during an actual melee swing. Run `tests/render_critical.gd` with `-- --capture` for profile isolation. The initial Winter Siege fixture retained that area's targeting roster, so the capture now starts in the base-world fixture before entering the barrow. Regular character and atlas saves were not used. Critical tests seed the player's dedicated combat RNG; normal play uses its randomized initial state. No new M1 benchmark or human balance study was performed.

## Free perk retraining — September 9, 2026

Added 18 checks for invalid and repeated refunds, exact one/two-point recovery, all-perk refunds, XP and gold preservation, immediate stat/cost updates, switching to a crafting build, existing Fine-item preservation, future crafts losing the refunded Artisan bonus, save/load and live refund/relearn buttons. Eight relevant regression suites also passed (skills, characters, character UI, crafting, combat, parry, critical, session save): **459 assertions across nine suites**, with no errors in final logs. Unrelated chapter suites were not rerun for this change.

The isolated native skills render suite completed and refreshed five `build/skills-*.png` captures. The learned-perk screen was inspected for the refund label and explanatory text. Character and atlas persistence remained disabled; no regular profile was used. Retraining introduces no new save fields and costs no gold. No new performance benchmark was performed.

## Saved equipment loadouts — September 9, 2026

Added 17 checks covering names/indices, exact item identity, upgraded-item preservation, whole-set sword/shield and two-handed swaps, missing-item atomic failure, missing-reference persistence and recovery, deleting sets without deleting gear, malformed records, older-save migration, and actual Save current/Equip set UI actions with live stat updates. Ten relevant regression suites passed (characters, character UI, crafting, skills, combat, critical, parry, retraining, session save, shops). Combined result: **509 assertions across eleven suites**, with no errors in final logs. Other chapter suites were not rerun for this change.

Native Mobile/Metal captures `build/loadouts-ranger.png` and `build/loadouts-missing.png` verify the character-screen controls and disabled swap with a named missing item. The capture opens the menu directly because automated renders intentionally ignore input events. Large missing-item lists use a two-item summary plus a full hover list. Tests and previews leave regular character and atlas profiles untouched. No M1 benchmark was performed.

## Whirlwind power attack — September 9, 2026

Added 19 checks for empty/full/capped meter behavior, damage charge, pause/negative-charge rejection, front/rear double-damage sweep, single consumption, attack lockout, self-charge prevention, spin/camera separation, real-time expiry, menu cleanup, ranged/blocking restrictions, wall occlusion, prior-time-scale restoration, respawn and scene teardown. Eleven relevant existing suites passed (combat, parry, critical, skills, characters, character UI, crafting, session save, loadouts, retraining, realms). Combined result: **533 assertions across twelve suites**, no errors in final logs. Other chapter suites were not rerun.

Three isolated native Mobile/Metal captures in `build/power-*.png` cover the charged HUD, third-person spin and first-person sweep. The camera remains steady in first person and the attack restores the weapon/body pose afterward. The final pose extends the weapon arm during the spin. Preview character and atlas persistence are disabled. Charge is transient, while ordinary damage/defeat rewards follow existing saves. No M1 benchmark or human combat-balance study was performed.

## Sundering Blow finisher — September 9, 2026

Added 21 checks covering weak-health threshold, facing, range, equipped melee requirement, paused input, target locking, windup timing, attack/power lockout, menu and range cancellation, normal persistent defeat, camera stability, duplicate impact/XP prevention, corpse rejection, wall occlusion, respawn release, protected-boss rejection, unprotected-boss eligibility and protection gained before impact. Nine relevant existing suites passed (combat, parry, critical, power, skills, session save, realms, seal, ending): **392 assertions across ten suites**, with no errors in final logs. Other suites were not rerun.

Native Mobile/Metal captures `build/finisher-ready.png`, `build/finisher-windup.png` and `build/finisher-impact.png` verify the X prompt, weapon windup, red voxel impact burst and normal corpse/loot outcome. Character and atlas persistence were disabled. This is one shared execution animation; it does not add a full roster of weapon-specific fatalities. No M1 benchmark or human combat-balance study was performed.

## Frostmere wilderness creatures — September 9, 2026

Added 19 checks for twelve actors and species counts, giant collision/health, supported spawn clearance, pursuit, habitat return, parry stagger, actual melee damage, chapter visibility/collision/target isolation, defeat, single-claim harvesting, giant forging rewards, save round-trip, invalid claims, home-world session actors and paused harvesting. All 29 existing suites passed after correcting the music threat scan: **1,436 assertions across 30 suites**, no errors in final logs.

Native Mobile/Metal captures `build/wilderness-wolf.png`, `build/wilderness-boar.png` and `build/wilderness-golem.png` verify original creature shapes and final habitat placement. Initial sites intersected foothills or dense trees; encounters now use supported clearings within reachable terrain. The forest generator reserves clearings around authored sites. Static environment batching now reports 346,292 blocks, excluding separately built actors and realm geometry.

Wilderness battle music follows creature threat eligibility rather than proximity alone; the audio release test now returns to the safe village instead of assuming the barrow exterior is empty. Home session snapshots include active wildlife and exclude inactive dungeon actors. Regular profile persistence was disabled in tests and captures. No M1 benchmark, timed human encounter study, automatic encounter reset or broader-region population pass was performed.

## Raised wilderness terrain — September 9, 2026

Added 11 checks for authored summit heights, preserved village/bridge/barrow elevations, Godot collision winding and walkable slope limits, actual continuous ascent/descent along all three paths, elevated session restoration and terrain-aligned tree roots. All 30 existing suites passed, including wilderness spawn clearance: **1,447 assertions across 31 suites**, no errors in final logs.

The initial collision triangles used the opposite winding from Godot's concave collision convention and were corrected. The terrain walking fixture excludes stationary creature collision so it measures the route itself; wildlife combat remains covered separately. It reached approximately 3.10, 2.70 and 2.30 metres at the three summits and returned to the base surface without jumping.

Three native Mobile/Metal captures `build/terrain-0.png` through `build/terrain-2.png` show raised winding paths, voxel columns and elevated vegetation/creatures. Trees along the paths are thinned for clearance. Static environment batching reports 333,236 blocks, excluding separate actors and realm batches. Tests and captures used isolated profiles. No new M1 benchmark or human traversal pacing study was performed.

## Frostmere village layout — September 9, 2026

Added 20 checks for the moved home and two added homes, actual doorway traversal, safe interiors, lane connections, all ten gathering approaches and the main arrival walk. The full regression run passed after fixing a tree obstruction at the northwest hill exit; the terrain suite plus affected smoke, shops, town, wilderness and session-save suites were rerun after that fix. Combined unique coverage: **1,467 assertions across 32 suites**, no errors in their final logs.

Frostmere now has six enterable buildings, a staggered western home, a riverside cottage, a shifted northern home, curved connecting lanes, a well-centered green, produce stalls, benches, gardens and wood piles. Existing merchant and quest coordinates are preserved. Street furniture was adjusted to keep the arrival route clear. Tree clearance now checks actual jittered trunk positions along hill paths and their flat approaches.

Four native Mobile/Metal captures `build/town-0.png` through `build/town-3.png` cover arrival, market, village overview and the northern lane. Final static batching reports 335,181 blocks, excluding separate actors and realm batches. Tests and captures used isolated profiles. This pass covers Frostmere; other towns and varied building rotations remain open. No M1 benchmark or human navigation study was performed.

## The Mossbound Oath — September 9, 2026

Added 22 checks covering physical board proximity, actual accept/reward buttons, incomplete and duplicate rejection, real defeat/harvest of all four targets, return-to-board requirement, chosen Fine/favorited gear, both recipe unlocks, forging the alternative, real tempering, save round-trip, malformed reward records, credit for earlier harvests, alternative reward choice and Escape. All 32 prior suites passed; crafting grew to 190 checks and the character UI expectation was updated for 57 weapons. Combined result: **1,491 assertions across 33 suites**, no errors in final logs.

Three isolated native Mobile/Metal captures `build/hunt-board.png`, `build/hunt-rewards.png` and `build/hunt-complete.png` verify the description, reward choices and completion state. The preview validates its own save/load and cannot write the regular profile. This contract uses the existing northwest wolves and colossus; it adds two equipment designs and two recipes, not new enemies or a difficulty change. Current catalog totals are 135 equipment designs and 151 recipes. No M1 benchmark or human quest-pacing study was performed.

## Mossbound Colossus encounter — 2026-09-09

Added a dedicated optional colossus controller with a five-metre ground-slam warning, 1.5-second reaction window, and a half-health Awakened phase. Harvests, contract rewards and persistent defeat remain compatible. No player-profile migration or enemy respawn is introduced.

Passed 267 assertions across ten relevant suites: colossus (16), wilderness (19), hunt (22), terrain (11), town (20), combat (46), parry (20), power (19), finishers (21), session_save (73). Colossus coverage includes reaction time, radius escape, single impact, solid cover, guarded non-parryable impact, exact phase damage after armor, cooldown, visible phase name and cancellation on pause, finisher lock, travel, retreat, stagger and death. Normal harvest proof still works.

Native Metal/Mobile capture on Apple M5 Max completed with COLOSSUS_RENDER_COMPLETE. Inspected build/colossus-slam.png: amber terrain ring and attack label are visible. QA used isolated headless profiles and --capture mode, with persistence disabled for native rendering. No new M1 benchmark or human balance study was performed. Static world batch count remains 335181; the warning adds 48 simple marker meshes only to the colossus encounter.

## Weapon finisher variants — 2026-09-09

Added six named melee-family profiles in scripts/finisher_moves.gd: dagger thrust, sword/greatsword sweep, and axe/battleaxe/mace overhead crush, with family-specific impact and recovery timing. Both camera rigs restore captured position/rotation on cancellation. Existing weak-target, range, wall, protected-phase and one-hit rules remain in place. Impact fragments use stone material for the colossus and flesh material for other current creatures; this does not add dismemberment or replace realm guardians.

Passed 249 checks across eight relevant suites: finisher_moves (33), finishers (21), colossus (16), power (19), combat (46), wilderness (19), hunt (22), session_save (73). The new suite exercises all six actual equipment families, pre-impact animation, cancellation restoration, persistent defeats, single XP award, recovery and stone fragment material. The finisher_moves suite was rerun successfully after first-person pose tuning.

Native Metal/Mobile rendering completed with FINISHER_MOVES_RENDER_COMPLETE. Captured three motion families in both camera modes and a colossus impact. Inspected dagger and mace first-person poses, sword third-person pose and stone fragments; corrected first-person windup rotation that initially lowered weapons out of frame. Files: build/finisher-{dagger,sword,mace}-{first,third}.png and build/finisher-stone-impact.png. Preview and headless QA use isolated state, leaving the regular profile untouched. No new M1 benchmark or human combat-balance study.

Recorded the user's monster-first boss direction and proposed Nordic/space/Aeralis/Crucible creature backlog in docs/SCOPE.md. Those future creatures are planned, not implemented by this pass.

## Rimefang and the Frostmaw Hunt — 2026-09-09

Added a thirteenth wilderness actor: a 540-health giant tusked quadruped, with an enlarged capsule, ice back plates and a committed straight-line charge. Its 1.3-second warning allows sidestepping; the charge hits once and ends in recovery. Cleared trees within twelve metres of the eastern-bank habitat. Static batch count is now 328801. Added a second market-board contract, proof/reward save validation, Fine favorited maul reward, two forge patterns, and the 137-item/153-recipe catalog.

Passed 458 assertions across eleven relevant suites: frost_beast 19, wilderness 19, hunt 22, characters 36, character_ui 17, crafting 192, session_save 73, terrain 11, town 20, finisher_moves 33, colossus 16. Expanded catalog count expectations were updated. The new suite checks a supported spawn, warning, locked charge direction, sidestep, recovery, actual single-hit damage, menu/finisher cancellation, board proximity, actual harvest/reward, forge/temper operations, save/load and invalid proof rejection. Existing hunt, colossus, paths and town tests pass.

Native Metal/Mobile rendering on Apple M5 Max completed with FROST_BEAST_RENDER_COMPLETE. Inspected build/frost-beast.png and build/frost-hunt-board.png; build/frost-beast-warning.png also captured. The board is readable and the creature has a distinct large quadruped/tusk silhouette. Native capture uses --capture with persistence disabled; headless tests use isolated profiles. No normal player save was changed. No new M1 benchmark or human combat-balance study was performed. Additional realm monsters remain backlog work.

## Hullcarver Broodmother — 2026-09-09

Replaced the station's humanoid threshold_5 guardian with an eight-legged armored alien, enlarged collision, plasma-spit windup and three-second exposed-core damage window. Preserved its persistent identity, 380 health, repair gates, named blade, archive and return requirements. Core exposure is a timed whole-target damage multiplier, not a separate aim collider.

Passed 268 checks across six suites: hullcarver 12, threshold 60, session_save 73, finishers 21, combat 46, ending 56. New coverage includes supported monster collision, shell/open damage, warning and shell movement, recovery, menu/travel cancellation, weakened-shell execution and single-claim existing loot. Station-to-Aeralis progression and ending regressions pass.

Native Metal/Mobile preview completed with HULLCARVER_RENDER_COMPLETE. Inspected build/hullcarver-armored.png and build/hullcarver-core.png; shell plates conceal/reveal the green core and the monster fits the deck. Fixed preview visibility for the frozen actor before final captures. QA used isolated headless state and --capture with persistence disabled. No normal save was modified, no new M1 benchmark was performed, and broader creature animation/art polish remains open.

## Prismwing, the Fractured Wyrm — 2026-09-09

Replaced Aeralis's humanoid aeralis_regent guardian with a grounded crystal-winged quadruped, enlarged collision, committed fan volley and half-health wing fracture. Existing 240 health, persistent ID, guardian loot and return progression remain. The fracture is health-driven rather than a separate wing hitbox; flight remains unimplemented.

Passed 259 assertions across six relevant suites: crystal_wyrm 11, realms 38, threshold 60, session_save 73, finishers 21, ending 56. New tests cover supported terrace collision, warning, fixed aim, five real projectiles, fracture/stagger, three-projectile phase, health-reset wing restoration, pause/other-realm cleanup and persistent finisher defeat. The crystal_wyrm suite was rerun after adding reset handling.

Native Metal/Mobile preview completed with CRYSTAL_WYRM_RENDER_COMPLETE. Inspected build/prismwing.png and build/prismwing-fractured.png: full and shortened crystal wings render clearly on the guardian terrace. QA used isolated headless state and --capture with persistence disabled. No normal player save changed; no new M1 benchmark or human balance study. Static world batch remains 328801.

## Furnace Maw — 2026-09-09

Replaced the Crucible humanoid guardian with a horned six-legged furnace beast. Added a fixed targeted rupture circle, 1.5-second warning, one impact, and increased damage/frequency below half health. Preserved crucible_warden identity, health, relic, engine shutdown and ending rewards.

Passed 210 assertions across six suites: furnace_beast 11, realms 38, ending 56, session_save 73, finishers 21, crystal_wyrm 11. New coverage includes supported giant collision, telegraph, circle escape, committed target position, real single-hit damage, exact half-health damage/cooldown, menu/travel/finisher cleanup and persistent guardian defeat. Existing ending and realm save checks pass.

Native Metal/Mobile rendering completed with FURNACE_BEAST_RENDER_COMPLETE. Inspected build/furnace-maw.png and build/furnace-rupture.png; the furnace jaw, horned silhouette and ground warning are visible on the final terrace. QA used isolated headless state and --capture with persistence disabled; no normal player save changed. No new M1 benchmark or human combat-balance study. Static world batch remains 328801. Each destination guardian now has a first monster implementation; wider regional encounter expansion and further art/animation remain backlog work.

## Monster impact presentation — 2026-09-09

Added surface-specific destination guardian finisher fragments and a brief cosmetic furnace eruption. Passed 98 checks across six suites: monster_effects 10, furnace_beast 11, finisher_moves 33, hullcarver 12, crystal_wyrm 11, finishers 21. New coverage checks actual fragment materials and crystal shape, real rupture effect creation, no additional damage, pause/resume, expiry and realm-travel cleanup. Existing finisher and boss behavior regressions pass.

Native Metal/Mobile preview completed with MONSTER_EFFECTS_RENDER_COMPLETE. Inspected build/furnace-eruption.png; ember fragments rise visibly at the former warning location. Preview/headless QA use isolated state, leaving the regular profile unchanged. No new M1 benchmark. The eruption has sixteen meshes, no collision, and a 0.65-second lifetime.

## Clan Voice capstone — 2026-09-09

Implemented iron_pact_3 for either mountain clan: Shieldbearer commission, both existing monster harvest proofs, sponsor-proximity mandate choice, rank three, reputation/supply consequences, Superior favorited signet and forge pattern. Added optional expedition/mandate save validation and live journal integration. Counts: 138 equipment designs, 154 recipes, 33 remaining atlas quest outlines.

Passed 497 checks across nine suites: clan_voice 21, mountain 74, atlas 42, characters 36, character_ui 17, crafting 193, session_save 73, hunt 22, frost_beast 19. Both clan/mandate branches, rank gating, unearned/remote/duplicate claims, reputation consequences, save/load validation, forging and tempering pass. Existing clan initiation/promotion and market hunt regressions pass.

Native Metal/Mobile preview completed with CLAN_VOICE_RENDER_COMPLETE. Inspected build/clan-voice-choice.png; both choices and reward description fit the dialogue. Also captured build/clan-voice-complete.png. QA used isolated profiles and --capture with persistence disabled; the normal player profile was not changed. No M1 benchmark. Mandates currently change reputation, supplies and recorded dialogue, not physical patrol simulation or other faction lockouts.

## Veiled Lantern initiation — 2026-09-09

Added The Uncatalogued Door as a playable membership trial, with testimony study, a physical archive-seal interaction, retryable answer, protected evidence and explicit Witness oath. Added a Fine favorited pendant/pattern, optional trial-stage save validation, live journal and faction membership text. Preserved either atlas custodian and its original exclusive reward. Catalog: 139 designs, 155 recipes, 32 remaining atlas outlines.

Passed 421 checks across six suites: lantern 24, archive 52, atlas 42, characters 36, crafting 194, session_save 73. New coverage includes both custodians, prerequisite/ordered evidence gates, wrong answer retry, correct-location turn-in, duplicate prevention, save/load, recipe and tempering. Atlas was rerun after faction dossier text changes.

Native Metal/Mobile preview completed with LANTERN_RENDER_COMPLETE. Captured build/lantern-trial.png and build/lantern-oath.png; inspected the oath layout and corrected the preview's prerequisite state to show only relevant actions. Tests/previews use isolated state and do not modify the regular player profile. Static world batch is 328806. The new door is an interactive record seal, not an additional dungeon wing; later Lantern chapters remain planned.

## Names Beneath the Water — 2026-09-09

Implemented Lantern chapter two with three Mirewatch record sites, membership and calibration gates, protected collection, two testimony outcomes and exclusive Superior ring/pattern rewards. Preserved existing expedition and atlas custody progression. Added optional archive investigation/choice validation and live journal/faction progress. Catalog totals: 141 equipment designs, 157 recipes, 31 remaining atlas outlines.

Passed 517 checks across eight suites: names_water 20, lantern 24, archive 52, convergence 74, atlas 42, characters 36, crafting 196, session_save 73. New tests exercise physical-site collection, duplicates, beacon gate, sponsor return, both exclusive reward branches, saves, forging, tempering and invalid proof rejection. Existing Mirewatch walking routes and expedition mechanics pass.

Native Metal/Mobile preview completed with NAMES_RENDER_COMPLETE. Inspected build/names-choice.png; choice buttons and reward description fit the dialogue. Also captured build/names-public.png. QA used isolated profiles/--capture with persistence disabled; normal player progress was not changed. Static world batch is 328812. Broader public-witness reactions remain future work.

Persisted the requested dark, Nordic/Hell-foreshadowing playable intro in the polish backlog, including natural onboarding and repeat-play skip. The intro itself is not implemented yet.

## NPC humor pass — 2026-09-09

Added original dry and gallows humor to existing village, clan, archive, station and expedition dialogue. Edda's jokes vary by quest stage; clan banter appears at early ranks. Mereth's safety-manual joke is suppressed during the missing-family investigation; its record text remains serious. Also corrected Rook's archive description to reference the current crystal wyrm guardian. Gameplay, rewards and saves are unchanged.

Existing headless smoke suite passed all 15 checks. Native Metal/Mobile preview completed with DIALOGUE_HUMOR_RENDER_COMPLETE. Inspected build/humor-edda.png, build/humor-rook.png and build/humor-mereth.png; expanded text and action buttons fit their dialogue panels. Isolated preview/headless state left the regular profile untouched. This is written dialogue, not a new ambient/voiced banter system.

## The Price of Knowing — 2026-09-09

Implemented the Lantern capstone: prerequisite testimony resolution, two physical faction consultations, archive-seal mandate, Keeper rank and Superior favorited keystone/pattern reward. Three decisions retain earlier testimony and custody choices. Optional price fields validate stage/prerequisite and unique consultations. Catalog: 142 designs, 158 recipes, 30 atlas outlines remaining.

Passed 472 checks across seven suites: lantern_capstone 48, lantern 24, archive 52, atlas 42, characters 36, crafting 197, session_save 73. The previous names_water suite also passed its 20 checks separately. Capstone tests exercise all three outcomes, consultation/site gates, single rewards, preserved testimony, save round-trips, forging and rejection of missing consultation proof.

Native Metal/Mobile preview completed with PRICE_RENDER_COMPLETE. Inspected build/price-choice.png; all three options and reward copy fit. Also captured build/price-oversight.png. QA used isolated profiles and --capture with persistence disabled. No normal save changed; no new M1 benchmark. Policy consequences currently appear in faction dialogue, journal and material rewards, not simulated public access or rival-faction lockouts.

## Briar Coven initiation — 2026-09-09

Implemented The Grove That Refused Spring: three physical seedbeds, visible restored shoots, two oath outcomes, preserved woodland pact, Seedkeeper rank and Fine favorited charm/pattern. Catalog: 143 designs, 159 recipes, 29 remaining atlas outlines.

Passed 482 checks across six suites: coven 48, roots 85, atlas 42, characters 36, crafting 198, session_save 73. Coven coverage includes prerequisites, cost atomicity, duplicate/remote rejection, both oaths and prior pacts, save round trips, invalid proof rejection, older-state compatibility, forging and tempering.

Native Metal/Mobile preview completed with COVEN_RENDER_COMPLETE; inspected build/coven-oath.png and build/coven-seedbed.png. QA uses isolated state with persistence disabled. No normal player save changed and no new M1 benchmark was performed. Oath consequences currently affect dialogue and supplies, not a medicine-distribution simulation.

## A Debt of Sap and Stone — 2026-09-09

Implemented the second Coven chapter: membership prerequisite, foundation/spring investigation, Oren consultation, two funded agreements, visible repair dressing and Pactmender ring/pattern. Existing woodland pact and Seedkeeper oath remain intact. Catalog: 144 designs, 160 recipes; 28 atlas outlines remain.

Passed 571 checks across seven suites: coven_debt 88, coven 48, roots 85, atlas 42, characters 36, crafting 199, session_save 73. New coverage exercises both agreements, evidence/site gates, exact and atomic material costs, repeated-claim rejection, visual choice state, prior promises, save round trips and invalid evidence/membership rejection, forging and tempering.

Native Metal/Mobile preview completed with COVEN_DEBT_RENDER_COMPLETE. Inspected build/coven-debt-choice.png and build/coven-debt-cistern.png: choices fit the panel and the selected repair appears beside the lodge. QA persistence was disabled; normal player saves were untouched. Repair dressing has no new collision or water simulation. No new M1 benchmark was performed.

## The Last Old Promise — 2026-09-09

Implemented the Coven finale with three physical consultations, a permanent Stag Heart decision, Rootwarden rank and a Superior favorited Old Promise Talisman/pattern. Both outcomes preserve the prior woodland pact, oath, repair and archive state. Catalog: 145 designs, 161 recipes, 27 remaining atlas outlines.

Passed 713 checks across seven suites: coven_finale 129, roots 85, atlas 42, characters 36, crafting 200, session_save 73, lantern_capstone 48. Finale coverage includes both full Coven paths, prerequisite/site gates, unique testimony, exact rewards, repeat rejection, earlier-state preservation, save round trips, malformed evidence rejection, forging and tempering.

Native Metal/Mobile preview completed with COVEN_FINALE_RENDER_COMPLETE. Inspected build/coven-finale-choice.png and build/coven-finale-shared.png; options and completion text fit. QA used isolated state with persistence disabled; normal player saves were untouched. Final policy affects dialogue, rank and supplies, not simulated governance. No new M1 benchmark was performed.

## Hollow Warden creature pass — 2026-09-09

Replaced the woodland humanoid boss with a four-legged bark creature with branching antlers, moss plates and a locked ground-target root eruption. Existing roots_3 identity, 300 health, three-root protection, loot and story gates remain intact. Bark-colored finisher fragments added. Root telegraphs and cosmetic thorns clear on interruption; half health changes raw eruption damage and recovery.

Passed 332 checks across six suites: hollow_warden 14, roots 85, coven_finale 129, session_save 73, monster_effects 10, finishers 21. Boss coverage includes spawn floor support, linked-root attack gate, 1.5-second warning, locked target avoidance, one-hit damage, exact half-health scaling, menu/travel/stagger/execution cancellation and finisher progression identity.

Native Metal/Mobile preview completed with HOLLOW_WARDEN_RENDER_COMPLETE. Inspected build/hollow-warden.png, build/hollow-root-warning.png and the eruption preview. The isolated preview moves the creature into the approach clearing to show its silhouette without the shrine statue obscuring it; the game spawn remains unchanged. Normal player saves were untouched. No new M1 benchmark; creature animation and encounter balance remain first-pass work.

## Hull Warden brine crab — 2026-09-09

Replaced the coastal humanoid guardian with a six-legged crab, claws, opening shell and barnacles. Added a locked-aim three-projectile pale brine volley (1.4-second warning, 20 raw damage per projectile), a 2.5-second exposed damage window and shell-colored finisher fragments. Existing shore_6 identity, 340 health, salvage and core progression remain intact.

Passed 183 checks across five suites: shore 65, brine_crab 14, session_save 73, monster_effects 10, finishers 21. Boss checks cover collision/floor support, closed versus open damage, volley count/tint/locked direction, opening and closing shell, stagger/menu/travel/execution interruption, lethal finisher identity and single-claim salvage. Coastal regression covers both core outcomes and old save compatibility.

Native Metal/Mobile preview completed with BRINE_CRAB_RENDER_COMPLETE. Inspected build/brine-crab.png and build/brine-crab-open.png; body fits the wreck chamber and shell opening is visible. QA used isolated state and disabled persistence; no normal save changed. No new M1 benchmark. Exposure is a whole-body timed modifier, not a precision hit zone. Animation and encounter balance remain first-pass work.

## Dissonant Cantor creature pass — 2026-09-09

Replaced the volcanic humanoid guardian with a six-legged ash creature, stone wing plates, glowing throat and expanding sonic ring. Preserved choir_4 identity, 340 health, repaired-receiver gate, signal archive and rewards. The 1.5-second warning marks eight meters. The wave travels at seven meters per second, hits once, checks line of sight, and misses airborne feet at least 0.85 meters above its origin. Half health increases raw damage from 30 to 40 and recovery changes from six to four seconds.

Passed 191 checks across five suites: choir 70, ash_cantor 17, session_save 73, monster_effects 10, finishers 21. New tests cover floor fit, dormant gate, telegraph/wave transition, airborne avoidance, safety just outside eight meters, single crossing damage, exact half-health scaling, stagger/menu/travel/execution cancellation, lethal finisher identity and single-claim loot. Airborne avoidance is tested with controlled player height; jump timing and encounter balance still need broader playtesting.

Native Metal/Mobile preview completed with ASH_CANTOR_RENDER_COMPLETE. Inspected build/ash-cantor.png and build/cantor-wave.png after refreshing the preview's repaired receiver barrier. The model and ring are visible in the archive approach. QA persistence was disabled; no normal player save changed. No new M1 benchmark. This remains a first model/animation and combat pass.

## Meridian Keeper solar scorpion — 2026-09-09

Replaced the observatory humanoid guardian with an eight-legged bronze-and-stone scorpion, pincers and raised solar tail. Added a locked-direction beam with a 1.4-second warning, twelve-meter forward range, 0.8-meter lateral threshold and a single-hit discharge. Existing lens_4 identity, 360 health, mirror gate, solar blade and star chart remain intact. Half health increases raw damage from 32 to 44 and shortens recovery from six to four seconds.

Passed 175 checks across five suites: lens 55, solar_scorpion 16, session_save 73, monster_effects 10, finishers 21. Tests cover floor fit, mirror attack gate, warning before damage, sidestep avoidance, exact half-health damage, one-hit behavior, rear/range exclusions, menu/travel/stagger/execution interruption and finisher identity. Lens regression verifies named loot, chart rewards, puzzle gates and save compatibility.

Native Metal/Mobile preview completed with SOLAR_SCORPION_RENDER_COMPLETE. Inspected build/solar-scorpion.png, build/solar-warning.png and build/solar-beam.png; the preview camera was moved left to clear an observatory pillar. QA persistence was disabled and normal player saves were untouched. No new M1 benchmark. Model, animation and encounter tuning remain first-pass work.

## Sundering Strike — 2026-09-09

Added Shift+G Sundering Strike alongside G Whirlwind. Both spend the full shared power meter and use the existing slow-motion/cancellation lifecycle. The new move applies triple melee damage in a five-meter forward cone and staggers surviving targets only after actual health loss. Added a distinct overhead pose and HUD control hint.

Passed 175 checks across five suites: sundering_strike 16, power 19, session_save 73, finishers 21, combat 46. New checks cover forward extended reach, rear/side/range exclusions, walls, protected boss damage/stagger rejection, shared meter/repeat prevention, no self-charge, Shift+G routing, ranged-weapon rejection and pose/time-scale cleanup. The directional fixture was corrected to use world coordinates for dungeon children before the final passing run.

Native Metal/Mobile preview completed with SUNDER_RENDER_COMPLETE. Inspected build/sunder-ready.png, build/sunder-third-person.png and build/sunder-first-person.png; HUD hint fits and camera remains steady. QA persistence was disabled; normal player saves were untouched. Damage currently occurs on activation, matching Whirlwind, with impact-frame animation and balance still open. No new M1 benchmark.

## Charged attack impact timing — 2026-09-09

Moved power-attack damage from activation to animation impact: Whirlwind at 0.30 real seconds and Sundering Strike at 0.48. Targets are evaluated at impact, while weapon damage/effect are captured at activation. Added separate Sunder lift, downswing and recovery poses. Hit flags enforce one resolution, including missed strikes; cancellation clears the active lifecycle. Large time steps retain the active flag through damage so attacks cannot charge themselves at expiry.

Passed 191 checks across six suites: power 20, sundering_strike 17, power_timing 14, combat 46, finishers 21, session_save 73. Timing tests cover harmless windup, moving out of range, no late hit after a miss, cancellation before impact, single impact across a large frame step, no self-charge and time-scale restoration. Existing directional, wall, protected-boss, combat and save checks remain passing.

Native Metal/Mobile preview completed with SUNDER_RENDER_COMPLETE. Inspected build/sunder-third-person.png and build/sunder-impact.png for windup/strike poses. QA used disabled persistence and did not touch normal player saves. Broader animation and feel tuning remain open; no new M1 benchmark.

## Contextual merchant humor — 2026-09-09

Added twenty original greetings across five merchants, with distinct trade-related voices and completed-chapter callbacks. Greetings rotate through eligible lines per session and appear on shop opening. Trade results/errors replace greetings; commerce and save schemas are unchanged.

Passed 60 checks: shops 33 and merchant_voice 27. Coverage includes ordinary rotation, story-gated callbacks, actual shop-opening integration, clear out-of-range trading errors, purchases, stock, prices, protected items, buyback and save compatibility. The dialogue test uses each line's declared prerequisite, including the provisioner's woodland callback.

Native Metal/Mobile preview completed with MERCHANT_VOICE_RENDER_COMPLETE. Inspected build/merchant-apothecary.png and build/merchant-mountain_smith.png; greeting text fits without interfering with the stock list or purchase controls. Also captured build/merchant-outfitter.png. QA persistence was disabled and normal player saves were untouched. This is written shop dialogue; no voice or ambient scheduler was added.

## Combat cue audio pass — 2026-09-09

Added five original deterministic synthesized effects: root_warning, brine_warning, ash_warning, solar_warning and power_impact. Monster warnings trigger at windup start; charged player impact triggers at the strike frame. The existing Effects bus, per-cue cooldowns and bounded voice pool remain in use. Full asset rebuilds invoke the new generator and preserve combined manifest metadata.

Passed 118 checks across six suites: audio 37, hollow_warden 15, brine_crab 15, ash_cantor 18, solar_scorpion 17, power_timing 16. WAV inspection confirmed stereo 22,050 Hz 16-bit PCM, nonempty samples, faded starts and unclipped 0.62 peaks for all five files. The manually stepped power fixture resets audio cooldowns between independent moves.

Created build/combat-cues.wav in root/brine/ash/solar/power order with half-second gaps. No listening-based mix approval is claimed; speaker/headphone tuning remains open. Cues are nonpositional one-shots and may finish after an attack is canceled. QA persistence was disabled; no normal player save or saved audio preference changed.

## Directional monster warning audio — 2026-09-09

Routed four monster warnings through six pooled AudioStreamPlayer3D voices on the Effects bus. Voices follow weakly referenced creature sources, use distance attenuation and a 32-meter maximum, and stop on menus, inactive chapter, death, stagger, execution lock or freed source. Generic effects and charged impacts remain centered.

Passed 114 checks across six suites: audio 37, spatial_audio 12, hollow_warden 15, brine_crab 15, ash_cantor 18, solar_scorpion 17. The freed-source fixture removes its test actor from the world roster before freeing it; final rerun is free of script errors. Tests cover bounded allocation, source tracking, bus/range, cooldown, interruptions and all four cue triggers.

Native recording completed with SPATIAL_RECORD_COMPLETE. In build/spatial-left.wav, channel RMS was approximately 1898 left / 1097 right; build/spatial-right.wav was 1016 left / 1759 right. Both verify expected channel dominance above 1.2x. Preview state disabled persistence; normal player saves and audio preferences were untouched. This validates engine panning, not subjective headphone mix, wall occlusion or HRTF behavior. No new M1 benchmark.

## Terrain-aware footsteps — 2026-09-09

Added original grass, snow and stone footstep WAVs and floor-ray surface selection. Tagged base terrain and hills; retained exact snow-patch rectangles and cobbled path cells from visual generation. Other solid floors default to stone. Existing cadence, grounded/movement checks, quiet effect volume and pitch variation remain active. The generator now builds eight combat/footstep cues and preserves manifest metadata.

Passed 79 checks across four suites: audio 37, footsteps 11, terrain 11, town 20. Footstep checks cover loaded assets, floor-ray selection, exact snow-patch edges, town cobbles, no-floor fallback, airborne silence, physically grounded walking cadence and menu suppression. Terrain and town traversal remain passing; block count remains 328820. WAV inspection confirmed nonempty unclipped PCM; build/footstep-cues.wav previews grass, snow and stone. No subjective listening or new M1 benchmark is claimed.

QA used disabled persistence and did not modify normal player saves or preferences. Wood, metal, water and further regional surface tags remain open. The runtime ray query occurs at footstep cadence, not every frame.

## Wooden interiors and metal decks — 2026-09-09

Added inset plank floors to shared house geometry, with a three-centimeter rise above the existing stone plinth and exposed stone borders. Tagged these floors as wood and the station deck as metal. Added two original synthesized cues, bringing the bank to eight music tracks and twenty-seven effects. Floor selection retains existing cadence and volume behavior.

Passed 165 checks across five suites: footsteps 15, audio 37, town 20, shops 33 and threshold 60. Coverage includes actual floor-ray selection for a house interior and station deck, loaded cues, town traversal, commerce and station progression. Final logs contain no script errors. WAV inspection confirmed nonempty, unclipped stereo 22,050 Hz PCM; build/wood-metal-steps.wav contains three wood and three metal footfalls.

Native Mobile/Metal capture completed with FLOORS_RENDER_COMPLETE on Apple M5 Max. Inspected build/plank-floor.png: floorboards are visible beneath the existing shop rug and furniture. QA persistence was disabled; normal saves and preferences were untouched. No new M1 benchmark or subjective listening approval is claimed. Water and wider regional surface coverage remain open.

## Shareable macOS playtest package — 2026-09-09

Built dist/Frostmere-0.1.0-macOS-AppleSilicon.zip (39,134,676 bytes) using the official Godot 4.7.2 release template, thinned to arm64. The archive contains Frostmere.app, recipient instructions, and Godot/third-party notices, with a sibling SHA-256 checksum. Ad-hoc signature validates with codesign --verify --deep --strict; no Developer ID identity is available, so this is not notarized. macOS 13+ is the configured minimum, not a tested compatibility guarantee.

The first export exposed raw-WAV loading failures. Runtime audio now uses imported Godot resources with a development fallback, and loop endpoints use sample duration so compressed audio loops correctly. All 37 audio regression checks pass, including comparison against authored music durations. Apple Silicon texture import support is enabled. Export logs contain no final script errors.

Launched the release app natively, then verified ZIP integrity, extracted it to a fresh temporary folder outside the workspace, verified its signature again, and launched the extracted app. Both native logs report PACKAGE_SMOKE_COMPLETE with 35 loaded nonempty audio streams, persistence disabled and 329352 world blocks. Inspected the native starting-town screenshot on M5 Max / Mobile Metal. No developer save or preferences are included in the archive or written during native QA. This is launch/resource/render verification, not a full packaged campaign playthrough, recipient Gatekeeper test, minimum-OS test or M1 benchmark.

## Playable dark opening — 2026-09-09

Implemented Ash Through the Snow with a lantern interaction, five-second monster glimpse, exit-arch handoff, optional Tab skip, cold local atmosphere, drifting ash, illuminated ward and restored village lighting. Added a strictly validated optional completion flag with legacy-save bypass. Incomplete prelude saves omit remote coordinates and restart safely. A dedicated preview flag/launcher disables persistence even after returning home.

Passed 215 checks across five suites: dark_intro 23, session_save 73, audio 37, characters 36 and combat 46. Coverage includes supported spawn and continuous walkable approach, proximity gates, actual HUD/interaction integration, pause-safe reveal, skip, completion/legacy/malformed save cases, incomplete-save restart state, reset-key recovery, lighting restoration and untouched first-quest/realm progression. Separate INTRO_PREVIEW_COMPLETE confirms automatic preview startup, disabled persistence and village handoff. The initial attempt named a nonexistent adventure.gd test; the actual combat.gd suite provides the first-adventure regression coverage and passes.

Native Mobile/Metal rendering on M5 Max produced INTRO_RENDER_COMPLETE. Inspected build/dark-intro.png and adjusted ward transparency, silhouette height and surface textures for visibility. Normal player saves/preferences were untouched. No M1 benchmark, voice recording, new composition or full packaged playthrough is claimed. The previously shared 0.1.0 ZIP remains the earlier snapshot.

## Opening scenery, creature choreography and arrival fade — 2026-09-09

Added layered snowy cliffs, pines, snow streaks, rubble, a roadside sign and framed lantern. Replaced the stationary five-second reveal with an eight-second approach, articulated head/jaw movement and retreat into fog. Added a 0.75-second arrival fade that freezes and hides during menus, then removes its overlay.

Passed 102 checks: dark_intro 29 and session_save 73. Opening coverage includes the continuous walkable route, approach/jaw pose, paused choreography, retreat before disappearance, fade progress, pause-menu visibility, overlay cleanup, skip and save migration. Separate INTRO_PREVIEW_COMPLETE verifies isolated startup and handoff. An initial restricted test could not write its isolated save; it was stopped and rerun successfully with the required test-directory access. Final test and render logs contain no script errors.

Native Mobile/Metal capture on M5 Max completed with INTRO_RENDER_COMPLETE. Inspected build/dark-intro.png, build/intro-arrival-fade.png and build/intro-arrival.png, including full lighting restoration after the overlay fades. Existing saves and audio preferences were untouched. No new audio composition or M1 benchmark was performed.

## Campaign handoff and parallel-route guidance — 2026-09-09

Added read-only home-world campaign suggestions, available branch summaries and journal travel directions. Corrected the Lens suggestion to match its archive prerequisite and supplied missing roots/choir/Mirewatch/space/Aeralis/siege/seal/Hell handoffs. Station guidance uses the home Lens trail first and the actual northern crossing inside Lens. Accepted branches are prioritized; other chapter objectives and manual waypoints remain authoritative. No progression or save schema changed.

Passed 197 checks across four suites: campaign_guide 21, atlas 42, threshold 60 and convergence 74. Guide coverage includes all sixteen four-branch completion combinations, actual HUD/journal integration, resume priority, home versus local transit targets, late realm gates, manual waypoint preservation, local objectives and no progression grants. Fixed an initialization-order error exposed during native rendering: map construction occurs before realm controllers. Final reruns have no script errors.

Native Mobile/Metal captures completed with CAMPAIGN_GUIDE_RENDER_COMPLETE on M5 Max. Inspected build/campaign-open-paths.png and build/campaign-route-journal.png for HUD wrapping, open-path footer and journal directions. Capture profiles disable persistence. No full timed playthrough, combat rebalance or new M1 benchmark is claimed.

## Batch crafting for expedition supplies — 2026-09-09

Added five- and ten-batch crafting for fourteen ammunition/refining/consumable recipes. Full scaled costs are checked before mutation; output and XP scale equally, with one commit. Gear and the Transit Regulator/Cinder Ward stay single-craft. UI buttons display yield and total ingredient counts and recheck station proximity on activation.

Passed 258 checks: batch_crafting 25, crafting 200 and shops 33. New coverage compares ten-batch output/cost/XP against ten single crafts for every eligible recipe, verifies invalid quantities, locked recipes, wrong stations, insufficient aggregate materials, story-component/gear exclusion, an actual five-batch UI action, and stale-button proximity rejection. Final logs contain no script errors.

Native Mobile/Metal capture on M5 Max completed with BATCH_CRAFTING_RENDER_COMPLETE. Inspected build/batch-crafting.png for output quantities, cost rows and button readability. QA used isolated character/atlas state. No combat-stat rebalance, new resource supply, M1 benchmark or full human campaign pacing study is claimed.

## Required story-craft supply recovery — 2026-09-09

Added dedicated spare-parts rebuild actions to the expedition and wardwright supply chests. Recovery requires accepted chapter, collected original supplies, learned design and its evidence/plans gate, insufficient ordinary ingredients, no owned component and an unfinished installation/binding. It grants one existing inventory component, then uses normal quest actions. No new persistent field or broad material replenishment is introduced.

Passed 367 checks: story_recovery 35, convergence 74, seal 58 and crafting 200. Coverage includes both actual rebuild buttons, proximity and subject checks, design and supply gates, affordable-recipe exclusion, duplicate prevention, no raw-material/gold/XP gain, rejected sales, save/load, ordinary installation, Sealbreaker requirement and no recovery after completion. All final logs are free of script errors.

Native Mobile/Metal capture on M5 Max completed with STORY_RECOVERY_RENDER_COMPLETE. Inspected build/story-recovery.png for explanation and action readability. Normal player saves/preferences were untouched. This addresses the two required crafted components; it does not claim a complete economy review or combat rebalance.

## Starting dagger cadence and combat baseline — 2026-09-09

Added family-aware melee timing/stamina helpers: daggers attack every 0.38 seconds for six stamina, or four with Measured Swing. Updated the perk description; other melee timings/costs remain intact. Basic damage, crit rules, ammo and potion rewards were not modified. The runtime-stat audit records eight untrained Frostkin starting playstyles in build/early-combat-baseline.md and completed with EARLY_BALANCE_AUDIT_COMPLETE.

Passed 147 checks across five suites: melee_pacing 10, combat 46, skills 42, power_timing 16 and finisher_moves 33. New coverage uses actual attack calls, checks exhausted stamina and cooldown rejection, both perk costs, preserved sword/two-handed timing, and a real dagger hit against a barrow guard with exactly one ordinary damage application. Final logs contain no script errors. QA used isolated saves.

The audit compares cooldown-limited, guaranteed-hit values and documents its assumptions. No human success-rate study, animation approval, complete ancestry comparison or M1 benchmark is claimed. In particular, high-tier dagger builds still require encounter playtesting.

## Staff upgrade scaling — 2026-09-09

Passed 388 checks: staff_scaling 100, crafting 200, skills 42, combat 46. New coverage tempers all eleven staff designs through all five ranks using actual forge transactions, checks the Legendary cap, Kindled Mind, physical-weapon exclusion, unequipping, save/load, live equipped-stat refresh, and projectiles from all five spells. Each spell retains its magicka cost and cooldown. Workshop detail includes the current contribution and next rank's magic benefit. Final test logs contain no script errors.

The runtime staff audit completed with STAFF_BALANCE_AUDIT_COMPLETE and wrote build/staff-combat-baseline.md. Native Mobile/Metal on M5 Max completed STAFF_SCALING_RENDER_COMPLETE; build/staff-scaling.png was checked for readable upgrade details. QA used isolated profiles. No human encounter-duration test or M1 performance measurement was performed; overall later-game difficulty remains open.

## Later reward progression — 2026-09-09

Passed 218 checks: reward progression audit 24, realms 38, ending 56, staff_scaling 100. The audit compares actual equipped damage/spell power at all six quality levels for four earlier/later pairs. Existing realm tests cover chapter gates, one-time guardian loot, portable gear/magic and progress persistence. Ending tests cover all three heirloom claims, quality/favorite protection, crafting and save validation. Staff tests cover all designs, actual tempering, spell projectiles and save/load. Final logs contain no script errors.

Reports: build/reward-progression.md and refreshed build/staff-combat-baseline.md. No visual assets or UI layout changed in this pass; no new native capture was needed. QA used isolated profiles. Enemy stats were not adjusted, and no human encounter-duration or M1 performance claim is made.

## Furnace Maw heat shutters — 2026-09-09

Passed 121 checks: furnace_pressure 16, furnace_beast 11, ending 56, realms 38. New checks cover exact closed mitigation for melee/marksman/magic, exposure after dodging, exact open damage, shutter position and label, window lifetime, pause/travel/death/execution cancellation, actual lethal finisher through closed shutters and one-time guardian loot. Existing suites preserve rupture damage/cadence, chapter gates, engine shutdown and ending reward behavior. Final logs contain no script errors.

Native Mobile/Metal M5 Max capture completed FURNACE_BEAST_RENDER_COMPLETE. Inspected build/furnace-core-exposed.png for separated shutters, visible furnace mouth and exposure feedback. The render fixture also captures the closed and warning states. QA uses isolated profiles; no human fight-duration study or M1 benchmark was performed.

## Prismwing second-phase bite — 2026-09-09

Passed 98 checks: prismwing_pressure 16, crystal_wyrm 11, realms 38 and finisher_moves 33. The new suite exercises warning-before-damage, committed aim, sidestep/range/facing/height evasion, exact armored hit damage, cooldown non-repetition, pause/travel/stagger/execution cancellation, retained fracture opening, ranged fallback and health-reset behavior. Existing suites verify fan projectile counts, persistent guardian defeat, finishers, realm progression and rewards. Final logs contain no script errors.

Native Mobile/Metal capture completed CRYSTAL_WYRM_RENDER_COMPLETE. Inspected build/prismwing-bite.png for readable bite warning and distinct raised-wing/head pose. The fixture also retains intact/fractured captures. QA profiles are isolated. No human fight-duration measurement or M1 benchmark was performed.

## Directional impact feedback — 2026-09-09

Passed 97 checks: damage_direction 15, parry 20, combat 46, prismwing_pressure 16. New coverage uses actual player damage calls to verify right/front/rear/left bearings, turning relative to impact position, ignored invulnerable hits, shield block, successful parry without health loss, exhausted guard, expiry, non-directional sources, menu clearing and death/respawn clearing. Existing checks preserve defensive mechanics and monster counterplay. Final logs contain no script errors.

Native Mobile/Metal M5 Max capture completed DAMAGE_DIRECTION_RENDER_COMPLETE. Inspected build/damage-direction-hit.png for directional arrow and readable outcome label; the fixture also writes build/damage-direction-parry.png. QA uses isolated profiles. No timed human encounter study or M1 benchmark was performed.

## Lights Beneath the Boards — 2026-09-09

Passed 181 checks: mirewatch_rescue 30, convergence 74, atlas 42, story_recovery 35. The new suite uses physical E interactions and actual dialogue buttons, verifies stage order, main-quest independence, remote-action rejection, exact rewards, duplicate prevention, visible rescued NPC/cache state, mid-quest and completed save/load, atomic rejection of malformed stages, legacy defaults, journal progress and return persistence. It checks supported positions and physically walks the western deck between quest stations. Final test logs contain no script errors.

Native Mobile/Metal capture completed MIREWATCH_RESCUE_RENDER_COMPLETE. Inspected the signal, readable rescue dialogue and rescued NPC in build/mirewatch-signal.png, build/mirewatch-rescue-dialogue.png and build/mirewatch-tovin-rescued.png. QA used isolated profiles. The rescue is a compact interaction sequence, not a fully modeled vault interior. No human duration or M1 performance measurement was performed.

## The Astronomer's Debt — 2026-09-09

Passed 233 checks: astronomer_debt 36, lens 55, atlas 42 and staff_scaling 100. New coverage uses actual keeper/cache buttons and actual sentinel defeats, checks acceptance and guard gates, duplicate/remote recovery rejection, main-supply independence, partial saves, both resolutions, exact distinct rewards, repeat/switch prevention, completed saves, journal outcomes and atomic rejection of seven malformed progress cases. Older saves default to unstarted debt progress. Final logs contain no script errors.

Native Mobile/Metal capture completed ASTRONOMER_DEBT_RENDER_COMPLETE. Inspected build/astronomer-debt-choice.png for readable narrative, exact reward labels and accessible choices. QA uses isolated profiles. This compact quest reuses existing excavation sites; no new tomb interior, town economy simulation, human duration study or M1 benchmark is claimed.

## Nets Full of Silver — 2026-09-09

Passed 351 checks: silver_nets 43, shore 65, crafting 201, atlas 42. New checks cover actual Sella/net/cache buttons, guard defeat, physical dock support, investigation order, remote-action rejection, main-quest independence, both exact payments, Fine/favorite reward protection, pattern unlock, forging another ring, tempering and equipped attributes, partial/completed saves, legacy defaults, journal outcomes and malformed progress rejection. The crafting catalog check now verifies every actual item ID instead of hard-coding the former 145-item count. Final logs contain no script errors.

Native Mobile/Metal capture completed SILVER_NETS_RENDER_COMPLETE. Inspected build/silver-nets-choice.png and build/netmender-band.png for readable choices and accurate gear details. QA uses isolated profiles. This is a compact investigation with dialogue-resolved crew recovery; no new refuge interior, escort behavior, human duration study or M1 benchmark was performed.

## Letters Above the Snow — 2026-09-09

Passed 175 checks: family_letters 38, mountain 74, clan_voice 21 and atlas 42. New checks use actual NPC/memorial buttons, verify both-account and witness prerequisites, duplicate/remote rejection, supported memorial access, independence from council/clan choices, exact reputation/gold/material rewards for both outcomes, public-only inscription change, mid/completed saves, journal outcomes, six malformed-progress cases and legacy defaults. Existing council and capstone checks remain green. Final logs contain no script errors.

Native Mobile/Metal capture completed FAMILY_LETTERS_RENDER_COMPLETE. Inspected build/family-letters-choice.png and build/family-letters-memorial.png for readable options and visible public dedication. QA uses isolated profiles. This is a compact peaceful investigation; no broader family simulation, human duration study or M1 performance measurement was performed.

## The Apprentice Who Vanished — 2026-09-09

Passed 156 checks: missing_apprentice 38, archive 52, lantern 24 and atlas 42. New checks use actual notice/testimony/NPC buttons and sentinel defeat, verify stage and proximity gates, automatic return to camp, relocated interaction targeting and updated title, supported camp position, independent atlas/faction progress, both exact equipment/formula/gold rewards, repeat/switch prevention, mid/completed saves, journal outcomes, malformed progress and legacy defaults. Final logs contain no script errors.

Native Mobile/Metal capture completed MISSING_APPRENTICE_RENDER_COMPLETE. Inspected build/apprentice-research-choice.png and build/apprentice-back-at-camp.png for readable choices and the returned NPC. QA uses isolated profiles. The return is resolved by interaction, not an escort pathfinding sequence; no human duration study or M1 benchmark was performed.


## Shadowless stag quest — September 9, 2026

Shadowless stag: 70 isolated checks; Roots 85, Coven finale 129, atlas 42 (326 total). Native Mac renders checked for the spectral guide and forgiveness dialogue. See SHADOWLESS_STAG.md for save and travel behavior.


## Tidemarch Compact initiation

Compact initiation: 43 checks plus shore 65, silver nets 43 and atlas 42 = 193 passing checks. Native Mac captures of the hearing, oath and arbiter were inspected. See TIDE_COMPACT.md.


## The Harbor That Lied

Harbor follow-up: 38 new checks plus Compact 43, shore 65, silver nets 43, atlas 42 = 231 passing checks. Native Mac presentation and sheltered-witness captures inspected. See HARBOR_LIED.md.


## The Price of Safe Passage

Safe Passage: 66 checks plus harbor 38, Compact 43, shore 65, silver nets 43 and atlas 42 = 297 passing checks. Native Mac charter choice and signed-caption visuals inspected. See SAFE_PASSAGE.md.


## Voices in the Furnace

Choir Listener initiation: 49 checks; choir 70, convergence 74, atlas 42, totaling 235 passing checks. Native Mac oath and cool-shrine visuals inspected. See CHOIR_LISTENER.md.


## Ash Remembers Everything

Ash Memory: 41 checks; Listener 49, choir 70, convergence 74, atlas 42 = 276 passing checks. Native Mac decision and open-cabinet captures inspected. See ASH_MEMORY.md.


## The Fire We Invite

Fire finale: 49 checks plus Ash Memory 41, choir 70, Clan Voice 21, mountain 74 and atlas 42 = 297 passing checks. Actual commission/mandate guards, prior-oath exclusion and contradictory-save validation covered. Native Mac visuals inspected. See FIRE_INVITE.md.


## A Pilgrim’s Empty Shoes

Empty Shoes: 33 checks, choir 70, Listener 49, Fire Invited 49, atlas 42 = 243 passing checks. Native Mac choice and relocated camp NPC captures inspected. See EMPTY_SHOES.md.


## The Last Warm Shelter

Warm Shelter: 30 checks plus mountain 74, Clan Voice 21, family letters 38, atlas 42 = 205 passing checks. Native Mac hut and route choice inspected. See WARM_SHELTER.md.


## The Old Watch Road

Hearthbound initiation: 33 checks, atlas 42, combat 46, characters 36, hunt 22, wilderness 19 = 198 passing checks. Native Mac board and marker visuals inspected. Replaced the stale character catalog item-count assertion with a catalog uniqueness check. See HEARTHBOUND.md.


## A Winter Without Wolves

Watershed: 39 checks; Hearthbound 33, hunt 22, wilderness 19, atlas 42 = 155 passing checks. Native Mac visuals inspected, including Senna’s corrected placement. See WATERSHED.md.


## Who Guards the Pass?

Warden: 37 checks; watershed 39, Hearthbound 33, hunt 22, atlas 42 = 173 passing checks. Fixed the supply cache’s conflicting terrain placement. Native Mac choice and patrol captures inspected. See WARDEN.md.


## The Boat That Would Not Burn

Ash boat 43, shore 65, silver nets 43, safe passage 66, atlas 42 = 259 passing checks. Native Mac cargo-choice and launch captures inspected. Coverage includes actual interaction buttons, supported ground, stale actions, both payouts, duplicate prevention, save compatibility and malformed progress. See ASH_BOAT.md.


## The Keeper’s Last Light

Last light 45, shore 65, ash boat 43, silver nets 43, safe passage 66, atlas 42 = 304 passing checks. Native Mac final dialogue, restored tower and anchored ship captures inspected. See LAST_LIGHT.md.


## A Harvest of Amber

Amber harvest 47, roots 85, shadowless stag 70, Coven finale 129, atlas 42 = 373 passing checks. Native Mac final dialogue and both visible grove outcomes inspected. See AMBER_HARVEST.md.


## Final seven quests

Final seven quests: remaining_quests 471 and road_branches 88, plus 20 affected-system regression suites, total 1,580 checks and zero failures. Native Mac captures inspected for every final dialogue and five physical scenes. Corrected a cart/tree overlap. Atlas has 51 playable quests and zero planned quests. See ROAD_QUESTS.md.


## Station supplies for existing builds

The station’s two caches previously supplied rifle ammunition but no arrows or magicka draughts. The emergency locker now adds 36 arrows and two magicka draughts; the cargo cache adds 24 arrows and one draught. Both remain one-time claims, and already-collected caches do not refill after an update. Existing rifle rewards, recipes, enemies and chapter gates are unchanged. Dialogue lists the new supplies.

A runtime equipment audit covers six bow/quality combinations against the five 100-HP troopers and 380-HP Hullcarver. A Superior Steel Longbow requires 30 ideal hits with exposed-core boss hits or 43 through the closed shell, leaving 17 misses within the 60-arrow cache budget in the latter case. An ordinary Iron Longbow uses all 60 if it never exploits exposure. These are conservative single-target hit budgets without criticals, training or finishers, not measured player accuracy or encounter duration. Three draughts restore up to 150 magicka. The reserve supports existing playstyles without requiring the rifle; players can still bring supplies, craft or return home.

Regenerate build/station-supply-baseline.md with --headless --path . --script tools/audit_station_supplies.gd. Threshold 68, staff scaling 100 and crafting 201 checks passed (369 total). New coverage verifies exact reserves, remote/duplicate rejection, live save reload and actual draught consumption. Native Mac engineer dialogue inspected. Human campaign-duration and resource-use testing remain open.


## Arrival reserves for existing builds

Aeralis attunement now adds 36 arrows and two Magicka Draughts; Crucible attunement adds 48 arrows and three draughts. The normal arrival-crystal interaction announces the exact reserve. Existing spells, equipment, materials and the Crucible’s 160 Infernal Rounds are unchanged. Supplies use the existing one-time attunement flags: duplicate interactions, revisits and reloads cannot refill them. Older saves that already claimed attunement do not receive a catch-up refill.

The runtime audit in tools/audit_realm_supplies.gd produces build/realm-supply-baseline.md for twelve realm/bow/quality combinations. A Superior Steel Longbow needs 16 ideal hits across Aeralis’s two sentries and guardian, and 18 hits against the Crucible’s enemies when exploiting the Maw’s exposure or 31 through closed shutters. The ordinary Iron Longbow leaves only two missed shots within the Crucible’s 48-arrow reserve if every boss hit lands against closed shutters. These are per-target rounded hit budgets with no criticals, training, enchantments or finishers, not human accuracy or timed fight results. Potion reserves restore up to 100 and 150 magicka respectively.

realm_supplies 30, realms 38 and staff_scaling 100 checks passed: 168 total. Coverage includes physical crystal interaction, exact additions, preserved Infernal Rounds, real bow firing, real potion use, used-inventory saves, revisits and old claimed-save compatibility. No save migration or release package. Winter Siege and Broken Seal resource pressure, plus timed campaign playtesting, remain next in the balance review.


## Recovery for spent siege repair stock

Spending the garrison’s original repair stock on optional upgrades could leave the ward or ballista unaffordable, while the failure message directed the player back to an already-claimed chest. After the scouts are cleared and the original stores have been collected, an unfinished, unaffordable defense now offers “Install the garrison’s fitted spare.” The spare repairs that defense directly and grants no raw materials, inventory item, gold or crafting XP. If ordinary costs are affordable, the fallback is unavailable. Normal repair prices are unchanged.

Existing repaired-defense flags prevent repeats and preserve the result in saves. Both defenses are still required before the assault. The ward’s one-time health/magicka restoration and the ballista’s existing combat effect follow the normal assault path. No new save fields or migration are needed. Broken Seal’s existing Cinder Ward recovery was regression-tested; no change was needed there.

winter_recovery 30, winter 55, seal 58 and story_recovery 35 checks passed: 178 total. Tests cover acceptance/scout/store gates, affordable versus spent stock, actual spare buttons, remote actions, exact no-reward behavior, saved repairs, duplicate prevention and the real assault transition. Native macOS fallback dialogue was inspected in build/winter-fitted-spare.png. General siege/underworks ammunition pressure and timed campaign difficulty still need review.


## Siege and underworks combat reserves

The existing reserved stores in both Winter Siege and Broken Seal now include 60 arrows and 120 Station Rounds. Winter adds two Magicka Draughts; Broken Seal adds three. Original steel, crystal, rune dust and Ash Glass quantities are unchanged, so these supplements do not spend the stock intended for defenses or the Cinder Ward. Supply descriptions list the additions. Existing acceptance, proximity and one-time claim flags apply; old claimed stores do not refill. Normal loot, enemies, crafting prices, the siege fitted-spare fallback and Cinder Ward recovery are unchanged.

The audit in tools/audit_defense_supplies.gd runs eight loadouts through live enemy receive_damage methods. It includes Winter’s actual 100-HP ballista reduction. A Superior Steel Longbow requires 36 ideal hits across the siege and 37 across Broken Seal. The original Fine Station Rifle needs 75 rounds in either chapter; 120 supplied rounds leave 45 misses in that ideal damage model. An ordinary Iron Longbow leaves only 5/3 missed shots within the 60-arrow reserve. These figures exclude criticals, training, other equipment, perks and finishers; they are not measured combat duration or player accuracy. Winter’s existing intermission ward already restores health and magicka; the added draughts provide limited in-fight support.

Report: build/defense-supply-baseline.md. Final checks: defense_supplies 42, winter_recovery 30, winter 55, seal 58 and story_recovery 35 = 220 passing checks. Coverage includes actual supply buttons, exact original and added supplies, real rifle/bow/potion use, saves, revisit/reload duplication prevention and earlier claimed profiles. The supply test normalizes JSON numbers to integers before comparing inventory quantities, matching the existing load behavior. Native Mac supply descriptions inspected in build/winter-combat-reserves.png and build/seal-combat-reserves.png. No release package produced.

The late-chapter ammunition reserve pass now covers the station, Aeralis, siege, underworks and Crucible. Timed campaign playtests, healing pressure and combat pacing across different builds remain open; this numerical supply review does not establish overall game balance.


## Consumable healing preview

407 checks passed: healing_preview 69, crafting 201, roots 85, archive 52. Run tests/healing_preview.gd headless for effective restoration, fractional caps, inventory actions, resource-full preservation and consumed-stock saves. Its native -- --capture mode also passed 69 checks and generated build/healing-preview.png, visually inspected for readable bonus, current pool, actual restoration and waste. Fixtures disable profile persistence. Final logs contain no script errors or failed checks. No release package or timed campaign playtest.


## Cross-build healing pressure audit

Run `--headless --path . --script tools/audit_healing_pressure.gd` using the local Godot engine. The isolated fixture invokes actual Prismwing/Maw attack methods, measures player damage and potion recovery, and checks full-stamina blocks and exhausted guard breaks. It produces 72 rows in `build/healing-pressure-baseline.md` only on success. Audit 253, combat 46, parry 20, prismwing_pressure 16, furnace_pressure 16 and healing_preview 69 checks passed (420 total); final logs have no script errors or failed checks. This numerical review did not change game UI or balance values and required no native screenshot. It does not replace timed campaign or hardware performance testing.


## Local combat metrics

`tests/combat_metrics.gd` passed 21 checks: disabled logging, real damage, invulnerability rejection, paused/unscaled timing, actual healing and rejected potion use, arrow/spell spending and rejected inputs, idle trimming, JSON append/readback, enemy overkill/kill recording, travel splitting and death before respawn. Combat 46, parry 20 and healing_preview 69 regressions also passed: 156 total. The Python summarizer successfully read the dedicated three-record QA log into build/combat-metrics-test-report.md. No UI changes or native visual capture were required. See COMBAT_PLAYTESTS.md for opt-in usage and limitations.


## Dedicated dark-opening score

Audio 38, dark_intro 35 and spatial_audio 12 checks passed (85 total). New coverage verifies the dedicated opening track, reveal/resolution cue selection, pause/resume synchronization, one-time resolution and cue cleanup at arrival. Three original stereo PCM assets passed channel/rate, non-silence, peak and matching-endpoint checks: intro 48 seconds (peak .48, RMS .1202), ward_approach 2.8 seconds (.62, .2230), ward_holds 1.8 seconds (.62, .1263). Godot imported the assets; generator syntax checked. The full generator now includes the intro extension. Subjective listening, M1 performance and cinematic pacing remain unverified.

Native Mac audio-only capture passed in tests/record_intro_audio.gd with isolated profiles and scene rendering disabled: 12.57 seconds, peak 10,534 / 32,767, no clipping. It verifies the intro track, live reveal, resolution and village crossfade and saves build/intro-audio-engine.wav. The initial capture validation was slow because it repeatedly accessed the WAV data property inside its sample loop; caching the PCM array resolved it. This is audio-engine validation, not a renderer benchmark or subjective listening review.


## Wyrmkeep circulation and winter detail

266 checks passed: wyrmkeep_detail 36, mountain 74, warm_shelter 30, family_letters 38 and road_branches 88. New checks sample eleven lanes at half-metre intervals with a player-width capsule and ground-support queries, verify nine existing interaction approaches and well collision, and exercise real stone/snow/wood footstep selection. Three initially obstructed lanes were rerouted around a house corner, ward stone and clan porch. Native Mac final overview and courtyard views were inspected; render fixture is tests/render_wyrmkeep_detail.gd with -- --capture and isolated profiles. World batch count increases from 333,718 to 333,862. No new M1 benchmark or release package.


## Saltbreak waterfront detail

298 checks passed: saltbreak_detail 21, shore 65, silver_nets 43, ash_boat 43, last_light 45, safe_passage 66, footsteps 15. Pier checks use three lanes sampled at half-metre intervals for capsule clearance and ground support, real floor-ray surface selection, nearby quest approaches and lack of an offshore floor. Native Mac captures inspected; one non-colliding rock stack overlapping the pier edge was then removed and final views regenerated. Final world batch count: 334,253, a net addition of 391 blocks. No new save fields, merchant transactions, release package or M1 performance claim.


## Pinehall environment detail

128 checks passed: pinehall_detail 23, archive 52, missing_apprentice 38 and footsteps 15. Five lanes are sampled every half metre for player-width collision clearance and ground support; coverage also includes seven existing quest approaches, the rescued apprentice position and grass/stone/wood floor-ray footstep selection. Native Mac views from tests/render_pinehall_detail.gd were inspected with -- --capture and isolated profiles. Final world batch count is 334,373 (+120 blocks). No new interactions, save fields, release package or hardware benchmark.


## Pinehall forest terrain

205 checks passed: pinehall_terrain 19, pinehall_detail 23, archive 52, missing_apprentice 38 and session_save 73. Coverage includes unchanged inhabited ground, summit collision/grass footsteps, slope gradients, actual uphill player traversal, elevated saves and obsolete flat-ground saves beneath the new terrain. The initial fixed-time traversal assertion was too short for uphill movement; the final bounded walk reaches the summit at x=35.04, y=3.87 on the floor. All final logs passed without script errors. Native Mac clearing, reading-table and forest-slope captures inspected. Batch count 336,143; no new M1 benchmark, release or save format.


## Detailed woodland pine geometry

153 checks passed: woodland_pine 111, pinehall_detail 23 and pinehall_terrain 19. New geometry checks cover all 37 trees for deterministic output, bounded piece count and footprint/height. Existing lane, uphill-walk and save tests passed with the branch geometry. Native Mac views were inspected; tapered tip segments now overlap the crown, correcting the initial floating-tip gap. Final world count 351,080 blocks; foliage uses existing material batches, with unchanged trunk collision and no per-tree update loop. No M1 benchmark or release package.


## Hullcarver wind-up and recoil

133 checks passed: hullcarver 19, threshold 68 and combat 46. The physical charge and mandibular pose track the actual wind-up, do not expose the core early, disappear on firing and clear on interruption. Recoil settles independently of the preserved three-second exposure window. Existing station gates, damage multipliers, finisher defeat and one-time loot checks pass. Native Mac armored/charge/recoil/core captures inspected through tests/render_hullcarver.gd with isolated -- --capture profiles. No combat tuning, release or hardware benchmark.


## Furnace Maw procedural animation

70 checks passed: furnace_beast 16, furnace_pressure 16 and realms 38. New assertions verify side bellows/jaw wind-up, preserved warning target and timing, impact settling during exposure and neutral pose on pause. Existing exact damage, dodging, exposure, travel, execution and guardian reward checks pass. Native Mac captures inspected using tests/render_furnace_beast.gd with isolated -- --capture profiles. No combat balance changes, save schema or release package.


## Prismwing procedural animation

70 checks passed: crystal_wyrm 14, prismwing_pressure 18 and realms 38, with zero failures or script errors. Coverage includes feather spread/body brace, release recoil, pause reset, jaw/head draw-back without aim drift, forward bite recoil, existing dodge windows, projectile counts and guardian progression. Native Mac captures from tests/render_crystal_wyrm.gd were inspected using isolated -- --capture profiles. No combat tuning, save changes, release package or hardware benchmark.


## Directional finisher effects

83 checks passed: finisher_moves 39, monster_effects 23 and finishers 21. All six melee weapon families execute through the normal defeat path at different headings, with fragment orientation checked against the player. Monster checks cover crystal/alien/furnace materials, tumbling movement, pause/resume, expiry and realm-change cleanup; existing eruption, protection-gate and one-time defeat checks still pass. Initial inferred-type compiler errors were fixed before the final successful runs.

Native Mac crystal-sweep and furnace-crush impacts were inspected using tests/render_finisher_effects.gd with isolated -- --capture profiles. Captures: build/finisher-aeralis-breakup.png and build/finisher-crucible-breakup.png. No release package or hardware benchmark.


## Creature corpse poses

88 checks passed: monster_corpses 18, hullcarver 19, crystal_wyrm 14, furnace_beast 16 and finishers 21. The new fixture checks collision removal, distinct settled poses, preservation through physics/menu updates, and reconstruction from existing defeated progress. A hidden Hullcarver charge transform initially differed on reconstruction; resetting its scale/rotation resolved the mismatch. Existing finisher gates and guardian loot checks pass. Final logs contain zero failures or script errors.

Native Mac front-facing corpse captures were inspected through tests/render_monster_corpses.gd with isolated -- --capture profiles: build/corpse-alien.png, build/corpse-crystal.png and build/corpse-furnace.png. This validates static final poses, not animated collapse timing or a human combat playthrough. No release or hardware benchmark.


## Animated creature defeats

100 checks passed: monster_corpses 30, hullcarver 19, crystal_wyrm 14, furnace_beast 16 and finishers 21. Coverage includes live-pose capture, intermediate transforms, menu freeze alongside enemy physics, completion/travel settling, collision removal and deterministic defeated-state reconstruction. Final transforms are assigned exactly to avoid interpolation rounding differences on reload. Dead Hullcarver/Maw updates preserve animated plate transforms instead of resetting them during menus. Final logs have zero failures or script errors.

Native Mac midpoint poses inspected using tests/render_monster_corpses.gd with isolated -- --capture profiles, producing build/collapse-alien.png, build/collapse-crystal.png and build/collapse-furnace.png. Motion timing was checked programmatically; these screenshots are midpoint visual checks, not a human timing/playthrough evaluation. No release or hardware benchmark.


## Creature execution reactions

108 checks passed: creature_executions 18, monster_corpses 30, finishers 21 and finisher_moves 39. New checks cover all three guardians for pre-impact motion without damage/collider displacement, pose preservation through enemy physics, menu cancellation, lethal handoff into collapse and corpse preservation during player finisher cleanup. Existing weapon-family, barrier, range and saved-defeat checks passed. Final logs have zero failures or script errors.

Native Mac wind-up poses inspected through tests/render_creature_executions.gd with isolated -- --capture profiles: build/execution-alien.png, build/execution-crystal.png and build/execution-furnace.png. The fixture holds a wind-up and moves the viewing position back for inspection; it is not a continuous gameplay timing review. No release or hardware benchmark.


## Creature finisher audio

104 checks passed: audio 38, creature_executions 27 and finisher_moves 39. Coverage includes loading all 41 audio assets, no early creature finisher sound, correct material cue on lethal impact, no repeat during recovery, and existing finisher behavior. Source WAV checks verified deterministic regeneration, stereo 22050 Hz / 16-bit format, silent/faded edges and peaks of 14,745 without clipping.

Native Mac tests/record_finisher_audio.gd recorded three actual impacts through the audio mixer with isolated -- --capture profiles. Result: build/finisher-audio-engine.wav, 5.14 seconds, peak 9,949, no clipped samples. This verifies mixer output and routing; subjective speaker/headphone listening remains open. No release package.


## Wyrmkeep winter pines

192 checks passed: winter_pines 52, wyrmkeep_detail 36, mountain 74 and warm_shelter 30. New geometry checks cover all thirteen trees for deterministic output, bounded piece counts, snow coverage and canopy clearance from the authored lane segments. Existing physical lane-clearance, interaction approaches and town/watch-hut quest checks pass. Native Mac east/west tree-group captures inspected through tests/render_winter_pines.gd with isolated -- --capture profiles. Assets: build/wyrmkeep-winter-pines.png and build/wyrmkeep-west-pines.png. Added geometry: 6,309 blocks. No new M1 benchmark, save fields or release package.


## Wyrmkeep ground detail

166 checks passed: winter_ground 26, wyrmkeep_detail 36, mountain 74 and warm_shelter 30. New runtime checks verify the 75-block budget, six rock snow-cap raycast heights, snowy footstep selection and supported positions on thirteen drifts. Existing physical lane and quest checks pass. Native Mac captures inspected: build/wyrmkeep-snow-ground.png and build/wyrmkeep-rocks.png, using tests/render_winter_ground.gd with isolated -- --capture profiles. No new save fields, release or hardware benchmark.

An initial disk-full error prevented file creation and test startup. Removing the redundant /private/tmp/skyrimcraft-godot.zip installer recovered approximately 163 MB; the installed engine was verified present and retained. Implementation and validation then completed.


## Rimefang charge presentation

82 checks passed: frost_beast 22, finishers 21 and finisher_moves 39. New assertions check head/body draw-down, running stride and cancellation reset. Existing committed aim, sidestep, single-hit damage, finisher interruption, harvest/reward and save checks pass. Native Mac warning and running poses inspected using tests/render_frost_beast.gd with isolated -- --capture profiles. Captures: build/frost-beast-warning.png and build/frost-beast-charge.png. No added mesh pieces, save fields, release or hardware benchmark.


## Wilderness bite animation

90 checks passed: wild_bites 10, wilderness 19, frost_beast 22 and finisher_moves 39. The new fixture checks wolf/boar warning poses without early damage, impact movement with actual damage, recovery, menu reset and retreat avoidance. Existing harvest, saved progression, Rimefang and finisher checks pass. Initial pause assertions used exact float equality for a Vector3 coordinate; tolerance-based comparisons now pass. Native Mac unobstructed jaw poses inspected through tests/render_wild_bites.gd with isolated -- --capture profiles: build/bite-wolf.png and build/bite-boar.png. No release or hardware benchmark.


## Colossus slam animation

78 checks passed: colossus 20, wilderness 19 and finisher_moves 39. New assertions cover two raised arms, downward impact, settling and menu reset. Existing warning time, dodge, cover, guard, phase damage, cancellation and harvest checks pass. Native Mac warning/impact poses inspected through tests/render_colossus.gd with isolated -- --capture profiles: build/colossus-slam.png and build/colossus-impact.png. No added mesh pieces, save schema, release or hardware benchmark.


## Terrain-aligned slam debris

50 checks passed: ground_slam_effect 7, colossus 20 and monster_effects 23. Coverage includes no early debris, one bounded burst on a resolved missed slam, terrain clearance without extra damage, pause/resume, expiry and travel cleanup. Existing Colossus damage/guard/phase checks and other monster effects pass. Native Mac impact inspected through tests/render_colossus.gd with isolated -- --capture profiles; build/colossus-impact.png holds debris at 0.24 seconds for inspection. No release or hardware benchmark.


## Regional native performance baseline

Added tools/benchmark_regions.gd and ran its three fixed views successfully on the M5 Max at 1280×800 with VSync enabled. Frostmere/Pinehall/Wyrmkeep median frame intervals: 8.31/8.33/8.32 ms; p95: 9.29/8.70/8.91 ms. Samples contain 601/600/601 frames after two-second warmups. Output schema, sample counts and ordered percentiles checked. No script errors. Full results and limits in PERFORMANCE.md and build/region-performance.json. This is an idle development-build baseline, not a before/after comparison, combat test, CPU/GPU bottleneck diagnosis or M1 validation.


## Moving-camera and Colossus performance

Native tools/benchmark_activity.gd completed on the M5 Max at 1280×800 with VSync. Pinehall moving view: 941 frames, median 8.36 ms, p95 9.71 ms, p99 12.13 ms. Colossus active AI: 1,414 frames, median 8.68 ms, p95 10.43 ms, p99 11.93 ms. Two actual slams occurred across warmup and sampling. Native isolation, active combat, sample counts and percentile ordering validated; no script errors. Method and limitations in PERFORMANCE.md. No release or M1 claim.


## Region/effect lifecycle stress

Native tools/soak_region_lifecycle.gd completed three warmup and 30 measured cycles in 51.82 seconds on M5 Max. All 120 measured effect instances completed pause/travel/expiry checks. Every settled sample retained 15,568 nodes, zero orphans and 106 resources. Godot static memory moved from 365.04 to 365.41 MiB. No script errors. Output validated in build/region-lifecycle.json; methodology and limits in PERFORMANCE.md. No game-state fix was needed. This is a short lifecycle stress check, not long-duration or save-file validation.


## Repeated save/load stress

294 checks passed: save_cycle_stress 221 and session_save 73. Twenty-four cycles exercise 48 disk writes/reloads, upgraded/favorited equipped gear, exact inventory growth, materials, resources, area restoration, reconstructed harvested creatures and duplicate-harvest rejection. Successful save replacements leave no .tmp file. All final logs have zero failures/script errors; dedicated fixture files removed. No gameplay fix or release was needed. Full application restarts and interrupted-write recovery are separate remaining coverage; see SAVE_RESUME.md.


## Native restart and pre-replacement interruption

Extended session_boot.gd passed across two native Mobile/Metal processes on M5 Max with a copied project configuration and the separate SkyrimCraft-Session-QA profile. Final markers: SESSION_BOOT_SAVED_WITH_ABANDONED_TMP and SESSION_BOOT_RESTORED_AND_TMP_REPLACED. Verified actual automatic startup restoration in Wyrmkeep, resources/camera, upgraded favorite equipment, inventory/material/gold state and a defeated/harvested creature. An intentionally truncated .tmp file left beside the valid primary did not prevent loading; the next save replaced it.

Initial fixture issues were focus-triggered pause during setup and JSON integer/float dictionary comparisons. Explicit setup unpause and serialization-normalized comparisons resolved them; final logs have no script errors. No game-save implementation change was needed. This is controlled interruption before rename, not a power-loss durability test. Regular profile untouched; no release created.

## Connected campaign progression and resource audit

`tools/audit_campaign_route.gd`: 1,705 checks passed across three fresh builds and 45 chapter checkpoints, from Oldwatch to each build's chosen homecoming heirloom. No prerequisite completion flags are inserted. Normal chapter actions, real enemy damage/loot handling, required story crafting, finite merchant ingredients and per-chapter completion/equipment/supply save round trips are covered. Combat is an idealized direct-damage model with prescribed ranged misses, no incoming attacks and no walking time; it is not a timed human playthrough or survival benchmark. See `CAMPAIGN_PLAYTHROUGH.md` and `build/campaign-route-audit.md`.

`tests/ending.gd`: 58 checks passed, including the corrected 30-damage bow and 32-damage staff base values in finale offer text. `tests/smoke.gd`: 15 checks passed after input initialization became idempotent. Combined: 1,778 checks, zero failures; final logs contain no engine/script errors. The campaign audit also reinitializes inputs in each fresh world and verifies the attack binding count does not grow. Dedicated audit save removed on success; normal player save untouched. No release built.

## Mage projectile and cost-readability follow-up

`tests/mage_projectiles.gd`: 57 checks passed across all five spells with/without Kindled Mind and Clear Channel. Uses real player casts and projectile collisions against arranged stationary targets; verifies costs, cooldown/resource rejection, target damage/counts, perk refund HUD changes and regeneration. Not a live-AI survival test. `tests/render_spell_costs.gd -- --capture`: native M5 render passed; inspected both the Starfall/Conductor and Soulfire/rifle HUD at 1280 × 800. Final logs contain no engine/script errors. See `build/mage-projectile-report.md`. Normal saves untouched; no release built.

## Native active-AI Prismwing exchanges

`tools/playtest_prismwing.gd -- --capture`: all three scenarios passed on native M5 Max / Metal Mobile, with no engine/script errors. Baseline Emberbolt took nine casts (7.62 s attack window), perked Emberbolt eight (6.72 s), and perked Starfall four (4.62 s). Each included a real incoming hit before casting, over two metres of enemy movement, wing fracture observed while alive, and recorded 240 damage dealt. Starting health was 116; remaining health was 74.6 / 95.3 / 95.3. No mana stalls, potions, invulnerability or direct damage injection during fights. Automatic aim, stationary player, configured stage/loadout/perks and disabled adds mean these are controlled exchanges, not human difficulty or campaign-time claims. Exact timings and raw recorder data: `build/prismwing-live-playtest.json`; readable report generated by `tools/summarize_prismwing_playtest.py`. Normal saves untouched; no release built.

## Native Aeralis close-range and overlapping attacks

`tools/playtest_aeralis_pressure.gd -- --capture`: three scenarios passed on native M5 Max, with no engine/script errors. Both close cases earned live fracture from casts and observed a resolved bite: staying took exactly 32 damage; collision-aware sidestepping avoided it. Both finished in four casts. The deliberately grouped sentries/Prismwing case waited for each enemy to resolve an attack, observed three simultaneous warning animations and completed in six casts, taking 40.25 damage. These isolated automatic-aim policies retain real AI, physics, projectiles, incoming damage and regeneration; they do not measure human success rates. See `build/aeralis-pressure.md`. Normal saves untouched; no release created.

## Native Furnace Maw pressure and steering correction

`tools/playtest_furnace_pressure.gd -- --capture`: four scenarios passed on M5 Max. Authored standing rupture dealt 34 damage; continuous gunfire spent 29 rounds versus 21 when firing during exposure; Soulfire used four casts over two ruptures including an enraged warning. Three fight policies won without rupture damage. Warning origins remained committed. Separate JSONL logs preserve actual combat metrics; automatic aim/full-resource staging/disabled adds limit difficulty conclusions. See `build/furnace-live-pressure.md`.

Corrected scripted sidestep velocity carryover in both pressure harnesses. Re-ran `tools/playtest_aeralis_pressure.gd -- --capture`: all three cases passed; bite hit/dodge remained 32/0 damage, and all three enemies attacked in the grouped case. Seven final native scenarios passed with no engine/script errors. Normal player movement code and saves unchanged; no release created.


## Refined sword and shield construction — September 13, 2026

`tests/characters.gd`: 36 checks passed, including all weapon/offhand and ancestry builds. `tests/combat.gd`: 46 checks passed. Total: **82 checks, zero failures**; final logs contain no script/runtime errors. Character coverage was rerun after the last rear-panel geometry addition; combat passed before that geometry-only addition.

Native Godot 4.7.2 Metal/Mobile on M5 Max: `tests/render_refined_equipment.gd` completed a four-item gallery; `tests/render_refined_held.gd -- --capture` completed first/third-person views. Inspected all three captures and refined blade channels, two-sided enchanted marks, crystal shield stock selection, and rear shield timber. Final gallery counts: iron sword 126 cuboids/12 batches, Oldwatch Oath 144/14, iron shield 280/11, crystal shield 288/13. These are spatial/material rendering batches, not one draw per cuboid. No new frame-time benchmark or M1 validation.

Gallery is standalone; held views require isolated capture state and assert persistence is disabled. Normal player profile remains untouched. Outputs: `build/refined-equipment.png`, `build/refined-held-first.png`, `build/refined-held-third.png`. These verify the first equipment construction pass, not completion of the larger visual-detail milestone.


## Armor and shared hands — September 13, 2026

Final `tests/characters.gd` (36) and `tests/combat.gd` (46) runs passed: **82 checks, zero failures**, no errors in final logs. Native Godot 4.7.2 Metal/Mobile on M5 Max completed `tests/render_refined_armor.gd` and `tests/render_refined_held.gd -- --capture`. Inspected the steel/leather/cloth gallery and steel first/third-person views, narrowing lighter shoulders and restricting layered leg plates to heavy armor after the initial comparison. Existing slot, weapon mount and animation behavior remains in use.

The standalone gallery explicitly disables persistence; held capture asserts isolated character/atlas state. Normal saves were not changed. Outputs: `build/refined-armor.png`, regenerated `build/refined-held-first.png` and `build/refined-held-third.png`. These views do not establish clipping-free fit for every mixed armor/body combination, final named-set art quality or M1 performance. Those reviews remain on the visual roadmap.


## Refined Rimefang model — September 13, 2026

`tests/frost_beast.gd`: 22 checks; `tests/monster_corpses.gd`: 30; `tests/creature_executions.gd`: 27. **79 checks passed, zero failures**, no runtime/script errors in the logs. These ran after the articulated jaw defeat reset was added; subsequent changes only raised the label and separated overlapping jaw geometry.

Native Godot 4.7.2 Metal/Mobile on M5 Max completed `tests/render_frost_beast.gd -- --capture` and the standalone `tests/render_refined_rimefang.gd`. Inspected idle, warning, charge and three-quarter gallery images. Raised the warning label after finding silhouette occlusion; final gameplay warning reads clearly. Final gallery confirms separated mouth surfaces. Gameplay captures assert isolated character/atlas persistence; gallery does not load player state. Normal profile untouched. No M1 measurement or claim of full creature-art completion. Gallery: `build/refined-rimefang.png`; gameplay: `build/frost-beast.png`, `build/frost-beast-warning.png`, `build/frost-beast-charge.png`.


## Refined staffs, bows, rifles and focuses — September 13, 2026

`tests/characters.gd` 36, `tests/combat.gd` 46, `tests/mage_projectiles.gd` 57 and `tests/realms.gd` 38: **177 checks passed, zero failures**, no errors in final logs. These cover equipment builds, combat behavior, actual spell projectile collisions and destination equipment/progression. Firing origins and gameplay rules were not changed.

Native Godot 4.7.2 Metal/Mobile on M5 Max completed `tests/render_refined_ranged.gd` and `tests/render_refined_ranged_held.gd -- --capture`. Inspected gallery and all six first/third-person captures for Iron Longbow, Lantern Conductor and Ashstorm Machine Gun. Reticle remains clear in inspected first-person views; gallery spacing and bow angle were corrected to show construction without overlapping items. Gallery: `build/refined-ranged.png`; held views: `build/refined-{iron_bow,lantern_conductor,cinder_gun}-{first,third}.png`. Gallery does not load player state; held captures require isolated state and assert character/atlas persistence disabled. Normal profile untouched. No M1 benchmark or full named-weapon visual completion claim.


## Copper Stag outfitter dressing — September 13, 2026

`tests/shops.gd`: 34 checks passed; `tests/town.gd`: 20 passed. **54 checks, zero failures**, no errors in final logs. All three shop porch/door routes remain traversable; town walking routes and real purchase/proximity guards pass. Initial shop run failed because its post-traversal interaction reached a nearby quest before injecting a purchase selection into the previously opened shop. The purchase-specific fixture now explicitly opens the intended nearby shop; existing entrance tests still exercise E routing. Added a regression check and UI guard for unavailable buy selections.

Native Godot 4.7.2 Metal/Mobile on M5 Max completed `tests/render_refined_outfitter.gd -- --capture`. Inspected street and interior, moved the stag plaque forward for visibility and captured without held weapons obscuring the furniture. Captures assert isolated character/atlas persistence; equipment changes affect only capture state. Outputs: `build/refined-outfitter-street.png`, `build/refined-outfitter-interior.png`. Normal profile untouched. No M1/performance benchmark or full visual-roadmap completion claim.


## Combined visual review, equipment surfaces and fur — September 13, 2026

`tests/characters.gd`: **36 checks passed, zero failures** after shared surface textures and revised collar geometry. Native Godot 4.7.2 Metal/Mobile on M5 Max completed `tests/render_visual_review.gd -- --capture`, `tests/render_refined_armor.gd` and `tests/render_refined_held.gd -- --capture` without errors. Inspected combined world composition, cloth/leather/steel gallery and both held cameras. Moved the staged camera clear of the herbalist stall; discarded the obsolete initial framing capture. Final combined output: `build/visual-review.png`.

Combined fixture asserts isolated persistence and stages a review character/monster without changing authored spawn data; lighting is the normal world setup. Three deterministic surface textures are cached and reused; no additional animated effects or collision changes. Normal profile untouched. This is visual/character validation, not a performance benchmark, M1 measurement, combat rebalance or sign-off that the game now matches the concept.


## Refined east riverbank — September 13, 2026

`tests/town.gd`: 20 checks passed. New `tests/riverbank.gd`: 4 checks passed for crossing the bank, following its elevation, traversing the original bridge and retaining land footsteps. Initial bank checks caught reversed collision triangle winding; corrected to the existing terrain convention. Final movement crossed z -9 to 7.36 at x ~21, with sampled feet heights 0.064–0.575 m. Bridge traversal passed. Total **24 checks, zero final failures**. Subsequent changes were decorative grass/canopy geometry and removal of diagnostic logging.

Native Godot 4.7.2 Metal/Mobile on M5 Max completed `tests/render_refined_riverbank.gd -- --capture` without errors. Inspected overview and walking-height views; fixed exposed soil covering grass tops, added patchy low cover and adjusted canopy spacing. Outputs: `build/refined-riverbank-overview.png`, `build/refined-riverbank-walk.png`. Capture asserts isolated persistence; normal profile untouched. Static world total 361623 cuboids. No new timing benchmark, M1 validation or claim of full environment/art completion.


## Rimefang torso and limb anatomy — September 13, 2026

`tests/frost_beast.gd` 22, `tests/monster_corpses.gd` 30, `tests/creature_executions.gd` 27: **79 checks passed, zero failures** after torso/limb/crest changes. Subsequent change only softened and cached the hide texture. Native Godot 4.7.2 Metal/Mobile on M5 Max completed `tests/render_refined_rimefang.gd` and `tests/render_frost_beast.gd -- --capture` without errors. Inspected final gallery, warning and moving charge poses; warning remains unobstructed and legs follow existing pivots. Final outputs reuse `build/refined-rimefang.png` and frost-beast gameplay captures.

Gameplay fixtures use isolated state and assert persistence disabled; standalone gallery loads no profile. Normal saves untouched. No new collision/combat rules, M1 benchmark or claim of full creature-art completion.


## Scalloped shelf collision and river surface — September 13, 2026

`tests/riverbank.gd`: **8 checks passed, zero failures**. Retains bank crossing/elevation, original bridge and land-footstep checks; adds downward ray checks at three shelf locations for expected elevation (within 0.04 m) and upward normals, plus a central-channel ray confirming the riverbed remains below -1 m. No collision or test changes followed that run; subsequent work only refined the water shader.

Native Godot 4.7.2 Metal/Mobile on M5 Max completed `tests/render_refined_riverbank.gd -- --capture` without errors. Inspected both final views after softening the water pattern. Outputs reuse `build/refined-riverbank-overview.png` and `build/refined-riverbank-walk.png`. Capture asserts isolated character/atlas persistence; normal saves untouched. Static world 361977 cuboids. This is a local shoreline/rendering pass, not a full river rebuild or M1/performance sign-off.


## Connected landscape, equipment and native performance cleanup — September 13, 2026

Final targeted suites: riverbank 11, town 20, shops 34, characters 36, combat 46; **147 checks passed, zero failures**. Broader checks exposed an obstructed Iron Outcrop approach and overly steep western shelf normals. Flattened the existing gathering clearing and widened narrow shelf sections; reruns passed. Preserved old shore-rock RNG consumption when suppressing redundant geometry so forest placement remains stable. Character checks were repeated after removing obsolete weapon branches.

Native Godot 4.7.2 Metal/Mobile on M5 Max completed the impact-weapon gallery and six held views (`tests/render_refined_ranged_held.gd -- --capture --impact`); inspected axe, battleaxe and mace in both camera modes. Added constructed heads, bindings, fittings and gem/enchantment details. Smaller nearby world signs reduce scenery obstruction. Final landscape capture includes both shelves, fuller local canopy, coherent grass patches and the gathering clearing. Gallery `build/refined-impact-weapons.png`; river images reuse the existing refined-riverbank outputs.

`tools/benchmark_visual_polish.gd -- --capture` measured scripted river/village views and actual Rimefang AI, then repeated the same scenarios while retaining both sets. Each Rimefang pass observed one warning and one charge. At 1280×800, paired-run p95 first/repeat: river 26.62/26.69 ms, village 9.55/9.54 ms, Rimefang 18.98/17.96 ms. High-percentile spikes persist on repetition; performance is not signed off. Report: `build/visual-polish-performance.md`, paired raw JSON and retained original exploratory JSON. Static world 362926 cuboids. No M1 validation or claim of speedup against different older scenarios.

All native fixtures assert isolated persistence; ordinary player saves remain untouched. No release created. Full regional/asset rollout and performance closure remain open.


## Frame diagnostics / HUD cleanup

- Consolidated objective and vital text assignments in `scripts/hud.gd`, preserving quest precedence and spell/ammo lines.
- Headless `tests/campaign_guide.gd`: 21 checks, zero failures.
- Headless `tests/mage_projectiles.gd`: 57 checks, zero failures, including actual spell-cost HUD updates.
- Added `tools/benchmark_visual_timing.gd`: isolated native paired river/village/real Rimefang charge samples, per-frame traces, CPU/GPU counters and temporary shadow/VSync controls. Logs omit full traces; JSON retains them.
- Metal returned zero-only GPU counters; interpreted as unavailable. See `build/visual-polish-timing-report.md` for all experiment results and comparison limits. Rendering quality/settings and normal saves unchanged; no release generated. Stutter root cause and M1 performance remain open.


## Destination boss geometry polish — September 24, 2026

Refined Furnace Maw and Prismwing geometry while retaining combat roots, collision capsules, animation pivots, enemy IDs, progression and rewards. Small boss parts batch per material without world-grid splitting; other block callers retain existing behavior.

Final headless checks: furnace_beast 16, crystal_wyrm 14, monster_corpses 30, creature_executions 27, realms 38 — 125 checks, zero failures. Native arena renders inspected for the Maw inhale/exposed core and Prismwing fracture/bite, plus angled galleries for both. `tests/render_refined_realm_bosses.gd` records 383 cuboids/42 batches for the Maw and 437/40 for Prismwing. `tools/benchmark_realm_bosses.gd` measures real attack windups in isolated native realms. No saved campaign mutation or release packaging. See PERFORMANCE.md for timing limits; M1 and broader visual/performance sign-off remain open.


## Creature roster review checkpoint — September 24, 2026

**Roadmap item #1 implementation pass covered for the full current creature roster; stopped for user visual review.** This is not approval of the entire art milestone or a performance sign-off.

| Creature family | Construction and presentation delivered | Review status |
| --- | --- | --- |
| Frostfang Wolf | Shaped trunk/muzzle, shoulder ruff, paws/teeth, articulated bite, finisher recoil and side collapse | Ready |
| Bristleback Boar | Broad shoulders, bristle ridge, swept tusks, hooves, bite and collapse | Ready |
| Mossbound Colossus | Staggered stone slabs, moss seams, recessed eyes, articulated fists/slam arms, kneeling defeat | Ready |
| Hollow Warden | Bark ribs, layered moss, branched antlers, root feet, braced warning and root-limb collapse | Ready |
| Hull Warden | Domed barnacle shell, eye stalks, hooked pincers, opening core plates and folded defeat | Ready |
| Dissonant Cantor | Tapered resonant chest, fluted throat, ribbed wings, inhale expansion and folded-wing defeat | Ready |
| Meridian Keeper | Segmented golden carapace, pincers, articulated solar tail, warning alignment and collapsed tail | Ready |
| Hullcarver | Layered alien carapace, recessed eye clusters, serrated mandibles, core covers; existing spit/finisher/collapse retained | Ready |
| Shadowless Stag | Shaped pale body, visible ribs, tapered neck/legs, branched antlers; shadowless noncombat quest behavior retained | Ready |
| Rimefang | Existing refined anatomy plus finisher reaction, animated defeat and corrected saved corpse reconstruction | Ready |
| Prismwing | Prior refined model reviewed with warning, finisher and defeated poses; fracture behavior retained | Ready |
| Furnace Maw | Prior refined model reviewed with warning, finisher and defeated poses; heat shutters retained | Ready |

Review: `build/creature-review/index.html` — 12 creatures, 45 model-pose captures, nine gameplay captures, click-to-enlarge and pose selection. Native M5 contact sheets cover idle/warning/finisher/defeated and arenas. Geometry changes are applied to runtime family builders, so all current instances use them, not just the review gallery. Existing attack hit areas, damage, progression IDs and rewards are retained.

Validation: 358 checks across 15 suites, including 64 new presentation checks for eight families covering model-only reactions, locked-pose persistence, cancellation, animated death, pause, corpse stability and saved corpse reconstruction. Fixed Rimefang reconstruction after its final rig is built, and prevented Hull Warden's shell update from disturbing its corpse. Model render fixtures and eight actual gameplay scene fixtures completed without errors. No player save changes or release packaging.

User requested a stop after #1. Further art adjustments await this review. Other roadmap work (equipment identities, people, environments, destination expansion, campaign tuning and performance/M1 verification) remains open. Performance gains are not claimed by this pass; full dismemberment is not implemented.


## Equipment / character review #2 — September 24, 2026

- `tests/equipment_fit.gd`: **480 checks, zero failures**. Builds 240 full-set ancestry/frame combinations, verifies finite nonzero transforms, limb attachment, unchanged stats/inventory, clear eye centers for 216 open-helmet combinations, and 24 mixed outfits. Geometry probes cover specific invariants, not exhaustive animated surface collision.
- Regression suites: characters **36**, combat **46**, crafting **201**, loadouts **17**, mage projectiles **57**. **837 total checks, zero failures**. Logs inspected for script errors as well as result markers.
- `tests/render_equipment_review.gd`: **238** native Metal studio images. `tests/render_equipment_held_review.gd -- --capture`: **134** native gameplay images, all 67 main/off-hand items in both cameras with cycling ancestry/frame/armor selections. Isolated state asserts persistence disabled. Normal save untouched.
- `tools/build_equipment_review.py` produces the offline, searchable review gallery and validates all 372 image paths. Studio views are unupgraded catalog geometry; held captures use quality-two/vigor instances to show existing upgrade effects.
- Gallery: `build/equipment-review/index.html`; machine-readable result: `build/equipment-review/validation.json`. All captures use 960×600 JPG to limit disk use.
- Hardware: M5 Max. No fresh performance benchmark, M1 test, or packaged release. User visual review remains pending.

## Building review #3 — September 24, 2026

- **883 checks, zero failures, 17 suites:** building access 102; shops 34; town 20; Pinehall detail 23; Wyrmkeep detail 36; Saltbreak detail 21; mountain 74; archive 52; shore 65; lens 55; roots 85; choir 70; convergence 74; threshold 68; winter 55; realms 38; riverbank 11. Final logs inspected for script errors and failure markers.
- New `tests/building_access.gd` physically walks in/out of all 25 buildings, verifies supported saved entry aisles and actual floor ray hits, and rejects duplicate building names/IDs. Existing suites cover shop interaction, regional lane/service access and chapter progression.
- `tests/render_building_review.gd -- --capture`: 114 native Metal captures at 1280×800. Floors hidden by plinths, daylight gaps in roofs, small-room hearth/table overlap, and obstructed review angles were corrected during inspection. Representative exterior/interior/detail/landmark views inspected.
- `tools/build_building_review.py`: all image paths and unique image IDs validated, 39 gallery cards. Gallery JavaScript syntax checked with Node. Interactive browser verification could not run because the browser URL policy blocks local file pages; no workaround attempted. The offline artifact remains directly available for user review.
- `tools/benchmark_buildings.gd -- --capture`: one fixed-view M5 Max / Metal Mobile run, 2 s warmup and 5 s sample per view. p95: Frostmere street **8.399 ms**, Copper Stag interior **8.396 ms**, Wyrmkeep halls **8.341 ms**, Pinehall houses **8.331 ms**. Full viewport/VSync/draw-count/memory metadata is in `build/building-review/performance.json`. Not a comparative speedup, combat test or M1 sign-off.
- Replaced the old repeated house builders while preserving building/door locations and service positions. Normal character and atlas saves remained untouched; all capture/benchmark fixtures assert persistence disabled. No packaged release.

## Regional towns and landscape polish — September 24, 2026

**1,014 checks passed across 21 suites**, zero failures/errors/warnings in the final regression logs. Counts are preserved in `build/landscape-review/validation.json`: regional scenery 75, town 20, shops 34, building access 102, terrain 11, riverbank 11, mountain 74, Wyrmkeep detail 36, archive 52, Pinehall detail 23, Pinehall terrain 19, shore 65, Saltbreak detail 21, lens 55, roots 85, choir 70, convergence 74, threshold 68, winter 55, winter ground 26, realms 38.

The new scenery fixture probes physical walking lanes and quest/service positions for new collision, exercises repeated entry/exit with exact Environment restoration, and checks that inactive realm roots are hidden. All 25 building entrances remain traversable. An actual Pinehall climb failed against a new rock; new solid props are now excluded from those hill shoulders and the climb/save test passes. The older home-terrain root check incorrectly assumed every tree used Terrain.height_at; it now ray-probes actual ground collision, including the already-existing refined riverbank's distinct profile.

Native Metal captures cover 26 matching before/after views across 12 regions (52 JPEGs), reviewed at gameplay-height cameras. A camera intersecting the riverside shop was removed from review. Final capture logs have no errors or warnings. Gallery assets and JavaScript syntax were validated offline; browser interaction was not automated. Isolated headless fixtures and `--capture` native runs assert nonpersistent character/atlas state. No release generated.

## Presentation pass — September 24, 2026

259 checks across nine suites passed, with final opening/presentation reruns after the last geometry edits. Counts are in `build/presentation-review/validation.json`. Intro preview startup/isolation/handoff also passed. Native review: 18 views, existing nine scores and 32 effects, plus a 13.42-second native opening mix (non-silent, no clipping). All 41 source WAVs passed the PCM/non-silence/clipping audit. Gallery assets and JS syntax checked offline; browser interaction not automated.

The native lifecycle stress run completed 120 measured cycles plus three warmups in 198.707 seconds, rebuilding the opening and traveling through Pinehall, Wyrmkeep, Crucible, Aeralis and home each cycle. It exercised effect pause, travel cancellation and expiry. Settled counts stayed at 17,976 nodes, zero orphans and 137 resources; Godot static allocator usage rose from 420.969 to 421.500 MiB (about 0.53 MiB, including retained report samples). This is allocator usage, not RSS/VRAM, and a short lifecycle test rather than hours-long active play. Native review captures/audio ran concurrently during part of this lifecycle run; its elapsed time is not a performance benchmark. See [lifecycle results](../build/presentation-review/lifecycle.json).

M5 moving-view and four actual-player-camera realm group-combat samples completed; see [PRESENTATION_REVIEW.md](PRESENTATION_REVIEW.md) for methodology and remaining first-pass spike. M1, extended human play and subjective audio approval remain open. Isolated saves; no release.
