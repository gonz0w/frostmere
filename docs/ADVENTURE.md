# An Ember Beneath Oldwatch

A complete first dungeon quest in the Frostmere prototype. This is a compact authored adventure with simple combat, not a finished combat or AI system.

## Play

Talk to Edda by the forge (E). Accept the quest for an iron bow, 30 arrows, three healing draughts and two magicka draughts. Supplies are granted once. A player who explored the barrow before speaking to her can still accept and turn in the recovered ember.

Cross the bridge, follow the path to the Watcher’s Stones, then find the door southeast of the relic. E descends into Oldwatch Barrow. Its three connected chambers contain two guards, two archers, two Ember Acolytes and the Watch-Captain. There are two hidden supply chests behind the side pillars. M opens an underground floor plan; return south to leave.

Loot enemies with E after defeating them. The Captain’s remains hold Superior Oldwatch Oath of Vigor, upgrade materials and the quest’s forge ember. The sword is automatically favorited. Return to Edda and claim the Oldwatch/steel blueprint unlocks plus ingots, embers and rune dust. The forge can create another copy or improve the one you recovered.

## Controls and rules

| Control | Behavior |
| --- | --- |
| Left mouse | Melee swing, bow shot, or Emberbolt with a staff |
| Hold right mouse | Directional shield or melee-weapon block |
| Q | Emberbolt with any loadout |
| F | Use an owned healing draught; keeps it if health is full |
| C / I | Equipment / supplies; pauses combat |
| E | Talk, enter, leave, loot or use nearby station |
| M | Map and quest journal; shows barrow plan underground |
| V | First/third-person camera |
| R | Retreat to the south trail; does not refill resources |

Melee costs 9 stamina, with a 0.62-second cooldown (0.85 for two-handed weapons). It hits a forward arc at 2.6 m, or 3.1 m for two-handed weapons. Walls block melee; empty stamina prevents attacks. Off-hand weapons contribute a displayed rating but do not yet have a separate attack action.

Bows consume one arrow per shot with a 0.85-second cooldown. The forge makes 12 arrows from one timber and one iron ingot. Emberbolt costs 18 magicka, has a 0.9-second cooldown and deals 43% of spell-power rating before enemy mitigation. Staff primary attacks use the same spell. Arrows and spells aim through the camera crosshair and sweep a collision ray each physics step, so they cannot pass through thin walls at normal speeds.

Incoming damage is multiplied by `100 / (100 + armor × 1.5)`. A frontal shield block then keeps 22% of that damage; a melee-weapon block keeps 45%. Blocking spends 65% of incoming raw damage as stamina, slows walking and stops stamina regeneration. An unaffordable block breaks guard. Rear hits bypass blocking. Minimum damage is 1. Critical rolls, elemental resistances, locational damage and enemy equipment-based mitigation are not implemented; the boss has a fixed 20% reduction.

Enemies raise a weapon and turn their label amber before attacking. Sentries wind up for 0.65 seconds; the Captain takes 0.85 seconds. Melee enemies approach visible targets; ranged enemies move into range and fire physical projectiles. They respect walls and pause with the player. Pathfinding is a direct chase within this broad, connected layout; they do not yet navigate around unseen corners or run coordinated tactics. Hits squash enemy models briefly, play a player swing animation and display damage feedback. Combat now has hit, block, spell and death sounds.

## Progress and recovery

The existing character save atomically includes an optional `adventure` record: accepted/rewarded flags, defeated enemies, claimed corpses and opened chests. Existing v1/v2 profiles load with empty adventure progress. Claims prevent repeated supplies, boss drops and quest rewards. Equipped/favorited gear retains the existing salvage protections.

Death restores vitals and returns the player to the south trail. Collected loot, defeated enemies and quest progress remain. Exiting or dying restores surviving enemies to full health at their home positions and clears projectiles. After reloading, corpses appear at their original positions. Session saves now restore the player position, resource levels and nearby surviving enemy health; see SAVE_RESUME.md. The quest ember is a persistent quest flag, not a sellable inventory item, so salvaging gear cannot block turn-in.

This slice has authored drops rather than random loot tables. There are no repeatable dungeon resets or combat difficulty options yet. Later chapters include clan choices, and use-based skill/perk progression is available with K. Three village shops are playable. After returning the ember, Edda directs the player to Ilyra for the first main chapter, Stonewake (see STORY.md).

## Implementation and testing

- `scripts/adventure.gd`: dungeon geometry, smith, quest/dialogue, loot and transition rules.
- `scripts/enemy.gd`: three combat roles plus boss, windups, damage and corpses.
- `scripts/projectile.gd`: collision-swept arrows and spells.
- `scripts/player.gd`: attacks, blocking, resource costs, damage and death hook.
- `scripts/character_state.gd`: compatible save extension and validation.
- `tests/combat.gd`: combat, live AI, quest, traversal and persistence checks.
- `tests/render_adventure.gd`: isolated engine renders; run with `-- --capture` to avoid real-profile writes.

Launch normally to play from the trail, or use `-- --adventure` to start beside Edda with her dialogue open. `-- --dungeon --capture` renders an isolated dungeon preview with expedition supplies; it does not change the actual profile.

## Timed guard and counterattack openings

A fresh RMB press with a shield or melee weapon opens a 0.22-second parry window. A frontal melee hit in that window costs eight stamina and causes no damage. The attacker loses its windup and cannot move or attack for 0.7 seconds (0.35 for bosses); its label turns cyan during recovery. No damage or skill XP is awarded merely for parrying.

The window is consumed by a successful parry. Releasing and pressing again can rearm it only after a 0.8-second cooldown. Holding guard does not rearm it. Attack animations and incompatible weapons prevent guarding; opening a menu cancels an active window. Projectiles use ordinary directional blocking and do not stagger their shooter.

If a normal block exhausts stamina, guard breaks for 0.65 seconds. Regaining stamina cannot bypass this recovery. Temporary guard and stagger timers are not serialized. These initial timings need human playtesting for balance. `tests/parry.gd` covers defense rules and the real enemy melee callback.
