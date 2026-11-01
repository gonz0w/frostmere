# The Harbor That Lied

The second Tidemarch Compact quest is playable after the Decksworn oath. Ask Vessa about forged harbor records, compare the departure register, recover the signed false-beacon orders east of the cave exit, and find pilot Tamsin east of the cave. Defeat the existing shore_2 relay raider before arranging watch protection. Earlier defeats count.

The protection interaction relocates Tamsin to the southern lodge doorway, updates her nameplate, closes dialogue and restores control. This is an interaction-resolved relocation, not a walking escort or simulated watch patrol. The original location stops offering her interaction; she remains available at shelter.

Return to Vessa to expose House Vale's deliberate wreck scheme. Tamsin consents to either public testimony under watch protection or testimony under seal while the orders are published. Both grant Envoy rank, 160 gold, 6 Wreck Alloy and 4 Signal Circuits. Public testimony grants a favorite-protected Superior Tideguard Cuirass with Vigor, named Envoy's Breakwater. Sealed testimony grants a favorite-protected Superior Signal Lens with Insight, named Envoy's Witness. Existing gear designs remain upgradeable; no catalog or recipe expansion. Harbor Speaker remains planned, and neither choice closes a rival capstone.

Optional `shore.harbor_stage` records 0 unstarted, 1 register investigation, 2 orders search, 3 witness protection, 4 sheltered/presentation pending, 5 completed. `shore.harbor_choice` is empty, public or sealed. Loading validates finite integral stages, Decksworn membership, guard defeat for shelter, and a choice exactly when complete. Legacy profiles default to unstarted. Core choice, silver-net progress and Compact initiation are preserved.

Validation: harbor_lied 38, tide_compact 43, shore 65, silver_nets 43, atlas 42: 231 passing checks. Native Mac captures cover the presentation and relocated witness. Tests use isolated profiles. Visuals show the existing southern house as the shelter; the quest adds no separate interior.
