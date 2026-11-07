# Accessibility preferences

Open **Esc → Accessibility**. Changes apply immediately; normal play saves them in
`accessibility-v1.json` beside the adventure files. Defaults preserve the original
presentation. Restore defaults resets only these preferences, not controls or saves.

- **Opening subtitle size:** 100%, 125% or 150% for the playable opening's text.
- **High-contrast opening subtitles:** a dark backdrop behind the opening text.
- **Reduce first-person weapon motion:** softens melee swings, power-attack hand
  rolls and finishing hand poses to 15% of their normal displacement. Third-person
  actor animations, camera look, damage, cooldowns and slow-motion timing remain
  unchanged.
- **Reduce opening and lightning flashes:** steadies the opening ward's pulsing
  light, dims chain-lightning lines and removes emissive finisher fragments.
- **Show finisher fragments:** disable to suppress newly spawned finishing bursts,
  including flesh-colored fragments. This does not remove enemies, corpses, normal
  death animations or all violent imagery.

Escape returns to the pause menu. Tab/Shift+Tab and arrow keys navigate the settings
with the keyboard; the settings list scrolls when vertical space is limited.

Preferences use a temporary file before replacement. Failed writes show that the
change applies only to the current session. Invalid or newer settings activate
original defaults and a warning; editing a preference explicitly replaces that
file. Preview/capture/headless sessions do not load or save the normal preference file.
Blocked recovery sessions cannot save preferences; if atlas recovery blocks later
in startup, preferences may already have been read. Fixtures use isolated files under `build/`.
See [save paths](SAVE_MIGRATION.md) before manually backing up settings.

## Coverage and remaining work

These controls target the specific presentation effects listed above. They are not
a global flash filter, a guarantee of photosensitive safety, or accessibility
certification. Existing directional hit feedback uses both an arrow and written
outcome labels; this batch does not qualify every enemy telegraph.

General HUD/menu scaling, broader subtitle/dialogue and color-independent telegraph
coverage, and the full smaller-display/HiDPI/ultrawide and human review remain in
[#22](https://github.com/gonz0w/frostmere/issues/22). Automated tests cover persistence,
UI application and cosmetic-state isolation; native previews do not replace the
owner's deferred final testing.
