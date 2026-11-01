# Music and sound

> Verification counts and capture observations below are historical development evidence, not fresh checks. `build/` paths refer to local output omitted from the source checkout; see [evidence guidance](README.md#screenshots-and-development-evidence).

The original synthesized score has nine tracks: eight exploration/battle loops
and a 48-second opening loop, totaling about 10.3 minutes before repetition.
There are 32 interaction/combat effects. No external samples or existing game
melodies are used. Pulse leads, triangle basses, bells, echoes and noise percussion
retain the old-school character. See [catalog sources](CONTENT_REFERENCE.md).

| Cue | Working title | BPM | Character |
| --- | --- | --- | --- |
| wander | Lanterns Along the Old Road | 76 | Slow minor-key wandering melody and soft percussion |
| battle | Hold the Northern Pass | 132 | Faster pulse lead, driving bass and drums |
| aeralis | Gardens Above the Sky | 92 | Bright bells, major-seventh harmony and airy arpeggios |
| aeralis_battle | The Crystal Vanguard | 144 | Crystal palette with a faster combat arrangement |
| crucible | Beneath the Furnace | 94 | Low distorted-style saw bass and chromatic industrial pulse |
| crucible_battle | Iron in the Inferno | 152 | Aggressive riffs and rapid noise drums |
| station | A Signal in the Dark | 88 | Sparse bell figures, sustained suspended harmony and pulse bass |
| station_battle | Command Override | 136 | Faster station motif with driving drums |
| intro | Ash Through the Snow | — | Slow minor-key harmonies, bell echoes and low drone |

Music crossfades over two seconds. A visible living enemy in its active area within 21 meters, or receiving/dealing damage, engages combat music. Six seconds without an engagement releases it. Realm entry selects that realm's exploration/battle pair; returning home restores the Nordic palette. Menus lower music and freeze the combat-release timer.

Sounds cover footsteps, melee swings, impacts, shield blocks, bows, automatic gunfire, spells, wall impacts, death, healing, interaction/menu confirmation, loot/trade, gathering, forge work, enchanting, main-story completion and realm transitions. Twelve non-positional effect voices and per-cue cooldowns bound rapid overlapping playback. Critical reveal/death cues can reclaim a lower-priority slot; footsteps cannot evict those cues. General effects use a centered stereo mix; four monster warnings now use positional 3D audio. Grass, snow, stone, wood and metal footsteps now have a first surface-aware pass; environmental ambience remains future work.

Press Escape for separate Master, Music and Effects sliders. Zero mutes the corresponding control. Normal play stores preferences in `user://audio.cfg`; isolated chapter previews can change levels for the session without overwriting preferences. Automated/headless runs are silent by default.

## Assets and regeneration

`assets/audio/music/` and `assets/audio/sfx/` contain 22,050 Hz, stereo, 16-bit WAV files (about 56 MB together). The music has full-file loop regions, circular delay tails and three-millisecond endpoint fades. The runtime loads Godot-imported audio resources, including inside exported packages, with a raw-WAV fallback for unimported development runs. Loop endpoints use sample duration rather than compressed byte size. [The audio manifest](../assets/audio/manifest.json) records duration, peak and RMS measurements. Paths under `build/` below are locally generated previews, not files shipped in the public source.

`tools/build_audio.py` is the deterministic composition and synthesis source. Run with Python and NumPy to regenerate all 41 assets. The project-local runtime uses `scripts/audio_director.gd`; no synthesizer or Python dependency is needed to play.

`build/soundtrack-preview.wav` is a 48-second sampler: eight seconds each of wandering, battle, Aeralis, Aeralis battle, Crucible and Crucible battle. `tests/audio.gd` verifies the audio state machine and UI hooks; `tests/render_audio.gd` records actual native engine output and captures the volume controls using an isolated preview.

The station extension is authored in `tools/build_station_audio.py`; the full generator runs it automatically and merges its two loops into the manifest. The older six-track sampler does not include these new cues.

## Monster warnings and charged impacts

Five additional original synthesized cues are built with the standard-library-only `tools/build_combat_audio.py`. The full audio generator invokes it after the station extension and merges metadata into the manifest. Root warning: 0.75 seconds; brine warning: 0.65; ash inhale: 0.85; solar charge: 0.80; charged impact: 0.32. Assets are 22,050 Hz stereo PCM with faded edges and a 0.62 peak.

Each monster cue is requested at windup start, and charged impact at the animation strike frame. They share the Effects volume control and per-cue cooldowns. The player impact uses the twelve-voice non-positional pool; the four monster warnings use the separate six-voice 3D pool. The four monster warnings now use positional one-shots, stopped on menu, travel, death, stagger or execution lock; the player impact remains centered. The visual warnings remain authoritative. `build/combat-cues.wav` previews root, brine, ash, solar and power impact in that order, with half-second gaps. Speaker/headphone mix tuning remains open.

## Directional monster warnings

Six pooled AudioStreamPlayer3D voices follow the four warning sources, with a six-meter unit distance and a 32-meter maximum distance. The active camera provides listener orientation. Both first- and third-person play retain visual warnings. Cues share the Effects volume control and per-cue cooldown; a full pool reuses a voice instead of allocating more. Interrupted or freed sources release their voices. Stereo recordings from the native engine verified left/right channel dominance; this is directional panning and distance attenuation, not wall occlusion or HRTF simulation.

## Terrain-aware footsteps

Grass, snow, stone, wood and metal use five original synthesized cues. A floor ray selects metadata from collision geometry; Frostmere terrain consults the same cobbled-path cells and exact snow-patch rectangles used to build its visible ground. The surface sample is taken only when a grounded, moving player is due a footstep. Existing walk/sprint cadence, quiet footstep gain, pitch variation and Effects volume remain in use.

Shared town houses now have inset plank floors tagged as wood, leaving their stone thresholds visible. The station deck uses metal footfalls. Exposed house plinths, bridge collision and untagged solid floors use stone. Unsupported/no-floor queries retain the original neutral step. Water splashes and further region-specific terrain coverage remain expansion work. The new data is derived at world construction and does not change saves. `build/footstep-cues.wav` previews grass, snow and stone in that order.

The combat/footstep generator also produces the three creature-finisher cues described below, for thirteen cues in total. Wood uses a short low knock; metal adds a brighter ringing decay. `build/wood-metal-steps.wav` previews three wooden steps followed by three metal steps.

## Opening prelude

Ash Through the Snow now selects its own original 48-second stereo synth loop, independent of the combat meter. Rounded minor-key harmonies, sparse bell echoes and a low drone accompany the snowy road. A 2.8-second ward_approach cue starts at the reveal; a 1.8-second ward_holds cue resolves the retreat. These cues use the Effects bus and existing bounded pool, freeze with menu pauses, and stop on completion or skip. Nordic music returns through the normal crossfade. tools/build_intro_audio.py generates the three assets and merges their manifest metadata; the full generator invokes it too. Subjective speaker/headphone mix review remains open.


## Creature finisher impacts

Three original synthesized effects now accompany successful lethal finishers: finish_shell (0.55 seconds) for Hullcarver, finish_crystal (0.70) for Prismwing and finish_furnace (0.85) for Furnace Maw. Shell uses short cracking noise over a descending low tone; crystal uses staggered high ringing fragments; furnace uses a descending rumble, metal resonance and a noise tail. No sampled or third-party audio is used.

The cues play once after confirmed defeat at the existing weapon impact frame, alongside the normal hit cue. They use the bounded non-positional Effects pool and volume control. Wind-up/cancellation does not play them, and ordinary kills retain existing audio. tools/build_combat_audio.py now generates thirteen cues; the full audio generator already invokes it. Total catalog: nine music tracks and thirty-two effects. Source peaks are capped at 0.45 to leave mix headroom. build/finisher-audio-engine.wav previews actual sword finishers in shell, crystal, furnace order. Subjective listening/mix review remains open.
