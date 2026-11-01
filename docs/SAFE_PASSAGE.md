# The Price of Safe Passage

The Compact's third chapter is playable after becoming Envoy. Ask Vessa to draft the charter, then use the separate charter discussion with Sella, Neris and sheltered Tamsin. Their existing quest and salvage dialogues remain available. Sign at the new charter table west of Saltbreak's southern road after recording all three proposals.

Three permanent terms:
- Open charter: shared oversight, published fees/accounts, independent routes welcome; 200 gold and a Masterwork Amulet of Presence with Vigor.
- House charter: House Merrow administers the harbor while Concord routes remain licensed; 300 gold and the same Masterwork amulet with Insight.
- House charter plus Concord ban: same house reward, but permanently closes the Sable Concord final quest, The Road Without Kings.

Every choice grants Harbor Speaker rank, 8 Wreck Alloy, 6 Signal Circuits, and a favorite-protected amulet named Harbor Speaker's Seal. Existing upgrade systems apply. No new design or recipe is added. Tamsin's prior protection choice and all main coastal outcomes remain intact. The charter's visible caption and journal change with the outcome. Administrative policy is a recorded story outcome, not a simulated tariff economy or new patrol system.

Save fields are optional `shore.passage_started` boolean, `passage_heard` unique harbor/salvager/witness IDs, and `passage_choice` empty/open/house/outlaw. Validation requires Envoy completion before starting and all consultations before signing. Legacy Envoy saves default to unstarted. Signing and rewards cannot repeat.

The Concord arc is now playable. Its final quest checks the Compact ban before every action. Conversely, a Concord declaration of war blocks the Compact finale. Neither hostile clause can retroactively invalidate a completed rival finale; peaceful finales work in either order. These conditions are enforced in dialogue, actions and save validation. See ROAD_QUESTS.md.

Validation: safe_passage 66, harbor_lied 38, tide_compact 43, shore 65, silver_nets 43, atlas 42: 297 passing checks. Covers all outcomes, dialogue access, exact reward quality, rival closure display, one-time signing, atomic load validation and legacy saves. Native Mac choice and signed-charter captures were inspected.
