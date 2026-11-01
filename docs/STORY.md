# Stonewake — first main chapter

Stonewake is playable after **An Ember Beneath Oldwatch**. Return the Captain's forge ember to Edda and claim her quest reward, then speak with **Ilyra**, the watchstone keeper east of the northern village house. The chapter also becomes available to existing profiles that already returned the ember.

Accept Ilyra's request, visit three ward stones around Frostmere, and read their inscriptions. Each offers Hearth, Tide and Sky runes. Invoke the matching rune to restore it; wrong answers consume nothing. Wards can be restored in any order, retain their blue light after saving, and cannot grant duplicate progress. The HUD guides the next uncompleted ward; the Frostmere-area map marks all three and Ilyra. The journal automatically selects Stonewake when accepted.

When all three wards are restored, interact with the central watchstone near the barrow. Three small voxel echoes appear: a station, a floating crystal and a sealed furnace. The text introduces their role in the future story without opening any destination gate. This interaction also records the relic objective for an active Oldwatch Survey, so the two quests cannot block each other.

Report to Ilyra to earn **Watchkeeper's Pendant**, a favorited Amulet of Resolve enchanted with Insight, **100 gold**, **six rune dust**, and **three crystals**. The pendant is an owned, customizable instance of an existing gear design; it does not add another base design to the collection. Quest completion records `stonewake` in shared story progress. It does not complete the council, archive, roots or space chapters, and neither later realm unlocks early.

## Normal play and preview

- Normal play: Edda's barrow quest → return ember → Ilyra → three ward puzzles → watchstone → Ilyra.
- **Preview Stonewake.command** starts beside Ilyra with Oldwatch already completed in a temporary profile. Both character and atlas saving are disabled for the entire preview, and a visible banner identifies it. The regular launcher still loads normal progress.
- E interacts, Esc closes dialogue, M opens the map/journal. Rune choices use the dialogue buttons. Quest dialogue pauses combat and supports switching to inventory, character or map without stacking overlays.

The optional `stonewake` save record stores acceptance, restored ward IDs, revelation and reward status. Load validation rejects duplicate/unknown wards, revelation before all wards, reward without revelation/completion, and acceptance before Oldwatch's turn-in. Earlier saves default to an unstarted chapter. Rewards and completion are committed together through the existing atomic character save.

## Scope

This is a complete small exploration/puzzle chapter connecting the existing dungeon adventure to the main narrative. The Divided Council is now playable in Wyrmkeep, reached through the north pass after this chapter. The Missing Atlas is also playable in Pinehall through the west trail; Pacts Beneath the Roots is playable at the Stag Shrine through the Amberweald trail. It adds no new combat encounter, faction membership or campaign skip. Later realm previews remain independently available.

`tests/stonewake.gd` covers 32 integration assertions, including the full UI-driven chapter, actual ward approaches, wrong/right answers, proximity guards, duplicate prevention, concurrent survey completion, save migration and later gate preservation. Native renders live in `build/stonewake-keeper.png`, `build/stonewake-runes.png`, `build/stonewake-echoes.png` and `build/stonewake-map.png`.
