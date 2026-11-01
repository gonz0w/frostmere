# Ash Remembers Everything

> Verification counts and capture observations below are historical development evidence, not fresh checks. `build/` paths refer to local output omitted from the source checkout; see [evidence guidance](README.md#screenshots-and-development-evidence).

The second Ashen Choir quest is playable after the Listener oath. Use Sereth's separate sealed-records discussion to begin. Beyond the existing northern sanctuary gate, use the archive pressure lock at (-6, 0, -77): mute the signal, vent the pressure, release the latch. Wrong settings reset the sequence without spending resources. Correct completion opens the visible cabinet west of the lock at (-13, 0, -77). This is a cabinet within the existing sanctuary, not a new dungeon wing.

Copy the elder council's signed sealing order and pressure log, then return to Sereth. Publication exposes the elders' responsibility to the families; concealment preserves the evidence privately while leaving the false public account intact. The dialogue explicitly acknowledges the latter's conflict with the Listener oath. Both grant Cantor rank, 180 gold, 8 Resonant Ore and 6 Ash Glass. Publication grants a favorite-protected Exquisite Cantor's Staff with Insight named Unburied Voice; concealment grants an Exquisite Resonance Blade with Fleet named Keeper of Ash. Existing gear/upgrade systems are reused. Iron Pact standing and the main distress signal remain unchanged.

The cabinet caption and journal record the outcome. No simulated family hearings, new NPC reactions outside this quest, or faction reputation changes are implied. The [Ember Voice finale](FIRE_INVITE.md) follows either outcome.

Optional choir fields: memory_started and memory_record booleans, memory_lock integer 0–3, memory_choice empty/publish/conceal. Validation requires Listener membership before starting, acceptance before lock progress, a fully opened lock before evidence, and evidence before a choice. Sequence checkpoints and the permanent outcome survive saves. Legacy saves default to unstarted. Rewards cannot repeat.

Validation: ash_memory 41, choir_listener 49, choir 70, convergence 74, atlas 42 = 276 passing checks. Native Mac cabinet and decision captures inspected. All fixtures disable normal persistence.
