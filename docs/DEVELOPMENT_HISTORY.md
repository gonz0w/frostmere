# Historical development notes

Archived November 1, 2026 from the original README. Counts and future-work statements are historical, not current support or live assignments. Relative paths in this archived text were written from the repository root.

# SkyrimCraft — Frostmere

A native Mac, single-player Nordic RPG prototype with refined block-built visuals.

Current remaining work is tracked in [the scope roadmap](docs/SCOPE.md#current-remaining-roadmap), including the substantial [visual-detail pass](docs/VISUAL_DETAIL_ROADMAP.md) against the original approved concept.

## Run

Double-click **Play Frostmere.command** in this folder. The launcher uses the project-local Godot engine in `.tools/Godot.app`, or an installed `/Applications/Godot.app`.

To edit: open `project.godot` in Godot 4.7.2 or newer. No third-party packages or paid assets are required.

To try the new prelude without changing your character, double-click **Preview Dark Opening.command**. New characters start with it automatically; existing saves bypass it. Tab skips the opening.

## Shareable Mac playtest

`dist/Frostmere-0.1.0-macOS-AppleSilicon.zip` contains a standalone app, first-launch instructions and engine license notices. Apple Silicon / macOS 13+ target; native launch verified on M5 Max. Ad-hoc signed, not notarized. This 0.1.0 ZIP predates the new dark opening; the source project includes it. No Godot installation is required for recipients.

Rebuild on this Mac with `python3 tools/package_macos.py`. The script uses the matching official 4.7.2 templates cached under `.tools/export_templates/4.7.2.stable/`, exports a release app, verifies its signature, and creates the ZIP plus SHA-256 checksum. See `docs/MAC_PLAYTEST.txt` for recipient instructions. Native package QA uses `-- --capture --package-smoke` with persistence disabled.

## Controls

| Control | Action |
| --- | --- |
| WASD / mouse | Move / look |
| Shift | Sprint (uses regenerating stamina) |
| Space | Jump |
| V | Switch first / third person |
| E | Talk, shop, enter/leave barrow, loot, gather, or use nearby workstation |
| Left mouse | Melee attack / fire equipped bow or staff |
| Right mouse | Hold to block; raise just before a melee hit to parry |
| G | Spend full power on a slow-motion melee Whirlwind |
| Shift+G | Spend full power on a forward Sundering Strike |
| X | Finish a nearby weakened enemy with an equipped melee weapon |
| Q | Cast selected learned spell |
| B | Cycle learned spells |
| F | Use an owned healing draught |
| I | Inventory, crafting, upgrades, consumables and collection |
| C | Character, attributes, equipment, and live preview |
| K | Skills, XP and perk purchases |
| M | World/local map, faction outlines, quest journal, walking waypoints |
| Escape | Pause movement and release cursor; resume or quit |
| R | Return to starting point |
| H | Show / hide controls |
| F3 | Performance display |

## First playable milestone

Explore Frostmere, enter its houses, cross the stone bridge east of the village, and find the Watcher's Stones. Four landmarks have discovery messages. The player has a block-built armor model, a walk animation, and a collision-aware third-person camera.

The character and armory foundation includes eight ancestries, eight flexible starting playstyles, 145 equipment designs, nine slots, six attributes, and a saved character profile. An interactive world atlas, a local survey and the first main chapter, Stonewake, are also available. Owned inventory, 161 crafting recipes, tempering, enchanting, gem sockets, salvage, alchemy, cooking and gathering are now playable. Sword combat, blocking, bows, Emberbolt, three enemy roles, a boss, loot, Edda’s dungeon quest, and five staffed buy/sell shops are playable. Other faction memberships, 27 main/faction/side outlines, and further world simulation remain future work. Using the forge also advances the Oldwatch Survey. The distant fortress is scenery. The concept image is the visual target; these first procedural assets establish the scene and need further art refinement.

## Technical choices

- Godot 4.7.2, typed GDScript, native Apple Silicon.
- Godot's Mobile renderer with native Metal for efficient desktop 3D on Apple Silicon. Measure M1 performance before choosing final quality settings.
- Seeded procedural cuboid assets with pixel textures, batched by material and 24 m spatial region using MultiMesh. No individual scene node per environment cube.
- Static structure colliders, capsule player, spring-arm camera, keyboard/mouse input.
- An authored compact map; world streaming is future work.
- 60 FPS on M1 is a target, not a measured guarantee.

## Project layout

- `scenes/main.tscn` — entry scene.
- `data/shops.json` — five merchants, stock and base prices.
- `scripts/trade.gd` — gold, pricing, purchases, sales and persistent buyback.
- `scripts/shops.gd` — merchant characters and trading UI.
- `scripts/building_detail.gd` — layered architecture and furnishings.
- `scripts/adventure.gd` — Oldwatch dungeon, smith dialogue, quest and loot.
- `scripts/enemy.gd` — melee, archer, mage and boss behavior.
- `scripts/projectile.gd` — swept collision for arrows and spells.
- `docs/ADVENTURE.md` — controls, combat rules and quest walkthrough.
- `scripts/world.gd` — terrain, architecture, forest, river, landmarks.
- `scripts/blocks.gd` — materials and batched block geometry.
- `scripts/player.gd` — movement, cameras, animated avatar.
- `scripts/hud.gd` — HUD, pause menu, discovery and interaction notices.
- `data/crafting.json` — recipes, materials, enchantments, gems, workstations and gathering spots.
- `scripts/workshop.gd` — inventory and workstation interface.
- `docs/CRAFTING.md` — collection loop, controls, recipes and save migration.
- `data/characters.json` — editable ancestry, playstyle and item definitions.
- `scripts/character_state.gd` — attributes, derived stats, equipment rules and character saves.
- `scripts/character_visual.gd` — modular body, armor, ancestry and weapon visuals.
- `scripts/character_menu.gd` — character screen, equipment search and live preview.
- `docs/CHARACTERS.md` — character-system behavior, content and current limits.
- `data/world_atlas.json` — regional geography, settlements, factions, routes and quest outlines.
- `scripts/atlas_state.gd` — local discoveries, waypoints and survey progress/save.
- `scripts/atlas_canvas.gd` — interactive regional/local cartography.
- `scripts/world_map.gd` — map, faction dossiers and quest journal.
- `docs/WORLD_DESIGN.md` — proposed world structure and implementation boundaries.
- `tests/smoke.gd` — headless movement and scene checks.
- `docs/SCOPE.md` — agreed scope and subsequent milestones.
- `docs/reference/approved-concept.png` — the approved visual target.

## Verification

```sh
.tools/Godot.app/Contents/MacOS/Godot --headless --path . --editor --import --quit
.tools/Godot.app/Contents/MacOS/Godot --headless --path . --script tests/smoke.gd
.tools/Godot.app/Contents/MacOS/Godot --headless --path . --script tests/characters.gd
.tools/Godot.app/Contents/MacOS/Godot --headless --path . --script tests/character_ui.gd
.tools/Godot.app/Contents/MacOS/Godot --headless --path . --script tests/atlas.gd
.tools/Godot.app/Contents/MacOS/Godot --headless --path . --script tests/crafting.gd
.tools/Godot.app/Contents/MacOS/Godot --headless --path . --script tests/combat.gd
.tools/Godot.app/Contents/MacOS/Godot --headless --path . --script tests/shops.gd
.tools/Godot.app/Contents/MacOS/Godot --path . -- --capture
```

The capture command saves `build/frostmere-preview.png` and exits. The project-local engine is excluded from version control. Godot is distributed under the MIT license; its bundled license and third-party notices remain inside the app bundle. See https://godotengine.org/license/.

## Earlier movement/performance validation

All 15 headless scene, camera-mode, movement, jump, stamina, pause, bridge, doorway, wall, respawn, and discovery checks passed on September 8, 2026. A stationary rendered development-build sample on Apple M5 Max at 1280×800 with Mobile/Metal measured 8.33 ms median and p95 frame intervals (approximately 120 FPS, display-paced). This does not measure the M1 or worst-case gameplay. Run with `-- --benchmark` to produce a local `build/performance.txt` sample.

## Finer voxel art pass

Visible geometry spacing is halved without scaling down the world: terrain cells 2→1 m, roof courses 0.4→0.2 m, tree layers 0.65→0.325 m, mountain columns 3→1.5 m (vertical steps 1.5→0.75 m), and bridge courses 0.5→0.25 m. Close-set cobblestones, plank relief, small branch clusters, armor plates, fur tufts, and boot straps add real geometric detail. Materials use consistent world-space texture density and nearest filtering with mipmaps to preserve square pixels without distant shimmer. Collision volumes and movement remain unchanged.

Screenshots: `build/frostmere-before-detail.png` and `build/frostmere-preview.png`. These are actual game renders; the approved concept remains the visual target.

## Character and equipment milestone

Press **C** to open the character screen. Choose ancestry, starting playstyle and body frame, assign ten attribute points, select an equipment slot, and equip compatible owned items. Changing a playstyle preserves gear; the starter-gear button equips matching pieces already owned. A two-handed weapon clears and blocks the off hand.

The character profile saves automatically after edits and every 15 seconds, including the active area, position, resources and camera. Use Save adventure or Save and quit in the pause menu. Equipped armor and weapons appear in third person and the character preview; held equipment and gloves also appear in first person. Movement speed, stamina costs and resource limits use the derived attributes. Melee/bow damage, armor mitigation and Emberbolt use the derived stats. Presence now improves shop prices. Critical chance remains a foundation.

## World map and first survey quest

Press **M**. The World tab is a regional design atlas: eight biomes, sixteen places, seven planned factions and fifty-one quest entries. **Frostmere area** shows the current scene with its actual building/forest positions, player arrow and five local sites. Drag to pan, use the wheel/pinch or +/− to zoom, and click markers for details. Planned destinations have no travel action.

Choose **Begin Oldwatch Survey**, close the map, inspect the forge with **E**, cross Oldwatch bridge, and inspect the relic with **E**. The HUD guides each objective. Local visits, waypoint and survey progress save separately to `user://atlas-progress-v1.json`; automation and tests leave the real profile alone. An Ember Beneath Oldwatch is also playable through Edda. The remaining 27 quest entries are outlines; the Iron Pact clan initiation and first promotion are playable in Wyrmkeep.

## Collecting and improving gear

Start with the **Smith’s Welcome Cache**, beside the south trail near your spawn. Press **E** to collect materials, an enchanted dagger and steel/chain blueprints. Visit the village forge to smelt ore, forge a new piece, or select **Improve** to temper owned equipment. The Runewright’s Table is east of the north village path; it handles enchantments, learning formulas by consuming enchanted finds, and gem sockets. The Herbalist’s Bench and Hearthfire Cooking Pot make usable potions and food.

Press **I** to browse your bag anywhere. Use the category selector for Gear, Materials, Forge, Improve, Enchant, Salvage, Alchemy, Cooking, Consumables and Collection. Each copy keeps its own name, favorite status, quality, enchantment and gem. Favorites and equipped gear cannot be salvaged or studied. See [crafting details](docs/CRAFTING.md).

## First dungeon adventure

Speak to **Edda beside the village forge** with E and accept **An Ember Beneath Oldwatch**. She supplies a bow, arrows and potions. Cross Oldwatch bridge and find the barrow door southeast of the relic. Defeat its guards, archers and Ember Acolytes; explore behind pillars for hidden chests. The Watch-Captain guards a Superior enchanted **Oldwatch Oath** sword and the forge ember. Loot his remains, leave through the entrance, then return to Edda to learn the sword’s forging recipe.

**LMB** attacks with the equipped weapon; bows consume arrows. **RMB** holds a directional block. **Q** casts the selected spell (**B** cycles), **F** uses a healing draught, and **I** pauses to manage supplies. **M** shows an underground plan while in the barrow. Death returns you to the south trail with earned loot and defeated enemies preserved. See [adventure details](docs/ADVENTURE.md).

## Shops and building detail

Enter **The Copper Stag** (Torren, outfitter in the southwest house), **Juniper & Rune** (Mira, apothecary in the small riverside house), or **Ember Hall Stores** (Halvar, provisions in the northern longhouse). Press **E** at the counter. Buy supplies, sell spare gear/materials/consumables, or buy back your original sold equipment with its name and upgrades intact. Equipped/favorited pieces cannot be sold. Start with 150 gold; new barrow loot and the smith's reward also grant gold. Presence affects both buying and selling prices. Stock, merchant purses and buyback persist, with no automatic restock yet.

All four village buildings now have deeper timber framing, stone courses, carved gables, ridge caps, sheltered porches, shutters, planters, shop signs, floorboards, ceiling joists, shelves, rugs and hearths. The smallest doorway was raised to make its shop accessible. Fortress towers also have masonry courses, ledges and slit windows. These procedural details bring the buildings closer to the approved concept; the concept's full lighting and art fidelity remain a target.

See [shops and architecture](docs/SHOPS.md). `-- --shops` opens the game at Torren's counter.

## Aeralis and the Crucible

Try **Preview Aeralis.command** for the floating crystal realm or **Preview Crucible.command** for the much later industrial Hell realm. Both are playable temporary profiles; progress does not overwrite your regular game. Defeat the guardian, loot its relic and return to Frostmere. Q casts learned realm magic; B cycles spells. Hold LMB to fire the Crucible machine gun; forge more ammunition from Cinder Alloy and Charcoal.

These slices add 15 realm gear designs, two spells, two enchantments and a portable automatic weapon. Aeralis now opens after returning from the station expedition. The Crucible still requires the later siege and broken-seal chapters. The space expedition still precedes Aeralis; the Crucible comes after a home-world siege and broken seal. See [realm details](docs/REALMS.md).


## First main chapter: Stonewake

After returning Oldwatch's ember to Edda, speak with **Ilyra** beside the northern village house. Restore three ward stones by deciphering their inscriptions, awaken the central watchstone, then report back for an enchanted pendant and upgrade materials. **M** shows ward markers and the current objective. This introduces the later destination worlds while preserving their story gates.

Use **Preview Stonewake.command** to try the chapter immediately with a temporary post-Oldwatch profile. It does not change your regular save. See [Stonewake details](docs/STORY.md).


## Wyrmkeep and joinable clans

After Stonewake, use the **north pass beyond Ember Hall** to visit Wyrmkeep. Investigate the lost road supplies with Speaker Runa, hear both clans and clear the reaver outpost. Settle the council while independent, or subsequently join **Stoneguard** or **Stormweaver**. Each has an initiation, reputation, a first promotion and exclusive weapon/armor/off-hand crafting patterns. Two local merchants and crafting stations support the collection loop.

**Preview Wyrmkeep.command** opens an isolated post-Stonewake profile for immediate play. **E** interacts; **M** shows the town and clan progress. See [Wyrmkeep details](docs/WYRMKEEP.md).

## Pinehall and The Missing Atlas

After Stonewake, take the western trail from Frostmere. Meet Mereth and Aelin, explore the ruined archive, defeat the Bound Archivist, and choose who receives the recovered atlas. The choice grants either a chain-lightning staff and pattern or healing armor and its pattern. The guardian also carries Echoharvest, a stamina-restoring sword. See [the chapter guide](docs/ARCHIVE.md).

Double-click **Preview Pinehall.command** to try this chapter immediately with character and atlas saving disabled. Press E to talk or interact, M for its local map, and I to inspect or craft relics.

## Background music and sound

Eight original chiptune loops cover wandering, combat, Aeralis, the orbital station and the Crucible, with a separate battle arrangement for each realm. Seventeen effects cover weapons, spells, footsteps, loot, crafting and interactions. Music crossfades automatically. Press **Escape** for **Master / Music / Effects** volume controls. See [AUDIO.md](docs/AUDIO.md).

## The Wreck on the Black Shore

After The Missing Atlas, take the coastal road southwest of Frostmere to Saltbreak. Hear Keeper Sella and Neris, restore the sea-cave pump and wreck relay, recover the flight recorder and defeat the Hull Warden. The core can power Saltbreak or restore the ship's navigation; report to Sella for your exclusive equipment and pattern.

Recover three damaged relics, identify them with Neris, then restore them at the forge. Further tempering uses alloy and steel rather than another broken relic. Double-click **Preview Black Shore.command** for an isolated post-atlas preview with saving disabled. See [BLACK_SHORE.md](docs/BLACK_SHORE.md).

## The Sky Below the Sand

After The Missing Atlas, follow the eastern expedition road to the Sunken Lens. Align three mirror beams, restore the central lens, defeat the Meridian Keeper and return its star chart to Veyra. The chapter adds three solar gear designs and **Sunlance**, a learned spell that pierces one enemy to hit a second. Both Black Shore choices preserve this route.

Double-click **Preview Sunken Lens.command** for a preview that does not change your saved adventure. See [SUNKEN_LENS.md](docs/SUNKEN_LENS.md).

## Pacts Beneath the Roots

The Stag Shrine woodland chapter is playable after Stonewake via the western Amberweald trail. Restore three blighted roots, defeat the Hollow Warden, and choose between a wild grove or a tended woodland pact. Each choice changes the grove and unlocks different gear. Both recover the woodland account needed for the later space expedition.

Double-click **Preview Stag Shrine.command** for an isolated preview with normal saves disabled. Speak to Maelin or Oren in the lodges; E interacts and M opens the local map. See [the woodland chapter guide](docs/ROOTS.md).

## A Song Through the Stone

After resolving The Divided Council, take the southeastern ash pilgrimage to **Ember Caldera**. Ring the three resonators, repair the receiver, defeat the Dissonant Cantor and bring the first distress signal to Sereth. Three new equipment designs use Resonant Ore and Ash Glass for forging and upgrades.

**Preview Ember Caldera.command** opens an isolated post-council preview with character and atlas saves disabled. See [the Choir chapter guide](docs/CHOIR.md).

## The Roads Converge

The four branch investigations now meet at **Mirewatch**. Assemble their evidence, forge a Transit Regulator at the expedition forge, and install it to begin a combat calibration. A stable return beacon earns a Wayfarer Shield, Pathfinder Sabatons and their patterns. Earlier woodland and harbor choices are preserved; faction membership is not required.

**Preview Mirewatch.command** launches an isolated expedition-ready character. E interacts; M opens the camp map. See [the expedition guide](docs/CONVERGENCE.md). The First Threshold crossing is now playable from the Sunken Lens vault; returning from it unlocks normal Aeralis progression.

## Beyond the First Threshold

The space expedition is playable after **The Roads Converge**. Use the crossing beside the star chart in the northern Sunken Lens vault. Restore station power and life support, defeat rogue security and bring the command archive through the return beacon. This unlocks **Aeralis** through Frostmere's crystal crossing in normal progression.

The station adds a portable automatic rifle with its own craftable ammunition, two more equipment designs, fabrication supplies and dedicated exploration/battle music. **Preview First Threshold.command** starts an isolated expedition-ready character. Talk to Rook and collect the emergency locker. See [the station guide](docs/THRESHOLD.md).

## The Winter Siege

After returning from Aeralis, take the **Northwatch supply road south of Frostmere**. Defend the snowy caldera frontier fort with Captain Halla: repel scouts, repair the watchstone ward and ballista, then call the main assault. Recover the Iron Marshal's orders and report for the Northwatch Helm, Northwatch Greatsword and their crafting patterns.

**Preview Winter Siege.command** starts an isolated late-story character with saving disabled. **E** interacts, **M** opens the fort map. The Broken Seal follows this chapter and opens normal Crucible progression. See [the siege guide](docs/WINTER_SIEGE.md).

## The Broken Seal and Crucible descent

The late-game route is now connected. After Winter Siege, take the **caldera service lift south of Frostmere**. Investigate the underworks with Tovan, isolate the furnace pressure lines, recover a containment design, and forge a **Cinder Ward**. Defeat the Sealbreaker, bind the ward and report to open normal Crucible access. The reward includes a forgeable and upgradeable **Wardkeeper's Amulet**.

**Preview Broken Seal.command** opens an isolated late-story character. Talk to Tovan to begin. The northern crossing leads into the Crucible after completion; defeat its defenders, loot the warden, shut down the invasion engine and return home to finish The Last Furnace. See [the chapter guide](docs/BROKEN_SEAL.md).

## The Last Furnace: a light brought home

The Crucible now ends with an **invasion-engine shutdown** and a homecoming chronicle. Clear its defenders, recover the Warden's relic, use the shutdown console on the final terrace, then return home. Choose a Dawnforged sword, bow or staff, learn all three patterns, and continue exploring with your equipment and story choices intact.

**Preview Last Furnace.command** launches an isolated infernal character. Read [the ending guide](docs/ENDING.md) for the reward, upgrades and older-save behavior.

## Save and resume

Use **Play Frostmere.command** for your regular adventure. Reopening restores your active region, grounded location, camera, health, magicka, stamina and nearby surviving enemies alongside equipment and quest progress. The game autosaves every 15 seconds and when character progress changes. **Escape → Save adventure** saves immediately; **Save and quit** and closing the game window save before exiting.

Older saves remain compatible. Unsafe positions fall back to the area's entrance. Preview launchers remain temporary and cannot write the regular save. See [save/resume details](docs/SAVE_RESUME.md).

## Skills and perks

Press **K**, or choose **Skills & perks** in the character screen. Successful melee, ranged and spell hits train their skill; forging, tempering and enchanting train Crafting. Each level earns a shared perk point to spend on eight perks, including stronger attacks, cheaper spells, Fine-quality forged gear and reduced tempering costs.

Use **Refund** on a learned perk to recover its points for free and try another build. XP and existing equipment are preserved. Skills and learned perks save with your character. Older saves carry existing crafting XP into the new Crafting skill. See [the skill guide](docs/SKILLS.md).

## Timed parries

Raise a shield or melee guard just before a frontal melee hit to parry. A successful parry costs eight stamina, prevents damage and briefly staggers the attacker, giving you time to counterattack. Bosses recover faster. Holding block retains ordinary protection; exhausted guards break briefly. Arrows and spells remain blockable with normal damage reduction.

## Weapon critical hits

Agility now drives the critical chance shown in **C**. Melee weapons, bows and firearms can deal **50% extra damage**, with a **Critical!** combat message. Agility from equipment and enchantments contributes, up to 35% chance. Spells continue to scale through spell power.

## Equipment loadouts

Open **C** and use **Equipment loadouts** beneath the character preview. Choose one of four slots, enter a name and click **Save current**. **Equip set** swaps all nine equipment slots together, preserving the exact item copies and their upgrades. Save current replaces the selected set; Delete set removes only its saved configuration.

Missing or sold pieces are listed and block the swap, leaving your current gear intact. Recover the original pieces or equip replacements and save the set again. Sets persist with your character; older saves start with four empty slots. Loadouts store equipment only; skills and attributes are unchanged.

## Whirlwind power attack

Dealing damage and successfully parrying fills the new **Power** meter. At 100, equip a melee weapon and press **G** for a spinning, 360-degree strike with a brief slow-motion burst. It deals twice weapon damage within 3.6 metres, respects walls, and consumes the whole meter. The third-person body spins; first person uses a weapon sweep with a steady camera.

The initial tuning grants one power per four enemy health removed and 15 per parry. Whirlwind cannot charge itself. Its slow motion lasts 1.2 real seconds; menus and respawn end it safely. Power is temporary combat state and resets on death, return-to-trail and relaunch.

## Weapon-specific finishers

An enemy at **20% health or less**, within **2.5 metres** and in front of you, shows **X · Finish** with a melee weapon equipped. X selects your weapon family's move: **Fang Pierce** (dagger), **Sundering Sweep** (sword), **Titan Cleave** (greatsword), **Rending Chop** (axe), **Worldsplitter** (battleaxe) or **Bonebreaker** (mace).

Daggers thrust, swords sweep and axes/maces deliver overhead blows, with different windup and recovery timing in both camera modes. Stone colossi shed stone chips; flesh creatures retain red voxel fragments. These are weapon animation and impact-effect variants, without full dismemberment or bespoke monster execution sequences yet.

Targets are held during the move; other enemies remain dangerous. The camera stays under your control. Walls and protected phases block execution. Leaving range or opening a menu before impact cancels safely and restores the weapon pose. Impact uses normal defeat, skill and loot handling, and cannot stack with other attacks.

## Wilderness creatures

Frostmere's outer routes now have **six Frostfang wolves, five Bristleback boars, the Mossbound Colossus and Rimefang**. Look for wolf clearings west of the village and toward the northwest woods, boars on the eastern bank, and the 4.5-metre stone colossus near the north pass. Rimefang occupies a clearing south of the bridge on the eastern bank, bringing the roster to thirteen authored wilderness encounters.

Creatures defend a limited habitat and stop pursuing inside the village and bridge safe zones. Their amber nameplates warn of attacks. Parrying, critical hits, power attacks and weakened-enemy finishers use the existing combat rules. Press **E** at remains to harvest hide/meat, or forging materials from the colossus. Claims and defeats persist; session saves include surviving wilderness health and position.

This pass uses fixed encounters without automatic respawning or pack tactics. Broader populations across later regions, more species and richer creature animations remain future work.

## Raised wilderness routes

Three outer-route landforms now break up Frostmere's flat ground: a **3.2-metre western ridge**, a **2.8-metre eastern rise**, and a **2.4-metre northwest knoll**. Winding cobbled paths climb and descend their slopes without requiring jumps. The voxel surface retains stepped edges, with sloped collision beneath for smooth walking.

Trees, ground cover and creature spawn points follow the new elevations. The village, bridge, barrow entrance and existing gathering sites retain their approach heights. Session saves can resume on the raised ground; old positions that are no longer safe use the existing safe-location fallback. This is a first elevation pass, with larger valleys and additional vertical routes still available for expansion.

## Frostmere village layout

Frostmere now has **six enterable buildings**, including a western home and riverside cottage. The unused northern house sits farther west, and curved cobbled lanes connect the staggered buildings to the main street. A village green with a stone well, two produce stalls, benches, gardens and firewood stacks adds detail between the buildings.

The three village shops and main quest services retain their locations. Wildlife safe zones cover the expanded homes, and trees are cleared from the new door approaches and lanes. The stalls and well are scenery; this pass adds no new merchants. Other towns remain candidates for later layout passes.

## The Mossbound Oath

Read the **Hunters’ Board beside the market** with **E** to start an optional hunt. Harvest the three northwest wolves and the Mossbound Colossus, then return for **120 gold** and your choice of a **Fine Mossfang Blade** or **Fine Mossheart Amulet**. Both crafting patterns unlock, so you can forge the other design and improve either through the existing crafting systems. Earlier harvests count. See [the hunt guide](docs/HUNTS.md).

The Mossbound Colossus now warns with an amber ground-slam ring. Move outside it before impact; below half health, its Awakened phase hits harder and slams more frequently. This optional encounter retains the Mossbound Oath rewards and existing save progress. See [hunt details](docs/HUNTS.md).

## The Frostmaw Hunt

At the market Hunters’ Board, select **The Frostmaw Hunt**. Cross the bridge and head south along the eastern bank to meet **Rimefang, the Frostmaw**, a giant tusked quadruped with 540 health. Sidestep its committed charge and counterattack during recovery. Harvest with E, then return to the board for **180 gold**, a **Fine Rimefang Maul**, and forge patterns for the maul and **Frostmaw Cuirass**.

The maul and cuirass support normal tempering, enchanting and sockets. Earlier harvests count. Rimefang is a single authored encounter whose defeat and harvest persist; this does not introduce repeatable hunting or replace other realm bosses.

## Hullcarver Broodmother

The space station's command-deck boss is now a large eight-legged alien. Dodge its telegraphed plasma spit, then attack during the **three-second exposed-core window** for increased damage. The station repairs, command archive and Void Cutter reward retain their existing progression. Previously defeated guardians stay defeated in saved games.

## Prismwing, the Fractured Wyrm

Aeralis now has a large crystal-winged monster guardian. Sidestep its telegraphed fan of crystal shots. At half health its outer wing crystals fracture, briefly staggering it and narrowing future volleys. Existing guardian rewards, Dawn Prism progression and saved completion remain compatible.

## The Furnace Maw

The Crucible's guardian is now a massive horned, six-legged furnace beast. Leave its burning target circle before the ground rupture. Below half health, ruptures hit harder and come more often. The guardian relic, engine shutdown and ending rewards keep their existing progression and save compatibility.

Monster impacts now match their world: alien shell fragments, crystal shards and furnace embers. Furnace ruptures also produce a short eruption effect at impact, without adding damage or a lingering hazard.

## Clan Voice

After reaching **Shieldbearer**, return to your Stoneguard or Stormweaver sponsor in Wyrmkeep for **A Crown of Separate Holds**. Harvest the colossus and Rimefang (earlier harvests count), then choose shared patrols or a central war leader. Earn **Clan Voice** rank, **160 gold**, a **Superior Clan Voice Signet** and its forging pattern. Your mandate changes clan reputation and supply rewards and is recorded in the journal.

## Join the Veiled Lantern

After resolving **The Missing Atlas**, ask **Mereth in Pinehall** about **The Uncatalogued Door**. Study the archivist's testimony, solve the seal in the second chamber, then return to take the oath. Become a **Witness** and receive **100 gold**, a **Fine Witness Pendant** and its forge pattern. Your earlier atlas custody choice remains intact.

## Names Beneath the Water

Lantern Witnesses can now accept Mereth's Mirewatch investigation. Recover three erased records, stabilize the expedition beacon to access the northern testimony, then choose whether to **publish the names** or **preserve them under seal**. Earn **Recordkeeper rank**, **140 gold**, and a **Superior Memorial Ring or Sealed Memory Ring**, with only the chosen forge pattern unlocked.

## The Price of Knowing

After **Names Beneath the Water**, speak to Mereth to begin the Lantern's final review. Hear both her and Aelin, then choose the archive's future at the Uncatalogued Door: **sealed study**, **public copying** or **shared oversight**. Earn **Keeper rank**, **200 gold**, and a **Superior Lantern Keystone** with its forge pattern. Earlier testimony and atlas custody choices remain intact.

The **Hollow Warden** at the Stag Shrine is now a huge antlered root creature. Clear the three blighted roots to remove its protection, then leave the pale ground circle before its roots erupt. Its attacks intensify below half health. The existing woodland quest, Amberbough Bow and Coven progression keep their original rewards.

Saltbreak's **Hull Warden** is now a giant wreck-encrusted crab. Sidestep its three-shot brine volley, then strike during the open-shell recovery window. Its existing salvage and the ship-core quest progression remain intact.

The **Dissonant Cantor** in Ember Caldera is now a massive ash cicada. Watch its inhale, then jump over the expanding sonic ring or retreat beyond the marked boundary. The bell puzzle, archive gate and existing rewards are preserved.

The **Meridian Keeper** at the Sunken Lens is now a giant solar scorpion. Watch the marked beam path and step sideways before its tail fires. The mirror puzzle, named solar blade and star-chart quest keep their existing progression.

**Sundering Strike** adds a second charged melee move: press **Shift+G** with a full power meter for a five-meter forward cone, triple weapon damage and 1.5 seconds of stagger on surviving targets that take damage. **G** keeps Whirlwind for surrounding enemies. Both use the same meter and 1.2 seconds of slow motion; walls and protected boss gates remain respected.

Charged attacks now hit during their animations: Whirlwind at **0.30 seconds**, Sundering Strike at **0.48 seconds**. Keep enemies in reach through the windup. Opening a menu or otherwise canceling before impact stops the pending hit; spent power is not refunded.

Monster windups now have distinct sounds for root eruptions, brine volleys, sonic rings and solar beams. Whirlwind and Sundering Strike also have a heavier strike cue at impact. Their volume follows the existing Effects control.
