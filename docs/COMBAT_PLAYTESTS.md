# Combat playtest recording

Start a development playtest from the project directory:

```sh
.tools/Godot.app/Contents/MacOS/Godot --path . -- --combat-metrics
```

This uses the normal game and saves. The optional recorder writes a separate local `user://combat-playtests.jsonl` file. It is off for ordinary launches, sends nothing over the network, and adds no fields to character saves. It stops logging if the file cannot be opened or reaches approximately 4 MB; move the log before starting a new recording session.

On this Mac, summarize a recorded session with:

```sh
python3 tools/summarize_combat_metrics.py "$HOME/Library/Application Support/Godot/app_userdata/SkyrimCraft • Frostmere/combat-playtests.jsonl"
```

The report goes to standard output. The JSON contains equipment and derived stats at both boundaries, ancestry/playstyle, area, damage dealt/taken, kills, parries, ammunition spent, melee/spell attempts, consumables used and actual restoration. Empty attacks count as activity; practice swings or missed shots can therefore create segments with no targets. Looting does not subtract from consumption counts. Successful potions outside a combat segment are not recorded.

Segments begin with an attack attempt, damage or parry. Ten seconds without combat activity ends a segment as `disengaged`, not victory. Area changes, death and exiting the game have separate end reasons. Active duration uses unscaled engine frame time, excludes paused menus, and removes the trailing inactivity interval. Long dodging/repositioning periods can split one fight into multiple segments. Analyze related segments together rather than treating every row as a complete encounter.

Death captures zero health before respawn. Travel is detected at the next event/frame; its ending snapshot may reflect the destination, identified by `end_area`. Session-end recording requires a normal shutdown; a crash or forced kill can lose the unfinished segment. No continuously written event trace or autosave recovery is provided.

For campaign testing, record the route and intended build alongside each log. Start with mage and ranger runs through the station, Aeralis and Crucible, then shield and dagger builds to examine stamina pressure. Compare actual equipment, supplies, deaths and whether boss openings were used. These logs do not measure player intent, exact hit accuracy, FPS or full campaign completion time.

Validation uses `tests/combat_metrics.gd` with a separate `combat-metrics-test.jsonl` fixture and disabled profile persistence. `build/combat-metrics-test-report.md` is synthetic QA data, not a human playthrough.
