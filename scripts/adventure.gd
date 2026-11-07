extends Node3D
const Blocks = preload("res://scripts/blocks.gd")
const State = preload("res://scripts/character_state.gd")
const Visual = preload("res://scripts/character_visual.gd")
const Enemy = preload("res://scripts/enemy.gd")
const Projectile = preload("res://scripts/projectile.gd")
const SMITH := Vector3(-3, 0, -7.5)
const ENTRANCE := Vector3(35, 0, -35)
const EXIT := Vector3(0, -30, 9)
var world: Node3D
var state: RefCounted
var inside := false
var dungeon: Node3D
var enemies: Array[CharacterBody3D] = []
var chests: Dictionary = {}
var b := Blocks.new()
var feedback := ""
var feedback_time := 0.0
var dialog: ColorRect
var dialog_text: Label
var dialog_action: Button
var combat_label: Label
var saved_environment: Dictionary = {}

func _ready() -> void:
	state = world.player.character
	_build_dungeon()
	_build_smith()
	_build_ui()
	var portal := Node3D.new()
	portal.position = ENTRANCE
	add_child(portal)
	b.piece(portal, "coal", Vector3(0, 1.1, 0), Vector3(1.7, 2.2, 0.2))
	for x in [-1.05, 1.05]:
		b.piece(portal, "stone_dark", Vector3(x, 1.25, 0), Vector3(0.4, 2.5, 0.6))
	b.piece(portal, "stone", Vector3(0, 2.5, 0), Vector3(2.5, 0.4, 0.6))
	world._craft_sign(ENTRANCE + Vector3.UP, "Oldwatch Barrow · E to descend", Color("d6bd80"))

func _solid(pos: Vector3, size: Vector3) -> void:
	var body := StaticBody3D.new()
	body.position = pos
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	collision.shape = shape
	body.add_child(collision)
	dungeon.add_child(body)

func _build_dungeon() -> void:
	dungeon = Node3D.new()
	dungeon.position = Vector3(0, -30, 0)
	add_child(dungeon)
	_solid(Vector3(0, -0.5, -20), Vector3(20, 1, 64))
	_solid(Vector3(0, 5.5, -20), Vector3(20, 1, 64))
	for x in [-10.0, 10.0]:
		_solid(Vector3(x, 2.5, -20), Vector3(1, 5, 64))
	for z in [-52.0, 12.0]:
		_solid(Vector3(0, 2.5, z), Vector3(20, 5, 1))
	for z in range(-52, 13):
		for x in range(-10, 11):
			b.add("stone_dark" if (x + z) % 3 else "stone", Vector3(x, -0.13, z), Vector3(0.97, 0.25, 0.97))
			b.add("stone_dark", Vector3(x, 5.05, z), Vector3(1, 0.3, 1))
		for x in [-10, 10]:
			for y in range(10):
				b.add("stone_dark" if y % 3 else "stone", Vector3(x, 0.25 + y * 0.5, z), Vector3(0.6, 0.48, 0.98))
	for z in [-52, 12]:
		b.add("stone_dark", Vector3(0, 2.5, z), Vector3(20, 5, 0.6))
	for z in [-10, -30]:
		for x in [-6.25, 6.25]:
			_solid(Vector3(x, 2.5, z), Vector3(7.5, 5, 1))
			b.add("stone_dark", Vector3(x, 2.5, z), Vector3(7.5, 5, 1))
		b.add("stone", Vector3(0, 4.2, z), Vector3(5, 1.6, 1.1))
		_solid(Vector3(0, 4.2, z), Vector3(5, 1.6, 1.1))
		for x in [-2.7, 2.7]:
			for y in range(7):
				b.add("stone", Vector3(x, 0.25 + y * 0.5, z), Vector3(0.55, 0.48, 1.3))
	# Offset pillars hide treasure while leaving broad routes for combat.
	for z in [1, -20, -42]:
		for x in [-6, 6]:
			_solid(Vector3(x, 2.5, z), Vector3(1.4, 5, 1.4))
			for y in range(10):
				b.add("stone", Vector3(x, y * 0.5 + 0.25, z), Vector3(1.4, 0.47, 1.4))
			b.add("gold", Vector3(x, 3.9, z), Vector3(1.46, 0.14, 1.46))
	for z in [7, -5, -17, -26, -37, -48]:
		for x in [-8.7, 8.7]:
			b.add("iron", Vector3(x, 1.0, z), Vector3(0.35, 2, 0.35))
			b.add("window", Vector3(x, 2.15, z), Vector3(0.32, 0.45, 0.32))
			var light := OmniLight3D.new()
			light.position = Vector3(x, 2.5, z)
			light.light_color = Color("ffbd7c")
			light.light_energy = 2.3
			light.omni_range = 13
			dungeon.add_child(light)
	b.add("gold", Vector3(0, 0.03, -45), Vector3(4, 0.05, 4))
	b.add("stone_dark", Vector3(0, 0.1, -45), Vector3(3.6, 0.1, 3.6))
	b.finish(dungeon)
	for record in [
		["guard_1", "guard", "Barrow Guard", Vector3(-1, 0.05, -2)],
		["archer_1", "archer", "Ashbow Sentry", Vector3(4, 0.05, -7)],
		["mage_1", "mage", "Ember Acolyte", Vector3(-3, 0.05, -20)],
		["guard_2", "guard", "Barrow Guard", Vector3(2, 0.05, -23)],
		["archer_2", "archer", "Ashbow Sentry", Vector3(-5, 0.05, -38)],
		["mage_2", "mage", "Ember Acolyte", Vector3(5, 0.05, -39)],
		["captain", "boss", "The Watch-Captain", Vector3(0, 0.05, -45)]]:
		var enemy := Enemy.new()
		enemy.adventure = self
		enemy.enemy_id = record[0]
		enemy.role = record[1]
		enemy.title = record[2]
		enemy.position = record[3]
		dungeon.add_child(enemy)
		enemies.append(enemy)
	for record in [["alcove", Vector3(-8, 0, -7)], ["vault", Vector3(8, 0, -48)]]:
		var chest := Node3D.new()
		chest.position = record[1]
		dungeon.add_child(chest)
		b.piece(chest, "wood", Vector3(0, 0.35, 0), Vector3(1.1, 0.7, 0.7))
		for x in [-0.4, 0.4]:
			b.piece(chest, "gold", Vector3(x, 0.37, 0), Vector3(0.1, 0.76, 0.76))
		chests[record[0]] = chest
		chest.scale.y = 0.3 if record[0] in state.adventure.chests else 1.0
	b.piece(dungeon, "wood", Vector3(0, 1.3, 11.6), Vector3(2, 2.6, 0.12))
	for x in [-0.8, 0.8]:
		b.piece(dungeon, "iron", Vector3(x, 1.3, 11.5), Vector3(0.1, 2.6, 0.08))

func _build_smith() -> void:
	var smith := Visual.new()
	smith.position = SMITH
	smith.rotation.y = PI / 2
	add_child(smith)
	var model := State.new()
	model.origin_id = "stoneborn"
	for slot: String in model.equipment:
		model.equipment[slot] = ""
	for slot in ["chest", "hands", "legs", "feet"]:
		model.equip(model.add_item("leather_" + slot), slot)
	model.equip(model.add_item("iron_mace"), "main_hand")
	smith.build(model)
	world._craft_sign(SMITH + Vector3.UP * 0.6, "Edda · Village Smith", Color("dec995"))

func nearest() -> Dictionary:
	var pos: Vector3 = world.player.global_position
	if not inside:
		if pos.distance_to(SMITH) < 2.3:
			return {"kind": "adventure", "id": "smith", "text": "[ E ] Speak with Edda"}
		if pos.distance_to(ENTRANCE) < 2.8:
			return {"kind": "adventure", "id": "enter", "text": "[ E ] Descend into Oldwatch Barrow"}
		return {}
	if pos.distance_to(EXIT) < 3:
		return {"kind": "adventure", "id": "leave", "text": "[ E ] Return to the Watcher's Stones"}
	var found := {}
	var distance := 2.8
	for enemy: CharacterBody3D in enemies:
		var d := pos.distance_to(enemy.global_position)
		if enemy.dead and enemy.enemy_id not in state.adventure.looted and d < distance:
			distance = d
			found = {"kind": "adventure", "id": enemy.enemy_id, "text": "[ E ] Loot " + enemy.title}
	for id: String in chests:
		var d := pos.distance_to(chests[id].global_position)
		if id not in state.adventure.chests and d < distance:
			distance = d
			found = {"kind": "adventure", "id": id, "text": "[ E ] Open hidden supply chest"}
	return found

func interact(id: String) -> void:
	var available := nearest()
	if world.player.paused or available.get("id", "") != id:
		return
	match id:
		"smith": open_dialog()
		"enter": enter()
		"leave": leave()
		"alcove", "vault": loot_chest(id)
		_: loot_enemy(id)

func enter() -> void:
	if world.player.paused:
		return
	inside = true
	world.player.invulnerable = 2.0
	world.player.position = EXIT + Vector3(0, 0.1, -3)
	world.player.velocity = Vector3.ZERO
	world.player.rotation = Vector3.ZERO
	world.player.pivot.rotation.x = -0.08
	for child in world.get_children():
		if child is WorldEnvironment:
			var env: Environment = child.environment
			saved_environment = {"ambient": env.ambient_light_energy, "fog": env.fog_enabled}
			env.ambient_light_energy = 0.19
			env.fog_enabled = false
	world.hud.announce("Oldwatch Barrow", world.controls.format_prompt("LMB attack · RMB hold block · Q Emberbolt · F healing potion\nRaise guard just before a melee hit to parry and stagger."))

func leave() -> void:
	inside = false
	clear_projectiles()
	world.player.position = ENTRANCE + Vector3(0, 0.15, 2)
	world.player.velocity = Vector3.ZERO
	for enemy: CharacterBody3D in enemies:
		if not enemy.dead:
			enemy.global_position = enemy.home
			enemy.health = enemy.maximum_health
			enemy.windup = 0
			enemy._update_label()
	for child in world.get_children():
		if child is WorldEnvironment and not saved_environment.is_empty():
			child.environment.ambient_light_energy = saved_environment.ambient
			child.environment.fog_enabled = saved_environment.fog

func on_death() -> void:
	if is_instance_valid(world.realms) and world.realms.inside:
		world.realms.leave()
	leave()
	world.player.respawn()
	world.player.health = world.player.derived.health
	world.player.stamina = world.player.derived.stamina
	world.player.magicka = world.player.derived.magicka
	world.hud.announce("You awaken on the south trail", "Your collected gear is safe. Defeated enemies stay defeated; surviving enemies recover.")

func mark_defeated(id: String) -> void:
	if id not in state.adventure.defeated:
		state.adventure.defeated.append(id)
		state._commit()
	if id == "captain":
		world.hud.announce("The Watch-Captain has fallen", "Search his remains for Oldwatch Oath and the forge ember.")

func loot_enemy(id: String) -> bool:
	if id not in state.adventure.defeated or id in state.adventure.looted:
		return false
	state.adventure.looted.append(id)
	state.gold += 90 if id == "captain" else 12
	var title := "Iron ore, arrows and a healing draught"
	if id == "captain":
		var uid: String = state.add_item("oldwatch_oath", 2, "vigor")
		state.inventory[uid].favorite = true
		grant_materials({"ember_core": 3, "steel_ingot": 3, "rune_dust": 4})
		title = "Oldwatch Oath · Superior of Vigor (favorited), rare materials and the forge ember"
	else:
		grant_materials({"iron_ore": 2, "arrow": 6, "rune_dust": 1})
		state.consumables.healing_draught = int(state.consumables.get("healing_draught", 0)) + 1
		if id == "mage_1":
			state.add_item("might_ring", 0, "insight")
		if id == "archer_2":
			state.add_item("steel_bow", 1, "fleet")
	state._commit()
	for enemy: CharacterBody3D in enemies:
		enemy._update_label()
	world.hud.announce("Recovered from the barrow", title)
	return true

func loot_chest(id: String) -> bool:
	if not chests.has(id) or id in state.adventure.chests:
		return false
	state.adventure.chests.append(id)
	state.gold += 30
	grant_materials({"crystal": 3, "rune_dust": 4, "arrow": 12, "ruby": 1} if id == "alcove" else {"ember_core": 2, "steel_ingot": 4, "sapphire": 1})
	state.add_item("steel_dagger" if id == "alcove" else "crystal_chest", 1, "fleet" if id == "alcove" else "resolve")
	state._commit()
	chests[id].scale.y = 0.3
	world.hud.announce("A hidden cache", "Enchanted gear, rare materials and a gem added to your bag.")
	return true

func grant_materials(materials: Dictionary) -> void:
	world.audio.sfx("loot")
	for id: String in materials:
		state.materials[id] = int(state.materials.get(id, 0)) + int(materials[id])

func accept_quest() -> bool:
	if state.adventure.accepted:
		return false
	state.adventure.accepted = true
	grant_materials({"arrow": 30})
	state.add_item("iron_bow")
	state.consumables.healing_draught = int(state.consumables.get("healing_draught", 0)) + 3
	state.consumables.magicka_draught = int(state.consumables.get("magicka_draught", 0)) + 2
	state._commit()
	world.atlas.set_waypoint("stones")
	return true

func reward_quest() -> bool:
	if not state.adventure.accepted or state.adventure.rewarded or "captain" not in state.adventure.looted:
		return false
	state.adventure.rewarded = true
	state.gold += 60
	if "oldwatch" not in state.blueprints:
		state.blueprints.append("oldwatch")
	if "steel" not in state.blueprints:
		state.blueprints.append("steel")
	grant_materials({"steel_ingot": 5, "ember_core": 2, "rune_dust": 6})
	state._commit()
	return true

func objective() -> String:
	if state.adventure.rewarded:
		return "Oldwatch restored · Recipe learned"
	if not state.adventure.accepted:
		return "Speak with Edda by the village forge"
	if "captain" in state.adventure.looted:
		return "Return the forge ember to Edda"
	if "captain" in state.adventure.defeated:
		return "Search the Watch-Captain's remains"
	return "Defeat the Watch-Captain beneath Oldwatch" if inside else "Enter Oldwatch Barrow beyond the Watcher's Stones"

func target() -> Vector3:
	if not state.adventure.accepted or "captain" in state.adventure.looted:
		return EXIT if inside else SMITH
	if inside:
		for enemy: CharacterBody3D in enemies:
			if enemy.enemy_id == "captain":
				return enemy.global_position
	return ENTRANCE

func line_clear(from: Vector3, to: Vector3, source: CollisionObject3D, target_body: CollisionObject3D = null) -> bool:
	var query := PhysicsRayQueryParameters3D.create(from, to, 1 | 2 | 4)
	query.exclude = [source.get_rid()]
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	return hit.is_empty() or hit.collider == target_body

func fire(origin: Vector3, direction: Vector3, damage: float, hostile: bool, source: CollisionObject3D, magic: bool, tint: Color = Color.TRANSPARENT, chain: int = 0, pierces: int = 0) -> void:
	if hostile: world.audio.sfx("spell" if magic else "bow")
	var bolt := Projectile.new()
	bolt.adventure = self
	bolt.position = origin
	bolt.direction = direction
	bolt.damage = damage
	bolt.hostile = hostile
	bolt.shooter = source
	bolt.magic = magic
	bolt.tint = tint
	bolt.chain = chain
	bolt.pierces = pierces
	bolt.speed = 13.0 if hostile and magic else 18.0 if hostile else 25.0 if magic else 34.0
	add_child(bolt)

func clear_projectiles() -> void:
	for child in get_children():
		if child is Projectile:
			child.queue_free()

func _build_ui() -> void:
	var canvas := CanvasLayer.new()
	canvas.layer = 4
	add_child(canvas)
	combat_label = Label.new()
	combat_label.position = Vector2(400, 75)
	combat_label.size = Vector2(480, 55)
	combat_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	combat_label.add_theme_font_size_override("font_size", 15)
	canvas.add_child(combat_label)
	dialog = ColorRect.new()
	dialog.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dialog.color = Color(0.025, 0.04, 0.05, 0.96)
	canvas.add_child(dialog)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dialog.add_child(center)
	var column := VBoxContainer.new()
	column.custom_minimum_size.x = 660
	column.add_theme_constant_override("separation", 24)
	center.add_child(column)
	var title := Label.new()
	title.text = "EDDA · THE VILLAGE SMITH"
	title.add_theme_font_size_override("font_size", 27)
	column.add_child(title)
	dialog_text = Label.new()
	dialog_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dialog_text.custom_minimum_size = Vector2(660, 230)
	dialog_text.add_theme_font_size_override("font_size", 20)
	column.add_child(dialog_text)
	dialog_action = Button.new()
	dialog_action.custom_minimum_size.y = 45
	dialog_action.pressed.connect(_dialog_action)
	column.add_child(dialog_action)
	var close_button := Button.new()
	close_button.text = "Return to the village  [ Esc ]"
	close_button.custom_minimum_size.y = 42
	close_button.pressed.connect(func(): close_dialog(); world.player.set_paused(false))
	column.add_child(close_button)
	dialog.visible = false

func open_dialog() -> void:
	world.player.character_menu_open = false
	world.player.workshop_open = false
	world.player.map_open = false
	world.player.dialog_open = true
	world.player.set_paused(true)
	dialog.visible = true
	if state.adventure.rewarded:
		dialog_text.text = "That ember is burning in our forge again. Oldwatch Oath's design is yours now.\n\nUse the forge to make another, or improve the blade you recovered. There is strength worth keeping in old things. Except my knees. Those are mostly weather reports. Ilyra, the watchstone keeper beside the northern village house, heard the stones answer when we relit the forge. Speak with her next."
		dialog_action.text = "Quest complete · Oldwatch recipe learned"
		dialog_action.disabled = true
	elif "captain" in state.adventure.looted and state.adventure.accepted:
		dialog_text.text = "You brought it back. And that blade… Oldwatch Oath. The Captain has finally let it go.\n\nI can teach you its pattern. Take these ingots and embers, too. Make that sword your own. Preferably before it develops another opinion about its owner."
		dialog_action.text = "Return forge ember · Learn recipe and claim materials"
		dialog_action.disabled = false
	elif state.adventure.accepted:
		dialog_text.text = world.controls.format_prompt("Cross the stone bridge and follow the path to the Watcher's Stones. The barrow entrance stands just southeast of the relic.\n\nThe Captain waits in the deepest chamber. If he offers you a permanent position, decline. Search his remains for our forge ember, then return to me.\n\nLMB: attack or fire bow · RMB: hold block\nQ: Emberbolt · F: healing potion · I: supplies")
		dialog_action.text = "Expedition supplies already received"
		dialog_action.disabled = true
	else:
		dialog_text.text = "AN EMBER BENEATH OLDWATCH\n\nWarm stones on the road? Keep away from them. Nothing under this valley should be breathing.\n\nOur forge ember was taken into the old barrow. The dead keep stealing our heat. Apparently being cold forever wasn’t enough. The Watch-Captain and his sentries still guard it. Bring it home, and I'll teach you a lost forging pattern.\n\nTake a bow, 30 arrows, three healing draughts and two magicka draughts. Watch for raised weapons; block or step away before they strike."
		dialog_action.text = "Accept Edda's quest and expedition supplies"
		dialog_action.disabled = false

func _dialog_action() -> void:
	if not world.player.dialog_open or world.player.global_position.distance_to(SMITH) >= 2.3:
		return
	if state.adventure.accepted:
		reward_quest()
	else:
		accept_quest()
	open_dialog()

func close_dialog() -> void:
	dialog.visible = false
	world.player.dialog_open = false

func _process(delta: float) -> void:
	if not world.player.paused:
		feedback_time = maxf(0, feedback_time - delta)
	combat_label.visible = not world.player.paused
	combat_label.text = feedback if feedback_time > 0 else "BLOCKING" if world.player.blocking else ""
