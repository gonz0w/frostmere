# Hearthbound Lodge — The Old Watch Road

The first Lodge rank is playable after returning Oldwatch's forge ember. Read the new Hearthbound Lodge tab at Frostmere's Hunters' Board. Acceptance grants exactly enough repair supplies: 6 wood and 3 iron ingots. Repair three physical markers on existing terrain at the village edge, eastern crossing and eastern ridge, costing 2 wood and 1 iron each. Both existing ridge bristlebacks (wild_9 and wild_10) must be defeated before the final marker can be repaired; earlier defeats count.

Repaired markers visibly light. Return to the board to optionally swear the Outrider oath, receiving 120 gold and a favorite-protected Superior Wardkeeper's Amulet with Vigor named Outrider's Hearth. Existing upgrades apply. Repairs remain if membership is deferred. This restores three markers and clears a road threat; it does not remodel all road terrain or add patrol AI. Waykeeper and Warden remain planned.

The hunt-board UI hosts a separate Lodge tab; marker interaction opens the same tab with that marker selected. Hunt claims still require proximity to the original board, so opening another tab at a marker cannot claim hunt rewards remotely. Normal pause/escape handling remains shared with the existing board.

Optional fields in hunt: lodge_started and lodge_joined booleans, lodge_repairs unique village/crossing/ridge IDs. Validation requires the forge ember reward before acceptance, acceptance before repairs, the two beast defeats before ridge completion, and all repairs before joining. Legacy hunt saves default to unstarted. Supplies and rewards cannot repeat; missing repair materials spend nothing.

Validation: hearthbound 33, atlas 42, combat 46, characters 36, hunt 22, wilderness 19 = 198 passing checks. Native Mac board/oath and restored crossing marker captures inspected. Character tests now verify catalog ID uniqueness against actual catalog entries instead of a stale pre-Netmender item count. No new item design was added.


## A Winter Without Wolves

A Winter Without Wolves now follows the Outrider oath. The Lodge tab opens the watershed investigation, with den/runoff/keeper evidence and a permanent filter-repair decision. Waykeeper rewards differ by exposure or concealment. See WATERSHED.md.


## Who Guards the Pass?

Waykeepers can now accept the north-pass commission and choose the watch’s leadership after harvesting the colossus. Both policies grant Warden; patrol outfits and support supplies differ. See WARDEN.md.
