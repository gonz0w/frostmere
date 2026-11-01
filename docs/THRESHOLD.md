# Beyond the First Threshold

The first space expedition is playable after **The Roads Converge**. Return to the Sunken Lens and use the glowing crossing beside the recovered star chart, inside its northern vault. The gate requires completed expedition preparation. It leads to an original orbital-station chapter; the planet outside the observation window is scenery.

## Station and return

Speak with **engineer Rook** in the southern airlock. The emergency locker holds a Fine Station Rifle, 120 Station Rounds, six Station Alloy and three Navigation Cells. It also teaches station equipment and ammunition recipes. Equip the rifle from the character/inventory interface. The airlock provides fabrication and enchantment benches.

Isolate the reactor circuit at the western control, then restart life support at the eastern control. The order is enforced without consumable repair costs. Restarting life support opens the physical command shutter and activates its security. Three rogue troopers occupy the maintenance area; two more troopers and the **Hullcarver Broodmother** guard the command deck. Cargo salvage provides additional ammunition and fabrication supplies.

Defeat the Broodmother, loot its blade and copy the command archive. The archive reveals that the home-world watchstones are losing their light and identifies Aeralis's Dawn Prism as the next remedy. **Use the southern return beacon with the archive to complete the expedition.** Merely copying the archive does not unlock the next realm. An early retreat preserves progress but does not award completion.

Returning awards 200 gold, a favorited Superior Station Carapace of Vigor, eight Station Alloy, six Navigation Cells and 100 Station Rounds. It records `threshold` and opens the **Aeralis crystal crossing in Frostmere**, near the Watcher's Stones. Enter normally, attune for realm magic and patterns, defeat the Fractured Regent, loot its remains, and use the return gate to complete **The Returning Light**. The Crucible still requires the later Winter Siege and Broken Seal chapters.

## Portable collection

| Equipment | Properties | Source |
| --- | --- | --- |
| Station Rifle | 9 base damage; automatic; one Station Round every 0.18 seconds; Agility scaling | Fine rifle in emergency locker; station forge pattern |
| Station Carapace | 22 heavy armor; +3 Endurance, +1 Agility | Superior armor of Vigor on successful return; station forge pattern |
| Void Cutter | 27 base damage; +3 Strength | Broodmother drops a favorited Superior blade of Fleet; station forge pattern |

Each equipment recipe costs four Station Alloy, two Navigation Cells and two steel ingots. Tempering uses steel and Station Alloy; Exquisite and higher also require Navigation Cells. Existing enchantments, gems, favorites and salvage work on owned copies.

**One steel ingot and one charcoal produce 40 Station Rounds** at any forge after learning the station patterns. The rifle remains usable at home and in other realms. It consumes Station Rounds only; the Crucible's Ashstorm Machine Gun continues to consume Infernal Rounds at its existing 0.12-second interval. Both use the existing automatic-fire and projectile systems. Station salvage is finite, but ordinary forging ingredients can supply more rifle ammunition.

## Presentation, saves and preview

The station has enclosed deck floors and ceilings, modular hull ribs, equipment racks, status strips, cargo cover, an observation window and voxel planet/star scenery. Its two original 32-bar chip-synth loops run at 88 BPM for exploration and 136 BPM for combat. They use the existing music crossfades and volume controls.

The optional `threshold` save record stores acceptance, locker/cargo claims, ordered system repairs, recovered archive, return reward, defeated enemies and claimed loot. Validation rejects contradictory repair order, command-deck defeat before opening, archive before boss defeat and completion without a return flag. Earlier saves receive untouched station progress. Departure and death restore the previous environment and safely return home; surviving enemies reset when leaving.

**Preview First Threshold.command** creates a temporary post-convergence character. Both character and atlas saving are disabled, including if you later visit Aeralis from that preview. Talk to Rook, collect the locker, and equip the rifle. E interacts, hold LMB for automatic fire, F heals, V changes camera, and M opens the station map.

The prototype now has **133 equipment designs, 149 recipes, eight music loops and seventeen sound effects**. Seventeen of 51 atlas quests are playable in normal progression; 34 remain outlines. The station and Aeralis are compact playable chapters, with further environment, narrative and encounter expansion still possible. No new M1 benchmark or timed human pacing study was performed.

## Monster guardian update

The command-deck guardian is now the Hullcarver Broodmother, an eight-legged armored alien occupying the existing threshold_5 boss slot. Its identity, 380 health, repair gates, Void Cutter reward and archive requirement remain compatible with saved progress. Existing defeated bosses remain defeated; this is not an extra spawn or reward claim.

The Broodmother approaches until within eleven metres, warns for 1.1 seconds, then fires a 26-damage hostile magic projectile. Its plates open for three seconds after firing. Armored hits apply a 0.65 multiplier before normal boss mitigation; exposed hits apply 1.5. The visible green core indicates this timed damage window; it is not a separate precision-hit collider. The attack cycle has a 4.5-second cooldown. Movement and leg animation use a new monster rig rather than humanoid arms and equipment.

Menus, chapter departure, protected story phases and finisher lock cancel the pending attack/core state. The existing weak-health finisher remains lethal through the shell, and defeat, loot, story progression and saves continue through the normal station controller. Space crew/troopers remain humanoid; other realm guardians are still awaiting their monster passes.


## Station supplies for existing builds

The station’s two caches previously supplied rifle ammunition but no arrows or magicka draughts. The emergency locker now adds 36 arrows and two magicka draughts; the cargo cache adds 24 arrows and one draught. Both remain one-time claims, and already-collected caches do not refill after an update. Existing rifle rewards, recipes, enemies and chapter gates are unchanged. Dialogue lists the new supplies.

A runtime equipment audit covers six bow/quality combinations against the five 100-HP troopers and 380-HP Hullcarver. A Superior Steel Longbow requires 30 ideal hits with exposed-core boss hits or 43 through the closed shell, leaving 17 misses within the 60-arrow cache budget in the latter case. An ordinary Iron Longbow uses all 60 if it never exploits exposure. These are conservative single-target hit budgets without criticals, training or finishers, not measured player accuracy or encounter duration. Three draughts restore up to 150 magicka. The reserve supports existing playstyles without requiring the rifle; players can still bring supplies, craft or return home.

Regenerate build/station-supply-baseline.md with --headless --path . --script tools/audit_station_supplies.gd. Threshold 68, staff scaling 100 and crafting 201 checks passed (369 total). New coverage verifies exact reserves, remote/duplicate rejection, live save reload and actual draught consumption. Native Mac engineer dialogue inspected. Human campaign-duration and resource-use testing remain open.


## Hullcarver attack presentation

The broodmother now opens articulated mandibles, lowers its body and braces its legs during the existing 1.1-second spit wind-up. A growing amber plasma cube at the mouth reinforces the warning label. Firing clears the charge and produces 0.35 seconds of body recoil while the existing green core opens. No damage, range, targeting, cooldown, armor multiplier, collision or three-second exposure values changed. Pause, travel, chapter gates and execution lock clear the pending pose; corpses hide the charge without overwriting the corpse transform.

133 checks passed: hullcarver 19, threshold 68 and combat 46. New checks verify growing charge, articulated jaws, bracing, no early exposure, recoil/settling and interruption cleanup. Native Mac charged/recoil/core views inspected in build/hullcarver-charge.png, build/hullcarver-recoil.png and build/hullcarver-core.png. Animation is procedural and intentionally cuboid; further creature choreography and human combat pacing remain open.


## Hullcarver corpse pose

The defeated Hullcarver rests low on folded legs with spread mandibles. Its charging effect is hidden and reset, and its plates close. This replaces the generic humanoid side-roll for both combat kills and finishers. Saved defeated guardians reconstruct the same pose without a save migration. Animated collapse transitions remain open.


Hullcarver collapse follow-up: new lethal hits now animate into the folded-leg corpse over 0.6 seconds. Menus freeze the motion and departure settles it. Saved corpses remain immediate, with the same defeat and loot rules.
