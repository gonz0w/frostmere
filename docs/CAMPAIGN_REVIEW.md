# Campaign outcome review

This is a reproducible review procedure and source inventory, not a completion
tracker. Record runs, failures and human sign-off in [issue #6](https://github.com/gonz0w/frostmere/issues/6).
A listed fixture is evidence of an implemented check, not evidence that it passed
on your machine or that a human has played the route.

## Automated branch matrix

Import the project as described in [CONTRIBUTING.md](../CONTRIBUTING.md), then run
an individual fixture with `godot --headless --path . --script tests/NAME.gd`.
Use a timeout and inspect errors as well as the final completion marker. Do not
add `--capture`: these are behavior checks. They use fixture saves rather than
the regular profile. Backups are part of a save set; a test resetting its own
fixture must also reset its own `.bak`, `.tmp` and `.bak.tmp` sidecars.

| Decision or interruption | Fixtures in `tests/` | Expected contract to review |
| --- | --- | --- |
| Four parallel findings and later chapter gates | `campaign_guide.gd`, `convergence.gd` | All 16 completion subsets retain a useful next step; convergence needs all four findings. |
| Atlas custody | `archive.gd`, `lantern.gd` | Lantern/Briar custody changes standing and rewards; either custodian still permits the Lantern membership trial. |
| Woodland pact | `roots.gd`, `coven_debt.gd`, `coven_finale.gd` | Wild/tended pact survives membership and reload; only the chosen pact pattern unlocks. Review later oath and final promise separately. |
| Coastal core | `shore.gd` | Harbor/navigation destinations are exclusive, visually distinct, and require the final report before advancement. |
| Clan allegiance and mandate | `mountain.gd`, `clan_voice.gd` | Membership/rank gates and mandate survive reload. Clan Voice fixture pairs Stoneguard/holds and Stormweaver/leader; it does not establish every cross-combination. |
| Hearthbound watch | `hearthbound.gd`, `watershed.gd`, `warden.gd` | Repairs, hunts and neutral/clan watch have correct proof gates and single rewards. |
| Names and knowledge custody | `lantern_capstone.gd` | Public/sealed testimony and seal/share/oversight mandate retain earlier testimony and reject repeat rewards. |
| Ashen Choir | `choir_listener.gd`, `ash_memory.gd`, `fire_invite.gd` | Initiation and evidence gate awaken/contain/silence. Check the warned effect of awakening on the Iron Pact capstone. |
| Harbor witness and passage | `tide_compact.gd`, `harbor_lied.gd`, `safe_passage.gd` | Public/sealed identity and open/house/outlaw charter remain permanent; outlaw closes the rival Concord capstone. |
| Concord and Compact order | `road_branches.gd` | Both signing orders; completed peaceful charters cannot be retroactively invalidated; war and outlaw exclusions are explicit in guidance. |
| Seven road stories | `remaining_quests.gd`, `road_branches.gd` | Each authored final option, exact reward, interrupted-step reload and malformed/legacy record; inspect cargo, wages and marsh alternatives. |
| Missing craft supplies | `story_recovery.gd` | Regulator/ward emergency rebuild requires learned design and claimed supplies; no duplicate resources or XP. |
| Interrupted chapter objectives | `lens.gd`, `choir.gd`, `convergence.gd`, `threshold.gd`, `winter.gd`, `seal.gd` | Partial saves resume; unsupported/inconsistent progress is rejected before applying; older records receive defaults. |
| Destination return and ending | `realms.gd`, `ending.gd`, `winter_recovery.gd` | World gates, portable rewards, return handoffs and recovery guidance remain consistent. |

These fixtures often seed prerequisites, move the player and disable enemies.
They establish controller contracts, not organic navigation, combat balance,
readability, elapsed play time or all combinations of all choices.

## Atlas-to-fixture inventory

The 51 playable atlas entries map to these fixture groups. Shared fixtures are
intentional: multiple quests use one controller. Consult the test assertions and
controller before treating a title match as full coverage.

| Atlas entries | Principal fixture names (without `.gd`) |
| --- | --- |
| `oldwatch_survey`, `stonewake` | `atlas`, `stonewake` |
| `council`, `iron_pact_1`, `iron_pact_2`, `iron_pact_3` | `mountain`, `clan_voice`, `fire_invite` |
| `archive` | `archive` |
| `roots` | `roots` |
| `tides` | `shore` |
| `lens` | `lens` |
| `choir` | `choir` |
| `convergence` | `convergence` |
| `threshold` | `threshold` |
| `returning_light`, `last_furnace` | `realms`, `ending` |
| `winter_siege`, `broken_seal` | `winter`, `seal` |
| `hearthbound_1`, `hearthbound_2`, `hearthbound_3` | `hearthbound`, `watershed`, `warden` |
| `lantern_1`, `lantern_2`, `lantern_3` | `lantern`, `names_water`, `lantern_capstone` |
| `briar_coven_1`, `briar_coven_2`, `briar_coven_3` | `coven_debt`, `coven_finale` |
| `sable_concord_1`, `sable_concord_2`, `sable_concord_3` | `remaining_quests`, `road_branches` |
| `ashen_choir_1`, `ashen_choir_2`, `ashen_choir_3` | `choir_listener`, `ash_memory`, `fire_invite` |
| `tide_compact_1`, `tide_compact_2`, `tide_compact_3` | `tide_compact`, `harbor_lied`, `safe_passage` |
| `side_frostmere` | `hunt` |
| `side_pinehall`, `side_wyrmkeep`, `side_rimegate` | `missing_apprentice`, `family_letters`, `warm_shelter` |
| `side_ashport`, `side_ember_caldera` | `ash_boat`, `empty_shoes` |
| `side_saltbreak`, `side_hallowcliff` | `silver_nets`, `last_light` |
| `side_alderrest`, `side_stag_shrine` | `amber_harvest`, `shadowless_stag` |
| `side_dunewell`, `side_larksbridge`, `side_three_roads`, `side_reedhollow` | `remaining_quests`, `road_branches` |
| `side_sunken_lens`, `side_mirewatch` | `astronomer_debt`, `mirewatch_rescue` |

## Targeted human play procedure

Use a copied project configured with `config/use_custom_user_dir=true` and a
unique QA `config/custom_user_dir_name`. Confirm that directory before playing.
Do not run setup or fixture scripts against your normal adventure. Keep a copy
of the entire QA save directory at a branch checkpoint, with the game closed.
Restore the complete directory when replaying an alternate choice so character,
atlas and backup generations do not get mixed.

1. Play to each decision in the branch matrix through ordinary movement, combat
   and dialogue. Record the checkpoint and which prerequisites were completed.
2. Before selecting, read the journal and NPC warning. Record whether the next
   location, required proof, permanent exclusion and reward are understandable.
3. Choose the outcome; inspect the actual world change, unlocked recipe/item,
   faction standing and journal. Attempt the opposite option and a repeat reward.
4. Save and quit mid-objective and after the final reward. Relaunch in a new
   process. Verify the objective, equipped item identity, reward count and next
   route. Replay the alternate choice from the preserved full checkpoint.
5. Specifically play Concord then Compact and Compact then Concord. Confirm
   peaceful coexistence, war exclusion and outlaw exclusion match the warning
   shown **before** commitment. A deliberate exclusive ending is not a softlock;
   losing every required main-story route is.
6. Review the 51-entry inventory for omitted branch families and record any case
   not exercised. Do not infer coverage of all combinations from one route.

Record revision, OS/hardware, archetype, route/choice order, checkpoint,
expected/observed result, duration and any screenshot or sanitized log in #6.
Mark each observation as human play, automated fixture, source inspection or
not exercised. Never substitute an automated pass for the human sign-off gate.
