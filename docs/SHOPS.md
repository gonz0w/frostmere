# Frostmere shops and architecture

## Shopping

| Shop | Merchant | Location | Initial goods |
| --- | --- | --- | --- |
| The Copper Stag | Torren | Southwest house | Weapons, armor, arrows, ingots and leather |
| Juniper & Rune | Mira | Small riverside house | Potions, herbs, crystals, rune dust and gems |
| Ember Hall Stores | Halvar | Northern longhouse | Food, hides, timber, charcoal and other provisions |

Walk through the open doorway and press E near the counter. Choose Buy, Sell gear, Sell materials, Sell consumables or Buy back gear. Lists are searchable; stack purchases/sales support quantities. Quotes show the total price before the action. I/C/M switch screens, and Escape returns to the world. Shop names also appear on the local map.

Characters receive 150 starting gold, including compatible migration of pre-shop saves. New barrow corpse loot grants 12 gold per sentry or 90 for the Captain; hidden chests grant 30, and Edda's turn-in grants 60. Existing claimed rewards cannot be reclaimed to obtain the new gold.

Shops have separate stock and purses. Buying transfers gold to the merchant and reduces stock. Selling stacks transfers them into the merchant's stock, including stacks outside its original assortment. Selling equipment transfers the exact unique piece to that merchant's buyback inventory. Repurchase retains its ID, personal name, quality, enchantment and gem. Equipped or favorited equipment cannot be sold. Unaffordable purchases/sales, unavailable stock and invalid quantities change nothing. The UI checks physical proximity again when the transaction occurs.

Purchase price is rounded up from `base value × 1.35 × (1 − barter bonus)`; sale price rounds down from `base value × 0.45 × (1 + barter bonus)`, with a one-gold minimum. Barter bonus comes from Presence and is bounded to 0–25%. Gear value includes base damage/armor, tempering, enchantment and gem. These are initial prototype prices, not a balanced economy. Buyback uses the current purchase quote; it is not a free undo/refund.

Gold, merchant stock, purses and buyback share the existing atomic character save. Old saves default to an empty merchant history and the starting purse; subsequent saves retain the actual balance. Merchant stock and purse do not refresh on reloading, and automatic restocking is not implemented in this pass. Merchant dialogue/AI is limited to trade; they have no schedules or combat behavior.

## Architecture

The approved concept remains `docs/reference/approved-concept.png`. The changes emphasize its layered timber/stone surfaces and Nordic silhouettes:

- Four village houses: projecting posts and pegged knee braces, rough foundation courses and corner stones, small gable plank relief, ridge caps, crossed finials, patterned banners, shuttered windows, sills and planter boxes.
- Sheltered porches keep the central doorway and approach clear. The small house's header was raised to provide capsule clearance.
- Interiors: visible floorboards, rugs, ceiling joists, stocked shelves, counter goods and hearth/chimney stacks. Merchant models occupy the three shop interiors.
- Physical storefront names, warmer glowing windows, and masonry courses, ledges and slit windows on the distant fortress.

Environment additions remain in material/spatial MultiMesh batches. Collisions cover porch supports and shelving; walkthrough tests verify each shop entrance. The fortress remains scenery. Dungeon architecture and the terrain layout were not redesigned in this pass. The procedural scene is closer to the concept, not a claim of matching its final lighting, density or asset quality.

## Files and verification

`data/shops.json` contains inventory/prices, `scripts/trade.gd` owns transactions, `scripts/shops.gd` owns merchants/UI, and `scripts/refined_buildings.gd`, `scripts/building_profiles.gd` and `scripts/building_furnishings.gd` build distinct regional houses and shop interiors. `tests/shops.gd` verifies transactions, protected equipment, buyback identity, persistence/migration and actual doorway/counter interactions. `tests/render_shops.gd` produces isolated render checks when run with `-- --capture`.

Screenshots: `build/village-shops.png`, `build/outfitter-interior.png`, `build/shop-trading.png`. Run normally from the trail, or pass `-- --shops` to start at Torren's counter.

## Wyrmkeep expansion

Two additional staffed shops, Summit Smithy and The High Road, use the same stock, gold, resale and buyback system. Both supply clan service materials. Their stock remains available regardless of chosen clan. Five shops now operate across the two towns; see WYRMKEEP.md.
