# The Mossbound Oath

The Hunters’ Board stands at (-8, 0, 12), beside Frostmere’s market. E opens it. Accept the hunt, harvest the three wolves in the northwest clearing and the Mossbound Colossus near the north pass, then return to choose a reward. A home-world tracker shows proof progress. This is a standalone optional contract; it does not gate the main campaign or change faction allegiance.

The relevant actors are wild_6, wild_7, wild_8 and wild_11. The colossus now has a dedicated ground-slam pattern; existing harvest rewards remain intact. Earlier harvests count even if the contract was not yet accepted, and there is no forced respawn. The player must harvest each corpse with E, not merely defeat it.

## Rewards

Choose one Fine-quality, favorited item plus 120 gold:

- Mossfang Blade: sword, 21 base damage, +2 Strength and +2 Agility.
- Mossheart Amulet: 3 base armor, +2 Endurance and +3 Willpower.

Both Mossbound forge recipes unlock with either choice. The blade requires three Steel Ingots, four Hide and one Crystal; the amulet requires two Silver Ingots, two Crystal and two Hide. Tempering uses the named materials, with Ember Cores required at higher ranks. Existing enchantment, socket, favorite and loadout rules apply.

## Persistence

An optional hunt record saves acceptance and the selected reward alongside wilderness proof and owned equipment. Older profiles default to an unaccepted contract. Claims recheck proof completion, reward identity and physical board proximity. The selected reward can be claimed once; selling or salvaging it does not reset the claim. Previously earned proofs remain valid.

This is the first equipment-focused hunt from the earlier backlog. Additional contracts, unique encounters and broader side-quest loot remain open. The new designs increase the catalog to 135 equipment items and 151 recipes.

## Colossus encounter

The optional north-pass colossus retains 420 health and its normal melee attacks. It adds a stationary ground slam with a 1.5-second amber warning ring, five metres in radius. Leave the ring before impact. Solid cover blocks damage; guarding reduces it, but the area impact cannot be parried. The slam deals 36 raw damage before equipment mitigation, with a seven-second slam cooldown and a brief melee recovery.

At half health, its label changes to Awakened, slam damage rises to 48 and the slam cooldown falls to four seconds. This phase derives from health, including restored session health. The initial slam cooldown is five seconds. Attack timers and warning effects are transient and are not saved. Menus, travel, retreat beyond the habitat, stagger, finishers and death cancel the warning safely.

This adds a first distinct optional-boss pattern, not repeatable hunts or a respawn system. Already defeated colossi remain defeated in existing profiles.

## The Frostmaw Hunt

A second tab at the same board offers Rimefang's hunt. The giant quadruped lives at (34, 0, 18), south of the bridge on the eastern bank, with a twelve-metre tree clearing. It has 540 health, boss mitigation, enlarged collision, ivory tusks and ice-colored back plates. Its 1.3-second warning locks the charge direction; it then rushes at ten metres per second for at most 1.1 seconds. One charge can damage only once (44 raw damage); solid walls stop it. The charge is an area/body impact and cannot be melee-parried. Misses and wall collisions lead to a recovery window; ordinary close-range attacks remain blockable and parryable.

Menus, chapter departure, retreat outside the habitat, stagger, finisher lock and death cancel charge state. Its attack timers remain transient. Enemy wild_12 joins the persistent wilderness/session roster. Older profiles load with this creature undefeated and the optional frost_hunt record unaccepted. Previously earned harvests count even before acceptance.

Harvest grants eight Hide, four Crystal, three Steel Ingots and 100 gold. Returning to the board adds 180 gold, a Fine favorited Rimefang Maul and both forge patterns. The maul has 26 base damage, +3 Strength/+2 Endurance. The Frostmaw Cuirass uses the steel chest armor base with +3 Endurance/+2 Willpower. Maul forge cost: four Steel Ingots, three Crystal, two Hide. Cuirass: three Steel Ingots, six Hide, two Crystal. Both support existing improvement systems. Reward claims require acceptance, real harvest proof and board proximity and cannot repeat. Catalog totals are now 137 equipment designs and 153 recipes.


## Rimefang charge animation

Rimefang now lowers its head and tusks while compressing its body during the existing 1.3-second charge warning. One foreleg paws while the others brace. The committed run uses a larger alternating stride and subtle body motion; cancellation resets the living head/body pose. The head pivot groups existing geometry, including tusks, without changing collision or adding mesh pieces. Charge direction, 10 m/s speed, 1.1-second run, 44 raw damage, single-hit limit and recovery remain unchanged.


## Wolf and boar bite presentation

The six wolves and five boars now have articulated heads and small toothed lower jaws. During the existing 0.65-second bite warning, the head draws back and the jaw opens. The strike snaps forward and recovers visually over 0.22 seconds. Existing bite reach, 13/20 raw damage and cooldowns remain unchanged. Menus, departure and execution locks clear pending wolf/boar bites and their poses; defeated creatures reset the jaw before the existing corpse handling. Rimefang and the colossus retain their own presentation.


## Colossus slam articulation

The Mossbound Colossus now raises both stone arms through its existing ground-slam warning. Impact lowers the arms and body briefly, then settles over 0.4 seconds during the existing cooldown. Shoulder pivots reuse the original arm meshes. Cancellation clears the living arm/body pose. The 1.5-second warning, five-metre ring, 36/48 raw damage, cover/guard checks and seven/four-second phase cooldowns are unchanged.


## Colossus landing debris

A resolved ground slam now kicks up 24 cosmetic stone/earth fragments around its origin, including when the player dodges. The fragments tumble outward and follow the underlying terrain height, rising and fading over 0.65 active seconds. Menus hide/freeze them and chapter departure removes them. They have no collision, damage, loot or persistent state; the existing warning ring and attack rules remain unchanged.
