extends RefCounted
const NAMES={"melee":"Melee","marksman":"Marksmanship","magic":"Magic","crafting":"Crafting"}
const PERKS={
	"heavy_hand":{"skill":"melee","level":2,"cost":1,"name":"Heavy Hand","detail":"Melee weapon damage +10%."},
	"measured_swing":{"skill":"melee","level":5,"cost":2,"name":"Measured Swing","detail":"Melee swings cost 6 stamina instead of 9; daggers cost 4 instead of 6."},
	"steady_aim":{"skill":"marksman","level":2,"cost":1,"name":"Steady Aim","detail":"Bow and firearm damage +10%."},
	"quick_release":{"skill":"marksman","level":5,"cost":2,"name":"Quick Release","detail":"Bow and firearm attack cooldowns are 15% shorter."},
	"kindled_mind":{"skill":"magic","level":2,"cost":1,"name":"Kindled Mind","detail":"Spell power +10%."},
	"clear_channel":{"skill":"magic","level":5,"cost":2,"name":"Clear Channel","detail":"Spells cost 20% less magicka."},
	"artisan":{"skill":"crafting","level":2,"cost":1,"name":"Artisan","detail":"Newly forged equipment starts at Fine quality."},
	"careful_tempering":{"skill":"crafting","level":5,"cost":2,"name":"Careful Tempering","detail":"Tempering uses one fewer of each material, minimum one."}
}
static func valid(value: Variant) -> bool:
	if not value is Dictionary or not value.get("xp") is Dictionary or not value.get("perks") is Array: return false
	if value.xp.size()!=4: return false
	var earned:=0
	for skill: String in NAMES:
		var amount: Variant=value.xp.get(skill)
		if not (amount is int or amount is float) or not is_finite(float(amount)) or amount!=int(amount) or amount<0 or amount>900: return false
		earned+=int(amount)/100
	var seen=[]; var spent:=0
	for id: Variant in value.perks:
		if not id is String or not PERKS.has(id) or id in seen: return false
		var perk: Dictionary=PERKS[id]
		if 1+int(value.xp[perk.skill])/100<perk.level: return false
		spent+=perk.cost; seen.append(id)
	return spent<=earned
