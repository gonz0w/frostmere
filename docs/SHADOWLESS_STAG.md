# The Stag Without a Shadow

> Verification counts and capture observations below are historical development evidence, not fresh checks. `build/` paths refer to local output omitted from the source checkout; see [evidence guidance](README.md#screenshots-and-development-evidence).

Playable optional Stag Shrine quest after completing Pacts Beneath the Roots. Speak to hunter Fenn beside the southern road (-5, 0, 34). This uses the existing grove, independently of the Coven trials and either woodland pact.

Fenn broke his hunting oath during a hungry winter. Follow a pale voxel stag north along the central path, listening at three stops. Its memories offer forgiveness and an invitation to tend the grove. Return to Fenn for 100 gold, 6 Heartwood and 4 Amber Resin, once only. His future gardening is a dialogue consequence, not an NPC farming simulation.

The stag moves at 2.2 metres per second, waits when the player is at least 16 metres away, and freezes during menus or while outside the grove. Interactions only become available at a reached stop. It has no collider or damage receiver, and every mesh disables shadow casting. This is a spectral guide along a fixed clear route, not a navigation-agent escort. There is no punishment for swinging a weapon at it.

Optional `roots.stag_step` saves 0 (unstarted), 1–3 (trail legs), 4 (return to Fenn), or 5 (complete). Leaving and returning restarts an unfinished leg from its preceding checkpoint. Moment-to-moment movement is not saved. Older profiles default to unstarted; malformed or prerequisite-breaking progress is rejected before applying a load. Existing pact and faction state remain independent.

Validation: `tests/shadowless_stag.gd` covers real dialogue interactions, movement, waiting, menu/travel pause, supported stop terrain, checkpoint return, rewards, journal, legacy saves and malformed saves. `tests/render_shadowless_stag.gd -- --capture` produces isolated native Mac screenshots in `build/shadowless-stag.png` and `build/stag-forgiveness.png`.
