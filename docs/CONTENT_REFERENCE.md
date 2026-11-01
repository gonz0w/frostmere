# Current content reference

This describes the source catalog reconciled on November 1, 2026. Counts identify
implemented content definitions, not campaign balance, hours of play, full towns
or supported hardware. [GitHub Issues](https://github.com/gonz0w/frostmere/issues)
own remaining work; this page is not a backlog.

| Content | Current source | Definition |
| --- | ---: | --- |
| Playable atlas quests | 51 | 13 main, 21 faction, 17 side; every catalog quest has `status: playable` |
| Gear designs | 146 | Base item definitions, not owned copies or every named quest reward |
| Crafting recipes | 162 | 146 gear, 11 material/refining/ammunition, 5 consumable recipes |
| Enchantment formulas | 10 | Six attribute formulas, two realm formulas and two clan formulas |
| Ancestries / starting playstyles | 8 / 8 | Equipment is not class-locked |
| Equipment slots | 9 | Includes main/off hand and jewelry |
| Merchant shops | 5 | Three Frostmere shops and two Wyrmkeep clan merchants |
| Learned spell definitions | 5 | Equipment-specific Chain Lightning is additional |
| Music / sound-effect WAVs | 9 / 32 | Eight exploration/battle loops plus the opening score; 41 files total |

## Sources and interpretation

- [Character catalog](../data/characters.json): `items`, `origins`, `archetypes`, `slots`.
- [Crafting catalog](../data/crafting.json): `recipes`, `enchants`; recipes identify output kinds.
- [Atlas](../data/world_atlas.json): `quests`, their kind, status and prerequisites.
- [Shops](../data/shops.json) and [realm/spell definitions](../data/realms.json).
- [Music](../assets/audio/music) and [effects](../assets/audio/sfx), with runtime
  selection in [audio_director.gd](../scripts/audio_director.gd).

The playable designation includes prerequisites and mutually exclusive outcomes.
It does not promise that every faction ending is available in one save. Some
named places are represented by camps or NPCs inside existing playable regions;
see [the atlas and faction guide](WORLD_DESIGN.md) and [road quests](ROAD_QUESTS.md).
The three destination chapters are connected to the story but remain compact.

## Player guides

[Adventure](ADVENTURE.md), [characters](CHARACTERS.md), [crafting](CRAFTING.md),
[skills](SKILLS.md), [saving](SAVE_RESUME.md), [music](AUDIO.md) and
[chapter navigation](README.md) describe the current behavior. Historical test
counts and native captures are evidence from development, not fresh verification
or proof of M1, Windows or Linux support.
