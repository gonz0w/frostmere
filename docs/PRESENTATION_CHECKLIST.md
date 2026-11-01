# Reviewing presentation

Use [issue #7](https://github.com/gonz0w/frostmere/issues/7) for observations and
owner approval. The galleries are local review artifacts, not releases. Historical
performance numbers in the older review documents are not measurements of a new
capture run.

## Regenerate native views

After the usual Godot import, run these fixtures with Godot 4.7.2 on a graphical
desktop. Replace `godot` with your executable path. `--capture` disables normal
profile persistence; do not omit it or add `--headless` to these native captures.
Create `build/presentation-review/` first if this is a fresh checkout.

```sh
godot --path . --script tests/render_building_review.gd -- --capture
godot --path . --script tests/render_realm_atmosphere.gd -- --capture
godot --path . --script tests/render_landscape_review.gd -- --capture
godot --path . --script tests/render_presentation_review.gd -- --capture
godot --path . --script tests/record_intro_audio.gd -- --capture
```

The realm fixture refreshes building-gallery images but does not add entries to
its manifest. Include its two `aeralis-atmosphere.jpg` and
`crucible-atmosphere.jpg` views separately when reviewing the skies.

The presentation builder expects the freshly recorded `build/intro-audio-engine.wav`
to be copied to `build/presentation-review/intro-engine-mix.wav` first. Then run
`python3 tools/build_building_review.py` and
`python3 tools/build_presentation_review.py`.

`tools/build_landscape_review.py` additionally requires historical `before/`
images. Those local comparison images are not distributed with the source. Do
not run the current capture with `--before` and present it as an older build.
Without a genuine baseline, review the current `after/` images listed in its
manifest; no before/after claim is needed.

After the three galleries exist, run `python3 tools/build_owner_review.py` for
a single entry page at `build/owner-review/index.html`. It verifies referenced
current captures exist; it does not assert they were regenerated or approve them.

## Review together

- Architecture: regional silhouettes, shop identity, entrances, interior purpose
  and signs; compare the Nordic towns, coastal stores, woodland lodges and realms.
- Landscape: each of the twelve regions, terrain and vegetation variety, readable
  paths, Aeralis sky and Crucible roof. Retained comparison images are historical.
- Opening and dialogue: first/third person reveal, 800×600 subtitle capture,
  village handoff, Edda/Rook/Mereth humor, and ordinary journal guidance.
- Audio: listen to all nine scores and the interaction/combat cues in the
  presentation gallery, then the recorded native intro mix. Check transitions
  during live exploration/combat too; isolated tracks do not establish mixing.

Captures freeze actors and position cameras for inspection. Review actual
movement, menus, transitions and both cameras in native play as well. Record
which areas were checked and any specific requested changes in #7. A technical
pass or agent screenshot inspection cannot supply subjective owner approval.
