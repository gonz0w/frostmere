# The Keeper’s Last Light

> Verification counts and capture observations below are historical development evidence, not fresh checks. `build/` paths refer to local output omitted from the source checkout; see [evidence guidance](README.md#screenshots-and-development-evidence).

`side_hallowcliff` is playable after archive access. Speak to relief pilot Mara near Saltbreak’s southern road. This compact quest uses the existing coastal scene: it adds an old fjord signal and a Hallowcliff relief ship, not a separate Hallowcliff town.

Read the former keeper’s log on the western shore, then repair the ground controls farther north with 2 iron ingots and 1 crystal. Missing either material spends nothing. Use the repaired signal to bring the ship to safe anchor, then return to Mara. The keeper accepted a smuggler’s payment before threats to his family kept the light dark.

- Publish the signed log and seek protection for the family: 120 gold and a Superior Insight Starsignal Staff, “Keeper’s Witness.”
- Report the smuggling route without the keeper’s name and return his log to the family: 120 gold and a Superior Fleet Tideglass Saber, “The Quiet Passage.”

Both rewards are favorites. The outcome is permanent and the journal records it. The tower light is independent from the main coastal quest’s harbor beacon. No faction rank is awarded. Family protection and reporting are narrative consequences.

The ship is a visual prop repositioned from offshore to the anchorage when signaling closes the dialogue. There is no animated sailing, boarding or crew simulation. The tower uses ground controls; climbing is not required.

Optional shore save fields: light_stage (0–4) and light_choice (empty/public/family). Stage 0 is unstarted; 1 needs the log; 2 needs repair; 3 needs signaling; 4 awaits or has completed reporting. Invalid types, ranges, missing archive access and premature outcomes are rejected before applying a save. Legacy saves default to unstarted.

Validation: last_light 45, shore 65, ash_boat 43, silver_nets 43, safe_passage 66, atlas 42 = 304 checks with zero failures. Covers actual interaction buttons, supported approaches, atomic material costs, remote actions, independent beacon behavior, ship relocation, both rewards, duplicate prevention, intermediate/final saves and malformed/legacy saves. Native macOS captures inspected: build/last-light-choice.png, build/last-light-tower.png and build/last-light-ship.png. No release package produced.
