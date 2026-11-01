# The Broken Seal

After completing Winter Siege, take the caldera service lift at `(12, 0, 34)` south of Frostmere. Wardwright Tovan waits in the underworks with supplies, a forge and an inscription bench.

## Playable investigation

1. Accept Tovan's investigation. Two outer enforcers activate.
2. Defeat each assigned enforcer and isolate its pressure valve. Both valves activate the two inner enforcers.
3. Defeat the inner enforcers and recover the shipping ledger. It teaches the Cinder Ward recipe and activates the Sealbreaker.
4. Forge a Cinder Ward at a real forge: 4 steel ingots, 4 crystals, 2 rune dust and 2 Ash Glass. Tovan's single-claim supply stock contains enough for two wards.
5. Defeat the Sealbreaker and bind one ward into the fractured containment seal. The crafted material is consumed once. The ward permanently protects the crossing as a story unlock, without occupying an equipment slot or providing a separate combat resistance effect.
6. Report to Tovan. This completes `broken_seal` and opens the northern crossing into the existing Crucible chapter in normal progression.

In the Crucible, attune to learn its equipment patterns and Soulfire, defeat all three defenders, loot the Furnace Warden, use the shutdown console on the final terrace, then return through the arrival gate to complete The Last Furnace. Infernal equipment remains usable at home. The return now includes an ending chronicle, a choice of heirloom and continued exploration. The realm remains a compact guardian chapter.

## Reward and collection

Reporting grants 220 gold, a favorited Superior Wardkeeper's Amulet of Vigor, its blueprint, and upgrade materials. The amulet has 2 base armor, +3 Endurance and +3 Intellect. It can be forged, tempered, enchanted and socketed through the existing collection systems. Its forge recipe uses the same quantities as the ward; high-rank tempering uses steel, crystal and Ash Glass.

The catalog now contains 133 equipment designs and 149 recipes: 133 gear, eleven material/refining/ammunition and five consumable recipes. Seventeen of 51 atlas quests are playable; 34 remain outlines.

## Save and preview behavior

Acceptance, supply claims, valves, ledger, ward binding, reward, defeats and loot claims persist atomically. Older saves receive untouched underworks progress. Invalid prerequisites, phase combinations, duplicates and field types are rejected before state is applied. Dead defenders and consumed rewards stay resolved on return; surviving defenders reset after leaving. Normal Crucible access still requires all three flags: Returning Light, Winter Siege and Broken Seal.

`Preview Broken Seal.command` launches an isolated late-story fixture with completed prerequisite records and Aeralis magic. Both character and atlas saving remain disabled throughout the session, including after entering and returning from the Crucible. Talk to Tovan to begin. E interacts; M opens the local map.

The underworks uses the existing northern exploration and battle audio, with the Crucible switching to its own tracks on entry. No new M1 benchmark or timed human pacing study was performed.

## Supply-shortage fallback

After learning the Cinder Ward design and collecting the original supplies, the supply chest offers a dedicated spare-parts rebuild if you lack both the component and enough ordinary ingredients. This produces one Cinder Ward without raw materials, gold or XP. Owning the component or finishing its installation removes the option. Use the existing quest action to install/bind it; other gates remain intact. No save-schema change is needed.


## Siege and underworks combat reserves

The existing reserved stores in both Winter Siege and Broken Seal now include 60 arrows and 120 Station Rounds. Winter adds two Magicka Draughts; Broken Seal adds three. Original steel, crystal, rune dust and Ash Glass quantities are unchanged, so these supplements do not spend the stock intended for defenses or the Cinder Ward. Supply descriptions list the additions. Existing acceptance, proximity and one-time claim flags apply; old claimed stores do not refill. Normal loot, enemies, crafting prices, the siege fitted-spare fallback and Cinder Ward recovery are unchanged.

The audit in tools/audit_defense_supplies.gd runs eight loadouts through live enemy receive_damage methods. It includes Winter’s actual 100-HP ballista reduction. A Superior Steel Longbow requires 36 ideal hits across the siege and 37 across Broken Seal. The original Fine Station Rifle needs 75 rounds in either chapter; 120 supplied rounds leave 45 misses in that ideal damage model. An ordinary Iron Longbow leaves only 5/3 missed shots within the 60-arrow reserve. These figures exclude criticals, training, other equipment, perks and finishers; they are not measured combat duration or player accuracy. Winter’s existing intermission ward already restores health and magicka; the added draughts provide limited in-fight support.

Report: build/defense-supply-baseline.md. Final checks: defense_supplies 42, winter_recovery 30, winter 55, seal 58 and story_recovery 35 = 220 passing checks. Coverage includes actual supply buttons, exact original and added supplies, real rifle/bow/potion use, saves, revisit/reload duplication prevention and earlier claimed profiles. The supply test normalizes JSON numbers to integers before comparing inventory quantities, matching the existing load behavior. Native Mac supply descriptions inspected in build/winter-combat-reserves.png and build/seal-combat-reserves.png. No release package produced.

The late-chapter ammunition reserve pass now covers the station, Aeralis, siege, underworks and Crucible. Timed campaign playtests, healing pressure and combat pacing across different builds remain open; this numerical supply review does not establish overall game balance.
