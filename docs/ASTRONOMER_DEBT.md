# The Astronomer's Debt

A compact optional quest at the Sunken Lens, available after The Missing Atlas opens the observatory road. Ask Veyra about her missing instruments. Recover her horizon gauge from the existing western excavation cache and her weather prism from the eastern survey cache. The western recovery requires defeating lens_0; the eastern requires lens_1. Earlier defeats count. Physical cache interactions recover the instruments separately from the main quest's restoration supplies.

Return both instruments to Veyra and choose:

- Sell them to settle her debt: 250 gold and six Solar Alloy.
- Keep them for public weather research: 80 gold, ten Optic Glass and eight Rune Dust. Veyra commits to repaying the creditor through her own work.

Both outcomes complete the quest once and leave distinct dialogue and journal text. Neither changes observatory puzzles, main rewards, faction allegiance, prices or simulated weather. The consequence in this compact implementation is the recorded story outcome and reward, not a broader town simulation.

Visible instrument props disappear after recovery. Quest items are recorded as protected evidence, not sellable inventory, and cannot be lost through crafting. Actions require physical proximity and correct subjects; claims cannot repeat or switch after payment. Optional debt_started, debt_instruments and debt_choice fields live in the existing lens save record. Older profiles default to unstarted; inconsistent progress is rejected before applying loaded state.

The atlas marks `side_sunken_lens` playable. See [the current content reference](CONTENT_REFERENCE.md) for catalog totals and quest availability. This implementation uses the existing excavation sites rather than adding new explorable tomb interiors.
