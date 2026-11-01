extends Node3D
## The first playable main chapter: ward puzzles and a watchstone revelation.
const Blocks = preload("res://scripts/blocks.gd")
const State = preload("res://scripts/character_state.gd")
const Visual = preload("res://scripts/character_visual.gd")
const KEEPER := Vector3(-5, 0, -28)
const RELIC := Vector3(31, 0, -33)
const WARDS := [
	{"id": "hearth", "name": "Hearth Ward", "position": Vector3(-19, 0, 9), "answer": "Hearth", "clue": "I keep the winter from the door. No crown commands me, yet every traveler seeks me."},
	{"id": "tide", "name": "Crossing Ward", "position": Vector3(8, 0, -17), "answer": "Tide", "clue": "I wear away the oldest stone. I leave, return, and carry every shore within me."},
	{"id": "sky", "name": "High Ward", "position": Vector3(27, 0, -24), "answer": "Sky", "clue": "No road can bind me. Above the mountain and the sail, I hold the lights that guide you."}
]
var world: Node3D
var state: RefCounted
var dialog: ColorRect
var title: Label
var text: Label
var action: Button
var choices: Array[Button] = []
var subject := ""
var lights: Dictionary = {}
var visions: Node3D
var preview_label: Label

func _ready() -> void:
	state = world.player.character
	_build()
	_ui()
	state.changed.connect(_refresh_world)
	_refresh_world()

func _build() -> void:
	var rig := Visual.new()
	rig.position = KEEPER
	rig.rotation.y = PI
	add_child(rig)
	var model := State.new()
	for slot in ["head", "chest", "hands", "legs", "feet"]: model.equip(model.add_item("cloth_" + slot), slot)
	model.equip(model.add_item("iron_staff"), "main_hand")
	rig.build(model)
	world._craft_sign(KEEPER + Vector3.UP * 0.6, "Ilyra · Watchstone Keeper", Color("a7d3df"))
	var b := Blocks.new()
	var blue: StandardMaterial3D = b.materials.window.duplicate()
	blue.albedo_color = Color("8addeb")
	blue.emission = Color("63cfe6")
	b.materials.blue_rune = blue
	for ward: Dictionary in WARDS:
		var p: Vector3 = ward.position
		for tier in range(4):
			b.add("stone", p + Vector3(0, 0.1 + tier * 0.18, 0), Vector3(1.5 - tier * 0.2, 0.18, 1.5 - tier * 0.2))
		for tier in range(7): b.add("stone_dark", p + Vector3(0, 0.8 + tier * 0.15, 0), Vector3(0.55 - tier * 0.04, 0.15, 0.5))
		for i in range(3): b.add("gold", p + Vector3(0, 0.9 + i * 0.23, 0.27), Vector3(0.15, 0.07, 0.04))
		world._solid(p + Vector3(0, 0.85, 0), Vector3(0.7, 1.7, 0.7))
		var light := OmniLight3D.new()
		light.position = p + Vector3.UP * 2.0
		light.light_color = Color("8bdae9")
		light.omni_range = 6
		add_child(light)
		lights[ward.id] = light
		var rune := MeshInstance3D.new()
		var mesh := BoxMesh.new(); mesh.size = Vector3(0.18, 0.18, 0.18)
		rune.mesh = mesh
		rune.material_override = b.materials.blue_rune
		rune.position = p + Vector3.UP * 1.9
		add_child(rune)
		lights[ward.id + "_rune"] = rune
		world._craft_sign(p + Vector3.UP * 0.5, ward.name, Color("a7cbd2"))
	b.finish(self)
	# Three small echoes foreshadow destinations without opening their gates.
	visions = Node3D.new()
	visions.position = RELIC
	add_child(visions)
	var echo := Blocks.new()
	echo.materials.blue_rune = blue
	var red: StandardMaterial3D = blue.duplicate()
	red.albedo_color = Color("ff8558"); red.emission = Color("ff6633")
	echo.materials.red_rune = red
	for x in [-2.0, 0.0, 2.0]:
		for i in range(12):
			var angle := i * TAU / 12
			echo.add("gold", Vector3(x + cos(angle) * 0.6, 2.7 + sin(angle) * 0.8, 0.2), Vector3(0.09, 0.12, 0.09))
	for i in range(5):
		echo.add("iron", Vector3(-2, 2.5 + i * 0.09, 0.2), Vector3(0.6 - i * 0.07, 0.08, 0.32))
		echo.add("blue_rune", Vector3(0, 2.35 + i * 0.15, 0.2), Vector3(0.25 - i * 0.035, 0.14, 0.25 - i * 0.035))
		echo.add("coal", Vector3(1.7, 2.25 + i * 0.16, 0.2), Vector3(0.14, 0.16, 0.2))
		echo.add("coal", Vector3(2.3, 2.25 + i * 0.16, 0.2), Vector3(0.14, 0.16, 0.2))
	echo.add("red_rune", Vector3(2, 2.6, 0.2), Vector3(0.35, 0.45, 0.12))
	echo.finish(visions)

func _ui() -> void:
	var layer := CanvasLayer.new(); layer.layer = 5
	add_child(layer)
	preview_label = Label.new()
	preview_label.position = Vector2(32, 76)
	preview_label.text = "STONEWAKE PREVIEW · after Oldwatch · progress is not saved"
	preview_label.add_theme_color_override("font_color", Color("e8ba7b"))
	layer.add_child(preview_label)
	dialog = ColorRect.new()
	dialog.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dialog.color = Color(0.025, 0.04, 0.05, 0.96)
	layer.add_child(dialog)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dialog.add_child(center)
	var column := VBoxContainer.new()
	column.custom_minimum_size.x = 680
	column.add_theme_constant_override("separation", 18)
	center.add_child(column)
	title = Label.new(); title.add_theme_font_size_override("font_size", 27)
	column.add_child(title)
	text = Label.new()
	text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text.custom_minimum_size = Vector2(680, 240)
	text.add_theme_font_size_override("font_size", 19)
	column.add_child(text)
	for rune: String in ["Hearth", "Tide", "Sky"]:
		var button := Button.new(); button.text = "Invoke " + rune
		button.custom_minimum_size.y = 40
		button.pressed.connect(func(): choose_rune(rune))
		column.add_child(button); choices.append(button)
	action = Button.new(); action.custom_minimum_size.y = 44
	action.pressed.connect(_action)
	column.add_child(action)
	var close := Button.new(); close.text = "Return  [ Esc ]"; close.custom_minimum_size.y = 40
	close.pressed.connect(func(): close_dialog(); world.player.set_paused(false))
	column.add_child(close)
	dialog.hide()

func _refresh_world() -> void:
	for ward: Dictionary in WARDS:
		var restored: bool = ward.id in state.stonewake.wards
		lights[ward.id].light_energy = 2.5 if restored else 0.0
		lights[ward.id + "_rune"].visible = restored
	visions.visible = state.stonewake.awakened

func available() -> bool:
	return (not is_instance_valid(world.seal) or not world.seal.inside) and (not is_instance_valid(world.winter) or not world.winter.inside) and (not is_instance_valid(world.threshold) or not world.threshold.inside) and (not is_instance_valid(world.convergence) or not world.convergence.inside) and (not is_instance_valid(world.choir) or not world.choir.inside) and (not is_instance_valid(world.roots) or not world.roots.inside) and (not is_instance_valid(world.lens) or not world.lens.inside) and (not is_instance_valid(world.shore) or not world.shore.inside) and (not is_instance_valid(world.archive_chapter) or not world.archive_chapter.inside) and not world.adventure.inside and not world.realms.inside and (not is_instance_valid(world.mountain) or not world.mountain.inside)
func ward_by_id(id: String) -> Dictionary:
	for ward: Dictionary in WARDS:
		if ward.id == id: return ward
	return {}
func nearest() -> Dictionary:
	if not available(): return {}
	var p: Vector3 = world.player.position
	if p.distance_to(KEEPER) < 2.3: return {"kind": "story", "id": "keeper", "text": "[ E ] Speak with Ilyra"}
	if not state.stonewake.accepted or state.stonewake.rewarded: return {}
	for ward: Dictionary in WARDS:
		if p.distance_to(ward.position) < 2.5: return {"kind": "story", "id": ward.id, "text": "[ E ] " + ward.name + (" · restored" if ward.id in state.stonewake.wards else " · decipher inscription")}
	if p.distance_to(RELIC) < 3: return {"kind": "story", "id": "relic", "text": "[ E ] Awaken the watchstone"}
	return {}
func interact(id: String) -> void:
	if world.player.paused or nearest().get("id", "") != id: return
	if id == "relic":
		world.inspect_atlas_site("inspect_relic")
		if state.stonewake.wards.size() == 3 and not state.stonewake.awakened:
			state.stonewake.awakened = true
			state._commit()
	_open(id)
func _open(id: String) -> void:
	subject = id
	world.player.character_menu_open = false; world.player.map_open = false; world.player.workshop_open = false
	world.player.dialog_open = true; world.player.set_paused(true)
	dialog.show()
	for button in choices: button.hide()
	action.show(); action.disabled = true
	if id == "keeper":
		title.text = "ILYRA · WATCHSTONE KEEPER"
		if state.stonewake.rewarded:
			text.text = "STONEWAKE COMPLETE\n\nThe watchstone remembers three roads: iron beneath strange stars, crystal above the clouds, and a furnace behind a broken seal. The furnace is a warning for a much later age.\n\nWe need the mountain council, the missing atlas, and the woodland account before any expedition. The north pass beyond Ember Hall now leads to the Wyrmkeep council. The archive and woodland chapters are still ahead. Keep the pendant; make its old magic your own."
			action.text = "Main chapter completed"
		elif state.stonewake.awakened:
			text.text = "You saw them too. Those are other worlds, not places on our map. The oldest route points toward the stars. The crystal realm follows it; the furnace must stay sealed.\n\nTake this Watchkeeper's Pendant, 100 gold, six rune dust and three crystals. Let the pendant remind you: we travel to protect this home."
			action.text = "Report the echoes · Claim Stonewake reward"; action.disabled = false
		elif state.stonewake.accepted:
			text.text = "The ember woke three wards: one by the southern woods, one at the west bank, and one below the Watcher's Stones. Read each inscription and invoke what it describes.\n\nWhen all three burn blue, touch the central watchstone. Return and tell me what answers.\n\n" + objective()
			action.text = "Follow the ward markers on M / Frostmere area"
		elif state.adventure.rewarded:
			text.text = "STONEWAKE\n\nWhen Edda relit the forge, the old watchstone answered. That ember once fed an entire network. Something beyond our valley is pulling at it.\n\nWill you restore the three ward stones and listen? Their inscriptions name the rune each needs. The ember's resonance is already with you; no crafting materials are consumed."
			action.text = "Accept Stonewake"; action.disabled = false
		else:
			text.text = "The watchstone has been silent since our forge ember was taken. Edda needs someone to recover it from Oldwatch Barrow.\n\nReturn the ember to her first, then come back to me. We may learn why the old network went dark."
			action.text = "First complete Edda's barrow quest"
	elif id == "relic":
		title.text = "THE WATCHSTONE · THREE ECHOES"
		text.text = "Three blue wards answer the ember. Above the stone, three fragments gather:\n\nIRON: a station hanging beneath unfamiliar stars.\nLIGHT: ivory towers and crystals floating above the clouds.\nASH: a distant furnace behind a seal that has not yet broken.\n\nThese are memories of roads, not open gates. Return to Ilyra with what you have seen." if state.stonewake.awakened else "The stone answers faintly. Restore all three wards before it can show you the old roads.\n\n" + objective()
		action.text = "Report to Ilyra" if state.stonewake.awakened else "The wards must be restored"
	else:
		var ward := ward_by_id(id)
		title.text = ward.name.to_upper()
		text.text = "An inscription circles three runes:\n\n“" + ward.clue + "”\n\nChoose the rune named by the inscription."
		action.hide()
		if id in state.stonewake.wards:
			text.text += "\n\nThis ward is already restored. Its blue light holds steady."
		else:
			for button in choices: button.show()
func _action() -> void:
	if not dialog.visible or subject != "keeper" or not available() or world.player.position.distance_to(KEEPER) >= 2.3: return
	if state.stonewake.awakened: reward()
	else: accept()
	_open("keeper")
func accept() -> bool:
	if not state.adventure.rewarded or state.stonewake.accepted: return false
	state.stonewake.accepted = true; state._commit()
	world.hud.world_map.selected_quest = "stonewake"
	world.hud.world_map.set_view(true)
	world.hud.world_map.tabs.current_tab = 2
	return true
func choose_rune(rune: String) -> bool:
	var ward := ward_by_id(subject)
	if not dialog.visible or ward.is_empty() or not available() or not state.stonewake.accepted or state.stonewake.rewarded or subject in state.stonewake.wards or world.player.position.distance_to(ward.position) >= 2.5: return false
	if rune != ward.answer:
		text.text = "The rune fades. Nothing is consumed. Listen to the inscription again:\n\n“" + ward.clue + "”"
		return false
	state.stonewake.wards.append(subject); state._commit()
	for button in choices: button.hide()
	text.text = "The " + rune + " rune catches blue fire. The ward joins the old network.\n\n" + objective()
	return true
func reward() -> bool:
	if not state.stonewake.accepted or not state.stonewake.awakened or state.stonewake.rewarded: return false
	state.stonewake.rewarded = true
	if "stonewake" not in state.story_completed: state.story_completed.append("stonewake")
	var uid: String = state.add_item("resolve_amulet", 0, "insight")
	state.inventory[uid].custom_name = "Watchkeeper's Pendant"
	state.inventory[uid].favorite = true
	state.gold += 100
	for id: String in {"rune_dust": 6, "crystal": 3}: state.materials[id] = int(state.materials.get(id, 0)) + (6 if id == "rune_dust" else 3)
	state._commit()
	return true
func objective() -> String:
	if state.stonewake.rewarded: return "Stonewake complete · Take the north pass to Wyrmkeep for the Divided Council."
	if state.stonewake.awakened: return "Report the three echoes to Ilyra"
	if state.stonewake.accepted:
		for ward: Dictionary in WARDS:
			if ward.id not in state.stonewake.wards: return "Restore " + ward.name + " · %d / 3 wards" % state.stonewake.wards.size()
		return "Awaken the central watchstone"
	return "Speak with Ilyra near the northern village house" if state.adventure.rewarded else "Return Oldwatch's ember to Edda first"
func target() -> Vector3:
	if not state.stonewake.accepted or state.stonewake.awakened: return KEEPER
	for ward: Dictionary in WARDS:
		if ward.id not in state.stonewake.wards: return ward.position
	return RELIC
func close_dialog() -> void:
	dialog.hide(); world.player.dialog_open = false
func _process(_delta: float) -> void:
	preview_label.visible = "--story-preview" in OS.get_cmdline_user_args() and not world.player.paused
