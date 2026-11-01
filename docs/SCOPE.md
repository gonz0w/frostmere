> Historical development record. Live work moved to [GitHub Issues](https://github.com/gonz0w/frostmere/issues) on November 1, 2026. Earlier counts, priorities, unchecked lists and build links below are retained as dated evidence, not current assignments. See [project policy](../PROJECT.md).

# Agreed direction

Current quest status: **51 playable quests; zero planned quest outlines remain.** The final seven are documented in ROAD_QUESTS.md. Later entries below record the implementation history; their remaining counts are historical. World expansion, polish and release work are separate.

- Mac only: M1 / 32 GB baseline; M5 / 128 GB higher settings.
- Single-player Skyrim-inspired RPG with original world content.
- Refined voxel art matching the approved concept: blocky characters, buildings, trees, and landscape. Halve the initial prototype’s visible detail spacing while preserving world/object size and old-school square silhouettes.
- Switchable first-person and third-person play.
- Handcrafted, fixed world. No Minecraft-style terrain editing or construction. A small player building area may be considered later.
- Exploration, quests, melee / ranged / magic combat, loot, use-based skills and perks.
- Smithing, equipment upgrades, alchemy, enchanting, cooking.
- The Nordic world remains the primary setting and home base. Later main-story chapters require travel to a Duke Nukem-inspired space setting, a Final Fantasy-inspired fantasy setting, and a much later Doom-inspired Hell mini-world. These are supporting adventures within the main timeline, not replacement main themes.

<a id="current-remaining-roadmap"></a>

## Historical roadmap snapshot

**Current checkpoint:** the presentation/performance #4 implementation pass is ready at `build/presentation-review/index.html`; see [PRESENTATION_REVIEW.md](PRESENTATION_REVIEW.md) for its remaining hardware/playtest limits. Previously, creature review #1 and equipment/character review #2 are user approved. The regional buildings and realm backgrounds are implemented. The wider towns/landscape pass is now implemented for the current regions and ready at `build/landscape-review/index.html`: 26 matched before/after views across 12 regions and destinations. See [LANDSCAPE_REVIEW.md](LANDSCAPE_REVIEW.md). This is a visual review checkpoint, not closure of world/encounter expansion, campaign testing or M1 performance work.

This section tracks remaining work; the milestone notes below are implementation history. Completing the 51 quest implementations does not complete the game’s visual or world-production work.

1. **Major visual-detail and asset pass — in progress, required before the next release.** Initial construction passes now cover all current weapon families, armor/hands and the full current creature roster (user approved), with the named equipment, character faces and armor-fitting pass also user approved. The regional building and town/landscape passes are ready for review; the refined riverbanks are retained. Use the original approved concept as the quality target and substantially refine bosses/creatures, armor, weapons, characters, architecture, vegetation, terrain and props across every world. This is a substantial art milestone, beyond the earlier half-size voxel and individual animation passes. See [VISUAL_DETAIL_ROADMAP.md](VISUAL_DETAIL_ROADMAP.md) for priorities and completion criteria.
2. **Campaign playtesting and balance — in progress.** Continue live encounter pressure, equipment/crafting progression, resource availability, faction outcomes and timed human playthroughs. Automated campaign and combat fixtures provide partial evidence; they do not close human pacing or difficulty review. See CAMPAIGN_PLAYTHROUGH.md.
3. **World and encounter expansion — open.** Develop fuller destination chapters, richer and less regular towns, varied regional landscapes, more monstrous enemies and bespoke creature finishers. Coordinate their final models and scenery with the visual-detail pass.
4. **Presentation and performance — in progress; current pass ready for review.** Refined and batched opening, responsive captions/quiet prelude HUD, priority sound allocation and shared slam debris are implemented. Native camera/effects/dialogue review, audio samples and M5 movement/group-combat evidence are in [PRESENTATION_REVIEW.md](PRESENTATION_REVIEW.md). M1, extended human sessions, subjective presentation approval and the rare frame-time spike remain open.
5. **Release and later platforms — deferred until requested.** Finish the roadmap before preparing another release. Keep implementation portable; Windows/Linux work follows the Mac work and is not part of this art pass.

## Later destination chapters

Aeralis and the Crucible now have compact playable arrival/guardian chapters connected through the station expedition, Winter Siege and Broken Seal. All destinations retain the approved refined voxel art style, single-player play, switchable cameras, and shared character progression. Inspiration guides tone and visual direction; the game's locations, characters, and lore will be original.

| Destination | Agreed inspiration | Proposed direction to develop |
| --- | --- | --- |
| Space world | Duke Nukem-inspired sci-fi action in space | Industrial stations, alien threats, gritty environments, exaggerated action and irreverent humor. A substantial expedition with a required story objective and optional local adventures. |
| Aeralis | Final Fantasy-inspired fantasy | Floating crystal terraces, ivory pavilions, airship scenery, Starfall magic and the Dawn Prism. |
| The Crucible | Doom-inspired Hell mini-world | Industrial lava platforms, the Furnace Warden, Soulfire and portable automatic weapons. Much later in the campaign. |

### Story structure

- Seed evidence of other worlds in the Nordic adventure before travel becomes available.
- Give each trip a concrete reason within the main timeline; required destination chapters must not be presented as wholly optional side quests.
- Each world should feel like a large, self-contained adventure chapter, with its own local problem, characters, exploration, and payoff.
- Return to the Nordic world after each expedition, carrying story consequences and selected rewards forward.
- Keep the primary world's identity intact. Realm equipment, spells, machine guns and crafting upgrades remain usable back home.

### Not yet decided

Watchstone gates connect Aeralis after the space expedition, then the Crucible after a home-world siege and broken seal. Automatic guns are now supported. Full chapter scale, optional quests, party combat and space-flight systems remain open. See REALMS.md for the implemented slice and exact unlock rules.

## Milestones

1. **Walkable visual prototype** — a Nordic scene, character movement, camera switching, collision, pause UI, and measured rendering checks.
2. **Combat test** — one enemy, sword/shield, damage feedback, death/reset; then bow and one spell.
3. **Adventure loop** — village NPC, quest, dungeon encounter, loot and return.
4. **Equipment and smithing** — inventory, equipping, material costs, one useful upgrade, save/load.
5. **Art and performance** — production-quality modular voxel assets, improved lighting/water, atmosphere/audio, profiling on both user machines.
6. **Destination chapter planning** — establish the story connection, travel rules, and one small arrival-area prototype for each later world after the core Nordic adventure loop works.

The first village-to-dungeon slice proves the RPG loop before we expand the map. No full Skyrim-scale world is assumed in the prototype.

## Character and equipment milestone

The prototype now includes eight initial original ancestries, eight unrestricted starting playstyles, six attributes with a ten-point allocation budget, nine equipment slots, and 145 equipment designs obtainable through forging and loot. A character screen with live preview, modular gear in both camera modes, and a local character-profile save supports experimentation. Movement, sprint cost and resource limits use derived stats; weapon damage, armor and spell power now drive combat; Presence affects merchant prices; Agility drives weapon critical hits. See `CHARACTERS.md`. The initial choices can expand as the world and story develop.

## Regional world direction

The user wants mountain ranges, strongly varied landscapes, towns and many side quests and primary quest lines, including groups that the player can join as clans or cults. The first proposed home-world atlas has eight regions, sixteen settlement/landmark sites, and seven factions. Ten main-timeline chapters, seven three-chapter faction arcs, and seventeen side-quest entries provide initial story structure. Names, counts and boundaries are a starting design, not final content limits.

Frostmere, its survey and barrow quests, Stonewake (the first main chapter), plus the two isolated realm previews are playable. Wyrmkeep, The Divided Council and two rival Iron Pact clan paths through the first promotion are also playable. Pinehall and The Missing Atlas are playable, including a Lantern/Coven custody choice and three equipment effects. Saltbreak and The Wreck on the Black Shore are also playable, with relic restoration and a permanent power-core choice. The Sunken Lens observatory, three mirror puzzles and the piercing Sunlance spell are now playable as well. Other towns and faction chains remain planned. This milestone adds an interactive map, local waypoints and persistent survey progress without constructing a continent-sized 3D world. See `WORLD_DESIGN.md`.

The collection/crafting milestone is playable: owned item instances, 161 recipes, gathering, tempering through Legendary, ten attribute enchantments, learn-by-disenchanting, three removable gem types, protected favorites, salvage, potions, cooking and a collection journal. See `CRAFTING.md`.

The first combat/adventure loop is playable: Edda’s quest, three barrow chambers, melee guards, archers, Ember Acolytes, the Watch-Captain, authored loot, a named upgradable sword and a return-to-smith recipe reward. See `ADVENTURE.md`.

Three staffed shops now support purchases, sales, gold and persistent original-item buyback. All four village buildings and the fortress exterior have another geometry detail pass; shop interiors remain accessible. See `SHOPS.md`.

## Requested next gameplay and world passes

After saved equipment loadouts, develop these user-requested features:

1. **Charged power attacks — two moves implemented:** Whirlwind uses a damage/parry meter, G activation, a 360-degree melee strike and 1.2 seconds of slow motion. Third person spins the body; first person sweeps the weapon with a steady camera. Shift+G now uses Sundering Strike: a forward cone with five-meter reach, triple weapon damage and stagger. Further moves and timing/balance refinement remain open.
2. **Finishing moves — weapon pass implemented:** X selects six named melee-family moves with dagger thrust, sword sweep and overhead crushing motions, family-specific timing, and stone fragments for the colossus. Weak-target requirements and normal defeat/loot handling remain intact. Full dismemberment, bespoke creature execution choreography and presentation refinement remain open.
3. **Populated wilderness — first pass implemented:** thirteen fixed encounters on Frostmere outer routes: six wolves, five boars, a 4.5-metre colossus and Rimefang, a giant tusked quadruped. Habitat limits, village/bridge safe zones, harvesting and saved defeat/session state are supported. More regions, species, density tuning and stronger creature animations remain open.
4. **Terrain elevation — first pass implemented:** three raised landforms on the western, eastern and northwest routes, with winding paths, walkable slope collision and terrain-aligned trees and creatures. Larger valleys and further vertical-route expansion remain open.
5. **Natural town layouts — Frostmere first pass implemented:** six enterable buildings with staggered placements, curved lanes, a well-centered green, market stalls, gardens, firewood and seating. Existing village shops and quest services stay reachable. Other towns and more varied building orientations remain open.

All five requests now have a first playable implementation. Each remains open for broader content, art and balance refinement. The earlier side-quest-loot backlog now includes The Mossbound Oath, an optional market-board hunt with two original equipment designs, a choice reward and both forge patterns. The colossus now has a telegraphed area slam and a stronger half-health phase, providing the first distinct optional-boss pattern. Further unique hunts and optional encounters remain open.

## Boss direction — monster-first

Favor large monstrous creatures over humanoid bosses across the Nordic wilderness, settlement-related quests, side quests, space, Aeralis and the Crucible. People remain useful as quest-givers and faction characters. Apply this direction to new encounters and future redesigns; existing humanoid guardians have not all been converted.

Creature backlog (status marked below):

- Nordic routes and town contracts — first implementation complete: Rimefang, a huge tusked frost beast with a committed charge, recovery window, harvest materials and a market-board hunt awarding equipment patterns.
- Space expedition — first implementation complete: the eight-legged Hullcarver Broodmother replaces the command-deck humanoid boss, with an armored shell, timed exposed-core phase and the existing station salvage/named blade reward.
- Aeralis — first implementation complete: Prismwing replaces the humanoid guardian with a crystal-winged quadruped, telegraphed fan volley and half-health wing fracture, retaining the realm guardian rewards.
- Crucible — first implementation complete: the horned six-legged Furnace Maw replaces the humanoid guardian with a targeted ground rupture and stronger half-health attacks, retaining infernal rewards and the engine-shutdown ending.

Each should have a distinct silhouette, combat pattern and collectible reward. Place town-linked encounters outside safe service areas so merchants and quest access remain usable. The Nordic beast and space Broodmother are now playable; Aeralis now has Prismwing as well; the Crucible now has the Furnace Maw. All three destination guardians have their first monster pass.

## Clan progression update

A Crown of Separate Holds is now a playable Iron Pact capstone for either mountain clan. Shieldbearers accept a monster road-defense commission, recover two existing monster proofs and choose shared patrols or a central leader. Completion grants Clan Voice rank and the forgeable Clan Voice Signet. Reputation, supply rewards and the recorded mandate are implemented; patrol simulation and broader political consequences remain open. The atlas has 27 remaining quest outlines.

## Platform strategy

Keep Mac as the development and release target during the roadmap. Windows and Linux ports are deferred until the game is finished. Preserve portability now: isolate launch/packaging code, use Godot platform APIs and user-data paths, keep resource filename casing exact, and assess new native dependencies/rendering features for future desktop support. No parallel Windows/Linux release effort is planned yet.

## Veiled Lantern initiation

The Uncatalogued Door is now playable after The Missing Atlas: testimony investigation, a physical archive-seal trial, and an explicit oath to become a Lantern Witness. Either prior atlas custodian is supported. The initiation grants the forgeable Witness Pendant and preserves prior custody consequences. The two later Lantern chapters remain planned. There are 32 remaining atlas quest outlines.

## Dark opening sequence — first playable pass

Ash Through the Snow now starts new characters on a snowbound road outside Frostmere. Walk to a ward lantern, inspect it, witness a huge horned silhouette beyond a glowing barrier, then reach the arch and continue to Edda. Drifting ash, cold fog, a flickering lantern, pulsing ward and the existing ominous Crucible score foreshadow the later storyline. Original sign text and Edda's greeting connect the arrival to the village.

Tab skips the sequence. Legacy saves bypass it; incomplete openings restart without saving off-map coordinates. Preview Dark Opening.command runs an isolated character with persistence disabled. This is a short first playable pass, not a finished cinematic: bespoke intro music, voice acting, richer road scenery and creature choreography remain open. See INTRO.md.

## Lantern second chapter

Names Beneath the Water is now playable: three physical Mirewatch records, a northern evidence gate tied to the existing expedition beacon, return to Mereth, and public-versus-sealed testimony resolution. Either outcome grants Recordkeeper rank and a choice-exclusive upgradeable ring pattern. Dialogue/journal and rewards reflect the decision; broader NPC consequences remain open. The Price of Knowing remains the next Lantern chapter. The atlas now has 31 remaining outlines.

## Humor and character voice — ongoing polish

Include fun and dark humor throughout the story, using original memorable lines and occasional callbacks. The first dialogue pass covers Edda, Runa, Hadrik, Sera, Mereth, Aelin, Rook and Ilyra. Keep distinct voices and practical in-world jokes, preserve clear objectives, and leave serious testimony room to land. See DIALOGUE_TONE.md. Merchant banter now has a first contextual pass; optional conversations and further callbacks remain open.

## Lantern capstone

The Price of Knowing is now playable after the testimony decision. Consult Mereth and Aelin, decide sealed study/public copying/shared oversight at the existing archive seal, and earn Keeper rank plus the Lantern Keystone pattern. All three Lantern chapters now have compact playable implementations. The choice affects dialogue, recorded policy and material rewards; broader political simulation and cross-faction lockouts remain open. Thirty atlas quest outlines remain.

The Grove That Refused Spring is now the first playable Briar Coven initiation. Restore three settlement seedbeds after the woodland chapter, then take a shelter or medicine oath with Maelin to become a Seedkeeper and learn the Seedkeeper Charm pattern. Both prior woodland pacts remain valid. Later Coven chapters and simulated oath consequences remain open; see `COVEN.md`.

A Debt of Sap and Stone is now a compact playable Coven second chapter. Investigate the lodge and spring, negotiate with Oren and Maelin, then fund one of two visible repairs and earn the Pactmender Ring. The Last Old Promise now has a playable finale. Repairs are decorative; ongoing settlement maintenance and water simulation remain future work.

The Last Old Promise completes the Coven's first playable three-chapter arc: hear the keepers and woodland memory, then renew the protections or adopt a shared charter. Rootwarden rank grants the forgeable Old Promise Talisman. Prior woodland and Lantern choices remain intact; policy consequences currently appear in dialogue and rewards. The next expansion priorities include remaining faction chapters, monster encounters and further dark-intro and world polish.

## Hollow Warden monster pass

The Stag Shrine's Hollow Warden now uses a large four-legged bark-and-root body, branching antlers and root eruptions. The 300-health roots_3 guardian, three-root gate, named bow loot and woodland/Coven progression remain intact. A pale 2.6-meter warning circle locks onto the player's location for 1.5 seconds; step clear before roots erupt. Half health increases raw damage from 28 to 38 and shortens recovery from six to four seconds. Menus, travel, staggers and finishers cancel pending attacks. This is a first creature/attack pass, with further animation and encounter tuning still open.

## Hull Warden coastal monster pass

Saltbreak's wreck guardian is now a six-legged crab with heavy claws, shell plates and barnacles. It retains the shore_6 identity, 340 health, salvage rewards and core gate. A 1.4-second claw windup locks the aim of three pale brine projectiles. After firing, the shell opens for 2.5 seconds: incoming damage uses a 1.4 multiplier instead of the closed shell's 0.8, before existing boss mitigation. The recovery window affects the whole creature rather than requiring a precise shell hit. Menus, travel and execution locks cancel the pending volley; staggers interrupt windup. Shell-colored finisher fragments complete the first pass. Further animation, balance and richer coastal encounters remain open.

## Dissonant Cantor creature pass

The volcanic archive guardian is now a large six-legged ash cicada with stone wing plates and a glowing throat. The choir_4 identity, 340 health, receiver gate and quest rewards remain intact. Its 1.5-second inhale marks an eight-meter boundary, then sends a low ring outward at seven meters per second. Retreat beyond the boundary or jump over the passing wave. Each wave hits at most once, checks line of sight and ignores feet at least 0.85 meters above its origin. Raw damage rises from 30 to 40 below half health, and recovery shortens from six to four seconds. Menus, travel, staggers and execution locks cancel the song. Further model/animation polish and encounter tuning remain open.

## Meridian Keeper creature pass

The Sunken Lens guardian is now an eight-legged bronze-and-stone scorpion with pincers and a raised solar tail. It retains lens_4 identity, 360 health, mirror activation gate, named solar blade and star-chart progression. Its 1.4-second warning locks a narrow forward beam, up to twelve meters long and 1.6 meters wide. Step sideways to avoid the single-hit discharge; line of sight and height are checked. Raw damage rises from 32 to 44 below half health, with recovery shortening from six to four seconds. Menus, travel, staggers and finishers cancel pending fire. This is a first creature/attack pass; model, animation and encounter tuning remain open.

## Sundering Strike combat pass

Shift+G spends the existing full meter on a directional melee power attack; G remains Whirlwind. Sundering Strike hits a 90-degree forward cone out to five meters for triple weapon damage, applying at least 1.5 seconds of stagger to surviving enemies only when health is reduced. Walls, shielded bosses and standard damage modifiers are respected. It shares activation guards, 1.2 real seconds of slow motion and cancellation/restoration behavior with Whirlwind. The overhead arm pose preserves body facing and camera orientation. Damage now applies at the strike frame: 0.30 real seconds for Whirlwind and 0.48 for Sundering Strike. Further choreography and tuning remain polish work. No new permanent save fields are required.

## Charged attack impact timing

Charged attacks now resolve once during their animation instead of at button press. Whirlwind strikes at 0.30 real seconds; Sundering Strike winds up and lands at 0.48. Target range, facing, walls and protection are checked at impact. Weapon damage and its effect are captured when the move starts, keeping one strike consistent even when combat training changes derived stats. Missing or canceling a strike does not refund spent power. Menu/death/travel cleanup prevents pending damage; large frame steps still resolve one hit and restore normal speed without recharging the meter. Sundering Strike now has separate lift, downswing and recovery poses.

## Merchant dialogue polish

Five merchants now have twenty original everyday and chapter-aware greetings. Completed-story gates avoid premature references to the woodland restoration, council and sky expedition. Shop visits rotate eligible lines per session; transaction feedback remains authoritative. Further ambient conversations and voice work remain open.

## Combat warning audio

The newer guardians now have original synthesized warning cues: a low root groan, bubbling brine, an ash inhale and a rising solar charge. They play once when the attack warning begins. Charged player attacks now use a heavier impact cue at the strike frame. All five cues use the existing Effects bus, cooldowns and bounded voice pool; music and volume settings remain unchanged. Warnings remain visible as well. Broader listening/balance passes on speakers and headphones remain open.

## Directional warning polish

Root, brine, ash and solar warnings now play from their creature's position through six reusable 3D voices. Moving creatures update the sound origin; menus, travel, death, staggers and execution locks stop the cue. The existing Effects slider controls volume. Native stereo recordings verify directional panning. General effects remain centered; acoustic occlusion and broader listening/mix tuning remain open.

## Terrain footstep polish

Player footsteps now distinguish grass, snow patches, stone, wooden interiors and metal station decks. Frostmere paths and patch edges use generated visual-ground data; a short floor ray preserves solid floor overrides. Walking, sprinting, airborne silence and menu suppression use existing movement conditions. Shared houses have inset plank floors with stone thresholds. Water splashes and further regional coverage remain open.

## Mac playtest distribution

A standalone Apple Silicon playtest ZIP is now available with a release app, controls/first-launch instructions and third-party notices. Native startup, rendering and the complete audio bank were verified from a freshly extracted copy on M5 Max. Ad-hoc signing is valid; Apple notarization, M1/minimum-OS verification and full packaged-campaign QA remain release work. Windows/Linux remain deferred.

## Opening scenery and choreography polish

The opening road now has layered snow-capped rock, pines, windblown snow streaks, scattered masonry and a physical roadside sign. The lantern has a metal frame and a quieter glow. The creature approaches, turns its head and opens its jaw, then retreats into fog over eight seconds. A pause-safe 0.75-second fade reveals Frostmere at the handoff. Existing skip, legacy-save bypass and first-quest behavior remain intact. Further cinematic art and dedicated intro music remain open; campaign pacing is the next review priority.

## Campaign handoff guidance

The home HUD now supplies a next destination throughout the connected campaign after Stonewake. Accepted unfinished chapters take priority; additional available branches are listed, with the complete list in the map footer. Journal entries for open chapters include directions from Frostmere. Lens and coast are correctly presented as parallel after Pinehall. The space handoff first points to the home-world Lens trail, then the northern transit vault once inside the observatory. Local chapter objectives and manual walking waypoints remain authoritative. No quest gates, rewards or save fields changed. Combat pacing, resource pressure and a timed full-campaign playthrough remain open.

## Supply preparation pacing

Ammunition, refining materials, potions and food now support five- and ten-batch crafting with visible total costs and yields. The full batch must be affordable; failed requests consume nothing. Equipment and main-story components remain single-craft. This reduces repeated workstation clicks while preserving the existing resource economy and XP. Combat difficulty and quest-critical material availability still need further review.

## Required-craft recovery

Mirewatch and the Wardworks now offer dedicated component rebuilds when spending shared ingredients leaves the required story craft unaffordable. Learned-design, original-supply, proximity and unfinished-objective checks guard the fallback. It grants only one unsellable component, with no raw materials or XP; the normal quest installation and boss requirements remain. Wider combat/resource pacing remains under review.

## Early melee pacing

Daggers now use a faster 0.38-second basic attack and cost six stamina (four with Measured Swing), addressing the starting rogue's low basic damage rate compared with sword builds. Other weapon timings and enemy, healing and ammunition values remain unchanged. A repeatable eight-playstyle numerical baseline supports further balance work; broader ancestry/build combinations and human encounter pacing remain open.

## Caster upgrade pacing

All eleven staff designs now contribute half their tempered base damage (rounded down) to equipped spell power before perks. Each quality rank adds one power, making staff improvement affect actual spells. Crafting displays the bonus and next rank's benefit. Existing spell unlocks, costs and cooldowns are preserved; a repeatable staff progression report supports further encounter balancing.

## Later reward progression

Skybreaker, Starweaver Rod, Dawnforged Bow and Dawnforged Staff now improve on comparable earlier equipment at equal quality. A runtime report checks the four comparisons at all six qualities. Existing item customizations and reward gates remain intact. Monster encounter pressure against post-realm gear is the next balance review; this is a targeted reward pass, not a completed campaign balance study.

## Final guardian attack timing

The Furnace Maw now has visible heat shutters and a 2.5-second exposed-core opportunity after each rupture. Closed shutters reduce incoming damage; the opening rewards timed retaliation. Its health, attack damage and story rewards remain intact. Actual finishers remain lethal through the shutters. Broader monster difficulty and human encounter timing remain under review.

## Aeralis guardian second phase

Prismwing gains a telegraphed close-range bite after its wings fracture, with locked aim, directional/range checks and a retaliation window. Its original fracture opening and ranged fans remain. Head and wing poses plus text communicate the attack. Broader campaign balance and human playtesting remain open.

## Defensive feedback polish

A brief directional impact cue now helps locate off-screen attacks. Hit, block, parry and guard-break outcomes have distinct labels/colors; the marker follows player facing toward the recorded impact position. It fades quickly and clears on menus/death. Existing damage rules and enemy awareness are unchanged.

## Lights Beneath the Boards

The Mirewatch side-quest outline is now playable: ask Ilyra about a blinking signal, investigate the western deck, rescue Tovin with a service-vault winch and claim his salvage cache. Physical interactions, visible rescue/cache outcomes, original dark humor, saved stages and journal objectives are implemented. It is an optional compact deck investigation, not a new underground dungeon. The atlas now has 26 remaining quest outlines. See MIREWATCH_RESCUE.md.

## The Astronomer's Debt

Veyra's optional Sunken Lens quest is now playable: recover two guarded instruments, then choose debt settlement or public research. Distinct gold/material rewards, persistent dialogue/journal outcomes, collectible props and validated save progress are implemented. Recovery uses the existing excavation caches and does not consume their main-quest supplies. The atlas now has 25 remaining quest outlines. See ASTRONOMER_DEBT.md.

## Nets Full of Silver

Saltbreak's side-quest outline is now playable: investigate a coin-laden net, recover a guarded smuggler ledger, and choose full publication or protection of the crew's identities. Both outcomes award the new forgeable, upgradeable Netmender's Band, with different gold/material rewards and saved story/journal outcomes. The atlas has 24 remaining outlines; the catalog has 146 designs and 162 recipes. See SILVER_NETS.md.

## Letters Above the Snow

The Wyrmkeep side quest is now playable: collect two conflicting family accounts, consult the new memorial and choose public remembrance or private replies. Both grant explicit reputation and material rewards; public remembrance changes the visible inscription. The quest is peaceful and independent of council policy/clan membership. Saved evidence and journal outcomes are implemented. The atlas now has 23 remaining quest outlines. See FAMILY_LETTERS.md.

## The Apprentice Who Vanished

Pinehall's missing-apprentice side quest is now playable: investigate a notice and research trail, clear the alcove sentinel, return Iven to camp and decide the research's future. Either outcome grants distinct Superior enchanted equipment and its reusable formula, plus gold. The rescued NPC relocates with updated nameplate/prompt; progress, rewards and journal outcomes persist. The return is interaction-driven rather than a walking escort. The atlas now has 22 remaining quest outlines. See MISSING_APPRENTICE.md.


## Shadowless stag quest — September 9, 2026

The Stag Without a Shadow is playable after woodland restoration: a moving spectral guide, three memory stops and hunter Fenn’s forgiveness resolution. Adds a quiet exploration quest independent of the Coven. 21 quest outlines remain planned. See SHADOWLESS_STAG.md.


## Tidemarch Compact initiation

A Ship Without a Name opens the Tidemarch Compact initiation after Black Shore. Investigate three sources, defend a supported claim at Vessa’s harbor hearing, and optionally swear the Decksworn oath for an enchanted Superior saber and formula. Higher Compact ranks remain planned. The atlas now has 20 remaining quest outlines. See TIDE_COMPACT.md.


## The Harbor That Lied

The Harbor That Lied continues the Compact through forged records, false beacon orders and witness protection. Tamsin relocates to the southern shelter; public or sealed testimony awards distinct Superior enchanted gear and Envoy rank. Saved progression and journal updates are implemented. 19 quest outlines remain planned. See HARBOR_LIED.md.


## The Price of Safe Passage

The Price of Safe Passage completes the playable three-rank Tidemarch Compact arc. Consult three voices and sign open, licensed house, or house-with-Concord-ban terms. Harbor Speaker grants a Masterwork enchanted amulet; the signed charter and journal preserve the outcome. The ban closes the still-planned Concord final quest in the atlas and exposes a gate for its future implementation. 18 quest outlines remain planned. See SAFE_PASSAGE.md.


## Voices in the Furnace

Voices in the Furnace opens the Ashen Choir initiation after its main signal quest. Three timed vent vigils, an omitted-name record and an optional Listener oath are playable, with saved checkpoints and enchanted robe/formula rewards. This reuses the existing caldera and adds a controlled cool-interval challenge without vent damage. 17 quest outlines remain planned. See CHOIR_LISTENER.md.


## Ash Remembers Everything

Ash Remembers Everything adds the Choir’s second rank: open a pressure-locked archive cabinet, recover signed evidence and choose publication or concealment. Distinct Exquisite enchanted gear, Cantor rank, saved lock progress and a visible outcome caption are implemented. 16 quest outlines remain planned. See ASH_MEMORY.md.


## The Fire We Invite

The Fire We Invite completes all three playable Ashen Choir ranks. Secure two guarded governors and awaken, contain or silence the local bound ember for Ember Voice and distinct Masterwork gear. Conquest closes actual unfinished Clan Voice actions; an existing Clan Voice oath instead excludes conquest. The campaign furnace is unchanged. 15 quest outlines remain planned. See FIRE_INVITE.md.


## A Pilgrim’s Empty Shoes

A Pilgrim’s Empty Shoes is playable as a compact independent caldera investigation. Follow shoes and a guarded letter to Leth, then offer shelter or free-departure supplies. Leth relocates to camp; both outcomes grant a protected enchanted ring and distinct materials. The route uses existing ash paths rather than adding a tunnel dungeon. 14 quest outlines remain planned. See EMPTY_SHOES.md.


## The Last Warm Shelter

The Last Warm Shelter is playable on the Rimegate approach within Wyrmkeep. A new hut and three stranded travelers support a wood-funded hearth repair and cleared-road/guide arrangement. The group relocates into shelter; rewards and choices persist. 13 quest outlines remain planned. See WARM_SHELTER.md.


## The Old Watch Road

The Old Watch Road begins the Hearthbound Lodge arc in Frostmere. Three repairable markers, supplied materials, a two-bristleback guard condition and optional Outrider oath are playable through the Hunters’ Board. Restored lights, saved repairs and a protected enchanted amulet reward are implemented. 12 quest outlines remain planned. See HEARTHBOUND.md.


## A Winter Without Wolves

A Winter Without Wolves continues the Hearthbound Lodge through an abandoned den, poisoned runoff and grove keeper Senna. Repair the local filter and expose or conceal the patron for Waykeeper rank and distinct Exquisite gear. Existing wildlife is unchanged; this is a compact investigation on existing terrain. 11 quest outlines remain planned. See WATERSHED.md.


## Who Guards the Pass?

Who Guards the Pass? completes the three-rank Hearthbound arc. Harvest the north-pass colossus and choose neutral Lodge or sworn-clan control for Warden rank and Masterwork gear. Policy changes the visible two-person village patrol and one-time support cache. These are fixed-route visual guards, not combat escorts. 10 quest outlines remain planned. See WARDEN.md.


## The Boat That Would Not Burn

The Boat That Would Not Burn is playable on the existing Saltbreak shore: inspect an Ashport launch, hear two cargo claims and award shelter plates to workers or Choir research for distinct Superior enchanted rewards. Nine quest outlines remain planned. See ASH_BOAT.md.


## The Keeper’s Last Light

The Keeper’s Last Light is playable on the existing Saltbreak shore. Read the keeper’s log, repair a separate fjord signal, guide a Hallowcliff relief ship to anchor and choose how to report the keeper’s bargain. Eight quest outlines remain planned. See LAST_LIGHT.md.


## A Harvest of Amber

A Harvest of Amber is playable through Edda and an Alderrest trial plot in the existing woodland chapter. Collect a sample, prepare and test a treatment, then preserve the grove or authorize limited emergency logging for distinct rewards and visible consequences. Seven quest outlines remain planned. See AMBER_HARVEST.md.


## Final seven quests

The full Sable Concord arc and the Dunewell well, Larksbridge mill, Three Roads traveler and Reedhollow medicine stories are playable through existing areas and new representative outposts. Saved choices, rank progression, material/gold costs, differentiated rewards, visible repairs and reciprocal rival finale closures are implemented. See ROAD_QUESTS.md.


## Station supply balance

A six-loadout bow audit informed one-time archer/caster reserves in the station locker and cargo cache: 60 arrows and three magicka draughts total. Existing cache claims prevent refills; rifle rewards and enemies are unchanged. 369 checks passed and native dialogue was inspected. See CAMPAIGN_PACING.md.


## Realm supply balance

Aeralis and Crucible arrival crystals now include one-time arrow and magicka reserves for existing builds, informed by a twelve-scenario ammunition audit. Existing realm rewards and enemies are unchanged; old claimed attunements do not refill. 168 checks passed. See CAMPAIGN_PACING.md.


## Siege repair recovery

After clearing scouts and collecting the original stores, an unaffordable required defense can use a fitted garrison spare. It installs directly without farmable supplies or rewards, persists through existing repair flags and preserves the assault prerequisites. 178 checks passed; native Mac dialogue inspected. See CAMPAIGN_PACING.md.


## Late defense supply review

Winter Siege and Broken Seal stores now add one-time arrow, Station Round and magicka reserves without reducing required repair/component stock. A live-enemy audit covers eight loadouts, including ballista damage. 220 checks passed; native descriptions inspected. See CAMPAIGN_PACING.md for the completed numerical supply pass and remaining human pacing review.


## Healing feedback review

Consumables show their existing armor bonus, actual restoration and unused capacity before use. Full-resource items are kept; success feedback reports the amount restored. Shared calculation preserves current balance. 407 checks passed and native Mac UI inspected. Healing demand and timed combat pacing still need campaign playtesting; see CAMPAIGN_PACING.md.


## Cross-build healing and guarding

Added a repeatable 72-scenario boss damage/recovery baseline across eight playstyles and three equipment kits. Live attacks verify armor mitigation, potion restoration, guarding and guard breaks; counterplay regressions cover dodge and exposure windows. 420 checks passed. No damage or supply tuning from these controlled samples. Real encounter duration, supplies spent and failed attempts remain the next campaign balance evidence; see CAMPAIGN_PACING.md.


## Campaign measurement tooling

Opt-in local combat logs now record build snapshots, active segment timing, damage, successful supplies used, ammunition, kills and deaths. A Python command turns logs into a readable report. 156 checks passed; default launches do not record. This enables measured campaign playtests but does not complete them. See COMBAT_PLAYTESTS.md.


## Bespoke opening music

Ash Through the Snow now has an original slow 48-second synth loop and dedicated creature-approach/ward-resolution cues. Cues follow pause and stop at the village handoff; ordinary music resumes through the existing crossfade. 85 gameplay/audio checks passed. No narrative gates or combat tuning changed. Further visual polish, human listening and campaign/performance playtests remain; see INTRO.md and AUDIO.md.


## Wyrmkeep winter layout polish

Winding paved lanes now connect the existing town, including a council-hall bypass to the northern pass and a watch-hut route. A frozen well courtyard, varied storage yards, approach markers and snow banks add detail without relocating saved services or NPCs. Ground footsteps match snow/paving and preserve wooden interiors. 266 checks passed; native Mac captures inspected. Building rotations, broader town expansion and hardware performance validation remain open. See WYRMKEEP.md.


## Saltbreak waterfront polish

The pier has a supported landward extension, mooring detail, decorative ropes, a covered sorting table, storage crates and lanterns. Wooden deck footsteps now match the planks. Quest locations and offshore boundaries are preserved. 298 checks passed; native Mac views inspected. Larger town expansion and hardware performance validation remain open; see BLACK_SHORE.md.


## Pinehall woodland camp polish

The clearing now has lanes to its existing hall doors and western building, a covered reading table, herb beds and fuel stores. Footsteps distinguish grass, paving, interiors and ruin stone. Existing archive/apprentice routes stay clear. 128 checks passed; native Mac views inspected. This is a camp detail pass, not a full forest-town expansion; see ARCHIVE.md.


## Pinehall woodland terrain

Four walkable outer-forest rises and deterministic tree variation replace the flat, evenly spaced forest edge. The camp, archive and existing quest routes stay level. Supported hill saves reload normally; obsolete positions beneath hills use the existing arrival fallback. 205 checks passed and native Mac slope views inspected. This advances terrain polish; broader regional landscapes and performance validation remain open. See ARCHIVE.md.


## Woodland tree refinement

Pinehall's broad stepped tree slabs are replaced with smaller branch clusters, irregular tips and lower bough detail. All 37 trees retain their locations and trunk collision. 153 checks passed and native Mac captures inspected. Geometry remains bounded and batched; M1 performance validation remains open. See ARCHIVE.md.


## Station monster presentation

Hullcarver wind-up now includes opening mandibles, braced legs, a growing plasma charge and post-shot recoil. Existing attack timing and core vulnerability are unchanged. 133 checks passed and native Mac poses inspected. This advances monster animation polish; additional creature choreography and finisher presentation remain open. See THRESHOLD.md.


## Crucible monster presentation

The Furnace Maw now has an inhaling bellows/jaw pose, braced legs and a brief rupture slam before its exposed-core recovery. Ground warnings and combat values are unchanged. 70 checks passed and native Mac poses inspected. Additional monster and finisher choreography remains open; see REALMS.md.


## Aeralis monster presentation

Prismwing now spreads its crystal feathers and braces before volleys, recoils after firing, and opens a hinged jaw during its fractured-wing bite draw-back and snap. Attack timing, committed aim and combat values remain unchanged. 70 checks passed and native Mac poses inspected. Further monster and finisher choreography remains open; see REALMS.md.


## Finisher impact motion

Weapon-specific fragment patterns now follow the strike direction, with tumbling/falling motion, faster crystal shards and rising furnace fragments. Menus freeze the effect and travel clears it. 83 checks passed; native Mac crystal and furnace impacts inspected. Broader creature execution choreography and human combat pacing remain open; see REALMS.md.


## Creature defeat silhouettes

Hullcarver, Prismwing and Furnace Maw now have individual settled corpse poses, preserving folded limbs, broken feathers and slack jaws across saved defeat reconstruction. 88 checks passed and native Mac views inspected. Animated collapse transitions and broader creature execution choreography remain open. See REALMS.md and THRESHOLD.md.


## Creature collapse transitions

The three destination monsters now animate from their live poses into the previously added corpse silhouettes over 0.6–0.85 seconds. Menus freeze motion, departure settles it, and saved corpses do not replay it. 100 checks passed and native Mac intermediate poses inspected. Basic collapse transitions are complete; bespoke execution sequences and human combat pacing review remain open. See REALMS.md.


## Creature execution reactions

Hullcarver, Prismwing and Furnace Maw now build distinct visual reactions through the existing finisher wind-up and hand those poses into collapse on impact. Cancellation restores the living pose. 108 checks passed and native Mac wind-up views inspected. This completes the basic reaction-to-impact-to-collapse chain; further bespoke choreography and human combat pacing remain open. See REALMS.md.


## Creature finisher sound

Hullcarver, Prismwing and Furnace Maw now have original synthesized shell, crystal and furnace finisher impact cues. They trigger once on the confirmed lethal frame. 104 checks passed; native Mac mixer recording verified and saved for listening. Subjective mix review and broader human combat pacing remain open. See AUDIO.md.


## Wyrmkeep winter foliage

Thirteen detailed snow-dusted pines now frame the outer settlement grounds, using small branch clusters, varied heights and existing material batches. 192 checks passed and native Mac views inspected. Wider terrain/town expansion and M1 performance validation remain open. See WYRMKEEP.md.


## Winter settlement ground detail

Low drifts around the pines and six snow-capped rock groups now break up Wyrmkeep's outer ground. 166 checks passed and native Mac views inspected. Broader terrain variation, town expansion and hardware validation remain open. See WYRMKEEP.md.


## Rimefang charge choreography

The wilderness giant now lowers its articulated head/tusks and paws during charge preparation, then uses a running stride and subtle body motion. Existing combat timing and hunt progression are unchanged. 82 checks passed and native Mac poses inspected. Further wilderness species animation and human combat pacing review remain open. See HUNTS.md.


## Wolf and boar combat readability

Ordinary wilderness wolves and boars now draw back, open toothed jaws and snap forward during their existing bite attacks. Cancellation clears their pending bite and pose. 90 checks passed and native Mac views inspected. Further creature variety and human combat pacing remain open. See HUNTS.md.


## Colossus heavy-attack presentation

The wilderness colossus now raises articulated arms and follows through into a short impact recovery during its existing ground slam. 78 checks passed and native Mac poses inspected. Existing combat values remain unchanged; broader creature variety and human pacing evaluation remain open. See HUNTS.md.


## Colossus landing effects

The ground slam now has a brief terrain-following burst of stone and earth fragments. 50 checks passed and native Mac impact inspected. The warning, articulated swing and landing effect now form a complete basic slam presentation. Human combat pacing and broader creature variety remain open; see HUNTS.md.


## Regional performance harness

Three repeatable fixed-view native samples now cover Frostmere, dense Pinehall foliage and Wyrmkeep. The current M5 Max run delivered roughly 120 FPS with VSync enabled; see PERFORMANCE.md for percentile timings and measurement limits. Moving/combat workloads, long-session behavior, town draw-call profiling and M1 validation remain open. No release created.


## Active performance scenarios

The benchmark now supports scripted moving views and a sustained Colossus AI sample with normal cooldowns. Current M5 Max p95 timings were 9.71 ms for Pinehall camera movement and 10.43 ms for combat; two slams verified. This advances performance coverage beyond fixed views. Full player/multi-enemy workloads, long sessions, profiling and M1 validation remain open. See PERFORMANCE.md.


## Region and effect lifecycle coverage

A repeatable native stress harness now checks repeated region visits plus paused/traveling/expiring effects. Thirty measured cycles passed with stable node/resource counts and zero orphans. Long-duration sessions, disk save/load under sustained play, full combat workloads and M1 validation remain open. See PERFORMANCE.md.


## Repeated save/load coverage

A 24-cycle isolated disk round-trip fixture now covers inventory upgrades and growth, travel/resources, defeated-creature reconstruction and duplicate-reward rejection. 294 checks passed with session regressions. Full application restart/recovery scenarios, long-duration play and M1 validation remain open. See SAVE_RESUME.md.


## Native save restart and interruption coverage

The native two-process QA fixture now verifies upgraded gear, harvested enemies and Wyrmkeep session restoration with an abandoned incomplete temporary save present. Both phases passed; the valid primary loaded and the next save replaced the temporary file. Full-duration play, primary-file corruption recovery, power-loss durability and M1 validation remain open. See SAVE_RESUME.md.

## Connected campaign progression and resource baseline

Three fresh warrior/ranger/mage routes now exercise Oldwatch through the homecoming heirloom with earned prerequisites, rewards, finite shop ingredients, story crafting and chapter save validation. The automated route uses explicitly modeled attacks, not a human playthrough. Ranger resupply and starter-spell caster recovery are now tracked across the entire route; see CAMPAIGN_PLAYTHROUGH.md. Fixed stale finale bow/staff damage descriptions by deriving their offers from item data, and made input setup safe across repeated world initialization. Timed human campaign pacing, realistic incoming combat pressure and M1 validation remain open. No release created.

## Mage spell recovery follow-up

Actual projectile tests now cover all five spells and the two magic perks, including chain/pierce attenuation and Starfall convergence. All 57 checks passed. Selected-spell HUD hints show current magicka cost; the Conductor no longer advertises a fixed 24 after Clear Channel lowers its cost to 19.2. Rifle ammunition occupies a separate line. Native Mac HUD verified. The conservative campaign model omitted working later-spell/perk gains, so no blanket magic rebalance was made. See CAMPAIGN_PLAYTHROUGH.md; incoming enemy pressure and human pacing remain open.

## Active Aeralis mage comparison

Added a repeatable native/headless Prismwing exchange harness using actual enemy AI, movement, fan projectiles, player casts, incoming damage, cooldowns and regeneration. It compares Emberbolt before/after magic perks and perked Starfall, with isolated stage fixtures and separate combat logs. Automatic aim and full starting resources limit its conclusions; no combat balance changes were made. See CAMPAIGN_PLAYTHROUGH.md and the generated Prismwing live-playtest report. Multi-enemy pressure, close-range retaliation and human campaign pacing remain open.

## Active Aeralis bite and group pressure

Added repeatable native/headless live-AI stress fixtures for standing in Prismwing's bite, collision-aware sidestepping, and both sentries attacking alongside the boss. Three native Mac scenarios passed, including real fracture/retaliation and overlapping warnings. The dodge avoids the bite; grouped attacks function without requiring changes to combat stats or AI. These are staged full-resource automatic-aim comparisons; human difficulty and other-world pressure remain open. See CAMPAIGN_PLAYTHROUGH.md.

## Active Furnace Maw resource tradeoff

Four native pressure scenarios now exercise authored rupture damage, committed warning circles, collision-aware dodges, machine-gun ammunition and Soulfire casts against live Maw AI. Waiting for exposure saved eight rounds in the recorded comparison but took longer than continuous fire. No combat numbers changed. Fixed an extra movement step in QA steering and reran all three Aeralis pressure cases successfully. Seven native scenarios passed; see CAMPAIGN_PLAYTHROUGH.md. Multi-enemy Hell pressure and human playthrough pacing remain open.


## Refined equipment construction — September 13, 2026

Started the major visual-detail roadmap with shaped and layered sword-family and shield models shared by first-person and character equipment. Added blade channels/edges, constructed grips and guards, shield panels/rims/bosses, rear straps and timber, and gem/enchantment details. Character and combat checks passed (82 total); native gallery and both held camera views inspected. Armor, hands, other weapon families, monsters and the representative environment remain open. See VISUAL_DETAIL_ROADMAP.md. No release created.


## Armor and hand construction — September 13, 2026

Added layered heavy torso/waist plates, tailored light panels, helmet details, shoulder trim, boot fittings and shared segmented first/third-person gloves. Light and heavy shoulders/legs now differ in construction. Native steel/leather/cloth gallery and held steel equipment views inspected; 82 character/combat checks passed. Named armor identities, comprehensive visual fitting, monsters and the rest of the visual-detail roadmap remain open. No release created.


## Refined Rimefang — September 13, 2026

Rimefang now has a tapered body, layered frost mantle/ridges, defined face, swept tusks, articulated jaw and clawed paws. Shared batching follows its existing head and leg animation pivots. The overhead charge warning was raised for visibility. Charge/hunt, corpse and execution suites passed (79 checks); native gallery and gameplay poses inspected. The wider monster and representative-scene roadmap remains open; no release created.


## Refined staffs and ranged equipment — September 13, 2026

Added shared constructed staffs, bows, rifles and focuses: faceted cores and forked settings, layered bow limbs and bindings, mechanical rifle fittings and illuminated Hell vents. First/third-person views and gallery inspected on M5 Max; 177 character/combat/projectile/realm checks passed. Street/interior treatment is next for the representative scene. Named equipment identities and remaining weapon/creature rollout stay open. No release created.


## Copper Stag street and interior — September 13, 2026

Added a carved entrance and stag plaque, approach edge stones/drain, banded supply crate, outfitter counter panels, ledger/scales, rear weapon display and leatherwork supplies. Shop/town checks passed (54 total), including physical door access; native street/interior captures inspected. Added safe handling for unavailable buy selections. Initial representative asset categories are in place, but combined concept comparison, further detail/identity rollout and performance review remain open. No release created.


## Combined visual reference review — September 13, 2026

Reviewed the staged Copper Stag/armor/Rimefang composition against the approved concept. Added shared cached metal/leather/cloth surfaces and a staggered fur collar with shoulder coverage, also applied to held gear. Character checks passed (36); native combined scene, armor gallery and both held cameras inspected. Recorded specific remaining gaps in VISUAL_DETAIL_ROADMAP.md: terrain/vegetation composition first, then creature mass/surface variation, character identities, lighting and measured performance. The visual milestone is not complete; no release created.


## East-bank terrain and vegetation — September 13, 2026

Added a bounded riverbank slice beside the village bridge with low traversable rises, matching collision, layered rock edges, reeds/ferns/grass, lichen shelves and branched pines. Town and bank/bridge movement checks passed (24 total); native overview and walking views inspected. Broader shoreline variation, vegetation/world rollout, water/lighting, creature anatomy and updated performance measurements remain open. No release created.


## Rimefang anatomy follow-up — September 13, 2026

Reworked the torso into shoulder, tucked abdomen and haunch masses; varied frost crest growth, swept mantle tufts and front/rear limb profiles. Added subtle shared hide variation after reducing overly noisy texture contrast. Preserved combat/collision behavior. Charge/hunt, corpse and execution checks passed (79 total); native gallery and charge poses inspected. Broader landscape variation and equivalent detail across the remaining boss roster remain open. No release created.


## Scalloped shoreline and finer water — September 13, 2026

Added irregular shallow shelves along the refined east-bank slice with matching collision, clustered rock noses and reed patches. Replaced broad bright water stripes with smaller broken ripples and subtle current variation. Eight bank/bridge/shelf/channel checks passed; native overview and walking views inspected. Wider river/landscape variation remains open, along with the rest of the visual roadmap. No release created.


## Connected visual cleanup — September 13, 2026

Completed opposite-bank shelves, canopy/ground-cover cleanup, reduced floating-label clutter, preserved procedural forest placement, restored the iron gathering clearing, and refined axes/battleaxes/maces through the shared equipment builder. Removed superseded weapon geometry paths. All 147 targeted checks passed. Native render and performance review accompany this batch; full regional rollout, authored boss/gear identities, M1 validation and the other roadmap tracks remain open. No release created.
