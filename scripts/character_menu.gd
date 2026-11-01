extends ColorRect
const Visual = preload("res://scripts/character_visual.gd")
const INK := Color("e3ded0")
const GOLD := Color("bfaa78")
var player: CharacterBody3D
var state: RefCounted
var name_field: LineEdit
var origin_picker: OptionButton
var class_picker: OptionButton
var frame_picker: OptionButton
var points: Label
var attribute_labels: Dictionary = {}
var plus_buttons: Dictionary = {}
var minus_buttons: Dictionary = {}
var stats_label: Label
var summary: Label
var slot_list: ItemList
var item_list: ItemList
var search: LineEdit
var detail: Label
var status: Label
var equip_button: Button
var item_ids: Array[String] = []
var selected_slot := "chest"
var selected_item := ""
var preview: Node3D
var viewport: SubViewport
var refreshing := false
var loadout_picker: OptionButton
var loadout_name: LineEdit
var loadout_apply: Button
var loadout_detail: Label

func _ready() -> void:
	state = player.character
	color = Color(0.025, 0.043, 0.06, 0.98)
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 24)
	add_child(margin)
	var page := VBoxContainer.new()
	page.add_theme_constant_override("separation", 12)
	margin.add_child(page)
	var header := HBoxContainer.new()
	page.add_child(header)
	var title := _label(header, "CHARACTER  /  ARMORY", 23, INK)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_button(header, "Skills & perks [ K ]", func(): player.get_parent().skills_menu.open_menu())
	_button(header, "Return to world   [ C / Esc ]", close)
	_label(page, "Experiment with any ancestry, playstyle, and equipment. Equip owned gear; craft and improve items with I or at workstations.", 13, GOLD)
	var columns := HBoxContainer.new()
	columns.size_flags_vertical = Control.SIZE_EXPAND_FILL
	columns.add_theme_constant_override("separation", 20)
	page.add_child(columns)
	var left := _scroll_column(columns, 0.85)
	_label(left, "IDENTITY", 16, GOLD)
	name_field = LineEdit.new()
	name_field.max_length = 32
	name_field.placeholder_text = "Character name"
	left.add_child(name_field)
	name_field.text_submitted.connect(func(_text: String): _identity())
	name_field.focus_exited.connect(_identity)
	origin_picker = _picker(left, "Ancestry", state.catalog.origins)
	class_picker = _picker(left, "Starting playstyle", state.catalog.archetypes)
	frame_picker = _picker(left, "Body frame", [{"name": "Lean"}, {"name": "Balanced"}, {"name": "Broad"}])
	for picker in [origin_picker, class_picker, frame_picker]:
		picker.item_selected.connect(func(_index: int): _identity())
	var starter := _button(left, "Equip owned starter pieces", func(): state.apply_starter())
	starter.tooltip_text = "Equips matching pieces already in your bag. Does not grant items."
	_label(left, "Starting playstyles give bonuses, not equipment restrictions.", 12, INK).autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	points = _label(left, "", 16, GOLD)
	for attribute: String in state.catalog.attributes:
		var row := HBoxContainer.new()
		left.add_child(row)
		var label := _label(row, attribute.capitalize(), 14, INK)
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		minus_buttons[attribute] = _button(row, "−", func(): state.allocate(attribute, -1))
		attribute_labels[attribute] = _label(row, "10", 16, INK)
		attribute_labels[attribute].custom_minimum_size.x = 28
		plus_buttons[attribute] = _button(row, "+", func(): state.allocate(attribute, 1))
	_button(left, "Reset assigned points", func(): state.reset_points())
	_label(left, "DERIVED STATS", 16, GOLD)
	stats_label = _label(left, "", 14, INK)
	stats_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var center := VBoxContainer.new()
	center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center.size_flags_stretch_ratio = 0.95
	columns.add_child(center)
	summary = _label(center, "", 16, GOLD)
	summary.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_build_preview(center)
	var turn := HSlider.new()
	turn.min_value = -180
	turn.max_value = 180
	turn.value = 155
	turn.value_changed.connect(func(value: float): preview.rotation.y = deg_to_rad(value))
	center.add_child(turn)
	_label(center, "Rotate character preview", 12, INK).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label(center, "EQUIPMENT LOADOUTS", 16, GOLD)
	loadout_picker = OptionButton.new(); center.add_child(loadout_picker)
	for i in range(4): loadout_picker.add_item("Set %d" % (i + 1))
	loadout_picker.item_selected.connect(func(_index: int): _refresh_loadout(true))
	loadout_name = LineEdit.new(); loadout_name.max_length = 24; loadout_name.placeholder_text = "Name this set"; center.add_child(loadout_name)
	var loadout_actions := HBoxContainer.new(); center.add_child(loadout_actions)
	_button(loadout_actions, "Save current", func():
		if state.save_loadout(loadout_picker.selected, loadout_name.text): status.text = "Saved current equipment set."
		else: status.text = "Enter a name (up to 24 characters)."
	)
	loadout_apply = _button(loadout_actions, "Equip set", func():
		if state.apply_loadout(loadout_picker.selected): status.text = "Equipment set applied."
		else: status.text = state.last_error
	)
	_button(loadout_actions, "Delete set", func(): state.delete_loadout(loadout_picker.selected); _refresh_loadout(true))
	loadout_detail = _label(center, "", 12, INK); loadout_detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var note := _label(center, "Agility grants weapon critical chance: critical hits deal 50% extra damage. Presence improves shop prices. Spell power strengthens magic. Equipped staves add half their base damage to spell power; tempering adds +1 per rank.", 13, GOLD)
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var right := VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.size_flags_stretch_ratio = 1.15
	columns.add_child(right)
	_label(right, "EQUIPPED  /  SELECT A SLOT", 16, GOLD)
	slot_list = ItemList.new()
	slot_list.custom_minimum_size.y = 225
	slot_list.add_theme_font_size_override("font_size", 14)
	slot_list.item_selected.connect(func(index: int):
		selected_slot = state.catalog.slots[index]
		selected_item = ""
		_filter_items())
	right.add_child(slot_list)
	search = LineEdit.new()
	search.placeholder_text = "Filter compatible equipment…"
	search.text_changed.connect(func(_value: String): _filter_items())
	right.add_child(search)
	item_list = ItemList.new()
	item_list.custom_minimum_size.y = 110
	item_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	item_list.add_theme_font_size_override("font_size", 14)
	item_list.item_selected.connect(func(index: int):
		selected_item = item_ids[index]
		_show_item())
	item_list.item_activated.connect(func(_index: int): _equip())
	right.add_child(item_list)
	detail = _label(right, "", 13, INK)
	detail.custom_minimum_size.y = 78
	detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var actions := HBoxContainer.new()
	right.add_child(actions)
	equip_button = _button(actions, "Equip selected", _equip)
	equip_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_button(actions, "Unequip slot", func(): state.unequip(selected_slot))
	status = _label(page, "", 13, GOLD)
	status.custom_minimum_size.y = 22
	state.changed.connect(_refresh)
	_refresh()
	visible = false

func _label(parent: Node, text: String, font_size: int, tint: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", tint)
	parent.add_child(label)
	return label

func _button(parent: Node, text: String, callback: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size.y = 30
	button.add_theme_font_size_override("font_size", 14)
	button.pressed.connect(callback)
	parent.add_child(button)
	return button

func _scroll_column(parent: Node, ratio: float) -> VBoxContainer:
	var scroll := ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_stretch_ratio = ratio
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	parent.add_child(scroll)
	var column := VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override("separation", 7)
	scroll.add_child(column)
	return column

func _picker(parent: Node, title: String, options: Array) -> OptionButton:
	_label(parent, title, 13, INK)
	var picker := OptionButton.new()
	picker.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for option: Dictionary in options:
		picker.add_item(option.name)
	parent.add_child(picker)
	return picker

func _build_preview(parent: Node) -> void:
	var container := SubViewportContainer.new()
	container.stretch = true
	container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	container.custom_minimum_size = Vector2(200, 280)
	parent.add_child(container)
	viewport = SubViewport.new()
	viewport.size = Vector2i(360, 560)
	viewport.own_world_3d = true
	viewport.msaa_3d = Viewport.MSAA_2X
	container.add_child(viewport)
	var environment := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("19242e")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("c4d4e2")
	env.ambient_light_energy = 0.5
	environment.environment = env
	viewport.add_child(environment)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-35, -35, 0)
	light.light_energy = 1.2
	viewport.add_child(light)
	var camera := Camera3D.new()
	camera.position = Vector3(0, 1.2, 3.8)
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 2.75
	viewport.add_child(camera)
	camera.look_at(Vector3(0, 1.02, 0))
	preview = Visual.new()
	preview.rotation_degrees.y = 155
	viewport.add_child(preview)

func _identity() -> void:
	if refreshing:
		return
	state.set_identity(name_field.text, state.catalog.origins[origin_picker.selected].id, state.catalog.archetypes[class_picker.selected].id, ["lean", "balanced", "broad"][frame_picker.selected])

func _refresh() -> void:
	refreshing = true
	name_field.text = state.character_name
	for i in range(state.catalog.origins.size()):
		if state.catalog.origins[i].id == state.origin_id:
			origin_picker.select(i)
	for i in range(state.catalog.archetypes.size()):
		if state.catalog.archetypes[i].id == state.archetype_id:
			class_picker.select(i)
	frame_picker.select(["lean", "balanced", "broad"].find(state.frame_id))
	origin_picker.tooltip_text = state.origins[state.origin_id].description
	class_picker.tooltip_text = state.archetypes[state.archetype_id].description
	var a: Dictionary = state.attributes()
	points.text = "ATTRIBUTES  /  %d points left" % state.points_left()
	for attribute: String in state.catalog.attributes:
		attribute_labels[attribute].text = str(a[attribute])
		plus_buttons[attribute].disabled = state.points_left() <= 0
		minus_buttons[attribute].disabled = state.allocated[attribute] <= 0
	_refresh_loadout()
	var stats: Dictionary = state.stats()
	stats_label.text = "Health %d  ·  Stamina %d\nMagicka %d  ·  Spell power %d\nDamage %d / %d off-hand  ·  Armor %d\nCritical %.1f%%  ·  Barter bonus %.1f%%\nGear %.1f kg  ·  Capacity %d kg\nMove speed %.0f%%  ·  Sprint cost %.1f/s" % [stats.health, stats.stamina, stats.magicka, stats.spell_power, stats.damage, stats.offhand_damage, stats.armor, stats.critical, stats.barter, stats.weight, stats.carry, stats.speed * 100, stats.sprint_cost]
	summary.text = "%s\n%s · %s" % [state.character_name, state.origins[state.origin_id].name, state.archetypes[state.archetype_id].name]
	preview.build(state)
	slot_list.clear()
	for slot: String in state.catalog.slots:
		slot_list.add_item("%s  ·  %s" % [slot.capitalize(), state.item_at(slot).get("name", "Empty")])
	slot_list.select(state.catalog.slots.find(selected_slot))
	_filter_items()
	status.text = state.last_error if not state.last_error.is_empty() else "Changes saved locally." if state.persist else "Preview session — no save changes."
	refreshing = false

func _filter_items() -> void:
	item_list.clear()
	item_ids.clear()
	for uid: String in state.inventory:
		var item: Dictionary = state.describe_item(uid)
		if not state.accepts(item.id, selected_slot) or (not search.text.is_empty() and not item.name.to_lower().contains(search.text.to_lower())):
			continue
		item_ids.append(item.id)
		item_list.add_item(item.name + ("  [equipped]" if state.equipment[selected_slot] == item.id else ""))
	if not selected_item in item_ids:
		selected_item = item_ids[0] if not item_ids.is_empty() else ""
	if not selected_item.is_empty():
		item_list.select(item_ids.find(selected_item))
	_show_item()

func _show_item() -> void:
	if selected_item.is_empty():
		detail.text = "No compatible items match your search."
		equip_button.disabled = true
		return
	var item: Dictionary = state.describe_item(selected_item)
	var current: Dictionary = state.item_at(selected_slot)
	var blocked: bool = selected_slot == "off_hand" and state.item_at("main_hand").get("two_handed", false)
	equip_button.disabled = blocked
	var bonuses := ""
	for attribute: String in item.get("bonuses", {}):
		bonuses += " +%d %s" % [item.bonuses[attribute], attribute.capitalize()]
	detail.text = "%s\n%s\nArmor %+d · Base damage %+d · Weight %+.1f kg%s" % [item.name, "Requires a free off hand: unequip your two-handed weapon." if blocked else item.description, int(item.get("armor", 0)) - int(current.get("armor", 0)), int(item.get("damage", 0)) - int(current.get("damage", 0)), float(item.weight) - float(current.get("weight", 0)), bonuses]
	if item.get("two_handed", false) and not state.item_at("off_hand").is_empty():
		detail.text += "\nEquipping this also removes the off-hand item."

func _equip() -> void:
	if not selected_item.is_empty() and not state.equip(selected_item, selected_slot):
		status.text = state.last_error

func close() -> void:
	_identity()
	player.character_menu_open = false
	player.set_paused(false)

func _process(_delta: float) -> void:
	visible = player.character_menu_open
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS if visible else SubViewport.UPDATE_DISABLED

func _refresh_loadout(update_name: bool = false) -> void:
	for i in range(4): loadout_picker.set_item_text(i, "%d · %s" % [i + 1, state.loadouts[i].get("name", "Empty")])
	var index := loadout_picker.selected
	var entry: Dictionary = state.loadouts[index]
	if update_name: loadout_name.text = entry.get("name", "")
	var missing: Array = state.loadout_missing(index)
	loadout_apply.disabled = entry.is_empty() or not missing.is_empty()
	loadout_detail.text = "Save current replaces this set. Items retain their upgrades."
	loadout_detail.tooltip_text = "\n".join(missing)
	if not missing.is_empty():
		loadout_detail.text = "Missing / sold: " + ", ".join(missing.slice(0, 2))
		if missing.size() > 2: loadout_detail.text += " (+%d more; hover for all)" % (missing.size() - 2)
		loadout_detail.text += ". Recover gear or save a replacement set."
