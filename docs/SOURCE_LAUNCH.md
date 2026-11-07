# Launch and verify from source

Players with the Windows ZIP can run its EXE directly. These commands are for
source checkouts and require Python 3.11+, Git and the standard official Godot
version pinned in [the platform contract](PLATFORMS.md).

After cloning, install the verified engine for your host using `toolchain.py`
as described there. Run from the checkout:

```sh
python3 tools/play.py
```

On Windows use `python` if that is your Python command. The same command works
on macOS and Linux. For paths with spaces or Unicode, quote the script or engine
path in your shell:

```sh
python3 "Frostmere QA 雪/tools/play.py" --godot "/path with spaces/Godot"
```

Explicit `--godot` paths are resolved relative to your current directory; PATH
commands are accepted. Otherwise the launcher tries the host's pinned setup,
`godot` on PATH, then existing macOS app locations. A missing explicit path or a
wrong engine version stops with an error; it does not silently switch engines.
Use the Windows console executable when supplying an official Windows editor.

The launcher verifies the version and runs a bounded import before normal play.
An import failure stops before starting the game; inspect `build/launch/import.log`.
Normal play uses your existing saves, just like F5 in the Godot editor. The legacy
`Play Frostmere.command` and other macOS launchers remain available with their
existing behavior; the Python entry point is the version-checked portable route.

For verification without normal character/atlas persistence:

```sh
python3 tools/play.py --smoke
python3 tools/play.py --verify
python3 tools/play.py --regression
```

All three use the same engine selection/version check and headless runner.
Smoke runs import, save isolation and movement smoke. Verify additionally runs
character, session, corruption recovery and fresh-process restart checks. Both
also run migration, controls and accessibility fixtures. Regression adds the
selected combat/economy and chapter groups documented in
[contributor checks](../CONTRIBUTING.md). Engine
errors, failed assertions, missing completion markers or timeouts cause a nonzero
exit. Each check has a bounded timeout (normally 180 seconds); logs/results are
retained in `build/ci/`. These commands do not enter normal gameplay. Run one suite
at a time per checkout because they share logs and dedicated QA fixtures.

For custom log locations/timeouts, invoke `tools/run_headless.py` directly with
`--godot`, `--logs` and `--timeout`; `--smoke` limits it to the short suite.
`--group core|combat|chapters|all` selects a bounded group (default core); non-core
groups cannot be combined with `--smoke`. Results record the selection.
No shell command concatenation is used to launch the engine. CI exercises clean
space/Unicode checkout paths on Windows/macOS/Linux; native rendering, focus,
audio and gameplay still require real platform testing.
