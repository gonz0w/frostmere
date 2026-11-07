# Windows tester builds

The Windows command is a compatibility entry point to the shared
[portable packager](PACKAGING.md), which also builds Linux and macOS archives.

The Windows x86_64 development package targets Windows 10/11 with current
Vulkan-capable drivers. Native graphics/input/audio/save acceptance belongs to
[#26](https://github.com/gonz0w/frostmere/issues/26); export success is not support
qualification. The [tester instructions](WINDOWS_PLAYTEST.txt) ship inside the ZIP.

Use Python 3.11+, Git and standard Godot 4.7.2 on the build host. Download the
[official standard export templates](https://github.com/godotengine/godot-builds/releases/download/4.7.2-stable/Godot_v4.7.2-stable_export_templates.tpz).
The packager verifies the pinned SHA-256 before extracting only the Windows x64
templates. It accepts an explicit engine path, including paths with spaces:

```sh
python3 tools/package_windows.py --godot /path/to/godot --templates /path/to/Godot_v4.7.2-stable_export_templates.tpz
```

Commit tracked changes first. The builder copies tracked runtime directories into
an isolated staging project, imports cleanly, exports the Windows preset and checks
the PE architecture. Export errors fail even with exit code zero. The ZIP under
`dist/` includes EXE/PCK and engine sidecars, BSD license, component notices, tester
instructions and BUILD.json containing revision/template/file hashes. A separate
`.zip.sha256` verifies the archive. Existing archives are never overwritten.
Build logs remain in ignored `build/packages/windows/`. Source identity is reproducible;
byte-for-byte identical archives across hosts are not promised.

No game session or normal saves are opened by the builder. The Frostmere identity uses
[copy-only migration](SAVE_MIGRATION.md) at normal game startup. The runtime
allowlist excludes tests, development policy, tools, galleries and local files.
The preset's template paths are filled inside staging; an editor-only export
requires extracting matching templates to those paths manually.

Run `python3 -m unittest discover -s tests -p test_windows_package.py` for template
checksum and architecture rejection checks. Run the core checks in CONTRIBUTING.md
before integration, then inspect the package and test on real Windows hardware.
Publishing a tester prerelease requires owner authorization; #45 records the
current Windows tester request. Stable release and Linux work retain their gates.
