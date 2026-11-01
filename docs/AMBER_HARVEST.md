# A Harvest of Amber

> Verification counts and capture observations below are historical development evidence, not fresh checks. `build/` paths refer to local output omitted from the source checkout; see [evidence guidance](README.md#screenshots-and-development-evidence).

`side_alderrest` is playable after Stonewake unlocks woodland travel. Herbalist Edda represents Alderrest’s growers at the existing woodland camp; this quest adds a three-tree trial plot, not a separate Alderrest town.

Accept Edda’s investigation, sample the plot east of the central path, prepare a treatment at the camp bench for 3 herbs and 2 water, then apply it to the first tree. Missing materials spend nothing. The treated crown changes to the woodland’s healthy copper foliage. Return to Edda for a permanent decision:

- Preserve the plot and suspend tapping: 100 gold, Superior Vigor Groveheart armor named “Amber’s Tomorrow,” and 6 Amber Resin from Edda’s reserve. All three trees show healthy crowns.
- Authorize two failing trees for emergency supplies: 160 gold, Superior Fleet Pactkeeper axe named “The Lean Season,” and 10 Heartwood. Two trees become stumps; the treated tree remains.

Both gear rewards are favorites. Journal outcomes and the visual plot persist through saves. Seasonal recovery, logging work and supply distribution are represented by dialogue and state changes; there is no simulated harvest economy or tree-cutting animation. The main woodland restoration, spectral stag and Coven rank progression remain independent.

Optional roots save fields: amber_stage (integer 0–4) and amber_choice (empty/protect/logging). Stages cover acceptance, sample collection, preparation and application. Choices require stage 4 and all started progress requires Stonewake. Malformed types/ranges and impossible outcomes are rejected before applying a save; legacy saves default to unstarted.

Validation: amber_harvest 47, roots 85, shadowless_stag 70, coven_finale 129, atlas 42 = 373 checks, zero failures. Covers actual interaction buttons, supported approaches, atomic costs, stale actions, visible outcomes, exact payments, duplicate prevention and partial/final/invalid/legacy saves. Native macOS captures inspected: build/amber-harvest-choice.png, build/amber-harvest-protect.png, build/amber-harvest-logging.png. No release package produced.
