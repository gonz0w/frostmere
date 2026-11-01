# Tidemarch Compact — first initiation

> Verification counts and capture observations below are historical development evidence, not fresh checks. `build/` paths refer to local output omitted from the source checkout; see [evidence guidance](README.md#screenshots-and-development-evidence).

A Ship Without a Name is playable in Saltbreak after completing the Black Shore expedition, with either core outcome. Meet Arbiter Vessa near the southern road (28, 0, 32). She represents the houses in a compact dialogue hearing; this does not add a council interior or simulated house economy.

Investigate the departure register (16, 0, 32), ask Neris about the coastal grain ship Mercy, and recover its scraped nameplate beside the sea-cave approach (4, 0, -16). The existing shore_0 Brinecutter must be defeated before recovering the plate; an earlier defeat counts. This ship is distinct from the fallen star vessel Wayfarer and the Nets Full of Silver fishing crew.

After gathering all three accounts, convene the hearing with Vessa. Two unsupported claims explain the evidence and allow retry without resource or reputation loss. The supported finding is that relief cargo was sold and the ship's identity erased. You can then leave and defer membership indefinitely, or swear the Decksworn oath.

Joining grants 140 gold, a favorite-protected Superior Tideglass Saber enchanted with Fleet and named Decksworn's Promise, plus the reusable Fleet enchantment formula. It uses the existing weapon design and upgrade systems; no new recipe is added. Membership does not close any rival faction path. The [Envoy](HARBOR_LIED.md) and [Harbor Speaker](SAFE_PASSAGE.md) chapters follow this oath.

Optional save fields: `shore.compact_stage` 0 unstarted, 1 investigating, 2 hearing, 3 finding upheld/oath pending, 4 Decksworn; `shore.compact_evidence` contains unique registry/nameplate/salvager IDs. Loading validates types, integral range, expedition completion, all evidence before hearing, and the nameplate's defeated guard. Old profiles default to unstarted. Rewards cannot repeat. Existing main expedition and silver-net progress are independent.

Validation: `tests/tide_compact.gd` (43 checks), shore (65), silver_nets (43), atlas (42): 193 passing checks. Native Mac captures from `tests/render_tide_compact.gd -- --capture` cover the hearing, oath and arbiter. All fixtures disable normal profile persistence.
