# Voices in the Furnace

> Verification counts and capture observations below are historical development evidence, not fresh checks. `build/` paths refer to local output omitted from the source checkout; see [evidence guidance](README.md#screenshots-and-development-evidence).

The Ashen Choir's initiation is playable after A Song Through the Stone. Ask Sereth about the ash pilgrimage. Three new vigil shrines stand beside the safe central caldera path; each alternates two seconds of VENTING with four seconds of COOL, offset between shrines. Orange/blue materials and readable labels convey the state without requiring audio. Listen in a cool interval to record each vigil, then copy the omitted names near the northern signal archive.

This is a controlled timing pilgrimage through the existing sanctuary. Hot interactions are rejected without damage or resource cost. Menus and travel pause the cycle; an open dialogue must be closed before waiting for cooling. Each completed vigil saves permanently; the transient cycle phase is not saved. The trial does not add a new lava traversal course or vent damage system.

The suppressed testimony describes pilgrims sealed inside a failed awakening against their wishes. Return to Sereth and optionally swear to preserve that testimony. Joining grants Listener rank, 140 gold, favorite-protected Superior cloth robes with Vigor named Listener's Ashweave, the reusable Vigor formula, 6 Resonant Ore and 4 Ash Glass. Existing gear and upgrade systems are used. Iron Pact membership and reputation are unaffected; the [Cantor](ASH_MEMORY.md) and [Ember Voice](FIRE_INVITE.md) chapters follow this oath.

Optional save fields under choir: listener_started, listener_record, listener_joined booleans and listener_vigils containing unique vigil_south/vigil_middle/vigil_north IDs. Validation enforces main quest completion before initiation, all vigils before copying the record, and the record before joining. Legacy profiles default to unstarted. Rewards cannot repeat.

Validation: choir_listener 49, choir 70, convergence 74, atlas 42 = 235 passing checks. Native Mac captures of the oath and cool shrine were inspected. Fixtures disable normal profile persistence.
