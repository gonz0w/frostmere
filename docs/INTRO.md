# Ash Through the Snow

> Verification counts and capture observations below are historical development evidence, not fresh checks. `build/` paths refer to local output omitted from the source checkout; see [evidence guidance](README.md#screenshots-and-development-evidence).

A short, playable first arrival for new characters. Move with WASD, look with the mouse, approach the lantern and press E. An eight-second approach, pause and retreat of a horned creature beyond a glowing ward foreshadows the late infernal storyline. Once it withdraws, walk to the arch and press E to reach Frostmere. Tab skips at any unpaused point. Escape retains the ordinary pause menu. Camera switching and character menus remain available.

The scene has snow-tagged collision, layered snow-capped cliffs, pines, shallow snow streaks, broken masonry, an actual roadside sign and a framed lantern. The center route stays clear. The creature approaches through fog, turns its head, opens its jaw, then withdraws before disappearing. Illuminated runes and drifting ash complete the scene. Tremor is suggested by the moving creature and ward rather than forcibly shaking the camera. The creature is scenery and awards no combat loot. A dedicated synth score and two ward cues accompany the reveal. Edda's initial dialogue comments on the warm road stones, then offers the existing first quest and supplies.

The scene is constructed only when the opening begins and freed on completion. Camera environment, sunlight and controls restore at the handoff. A 0.75-second fade reveals the village. Pause freezes the fade and hides its overlay so the menu stays readable. The village quest objective stays hidden until arrival. Finishing does not accept a quest or unlock a realm. Existing saves without the optional boolean intro_completed field migrate with the introduction bypassed. New profiles default to incomplete. Save validation rejects malformed values before applying state. Saving midway records no remote prelude coordinates; a reload starts the short opening again.

Preview Dark Opening.command uses --intro-preview and disables character and atlas persistence, including after arriving in Frostmere. It never loads the regular character. The ordinary launcher uses the opening only for new or explicitly incomplete characters.

First-pass limits: compact corridor scenery, simplified creature rig, unvoiced captions, and no manual full cinematic pacing study or fresh M1 benchmark. Varied snowy terrain and creature choreography remain polish work. The previously shared 0.1.0 Mac ZIP predates this change.

## Dedicated opening audio

The prelude now has its own original 48-second looping synth score: slow minor phrases, rounded triangle harmonics, sparse stereo bell echoes and a low drone. It preserves the old-school sound without the Crucible's exploration rhythm. Two original cues mark the creature approach and the ward holding after withdrawal. Cues pause with the reveal and stop on completion/skip; the score uses the existing music crossfade and pause ducking. Nordic exploration music resumes at arrival.

Generate the three assets with `python3 tools/build_intro_audio.py`; the full audio generator also invokes it. Audio is deterministic, synthesized without samples, 22,050 Hz stereo PCM. The music peaks at 0.48 and effects at 0.62 before mixer gain. Captions, reveal timing, movement, skip behavior, quest gates and saves are unchanged. Speaker/headphone listening and human cinematic pacing remain open.

Validation: 85 gameplay/audio checks passed. build/intro-audio-engine.wav is a 12.57-second native Mac mixer capture of the opening, reveal and return crossfade (no clipping). The full score is assets/audio/music/intro.wav.
