# Keyboard and mouse controls

Open **Esc → Controls & mouse settings**. Select an action, then press a key or
mouse button. Bindings apply immediately and update gameplay hints. Conflict
messages name the existing action; move that action to another key before reusing
its binding. Each action has one binding. Mouse wheel bindings are not supported.

Hold Shift while pressing another key to bind a combination. To bind Shift alone,
press and release it. Shared keys with different Shift modifiers are rejected to
avoid triggering two actions, except the existing Whirlwind/Sundering Strike pair
(default G / Shift+G), which uses exact matching. Ctrl, Alt and Meta combinations
are reserved for the operating system. Escape cancels a pending bind; pressing it
again returns to the pause menu. Tab, Enter and Escape remain fixed for menu
navigation and opening-skip behavior, so changing gameplay keys cannot remove the
way back to settings.

Defaults use physical key positions. The controls screen shows the active keyboard
layout's labels, including on non-US layouts; focus the game again after changing
keyboard layout. Existing mouse/keyboard action semantics, camera modes and save
progression are unchanged. Controller support is separate work.

Mouse sensitivity and **Invert vertical mouse look** affect both camera modes.
**Restore defaults** resets all gameplay bindings and both mouse options. Losing
focus pauses the game, releases held gameplay actions and exposes the cursor;
returning focus does not resume gameplay automatically.

Settings are stored separately from adventures in `controls-v1.json` in the
[Frostmere user-data folder](SAVE_MIGRATION.md). Successful changes replace the
settings file through a temporary file. Invalid/newer settings load defaults with
a warning in the controls menu; editing settings explicitly replaces that file.
Failed writes keep the current session's changes and show that they were not saved.
Isolated tests/captures and sessions with adventure persistence disabled never load
or save normal control settings. Test fixtures use dedicated files under `build/`.

Automated model/UI checks cover conflicts, persistence, invalid data, fixed escape,
remapped camera input, look calculations and focus loss. Native preview checks cover
the settings screen. Human first/third-person input and non-US keyboard-layout
qualification on each target OS remain part of final testing in
[#21](https://github.com/gonz0w/frostmere/issues/21), not implied by headless CI.
