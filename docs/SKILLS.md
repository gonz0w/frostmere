# Skills and perks

Press **K** to open or close the skills screen, or use the button in the character menu. Select one of four skill tabs and choose an eligible perk. Learned perks show a Refund button that returns their full point cost. Escape returns to exploration. The game pauses while choosing.

## Progression

Melee, Marksmanship, Magic and Crafting start at level 1 and cap at level 10. Every 100 cumulative XP earns another level and one shared perk point. Levels unlock perk eligibility; bonuses apply only after purchasing a perk. Points earned from any skill can fund any eligible perk. Neither perk requires the other.

Successful player damage awards the corresponding combat skill one XP per five actual health removed, rounded down with a minimum of one per hit. Overkill is excluded. Misses, protected targets and defeated enemies award no XP. Bows and firearms train Marksmanship; spell projectiles and chain lightning train Magic. Projectile attribution is fixed when fired.

Successful recipes award their configured XP, tempering awards two XP, and enchanting awards three XP. Failed operations award none. Gathering and salvage do not train the new Crafting skill.

## Current perks

| Skill | Perk | Required level | Points | Effect |
| --- | --- | --- | --- | --- |
| Melee | Heavy Hand | 2 | 1 | Melee weapon damage +10% |
| Melee | Measured Swing | 5 | 2 | Swing stamina cost falls from 9 to 6 |
| Marksmanship | Steady Aim | 2 | 1 | Bow and firearm damage +10% |
| Marksmanship | Quick Release | 5 | 2 | Bow and firearm attack cooldowns 15% shorter |
| Magic | Kindled Mind | 2 | 1 | Spell power +10% |
| Magic | Clear Channel | 5 | 2 | Spell magicka cost reduced by 20% |
| Crafting | Artisan | 2 | 1 | Newly forged equipment starts at Fine quality |
| Crafting | Careful Tempering | 5 | 2 | One fewer of each tempering material, minimum one |

Artisan affects future forged equipment; existing items retain their quality. Careful Tempering affects material costs, preserving existing forge requirements and quality limits.

## Persistence and scope

XP and learned perks share the atomic character save. Level gains and perk purchases save immediately in regular play; partial combat XP is included in the next normal progress save or autosave. Older saves without skill data migrate existing crafting XP, capped at 900, and start the combat skills at level 1. Migration does not choose perks for the player. Preview and test characters remain isolated from the regular profile.

This first progression pass has eight perks across four skills. Additional defensive or utility skill branches and further balance tuning remain future work.

## Retraining

Refund any learned perk directly in the K screen, then spend its points on another eligible perk. Refunds are free, preserve XP and skill levels, and save with the character. A one-point perk returns one point; a two-point perk returns two. Refunding an unknown or already refunded perk cannot grant extra points.

Bonuses are removed immediately, including damage, attack costs, spell costs and crafting discounts. Items already created or improved retain their quality, enchantments and other properties. Refunding Artisan changes future crafts only. The screen stays open so you can rebuild; no new save schema or character restart is required.
