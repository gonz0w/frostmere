# Licenses and asset provenance

The root [BSD-3-Clause license](LICENSE) covers Frostmere's original code,
GDScript-generated geometry/materials, game data, original synthesized audio,
and project artwork and screenshots, unless a file carries another notice.
Copyright: 2026 gonz0w. Owner authorized BSD-3-Clause public distribution.

- `.agent-temper/` contains Agent Temper guidance from the exact revision in
  [SOURCE.md](.agent-temper/SOURCE.md), under its own BSD-3-Clause notice. Keep
  `.agent-temper/LICENSE` unchanged.
- Godot is a separate MIT-licensed dependency. It is not vendored in this source
  repository. Its binaries contain third-party components with additional
  notices. Binary distributors must carry the engine and component notices;
  see [Godot's license](https://godotengine.org/license/) and
  [packaging guidance](docs/MAC_PLAYTEST.txt). Existing packaging tooling exports
  engine notices; future platform packages must verify theirs too.
- Audio under `assets/audio/` is original synthesized music and effects, with
  generation source in `tools/build_*audio.py`. Those generators use NumPy,
  a separately installed BSD-3-Clause dependency; NumPy is not shipped here.
- `docs/reference/approved-concept.png` is the original AI-generated art-direction
  reference from project development. It is not an in-game render. Public README
  screenshots are actual native game captures; see their provenance in
  [the screenshot guide](docs/screenshots/README.md).

The public game and its setting are original. Historic design notes mention
other games as inspirations; this repository includes no assets or music from
those games and claims no affiliation with their owners. This inventory is a
source audit, not a substitute for checking future contributions and packages.
