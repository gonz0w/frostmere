extends RefCounted
## Owned equipment and atomic character/crafting progress.
signal changed
signal skills_changed
signal skill_advanced(skill: String, level: int)
const Skills=preload("res://scripts/skill_rules.gd")
var skills: Dictionary={"xp":{"melee":0,"marksman":0,"magic":0,"crafting":0},"perks":[]}

const SAVE_PATH := "user://character-v1.json"
const ATTRIBUTE_POINTS := 10
var realm_data: Dictionary
var finale: Dictionary = {"shutdown": false, "reward": ""}
var realm_progress: Dictionary = {"defeated": [], "looted": [], "attuned": [], "completed": []}
var story_completed: Array = []
var seal: Dictionary = {"accepted": false, "supplies": false, "valves": [], "plans": false, "bound": false, "rewarded": false, "defeated": [], "looted": []}
var winter: Dictionary = {"accepted": false, "supplies": false, "repairs": [], "assault": false, "orders": false, "rewarded": false, "defeated": [], "looted": []}
var threshold: Dictionary = {"accepted": false, "locker": false, "cargo": false, "power": false, "air": false, "record": false, "rewarded": false, "defeated": [], "looted": []}
var convergence: Dictionary = {"accepted": false, "evidence": [], "supplies": false, "installed": false, "calibrated": false, "rewarded": false, "defeated": [], "looted": []}
var choir: Dictionary = {"accepted": false, "song": [], "activated": false, "record": false, "rewarded": false, "caches": [], "defeated": [], "looted": []}
var roots: Dictionary = {"accepted": false, "heard": [], "cleansed": [], "choice": "", "record": false, "rewarded": false, "caches": [], "defeated": [], "looted": []}
var lens: Dictionary = {"accepted": false, "rotations": {"dawn": 0, "dusk": 0, "crown": 2}, "activated": false, "chart": false, "rewarded": false, "caches": [], "defeated": [], "looted": []}
var shore: Dictionary = {"accepted": false, "heard": [], "relays": [], "caches": [], "identified": [], "log": false, "core": false, "choice": "", "rewarded": false, "defeated": [], "looted": []}
var archive: Dictionary = {"accepted": false, "heard": [], "atlas": false, "recipient": "", "caches": [], "defeated": [], "looted": [], "reputation": {"lantern": 0, "briar": 0}}
var mountain: Dictionary = {"accepted": false, "heard": [], "ledger": false, "settlement": "", "clan": "", "wards": [], "rank": 0, "services": [], "reputation": {"stoneguard": 0, "stormweaver": 0}, "defeated": [], "looted": []}
var stonewake: Dictionary = {"accepted": false, "wards": [], "awakened": false, "rewarded": false}
var known_spells: Array = ["emberbolt"]
var active_spell := "emberbolt"
var frost_hunt := {"accepted":false,"rewarded":false}
var hunt := {"accepted":false, "reward":""}
var wilderness := {"defeated":[], "looted":[]}
var loadouts: Array = [{}, {}, {}, {}]
var gold := 150
var merchants: Dictionary = {}
var shop_data: Dictionary
var crafting: Dictionary
var inventory: Dictionary = {}
var materials: Dictionary = {}
var consumables: Dictionary = {}
var blueprints: Array = []
var formulas: Array = []
var discovered: Array = []
var claims: Dictionary = {}
var adventure: Dictionary = {"accepted": false, "rewarded": false, "defeated": [], "looted": [], "chests": []}
var craft_xp := 0
var next_id := 1
var catalog: Dictionary
var items: Dictionary = {}
var origins: Dictionary = {}
var archetypes: Dictionary = {}
var equipment: Dictionary = {}
var allocated: Dictionary = {}
var character_name := "The Wanderer"
var origin_id := "frostkin"
var archetype_id := "warrior"
var frame_id := "balanced"
var session: Dictionary = {}
var session_provider: Callable
var persist := false
var intro_completed := false
var last_error := ""

func _init() -> void:
	realm_data = JSON.parse_string(FileAccess.get_file_as_string("res://data/realms.json"))
	shop_data = JSON.parse_string(FileAccess.get_file_as_string("res://data/shops.json"))
	catalog = JSON.parse_string(FileAccess.get_file_as_string("res://data/characters.json"))
	for item: Dictionary in catalog.items:
		items[item.id] = item
	for origin: Dictionary in catalog.origins:
		origins[origin.id] = origin
	for archetype: Dictionary in catalog.archetypes:
		archetypes[archetype.id] = archetype
	for attribute: String in catalog.attributes:
		allocated[attribute] = 0
	for slot: String in catalog.slots:
		equipment[slot] = ""
	crafting = JSON.parse_string(FileAccess.get_file_as_string("res://data/crafting.json"))
	materials = crafting.starting_materials.duplicate()
	blueprints = crafting.starting_blueprints.duplicate()
	formulas = crafting.starting_enchants.duplicate()
	for slot: String in catalog.slots:
		var base: String = archetypes[archetype_id].loadout.get(slot, "")
		if base != "":
			equipment[slot] = add_item(base)

func item_at(slot: String) -> Dictionary:
	return describe_item(equipment.get(slot, ""))

func points_left() -> int:
	var used := 0
	for value: int in allocated.values():
		used += value
	return ATTRIBUTE_POINTS - used

func attributes() -> Dictionary:
	var result := {}
	for attribute: String in catalog.attributes:
		result[attribute] = 10 + allocated[attribute] + int(origins[origin_id].bonuses.get(attribute, 0)) + int(archetypes[archetype_id].bonuses.get(attribute, 0))
	for slot: String in catalog.slots:
		var item := item_at(slot)
		for attribute: String in item.get("bonuses", {}):
			result[attribute] += int(item.bonuses[attribute])
	return result

func staff_spell_bonus(item: Dictionary) -> int:
	# Tempering adds two base damage per rank, so every rank adds one spell power.
	return floori(float(item.get("damage", 0)) * 0.5) if item.get("family", "") == "staff" else 0

func stats() -> Dictionary:
	var a := attributes()
	var weight := 0.0
	var armor := 0
	for slot: String in catalog.slots:
		var item := item_at(slot)
		weight += float(item.get("weight", 0))
		armor += int(item.get("armor", 0))
	var weapon := item_at("main_hand")
	var damage := roundi(float(weapon.get("damage", 3)) * (1.0 + float(a[weapon.get("scaling", "strength")]) * 0.025))
	var ranged: bool=weapon.get("family","") in ["bow","machine_gun"]
	if has_perk("steady_aim" if ranged else "heavy_hand") and weapon.get("family","") not in ["staff","focus"]: damage=roundi(damage*1.1)
	return {
		"health": 100 + (a.endurance - 10) * 8,
		"stamina": 100 + (a.endurance - 10) * 6,
		"magicka": 100 + (a.intellect - 10) * 8,
		"armor": armor, "damage": damage,
		"offhand_damage": roundi(float(item_at("off_hand").get("damage", 0)) * (1 + float(a[item_at("off_hand").get("scaling", "strength")]) * 0.025)),
		"spell_power": roundi((20 + a.intellect * 2 + a.willpower + staff_spell_bonus(weapon))*(1.1 if has_perk("kindled_mind") else 1.0)),
		"critical": minf(35, a.agility * 0.6),
		"carry": 50 + a.strength * 5, "weight": weight,
		"speed": clampf(1.0 + (a.agility - 10) * 0.015 - weight / 250.0, 0.65, 1.35),
		"sprint_cost": 19.0 * (1.0 + weight / 100.0),
		"stamina_regen": 8.0 + a.endurance * 0.6,
		"magicka_regen": 3.0 + a.willpower * 0.4,
		"barter": minf(25, (a.presence - 10) * 1.5)
	}

func _commit() -> void:
	last_error = ""
	if persist and not save_to(SAVE_PATH):
		last_error = "Changes applied, but the character could not be saved."
	changed.emit()

func set_identity(new_name: String, origin: String, archetype: String, frame: String) -> bool:
	if not origins.has(origin) or not archetypes.has(archetype) or frame not in ["lean", "balanced", "broad"]:
		return false
	character_name = new_name.strip_edges().left(32)
	if character_name.is_empty():
		character_name = "The Wanderer"
	origin_id = origin
	archetype_id = archetype
	frame_id = frame
	_commit()
	return true

func allocate(attribute: String, amount: int) -> bool:
	if not allocated.has(attribute) or amount not in [-1, 1]:
		return false
	if amount > 0 and points_left() == 0:
		return false
	if allocated[attribute] + amount < 0:
		return false
	allocated[attribute] += amount
	_commit()
	return true

func reset_points() -> void:
	for attribute: String in allocated:
		allocated[attribute] = 0
	_commit()

func accepts(item_id: String, slot: String) -> bool:
	var base: String = inventory.get(item_id, {}).get("base_id", item_id)
	if not items.has(base) or not equipment.has(slot):
		return false
	var item: Dictionary = items[base]
	if item.slot == slot:
		return true
	return slot == "off_hand" and item.category == "weapon" and not item.get("two_handed", false)

func equip(item_id: String, slot: String) -> bool:
	if not inventory.has(item_id) or not accepts(item_id, slot):
		last_error = "That item does not fit this slot."
		return false
	if slot == "off_hand" and item_at("main_hand").get("two_handed", false):
		last_error = "Unequip the two-handed weapon before using the off hand."
		return false
	for other: String in equipment:
		if equipment[other] == item_id:
			equipment[other] = ""
	equipment[slot] = item_id
	if slot == "main_hand" and describe_item(item_id).get("two_handed", false):
		equipment.off_hand = ""
	_commit()
	return true

func unequip(slot: String) -> void:
	if equipment.has(slot):
		equipment[slot] = ""
		_commit()

func apply_starter() -> void:
	for slot: String in catalog.slots:
		var base: String = archetypes[archetype_id].loadout.get(slot, "")
		for uid: String in inventory:
			if inventory[uid].base_id == base:
				equip(uid, slot)
	_commit()

func save_to(path: String) -> bool:
	if session_provider.is_valid(): session=session_provider.call()
	var data := {"version": 2, "frost_hunt": frost_hunt, "hunt": hunt, "wilderness": wilderness, "loadouts": loadouts, "skills": skills, "session": session, "finale": finale, "seal": seal, "winter": winter, "threshold": threshold, "convergence": convergence, "choir": choir, "roots": roots, "lens": lens, "shore": shore, "archive": archive, "mountain": mountain, "stonewake": stonewake, "realm_progress": realm_progress, "story_completed": story_completed, "known_spells": known_spells, "active_spell": active_spell, "gold": gold, "merchants": merchants, "adventure": adventure, "inventory": inventory, "materials": materials, "consumables": consumables, "blueprints": blueprints, "formulas": formulas, "discovered": discovered, "claims": claims, "craft_xp": craft_xp, "next_id": next_id, "name": character_name, "origin": origin_id, "archetype": archetype_id, "frame": frame_id, "allocated": allocated, "equipment": equipment}
	var file := FileAccess.open(path + ".tmp", FileAccess.WRITE)
	data["intro_completed"] = intro_completed
	if file == null:
		return false
	file.store_string(JSON.stringify(data, "\t"))
	file.close()
	return DirAccess.rename_absolute(path + ".tmp", path) == OK

func load_from(path: String) -> bool:
	if not FileAccess.file_exists(path):
		return false
	var parser := JSON.new()
	if parser.parse(FileAccess.get_file_as_string(path)) != OK:
		return false
	var value: Variant = parser.data
	if not value is Dictionary or (value.get("version") != 1 and value.get("version") != 2):
		return false
	if value.has("intro_completed") and not value.intro_completed is bool: return false
	if not origins.has(value.get("origin", "")) or not archetypes.has(value.get("archetype", "")):
		return false
	if not value.get("allocated") is Dictionary or not value.get("equipment") is Dictionary:
		return false
	var clean_points := {}
	var spent := 0
	for attribute: String in catalog.attributes:
		var amount: Variant = value.allocated.get(attribute, 0)
		if typeof(amount) not in [TYPE_INT, TYPE_FLOAT] or float(amount) != floorf(float(amount)) or amount < 0 or amount > ATTRIBUTE_POINTS:
			return false
		clean_points[attribute] = int(amount)
		spent += int(amount)
	if spent > ATTRIBUTE_POINTS or not value.get("name", "") is String:
		return false
	if not _valid_adventure(value.get("adventure", {})):
		return false
	if not _valid_seal(value): return false
	if not _valid_winter(value): return false
	if not _valid_threshold(value): return false
	if not _valid_convergence(value): return false
	if not _valid_choir(value): return false
	if not _valid_roots(value): return false
	if not _valid_lens(value):
		return false
	if not _valid_shore(value):
		return false
	if not _valid_archive(value):
		return false
	if not _valid_mountain(value):
		return false
	if not _valid_stonewake(value):
		return false
	if not valid_frost_hunt(value): return false
	if not valid_hunt(value): return false
	if not preload("res://scripts/road_quest_rules.gd").valid(value): return false
	if not valid_wilderness(value.get("wilderness", {"defeated":[], "looted":[]})): return false
	if value.has("skills") and not Skills.valid(value.skills): return false
	if not valid_session(value.get("session",{})): return false
	if not _valid_finale(value): return false
	if not _valid_realms(value):
		return false
	if not _valid_trade(value):
		return false
	var clean_inventory: Dictionary = {}
	var clean_next := 1
	if value.version == 2:
		if not _valid_crafting_save(value):
			return false
		clean_inventory = value.inventory.duplicate(true)
		for record: Dictionary in clean_inventory.values():
			record.quality = int(record.quality)
		clean_next = int(value.next_id)
	if not valid_loadouts(value.get("loadouts", [{}, {}, {}, {}]), clean_inventory): return false
	var clean_equipment := {}
	for slot: String in catalog.slots:
		var item: Variant = value.equipment.get(slot, "")
		if not item is String:
			return false
		var base: String = clean_inventory.get(item, {}).get("base_id", "") if value.version == 2 else item
		if item != "" and (not accepts(base, slot) or (value.version == 2 and item in clean_equipment.values())):
			return false
		if value.version == 1 and item != "":
			var uid := "gear_%d" % clean_next
			clean_next += 1
			clean_inventory[uid] = _record(item)
			item = uid
		clean_equipment[slot] = item
	var main: Dictionary = items.get(clean_inventory.get(clean_equipment.main_hand, {}).get("base_id", ""), {})
	if main.get("two_handed", false) and not clean_equipment.off_hand.is_empty():
		return false
	var frame: Variant = value.get("frame", "balanced")
	if frame not in ["lean", "balanced", "broad"]:
		return false
	seal = value.get("seal", {"accepted": false, "supplies": false, "valves": [], "plans": false, "bound": false, "rewarded": false, "defeated": [], "looted": []}).duplicate(true)
	winter = value.get("winter", {"accepted": false, "supplies": false, "repairs": [], "assault": false, "orders": false, "rewarded": false, "defeated": [], "looted": []}).duplicate(true)
	threshold = value.get("threshold", {"accepted": false, "locker": false, "cargo": false, "power": false, "air": false, "record": false, "rewarded": false, "defeated": [], "looted": []}).duplicate(true)
	convergence = value.get("convergence", {"accepted": false, "evidence": [], "supplies": false, "installed": false, "calibrated": false, "rewarded": false, "defeated": [], "looted": []}).duplicate(true)
	choir = value.get("choir", {"accepted": false, "song": [], "activated": false, "record": false, "rewarded": false, "caches": [], "defeated": [], "looted": []}).duplicate(true)
	roots = value.get("roots", {"accepted": false, "heard": [], "cleansed": [], "choice": "", "record": false, "rewarded": false, "caches": [], "defeated": [], "looted": []}).duplicate(true)
	lens = value.get("lens", {"accepted": false, "rotations": {"dawn": 0, "dusk": 0, "crown": 2}, "activated": false, "chart": false, "rewarded": false, "caches": [], "defeated": [], "looted": []}).duplicate(true)
	for id: String in lens.rotations: lens.rotations[id]=int(lens.rotations[id])
	shore = value.get("shore", {"accepted": false, "heard": [], "relays": [], "caches": [], "identified": [], "log": false, "core": false, "choice": "", "rewarded": false, "defeated": [], "looted": []}).duplicate(true)
	archive = value.get("archive", {"accepted": false, "heard": [], "atlas": false, "recipient": "", "caches": [], "defeated": [], "looted": [], "reputation": {"lantern": 0, "briar": 0}}).duplicate(true)
	for faction: String in archive.reputation: archive.reputation[faction] = int(archive.reputation[faction])
	mountain = value.get("mountain", {"accepted": false, "heard": [], "ledger": false, "settlement": "", "clan": "", "wards": [], "rank": 0, "services": [], "reputation": {"stoneguard": 0, "stormweaver": 0}, "defeated": [], "looted": []}).duplicate(true)
	mountain.rank = int(mountain.rank)
	for clan: String in mountain.reputation: mountain.reputation[clan] = int(mountain.reputation[clan])
	stonewake = value.get("stonewake", {"accepted": false, "wards": [], "awakened": false, "rewarded": false}).duplicate(true)
	skills=value.get("skills",{"xp":{"melee":0,"marksman":0,"magic":0,"crafting":mini(900,int(value.get("craft_xp",0)))},"perks":[]}).duplicate(true)
	for skill: String in Skills.NAMES: skills.xp[skill]=int(skills.xp[skill])
	session=value.get("session",{}).duplicate(true)
	# Saves from before the opening existed keep their current adventure.
	intro_completed=value.get("intro_completed",true)
	finale = value.get("finale", {"shutdown": "last_furnace" in value.get("story_completed",[]), "reward":""}).duplicate(true)
	realm_progress = value.get("realm_progress", {"defeated": [], "looted": [], "attuned": [], "completed": []}).duplicate(true)
	story_completed = value.get("story_completed", []).duplicate()
	known_spells = value.get("known_spells", ["emberbolt"]).duplicate()
	active_spell = value.get("active_spell", "emberbolt")
	gold = int(value.get("gold", 150))
	merchants = value.get("merchants", {}).duplicate(true)
	for vendor: Dictionary in merchants.values():
		vendor.purse = int(vendor.purse)
		for sku: String in vendor.stock:
			vendor.stock[sku] = int(vendor.stock[sku])
		for record: Dictionary in vendor.buyback.values():
			record.quality = int(record.quality)
	origin_id = value.origin
	archetype_id = value.archetype
	character_name = value.name.strip_edges().left(32)
	if character_name.is_empty():
		character_name = "The Wanderer"
	frame_id = frame
	allocated = clean_points
	adventure = {"accepted": false, "rewarded": false, "defeated": [], "looted": [], "chests": []}
	if not value.get("adventure", {}).is_empty():
		adventure = value.adventure.duplicate(true)
	frost_hunt = value.get("frost_hunt", {"accepted":false,"rewarded":false}).duplicate(true)
	hunt = value.get("hunt", {"accepted":false, "reward":""}).duplicate(true)
	wilderness = value.get("wilderness", {"defeated":[], "looted":[]}).duplicate(true)
	loadouts = value.get("loadouts", [{}, {}, {}, {}]).duplicate(true)
	equipment = clean_equipment
	inventory = clean_inventory
	next_id = clean_next
	if value.version == 2:
		materials = value.materials.duplicate()
		consumables = value.consumables.duplicate()
		for id: String in materials:
			materials[id] = int(materials[id])
		for id: String in consumables:
			consumables[id] = int(consumables[id])
		blueprints = value.blueprints.duplicate()
		formulas = value.formulas.duplicate()
		discovered = value.discovered.duplicate()
		claims = value.claims.duplicate()
		craft_xp = int(value.craft_xp)
	else:
		materials = crafting.starting_materials.duplicate()
		blueprints = crafting.starting_blueprints.duplicate()
		formulas = crafting.starting_enchants.duplicate()
		consumables = {}
		claims = {}
		discovered = []
		for record: Dictionary in inventory.values():
			if record.base_id not in discovered:
				discovered.append(record.base_id)
	changed.emit()
	return true

func _record(base: String, quality: int = 0, enchant: String = "") -> Dictionary:
	return {"base_id": base, "quality": quality, "enchant": enchant, "gem": "", "favorite": false, "custom_name": ""}

func add_item(base: String, quality: int = 0, enchant: String = "") -> String:
	if not items.has(base) or quality < 0 or quality > 5 or (enchant != "" and definition("enchants", enchant).is_empty()):
		return ""
	var uid := "gear_%d" % next_id
	next_id += 1
	inventory[uid] = _record(base, quality, enchant)
	if base not in discovered:
		discovered.append(base)
	return uid

func definition(group: String, id: String) -> Dictionary:
	for entry: Dictionary in crafting[group]:
		if entry.id == id:
			return entry
	return {}

func describe_item(uid: String) -> Dictionary:
	if not inventory.has(uid):
		return {}
	var record: Dictionary = inventory[uid]
	var item: Dictionary = items[record.base_id].duplicate(true)
	item.id = uid
	item.base_id = record.base_id
	item.quality = int(record.quality)
	item.enchant = record.enchant
	item.gem = record.gem
	item.name = (record.custom_name if record.custom_name != "" else item.name) + (" · " + crafting.quality_names[int(record.quality)] if record.quality > 0 else "")
	if record.enchant != "":
		item.name += " of " + definition("enchants", record.enchant).name
	for stat in ["armor", "damage"]:
		if item.has(stat):
			item[stat] += int(record.quality) * 2
	for pair in [["enchant", "enchants"], ["gem", "gems"]]:
		var extra := definition(pair[1], record[pair[0]])
		for attribute: String in extra.get("bonuses", {}):
			item.bonuses[attribute] = int(item.bonuses.get(attribute, 0)) + int(extra.bonuses[attribute])
	return item

func protected_item(uid: String) -> bool:
	return not inventory.has(uid) or uid in equipment.values() or inventory[uid].favorite

func can_pay(cost: Dictionary) -> bool:
	for id: String in cost:
		if int(materials.get(id, 0)) < int(cost[id]):
			return false
	return true

func pay(cost: Dictionary) -> void:
	for id: String in cost:
		materials[id] = int(materials.get(id, 0)) - int(cost[id])

func cost_text(cost: Dictionary) -> String:
	var lines: PackedStringArray = []
	for id: String in cost:
		lines.append("%s  %d / %d" % [definition("materials", id).get("name", id), materials.get(id, 0), cost[id]])
	return "\n".join(lines)

func recipe_batchable(recipe: Dictionary) -> bool:
	return not recipe.is_empty() and recipe.output_kind in ["material","consumable"] and recipe.output not in ["transit_regulator","cinder_ward"]

func story_recovery_available(component: String) -> bool:
	var recipe_id := ""
	if component=="transit_regulator":
		if not convergence.accepted or not convergence.supplies or convergence.evidence.size()!=4 or convergence.installed: return false
		recipe_id="forge_transit_regulator"
	elif component=="cinder_ward":
		if not seal.accepted or not seal.supplies or not seal.plans or seal.bound: return false
		recipe_id="craft_cinder_ward"
	else: return false
	var recipe := definition("recipes",recipe_id)
	return recipe.unlock in blueprints and int(materials.get(component,0))==0 and not can_pay(recipe.cost)

func batch_cost(id: String, batches: int) -> Dictionary:
	var recipe := definition("recipes",id)
	if recipe.is_empty() or batches<1 or batches>10 or (batches>1 and not recipe_batchable(recipe)): return {}
	var total := {}
	for material: String in recipe.cost: total[material]=int(recipe.cost[material])*batches
	return total

func craft_recipe(id: String, station: String, batches: int=1) -> String:
	var recipe := definition("recipes", id)
	if recipe.is_empty() or recipe.station != station:
		return "Use the correct workstation."
	var total := batch_cost(id,batches)
	if total.is_empty(): return "Choose 1–10 batches; equipment and story components are crafted singly."
	if recipe.unlock not in blueprints:
		return "Find this blueprint while exploring."
	if not can_pay(total):
		return "Not enough materials."
	pay(total)
	match recipe.output_kind:
		"gear": add_item(recipe.output,1 if has_perk("artisan") else 0)
		"material": materials[recipe.output] = int(materials.get(recipe.output, 0)) + int(recipe.amount)*batches
		"consumable": consumables[recipe.output] = int(consumables.get(recipe.output, 0)) + int(recipe.amount)*batches
	train("crafting",int(recipe.xp)*batches,false)
	craft_xp += int(recipe.xp)*batches
	_commit()
	if batches>1:
		var group: String="materials" if recipe.output_kind=="material" else "consumables"
		return "Created %d × %s (%d batches)." % [int(recipe.amount)*batches,definition(group,recipe.output).get("name",recipe.output),batches]
	return "Created %s." % recipe.name

func temper_cost(uid: String) -> Dictionary:
	if not inventory.has(uid) or inventory[uid].quality >= 5:
		return {}
	var recipe := definition("recipes", "craft_" + inventory[uid].base_id)
	var cost := {}
	var temper_materials: Dictionary = items[inventory[uid].base_id].get("temper_materials", recipe.cost)
	for id: String in temper_materials:
		cost[id] = int(inventory[uid].quality) + 1
	if inventory[uid].quality >= 3:
		var family: String = items[inventory[uid].base_id].get("material", items[inventory[uid].base_id].family)
		var rare: String = items[inventory[uid].base_id].get("rare_temper_material", "")
		if rare != "":
			cost[rare] = int(inventory[uid].quality)-2
			return temper_discount(cost)
		cost["aether_shard" if family == "aether" else "soul_ember" if family == "cinder" else "ember_core"] = int(inventory[uid].quality) if family in ["aether", "cinder"] else 1
	return temper_discount(cost)

func improve(uid: String, station: String) -> String:
	if station != "forge" or not inventory.has(uid):
		return "Use the village forge with an owned item."
	var item := describe_item(uid)
	if not item.has("armor") and not item.has("damage"):
		return "This accessory can be enchanted, but cannot be tempered."
	var cost := temper_cost(uid)
	if cost.is_empty():
		return "Already Legendary."
	if not can_pay(cost):
		return "Not enough materials."
	pay(cost)
	inventory[uid].quality += 1
	train("crafting",2,false)
	craft_xp += 2
	_commit()
	return "Improved to %s." % crafting.quality_names[int(inventory[uid].quality)]

func enchant_item(uid: String, formula: String, station: String) -> String:
	var entry := definition("enchants", formula)
	if station != "enchant" or not inventory.has(uid) or formula not in formulas or entry.is_empty():
		return "Use the Runewright's Table and a learned formula."
	if inventory[uid].enchant == formula:
		return "This enchantment is already applied."
	if not can_pay(entry.cost):
		return "Not enough materials."
	pay(entry.cost)
	inventory[uid].enchant = formula
	train("crafting",3,false)
	craft_xp += 3
	_commit()
	return "Applied %s." % entry.name

func socket_gem(uid: String, gem: String, station: String) -> String:
	if station != "enchant" or not inventory.has(uid) or definition("gems", gem).is_empty():
		return "Use the Runewright's Table."
	if inventory[uid].quality < 2:
		return "Improve to Superior to unlock a gem socket."
	if inventory[uid].gem != "":
		return "Extract the existing gem first."
	if not can_pay({gem: 1}):
		return "You do not own this gem."
	pay({gem: 1})
	inventory[uid].gem = gem
	_commit()
	return "Gem socketed."

func extract_gem(uid: String, station: String) -> String:
	if station != "enchant" or not inventory.has(uid) or inventory[uid].gem == "":
		return "Select socketed gear at the Runewright's Table."
	if not can_pay({"rune_dust": 1}):
		return "Extraction requires 1 rune dust."
	pay({"rune_dust": 1})
	var gem: String = inventory[uid].gem
	materials[gem] = int(materials.get(gem, 0)) + 1
	inventory[uid].gem = ""
	_commit()
	return "Gem returned to your bag."

func salvage_yield(uid: String) -> Dictionary:
	if not inventory.has(uid):
		return {}
	var recipe := definition("recipes", "craft_" + inventory[uid].base_id)
	var result := {}
	for id: String in recipe.cost:
		if int(recipe.cost[id]) >= 2:
			result[id] = maxi(1, int(recipe.cost[id]) / 2)
	if result.is_empty():
		result[recipe.cost.keys()[0]] = 1
	return result

func dismantle(uid: String, learn: bool, station: String) -> String:
	if station != ("enchant" if learn else "forge"):
		return "Use the correct workstation."
	if protected_item(uid):
		return "Unequip and unfavorite the item first."
	var enchant: String = inventory[uid].enchant
	if learn and (enchant == "" or enchant in formulas):
		return "Select gear with an unknown enchantment."
	if learn:
		formulas.append(enchant)
	else:
		for id: String in salvage_yield(uid):
			materials[id] = int(materials.get(id, 0)) + int(salvage_yield(uid)[id])
	inventory.erase(uid)
	craft_xp += 1
	_commit()
	return "Item consumed; formula learned." if learn else "Item salvaged; materials recovered."

func personalize(uid: String, title: String, favorite: bool) -> void:
	if inventory.has(uid):
		inventory[uid].custom_name = title.strip_edges().left(32)
		inventory[uid].favorite = favorite
		_commit()

func gather(id: String, now: float) -> String:
	var node := definition("nodes", id)
	if node.is_empty():
		return "Unknown gathering spot."
	if claims.has(id) and (not node.has("cooldown") or now < float(claims[id]) + float(node.cooldown)):
		return "Already gathered. Explore elsewhere while it replenishes."
	var found: PackedStringArray = []
	for material: String in node.materials:
		materials[material] = int(materials.get(material, 0)) + int(node.materials[material])
		found.append("%s ×%d" % [definition("materials", material).name, node.materials[material]])
	for gear: Dictionary in node.get("gear", []):
		add_item(gear.base_id, int(gear.get("quality", 0)), gear.get("enchant", ""))
		found.append(items[gear.base_id].name)
	for blueprint: String in node.get("blueprints", []):
		if blueprint not in blueprints:
			blueprints.append(blueprint)
			found.append(blueprint.capitalize() + " blueprints")
	claims[id] = now
	_commit()
	return "Collected: " + ", ".join(found)

func consumable_preview(id: String, player: CharacterBody3D) -> Dictionary:
	var food := definition("consumables", id)
	if food.is_empty():
		return {}
	var pool: String = food.pool
	var boosted: bool = pool == "health" and item_at("chest").get("effect", "") == "healing_bonus"
	var restore := float(food.restore) * (1.25 if boosted else 1.0)
	var actual := minf(restore, maxf(0.0, float(player.derived[pool]) - float(player.get(pool))))
	return {"pool": pool, "restore": restore, "actual": actual, "unused": restore - actual, "boosted": boosted}

func consume(id: String, player: CharacterBody3D) -> String:
	var food := definition("consumables", id)
	if food.is_empty() or int(consumables.get(id, 0)) <= 0:
		return "None in your bag."
	var preview := consumable_preview(id, player)
	var pool: String = preview.pool
	if float(preview.actual) <= 0.0:
		return "%s is already full; item kept." % pool.capitalize()
	if player.has_method("record_combat"): player.record_combat("consume", preview.actual, id)
	player.set(pool, minf(float(player.derived[pool]), float(player.get(pool)) + float(preview.actual)))
	consumables[id] -= 1
	_commit()
	return "Used %s. Restored %s %s." % [food.name, String.num(preview.actual, 2), pool]

func _whole(value: Variant) -> bool:
	return typeof(value) in [TYPE_INT, TYPE_FLOAT] and is_finite(float(value)) and value >= 0 and value <= 100000000 and float(value) == floorf(float(value))

func _valid_crafting_save(value: Dictionary) -> bool:
	for key in ["inventory", "materials", "consumables", "claims"]:
		if not value.get(key) is Dictionary:
			return false
	for key in ["blueprints", "formulas", "discovered"]:
		if not value.get(key) is Array:
			return false
	if not _whole(value.get("next_id")) or value.next_id < 1 or not _whole(value.get("craft_xp")):
		return false
	for uid: Variant in value.inventory:
		var r: Variant = value.inventory[uid]
		if not uid is String or not uid.begins_with("gear_") or not uid.trim_prefix("gear_").is_valid_int() or int(uid.trim_prefix("gear_")) >= value.next_id or not r is Dictionary:
			return false
		if not items.has(r.get("base_id", "")) or not _whole(r.get("quality")) or r.quality > 5:
			return false
		if not r.get("favorite") is bool or not r.get("custom_name") is String or r.custom_name.length() > 32:
			return false
		for pair in [["enchant", "enchants"], ["gem", "gems"]]:
			if not r.get(pair[0]) is String or (r[pair[0]] != "" and definition(pair[1], r[pair[0]]).is_empty()):
				return false
		if r.gem != "" and r.quality < 2:
			return false
	for pair in [["materials", "materials"], ["consumables", "consumables"], ["claims", "nodes"]]:
		for id: Variant in value[pair[0]]:
			if not id is String or definition(pair[1], id).is_empty() or not _whole(value[pair[0]][id]) and pair[0] != "claims":
				return false
			if pair[0] == "claims" and (typeof(value.claims[id]) not in [TYPE_INT, TYPE_FLOAT] or not is_finite(float(value.claims[id])) or value.claims[id] < 0):
				return false
	var unlocks: Array = crafting.starting_blueprints.duplicate()
	for recipe: Dictionary in crafting.recipes:
		if recipe.unlock not in unlocks:
			unlocks.append(recipe.unlock)
	for id: Variant in value.blueprints:
		if id not in unlocks:
			return false
	for id: Variant in value.formulas:
		if not id is String or definition("enchants", id).is_empty():
			return false
	for id: Variant in value.discovered:
		if not items.has(id):
			return false
	return true

func _valid_adventure(value: Variant) -> bool:
	if not value is Dictionary:
		return false
	if value.is_empty():
		return true
	if not value.get("accepted") is bool or not value.get("rewarded") is bool:
		return false
	for group in ["defeated", "looted", "chests"]:
		if not value.get(group) is Array:
			return false
		var allowed := ["alcove", "vault"] if group == "chests" else ["guard_1", "archer_1", "mage_1", "guard_2", "archer_2", "mage_2", "captain"]
		var seen := []
		for id: Variant in value[group]:
			if id not in allowed or id in seen:
				return false
			seen.append(id)
	for id: String in value.looted:
		if id not in value.defeated:
			return false
	return not value.rewarded or (value.accepted and "captain" in value.looted)

func _valid_trade(value: Dictionary) -> bool:
	if not _whole(value.get("gold", 150)) or not value.get("merchants", {}) is Dictionary:
		return false
	var known := []
	for row: Dictionary in shop_data.shops: known.append(row.id)
	var held: Array = value.get("inventory", {}).keys() if value.get("inventory", {}) is Dictionary else []
	for id: Variant in value.get("merchants", {}):
		var vendor: Variant = value.merchants[id]
		if id not in known or not vendor is Dictionary or not _whole(vendor.get("purse")) or not vendor.get("stock") is Dictionary or not vendor.get("buyback") is Dictionary:
			return false
		for sku: Variant in vendor.stock:
			if not sku is String or not _whole(vendor.stock[sku]): return false
			var kind: String = sku.get_slice(":", 0)
			var base: String = sku.get_slice(":", 1)
			if kind == "gear":
				if not items.has(base): return false
			elif kind in ["material", "consumable"]:
				if not shop_data[kind + "_values"].has(base): return false
			else: return false
		for uid: Variant in vendor.buyback:
			if uid in held: return false
			held.append(uid)
		# Reuse the complete owned-item validator for sold equipment records.
		var probe := {"inventory": vendor.buyback, "materials": {}, "consumables": {}, "claims": {}, "blueprints": [], "formulas": [], "discovered": [], "next_id": value.get("next_id", 1), "craft_xp": 0}
		if not _valid_crafting_save(probe): return false
	return true

func spell_definition(id: String) -> Dictionary:
	for entry: Dictionary in realm_data.spells:
		if entry.id == id: return entry
	return {}

func cycle_spell() -> void:
	active_spell = known_spells[(known_spells.find(active_spell) + 1) % known_spells.size()]
	_commit()

func _valid_realms(value: Dictionary) -> bool:
	var progress: Variant = value.get("realm_progress", {"defeated": [], "looted": [], "attuned": [], "completed": []})
	if not progress is Dictionary: return false
	var enemies := ["aeralis_guard", "aeralis_mage", "aeralis_regent", "crucible_guard", "crucible_gunner", "crucible_warden"]
	for key in ["defeated", "looted", "attuned", "completed"]:
		if not progress.get(key) is Array: return false
		var seen := []
		for id: Variant in progress[key]:
			if id in seen or id not in (enemies if key in ["defeated", "looted"] else ["aeralis", "crucible"]): return false
			seen.append(id)
	for id: String in progress.looted:
		if id not in progress.defeated: return false
	for id: String in progress.completed:
		if ("aeralis_regent" if id == "aeralis" else "crucible_warden") not in progress.looted: return false
	if not value.get("story_completed", []) is Array or not value.get("known_spells", ["emberbolt"]) is Array: return false
	for id: Variant in value.get("story_completed", []):
		if id not in realm_data.story_ids: return false
	var spells: Array = value.get("known_spells", ["emberbolt"])
	if "emberbolt" not in spells: return false
	for id: Variant in spells:
		if not id is String or spell_definition(id).is_empty(): return false
	return value.get("active_spell", "emberbolt") in spells

func _valid_stonewake(value: Dictionary) -> bool:
	if not value.has("stonewake"): return true
	var record: Variant = value.stonewake
	if not record is Dictionary: return false
	for key in ["accepted", "awakened", "rewarded"]:
		if not record.get(key) is bool: return false
	if not record.get("wards") is Array or not value.get("story_completed", []) is Array: return false
	var seen := []
	for id: Variant in record.wards:
		if id not in ["hearth", "tide", "sky"] or id in seen: return false
		seen.append(id)
	if not record.accepted and (not seen.is_empty() or record.awakened or record.rewarded): return false
	if record.accepted and not value.get("adventure", {}).get("rewarded", false): return false
	if record.awakened and seen.size() != 3: return false
	if record.rewarded and (not record.awakened or "stonewake" not in value.get("story_completed", [])): return false
	return true

func _valid_mountain(value: Dictionary) -> bool:
	if not value.has("mountain"): return true
	var p: Variant = value.mountain
	if not p is Dictionary or not value.get("story_completed", []) is Array: return false
	for key in ["accepted","ledger"]:
		if not p.get(key) is bool: return false
	if p.get("clan") not in ["","stoneguard","stormweaver"] or p.get("settlement") not in ["","accord","stoneguard","stormweaver"]: return false
	if typeof(p.get("rank")) not in [TYPE_INT,TYPE_FLOAT] or p.rank != floorf(p.rank) or p.rank < 0 or p.rank > 3: return false
	var shelter: Variant=p.get("shelter_stage",0)
	if not (shelter is int or shelter is float) or not is_finite(float(shelter)) or shelter!=int(shelter) or shelter<0 or shelter>3: return false
	if p.get("shelter_choice","") not in ["","road","ridge"]: return false
	if shelter>0 and "stonewake" not in value.story_completed: return false
	if p.get("shelter_choice","")!="" and shelter!=3: return false
	if p.get("shelter_choice","")=="road" and (not p.get("defeated") is Array or p.defeated.size()!=3): return false
	var allowed := {"heard":["stoneguard","stormweaver"],"wards":["west","south","east"],"services":["supply_west","supply_east"],"defeated":["pass_0","pass_1","pass_2"],"looted":["pass_0","pass_1","pass_2"]}
	for key: String in allowed:
		if not p.get(key) is Array: return false
		var seen := []
		for id: Variant in p[key]:
			if id not in allowed[key] or id in seen: return false
			seen.append(id)
	for id in p.looted:
		if id not in p.defeated: return false
	if not p.get("reputation") is Dictionary: return false
	for clan in ["stoneguard","stormweaver"]:
		var rep: Variant = p.reputation.get(clan)
		if typeof(rep) not in [TYPE_INT,TYPE_FLOAT] or rep != floorf(rep) or rep < -100 or rep > 100: return false
	if p.accepted and "stonewake" not in value.story_completed: return false
	if not p.accepted and (not p.heard.is_empty() or p.ledger or p.settlement != ""): return false
	if p.ledger and p.defeated.size()!=3: return false
	if p.settlement!="" and (not p.ledger or p.heard.size()!=2 or "council" not in value.story_completed): return false
	if p.clan!="" and p.settlement=="": return false
	if p.clan=="" and (p.rank!=0 or not p.wards.is_empty() or not p.services.is_empty()): return false
	if p.rank>0 and p.wards.size()!=3: return false
	if p.rank==0 and not p.services.is_empty(): return false
	if p.rank>=2 and p.services.size()!=2: return false
	if not p.get("expedition",false) is bool or p.get("mandate","") not in ["","holds","leader"]: return false
	if not p.get("letters_started",false) is bool or not p.get("letters_witness",false) is bool or p.get("letters_choice","") not in ["","public","private"]: return false
	var letters: Variant=p.get("letters_received",[])
	if not letters is Array: return false
	var seen_letters:=[]
	for sender in letters:
		if sender not in ["stoneguard","stormweaver"] or sender in seen_letters: return false
		seen_letters.append(sender)
	if p.get("letters_started",false) and "stonewake" not in value.story_completed: return false
	if not letters.is_empty() and not p.get("letters_started",false): return false
	if p.get("letters_witness",false) and letters.size()!=2: return false
	if p.get("letters_choice","")!="" and not p.get("letters_witness",false): return false
	if p.get("expedition",false) and p.rank<2: return false
	if (p.rank==3)!=(p.get("mandate","")!=""): return false
	if p.rank==3:
		var wild: Variant=value.get("wilderness",{})
		if not p.get("expedition",false) or not valid_wilderness(wild): return false
		for id in ["wild_11","wild_12"]:
			if id not in wild.looted: return false
	return true

func _valid_archive(value: Dictionary) -> bool:
	if not value.has("archive"): return true
	var p: Variant = value.archive
	if not p is Dictionary or not value.get("story_completed", []) is Array: return false
	if not p.get("accepted") is bool or not p.get("atlas") is bool or p.get("recipient") not in ["","lantern","briar"]: return false
	var allowed := {"heard":["lantern","briar"],"caches":["cache_west","cache_east"],"defeated":["archive_0","archive_1","archive_2","archive_3"],"looted":["archive_0","archive_1","archive_2","archive_3"]}
	for key: String in allowed:
		if not p.get(key) is Array: return false
		var seen := []
		for id: Variant in p[key]:
			if id not in allowed[key] or id in seen: return false
			seen.append(id)
	for id in p.looted:
		if id not in p.defeated: return false
	if p.accepted and "stonewake" not in value.story_completed: return false
	if p.atlas and (not p.accepted or "archive_3" not in p.defeated): return false
	if p.recipient!="" and (not p.atlas or p.heard.size()!=2 or "archive" not in value.story_completed): return false
	var apprentice_stage: Variant=p.get("apprentice_stage",0)
	if not (apprentice_stage is int or apprentice_stage is float) or not is_finite(float(apprentice_stage)) or apprentice_stage!=int(apprentice_stage) or apprentice_stage<0 or apprentice_stage>3: return false
	if p.get("apprentice_choice","") not in ["","return","protect"]: return false
	if apprentice_stage>0 and "stonewake" not in value.story_completed: return false
	if apprentice_stage==3 and "archive_2" not in p.defeated: return false
	if p.get("apprentice_choice","")!="" and apprentice_stage!=3: return false
	if p.get("lantern_trial","") not in ["","accepted","testimony","fragment","member"]: return false
	if p.get("lantern_trial","")!="" and p.recipient=="": return false
	if not p.get("names_accepted",false) is bool or p.get("names_choice","") not in ["","public","sealed"]: return false
	var records: Variant=p.get("names_records",[])
	if not records is Array: return false
	var seen_names:=[]
	for id in records:
		if id not in ["names_dock","names_roll","names_seal"] or id in seen_names: return false
		seen_names.append(id)
	if p.get("names_accepted",false) and p.get("lantern_trial","")!="member": return false
	if not records.is_empty() and not p.get("names_accepted",false): return false
	if "names_seal" in records and not value.get("convergence",{}).get("calibrated",false): return false
	if p.get("names_choice","")!="" and records.size()!=3: return false
	if not p.get("price_started",false) is bool or p.get("price_choice","") not in ["","seal","share","oversight"]: return false
	var views: Variant=p.get("price_heard",[])
	if not views is Array or views.size()>2: return false
	var seen_views:=[]
	for id in views:
		if id not in ["lantern","briar"] or id in seen_views: return false
		seen_views.append(id)
	if p.get("price_started",false) and p.get("names_choice","")=="": return false
	if not views.is_empty() and not p.get("price_started",false): return false
	if p.get("price_choice","")!="" and views.size()!=2: return false
	if not p.get("reputation") is Dictionary: return false
	for faction in ["lantern","briar"]:
		var expected := 0 if p.recipient=="" else 25 if p.recipient==faction else -10
		if p.reputation.get(faction) != expected: return false
	return true

func _valid_shore(value: Dictionary) -> bool:
	if not value.has("shore"): return true
	var p: Variant=value.shore
	if not p is Dictionary or not value.get("story_completed",[]) is Array: return false
	for key in ["accepted","log","core","rewarded"]:
		if not p.get(key) is bool: return false
	if p.get("choice") not in ["","harbor","navigation"]: return false
	var enemy_ids=["shore_0","shore_1","shore_2","shore_3","shore_4","shore_5","shore_6"]
	var allowed={"heard":["harbor","salvager"],"relays":["pump","relay"],"caches":["coast_cache","cave_cache"],"identified":["blade","armor","focus"],"defeated":enemy_ids,"looted":enemy_ids}
	for key: String in allowed:
		if not p.get(key) is Array: return false
		var seen=[]
		for id: Variant in p[key]:
			if id not in allowed[key] or id in seen: return false
			seen.append(id)
	for id in p.looted:
		if id not in p.defeated: return false
	if p.accepted and "archive" not in value.story_completed: return false
	if not p.relays.is_empty() and not p.accepted: return false
	if "relay" in p.relays and "pump" not in p.relays: return false
	if p.log and p.relays.size()!=2: return false
	if p.core and (not p.log or "shore_6" not in p.defeated): return false
	if p.choice!="" and (not p.core or p.heard.size()!=2): return false
	if p.rewarded and (p.choice=="" or "tides" not in value.story_completed): return false
	var silver: Variant=p.get("silver_stage",0)
	if not (silver is int or silver is float) or not is_finite(float(silver)) or silver!=int(silver) or silver<0 or silver>3: return false
	if p.get("silver_choice","") not in ["","public","protect"]: return false
	if silver>0 and "archive" not in value.story_completed: return false
	if silver==3 and "shore_1" not in p.defeated: return false
	if p.get("silver_choice","")!="" and silver!=3: return false
	var compact: Variant=p.get("compact_stage",0)
	if not (compact is int or compact is float) or not is_finite(float(compact)) or compact!=int(compact) or compact<0 or compact>4: return false
	var evidence: Variant=p.get("compact_evidence",[])
	if not evidence is Array: return false
	var seen_evidence:=[]
	for entry in evidence:
		if entry not in ["registry","nameplate","salvager"] or entry in seen_evidence: return false
		seen_evidence.append(entry)
	if compact>0 and not p.rewarded: return false
	if not evidence.is_empty() and compact==0: return false
	if "nameplate" in evidence and "shore_0" not in p.defeated: return false
	if compact>=2 and evidence.size()!=3: return false
	var harbor: Variant=p.get("harbor_stage",0)
	if not (harbor is int or harbor is float) or not is_finite(float(harbor)) or harbor!=int(harbor) or harbor<0 or harbor>5: return false
	if p.get("harbor_choice","") not in ["","public","sealed"]: return false
	if harbor>0 and compact!=4: return false
	if harbor>=4 and "shore_2" not in p.defeated: return false
	if (harbor==5)!=(p.get("harbor_choice","")!=""): return false
	if not p.get("passage_started",false) is bool or p.get("passage_choice","") not in ["","open","house","outlaw"]: return false
	var proposals: Variant=p.get("passage_heard",[])
	if not proposals is Array: return false
	var seen_proposals:=[]
	for entry in proposals:
		if entry not in ["harbor","salvager","witness"] or entry in seen_proposals: return false
		seen_proposals.append(entry)
	if p.get("passage_started",false) and harbor!=5: return false
	if not proposals.is_empty() and not p.get("passage_started",false): return false
	if p.get("passage_choice","")!="" and (not p.get("passage_started",false) or proposals.size()!=3): return false
	var light: Variant=p.get("light_stage",0)
	if not (light is int or light is float) or light!=int(light) or light<0 or light>4: return false
	if p.get("light_choice","") not in ["","public","family"]: return false
	if light>0 and "archive" not in value.story_completed: return false
	if p.get("light_choice","")!="" and light!=4: return false
	if not p.get("ash_started",false) is bool or p.get("ash_choice","") not in ["","workers","choir"]: return false
	for pair in [["ash_evidence",["ash_hull","ash_manifest"]],["ash_claims",["ash_factor","ash_reader"]]]:
		var entries: Variant=p.get(pair[0],[])
		if not entries is Array: return false
		var seen:=[]
		for entry in entries:
			if entry not in pair[1] or entry in seen: return false
			seen.append(entry)
		if not entries.is_empty() and not p.get("ash_started",false): return false
	if p.get("ash_started",false) and "archive" not in value.story_completed: return false
	if not p.get("ash_claims",[]).is_empty() and p.get("ash_evidence",[]).size()!=2: return false
	if p.get("ash_choice","")!="" and p.get("ash_claims",[]).size()!=2: return false
	var sources={"blade":"coast_cache","armor":"cave_cache","focus":"shore_6"}
	for id in p.identified:
		if sources[id] not in p.caches and sources[id] not in p.looted: return false
	return true

func _valid_lens(value: Dictionary) -> bool:
	if not value.has("lens"): return true
	var p: Variant=value.lens
	if not p is Dictionary or not value.get("story_completed",[]) is Array: return false
	for key in ["accepted","activated","chart","rewarded"]:
		if not p.get(key) is bool: return false
	if not p.get("rotations") is Dictionary or p.rotations.size()!=3: return false
	for id in ["dawn","dusk","crown"]:
		var r: Variant=p.rotations.get(id)
		if typeof(r) not in [TYPE_INT,TYPE_FLOAT] or r!=floorf(float(r)) or r<0 or r>3: return false
	var enemy_ids=["lens_0","lens_1","lens_2","lens_3","lens_4"]
	var allowed={"caches":["west_cache","east_cache"],"defeated":enemy_ids,"looted":enemy_ids}
	for key: String in allowed:
		if not p.get(key) is Array: return false
		var seen=[]
		for id: Variant in p[key]:
			if id not in allowed[key] or id in seen: return false
			seen.append(id)
	for id in p.looted:
		if id not in p.defeated: return false
	if p.accepted and "archive" not in value.story_completed: return false
	if not p.accepted and (int(p.rotations.dawn)!=0 or int(p.rotations.dusk)!=0 or int(p.rotations.crown)!=2): return false
	if p.activated and (not p.accepted or int(p.rotations.dawn)!=1 or int(p.rotations.dusk)!=3 or int(p.rotations.crown)!=0): return false
	if "lens_4" in p.defeated and not p.activated: return false
	if p.chart and "lens_4" not in p.defeated: return false
	if p.rewarded and (not p.chart or "lens" not in value.story_completed): return false
	if not p.get("debt_started",false) is bool or p.get("debt_choice","") not in ["","creditor","public"]: return false
	var instruments: Variant=p.get("debt_instruments",[])
	if not instruments is Array: return false
	var seen_instruments:=[]
	for instrument in instruments:
		if instrument not in ["west_cache","east_cache"] or instrument in seen_instruments: return false
		if ("lens_0" if instrument=="west_cache" else "lens_1") not in p.defeated: return false
		seen_instruments.append(instrument)
	if p.get("debt_started",false) and "archive" not in value.story_completed: return false
	if not instruments.is_empty() and not p.get("debt_started",false): return false
	if p.get("debt_choice","")!="" and instruments.size()!=2: return false
	return true

func _valid_roots(value: Dictionary) -> bool:
	if not value.has("roots"): return true
	var p: Variant=value.roots
	if not p is Dictionary or not value.get("story_completed",[]) is Array: return false
	var amber: Variant=p.get("amber_stage",0)
	if not (amber is int or amber is float) or amber!=int(amber) or amber<0 or amber>4: return false
	if p.get("amber_choice","") not in ["","protect","logging"]: return false
	if amber>0 and "stonewake" not in value.story_completed: return false
	if p.get("amber_choice","")!="" and amber!=4: return false
	for key in ["accepted","record","rewarded"]:
		if not p.get(key) is bool: return false
	if p.get("choice") not in ["","wild","tended"]: return false
	var enemy_ids=["roots_0","roots_1","roots_2","roots_3"]
	var allowed={"heard":["keeper","steward"],"cleansed":["spring","stone","seed"],"caches":["camp_cache","grove_cache"],"defeated":enemy_ids,"looted":enemy_ids}
	for key: String in allowed:
		if not p.get(key) is Array: return false
		var seen=[]
		for id: Variant in p[key]:
			if id not in allowed[key] or id in seen: return false
			seen.append(id)
	for id in p.looted:
		if id not in p.defeated: return false
	if p.accepted and "stonewake" not in value.story_completed: return false
	var guards={"spring":"roots_0","stone":"roots_1","seed":"roots_2"}
	for id in p.cleansed:
		if not p.accepted or guards[id] not in p.defeated: return false
	if "roots_3" in p.defeated and p.cleansed.size()!=3: return false
	if p.choice!="" and (p.heard.size()!=2 or "roots_3" not in p.defeated): return false
	if p.record and p.choice=="": return false
	if p.rewarded and (not p.record or "roots" not in value.story_completed): return false
	if not p.get("coven_started",false) is bool or p.get("coven_oath","") not in ["","shelter","medicine"]: return false
	var beds: Variant=p.get("coven_beds",[])
	if not beds is Array: return false
	var seen_beds:=[]
	for id in beds:
		if id not in ["bed_west","bed_east","bed_south"] or id in seen_beds: return false
		seen_beds.append(id)
	if p.get("coven_started",false) and not p.rewarded: return false
	if not beds.is_empty() and not p.get("coven_started",false): return false
	if p.get("coven_oath","")!="" and beds.size()!=3: return false
	if not p.get("debt_started",false) is bool or p.get("debt_choice","") not in ["","bridge","cistern"]: return false
	var evidence: Variant=p.get("debt_evidence",[])
	if not evidence is Array: return false
	var seen_evidence:=[]
	for id in evidence:
		if id not in ["foundation","spring","steward"] or id in seen_evidence: return false
		seen_evidence.append(id)
	if p.get("debt_started",false) and p.get("coven_oath","")=="": return false
	if not evidence.is_empty() and not p.get("debt_started",false): return false
	if p.get("debt_choice","")!="" and evidence.size()!=3: return false
	if not p.get("promise_started",false) is bool or p.get("promise_choice","") not in ["","renew","shared"]: return false
	var heard: Variant=p.get("promise_heard",[])
	if not heard is Array: return false
	var seen_heard:=[]
	for id in heard:
		if id not in ["keeper","steward","record"] or id in seen_heard: return false
		seen_heard.append(id)
	if p.get("promise_started",false) and p.get("debt_choice","")=="": return false
	if not heard.is_empty() and not p.get("promise_started",false): return false
	if p.get("promise_choice","")!="" and heard.size()!=3: return false
	var stag_step: Variant=p.get("stag_step",0)
	if not (stag_step is int or stag_step is float) or not is_finite(float(stag_step)) or stag_step!=int(stag_step) or stag_step<0 or stag_step>5: return false
	if stag_step>0 and not p.rewarded: return false
	return true

func _valid_choir(value: Dictionary) -> bool:
	if not value.has("choir"): return true
	var p: Variant=value.choir
	if not p is Dictionary or not value.get("story_completed",[]) is Array: return false
	for key in ["accepted","activated","record","rewarded"]:
		if not p.get(key) is bool: return false
	var song=["ember","ash","stone"]
	if not p.get("song") is Array or p.song.size()>3: return false
	for i in range(p.song.size()):
		if p.song[i]!=song[i]: return false
	var enemy_ids=["choir_0","choir_1","choir_2","choir_3","choir_4"]
	var allowed={"caches":["camp_cache","vault_cache"],"defeated":enemy_ids,"looted":enemy_ids}
	for key: String in allowed:
		if not p.get(key) is Array: return false
		var seen=[]
		for id: Variant in p[key]:
			if id not in allowed[key] or id in seen: return false
			seen.append(id)
	for id in p.looted:
		if id not in p.defeated: return false
	if p.accepted and "council" not in value.story_completed: return false
	if not p.song.is_empty() and not p.accepted: return false
	if p.activated and (not p.accepted or p.song!=song): return false
	if "choir_4" in p.defeated and not p.activated: return false
	if p.record and "choir_4" not in p.defeated: return false
	if p.rewarded and (not p.record or "choir" not in value.story_completed): return false
	var pilgrim_stage: Variant=p.get("pilgrim_stage",0)
	if not (pilgrim_stage is int or pilgrim_stage is float) or not is_finite(float(pilgrim_stage)) or pilgrim_stage!=int(pilgrim_stage) or pilgrim_stage<0 or pilgrim_stage>3: return false
	if p.get("pilgrim_choice","") not in ["","shelter","depart"]: return false
	if pilgrim_stage>0 and "council" not in value.story_completed: return false
	if pilgrim_stage==3 and "choir_1" not in p.defeated: return false
	if p.get("pilgrim_choice","")!="" and pilgrim_stage!=3: return false
	for key in ["listener_started","listener_record","listener_joined"]:
		if not p.get(key,false) is bool: return false
	var vigils: Variant=p.get("listener_vigils",[])
	if not vigils is Array: return false
	var seen_vigils:=[]
	for entry in vigils:
		if entry not in ["vigil_south","vigil_middle","vigil_north"] or entry in seen_vigils: return false
		seen_vigils.append(entry)
	if p.get("listener_started",false) and not p.rewarded: return false
	if not vigils.is_empty() and not p.get("listener_started",false): return false
	if p.get("listener_record",false) and vigils.size()!=3: return false
	if p.get("listener_joined",false) and not p.get("listener_record",false): return false
	for key in ["memory_started","memory_record"]:
		if not p.get(key,false) is bool: return false
	var lock: Variant=p.get("memory_lock",0)
	if not (lock is int or lock is float) or not is_finite(float(lock)) or lock!=int(lock) or lock<0 or lock>3: return false
	if p.get("memory_choice","") not in ["","publish","conceal"]: return false
	if p.get("memory_started",false) and not p.get("listener_joined",false): return false
	if lock>0 and not p.get("memory_started",false): return false
	if p.get("memory_record",false) and lock!=3: return false
	if p.get("memory_choice","")!="" and not p.get("memory_record",false): return false
	if not p.get("fire_started",false) is bool or p.get("fire_choice","") not in ["","awaken","contain","silence"]: return false
	var seals: Variant=p.get("fire_seals",[])
	if not seals is Array: return false
	var seen_seals:=[]
	for entry in seals:
		if entry not in ["fire_west","fire_east"] or entry in seen_seals: return false
		if ("choir_2" if entry=="fire_west" else "choir_3") not in p.defeated: return false
		seen_seals.append(entry)
	if p.get("fire_started",false) and p.get("memory_choice","")=="": return false
	if not seals.is_empty() and not p.get("fire_started",false): return false
	if p.get("fire_choice","")!="" and seals.size()!=2: return false
	if p.get("fire_choice","")=="awaken" and value.get("mountain",{}).get("rank",0)==3: return false
	return true

func _valid_convergence(value: Dictionary) -> bool:
	if not value.has("convergence"): return true
	var p: Variant=value.convergence
	if not p is Dictionary or not value.get("story_completed",[]) is Array: return false
	for key in ["accepted","supplies","installed","calibrated","rewarded"]:
		if not p.get(key) is bool: return false
	var rescue: Variant=p.get("rescue_stage",0)
	if not (rescue is int or rescue is float) or not is_finite(float(rescue)) or rescue!=int(rescue) or rescue<0 or rescue>4: return false
	if rescue>0:
		for prerequisite in ["roots","tides","lens","choir"]:
			if prerequisite not in value.story_completed: return false
	var requirements=["roots","tides","lens","choir"]
	var enemy_ids=["convergence_0","convergence_1","convergence_2"]
	var allowed={"evidence":requirements,"defeated":enemy_ids,"looted":enemy_ids}
	for key: String in allowed:
		if not p.get(key) is Array: return false
		var seen=[]
		for id: Variant in p[key]:
			if id not in allowed[key] or id in seen: return false
			seen.append(id)
	for id in p.looted:
		if id not in p.defeated: return false
	if p.accepted:
		for id in requirements:
			if id not in value.story_completed: return false
	if not p.evidence.is_empty() and not p.accepted: return false
	if p.installed and (not p.accepted or p.evidence.size()!=4): return false
	if not p.defeated.is_empty() and not p.installed: return false
	if p.calibrated and (not p.installed or p.defeated.size()!=3): return false
	if p.rewarded and (not p.calibrated or "convergence" not in value.story_completed): return false
	return true

func _valid_threshold(value: Dictionary) -> bool:
	if not value.has("threshold"): return true
	var p: Variant=value.threshold
	if not p is Dictionary or not value.get("story_completed",[]) is Array: return false
	for key in ["accepted","locker","cargo","power","air","record","rewarded"]:
		if not p.get(key) is bool: return false
	var ids=["threshold_0","threshold_1","threshold_2","threshold_3","threshold_4","threshold_5"]
	for key in ["defeated","looted"]:
		if not p.get(key) is Array: return false
		var seen=[]
		for id: Variant in p[key]:
			if id not in ids or id in seen: return false
			seen.append(id)
	for id in p.looted:
		if id not in p.defeated: return false
	if p.accepted and "convergence" not in value.story_completed: return false
	if p.power and not p.accepted: return false
	if p.air and not p.power: return false
	for id in ["threshold_3","threshold_4","threshold_5"]:
		if id in p.defeated and not p.air: return false
	if p.record and "threshold_5" not in p.defeated: return false
	if p.rewarded and (not p.record or "threshold" not in value.story_completed): return false
	return true

func _valid_winter(value: Dictionary) -> bool:
	if not value.has("winter"): return true
	var p: Variant=value.winter
	if not p is Dictionary or not value.get("story_completed",[]) is Array: return false
	for key in ["accepted","supplies","assault","orders","rewarded"]:
		if not p.get(key) is bool: return false
	var ids=["winter_0","winter_1","winter_2","winter_3","winter_4","winter_5"]
	var allowed={"repairs":["ward","ballista"],"defeated":ids,"looted":ids}
	for key: String in allowed:
		if not p.get(key) is Array: return false
		var seen=[]
		for id: Variant in p[key]:
			if id not in allowed[key] or id in seen: return false
			seen.append(id)
	for id in p.looted:
		if id not in p.defeated: return false
	if p.accepted and "returning_light" not in value.story_completed: return false
	if (p.supplies or not p.defeated.is_empty() or not p.repairs.is_empty()) and not p.accepted: return false
	if not p.repairs.is_empty():
		for id in ids.slice(0,3):
			if id not in p.defeated: return false
	if p.assault and p.repairs.size()!=2: return false
	for id in ids.slice(3,6):
		if id in p.defeated and not p.assault: return false
	if p.orders and p.defeated.size()!=6: return false
	if p.rewarded and (not p.orders or "winter_siege" not in value.story_completed): return false
	return true

func _valid_seal(value: Dictionary) -> bool:
	if not value.has("seal"): return true
	var p: Variant=value.seal
	if not p is Dictionary or not value.get("story_completed",[]) is Array: return false
	for key in ["accepted","supplies","plans","bound","rewarded"]:
		if not p.get(key) is bool: return false
	var ids=["seal_0","seal_1","seal_2","seal_3","seal_4"]
	var allowed={"valves":["intake","exhaust"],"defeated":ids,"looted":ids}
	for key: String in allowed:
		if not p.get(key) is Array: return false
		var seen=[]
		for id: Variant in p[key]:
			if id not in allowed[key] or id in seen: return false
			seen.append(id)
	for id in p.looted:
		if id not in p.defeated: return false
	if p.accepted and "winter_siege" not in value.story_completed: return false
	if (p.supplies or not p.defeated.is_empty() or not p.valves.is_empty()) and not p.accepted: return false
	if "intake" in p.valves and "seal_0" not in p.defeated: return false
	if "exhaust" in p.valves and "seal_1" not in p.defeated: return false
	for id in ["seal_2","seal_3"]:
		if id in p.defeated and p.valves.size()!=2: return false
	if p.plans and ("seal_2" not in p.defeated or "seal_3" not in p.defeated): return false
	if "seal_4" in p.defeated and not p.plans: return false
	if p.bound and (not p.plans or "seal_4" not in p.defeated): return false
	if p.rewarded and (not p.bound or "broken_seal" not in value.story_completed): return false
	return true

func _valid_finale(value: Dictionary) -> bool:
	if not value.has("finale"): return true
	var p: Variant=value.finale
	if not p is Dictionary or not p.get("shutdown") is bool or p.get("reward") not in ["","blade","bow","staff"]: return false
	var progress: Variant=value.get("realm_progress",{})
	var story: Variant=value.get("story_completed",[])
	if not progress is Dictionary or not story is Array: return false
	if p.shutdown:
		if not progress.get("looted",[]) is Array or "crucible_warden" not in progress.get("looted",[]): return false
	if p.reward!="" and (not p.shutdown or "last_furnace" not in story or "crucible" not in progress.get("completed",[])): return false
	if "last_furnace" in story and not p.shutdown: return false
	return true

static func valid_session(value: Variant) -> bool:
	if not value is Dictionary: return false
	if value.is_empty(): return true
	if value.get("area") not in ["home","aeralis","crucible","seal","winter","threshold","convergence","choir","roots","lens","shore","archive_chapter","mountain","adventure"]: return false
	if not value.get("third_person") is bool: return false
	if not _session_vector(value.get("position")): return false
	for key in ["yaw","pitch","health","magicka","stamina"]:
		if not _session_number(value.get(key)): return false
	if value.health<=0 or value.magicka<0 or value.stamina<0: return false
	if not value.get("enemies") is Array or value.enemies.size()>100: return false
	var ids=[]
	for actor: Variant in value.enemies:
		if not actor is Dictionary or not actor.get("id") is String or actor.id.length()>100 or actor.id in ids: return false
		if not _session_vector(actor.get("position")) or not _session_number(actor.get("health")) or actor.health<=0: return false
		ids.append(actor.id)
	return true
static func _session_number(value: Variant) -> bool:
	return (value is int or value is float) and is_finite(float(value)) and absf(float(value))<100000
static func _session_vector(value: Variant) -> bool:
	return value is Array and value.size()==3 and _session_number(value[0]) and _session_number(value[1]) and _session_number(value[2])

func skill_level(skill: String) -> int:
	return 1+int(skills.xp.get(skill,0))/100
func perk_points() -> int:
	var points:=0
	for skill: String in Skills.NAMES: points+=skill_level(skill)-1
	for id: String in skills.perks: points-=int(Skills.PERKS[id].cost)
	return points
func has_perk(id: String) -> bool: return id in skills.perks
func can_learn_perk(id: String) -> bool:
	if not Skills.PERKS.has(id) or has_perk(id): return false
	var perk: Dictionary=Skills.PERKS[id]
	return skill_level(perk.skill)>=perk.level and perk_points()>=perk.cost
func learn_perk(id: String) -> bool:
	if not can_learn_perk(id): return false
	skills.perks.append(id); _commit(); skills_changed.emit(); return true
func refund_perk(id: String) -> bool:
	if not Skills.PERKS.has(id) or not has_perk(id): return false
	skills.perks.erase(id)
	_commit()
	skills_changed.emit()
	return true

func train(skill: String,amount: int,commit: bool=true) -> bool:
	if not Skills.NAMES.has(skill) or amount<=0: return false
	var before:=skill_level(skill)
	skills.xp[skill]=mini(900,int(skills.xp[skill])+amount)
	var after:=skill_level(skill)
	skills_changed.emit()
	if after>before:
		skill_advanced.emit(skill,after)
		if commit: _commit()
	return after>before
func temper_discount(cost: Dictionary) -> Dictionary:
	if has_perk("careful_tempering"):
		for key: String in cost: cost[key]=maxi(1,int(cost[key])-1)
	return cost
func spell_cost(base: float) -> float: return base*(.8 if has_perk("clear_channel") else 1.0)

func valid_loadouts(value: Variant, owned: Dictionary) -> bool:
	if not value is Array or value.size() != 4: return false
	for entry: Variant in value:
		if not entry is Dictionary: return false
		if entry.is_empty(): continue
		if not entry.get("name") is String or entry.name.strip_edges().is_empty() or entry.name.length() > 24: return false
		if not entry.get("equipment") is Dictionary or not entry.get("bases") is Dictionary: return false
		if entry.equipment.size() != catalog.slots.size() or entry.bases.size() != catalog.slots.size(): return false
		var seen := []
		for slot: String in catalog.slots:
			var uid: Variant = entry.equipment.get(slot)
			var base: Variant = entry.bases.get(slot)
			if not uid is String or not base is String or uid.length() > 128: return false
			if uid == "":
				if base != "": return false
				continue
			if uid in seen or not items.has(base): return false
			seen.append(uid)
			var item: Dictionary = items[base]
			if item.slot != slot and not (slot == "off_hand" and item.category == "weapon" and not item.get("two_handed", false)): return false
			if owned.has(uid) and owned[uid].base_id != base: return false
		if items.get(entry.bases.main_hand, {}).get("two_handed", false) and entry.equipment.off_hand != "": return false
	return true

func save_loadout(index: int, title: String) -> bool:
	title = title.strip_edges()
	if index < 0 or index >= 4 or title.is_empty() or title.length() > 24: return false
	var bases := {}
	for slot: String in catalog.slots: bases[slot] = inventory.get(equipment[slot], {}).get("base_id", "")
	loadouts[index] = {"name": title, "equipment": equipment.duplicate(), "bases": bases}
	_commit()
	return true

func loadout_missing(index: int) -> Array[String]:
	var missing: Array[String] = []
	if index < 0 or index >= 4 or loadouts[index].is_empty(): return missing
	for slot: String in catalog.slots:
		var uid: String = loadouts[index].equipment[slot]
		if uid != "" and not inventory.has(uid): missing.append(slot.capitalize() + ": " + items[loadouts[index].bases[slot]].name)
	return missing

func apply_loadout(index: int) -> bool:
	if index < 0 or index >= 4 or loadouts[index].is_empty(): return false
	var missing := loadout_missing(index)
	if not missing.is_empty():
		last_error = "Missing / sold gear: " + ", ".join(missing)
		return false
	if not valid_loadouts(loadouts, inventory): return false
	equipment = loadouts[index].equipment.duplicate()
	_commit()
	return true

func delete_loadout(index: int) -> bool:
	if index < 0 or index >= 4 or loadouts[index].is_empty(): return false
	loadouts[index] = {}; _commit(); return true

func valid_wilderness(value: Variant) -> bool:
	if not value is Dictionary: return false
	var allowed := []
	for i in range(13): allowed.append("wild_%d" % i)
	for group in ["defeated", "looted"]:
		if not value.get(group) is Array: return false
		var seen := []
		for id in value[group]:
			if id not in allowed or id in seen: return false
			seen.append(id)
	for id in value.looted:
		if id not in value.defeated: return false
	return true

func valid_hunt(value: Dictionary) -> bool:
	var record: Variant = value.get("hunt", {"accepted":false, "reward":""})
	if not record is Dictionary or not record.get("accepted") is bool or record.get("reward") not in ["", "mossfang_blade", "mossheart_amulet"]: return false
	for key in ["lodge_started","lodge_joined"]:
		if not record.get(key,false) is bool: return false
	var repairs: Variant=record.get("lodge_repairs",[])
	if not repairs is Array: return false
	var seen:=[]
	for entry in repairs:
		if entry not in ["village","crossing","ridge"] or entry in seen: return false
		seen.append(entry)
	if record.get("lodge_started",false) and not value.get("adventure",{}).get("rewarded",false): return false
	if not repairs.is_empty() and not record.get("lodge_started",false): return false
	if record.get("lodge_joined",false) and repairs.size()!=3: return false
	if "ridge" in repairs:
		var wild: Variant=value.get("wilderness",{})
		if not valid_wilderness(wild): return false
		if "wild_9" not in wild.defeated or "wild_10" not in wild.defeated: return false
	var water: Variant=record.get("water_stage",0)
	if not (water is int or water is float) or not is_finite(float(water)) or water!=int(water) or water<0 or water>4: return false
	if record.get("water_choice","") not in ["","expose","patron"]: return false
	if water>0 and not record.get("lodge_joined",false): return false
	if record.get("water_choice","")!="" and water!=4: return false
	for key in ["watch_started","watch_supplies"]:
		if not record.get(key,false) is bool: return false
	if record.get("watch_choice","") not in ["","neutral","clan"]: return false
	if record.get("watch_started",false) and record.get("water_choice","")=="": return false
	if record.get("watch_choice","")!="":
		if not record.get("watch_started",false): return false
		var wild: Variant=value.get("wilderness",{})
		if not valid_wilderness(wild) or "wild_11" not in wild.looted: return false
	if record.get("watch_choice","")=="clan" and value.get("mountain",{}).get("clan","")=="": return false
	if record.get("watch_supplies",false) and record.get("watch_choice","")=="": return false
	if record.reward != "":
		if not record.accepted: return false
		var wild: Variant = value.get("wilderness", {})
		if not valid_wilderness(wild): return false
		for id in ["wild_6", "wild_7", "wild_8", "wild_11"]:
			if id not in wild.looted: return false
	return true

func valid_frost_hunt(value: Dictionary) -> bool:
	var record: Variant=value.get("frost_hunt",{"accepted":false,"rewarded":false})
	if not record is Dictionary or not record.get("accepted") is bool or not record.get("rewarded") is bool: return false
	if record.rewarded:
		var wild: Variant=value.get("wilderness",{})
		if not record.accepted or not valid_wilderness(wild) or "wild_12" not in wild.looted: return false
	return true
