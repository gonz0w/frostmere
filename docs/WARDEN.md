# Who Guards the Pass?

> Verification counts and capture observations below are historical development evidence, not fresh checks. `build/` paths refer to local output omitted from the source checkout; see [evidence guidance](README.md#screenshots-and-development-evidence).

The Hearthbound Lodge finale is playable after either Waykeeper outcome. Accept the north-pass commission from the Lodge tab at the Hunters' Board, then defeat and harvest the existing Mossbound Colossus. Earlier harvests count. Return to choose a neutral Lodge or control by your already-sworn mountain clan. Independent characters retain the neutral option; the clan option requires an existing clan oath.

Both permanent choices grant Warden rank and 220 gold. Neutral grants a favorite-protected Masterwork Vigor Wardkeeper's Amulet named Warden's Open Hearth. Clan grants a Masterwork Fleet steel bow named Warden's Sworn Watch. Neither changes existing faction standings or closes another quest.

Two visible watch members walk a short fixed village-road circuit with leg animation. Neutral watch wears fur; Stoneguard control uses steel; Stormweaver uses cloth. They pause during menus and disappear while the player is away from the home region. These are visual patrols, not combat companions, navigation-agent escorts or a simulated defense network. Patrol phase is transient; membership and appearance are restored from saved policy.

A separate one-time support cache at the southern village approach grants neutral characters 3 healing draughts, 8 herbs and 6 water, or clan characters 8 steel ingots and 6 leather. Claim state is saved and reflected in the journal. The cache was moved to supported road ground after placement testing.

Optional hunt.watch_started/watch_supplies booleans and watch_choice empty/neutral/clan are validated against Waykeeper completion, accepted commission, harvested colossus proof, and a clan oath for clan control. Legacy saves default to unstarted. Mandates, rewards and supplies cannot repeat.

Validation: warden 37, watershed 39, hearthbound 33, hunt 22, atlas 42 = 173 passing checks. Covers both outcomes, remote rejection, movement/menu pause, support variants, save/load, and legacy profiles. Native Mac mandate and road-watch captures inspected. Normal saves remain isolated from QA fixtures.
