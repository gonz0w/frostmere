# Contribute to Frostmere

Read [project policy](PROJECT.md) and the [repository map](docs/REPOSITORY_MAP.md).
Choose an existing issue or propose a bounded change before substantial work.
Wait for scope selection when an issue is backlog or deferred. Include an outcome,
non-goals, observable acceptance and prerequisites; do not duplicate a live roadmap
in a Markdown file. Use the issue for progress and evidence.

## Setup and checks

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

CI currently runs only repository source checks with Python. Engine test automation
and platform qualification are tracked separately. No formatter or GDScript linter
is enforced yet; match neighboring style and use engine parsing plus focused
behavior tests. Godot runtime results are not implied by documentation CI.

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
