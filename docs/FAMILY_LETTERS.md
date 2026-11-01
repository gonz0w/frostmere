# Letters Above the Snow

A peaceful optional Wyrmkeep investigation, available after Stonewake opens the mountain road. Ask Runa about the undelivered family letters, collect accounts from Hadrik and Sera, then compare them against the passkeepers' memorial just west of the central road. Neither clan membership nor acceptance of the council investigation is required.

The families' accounts blame Mara and Oren respectively for abandoning the other during a whiteout. The final watch record instead shows them saving travelers together. Return the evidence to Runa and choose:

- Public remembrance: add both names and their shared watch to the memorial, +10 reputation with each clan, 150 gold and four Steel Ingots.
- Private replies: return copies to the families without changing the public inscription, +5 reputation with each clan, 120 gold and four Silver Ingots.

Reputation gains cap at 100. The decision is single-use and survives save/load. Clan membership, rank and council policy remain separate. The journal and Runa retain the outcome; broader family/NPC simulation is not implemented.

Physical conversations and memorial inspection require proximity. Both distinct accounts are required before verification; verification is required before resolution. Optional letters_started, letters_received, letters_witness and letters_choice fields are stored inside mountain progress. Old saves default to unstarted; inconsistent progress is rejected before loading changes. Letters are evidence records rather than sellable items.

The memorial has a stone plinth, brass inscription and collision. Public resolution changes its visible text to “MARA & OREN / One final watch”; private resolution retains the existing dedication. No new combat encounter is needed.

The atlas now has 23 remaining planned quest outlines.
