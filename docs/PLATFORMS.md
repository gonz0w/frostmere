# Platform and toolchain contract

These are development/qualification targets, not a claim that every listed
machine runs Frostmere well. Keep native game acceptance separate from a successful
headless import or export. The Mobile renderer and historical application/save
identity remain unchanged.

| Target | Initial OS and architecture | Graphics path | Evidence needed |
| --- | --- | --- | --- |
| macOS | macOS 13+, Apple Silicon arm64 | Metal 3 or newer, Mobile | M5 native evidence exists; M1 / 32 GB remains the baseline to qualify in #25. |
| Windows | Windows 10/11, x86_64 Intel/AMD with SSE4.2 | Vulkan, Mobile, current vendor driver | Experimental package available; native input/audio/render/save checks in #26. |
| Linux | Ubuntu 22.04 or newer, x86_64 with SSE4.2 | Vulkan, Mobile, current vendor driver; X11 initial desktop target | Headless Ubuntu 24.04 CI is source evidence; native checks remain #27. Other distributions and Wayland need separate evidence. |

Vulkan 1.0 is the engine API floor; Vulkan 1.2-capable hardware is the preferred
qualification target. This does not establish a game GPU/RAM/FPS minimum. Native
hardware budgets remain #25/#26/#27/#29. OpenGL Compatibility and Direct3D fallback
are not qualified game configurations. Windows/Linux ARM, Intel Mac release builds,
mobile and web exports are outside this initial target set.
[Godot system requirements](https://docs.godotengine.org/en/stable/about/system_requirements.html)
explain the engine floor; our game needs its own measurements.

## Pinned dependencies

[tools/toolchain.json](../tools/toolchain.json) records official standard Godot
4.7.2 engine archives for macOS, Windows and Linux, plus the matching export
template archive. SHA-256 values come from the corresponding official
[godot-builds release assets](https://github.com/godotengine/godot-builds/releases/tag/4.7.2-stable).
Use standard binaries, not .NET/Mono. Python 3.11+ and Git are contributor tools;
players of packaged builds need neither. Pin changes require review, updated
matching templates and verification; do not substitute a newer engine silently.

For a command-line engine in this checkout, run the matching command:

```sh
python3 tools/toolchain.py --install macos
python3 tools/toolchain.py --install windows
python3 tools/toolchain.py --install linux
```

Run only your host's command. On Windows, `python` may replace `python3`. This
downloads and verifies the selected archive, extracts its CLI executable(s), preserving the signed macOS app bundle
into `.tools/pinned/<platform>/`, then checks the official engine version.
The macOS CLI is `Godot.app/Contents/MacOS/Godot` inside that bundle. `--archive "path with spaces/engine.zip"`
uses an existing archive with the same checksum check. Mismatch or download failure
stops setup; it never launches an unverified archive. Existing downloads are not
trusted by filename alone. System engine installations and player saves are untouched.

Append `--import-check` to perform a bounded headless editor import. This creates
local `.godot/` cache and import metadata without running a game session. Diagnostics
are retained under `build/toolchain/`. Windows/macOS CI uses this check; Linux CI
runs the core fixture runner, which starts with the same clean import. Hosted CI
OS/CPU evidence does not establish the OS floor or native graphics support.

To check an already downloaded official template archive:

```sh
python3 tools/toolchain.py --verify-templates /path/to/Godot_v4.7.2-stable_export_templates.tpz
```

The [portable packager](PACKAGING.md) consumes this same manifest for Windows,
Linux and macOS. `--download-templates` downloads and verifies the archive locally;
verification alone does not install templates globally.

## Optional audio authoring

Committed WAVs play without Python packages. Regeneration scripts
`tools/build_audio.py`, `build_combat_audio.py`, `build_intro_audio.py` and
`build_station_audio.py` use NumPy. For optional authoring, create a Python virtual
environment and install NumPy there (`python -m pip install numpy`). NumPy is not a
runtime dependency or a pinned audio-reproduction guarantee; record its version
when changing generated assets. Rebuilding audio is not part of engine setup/CI.

## Portability audit boundary

`python3 tools/toolchain.py --audit` checks tracked filename case collisions and
complete literal `res://` file references in runtime GDScript/scenes/shaders and
project configuration against exact Git spelling. Generated `res://build/` outputs
are excluded. It does not prove computed-path coverage; clean imports and targeted
runtime tests (including the 41-cue audio fixture) complement it.

Runtime code uses Godot resources and `user://` storage; no runtime process launch
or shell API was found in this audit. The screenshot fixture uses `TMPDIR` with a
`user://` fallback. Existing `.command` launchers, macOS packaging (lipo/codesign) and
native-soak RSS sampling (`ps`, macOS-only) remain explicitly host-specific.
[Source launch/verification](SOURCE_LAUNCH.md) and [packaging](PACKAGING.md) provide
the portable routes; the full regression matrix remains #28. Native screenshots, audio and timing still
require actual hardware. Application identity migration remains #20; do not rename
save directories as a setup step.
