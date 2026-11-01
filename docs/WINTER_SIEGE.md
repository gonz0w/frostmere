# The Winter Siege

Playable after `returning_light`, through the Northwatch supply road at `(0, 0, 34)` south of Frostmere. Northwatch guards Ember Caldera's northern approaches and the supply route into the northern holds. Its restored watchstones have attracted the furnace invasion.

## Playable route

1. Speak with Captain Halla in the southern courtyard to accept the defense. Three scouts become active; later invaders stay hidden and noncolliding.
2. Collect the garrison's reserved supplies: 8 steel ingots, 6 crystals and 4 rune dust. Repel all three scouts.
3. Restore the ward with 2 crystals and 2 rune dust, and the ballista with 3 steel ingots. Repairs spend materials once, and insufficient materials spend nothing.
4. Return to Halla and sound the muster when ready. The ward restores health and magicka. The ballista reduces the Iron Marshal's starting health from 440 to 340. Two vanguard soldiers and the marshal become active.
5. Defeat the assault, recover the command satchel in the northern courtyard, and report to Halla. The orders point to the industrial passage beneath the caldera, setting up The Broken Seal.

The fort includes detailed lodges, snow-covered ridges, masonry, pennants, equipment racks, a forge, a rune table and a local map. Repairs illuminate their corresponding defense markers. Existing northern exploration and battle music applies.

## Collection and upgrades

Victory grants 240 gold, a Superior Northwatch Helm of Vigor, a Superior Northwatch Greatsword of Fleet, the Northwatch blueprint family and additional steel/crystal/rune dust. Both rewards are favorited. The helm has 8 base armor and +3 Endurance; the greatsword has 30 base damage and +4 Strength. They use the existing modular steel visuals with an icy tint.

Each pattern costs 4 steel, 3 crystals and 2 rune dust at a forge. Tempering consumes steel and crystal, with rune dust added at higher ranks. Both support the normal enchanting, socketing and collection systems. Invaders offer finite, single-claim steel and crystal loot.

## Persistence and scope

The chapter saves acceptance, supplies, repairs, assault activation, orders, reward, defeats and loot claims. Old saves receive untouched siege progress. Validation rejects impossible phase combinations, duplicates and invalid types before applying state. Leaving or dying preserves earned progress; surviving invaders reset, including the ballista's permanent 100-health advantage against the marshal.

This is a compact two-wave defense encounter. Allied combat AI, destructible fort health, repeatable siege farming and a timed failure condition are not implemented. The Broken Seal is now playable and remains required for normal Crucible entry.

Double-click `Preview Winter Siege.command` for an isolated late-story fixture with completed prerequisite records and Aeralis magic. Character and atlas saving remain disabled for the entire preview session.

The prototype now contains 133 equipment designs, 149 recipes and 17 playable atlas quests out of 51. No new M1 benchmark or human pacing study was performed.


## Recovery for spent siege repair stock

Spending the garrison’s original repair stock on optional upgrades could leave the ward or ballista unaffordable, while the failure message directed the player back to an already-claimed chest. After the scouts are cleared and the original stores have been collected, an unfinished, unaffordable defense now offers “Install the garrison’s fitted spare.” The spare repairs that defense directly and grants no raw materials, inventory item, gold or crafting XP. If ordinary costs are affordable, the fallback is unavailable. Normal repair prices are unchanged.

Existing repaired-defense flags prevent repeats and preserve the result in saves. Both defenses are still required before the assault. The ward’s one-time health/magicka restoration and the ballista’s existing combat effect follow the normal assault path. No new save fields or migration are needed. Broken Seal’s existing Cinder Ward recovery was regression-tested; no change was needed there.

winter_recovery 30, winter 55, seal 58 and story_recovery 35 checks passed: 178 total. Tests cover acceptance/scout/store gates, affordable versus spent stock, actual spare buttons, remote actions, exact no-reward behavior, saved repairs, duplicate prevention and the real assault transition. Native macOS fallback dialogue was inspected in build/winter-fitted-spare.png. General siege/underworks ammunition pressure and timed campaign difficulty still need review.


## Siege and underworks combat reserves

The existing reserved stores in both Winter Siege and Broken Seal now include 60 arrows and 120 Station Rounds. Winter adds two Magicka Draughts; Broken Seal adds three. Original steel, crystal, rune dust and Ash Glass quantities are unchanged, so these supplements do not spend the stock intended for defenses or the Cinder Ward. Supply descriptions list the additions. Existing acceptance, proximity and one-time claim flags apply; old claimed stores do not refill. Normal loot, enemies, crafting prices, the siege fitted-spare fallback and Cinder Ward recovery are unchanged.

The audit in tools/audit_defense_supplies.gd runs eight loadouts through live enemy receive_damage methods. It includes Winter’s actual 100-HP ballista reduction. A Superior Steel Longbow requires 36 ideal hits across the siege and 37 across Broken Seal. The original Fine Station Rifle needs 75 rounds in either chapter; 120 supplied rounds leave 45 misses in that ideal damage model. An ordinary Iron Longbow leaves only 5/3 missed shots within the 60-arrow reserve. These figures exclude criticals, training, other equipment, perks and finishers; they are not measured combat duration or player accuracy. Winter’s existing intermission ward already restores health and magicka; the added draughts provide limited in-fight support.

Report: build/defense-supply-baseline.md. Final checks: defense_supplies 42, winter_recovery 30, winter 55, seal 58 and story_recovery 35 = 220 passing checks. Coverage includes actual supply buttons, exact original and added supplies, real rifle/bow/potion use, saves, revisit/reload duplication prevention and earlier claimed profiles. The supply test normalizes JSON numbers to integers before comparing inventory quantities, matching the existing load behavior. Native Mac supply descriptions inspected in build/winter-combat-reserves.png and build/seal-combat-reserves.png. No release package produced.

The late-chapter ammunition reserve pass now covers the station, Aeralis, siege, underworks and Crucible. Timed campaign playtests, healing pressure and combat pacing across different builds remain open; this numerical supply review does not establish overall game balance.
