# Contribute to Frostmere

Read [project policy](PROJECT.md) and the [repository map](docs/REPOSITORY_MAP.md).
Choose an existing issue or propose a bounded change before substantial work.
Wait for scope selection when an issue is backlog or deferred. Include an outcome,
non-goals, observable acceptance and prerequisites; do not duplicate a live roadmap
in a Markdown file. Use the issue for progress and evidence.

## Setup and checks

See [platform targets and verified engine setup](docs/PLATFORMS.md) for the pinned
engine/template manifest, OS/API boundaries and optional audio authoring tools.

Install Godot 4.7.2 and Python 3.11+. The commands below run from the repository
root. Use the full path to Godot if it is not on PATH. On macOS that can be
`/Applications/Godot.app/Contents/MacOS/Godot`; on Windows use the console binary.
No packages are needed to play or run these checks. Audio regeneration requires
NumPy separately and is not part of ordinary checkout validation.

```sh
python3 tools/verify_repo.py
godot --headless --path . --editor --import --quit
godot --headless --path . --script tests/smoke.gd
godot --headless --path . --script tests/characters.gd
godot --headless --path . --script tests/session_save.gd
```

On Windows use `python` if Python is not named `python3`. Import first in a clean
checkout. Headless game fixtures disable normal character/atlas persistence;
do not add `--capture` to input-driven headless tests. Run suites relevant to
changed contracts too: combat, crafting, atlas, chapter and presentation fixtures
are in `tests/`. Test-first defects should include the failing result and fix.
Stop on assertions, script errors or nonzero exit. A timeout is a failure to
establish the result. Do not weaken tests to force a green run.

For documentation/policy/screenshots: run `verify_repo.py`, check factual claims
against source, inspect screenshots and perform a fresh-reader review. For engine
configuration or runtime code: import, the three core suites above, affected
suites and appropriate native checks are required. Artwork, controls, audio and
rendering changes need native inspection; performance claims need hardware,
renderer, resolution and workload recorded. Do not extrapolate M5 to M1 or Windows.

CI runs repository checks, runner rejection tests and the core headless fixtures
on a clean Ubuntu 24.04 checkout. It downloads the official standard Linux x86_64
Godot 4.7.2 archive and verifies the SHA-256 in `tools/toolchain.json`.
Separate Windows and macOS jobs verify the same pinned version and clean source
import, without native graphics/input/audio qualification.
Updating that pin requires a reviewed engine-version change. No PR secrets,
write token or self-hosted runner is used. This is headless regression evidence,
not native Linux graphics/input/audio qualification.

Run the same bounded fixture runner locally (use your actual engine path):

```sh
python3 -m unittest discover -s tests -p test_headless_runner.py
python3 tools/run_headless.py --godot godot
```

The runner checks the engine version, imports resources, verifies headless save
isolation, then runs smoke, character, save/session, corruption recovery and two-process
restart checks. It stops at the
first failure, including zero-exit Godot errors or missing completion markers.
Each import/suite has a 180-second timeout (override with `--timeout`, at most
600 seconds). Logs and `results.json` go to ignored `build/ci/`; CI retains them
for seven days even after failure. Download/setup failures are in the Actions
step log. Inspect the failing log before retrying. The six Python tests include
intentional failing subprocesses; their successful rejection is the expected result.
Native platform qualification and the wider suite matrix remain separate work. No formatter or GDScript linter
is enforced yet; match neighboring style and use engine parsing plus focused
behavior tests. Godot runtime results are not implied by documentation CI.

The portable [source entry point](docs/SOURCE_LAUNCH.md) supports
`python3 tools/play.py --smoke` for bounded import/isolation/movement checks and
`python3 tools/play.py --verify` for the full core runner. Windows/macOS CI runs
source smoke and Linux runs the full core suite from fresh checkouts whose paths
contain spaces and Unicode. This establishes source command portability, not
native GPU/audio/input qualification.

The two-process `tests/save_migration.gd` fixture also runs in smoke/full modes
on every native host, using only `build/migration-fixture 雪/`. It verifies copy
integrity, profile precedence, repeat launches and interrupted migration guards.
Do not point migration fixtures at real player folders.

CI also builds and inspects development packages on each native host using the
[pinned portable packaging workflow](docs/PACKAGING.md). It retains package logs,
not game archives, and does not publish releases or qualify native rendering.

## Review and integration

Use a focused branch and PR to `main`, linking the selected issues and checks.
Map each accepted requirement to evidence and state unavailable verification.
A separate human or reviewer agent examines the final candidate. Resolve findings
before merge. Agents may merge under PROJECT.md; release publication still needs
the owner's request. Follow BSD-3-Clause and retain third-party notices. Do not
include engine binaries, build output, normal saves, secrets or personal paths.

For bugs, include revision, OS/architecture, Godot version, renderer, steps and
expected/actual behavior. Sanitize logs and save snippets before sharing. See
[SECURITY.md](SECURITY.md) for sensitive reports.
