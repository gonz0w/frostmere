# Portable development packaging

Use Python 3.11+, Git, the pinned standard Godot engine, and the matching official
export templates. The [toolchain setup](PLATFORMS.md) verifies upstream hashes:

```sh
python3 tools/toolchain.py --install linux
python3 tools/toolchain.py --download-templates
python3 tools/package_game.py --target linux --templates .tools/downloads/godot-4.7.2-templates.tpz
```

Substitute your host in the install command (`windows`, `macos`, `linux`). Windows
users may use `python` instead of `python3`. `--target windows` produces a ZIP;
`--target linux` produces a tar.gz preserving the executable bit. Either target
can be cross-exported from any supported build host. Use `--godot "engine path"`
to override the verified host setup. Paths with spaces/Unicode are supported.

`--target macos` requires macOS with `lipo`, `codesign` and `ditto`; it preserves
the existing arm64-only, ad-hoc-signed behavior. It derives the thin template from
the verified official archive in temporary staging, without modifying a global
template installation. No signing credentials or notarization are used. The old
`package_windows.py` and `package_macos.py` commands forward to the shared builder;
both accept the same explicit `--templates` and optional `--godot` arguments.

Commit tracked changes before building. The builder refuses dirty tracked files
and existing output names. It stages only tracked assets/data/scenes/scripts/
shaders and project/preset configuration, so local profiles, tools, tests, policy,
history galleries and secrets outside that runtime set never enter the export.
Untracked runtime files are omitted. Keep runtime credentials out of source.

The builder imports cleanly, exports, validates Windows PE/Linux ELF architecture,
checks macOS signatures, and uses the matching engine to inspect the PCK contents
without loading a game session. It then bundles player instructions, BSD license,
engine/component notices and BUILD.json (source commit, engine/template provenance
and file hashes). The completed archive is inspected against that manifest before
it appears in `dist/`, alongside its `.sha256`. Linux archives must retain an
executable binary. Failed import/export logs stay in `build/packages/<target>/`.
Archives and local engine/template downloads are ignored by Git.

This is reproducibility from identified source and dependencies, not a promise of
byte-identical archives across hosts: ZIP/tar timestamps and signing metadata can
differ. CI builds/inspects native-host archives on Windows, Linux and macOS and
retains diagnostic logs, not downloadable game artifacts. Creating a public release
still needs owner approval. The existing Windows tester prerelease is unchanged.

Player instructions: [Windows](WINDOWS_PLAYTEST.txt), [Linux](LINUX_PLAYTEST.txt),
[macOS](MAC_PLAYTEST.txt). A successful export or headless PCK inspection does not
qualify native graphics, input, audio or campaign play. Linux qualification remains
[#27](https://github.com/gonz0w/frostmere/issues/27), Windows
[#26](https://github.com/gonz0w/frostmere/issues/26), and M1
[#25](https://github.com/gonz0w/frostmere/issues/25).
