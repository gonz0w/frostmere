# The collector’s workshop

Playable in the current Frostmere scene. The aim is to find a useful piece, make it personal, and keep improving it. No terrain editing or building is added.

## First circuit

1. Collect the Smith’s Welcome Cache beside the south trail, just right of spawn. It contains materials, a Fine dagger of Insight, a ruby, and steel/chain blueprints.
2. Use the Village Forge west of the main path. Smelt iron ore into ingots, forge equipment, and choose Improve to temper an owned piece.
3. Visit the Runewright’s Table beside the northern village path. Apply Vigor or Fleetfoot, or consume the cache’s dagger to learn Insight. At Superior quality, add a gem to a piece you want to keep.
4. Gather herbs near the south trail, mushrooms farther north, water from the barrel, and food/hides/timber from the provision basket. Brew potions at the Herbalist’s Bench and cook at the Hearthfire Cooking Pot.
5. Cross Oldwatch bridge. The Watcher’s Cache north of the ruins contains more enchanted gear, rare materials, gems and silver/obsidian/crystal blueprints. Ore and crystal deposits support repeat crafting. The Silver Vein also yields an Ember Core.

Press **E** when the nearby prompt appears. **I** opens the bag; the category selector switches between gear, materials, recipes, improvements, enchanting, salvage, consumables and collection. **C** equips owned pieces and shows your character. **I/Escape** closes the workshop; C/M switch to the corresponding screen.

## Systems

- **Gear and supply recipes:** see [current counts](CONTENT_REFERENCE.md). Ingredients are spent only on successful operations. Recipes list required station, blueprint and owned/required ingredients.
- **Individual ownership:** duplicates have separate instance IDs and upgrades. A single instance cannot occupy two slots. The starter button equips owned matches and never grants free replacements.
- **Tempering:** Standard → Fine → Superior → Exquisite → Masterwork → Legendary. Each rank adds 2 to existing base damage and/or armor; it does not invent these ratings on jewelry. Costs rise each rank. The final two steps consume Ember Cores for home-world equipment, Aether Shards for Aeralis gear, or Soul Embers for Crucible gear. Accessories without damage/armor can be enchanted but cannot be tempered/socketed.
- **Ten enchantments:** Might, Fleetfoot, Vigor, Insight, Resolve and Presence each add two points to their attribute. Vigor and Fleetfoot are initially known; enchanted cache gear teaches the remaining formulas when consumed at the table. Applying a formula costs three rune dust and one crystal, replacing the prior enchantment. Aether Attunement adds +3 Intellect / +1 Agility; Infernal Resolve adds +3 Endurance / +1 Strength. These use realm materials and rune dust, listed per formula. No elemental combat procs are implied.
- **Gem sockets:** Superior or better gear accepts one ruby (+2 Strength), sapphire (+2 Intellect), or emerald (+2 Agility). Extraction consumes one rune dust and returns the gem. A filled socket cannot be overwritten.
- **Salvage:** the forge destroys unequipped, unfavorited gear for a partial base-material return. The UI displays the yield and states that quality, enchantment and socketed gem will be lost. Learning an enchantment similarly consumes the item. Equipped/favorited items are protected.
- **Personalization:** rename and favorite individual pieces. Collection discovery survives dismantling; finding duplicate designs does not inflate completion.
- **Potions and food:** five recipes restore health, stamina or magicka. Use from Consumables. A full resource keeps the consumable. Combat drains health, Emberbolt spends magicka and sprinting/attacks/blocking spend stamina. F uses a healing draught directly.
- **Gathering:** two one-time chests and eight renewable spots, with 45–120 second real-time cooldowns. Claims persist across reloads; emptied chests visibly flatten. Nearby prompts show remaining cooldown. Gems are rare finite finds in this first slice, including barrow chests, but can be extracted and reused.
- **Appearance:** enchanted held gear has small glowing runes, socketed held gear has a colored gem, and tempering reduces weapon material roughness. Armor bonuses are functional; this is not a complete upgrade art pass for every armor piece.
- **Craft XP:** successful crafting, tempering and enchanting train Crafting and contribute shared perk points. [Skills and perks](SKILLS.md) includes forging and tempering benefits.

## Workstation coordinates

World coordinates are for developers; the game uses floating labels and proximity prompts.

| Station | X | Z |
| --- | ---: | ---: |
| Village Forge | -5.8 | -11 |
| Runewright’s Table | 6 | -29 |
| Herbalist’s Bench | -3.8 | 3 |
| Hearthfire Cooking Pot | 5.5 | -4 |

The UI rechecks physical proximity when performing an action. Inventory browsing and consumable use work anywhere. Using the forge still records its Oldwatch Survey objective before opening the paused workshop.

## Persistence and limits

Character save schema v2 keeps equipment, inventory, crafting and gathering progress in one atomic temporary-file/rename write to the existing `user://character-v1.json` path. Legacy v1 equipped items become distinct owned instances, retaining identity and attribute points. A starting material allowance is given to a new/migrated character; loading v2 replaces saved counts rather than granting another allowance. Atlas progress remains separate. Captures and headless tests do not load or alter the real profile.

Authored enemy drops and five [buy/sell shops](SHOPS.md) supply equipment and materials. [Use-based skills](SKILLS.md), crafting sound cues and [session saving](SAVE_RESUME.md) are implemented. Random loot-affix generation, repair durability and inventory weight enforcement are not implemented. Saves restore supported state rather than every transient world event; campaign economy balance remains unverified.

Content lives in `data/crafting.json`; transaction and save rules are in `scripts/character_state.gd`, the interface in `scripts/workshop.gd`, and gathering/station props in `scripts/world.gd`.

Oldwatch Oath adds a named boss sword and unlockable forging pattern. Edda rewards its recipe after the player retrieves the forge ember from the Captain’s remains. The forge also makes twelve arrows from one timber and one iron ingot. See `ADVENTURE.md`.

Stoneguard Oath (+3 Endurance / +1 Willpower) and Stormweaver Sight (+3 Intellect / +1 Agility) are earned through their clan initiations. Weapon patterns unlock at Sworn, with chest and off-hand patterns at Shieldbearer. See WYRMKEEP.md.

## Batch supply preparation

Unlocked ammunition, refining, potion and cooking recipes now offer five- and ten-batch buttons in addition to a single craft. Each button shows the exact output quantity, with total ingredient counts directly underneath and in its tooltip. The buttons disable when the entire batch is unaffordable or the player is at the wrong workstation. A stale click rechecks current proximity, blueprint and materials.

Batch costs, output and crafting XP scale exactly with the number of ordinary crafts. All ingredients are checked before any are spent, then the batch commits once. There is no bulk discount or XP bonus. Equipment, Transit Regulators and Cinder Wards remain single-craft. Recipe counts, per-recipe prices, material sources and save fields are unchanged.

## Emergency story-component recovery

If optional upgrades leave you unable to afford a required component, revisit the chapter supply chest after learning its design and collecting the original supplies. Mirewatch offers a Transit Regulator rebuild from dedicated spare parts; the wardwright's chest offers a Cinder Ward rebuild. The option appears only while the objective is unfinished, no component is owned and normal crafting is unaffordable. When ordinary ingredients are sufficient, use the forge as before.

A rebuild grants exactly one component and no raw materials, gold or crafting XP. These components cannot be sold or used in other recipes; the ordinary installation/binding action consumes them. Owning one or completing the objective removes the recovery option. The Cinder Ward still requires defeating the Sealbreaker before binding. Blueprint/evidence gates and original supply rewards remain intact. Recovery uses existing material inventory and saves without new fields.

### Staves and spell power

An equipped staff adds half its tempered base damage, rounded down, to spell power before Kindled Mind. Each temper rank therefore adds one spell power before perks, through Legendary. The benefit applies to selected spells and conductor Chain Lightning. The workshop shows the current bonus and next upgrade benefit. Unequipping the staff removes it; physical weapon damage does not grant this bonus. Focus items retain their attribute-based benefits.

### Netmender's Band

Either Nets Full of Silver resolution unlocks this Saltbreak ring and grants one Fine, favorited copy. It has two base armor, +2 Endurance/+2 Presence; forge additional copies with two Silver Ingots, two Leather and one Crystal. It supports tempering, enchantment and sockets. See [the current content reference](CONTENT_REFERENCE.md) for catalog totals and quest availability.
