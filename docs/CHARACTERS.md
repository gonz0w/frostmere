# Character and equipment foundation

Open with **C**, or use Character & equipment from the pause menu. C/Escape returns to exploration. Editing the name supports normal text entry; press Return or leave the field to apply it.

## Content

- **8 ancestries:** Frostkin, Sunborn, Grove Elf, Dusk Elf, Stoneborn, Orckin, Wildcat, Scaleborn. Each has a small attribute bonus and an appearance variant (skin, ears, beard, tusks, muzzle or tail). Three body frames: lean, balanced, broad. These are initial original-world options, not an exhaustive final roster.
- **8 starting playstyles:** Warrior, Berserker, Ranger, Rogue, Mage, Battlemage, Warden, Spellblade. They grant initial attribute bonuses and offer a starter loadout. They do not restrict equipment. Changing playstyle preserves equipment; the starter-gear button equips matching owned pieces.
- **6 attributes:** Strength, Agility, Endurance, Intellect, Willpower, Presence. Each starts at 10, plus ancestry/playstyle bonuses, up to ten assigned points, and equipped item bonuses. Points can be refunded while experimenting.
- **9 slots:** head, chest, hands, legs, feet, main hand, off hand, ring, amulet.
- **145 items:** 62 armor pieces, 58 weapons (including realm and clan designs), six shields, three magical focuses, seven rings and nine amulets.
- **Armor families:** cloth, fur, leather, iron, chain, steel, obsidian, crystal. They differ in protection, weight, bonuses, color, and selected geometry details. Mixed sets are supported.
- **Weapon families:** dagger, sword, war axe, mace, greatsword, battleaxe, bow, staff. Materials: iron, steel, obsidian, crystal. Every family has a procedural voxel model.

Equipment is owned: obtain additional pieces from supply caches and forging. The Collection view shows all 145 designs and remembers discoveries after salvage. Copies have independent tempering, enchantments, gems, names and favorites. See `CRAFTING.md`.

## Equipment rules

Armor and jewelry fit only their named slot. Main-hand weapons must be weapons. The off hand accepts shields, a magical focus, or one-handed weapons. Greatswords, battleaxes, bows, staves and machine guns occupy both hands: equipping one clears the off hand, and off-hand selection is blocked until it is removed. Removing a two-handed weapon does not automatically restore the previous off-hand item.

Changing equipment rebuilds the modular character and both held-item views. First-person gear changes do not reveal the third-person body. The character preview uses its own world and renders only while the character screen is visible.

The comparison panel shows selected-slot armor, base-damage, and weight differences against the current item. Item bonuses are displayed separately; it is not a full final-build DPS simulation. Two-handed items explicitly indicate off-hand removal.

## Attributes and current effects

| Attribute | Derived values |
| --- | --- |
| Strength | Strength-scaling weapon rating; carrying capacity |
| Agility | Agility-scaling weapon rating; movement speed; weapon critical-hit chance |
| Endurance | Health/stamina limits; stamina regeneration |
| Intellect | Magicka limit; magical weapon rating; spell power |
| Willpower | Spell power; magicka regeneration |
| Presence | Barter bonus rating |

Equipped weight reduces movement speed and raises sprint drain. Health, stamina and magicka limits update when the build changes, preserving the current resource percentage to prevent equipment toggles from granting free refills. Stamina drains during sprint and regenerates at the build's rate; magicka regenerates at the derived rate. Movement and sprint effects are active now.

Weapon damage drives melee and bows; armor mitigates incoming damage; spell power scales Emberbolt. Presence affects shop buying/selling prices. Agility grants 0.6 percentage points of weapon critical chance per point, capped at 35%; critical melee, bow and firearm hits deal 50% extra damage before enemy mitigation. Each melee swing shares one roll across targets; projectiles retain their launch roll. Spells use spell power instead. Use-based Melee, Marksmanship, Magic and Crafting now earn shared perk points; eight selectable perks improve combat and equipment creation. See `SKILLS.md`. Loot weight enforcement, racial powers and active class abilities remain future work. There is no class lock or turn-based system.

## Saving

One local current character profile is automatically saved after each edit to Godot's `user://character-v1.json` (normally `~/Library/Application Support/Godot/app_userdata/SkyrimCraft • Frostmere/character-v1.json`). The filename remains stable, but schema v2 includes identity, allocated points, owned item instances, equipment, materials, consumables, blueprints, learned formulas, collection discoveries, crafting XP and gathering claims. Old v1 equipped gear migrates into owned instances. Session data now saves the active area, world position, camera, current health/magicka/stamina and nearby surviving enemies alongside the character. Atlas progress saves separately. See `SAVE_RESUME.md`.

The loader checks schema version, known IDs, valid slot assignments, two-handed conflicts, and point budget before applying any values. Writes use a temporary file followed by a rename. Headless checks, captures and benchmarks are isolated from the real profile. Future character slots or cloud sync are not included.

## Extending the system

Edit `data/characters.json` to add definitions. `character_state.gd` owns rules and stats; `character_visual.gd` owns body/armor and weapon construction; `character_menu.gd` owns the screen. Future NPCs can reuse the same state and visual classes; Edda and barrow enemies reuse these classes; broader NPC AI is future work. New weapon families or ancestries with new shapes need corresponding visual construction as well as catalog entries.

## Saved equipment sets

Four named loadouts are available beneath the C-screen preview. Save current captures all nine slots by owned-instance ID and records base identities for missing-item reporting. Applying a set validates ownership and slot compatibility before replacing equipment in one commit, so switching between a two-handed weapon and sword/shield does not depend on equip order. Existing item upgrades, enchantments, sockets, names and favorites remain attached to the same instances.

Sold or salvaged pieces remain referenced in the set and block applying it. Recovering the same instance (such as shop buyback) makes it usable again. No substitute copies are silently selected. Deleting or overwriting a set does not delete its items. Optional loadout save data is validated before any loaded character fields are applied; older profiles receive four empty sets.
