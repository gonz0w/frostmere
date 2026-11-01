# The Wreck on the Black Shore

> Verification counts and capture observations below are historical development evidence, not fresh checks. `build/` paths refer to local output omitted from the source checkout; see [evidence guidance](README.md#screenshots-and-development-evidence).

The playable Saltbreak chapter follows **The Missing Atlas**. Take the coastal road southwest of Frostmere. It can advance independently of the council, woodland and observatory branches. Its atlas ID remains `tides`, preserving the existing campaign dependency graph.

## Expedition

1. Speak with **Keeper Sella** in the eastern harbor house or **Neris** in the western Iron Keel house. Accept the investigation and hear both claims.
2. Follow the black beach into the sea cave. Vent the **pressure pump**, then connect the **blue return line** at the beach relay. Wrong settings cost nothing. The two repairs physically open the wreck's bulkhead.
3. Enter the Wayfarer's two hull compartments, copy the **flight recorder**, defeat the **Hull Warden**, loot its damaged lens and recover the protected **power core**.
4. Give the core to Sella or install it at the ship's navigation cradle. This is a permanent choice. The beacon lights for Saltbreak; a star chart appears for navigation.
5. Return to Sella to claim the expedition reward and finish the chapter. Both outcomes preserve the recorder's lead to the Sunken Lens. The observatory is now playable as The Sky Below the Sand; the eventual space expedition remains unbuilt and later realm gates do not open early.

Six raiders/sentinels and the Hull Warden guard the route. The Iron Keel and Brinecutters' rivalry is conveyed through dialogue and hostile raiders; autonomous battles between NPC factions are not implemented. Surviving enemies reset on departure, defeated ones and collected salvage stay recorded. Dangerous surf returns you to the coastal arrival; combat death returns home and restores vitals.

## Recover, identify, restore

| Damaged salvage | Source | Restoration | Properties |
| --- | --- | --- | --- |
| Fractured Hilt | Beach salvage chest | Tideglass Saber | 22 base damage, +2 Agility, one-handed sword |
| Cracked Pressure Shell | Sea-cave cache | Tideguard Cuirass | 18 base armor, +2 Endurance, heavy chest armor |
| Clouded Signal Lens | Hull Warden loot | Signal Lens | +3 Intellect, off-hand focus |

Neris identifies each recovered relic once, unlocking its recipe. Restoration consumes its damaged part plus ship salvage and familiar materials at the forge. Weapons and armor then temper with Wreck Alloy and steel; high ranks also need Signal Circuits. A second damaged part is never required for tempering. The off-hand focus follows the existing accessory rules: enchantments and gems, without tempering. All three are ordinary owned instances after restoration.

Salvage sources are finite. Damaged parts and components can be traded under the normal material rules; sell unique damaged parts only if you do not want to restore them. Collecting the quest core and copying the recorder use protected progress flags, so neither can be sold.

## Core outcomes

- **Power Saltbreak:** the beacon illuminates. Sella grants the favorited Superior **Breakwater Mantle of Vigor** and its pattern. Its intrinsic effect improves health from consumables by 25%; its base bonus is +2 Endurance.
- **Restore navigation:** the ship's star chart activates. Sella grants the favorited Superior **Starsignal Staff of Insight** and its pattern. It uses the existing 24-magicka chain-lightning primary attack and grants +2 Intellect.

Only the chosen item's pattern and reward are awarded. Both reports grant 150 gold, six Wreck Alloy, four Signal Circuits, six steel ingots, four leather and four crystals. The unchosen outcome stays unavailable in that profile. The beacon's harbor benefits are narrative and visual; no passive healing aura or economy simulation is added.

## Preview and scope

Double-click **Preview Black Shore.command** to start an isolated post-atlas character with a tempered sword, healing supplies and restoration materials. Both character and atlas saves are disabled. Press E to interact, M for the coastal map, I for inventory/workstations and Escape for audio controls. The chapter uses the existing Nordic exploration/battle score.

The region includes three enterable houses, a dock and fishing boats, layered cliffs, a sea cave, an enclosed wreck, two workstations and a local map. See [the current content reference](CONTENT_REFERENCE.md) for catalog totals and quest availability. Five existing merchant shops remain available elsewhere.

The proposed 20–30-minute pacing target has not been verified by a timed human playthrough. Encounter balance and exploration pacing still need that playtest; repeatable salvage sources, dynamic weather and a full coastal region are future work.

## Optional silver investigation

Sella now offers Nets Full of Silver. Investigate the western dock net and the ledger at the sea-cave cache after defeating its approach guard, then choose how to report the evidence. The crew's recovery and the lasting reporting outcome are conveyed through dialogue/journal. Both choices award a Netmender's Band and pattern. This does not consume damaged relics, repair supplies or the main power core. See SILVER_NETS.md.


## Working waterfront polish

Saltbreak's existing pier now continues onto land with thirteen matching planks and three shallow approach pieces. Mooring posts, sagging decorative ropes and rope coils frame its edges; a covered fish-sorting table, two storage crates and two lanterns sit south of the approach. The scenery is not a new merchant or quest service. A pre-existing decorative rock stack that overlapped the pier edge was omitted. Net, harbor, charter and other quest positions remain unchanged, as do the boats and offshore water boundaries. Net addition: 391 batched decorative blocks.

The existing and new solid pier planks are explicitly tagged wood, fixing their former stone footstep sound. Other shore solids retain their existing surface behavior. The new tests sample three player-width paths across the pier and approach at half-metre intervals, check support and footsteps, verify nearby quest approaches and confirm there is still no floor beside the seaward pier.

Validation: saltbreak_detail 21, shore 65, silver_nets 43, ash_boat 43, last_light 45, safe_passage 66 and footsteps 15 checks passed (298 total). Native Mac waterfront and pier views inspected in build/saltbreak-waterfront.png and build/saltbreak-pier.png. Broader settlement layout/architecture and hardware performance work remain open.
