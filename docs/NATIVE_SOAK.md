# Native session soak

Run `python3 tools/run_native_soak.py --godot /path/to/Godot` on macOS to exercise
four 30-minute native processes. A shorter pilot uses `--seconds 65 --segments 2`.
Only at least four processes and 7,200 seconds of recorded active workload meet
the duration condition. A successful pilot does not qualify a long session.

The runner creates a unique copied project configuration and custom
`Frostmere-Soak-QA-<random>` user-data directory. Source/assets are linked from the
checkout; do not edit source during a qualification run. Normal game save paths
are never used. The fixture asserts its QA directory before any write. Evidence
is retained under `build/native-soak/<random>/`; profile data is retained in the
engine's separate QA directory. No player profile is removed or reset.

Every 30 seconds the workload crafts an iron dagger through the normal crafting
method, visits Wyrmkeep, and alternates Aeralis/Crucible. Ordinary autosaves remain
active; explicit saves and atlas round trips are checked too. Fresh processes
verify inventory, equipped identity, materials, gold, crafting XP, story gates,
atlas visits and saved area. Three enemies use real AI, and scripted player melee
must produce attacks, hits and enemy windups in each full combat window. The
player is repositioned periodically to sustain contact. Native focus-loss pauses
are explicitly resumed for unattended execution.

Prerequisites and materials are seeded, player invulnerability/stamina are
maintained and enemy health is enlarged within the existing save schema. This
is a stability workload, **not** earned-resource balance or human campaign play.
It is capped at 60 FPS at 1280×800 with the existing Mobile renderer. Audio stays
active; it does not establish subjective mixing quality or other hardware support.

Reports keep node, resource and orphan counts; Godot static allocator MiB;
separate macOS process RSS samples; inventory growth; combat/craft/travel counts;
frame p95/p99 upper bounds, maximum and intervals over 250 ms. The bounded
millisecond histogram uses the observed maximum for its overflow bucket.
Frames include travel/save work. Counts sampled around travel can include queued
frees and active effects; they are not settled lifecycle counts. RSS is not VRAM.

The runner stops on engine errors, missing completion markers, insufficient
active duration, failed restart comparison, RSS sampling failures while the
process is alive, or a segment exceeding its duration plus 120 seconds. Logs
and partial RSS data survive failures. Four Python failure-detection tests can
run without Godot: `python3 -m unittest discover -s tests -p test_native_soak.py`.
Process RSS access must be permitted by the host sandbox.

A completed report is collected evidence, not automatic leak-free qualification.
Inspect activity windows, errors, memory trends within and across processes,
inventory growth and stalls before accepting [issue #9](https://github.com/gonz0w/frostmere/issues/9).
Compare equivalent workloads and note background applications. Do not extrapolate
M5 results to M1 or Windows/Linux. Keep actual run outcomes and outstanding work
in the issue rather than treating this procedure as a progress log.
