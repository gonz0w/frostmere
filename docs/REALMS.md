# Later realm chapters

> Verification counts and capture observations below are historical development evidence, not fresh checks. `build/` paths refer to local output omitted from the source checkout; see [evidence guidance](README.md#screenshots-and-development-evidence).

Two original destination slices now run in the same native Mac game. Nordic Frostmere remains the main setting. These are arrival routes with two sentries, a guardian, realm crafting, loot and a return gate—not completed giant chapters. Stonewake now introduces the network in normal play; the campaign prerequisites are connected, while additional realm NPC dialogue and optional quests still need authoring. The First Threshold expedition is now playable and opens Aeralis in normal progression.

## Timeline

Space expedition (`threshold`) → **Aeralis / The Returning Light** (`returning_light`, Act IV) → home-world **Winter Siege** → **Broken Seal** → **The Crucible / The Last Furnace** (`last_furnace`, Act VI).

The space expedition reveals that the watchstones are losing light. Aeralis holds the Dawn Prism, guarded by the Prismwing, the Fractured Wyrm; bringing it home stabilizes the network. Much later, the siege and broken ward reveal an invasion engine in the Crucible. Recover the Furnace Maw's heart to shut it down. The realm slices implement guardian defeat, relic loot and completion on return. The Crucible additionally requires an explicit engine shutdown, then opens a homecoming chronicle and heirloom reward. The connected Northwatch siege and Caldera Underworks chapters now provide the home-world bridge between them.

Normal gates near the Watcher's Stones enforce those prerequisites. Aeralis requires `threshold`; the Crucible requires `returning_light`, `winter_siege` and `broken_seal`. Aeralis is now reached after completing the station expedition and returning home. Winter Siege and Broken Seal are now playable. Completing them opens the Crucible through the underworks crossing or the home-world gate; its isolated preview remains available. Revisit gates preserve defeated enemies and claimed loot.

## Realm identities and rewards

| | Aeralis · The Shattered Sky | The Crucible · Iron Below |
|---|---|---|
| Setting | Floating terraces, ivory pavilions, crystal spires, distant islands, moored airship scenery | Lava below iron bridges, furnace walls, pipes and smokestacks |
| Armor | Five Aetherguard pieces; crown and crystal shoulders, Intellect bonuses | Five Cinderplate pieces; visor, vents and heavy shoulders, Endurance bonuses |
| Weapons | Dawnweave Saber, Skybreaker greatsword, Starweaver Rod | Furnace Reaver axe, Ashstorm Machine Gun |
| Spell | Starfall: three converging crystal bolts, 28 magicka, 1.4-second cooldown | Soulfire Lance: one stronger bolt, 32 magicka, 1.6-second cooldown |
| Materials | Aether Shards, Star Alloy | Soul Embers, Cinder Alloy, Infernal Rounds |
| Formula | Aether Attunement: +3 Intellect / +1 Agility | Infernal Resolve: +3 Endurance / +1 Strength |
| Guardian | Prismwing, the Fractured Wyrm | Furnace Maw |

All 15 added equipment designs use owned instances, tempering, enchanting, gems, favorites, salvage and merchant trading. High-rank tempering consumes the realm's rare material. Attunement grants the realm blueprint family, formula, spell, enchanted weapon and initial materials once. Guardians and sentries provide finite additional loot; farming/replenishing realm resources is not implemented yet. Guardian weapons arrive Superior and favorited. See [the current content reference](CONTENT_REFERENCE.md) for catalog totals and quest availability.

The machine gun fires while LMB is held, one shot every 0.12 seconds, consuming one Infernal Round per shot. Damage uses the normal equipped-weapon stats. The learned forge recipe turns one Cinder Alloy and two Charcoal into 40 rounds, including at home forges. Guns, spells, armor and upgrades remain usable after returning to Frostmere. Preview profiles retain them only until the preview closes.

## Playing the previews

Double-click **Preview Aeralis.command** or **Preview Crucible.command** in the project folder. They start a fresh temporary profile with equipped realm armor, a weapon, learned magic and supplies. Both character and atlas saving are disabled, including after returning home. **Play Frostmere.command** still loads the regular profile.

- WASD/mouse to move/look; V switches camera.
- LMB attacks; hold it for automatic gunfire.
- Q casts the selected spell; B cycles learned spells; F uses a healing draught.
- E uses the attunement crystal, forge, separate enchantment altar, defeated-enemy loot and return gate.
- I manages gear/materials; C opens character equipment; M opens the realm route map.
- Defeat the guardian and collect its remains with E. In the Crucible, defeat both sentries and use the shutdown console before returning. The homecoming chronicle offers an heirloom and all three Dawnforged recipes.
- Falling costs health and returns you to the arrival terrace. Death or R retreats to Frostmere.

Preview mode is explicit (`--crystal-preview` or `--hell-preview`), refuses persistent profiles, and remains visibly labeled. Production save schema stays version 2 with backward-compatible optional realm progress, story completion and spell fields. Invalid spell IDs and inconsistent realm loot are rejected before applying a save.

## Validation and limits

38 realm integration assertions cover story gating, isolated saves, bridge joins, station proximity, spells, held-trigger fire, ammo crafting, portable gear, guardian rewards, save migration, falling and death. Native Metal screenshots are in `build/aeralis-preview.png`, `build/aeralis-map.png`, `build/crucible-preview.png` and `build/crucible-first-person.png`.

The airship and distant islands are scenery. Sentries use guard, caster and ranged behaviors. Prismwing and Furnace Maw have dedicated monster attacks, phase changes and animated defeat poses described below. Large optional quest networks, firearm reload animations and repeatable realm-resource farming are not implemented. No M1 performance measurement has been made for these additions.

## Prismwing monster pass

Aeralis's guardian now uses a large grounded crystal-winged quadruped rig, rather than a humanoid knight. It retains the aeralis_regent persistent ID, 240 health, guardian loot and return requirement. Existing completed saves remain compatible.

The wyrm approaches to twelve metres, raises its wings for a 1.2-second warning and fires five 18-damage crystal projectiles in a fan toward the committed aim direction. Sidestepping during the warning can avoid the volley. At half health, four outer wing crystals disappear, briefly staggering it for 1.6 seconds; subsequent volleys narrow to three projectiles. These are health-driven phases, not separately targetable wing colliders. Encounter health resets restore the intact wing appearance; restored low health triggers the fractured phase. Wings animate but the creature does not fly.

Pausing, realm departure and finisher lock cancel pending volleys. Weak-health finishers, guardian defeat, relic claims, chapter return and saves retain their existing paths. The remaining sentries are humanoid; the Crucible uses Furnace Maw, described below.

## Furnace Maw monster pass

The Crucible guardian now uses a horned six-legged furnace-beast rig. The existing crucible_warden identity, 340 health, relic loot, shutdown requirement and ending rewards are preserved. Previously defeated guardians remain defeated.

Within thirteen metres and clear sight, it marks the player's current location with a burning 2.8-metre-radius circle. The location stays fixed during a 1.5-second warning. Remaining inside on impact takes 34 raw damage before normal player defenses; below half health that rises to 46 and the cooldown drops from six seconds to four. Leaving the ring avoids damage. Impact also checks height and line of sight. It can be guarded but not melee-parried. There is one damage application per rupture, with no lingering damage pool.

Menus, realm departure, finisher lock, stagger, retreat and death cancel pending attacks and hide the marker. The warning is transient and not saved. Weak-health finishers and existing campaign completion remain intact. Ruptures have cosmetic eruption effects; the guardian also has the refined shell, articulated warning and collapse presentation described below. Further encounter expansion is tracked in [issue #13](https://github.com/gonz0w/frostmere/issues/13).

## Monster impact presentation

Destination guardian finishers now use distinct materials: Hullcarver shell fragments with green emission, elongated blue/lilac Prismwing shards, and dark Furnace Maw fragments with ember emission. Existing red flesh and mossy stone effects remain for other enemies. Weapon-specific spread patterns and normal defeat/loot handling are preserved.

Furnace ruptures now spawn a brief 16-fragment eruption at impact. This has no collision or damage and lasts 0.65 seconds. Menus hide and freeze the eruption; travel out of the Crucible removes it. It is cosmetic transient state, not saved or a lingering hazard.

## Reward progression tuning

Skybreaker's base damage is 38 and Starweaver Rod's is 32. They now exceed the Crystal Greatsword and Crystal Staff respectively at equal quality in the runtime progression audit. Guardian loot still grants Superior Skybreaker with Aether Attunement and favorite protection. Realm access, recipes, resource rewards and monster stats are unchanged. Existing owned copies use the revised catalog stats automatically.

### Furnace Maw heat shutters

The Maw's mouth shutters reduce incoming damage by 40% while closed. After each resolved rupture, they open for 2.5 seconds and incoming damage gains a 35% bonus; both apply before the ordinary boss mitigation. Leave the burning circle, then strike the exposed core. The opening occurs even when the eruption misses. Existing health, rupture damage and loot are unchanged. Eligible finishers bypass shutter mitigation. Menus, realm travel, death and execution locks safely clear the warning and exposure.

### Prismwing's fractured-wing bite

After the half-health wing fracture, Prismwing can bite nearby players. Watch for the raised wings, head draw-back and BITE warning; sidestep or retreat before the committed strike. The warning lasts 0.9 seconds and the recovery lasts 2.4 seconds. Farther targets still draw the reduced three-bolt fan. The fracture itself retains its initial counterattack opening, and existing finisher/guardian loot behavior is preserved.


## Arrival reserves for existing builds

Aeralis attunement now adds 36 arrows and two Magicka Draughts; Crucible attunement adds 48 arrows and three draughts. The normal arrival-crystal interaction announces the exact reserve. Existing spells, equipment, materials and the Crucible’s 160 Infernal Rounds are unchanged. Supplies use the existing one-time attunement flags: duplicate interactions, revisits and reloads cannot refill them. Older saves that already claimed attunement do not receive a catch-up refill.

The runtime audit in tools/audit_realm_supplies.gd produces build/realm-supply-baseline.md for twelve realm/bow/quality combinations. A Superior Steel Longbow needs 16 ideal hits across Aeralis’s two sentries and guardian, and 18 hits against the Crucible’s enemies when exploiting the Maw’s exposure or 31 through closed shutters. The ordinary Iron Longbow leaves only two missed shots within the Crucible’s 48-arrow reserve if every boss hit lands against closed shutters. These are per-target rounded hit budgets with no criticals, training, enchantments or finishers, not human accuracy or timed fight results. Potion reserves restore up to 100 and 150 magicka respectively.

realm_supplies 30, realms 38 and staff_scaling 100 checks passed: 168 total. Coverage includes physical crystal interaction, exact additions, preserved Infernal Rounds, real bow firing, real potion use, used-inventory saves, revisits and old claimed-save compatibility. No save migration or release package. Winter Siege and Broken Seal resource pressure, plus timed campaign playtesting, remain next in the balance review.


## Furnace Maw rupture presentation

The Maw now inhales through expanding side bellows, opens a hinged toothed jaw and braces its six legs during the existing rupture warning. Impact briefly lowers and pitches the body for 0.4 seconds; the jaw stays open during the existing exposed-core interval, then returns to idle. The warning circle's location/radius, 1.5-second timing, 34/46 damage, cooldowns and 2.5-second exposure remain unchanged. Animation does not move collision or hit origins. Cancellation clears the pose; corpse handling preserves the normal fallen transform.

70 checks passed: furnace_beast 16, furnace_pressure 16 and realms 38. Coverage includes wind-up pose, no early damage/exposure, locked warning target, dodging, slam recovery, pause reset, later phases, finishers and one-time guardian rewards. Native Mac inhale, rupture and exposed-core views inspected in build/furnace-inhale.png and build/furnace-core-exposed.png. Further monster choreography and human pacing remain open.


## Prismwing volley and bite presentation

Prismwing now braces its body and spreads individual crystal feathers during its volley warning, then recoils on release. Its fractured-wing bite opens a hinged toothed jaw as the head draws back, followed by a forward snap. The committed aim, collision and hit origins remain unchanged, as do the 1.2-second volley warning, 0.9-second bite warning, 2.4-second bite recovery and five/three projectile counts. Pausing clears transient poses; corpse transforms remain intact.

70 checks passed: crystal_wyrm 14, prismwing_pressure 18 and realms 38. Native Mac fan-charge and fractured bite captures were inspected in build/prismwing-fan-charge.png and build/prismwing-bite.png. Further creature choreography, finishers and human pacing review remain open.


## Directional finisher breakup

Finisher fragments now follow the player's strike heading: sword sweeps spread across the swing, dagger thrusts scatter forward, and crushing strikes burst outward. Pieces tumble and fall instead of stopping at a fixed point. Prismwing's elongated shards scatter farther and spin faster; alternating Furnace Maw fragments rise higher like escaping embers. Existing surface palettes and 18-piece budgets remain intact.

The cosmetic effect uses the existing monster-effect lifecycle: menus hide and freeze it, resuming restores it, and leaving an area or switching realms removes it. It expires after 0.65 active seconds. Finisher eligibility, damage frames, camera orientation, corpse handling, loot and saves are unchanged. This advances impact presentation, not a new set of creature execution animations.


## Creature corpse silhouettes

Prismwing now rests low with a dropped head, slack jaw and uneven lowered wings. Its four outer feathers remain broken on defeat, including reconstructed saved corpses. Furnace Maw rests on splayed legs with compressed bellows and an open jaw; pending rupture effects are cleared. These are immediate final defeat poses shared by ordinary kills and finishers. New deaths animate into these poses as described in the following section; saved corpses start in their final pose. Existing collision removal, loot identity and defeat persistence are preserved.


## Animated creature collapse

New defeats now interpolate from the live creature pose into the settled corpse: Hullcarver takes 0.6 seconds, Prismwing 0.75 and Furnace Maw 0.85. The transition includes the body and articulated limbs/jaws, with smooth acceleration and settling. Ordinary kills and finishers share this cosmetic transition. Collision removal, defeat persistence and loot eligibility still occur immediately on the lethal hit.

Menus freeze the transition; leaving the area or changing realms settles it immediately. Loaded defeated creatures start in their final corpse pose without replaying the collapse. Animation state is transient, with no save fields. This completes the basic collapse transitions previously listed as open; bespoke execution sequences remain further presentation work.


## Creature finisher wind-up reactions

Destination guardians now react during the existing melee finisher wind-up. Hullcarver lowers its body and spreads its mandibles; Prismwing raises its wings and opens its jaw; Furnace Maw braces, opens its jaw and expands its bellows. Reaction strength follows progress toward the selected weapon's existing impact frame. The visual rig moves without relocating the actor or collision. Cancellation clears the reaction, while a lethal hit captures it as the starting pose for the existing collapse.

These reactions use the existing eligibility, range, barrier and damage checks. There are no new finisher rewards, invulnerability windows, camera movements or save fields. This connects creature reactions, weapon impact, fragment breakup and collapse; further bespoke choreography and human pacing evaluation remain open.
