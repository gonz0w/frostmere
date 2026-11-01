# A Pilgrim's Empty Shoes

A compact optional quest in Ember Caldera, accessible after the council travel gate without accepting the signal quest or joining the Choir. Start at the notice beside the entrance. Inspect abandoned shoes west of the central path, recover a hidden letter by the eastern wall after defeating choir_1, then find Leth opposite the shoes on the east path.

The apparent sacrifice is a staged escape from an unwanted oath. Offer temporary shelter without vows, or supplies for a free departure. Both resolve by moving Leth to camp, where the pilgrim remains available with an updated nameplate, interaction prompt and dialogue title. This is an interaction-resolved safe return, not a walking escort or simulated journey out of the region. The departure choice explicitly has Leth waiting at camp with supplies.

Both grant 100 gold and a favorite-protected Superior Ring of Swiftness with Fleet named Unbound Pilgrim's Ring. Shelter adds 8 herbs and 6 water; departure adds 6 Resonant Ore and 4 Ash Glass. Existing gear and upgrade systems apply. Main and faction progress remain independent.

The original outline's cooling-lava tunnels are represented here by the existing caldera ash paths and sanctuary approach; no new tunnel dungeon is added. The atlas summary reflects the implemented route.

Optional choir.pilgrim_stage is 0 unstarted, 1 shoes, 2 letter, 3 Leth found; pilgrim_choice is empty/shelter/depart. Save validation enforces Council access, defeated evidence guard and correct decision stage. Older saves default to unstarted. Rewards cannot repeat.

Validation: empty_shoes 33, choir 70, choir_listener 49, fire_invite 49, atlas 42 = 243 passing checks. Native Mac choice and safe-camp captures inspected. Test profiles are isolated from normal saves.
