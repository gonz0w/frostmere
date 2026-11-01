> Historical development record. Live work moved to [GitHub Issues](https://github.com/gonz0w/frostmere/issues) on November 1, 2026. Earlier counts, priorities, unchecked lists and build links below are retained as dated evidence, not current assignments. See [project policy](../PROJECT.md).

# Campaign pacing review

## Navigation pass implemented

The prior HUD had home-world guidance for the council, coast and observatory but omitted several other handoffs. It also withheld the observatory suggestion until the coast was complete, despite the observatory's actual gate requiring only Pinehall's archive chapter. A read-only campaign guide now covers every later main route and exposes the parallel branches.

| Completion | Available next directions |
| --- | --- |
| Stonewake | Wyrmkeep, Pinehall, Stag Shrine |
| Council | Ember Caldera, alongside remaining open branches |
| Archive | Saltbreak and Sunken Lens, alongside remaining open branches |
| Roots, tides, lens and choir | Mirewatch expedition preparation |
| Convergence | Sunken Lens trail, then the northern transit vault |
| Space expedition | Aeralis gate in Frostmere |
| Aeralis return | Winter garrison |
| Winter Siege | Wardworks / Broken Seal |
| Broken Seal with all realm prerequisites | Crucible gate |
| Last Furnace | Existing homecoming / free exploration objective |

Accepted unfinished work is suggested first; other branches remain optional in order. HUD alternatives are capped for readability, with a remaining count; the map footer lists all open main paths. Each open chapter's journal entry provides directions from Frostmere. A manual walking waypoint takes precedence over the new home guidance. Once inside a chapter, its own current objective remains in place, except the completed observatory gains transit-vault directions when the space crossing is next.

The guide derives suggestions without accepting quests, modifying completions, moving players, granting items or changing save fields. The first dungeon and Stonewake retain their existing detailed guidance. Gate behavior is unchanged. The guide tolerates the map being constructed before realm controllers during startup.

## Remaining pacing work

This pass addresses navigation gaps, not measured campaign duration. Next review combat difficulty and resource availability along the normal first-dungeon-to-expedition path, including different character builds, crafting supply use, optional detours and post-realm equipment. A human, timed campaign playthrough and broader consequences for faction choices remain open. The atlas quest implementation list is now complete; see ROAD_QUESTS.md.

## Supply preparation pass implemented

The workstation previously required a separate action for every stack of twelve arrows, forty rounds, potion or refining batch. Five- and ten-batch controls now reduce this preparation time without changing ingredient prices, output ratios or XP. Fourteen stackable recipes support bulk preparation; the two story components remain single-craft. No partial batch executes when supplies are short.

This is a usability improvement, not a combat rebalance. Finite chapter supply caches and how players can recover after spending shared materials on optional equipment remain subjects for the resource-availability review.

## Emergency story-component recovery

If optional upgrades leave you unable to afford a required component, revisit the chapter supply chest after learning its design and collecting the original supplies. Mirewatch offers a Transit Regulator rebuild from dedicated spare parts; the wardwright's chest offers a Cinder Ward rebuild. The option appears only while the objective is unfinished, no component is owned and normal crafting is unaffordable. When ordinary ingredients are sufficient, use the forge as before.

A rebuild grants exactly one component and no raw materials, gold or crafting XP. These components cannot be sold or used in other recipes; the ordinary installation/binding action consumes them. Owning one or completing the objective removes the recovery option. The Cinder Ward still requires defeating the Sealbreaker before binding. Blueprint/evidence gates and original supply rewards remain intact. Recovery uses existing material inventory and saves without new fields.

## Starting melee and barrow-supply baseline

A runtime-stat audit covers the eight starting playstyles with Frostkin ancestry, unspent attribute points and no upgrades/perks. The starter rogue's ten-damage dagger previously shared the sword's 0.62-second interval: about 16.1 theoretical basic melee DPS against the warrior's 25.8. Daggers now use a 0.38-second interval and six stamina, yielding 26.3 DPS at that baseline. Measured Swing reduces dagger cost to four; other melee weapons retain their existing timings and nine/six stamina costs. Damage per hit, critical chance, charged attacks and finishers are unchanged. This applies to all main-hand daggers; higher-tier builds still need playtesting.

The iron-bow baseline requires 29–32 successful arrows across the seven barrow defenders before training, crits or upgraded loot. Edda supplies 30 arrows; looting the six ordinary defenders adds 36, and the optional alcove adds 12. Healing is three draughts from Edda plus one from each ordinary defender. These supplies were left unchanged: the audit found no reason to increase them before testing actual miss rates, potion use and player behavior.

Regenerate build/early-combat-baseline.md with the local Godot engine in headless mode using --script tools/audit_early_balance.gd. The report lists HP, armor, melee timing/cost, unblocked Captain hits to defeat and ideal arrow counts. It is a numerical baseline, not a timed playthrough or a claim of balanced difficulty across all ancestries and builds.

## Staff upgrade progression

The next equipment review found that staff damage, including tempering, did not affect actual casts. Equipped main-hand staves now contribute floor(tempered base damage / 2) to spell power before Kindled Mind. Every temper rank adds one spell power before perks. This makes forge investment matter for caster builds as well as physical weapons; innate attributes, enchantments and gems still apply normally. Focus items continue to use their existing attribute bonuses.

The workshop explains both current staff contribution and the next rank's magic benefit. No save migration is needed: power is derived from existing owned gear. Spell unlocks, costs, cooldowns and multi-target rules remain intact. The new contribution also strengthens ordinary staves: an otherwise unequipped Frostkin mage goes from 59 power without a staff to 67 with an ordinary Iron Staff, and 72 at Legendary. This is a deliberate caster equipment buff, not just a tooltip correction.

Regenerate build/staff-combat-baseline.md with --script tools/audit_staff_balance.gd. The report covers all eleven staff designs at ordinary and Legendary quality using runtime spell scaling. Later rewards are not universally stronger than earlier specialized gear; broader encounter and reward progression still need review. Numerical reports do not replace timed human playthroughs.

## Later reward progression

Equal-quality comparisons found four later designs below comparable earlier gear. Base damage is now Skybreaker 38 (was 31), Starweaver Rod 32 (was 22), Dawnforged Bow 30 (was 25), and Dawnforged Staff 32 (was 24). These changes give the Aeralis greatsword/staff and the final bow/staff a stat advantage over their selected earlier counterparts at every matching quality. Innate bonuses remain intact; earlier specialized or more heavily tempered gear can still be useful.

Run --script tools/audit_reward_progression.gd to regenerate build/reward-progression.md. It checks six qualities for each of four comparisons using runtime damage or spell power, with Frostkin ancestry and the matching berserker, ranger or mage playstyle. Existing realm loot quality, enchantment and favorite protection, finale choices, recipe costs and enemy stats remain unchanged. Existing owned copies inherit the catalog adjustment without save migration. This targeted reward correction does not establish balanced monster encounters; the next pass should examine monster survival and attack pressure against post-realm builds.

## Furnace Maw retaliation window

The final guardian previously remained equally vulnerable throughout its long rupture recovery, allowing automatic weapons to apply uninterrupted damage. Heat shutters now multiply incoming damage by 0.6 while closed and 1.35 during a 2.5-second opening after a resolved rupture, in addition to the existing boss multiplier of 0.8. Dodging the locked circle still triggers the opening. This makes damage during the opening 2.25 times as effective as damage through closed shutters; players can save ammunition or stronger attacks for it.

Two visible shutters cover the furnace mouth while closed and separate during exposure. Enemy labeling and encounter feedback call out the opening. Warning duration, rupture damage, half-health cadence, health (340), loot and ending gates remain intact. All ordinary damage types share the rule; eligible executions bypass the shutter multiplier so fatalities remain lethal. Pausing, leaving the realm, death and execution lock clear the pending warning and exposure. The window is transient combat state and adds no save fields.

This is a targeted final-monster timing change. Automated checks verify actual incoming damage, dodge-triggered exposure, expiry, interruptions and the real finisher/loot path. Human playtesting with different gear and accuracy remains necessary to judge total fight length; the Aeralis guardian and other post-realm encounters remain candidates for further review.

## Prismwing close-range second phase

Wing fracture previously reduced Prismwing's projectile fan without adding close-range pressure. After its existing fracture stagger/recovery, the wyrm now chooses a bite when the player is within 4.5 meters. It draws its head back and raises its remaining wings for a 0.9-second warning, locking its horizontal direction. Resolution requires the player to remain within 3.8 meters, inside a 120-degree forward cone, within 2.5 meters vertically and visible through a clear collision ray. A hit deals 32 raw damage through ordinary player defenses; the bite has 2.4 seconds of recovery and a brief head snap pose.

Sidestepping, retreating or moving behind the committed direction avoids the attack. The ranged fan remains three bolts after fracture and five before; the initial fracture opportunity and 240 health remain unchanged. Pause, travel, stagger and execution cancel the warning. No gear, reward, chapter gate or save fields changed. This adds a distinct second-phase melee threat; human fight-length and difficulty testing remain open.

## Incoming-impact readability

Accepted incoming hits now produce a brief directional marker around the aiming reticle. It points toward the latest impact location relative to current player facing, updating as the player turns. Red HIT/GUARD BROKEN, gold BLOCK and green PARRY labels distinguish outcomes without relying on color alone. The cue lasts 0.9 seconds and fades over the final quarter-second. A source with no horizontal bearing displays only its outcome.

This gives players feedback when enemies hit from outside their view without exposing unseen enemies before they attack. Invulnerability-rejected damage does not replace the cue. Menus and death clear it; it adds no save state. Existing armor, guard, stamina and parry rules are unchanged. Multiple impacts replace the marker with the latest accepted one; this is not an enemy tracker. Broader multi-enemy encounter playtesting remains open.

## Optional Mirewatch salvage rescue

Lights Beneath the Boards adds a short exploration/dialogue detour while preparing the station expedition. It uses the existing Mirewatch travel gate but does not require accepting or advancing the expedition. The rescue consumes no shared ingredients and awards 90 gold, six crystals, four rune dust and two healing draughts once. These rewards supplement optional upgrades without replacing the main chapter's supplies or required-component recovery. The west-deck route is physically traversable; human quest-duration measurement remains open.


## Station supplies for existing builds

The station’s two caches previously supplied rifle ammunition but no arrows or magicka draughts. The emergency locker now adds 36 arrows and two magicka draughts; the cargo cache adds 24 arrows and one draught. Both remain one-time claims, and already-collected caches do not refill after an update. Existing rifle rewards, recipes, enemies and chapter gates are unchanged. Dialogue lists the new supplies.

A runtime equipment audit covers six bow/quality combinations against the five 100-HP troopers and 380-HP Hullcarver. A Superior Steel Longbow requires 30 ideal hits with exposed-core boss hits or 43 through the closed shell, leaving 17 misses within the 60-arrow cache budget in the latter case. An ordinary Iron Longbow uses all 60 if it never exploits exposure. These are conservative single-target hit budgets without criticals, training or finishers, not measured player accuracy or encounter duration. Three draughts restore up to 150 magicka. The reserve supports existing playstyles without requiring the rifle; players can still bring supplies, craft or return home.

Regenerate build/station-supply-baseline.md with --headless --path . --script tools/audit_station_supplies.gd. Threshold 68, staff scaling 100 and crafting 201 checks passed (369 total). New coverage verifies exact reserves, remote/duplicate rejection, live save reload and actual draught consumption. Native Mac engineer dialogue inspected. Human campaign-duration and resource-use testing remain open.


## Arrival reserves for existing builds

Aeralis attunement now adds 36 arrows and two Magicka Draughts; Crucible attunement adds 48 arrows and three draughts. The normal arrival-crystal interaction announces the exact reserve. Existing spells, equipment, materials and the Crucible’s 160 Infernal Rounds are unchanged. Supplies use the existing one-time attunement flags: duplicate interactions, revisits and reloads cannot refill them. Older saves that already claimed attunement do not receive a catch-up refill.

The runtime audit in tools/audit_realm_supplies.gd produces build/realm-supply-baseline.md for twelve realm/bow/quality combinations. A Superior Steel Longbow needs 16 ideal hits across Aeralis’s two sentries and guardian, and 18 hits against the Crucible’s enemies when exploiting the Maw’s exposure or 31 through closed shutters. The ordinary Iron Longbow leaves only two missed shots within the Crucible’s 48-arrow reserve if every boss hit lands against closed shutters. These are per-target rounded hit budgets with no criticals, training, enchantments or finishers, not human accuracy or timed fight results. Potion reserves restore up to 100 and 150 magicka respectively.

realm_supplies 30, realms 38 and staff_scaling 100 checks passed: 168 total. Coverage includes physical crystal interaction, exact additions, preserved Infernal Rounds, real bow firing, real potion use, used-inventory saves, revisits and old claimed-save compatibility. No save migration or release package. Winter Siege and Broken Seal resource pressure, plus timed campaign playtesting, remain next in the balance review.


## Recovery for spent siege repair stock

Spending the garrison’s original repair stock on optional upgrades could leave the ward or ballista unaffordable, while the failure message directed the player back to an already-claimed chest. After the scouts are cleared and the original stores have been collected, an unfinished, unaffordable defense now offers “Install the garrison’s fitted spare.” The spare repairs that defense directly and grants no raw materials, inventory item, gold or crafting XP. If ordinary costs are affordable, the fallback is unavailable. Normal repair prices are unchanged.

Existing repaired-defense flags prevent repeats and preserve the result in saves. Both defenses are still required before the assault. The ward’s one-time health/magicka restoration and the ballista’s existing combat effect follow the normal assault path. No new save fields or migration are needed. Broken Seal’s existing Cinder Ward recovery was regression-tested; no change was needed there.

winter_recovery 30, winter 55, seal 58 and story_recovery 35 checks passed: 178 total. Tests cover acceptance/scout/store gates, affordable versus spent stock, actual spare buttons, remote actions, exact no-reward behavior, saved repairs, duplicate prevention and the real assault transition. Native macOS fallback dialogue was inspected in build/winter-fitted-spare.png. General siege/underworks ammunition pressure and timed campaign difficulty still need review.


## Siege and underworks combat reserves

The existing reserved stores in both Winter Siege and Broken Seal now include 60 arrows and 120 Station Rounds. Winter adds two Magicka Draughts; Broken Seal adds three. Original steel, crystal, rune dust and Ash Glass quantities are unchanged, so these supplements do not spend the stock intended for defenses or the Cinder Ward. Supply descriptions list the additions. Existing acceptance, proximity and one-time claim flags apply; old claimed stores do not refill. Normal loot, enemies, crafting prices, the siege fitted-spare fallback and Cinder Ward recovery are unchanged.

The audit in tools/audit_defense_supplies.gd runs eight loadouts through live enemy receive_damage methods. It includes Winter’s actual 100-HP ballista reduction. A Superior Steel Longbow requires 36 ideal hits across the siege and 37 across Broken Seal. The original Fine Station Rifle needs 75 rounds in either chapter; 120 supplied rounds leave 45 misses in that ideal damage model. An ordinary Iron Longbow leaves only 5/3 missed shots within the 60-arrow reserve. These figures exclude criticals, training, other equipment, perks and finishers; they are not measured combat duration or player accuracy. Winter’s existing intermission ward already restores health and magicka; the added draughts provide limited in-fight support.

Report: build/defense-supply-baseline.md. Final checks: defense_supplies 42, winter_recovery 30, winter 55, seal 58 and story_recovery 35 = 220 passing checks. Coverage includes actual supply buttons, exact original and added supplies, real rifle/bow/potion use, saves, revisit/reload duplication prevention and earlier claimed profiles. The supply test normalizes JSON numbers to integers before comparing inventory quantities, matching the existing load behavior. Native Mac supply descriptions inspected in build/winter-combat-reserves.png and build/seal-combat-reserves.png. No release package produced.

The late-chapter ammunition reserve pass now covers the station, Aeralis, siege, underworks and Crucible. Timed campaign playtests, healing pressure and combat pacing across different builds remain open; this numerical supply review does not establish overall game balance.


## Healing supply feedback

Consumables now preview equipment-adjusted restoration, the amount that can actually fit in the current resource pool, and unused restoration. The existing 25% chest healing effect is included for health potions and food; stamina and magicka stay unchanged. Full-resource use is disabled in the workshop, while direct/hotkey use still keeps the item. Successful use reports actual restored health, stamina or magicka. The preview and consumption share one calculation; restoration values, enemy damage and potion timing are unchanged. Groveheart's item description now mentions its existing food benefit.

Healing preview 69, crafting 201, roots 85 and archive 52 checks passed (407 total). Tests cover all five consumables with and without healing armor, fractional caps, no-cost previews, full/empty bags, actual inventory use, UI refresh and save/reload of supplies/equipment. Native Mac capture also passed all 69 checks and was inspected at build/healing-preview.png. This resolves misleading healing information; it is not a timed encounter balance result. Human campaign playtests, healing demand across builds and combat pacing remain open.


## Cross-build healing and guard baseline

`tools/audit_healing_pressure.gd` now measures 72 live boss/build combinations: all eight Frostkin playstyles, three controlled equipment kits, and Prismwing's bite plus both Maw rupture phases. It calls the actual enemy attack methods and player damage/consumption paths, checks facing blocks and depleted-stamina guard breaks, and writes `build/healing-pressure-baseline.md` only after all checks pass. Starter gear, Exquisite versions of the same gear, and an Exquisite kit with Groveheart are comparisons, not assumed campaign acquisition paths. No allocated attributes or training/perks are included.

For an unblocked enraged Maw rupture, ordinary mage gear takes 46 damage and a 50-health potion replaces 1.09 hits. Exquisite versions of the same outfit take 31.72 damage, making a potion worth 1.58 hits. Warrior equivalents are 31.40/22.94 damage and 1.59/2.18 hits. The healing-vest kits further change armor, Endurance and potion capacity, so their result is not solely the 25% bonus. Guard spends 29.9 stamina against that attack regardless of armor; once stamina is depleted, the audit confirms full damage and guard recovery. These results support testing upgraded armor before changing raw boss damage. They do not establish fair difficulty or measured survival time.

Validation: audit 253 checks, combat 46, parry 20, Prismwing pressure 16, furnace pressure 16, healing preview 69: 420 total passing checks. Existing counterplay tests verify the locked bite direction, sidestep/range escapes, bite recovery, rupture dodge/exposure window and interruption handling. All fixtures isolate profile saves. No gameplay values, UI or release artifacts changed in this pass.

Next campaign pacing work should measure real encounter duration and supplies spent, including misses, looting and failed attempts. Record entering/leaving health, healing draughts consumed, deaths, equipment/quality and whether boss openings were used. Prioritize mage and ranger runs through the station, Aeralis and Crucible, then shield and dagger runs to examine the stamina cost of repeated guarding. Keep travel, menu and shopping time separate from active combat time. Human M1 performance and full campaign playthroughs remain outstanding.


## Opt-in combat playtest measurements

Added a local recorder enabled only with `--combat-metrics`, plus `tools/summarize_combat_metrics.py`. Actual gameplay hooks capture damage, kills, parries, spent ammo, melee/spell attempts and successful consumable restoration. Build and vitals snapshots accompany each segment. Death is recorded before respawn; menus and slow-motion scaling are excluded from the active clock. Ten-second inactivity, travel, death and normal shutdown close segments; inactivity is not labeled victory. Travel snapshots include the observed ending area. See COMBAT_PLAYTESTS.md for launch commands and measurement limits.

Metrics 21, combat 46, parry 20 and healing preview 69 checks passed (156 total). The summarizer was run against the three-record QA log; its report is synthetic test data. No human campaign measurements, balance changes or release package were produced. The next balance step is to gather comparable playtest recordings across actual campaign builds, then tune based on observed failures and supply use.

## Connected first-dungeon-to-homecoming audit

The three-build audit in `tools/audit_campaign_route.gd` now carries actual quest rewards, materials, finite purchases and progress through the entire main route without inserting prerequisite completion flags. It checks required crafting, normal realm gates, final heirloom claims and save acceptance at all 45 chapter boundaries. Combat uses a declared numerical model, not live attack inputs or enemy retaliation. Ranger resupply is affordable from finite stock; mage regeneration demand needs live comparison with earned perks, later spells and travel recovery before tuning. See `CAMPAIGN_PLAYTHROUGH.md` and the generated `build/campaign-route-audit.md` for results, limitations and the remaining hands-on matrix.
