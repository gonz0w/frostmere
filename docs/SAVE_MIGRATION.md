# Frostmere save-folder migration

The application is now named **Frostmere**. Its default save folder is:

| OS | Folder |
| --- | --- |
| macOS | `~/Library/Application Support/Godot/app_userdata/Frostmere/` |
| Windows | `%APPDATA%\Godot\app_userdata\Frostmere\` |
| Linux | `$XDG_DATA_HOME/godot/app_userdata/Frostmere/`, defaulting to `~/.local/share/godot/app_userdata/Frostmere/` |

Quit older versions before starting the new build. On the first normal launch,
Frostmere looks for the sibling folder named `SkyrimCraft • Frostmere`. It copies
`character-v1.json`, `atlas-progress-v1.json`, their backup/temporary/corruption
siblings, and `audio.cfg`. It never edits or deletes the old files. Unrelated
screenshots, logs and test files are not imported. Save schemas and item/quest IDs
are unchanged. Existing corruption/newer-version checks still apply after copying.

If the new folder already contains any character, atlas or audio file, its profile
wins as a whole. Missing pieces are not filled from the older adventure. This avoids
combining a new character with an old atlas. Back up both folders before manually
selecting a different adventure. Copies are not synchronized: going back to an old
build opens the old progress, not changes made in Frostmere.

A completed `identity-migration-v1.txt` marker prevents importing again, even if
save files are later removed. No marker is written when there is nothing to import.
Custom Godot user directories are caller-owned and are never auto-migrated.
Headless world tests, captures, benchmarks and preview modes skip migration.

## If migration cannot finish

Both character and atlas saving are disabled for that session, with an on-screen
notice. A `.identity-migration-pending` directory means copying/commit was started
but not confirmed complete. Do not simply delete it and continue: the destination
may contain only part of the adventure. Originals remain in the historical folder.

1. Quit **all** game versions and back up both complete folders, including hidden
   files, backups, pending data and markers.
2. To retry from the historical profile, rename the entire new `Frostmere` folder
   to an unused backup name outside that location. Keep the old folder intact.
3. Start the new game. It creates a fresh destination and copies the old profile.
   Confirm inventory, quests and atlas before continuing. If the new destination
   had newer progress, preserve that backup and seek help instead of retrying from
   an older snapshot.

If permissions or a disk-full condition caused failure, correct that first.
Never remove the only copy of any save. Report failures with OS, game revision and
steps in [the issue tracker](https://github.com/gonz0w/frostmere/issues); do not post
private saves without reviewing their contents.

Migration is a one-time local copy, not a cloud sync or a multi-instance save lock.
Run only one game version at a time. It does not promise power-loss durability.
The isolated two-process migration fixture exercises sibling-folder discovery on
native macOS, Windows and Linux filesystems in CI; headless filesystem tests do not qualify graphics/input/audio.

For native startup QA, copy the project with `config/use_custom_user_dir=true`
and `config/custom_user_dir_name="Frostmere-Migration-QA"`. In a fresh QA folder,
run `tests/migration_native.gd` with `-- --prepare`, then without that argument
in a separate native process. It copies a synthetic historical profile and tests
normal loading/saving in the dedicated QA directory; it never uses real profiles.
Custom-directory bypass and normal sibling discovery are tested separately.
