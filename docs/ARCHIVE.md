# Pinehall — The Missing Atlas

Complete Stonewake, then follow the western trail from Frostmere. This chapter can run independently of the Wyrmkeep council. The forest settlement has three enterable houses, a forge, an enchanting altar and a two-chamber ruined archive.

Speak with Mereth of the Veiled Lantern or Aelin of the Briar Coven to accept the investigation. Hear both claims, read the optional archivist testimony, search the two caches, defeat the Bound Archivist, and recover the atlas. Return to the chosen representative and explicitly entrust it to them.

The Lantern favors controlled study; the Coven favors returning knowledge to the communities sustaining the forest. Custody awards +25 reputation with the recipient and −10 with the rival. It does not join either faction or cause automatic hostility. Only the chosen recipient's item and crafting pattern are awarded. The permanent choice, loot and quest progress save with the character.

## Relics

- **Echoharvest:** the guardian's favorited Superior sword of Fleet. Melee kills restore 18 stamina, capped at maximum. Corpse hits, spell kills and unequipped gear do not trigger it. The guardian also grants its forging pattern.
- **Lantern Conductor:** a favorited Superior staff of Insight. Its left-click attack spends 24 magicka with a 1.2-second cooldown. The projectile deals 60% of spell power, then jumps to up to two other living enemies. Each jump deals 65% of the previous damage and needs a visible target within five meters. Walls block jumps. The ability requires the equipped staff; Q and B retain the learned-spell controls.
- **Vestment of Renewal:** a favorited Superior chest piece of Vigor. While equipped, health restored by consumables increases by 25%, capped at maximum health. Magicka and stamina restoration stay unchanged.

All three use the existing owned-instance, tempering, enchantment, socket, favorite and salvage systems. Their intrinsic effects remain alongside ordinary enchantments. Memory Shards and Living Resin from finite guardian loot and caches feed the three new forging recipes; the materials can also be sold. Turn-in grants 100 gold and three of each component.

The catalog now contains 133 gear designs, 149 recipes and ten enchantment formulas. There are seventeen normal playable quests in the 51-entry atlas; 34 remain outlines.

## Preview and limits

`Preview Pinehall.command` opens an isolated post-Stonewake character. Both character and atlas persistence are disabled. Return home through the southern trail; the relic effects work elsewhere too.

The atlas now leads to the playable Black Shore shipwreck chapter. The Sunken Lens observatory chapter is now playable through the eastern expedition road. This chapter does not bypass the later space, Aeralis or Crucible gates. Lantern/Coven membership campaigns, repeatable resource farming and further reputation consequences are not implemented.

## Missing apprentice

The college notice offers an independent investigation into Iven's disappearance. His trail uses the existing archivist testimony, followed by an alcove interaction after archive_2 is defeated. Iven returns to camp, where supervised college research or independent authorship grants different enchanted equipment and formulas. The notice/returned-NPC dialogue remains accessible regardless of the player's Lantern or Coven progress. See MISSING_APPRENTICE.md.


## Pinehall woodland clearing polish

Pinehall now has bending lanes from its arrival route to both faction halls, the western building and a new covered reading table. The ruin's central approach remains straight and its geometry, encounters and quest locations are unchanged. Two tended herb beds and three fuel stacks sit outside the halls; the reading table's books are scenery, not new collectible rewards. A lantern marks the table approach. The pass adds 120 decorative blocks to existing batches.

Footsteps now use the visible clearing's path predicate: stone on paving, grass elsewhere. The archive floor remains stone even away from its central stripe, and separate wooden interior floors preserve their own surface metadata. Tests sample five lanes at half-metre intervals for capsule clearance and support, check the rescued apprentice position and existing quest approaches, and exercise real floor-ray sounds. Native Mac clearing and table views were inspected. Broader forest terrain, building layout variety and performance profiling remain open.

128 checks passed: pinehall_detail 23, archive 52, missing_apprentice 38 and footsteps 15. Captures: build/pinehall-clearing.png and build/pinehall-reading-table.png. Normal saves and quest progression are unchanged.


## Woodland elevation and tree variation

Four low rises now shape Pinehall's outer woodland, with maximum authored heights of 3.4, 4.0, 2.6 and 3.2 metres. Earth columns and grass caps keep the voxel silhouette; a triangulated ground surface provides walkable slopes rather than requiring jumps up each visible block. The central camp, western building, lanes and archive remain level. Tree spacing, height and foliage offsets vary deterministically, trunks follow the terrain, and the western building has an explicit tree exclusion. Existing undergrowth follows the new heights.

The old flat collision slab is replaced, so a saved position beneath a new rise cannot be mistaken for supported ground. Existing session validation restores supported elevated positions and sends obsolete underground positions to the chapter arrival point. No save schema change is needed. The slope fixture walks the real player from x=25 to x=35 near the eastern summit without jumping; it uses a bounded traversal window rather than assuming uphill speed matches level-ground speed.

205 checks passed: pinehall_terrain 19, pinehall_detail 23, archive 52, missing_apprentice 38 and session_save 73. Native Mac clearing and slope captures inspected, including build/pinehall-forest-rise.png. World batches now contain 336,143 blocks (+1,770 net for this pass). Collision uses 68,640 triangle vertices for the chapter ground. M1 performance and broad terrain expansion remain unverified.


## Refined woodland pines

Pinehall's 37 trees now use small, deterministic branch clusters instead of fourteen broad foliage slabs. Six uneven radial boughs per tier, smaller side clusters, visible lower twig pieces and connected tapered tips create a less uniform silhouette. Tree sites, heights, terrain alignment and solid trunks remain unchanged; foliage stays decorative. All pieces use existing batched pine/timber materials, with no new textures or per-tree processing.

The generator uses a local seeded random source, so rebuilding the forest is reproducible without consuming gameplay randomness. Each tree remains within a 650-piece cap and a height-relative footprint. Final foliage uses 15,455 pieces; replacing 518 old slabs adds 14,937 net blocks, bringing world batches to 351,080. This count is not an M1 performance result.

153 checks passed: woodland_pine 111, pinehall_detail 23 and pinehall_terrain 19. Coverage includes reproducibility, geometry budget/footprint, walking lanes, hill climbing and saves. Native Mac views were inspected and a visible gap beneath the treetops was corrected before the final capture. See build/pinehall-forest-rise.png.
