extends Node3D
const Blocks = preload("res://scripts/blocks.gd")
const SUPPORT_KITS={"aeralis":{"arrows":36,"draughts":2},"crucible":{"arrows":48,"draughts":3}}
const Enemy = preload("res://scripts/enemy.gd")
var ending: Node
var world: Node3D
var state: RefCounted
var inside := false
var current := ""
var preview := false
var definitions: Dictionary = {}
var roots: Dictionary = {}
var atmospheres: Dictionary = {}
var enemies: Array[CharacterBody3D] = []
var feedback := ""
var feedback_time := 0.0
var environment_backup: Environment
var preview_label: Label

func _ready() -> void:
	state = world.player.character
	for entry: Dictionary in state.realm_data.realms:
		definitions[entry.id] = entry
		_build(entry)
		var p := vector(entry.portal)
		var b := Blocks.new()
		for i in range(10):
			var angle := float(i) / 9 * PI
			b.add("stone", p + Vector3(cos(angle) * 1.2, 0.5 + sin(angle) * 2.3, 0), Vector3(0.42, 0.42, 0.5))
		b.add("cloth" if entry.id == "aeralis" else "coal", p + Vector3(0, 1.1, 0), Vector3(1.4, 2.1, 0.12))
		b.finish(self)
		world._craft_sign(p + Vector3.UP * 1.0, entry.name + "\n" + entry.act, Color("c7c0dd"))
	var layer := CanvasLayer.new()
	layer.layer = 3
	add_child(layer)
	preview_label = Label.new()
	preview_label.position = Vector2(32, 76)
	preview_label.add_theme_font_size_override("font_size", 14)
	preview_label.add_theme_color_override("font_color", Color("e8ba7b"))
	layer.add_child(preview_label)

func vector(p: Array) -> Vector3:
	return Vector3(p[0], p[1], p[2])
func can_enter(id: String) -> bool:
	if not definitions.has(id): return false
	for requirement: String in definitions[id].requires:
		if requirement not in state.story_completed: return false
	return true
func _box(root: Node3D, b: RefCounted, material: String, pos: Vector3, size: Vector3, solid: bool = false) -> void:
	b.add(material, pos, size)
	if solid:
		_add_collision(root, pos, size)

func _add_collision(root: Node3D, pos: Vector3, size: Vector3) -> void:
	var body := StaticBody3D.new()
	body.position = pos
	var shape := BoxShape3D.new()
	shape.size = size
	var collider := CollisionShape3D.new()
	collider.shape = shape
	body.add_child(collider)
	root.add_child(body)

func _crystal(b: RefCounted, pos: Vector3, size: float, key: String) -> void:
	for i in range(10):
		var width := size * (1 - absf(float(i) - 4) / 7)
		b.add(key, pos + Vector3(0, i * size * 0.23, 0), Vector3(width, size * 0.25, width))
func _build(entry: Dictionary) -> void:
	var root := Node3D.new()
	root.position = vector(entry.origin)
	add_child(root)
	roots[entry.id] = root
	root.hide()
	var atmosphere := preload("res://scripts/realm_atmosphere.gd").new()
	root.add_child(atmosphere)
	atmosphere.configure(entry.id)
	atmospheres[entry.id] = atmosphere
	var b := Blocks.new()
	var light_mat: StandardMaterial3D = b.materials.window.duplicate()
	light_mat.albedo_color = Color("8ee7ee") if entry.id == "aeralis" else Color("ff723a")
	light_mat.emission = light_mat.albedo_color
	light_mat.emission_energy_multiplier = 1.3
	b.materials.realm_glow = light_mat
	var stone_mat: StandardMaterial3D = b.materials.stone.duplicate()
	stone_mat.albedo_color = Color("cecbdc") if entry.id == "aeralis" else Color("604e53")
	b.materials.realm_stone = stone_mat
	# Three terraces linked by actual narrow bridges with open edges.
	for z in [13, -9, -32]:
		var width := 25.0 if z == -32 else 21.0
		_box(root, b, "realm_stone", Vector3(0, -0.55, z), Vector3(width, 1.1, 17), true)
		for x in range(int(-width / 2), int(width / 2)):
			for dz in range(-8, 9):
				b.add("realm_stone" if (x + dz) % 4 else "stone", Vector3(x + 0.5, 0.02, z + dz), Vector3(0.97, 0.06, 0.97))
		for side in [-1, 1]:
			for dz in range(-7, 8, 2):
				_box(root, b, "gold" if entry.id == "aeralis" else "iron", Vector3(side * (width / 2 - 0.3), 0.6, z + dz), Vector3(0.25, 1.2, 0.25), true)
		if entry.id == "aeralis":
			for tier in range(10):
				b.add("stone_dark", Vector3(0, -1.1 - tier * 0.65, z), Vector3(width - tier * 1.8, 0.7, 16 - tier * 1.35))
		else:
			for side in [-1, 1]:
				_box(root, b, "coal", Vector3(side * (width / 2 + 0.8), 3.8, z), Vector3(1.5, 7.6, 16), true)
				for i in range(5):
					b.add("realm_glow", Vector3(side * (width / 2 - 0.01), 2, z - 6 + i * 3), Vector3(0.07, 1.6, 0.3))
	for z in [2, -20]:
		_box(root, b, "wood" if entry.id == "aeralis" else "iron", Vector3(0, -0.2, z), Vector3(4.4, 0.4, 7), true)
		for side in [-1, 1]:
			_box(root, b, "gold" if entry.id == "aeralis" else "iron", Vector3(side * 2.2, 0.65, z), Vector3(0.14, 1.3, 7), true)
	if entry.id == "aeralis":
		for pos in [Vector3(-7, 0, 10), Vector3(7, 0, -8), Vector3(-8, 0, -33), Vector3(8, 0, -33)]:
			_crystal(b, pos, 1.4, "realm_glow")
			# One core collider supports the base of the layered crystal.
			_add_collision(root, pos + Vector3.UP * .65, Vector3(1.1, 1.65, 1.1))
		# Layered arcades, blue banners and small tiled pavilions flank the path.
		for z in [9, -12, -34]:
			for side in [-1, 1]:
				var x: float = side * 8.5
				_box(root, b, "realm_stone", Vector3(x, 0.25, z), Vector3(3.4, 0.5, 4), true)
				for dx in [-1.2, 1.2]:
					for dz in [-1.5, 1.5]:
						_box(root, b, "realm_stone", Vector3(x + dx, 2.2, z + dz), Vector3(0.35, 4, 0.35), true)
						b.add("gold", Vector3(x + dx, 3.8, z + dz), Vector3(0.48, 0.2, 0.48))
				for tier in range(8):
					b.add("cloth", Vector3(x, 4.2 + tier * 0.22, z), Vector3(3.6 - tier * 0.4, 0.23, 4.2 - tier * 0.45))
				_crystal(b, Vector3(x, 6, z), 0.4, "realm_glow")
				b.add("cloth", Vector3(x - side * 1.2, 2.8, z), Vector3(0.08, 1.3, 0.65))
		# Distant suspended islands make the realm feel larger than its playable route.
		for i in range(9):
			var x: float = (-1 if i % 2 else 1) * (30 + i * 4)
			var z: float = -15 - i * 12
			var y: float = -8 + (i % 3) * 7
			for tier in range(12):
				b.add("stone_dark", Vector3(x, y - tier * 0.7, z), Vector3(13 - tier, 0.75, 10 - tier * 0.75))
			b.add("grass", Vector3(x, y + 0.4, z), Vector3(13, 0.2, 10))
			for tier in range(15):
				b.add("realm_stone", Vector3(x, y + 0.8 + tier * 0.65, z), Vector3(3 - tier * 0.12, 0.66, 3 - tier * 0.12))
			_crystal(b, Vector3(x, y + 10.5, z), 1.0, "realm_glow")
		# Tall ivory spires and a luminous arch frame the final terrace.
		for side in [-1, 1]:
			for i in range(18):
				b.add("realm_stone", Vector3(side * 9, i * 0.55, -38), Vector3(1.8 - i * 0.05, 0.53, 1.8 - i * 0.05))
			_crystal(b, Vector3(side * 9, 10, -38), 1.1, "realm_glow")
		for i in range(16):
			var angle := PI * i / 15.0
			b.add("gold", Vector3(cos(angle) * 7, 3 + sin(angle) * 6, -39), Vector3(0.55, 0.65, 0.45))
		# Moored voxel airship: tiered hull, cabin, mast and cloth sails.
		for tier in range(6):
			b.add("wood", Vector3(-18, 1.3 + tier * 0.3, 7), Vector3(2.2 + tier * 0.55, 0.29, 9 + tier * 0.85))
		b.add("gold", Vector3(-18, 3.15, 7), Vector3(5.5, 0.12, 14))
		b.add("timber", Vector3(-18, 6, 7), Vector3(0.22, 6.3, 0.22))
		for row in range(12):
			b.add("cloth", Vector3(-18 + sin(row * 0.23) * 0.25, 4.2 + row * 0.3, 7), Vector3(4.7 - absf(row - 5.5) * 0.23, 0.28, 0.08))
		for side in [-1, 1]: _crystal(b, Vector3(-18 + side * 3.2, 1.8, 8), 0.75, "realm_glow")
	else:
		# Lava below the platforms; pipes, crucibles and an iron cathedral skyline.
		_box(root, b, "realm_glow", Vector3(0, -4, -12), Vector3(80, 0.2, 100))
		for x in [-18, -14, 14, 18]:
			for z in [-10, -32]:
				b.add("coal", Vector3(x, 5, z), Vector3(2.5, 15, 2.5))
				b.add("iron", Vector3(x, 11, z), Vector3(3, 0.6, 3))
				_crystal(b, Vector3(x, 12, z), 0.8, "realm_glow")
		for x in [-6, 0, 6]:
			_box(root, b, "iron", Vector3(x, 6, -40), Vector3(1.3, 12, 1.2), true)
			b.add("realm_glow", Vector3(x, 6, -39.3), Vector3(0.25, 8, 0.12))
		for z in [-2, -24]: b.add("iron", Vector3(0, 6, z), Vector3(27, 0.8, 0.8))
	if entry.id=="aeralis": preload("res://scripts/landmark_architecture.gd").aeralis(b)
	else: preload("res://scripts/landmark_architecture.gd").crucible(b)
	# A crafting anvil and an attunement crystal at the arrival terrace.
	_box(root, b, "stone_dark", Vector3(6, 0.5, 16), Vector3(1.4, 1, 1), true)
	b.add("iron", Vector3(6, 1.1, 16), Vector3(1.65, 0.25, 0.8))
	_crystal(b, Vector3(-6, 0, 16), 0.8, "realm_glow")
	b.add("gold", Vector3(0, 0.08, 19), Vector3(3, 0.15, 2))
	_box(root, b, "realm_stone", Vector3(7, 0.5, 10), Vector3(1.4, 1, 1.2), true)
	_crystal(b, Vector3(7, 1.0, 10), 0.35, "realm_glow")
	b.finish(root)
	for name_and_pos in [["Return gate", Vector3(0, 2, 19)], ["Realm Forge", Vector3(6, 2.2, 16)], ["Enchantment altar", Vector3(7, 2.2, 10)], ["Attunement / supplies", Vector3(-6, 2.4, 16)]]:
		var label := Label3D.new()
		label.text = name_and_pos[0]
		label.position = name_and_pos[1]
		label.font_size = 20; label.pixel_size = 0.003
		label.visibility_range_begin = 4.5
		label.visibility_range_end = 22
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		root.add_child(label)
	var roles := ["guard", "mage", "boss"] if entry.id == "aeralis" else ["guard", "archer", "boss"]
	var ids := ["guard", "mage", "regent"] if entry.id == "aeralis" else ["guard", "gunner", "warden"]
	var titles := ["Prism Knight", "Starbound Adept", "Prismwing, the Fractured Wyrm"] if entry.id == "aeralis" else ["Cinder Legionnaire", "Furnace Gunner", "The Furnace Maw"]
	for i in range(3):
		var enemy = preload("res://scripts/crystal_wyrm.gd").new() if entry.id=="aeralis" and i==2 else preload("res://scripts/furnace_beast.gd").new() if entry.id=="crucible" and i==2 else Enemy.new()
		enemy.adventure = self
		enemy.progress = state.realm_progress
		enemy.enemy_id = entry.id + "_" + ids[i]
		enemy.role = roles[i]; enemy.title = titles[i]
		enemy.armor_override = entry.armor
		enemy.weapon_override = entry.weapon if i != 1 else "aether_staff" if entry.id == "aeralis" else "cinder_gun"
		enemy.origin_override = "grove_elf" if entry.id == "aeralis" else "orckin"
		enemy.health_override = (240 if i == 2 else 90) if entry.id == "aeralis" else (340 if i == 2 else 125)
		enemy.position = Vector3(-3 if i == 0 else 3 if i == 1 else 0, 0.05, -7 if i == 0 else -13 if i == 1 else -33)
		root.add_child(enemy)
		enemies.append(enemy)

func enter(id: String, as_preview: bool = false) -> bool:
	if world.player.paused or not definitions.has(id): return false
	if not as_preview and not can_enter(id): return false
	# Preview mode must never mutate a real persistent profile.
	if as_preview and state.persist: return false
	if is_instance_valid(world.mountain) and world.mountain.inside: world.mountain.leave()
	if is_instance_valid(world.seal) and world.seal.inside: world.seal.leave()
	if is_instance_valid(world.winter) and world.winter.inside: world.winter.leave()
	if is_instance_valid(world.threshold) and world.threshold.inside: world.threshold.leave()
	if is_instance_valid(world.convergence) and world.convergence.inside: world.convergence.leave()
	if is_instance_valid(world.choir) and world.choir.inside: world.choir.leave()
	if is_instance_valid(world.roots) and world.roots.inside: world.roots.leave()
	if is_instance_valid(world.lens) and world.lens.inside: world.lens.leave()
	if is_instance_valid(world.shore) and world.shore.inside: world.shore.leave()
	if is_instance_valid(world.archive_chapter) and world.archive_chapter.inside: world.archive_chapter.leave()
	if world.adventure.inside: world.adventure.leave()
	if inside: leave()
	preview = preview or as_preview
	current = id; inside = true
	roots[id].show()
	world.player.position = vector(definitions[id].origin) + Vector3(0, 0.15, 16)
	world.player.velocity = Vector3.ZERO
	world.player.rotation = Vector3.ZERO
	world.player.pivot.rotation.x = -0.10
	world.player.invulnerable = 3
	for child in world.get_children():
		if child is WorldEnvironment:
			environment_backup = child.environment
			var env: Environment = environment_backup.duplicate(true)
			env.background_mode = Environment.BG_COLOR
			env.background_color = Color("90accb") if id == "aeralis" else Color("28151c")
			env.fog_light_color = env.background_color
			env.fog_density = 0.005
			env.ambient_light_color = Color("bfd8ee") if id == "aeralis" else Color("d79b89")
			env.ambient_light_energy = 0.5 if id == "aeralis" else 0.36
			atmospheres[id].apply(env, id)
			child.environment = env
	world.hud.announce(definitions[id].name, definitions[id].story)
	return true
func preview_kit(id: String) -> void:
	if state.persist: return
	var info: Dictionary = definitions[id]
	attune(id)
	for slot in ["head", "chest", "hands", "legs", "feet"]: state.equip(state.add_item(info.armor + "_" + slot, 1), slot)
	state.equip(state.add_item(info.weapon, 1, info.enchant), "main_hand")
	state.materials.hell_round = 300
	state.materials.charcoal = 20
	state.consumables.healing_draught = 8
	state.consumables.magicka_draught = 8
	state._commit()
	world.player.health = world.player.derived.health
	world.player.magicka = world.player.derived.magicka
	world.player.stamina = world.player.derived.stamina
func leave() -> void:
	if not inside: return
	atmospheres[current].deactivate()
	roots[current].hide()
	world.adventure.clear_projectiles()
	for child in world.get_children():
		if child is WorldEnvironment and environment_backup != null: child.environment = environment_backup
	world.player.position = vector(definitions[current].portal) + Vector3(0, 0.15, 2.8)
	world.player.velocity = Vector3.ZERO
	inside = false
	for enemy: CharacterBody3D in enemies:
		if not enemy.dead:
			enemy.global_position = enemy.home
			enemy.velocity = Vector3.ZERO
			enemy.health = enemy.maximum_health; enemy.windup = 0
			enemy._update_label()
func nearest() -> Dictionary:
	if inside:
		var origin := vector(definitions[current].origin)
		var pos: Vector3 = world.player.position - origin
		if current=="crucible" and pos.distance_to(ending.CONTROL)<2.4: return {"kind":"realm","id":"shutdown","text":"[ E ] "+("Engine stopped" if state.finale.shutdown else "Shut down invasion engine")}
		for pair in [["leave", Vector3(0, 0, 19), "Return to Frostmere"], ["attune", Vector3(-6, 0, 16), "Attune / claim supplies"], ["forge", Vector3(6, 0, 16), "Use realm forge"], ["enchant", Vector3(7, 0, 10), "Enchant realm gear"]]:
			if pos.distance_to(pair[1]) < 2.4: return {"kind": "realm", "id": pair[0], "text": "[ E ] " + pair[2]}
		for enemy: CharacterBody3D in enemies:
			if enemy.enemy_id.begins_with(current) and enemy.dead and enemy.enemy_id not in state.realm_progress.looted and world.player.position.distance_to(enemy.global_position) < 2.8:
				return {"kind": "realm", "id": enemy.enemy_id, "text": "[ E ] Recover " + enemy.title + "'s relics"}
	else:
		if "last_furnace" in state.story_completed and world.player.position.distance_to(ending.HOME)<2.4: return {"kind":"realm","id":"chronicle","text":"[ E ] Read the Returning Light chronicle"}
		for id: String in definitions:
			if world.player.position.distance_to(vector(definitions[id].portal)) < 2.4:
				return {"kind": "realm", "id": id, "text": "[ E ] " + definitions[id].name + (" · sealed story gate" if not can_enter(id) and not preview else "")}
	return {}
func interact(id: String) -> void:
	if world.player.paused or nearest().get("id", "") != id: return
	if id=="chronicle": ending.open_chronicle()
	elif not inside:
		if not enter(id, preview):
			var names: Array[String] = []
			for requirement: String in definitions[id].requires: names.append(world.atlas.quests[requirement].name)
			world.hud.announce("A later chapter", "Requires " + ", ".join(names) + ".")
	elif id == "leave":
		var final_return: bool=current=="crucible" and (finish_chapter() or ("last_furnace" in state.story_completed and state.finale.reward==""))
		if current!="crucible": finish_chapter()
		leave()
		if final_return: ending.open_chronicle()
	elif id=="shutdown": ending.shutdown()
	elif id == "attune":
		world.hud.announce("Realm attunement", "Magic, blueprints, enchanted gear and materials collected. Traveler reserve: %d arrows and %d Magicka Draughts." % [SUPPORT_KITS[current].arrows,SUPPORT_KITS[current].draughts] if attune(current) else "Already attuned. Loot the guardians for more materials.")
	elif id in ["forge", "enchant"]: world.hud.workshop.open(id)
	else: loot(id)
func station_nearby() -> String:
	if not inside: return ""
	var p: Vector3 = world.player.position - vector(definitions[current].origin)
	if p.distance_to(Vector3(7, 0, 10)) < 2.4: return "enchant"
	if p.distance_to(Vector3(6, 0, 16)) < 2.4: return "forge"
	return ""
func attune(id: String) -> bool:
	if not definitions.has(id) or id in state.realm_progress.attuned: return false
	var info: Dictionary = definitions[id]
	state.realm_progress.attuned.append(id)
	if info.armor not in state.blueprints: state.blueprints.append(info.armor)
	if info.enchant not in state.formulas: state.formulas.append(info.enchant)
	if info.spell not in state.known_spells: state.known_spells.append(info.spell)
	state.active_spell = info.spell
	state.add_item(info.weapon, 1, info.enchant)
	for material: String in [info.material, info.alloy]: state.materials[material] = int(state.materials.get(material, 0)) + 16
	state.materials.arrow=int(state.materials.get("arrow",0))+int(SUPPORT_KITS[id].arrows)
	state.consumables.magicka_draught=int(state.consumables.get("magicka_draught",0))+int(SUPPORT_KITS[id].draughts)
	if id == "crucible": state.materials.hell_round = int(state.materials.get("hell_round", 0)) + 160
	state._commit()
	return true
func mark_defeated(id: String) -> void:
	if id not in state.realm_progress.defeated:
		state.realm_progress.defeated.append(id); state._commit()
func loot(id: String) -> bool:
	if id not in state.realm_progress.defeated or id in state.realm_progress.looted: return false
	state.realm_progress.looted.append(id)
	var realm: String = id.get_slice("_", 0)
	var info: Dictionary = definitions[realm]
	for material: String in [info.material, info.alloy]: state.materials[material] = int(state.materials.get(material, 0)) + 8
	state.gold += 60
	state.consumables.healing_draught = int(state.consumables.get("healing_draught", 0)) + 2
	if id.ends_with("regent") or id.ends_with("warden"):
		var uid: String = state.add_item("aether_greatsword" if realm == "aeralis" else "cinder_axe", 2, info.enchant)
		state.inventory[uid].favorite = true
	else: state.add_item(info.armor + "_chest", 1)
	state._commit()
	for enemy: CharacterBody3D in enemies: enemy._update_label()
	world.hud.announce("Realm relics recovered", "Gear and upgrade materials added to your bag. Return through the gate when ready.")
	return true
func finish_chapter() -> bool:
	if not inside or world.player.paused or world.player.position.distance_to(vector(definitions[current].origin)+Vector3(0,0,19))>=2.4: return false
	if current=="crucible" and not state.finale.shutdown: return false
	var boss := "aeralis_regent" if current == "aeralis" else "crucible_warden"
	if boss not in state.realm_progress.looted or current in state.realm_progress.completed: return false
	state.realm_progress.completed.append(current)
	var quest: String = definitions[current].quest
	if quest not in state.story_completed: state.story_completed.append(quest)
	state._commit()
	return true
func check_fall() -> void:
	var origin := vector(definitions[current].origin)
	if world.player.position.y < origin.y - 8 or absf(world.player.position.x - origin.x) > 65 or absf(world.player.position.z) > 80:
		world.player.position = origin + Vector3(0, 0.2, 16)
		world.player.velocity = Vector3.ZERO
		world.player.invulnerable = 0
		world.player.receive_damage(35, world.player.position + Vector3.BACK)
func fire(origin: Vector3, direction: Vector3, damage: float, hostile: bool, source: CollisionObject3D, magic: bool) -> void:
	world.adventure.fire(origin, direction, damage * (1.4 if current == "crucible" else 1.15), hostile, source, magic, Color("f58558") if current == "crucible" else Color("a5d6ef"))
func line_clear(from: Vector3, to: Vector3, source: CollisionObject3D, target_body: CollisionObject3D = null) -> bool:
	return world.adventure.line_clear(from, to, source, target_body)
func _process(delta: float) -> void:
	preview_label.visible = preview and not world.player.paused
	preview_label.text = "REALM PREVIEW · progress is not saved · B cycles learned spells"
	if feedback_time > 0:
		world.adventure.feedback = feedback
		world.adventure.feedback_time = feedback_time
		feedback_time = maxf(0, feedback_time - delta)

func objective() -> String:
	if current=="crucible" and "crucible_warden" in state.realm_progress.looted and not state.finale.shutdown: return "Clear all defenders, then use the shutdown console on the final terrace."
	var boss := "aeralis_regent" if current == "aeralis" else "crucible_warden"
	if boss in state.realm_progress.looted: return "Return through the arrival gate with the guardian relic."
	if boss in state.realm_progress.defeated: return "Recover the guardian's remains with E."
	if current not in state.realm_progress.attuned: return "Attune at the arrival crystal to learn realm magic and forging."
	return "Cross the terraces and defeat the guardian."
