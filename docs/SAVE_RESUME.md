# Save and resume

> Verification counts and capture observations below are historical development evidence, not fresh checks. `build/` paths refer to local output omitted from the source checkout; see [evidence guidance](README.md#screenshots-and-development-evidence).

The existing character file now includes an optional session record. Position, active area, first/third-person camera, yaw, pitch, health, magicka, stamina and nearby living enemies' positions/health are written in the same atomic file as equipment, crafting and quest progress. Quest-controlled world changes and defeated/looted actors continue using their existing records. Atlas progress remains in its separate file.

See [save-folder migration](SAVE_MIGRATION.md) for Frostmere paths, automatic
copying from the historical identity, conflicts and interrupted migration recovery.

## Normal play

Start with `Play Frostmere.command`. After the world and actors are built, the game enters the saved area through its normal entry logic and restores the session. Area prerequisites still apply. Every 15 seconds and on character-progress saves, the live session is captured. Escape offers Save adventure and Save and quit. Closing the main window saves before quitting; a failed save keeps the game open.

All fourteen area types are supported: Frostmere, Oldwatch Barrow, Wyrmkeep, Pinehall, Saltbreak, Sunken Lens, Stag Shrine, Ember Caldera, Mirewatch, First Threshold, Northwatch, Caldera Underworks, Aeralis and the Crucible.

Grounded, unobstructed positions restore exactly. A short floor probe and capsule clearance check reject falling or obstructed positions; the authored entrance is retained instead. Unavailable regions fall back to home-world travel positions. Resources are clamped to the current character's limits. Resume grants two seconds of protection. Nearby surviving enemies restore health and supported positions; defeated enemies remain governed by their existing quest state.

## Backup and corruption recovery

Each successful replacement validates the outgoing data and retains the previous
valid primary as `.bak`. Startup prefers a valid primary; otherwise it restores
a validated backup and shows a recovery notice. Recent progress may be lost.
On the next successful save, rejected primary bytes are kept as `.corrupt`
(or a numbered suffix) without replacing the good backup with corrupt data.
Character and atlas are independent snapshots, not a single transaction.

If neither copy is valid, or either copy has a newer schema version, startup
shows a warning and disables **both** character and atlas saving for the session.
You may quit or continue without saving. An abandoned `.tmp` alone is preserved
and does not authorize starting a new profile over it. A valid primary takes
precedence over an abandoned temporary file. Write or validation failures leave
the durable primary intact; ordinary save-and-quit stays open after failure.

Before manual recovery, quit and copy the entire user-data folder somewhere safe.
Use the matching game version for newer saves. Do not delete the only remaining
copy to dismiss a warning. There is no in-game repair editor. Temporary files are
not promoted automatically. Keep `.bak` and `.corrupt` files when reporting a
recovery problem, and remove personal details before sharing them.

The isolated `tests/save_recovery.gd` covers corrupt files, incompatible schemas,
interrupted temporary files and failed writes. `tests/recovery_restart.gd` runs
first with `-- --prepare`, then in a separate headless process without that
argument to verify inventory, quest and atlas recovery. Neither fixture accesses
the normal profile. These checks do not establish power-loss durability or
native Windows/Linux qualification.

## Compatibility and limits

Older files without a session record retain the usual starting location. Malformed records are rejected before character state is applied. Native previews, automated captures and headless runs cannot save to the regular profile. Tests write temporary fixture files; the real native relaunch check uses the separate `SkyrimCraft-Session-QA` user-data directory.

This remains one current profile. Multiple save slots and a save-selection screen are future work. Projectiles, enemy attack windups/cooldowns, open dialogue/menu state, player velocity and temporary combat timers restart rather than being serialized. The saved snapshot does not include every distant actor's transient position. Forced termination can lose movement/resource changes since the last autosave; ordinary save-and-quit writes immediately.

Wilderness creatures now populate home-world session snapshots; inactive barrow enemies remain excluded by the active combat roster. Their defeated and harvested IDs live in an optional validated `wilderness` character record. Older saves default to no wilderness defeats or claims.


## Repeated disk round-trip coverage

The isolated tests/save_cycle_stress.gd fixture performs 24 cycles across home, Pinehall, Wyrmkeep and Oldwatch. Each cycle writes the live character/session, loads a fresh CharacterState, saves that loaded state again and loads a second fresh state before restoring its session. This exercises 48 file replacements and 48 fresh-state loads. It checks that successful atomic replacement leaves no temporary save file.

A real forged sword upgrade, equipped/favorited item identity, material counts, growing inventory IDs, player resources and a real defeated/harvested wolf are preserved. Reconstructed wolf nodes remain dead with their loot label hidden. Only six deliberately added items appear, and a final return cannot harvest the original wolf again. Test files use a dedicated user://save-cycle-stress.json name and are removed afterward; the normal save remains inaccessible through the fixture's session persistence.

221 checks passed, plus 73 session regression checks: 294 total. This does not restart the whole application between cycles, simulate interrupted writes, or replace long-duration player testing.


## Native restart with an abandoned temporary save

The extended tests/session_boot.gd now runs across two native Godot processes against the separate SkyrimCraft-Session-QA user directory. The first seeds an isolated completed-intro profile, forges/equips/favorites a sword, defeats and harvests a wolf, travels to Wyrmkeep, and saves position, camera and resources. It then writes an intentionally truncated character .tmp file while preserving the valid primary save.

The second process uses normal automatic character/session loading. It verifies Wyrmkeep, position, health/magicka/stamina, camera, inventory/materials/gold and the reconstructed harvested wolf. The incomplete .tmp file is ignored; a subsequent successful save replaces/removes it normally. Both phases passed on the M5 Max. This models interruption before rename, not power failure during filesystem replacement or corruption of the primary file.

Run only from a copied project configuration with config/use_custom_user_dir=true and config/custom_user_dir_name="SkyrimCraft-Session-QA". The fixture asserts the QA directory before accessing a save. Launch tests/session_boot.gd with -- --save-session-fixture first, then without that user argument in a new native process. Do not pass --capture or run headless: this specifically exercises persistent native startup in the QA directory. The setup phase intentionally resets that QA profile.

The native `tests/recovery_notice.gd` fixture requires a copied project with the
custom user directory `Frostmere-Recovery-QA`. Run `-- --prepare`, then without
arguments, then `-- --blocked` in separate native processes. It tests real startup
recovery, disables both writers on incompatible atlas data, and captures the
notices. Never point this fixture at the regular profile.
