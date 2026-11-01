# The Last Warm Shelter

> Verification counts and capture observations below are historical development evidence, not fresh checks. `build/` paths refer to local output omitted from the source checkout; see [evidence guidance](README.md#screenshots-and-development-evidence).

A compact Rimegate-approach side quest in the existing Wyrmkeep region, available after Stonewake. Read the overdue notice beside the southern road, find Marae's three-person group northeast of town, and restore the new watch hut hearth with 4 wood. Missing materials spend nothing; ordinary wood can be brought from town. No clan oath or council settlement is required.

Lighting the hearth visibly activates its fire and relocates the travelers into the hut. They remain there to rest. Arrange a cleared road home after defeating all three existing northern outpost raiders, or choose shelter until a ridge guide can travel after the thaw. These are saved arrangements, not a walking escort, weather simulation or timed NPC departure.

Both choices award 120 gold and favorite-protected Superior fur boots with Fleet named Last Warm Mile. Road adds 4 Steel Ingots; guide adds 8 herbs and 6 water. Existing gear upgrade systems apply. The council, family letters, clan membership and faction finales remain independent.

This adds a hut and travelers within Wyrmkeep's supported terrain, not a separate Rimegate town or large new mountain zone. The atlas quest summary now identifies the Wyrmkeep approach explicitly.

Optional mountain.shelter_stage is 0 unstarted, 1 searching, 2 hearth repair, 3 sheltered. shelter_choice is empty/road/ridge. Validation enforces Stonewake access, warm shelter before choosing and all three defeated raiders for the road option. Old profiles default to unstarted. Repairs, rewards and choices cannot repeat.

Validation: warm_shelter 30, mountain 74, clan_voice 21, family_letters 38, atlas 42 = 205 passing checks. Native Mac hut and route-decision captures inspected. Tests isolate normal saves. The group remains interactable at the hut after relocation, with updated nameplate, title and prompt.
