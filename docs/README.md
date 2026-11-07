# Frostmere documentation

Start with the [project README](../README.md) to run the game, then use the
[current content reference](CONTENT_REFERENCE.md) for catalog counts and scope.
The guides below describe implemented behavior. Implementation is not a claim
of completed campaign balance or native cross-platform qualification.

## Playing and contributing

- [Adventure and combat](ADVENTURE.md), [characters](CHARACTERS.md),
  [crafting](CRAFTING.md), [skills](SKILLS.md), [shops](SHOPS.md),
  [saving](SAVE_RESUME.md), [music and sounds](AUDIO.md).
- [Opening](INTRO.md), [atlas and factions](WORLD_DESIGN.md), [dialogue tone](DIALOGUE_TONE.md).
- [Contributing](../CONTRIBUTING.md), [repository map](REPOSITORY_MAP.md),
  [project policy](../PROJECT.md), [asset notices](../THIRD_PARTY_NOTICES.md).

## Main chapters

| Place or stage | Guide |
| --- | --- |
| Oldwatch and Frostmere | [Barrow adventure](ADVENTURE.md), [Stonewake](STORY.md) |
| Wyrmkeep | [The Divided Council](MOUNTAIN.md) |
| Pinehall | [The Missing Atlas](ARCHIVE.md) |
| Stag Shrine | [Pacts Beneath the Roots](ROOTS.md) |
| Saltbreak | [The Wreck on the Black Shore](BLACK_SHORE.md) |
| Sunken Lens | [The Sky Below the Sand](SUNKEN_LENS.md) |
| Ember Caldera | [A Song Through the Stone](CHOIR.md) |
| Mirewatch | [The Roads Converge](CONVERGENCE.md) |
| Space station | [Beyond the First Threshold](THRESHOLD.md) |
| Aeralis | [The Returning Light and realm access](REALMS.md) |
| Northwatch | [The Winter Siege](WINTER_SIEGE.md) |
| Caldera underworks | [The Broken Seal](BROKEN_SEAL.md) |
| Crucible and homecoming | [Realm encounters](REALMS.md), [The Last Furnace](ENDING.md) |

## Factions and side quests

[The faction guide](WORLD_DESIGN.md#faction-guides) links all seven initiation
and promotion chains. Additional quest guides are grouped by their setting:

| Area | Guides |
| --- | --- |
| Frostmere and outer roads | [Mossbound and Frostmaw hunts](HUNTS.md), [caravan, mill and inn quests](ROAD_QUESTS.md) |
| Wyrmkeep | [Warm Shelter](WARM_SHELTER.md), [Family Letters](FAMILY_LETTERS.md), [water claims](ROAD_QUESTS.md) |
| Pinehall | [Missing Apprentice](MISSING_APPRENTICE.md) |
| Woodland | [Amber Harvest](AMBER_HARVEST.md), [Shadowless Stag](SHADOWLESS_STAG.md) |
| Saltbreak | [Silver Nets](SILVER_NETS.md), [Ash Boat](ASH_BOAT.md), [Last Light](LAST_LIGHT.md) |
| Ember Caldera | [Empty Shoes](EMPTY_SHOES.md) |
| Sunken Lens | [Astronomer's Debt](ASTRONOMER_DEBT.md) |
| Mirewatch | [Refugee rescue](MIREWATCH_RESCUE.md), [Reedhollow road quest](ROAD_QUESTS.md) |

## Screenshots and development evidence

[Public screenshots](screenshots/README.md) are actual native game captures.
[Art-direction history](VISUAL_DETAIL_ROADMAP.md), [scope history](SCOPE.md),
[original development notes](DEVELOPMENT_HISTORY.md), [validation](VALIDATION.md),
[performance](PERFORMANCE.md), [campaign evidence](CAMPAIGN_PLAYTHROUGH.md),
[campaign pacing](CAMPAIGN_PACING.md) and the [presentation review](PRESENTATION_REVIEW.md)
retain observations from earlier development. The [building](BUILDING_REVIEW.md)
and [landscape](LANDSCAPE_REVIEW.md) reviews describe local capture artifacts.

Validation counts and native-capture statements in chapter guides are historical
observations, not newly executed checks. `build/` galleries, traces and packages
are not shipped in a fresh clone; their paths describe local output. The public
screenshots above are maintained separately. [Combat playtest instructions](COMBAT_PLAYTESTS.md)
describe opt-in local evidence collection, not automatic telemetry.

Live work and review status belong only in [GitHub Issues](https://github.com/gonz0w/frostmere/issues)
and [milestones](https://github.com/gonz0w/frostmere/milestones). Historic unchecked
lists and “next” statements do not assign new work or promise a supported release.

- [Platform targets and pinned toolchain](PLATFORMS.md)
- [Portable source launch and verification](SOURCE_LAUNCH.md)
