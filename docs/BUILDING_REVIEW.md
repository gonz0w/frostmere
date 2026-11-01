> Historical review evidence from September 24, 2026. Local `build/` galleries and reports are not distributed with the source. See [public screenshots](screenshots/README.md) and [GitHub work](https://github.com/gonz0w/frostmere/issues) for current review status.

# Building review #3

The user-approved equipment pass is followed by this architecture checkpoint. Review the existing building roster at `build/building-review/index.html`. Each house/hall has four views, with additional town and destination architecture scenes.

| Building | Region palette | Interior purpose | Roof feature |
|---|---|---|---|
| The Copper Stag | nordic | store | dormer |
| The Runesmith's House | nordic | runes | lantern |
| Thread & Thistle | nordic | weaver | hip |
| The Crofter's Rest | nordic | home | hip |
| Ember Hall Stores | nordic | provisions | clerestory |
| Juniper & Rune | grove | herbs | dormer |
| Stoneguard Hall | mountain | armory | battlement |
| Stormweaver Hall | mountain | runes | lantern |
| The Divided Council | mountain | council | clerestory |
| Summit Smithy | mountain | smith | vent |
| The High Road | mountain | store | dormer |
| The Last Warm Shelter | winter | shelter | hip |
| Lantern Chapter House | woodland | library | lantern |
| The Veiled Coven | woodland | runes | dormer |
| The Mapmaker's Lodge | woodland | maps | hip |
| Saltbreak Harbour House | coast | maps | lantern |
| The Net & Needle | coast | nets | dormer |
| The Salt Granary | coast | provisions | hip |
| Lenswarden Observatory Lodge | sun | astronomy | observatory |
| Amberbough Keeper's Lodge | grove | herbs | lantern |
| The Pactkeeper's Hearth | grove | hunter | hip |
| The Cantor's Hospice | ash | music | bell |
| The Witness House | sun | library | clerestory |
| Passkeeper's Rest | winter | shelter | dormer |
| The White Road Stores | winter | provisions | vent |

Additional architecture: Frostmere distant fortress; six Aeralis pavilions and final arch; Crucible foundry walls and cathedral frame; First Threshold arrival/salvage/command compartments.

Sources: `scripts/building_profiles.gd`, `scripts/refined_buildings.gd`, `scripts/building_furnishings.gd`, `scripts/landmark_architecture.gd`. Captures and validation results are under `build/building-review/`.

Review emphasis: regional silhouettes, facade construction and the purpose of each room. Upper galleries/dormers are architectural dressing, not new playable floors. This covers existing buildings, not completion of the wider world-expansion roadmap.

### Realm atmosphere follow-up · September 24, 2026

Aeralis now uses an animated celestial sky with violet cloud layers, teal aurora ribbons, stars and a crescent moon. The Crucible has a continuous basalt cavern shell, staggered rock plates, hanging formations, molten ceiling seams, distant cliff walls and 80 rising ember particles. Overhead geometry remains above the existing structures and combat space; no walkable surfaces or collision layouts changed.

Atmosphere nodes are built once and activated only for their realm. Leaving restores the original Environment resource and stops the ember emitter. The six existing realm architecture views have been refreshed; two upward atmosphere views bring the gallery to 116 images / 41 cards.

Validation: `tests/realms.gd` passed all 38 checks in standard headless mode. `tests/render_realm_atmosphere.gd -- --capture` rendered eight native Metal views and asserted isolated saves, realm visibility and original environment restoration. Final logs contain no errors or warnings. Initial regression invocation incorrectly included `--capture`, which suppresses input; the standard headless rerun passed. M1 performance remains unverified.
