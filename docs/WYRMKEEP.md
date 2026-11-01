# Wyrmkeep and the Iron Pact clans

Wyrmkeep is a second playable settlement, reached through the north pass beyond Ember Hall after completing Stonewake. It has five enterable, furnished buildings: the council hall, two clan halls, Summit Smithy and The High Road. A snowy square, market stalls, lanterns, benches, mountains and a northern reaver outpost give it a distinct setting. Travel is a pass interaction between authored areas, not a seamless continent.

## The Divided Council

1. Speak with **Speaker Runa** in the central hall to accept the investigation.
2. Hear **Hadrik of Stoneguard** in the west hall and **Sera of Stormweaver** in the east hall.
3. Walk around the council hall to the northern outpost. Defeat the three road reavers, then recover the ledger from its chest. Reaver corpses also offer gold, steel and crystals.
4. Return to Runa and choose a settlement. Shared patrols and rune repairs give +10 reputation with each clan. Favoring one policy gives +20 to that clan and −5 to its rival. None of these choices enrolls you.
5. Receive 120 gold, five steel ingots and six rune dust. `council` is recorded in main-story completion, opening the narrative route toward the Ashen Choir chapter; that next chapter remains planned.

Evidence is a saved quest flag and cannot be sold or salvaged. Investigation, testimony, evidence and reward are one-time. Main-story completion requires no faction membership.

## Optional clan progression

The two clans belong to the existing **Iron Pact**, preserving the seven-faction world outline. You may swear to one of these rivals per character. The oath button explicitly states that rival membership closes; both shops and the main story remain available. There is no resignation or switching system yet.

| | Stoneguard | Stormweaver |
|---|---|---|
| Values | Protect the holds through patrols, stores and shieldwork | Restore old knowledge through runes and exploration |
| Initiation | Repair west, south and east road wards; each costs one iron ingot and two timber (inventory ID `wood`). Joining grants these supplies once. | Attune those three wards; each consumes 15 magicka. |
| Sworn reward | Fine enchanted Oathblade, weapon pattern, Stoneguard Oath formula | Fine enchanted Spire staff, weapon pattern, Stormweaver Sight formula |
| First promotion | Deliver two steel ingots to each of two town supply posts | Deliver three crystals to each of two town supply posts |
| Shieldbearer reward | Superior enchanted Bulwark chest; chest and Aegis shield patterns | Superior enchanted Mantle chest; chest and Lens focus patterns |
| Enchantment | +3 Endurance / +1 Willpower | +3 Intellect / +1 Agility |

After the three wards, report to your sponsor to become **Sworn**. After both deliveries, report again to become **Shieldbearer**. Each rank adds 25 clan reputation. Joining adds five; promotion also grants 80 gold. Rank rewards are favorited owned instances. Weapon patterns unlock at Sworn; chest and off-hand patterns unlock at Shieldbearer. The final **Clan Voice** capstone remains planned.

These are six new craftable gear designs and two new formulas: 133 equipment designs, 149 recipes and ten enchantments in total. Clan formulas use three rune dust and two crystals. Clan gear, patterns, ranks and reputation travel home with you. Shops use normal Presence-based prices; reputation currently records policy and service standing rather than changing vendor prices or starting automatic hostilities.

## Shops, map and recovery

**Summit Smithy** (Brenna) and **The High Road** (Oren) sell finite stocks of ingots, timber, crystals, rune dust and healing draughts. Normal purchases, resale, protected gear and instance-preserving buyback work here. Separate forge and enchantment stations sit beside the square. Materials gathered earlier can pay for clan tasks, or you can use loot and the local merchants.

M opens a dedicated town map. The journal reports council/clan objectives, and the Iron Pact faction dossier reports your chosen clan, rank and both reputations. E talks, interacts, loots, crafts and travels. Esc closes dialogue. Death returns you to Frostmere with earned progress intact; surviving reavers reset when you leave. Defeated reavers and claimed loot stay defeated/claimed after reload. Repeatable raids and stock replenishment are not implemented.

**Preview Wyrmkeep.command** starts a temporary post-Stonewake profile with supplies. Both character and atlas saving are disabled for the entire preview, including after returning home. Use the normal launcher for persistent progression through Edda → Stonewake → north pass.

## Validation

`tests/mountain.gd`: 74 assertions covering the pass lock, all five building entrances, real player melee, the full council investigation, all three policies, independent completion, both exclusive clan branches, resource costs, one-time rewards, promotions, forging, shops, stations, saves, migration, invalid ranks, return travel and death. New schema fields are optional in version-2 saves and validated before application. Existing profile data is retained.

Native Metal renders in `build/wyrmkeep-arrival.png`, `build/wyrmkeep-council.png`, `build/wyrmkeep-map.png`, `build/wyrmkeep-outpost.png` and `build/wyrmkeep-clan-oath.png` document visual checks. The added geometry is included in the world's batch count, while separate character/dungeon/realm geometry is still excluded from that count. No M1 benchmark was performed for this milestone.

## A Crown of Separate Holds — Clan Voice capstone

After Shieldbearer rank, speak to your own sponsor and accept the road-defense commission. Harvest the Mossbound Colossus (wild_11) and Rimefang (wild_12) in Frostmere, then return to your sponsor. Earlier harvests count and no creatures respawn. Neither the market hunt's acceptance nor its reward claim is required. The commission works for both Stoneguard and Stormweaver members.

Choose independent holds with shared patrols, or a central war leader. Shared patrols grant +15 own-clan/+10 rival reputation, four Steel Ingots and two Silver Ingots. A central leader grants +25 own-clan/−10 rival reputation, six Steel Ingots and two Crystal. Reputation remains capped at the existing limits. The permanent mandate is recorded in sponsor dialogue and the journal. This first pass changes reputation and supplies; it does not spawn patrol NPCs, simulate government, or close other faction capstones.

Either choice grants Clan Voice rank, 160 gold, a Superior favorited Clan Voice Signet and its forge pattern. The signet has two base armor and +2 Strength, Willpower and Presence. Forge cost is three Steel Ingots, two Silver Ingots and two Crystal. It supports normal tempering (silver/crystal), higher-tier Ember Core costs, enchanting and sockets.

Optional mountain expedition/mandate fields preserve older profiles. Rank three requires accepted commission, complete earlier rank prerequisites, a valid mandate and both monster harvests. Claims require the sponsor's physical proximity and cannot repeat. Existing main-story gates remain intact. The atlas now marks iron_pact_3 playable and shows live sponsor/commission progress.

## Optional family-letter investigation

Runa now offers Letters Above the Snow. Hadrik and Sera provide conflicting family accounts regardless of membership. Compare them at the passkeepers' memorial west of the central road, then choose public remembrance or private replies. Rewards increase both clan reputations and provide gold/forge materials; the public outcome adds Mara and Oren's shared watch to the physical inscription. No council policy, oath or rank is selected by this quest. See FAMILY_LETTERS.md.


## Winter lanes and courtyard polish

The rigid cross-shaped ground pattern is replaced with worn, bending lanes linking existing services and doors. A paved bypass runs east of the council hall toward the northern outpost; a separate route reaches the travelers and watch hut. A covered frozen well, three distinct firewood stacks, low council approach markers and windblown snow banks give the existing settlement more variety. This adds 144 decorative blocks in existing material batches. Buildings, quest NPCs, services and saved actor coordinates are unchanged; no new shops or interaction rewards are implied by the scenery.

The mountain ground collision carries a Wyrmkeep surface tag. Footsteps use the same rounded grid/path predicate as the visible ground: stone on paving, snow elsewhere, with wooden building floors retaining their own surface. Eleven walking lanes were sampled every half metre for ground support and player-width collision clearance. Initial corner/step/ward obstructions were corrected. 266 checks passed: wyrmkeep_detail 36, mountain 74, warm_shelter 30, family_letters 38 and road_branches 88. Native Mac overview/courtyard captures inspected in build/wyrmkeep-lanes.png and build/wyrmkeep-well.png. This is a circulation and scenery pass; building relocation/rotation, larger settlements and M1 profiling remain open.


## Winter pine groups

Thirteen snow-dusted pines now break up the bare outer settlement grounds. They reuse the deterministic small-branch woodland geometry, with thin snow caps on selected foliage clusters, varied heights and narrow colliding timber trunks. Tree groups sit outside the existing lane canopy-clearance envelope; town buildings, ward stones and watch-hut approaches remain in place. The new geometry adds 6,309 batched blocks with no per-tree update loop. This is settlement-edge planting; the enclosing ridge terrain is unchanged.


## Snow drifts and exposed rocks

Low layered drifts now gather around the thirteen outer pines, with six snow-capped rock groups breaking up nearby bare ground. All 75 added blocks have matching collision and snow/stone footstep metadata. Town lanes and interaction approaches remain clear. This adds small off-road obstacles and ground detail, not a new terrain-height system.
