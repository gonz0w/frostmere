> Historical development record. Live work moved to [GitHub Issues](https://github.com/gonz0w/frostmere/issues) on November 1, 2026. Earlier counts, priorities, unchecked lists and build links below are retained as dated evidence, not current assignments. See [project policy](../PROJECT.md).

# Campaign playthrough and balance pass

## Connected automated route

Run from the project root:

```sh
.tools/Godot.app/Contents/MacOS/Godot --headless --path . --script tools/audit_campaign_route.gd
python3 tools/summarize_campaign_route.py
```

Read `build/campaign-route-audit.md` for the results and all assumptions; `build/campaign-route-audit.json` retains the per-chapter ledger. The engine audit refuses a non-headless launch or persistent character/atlas. It writes only its dedicated `user://campaign-route-audit.json` checkpoint and removes it on success. It does not update the normal character save. Failed runs exit nonzero and must not be treated as a new report; the summarizer reads the last successful JSON, whose UTC timestamp identifies that run.

Three separate fresh characters carry inventory and quest progress through Oldwatch, Stonewake, Wyrmkeep, Pinehall, Roots, Saltbreak, Sunken Lens, Choir, Mirewatch, the station, Aeralis, Winter Siege, Broken Seal, Crucible and homecoming. Choices are council accord, Lantern atlas recipient, wild grove and navigation core. These are one set of compatible choices, not coverage of every branch combination or all 51 quests. Prerequisites and completion records are earned through chapter actions rather than fixture-inserted flags. Required regulator/ward crafting and the chosen finale reward are included. Each chapter save is loaded into a separate state to validate completion, equipment and supply persistence; the active route retains its existing character.

Combat is a numerical demand model using real character stats, enemy damage rules, skill training and loot. It directly applies damage and freezes enemy AI. It does **not** exercise the player's attack/cast input, projectile accuracy, navigation, incoming damage, healing, death, guarding or finishers. Ranged misses are prescribed, not measured. Closed boss defenses give a conservative ammunition demand relative to exploiting their openings, but the lack of retaliation makes this unsuitable for survival estimates. Unspent perks/attributes and Emberbolt-only magic are deliberately modest baselines. No numeric combat balance change is justified from these results alone.

The ranger's replenishment requirement begins in Roots, before the later expedition reserve kits. Finite merchant ingredients cover the audited route for 289 gold. The mage's regeneration waits flag a useful live test, but overstate waiting when walking between encounters and omit stronger spells and Clear Channel. The warrior's absence of modeled stamina waits omits sprinting and blocking. See the generated report for totals.

Two code corrections arose during this pass: finale reward buttons now derive base damage and attribute bonuses from item definitions, and repeated world initialization no longer registers duplicate input actions/events.

## Hands-on runs still required

Use the opt-in recorder described in `COMBAT_PLAYTESTS.md`. Keep one log and manual route sheet per build. Start a fresh QA character; do not overwrite an existing playthrough. A timed human campaign run has **not** been completed by this audit.

| Run | Spend earned progression normally | Highest-priority observations |
| --- | --- | --- |
| Warrior | Weapon upgrades, Heavy Hand/Measured Swing, shield or two-handed choice | Guard/sprint stamina, multi-enemy pressure, ability to reach large-monster openings |
| Ranger | Bow upgrades, Steady Aim/Quick Release, finite shop/forge resupply | First arrow shortage, actual misses, whether home resupply interrupts Roots/Choir, boss exposure savings |
| Mage | Staff upgrades, Kindled Mind/Clear Channel, learned spells | Waiting after travel regeneration, practical chain/pierce/fan hits, potion use, late-realm spell choice |

At every chapter boundary, note wall-clock start/end, exploration/dialogue time, equipment and perks, arrows/potions entering/leaving, shopping/crafting detours, deaths and the reason for any retreat. Record which caches and optional quests were taken. After each major guardian, note whether its warning and opening were understood before dying, and whether a stronger spell/weapon or upgraded item felt useful. Compare full related combat segments; a `disengaged` recorder row does not mean victory.

Prioritize the station → Aeralis → Winter Siege → Broken Seal → Crucible chain for real boss pressure. Then walk the early ranger resupply route and compare the same mage encounters before/after Clear Channel. Use these observations to decide whether to adjust supply placement, monster pressure or recovery rates. M1 performance and hours-long native sessions remain separate validation work. No release package is part of this pass.

## Live projectile follow-up

`tests/mage_projectiles.gd` adds 57 checks using actual casts and physics projectile collisions for all five spells, without and with Kindled Mind/Clear Channel. The isolated fixture uses stationary arranged targets and a configured mage loadout/level; it is not a live-AI battle or a campaign-earned character. Exact costs, cooldown rejection, insufficient-resource preservation, hit counts, chain/pierce attenuation, perk refund HUD changes and real player regeneration are checked. See `build/mage-projectile-report.md` for ten measured cast cases. All three Starfall bolts land on the aligned target; the multi-target spells and perk improvements omitted by the conservative campaign model work as intended. Do not infer human accuracy or survival from this geometry.

The HUD now shows the selected spell's actual current magicka cost and the Conductor's discounted Chain Lightning cost, updating after perk changes. Rifle ammunition gets its own line to preserve room for the longer spell hint. Native M5 captures at 1280 × 800 were inspected. No mana or damage balance changed; live-AI pressure, moving-target accuracy and timed human campaign review remain open.

## Active Prismwing mage exchange

`tools/playtest_prismwing.gd` advances beyond stationary targets: Prismwing's authored movement, fan projectiles, health, cooldowns and wing fracture run alongside real player physics, casts, regeneration and incoming damage. It compares baseline Emberbolt, perked Emberbolt and perked Starfall. Each isolated stage fixture starts at full resources with the same Horizon Staff/cloth kit; the other realm enemies are disabled. The player stands still, aims automatically and begins casting only after a real hostile hit. No healing, invulnerability or direct damage injection occurs during combat. Native launches require `-- --capture`; persistent character/atlas state is rejected.

The run validates AI movement, actual retaliation, wing fracture while alive, bounded defeat and bidirectional combat metrics. Separate logs and `build/prismwing-live-playtest.json` retain the evidence. Run `python3 tools/summarize_prismwing_playtest.py` after a successful engine run to regenerate the readable report. Native M5 results show these three single-boss exchanges can finish without mana stalls; the earlier cumulative no-travel-regeneration model does not justify a general mana buff. This is a deterministic stand-and-cast comparison, not human aim, multi-enemy survival, close-range bite pressure or a full campaign playthrough. No combat stats changed.

## Aeralis close-range and overlapping-enemy pressure

`tools/playtest_aeralis_pressure.gd` adds two real-AI bite cases and a deliberately grouped encounter with both sentries beside Prismwing. The close cases earn fracture through actual Starfall casts, stop attacking to allow a bite, then either stand still or steer sideways with collision-aware movement. The group waits for all three enemies to resolve an attack before auto-aiming at the nearest survivor. No healing, direct damage injection, invulnerability or enemy-health inflation occurs during combat. These are configured stage fixtures with a perked Horizon Staff mage and full starting resources, not human reaction/accuracy measurements or a normal campaign approach.

All three native M5 cases passed. Staying in the bite took 32 damage; a roughly 3.6-metre sidestep avoided it. The group produced three simultaneous warnings and damaged all three enemies; the scripted mage finished with 75.75 of 116 HP after taking 40.25 damage. See `build/aeralis-pressure.md` and the dedicated JSONL records for exact policies/results. `python3 tools/summarize_aeralis_pressure.py` regenerates the report after the engine harness. No combat or AI balance change was justified. Human misses, reaction delay, depleted-resource approaches, other-world monster pressure and timed campaign pacing remain open.

## Furnace Maw active pressure and ammunition tradeoff

`tools/playtest_furnace_pressure.gd` covers a standing rupture probe, continuous gunfire with dodges, exposure-only gunfire with dodges, and exposure-only Soulfire with dodges. The Maw retains authored health, AI, rupture timing and shutter multipliers. Shots, casts, ammunition, projectile flight and incoming damage use their real runtime paths. Fixtures stage the chapter/gear/perks and disable adds; aim and reaction are scripted.

Four native M5 cases passed. Standing took 34 damage. Continuous gunfire used 29 rounds in 3.80 physics seconds; firing only while the core was open used 21 rounds in 10.02 seconds. Thus waiting saved eight rounds but prolonged this scripted fight; it is not universally the better choice. Late shots can arrive after the shutters close. Soulfire completed in four casts across two eruptions, including an enraged warning. All fighting policies avoided rupture damage, and committed warning origins stayed fixed. See `build/furnace-live-pressure.md` and its raw logs. No combat stats changed.

The dodge harness now clears its scripted velocity immediately after move_and_slide, preventing the ordinary player tick from adding another movement step through deceleration. This is a test-steering correction, not a player movement change. The three Aeralis pressure scenarios were rerun natively with that correction and all passed, including the approximately 3.6-metre bite dodge. Human reaction/aim, depleted resources and multi-enemy Hell encounters remain open.
