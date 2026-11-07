extends CanvasLayer
const CampaignGuide = preload("res://scripts/campaign_guide.gd")
const CharacterMenu = preload("res://scripts/character_menu.gd")
var character_menu: Control
const Workshop = preload("res://scripts/workshop.gd")
var workshop: Control
const WorldMap = preload("res://scripts/world_map.gd")
var world_map: Control
var objective: Label
var damage_direction: Control

var world: Node3D
var compass: Label
var mode: Label
var prompt: Label
var notice: VBoxContainer
var notice_title: Label
var notice_detail: Label
var controls: PanelContainer
var pause_panel: ColorRect
var finisher_hint: Label
var power_label: Label
var power_bar: ProgressBar
var combat_panel: VBoxContainer
var vitals: Label
var stamina: ProgressBar
var performance: Label
var notice_time := 0.0
var show_performance := false
const INK := Color("e3ded0")
const GOLD := Color("bfaa78")

func _ready() -> void:
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	var top := VBoxContainer.new()
	top.position = Vector2(38, 30)
	root.add_child(top)
	_label(top, "F R O S T M E R E", 23, INK)
	_label(top, "THE NORTHERN REACH  /  EXPLORATION PROTOTYPE", 10, GOLD)
	compass = Label.new()
	compass.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	compass.position = Vector2(-190, 32)
	compass.size = Vector2(380, 40)
	compass.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	compass.add_theme_font_size_override("font_size", 18)
	compass.add_theme_color_override("font_color", INK)
	root.add_child(compass)
	var dot := Label.new()
	dot.text = "·"
	dot.add_theme_font_size_override("font_size", 30)
	dot.add_theme_color_override("font_color", Color(1, 1, 1, 0.6))
	dot.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	dot.position = Vector2(-4, -20)
	root.add_child(dot)
	damage_direction=preload("res://scripts/damage_direction.gd").new()
	damage_direction.player=world.player
	root.add_child(damage_direction)
	notice = VBoxContainer.new()
	notice.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	notice.position = Vector2(-350, 119)
	notice.size = Vector2(700, 100)
	root.add_child(notice)
	var eyebrow := _label(notice, "—  D I S C O V E R E D  —", 11, GOLD)
	eyebrow.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	notice_title = _label(notice, "", 34, INK)
	notice_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	notice_detail = _label(notice, "", 14, INK)
	notice_detail.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	notice_detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	notice_detail.custom_minimum_size.x = 700
	notice.visible = false
	controls = PanelContainer.new()
	controls.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	controls.position = Vector2(32, -187)
	controls.size = Vector2(275, 148)
	controls.add_theme_stylebox_override("panel", _panel())
	root.add_child(controls)
	var guide := VBoxContainer.new()
	guide.add_theme_constant_override("separation", 7)
	controls.add_child(guide)
	_label(guide, "V Camera · E Use / Gather", 12, GOLD)
	_label(guide, "W A S D   Move       MOUSE   Look", 13, INK)
	_label(guide, "SHIFT   Sprint       SPACE   Jump", 13, INK)
	_label(guide, "LMB Attack   RMB Block   Q Spell   F Heal", 13, INK)
	_label(guide, "Raise guard just before a hit to parry", 12, GOLD)
	_label(guide, "C Gear   I Bag   K Skills   M Map   ESC Pause", 13, INK)
	var bottom := VBoxContainer.new()
	combat_panel=bottom
	bottom.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	bottom.position = Vector2(-340, -212)
	bottom.size = Vector2(305, 110)
	root.add_child(bottom)
	mode = _label(bottom, "", 12, GOLD)
	mode.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	vitals = _label(bottom, "", 13, INK)
	stamina = ProgressBar.new()
	stamina.custom_minimum_size = Vector2(255, 5)
	stamina.show_percentage = false
	var back := StyleBoxFlat.new()
	back.bg_color = Color(0.05, 0.08, 0.08, 0.7)
	stamina.add_theme_stylebox_override("background", back)
	var fill := StyleBoxFlat.new()
	fill.bg_color = Color("929e76")
	stamina.add_theme_stylebox_override("fill", fill)
	bottom.add_child(stamina)
	finisher_hint = _label(bottom, "", 12, GOLD)
	power_label = _label(bottom, "", 12, GOLD)
	power_bar = ProgressBar.new(); power_bar.show_percentage = false; power_bar.custom_minimum_size = Vector2(255, 5); bottom.add_child(power_bar)
	var hint := _label(bottom, "STAMINA  /  R to return to the trail", 11, INK)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	prompt = Label.new()
	prompt.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	prompt.position = Vector2(-250, -110)
	prompt.size = Vector2(500, 30)
	prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt.add_theme_font_size_override("font_size", 17)
	root.add_child(prompt)
	performance = Label.new()
	performance.position = Vector2(38, 88)
	performance.add_theme_font_size_override("font_size", 12)
	root.add_child(performance)
	_build_pause(root)
	character_menu = CharacterMenu.new()
	character_menu.player = world.player
	root.add_child(character_menu)
	world_map = WorldMap.new()
	world_map.world = world
	root.add_child(world_map)
	workshop = Workshop.new()
	workshop.world = world
	root.add_child(workshop)
	objective = Label.new()
	objective.add_theme_color_override("font_outline_color", Color(0.04,0.06,0.08,0.85))
	objective.add_theme_constant_override("outline_size", 4)
	objective.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	objective.position = Vector2(-375, 90)
	objective.size = Vector2(335, 90)
	objective.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	objective.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	objective.add_theme_font_size_override("font_size", 14)
	objective.add_theme_color_override("font_color", INK)
	root.add_child(objective)

func _panel() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.045, 0.07, 0.085, 0.83)
	style.border_color = Color(0.64, 0.57, 0.40, 0.35)
	style.set_border_width_all(1)
	style.content_margin_left = 17
	style.content_margin_right = 17
	style.content_margin_top = 14
	style.content_margin_bottom = 14
	return style

func _label(parent: Node, value: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = value
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.7))
	label.add_theme_constant_override("shadow_offset_y", 1)
	parent.add_child(label)
	return label

func _build_pause(root: Control) -> void:
	pause_panel = ColorRect.new()
	pause_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	pause_panel.color = Color(0.025, 0.045, 0.06, 0.88)
	root.add_child(pause_panel)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	pause_panel.add_child(center)
	var column := VBoxContainer.new()
	column.custom_minimum_size.x = 410
	column.add_theme_constant_override("separation", 16)
	center.add_child(column)
	_label(column, "F R O S T M E R E", 36, INK)
	_label(column, "Take a breath. The mountains can wait.", 16, GOLD)
	_button(column, "Resume exploration", func(): world.player.set_paused(false))
	_button(column, "World map & quests   [ M ]", func():
		world.player.map_open = true
		world.player.character_menu_open = false
		world.player.set_paused(true))
	_button(column, "Character & equipment   [ C ]", func():
		world.player.character_menu_open = true
		world.player.set_paused(true))
	_button(column, "Switch first / third person", func(): world.player.set_third_person(not world.player.third_person))
	_button(column, "Return to the trail", func():
		world.player.respawn()
		world.player.set_paused(false))
	for kind in ["master", "music", "effects"]:
		var row := HBoxContainer.new(); column.add_child(row)
		var caption := _label(row, kind.capitalize(), 14, INK); caption.custom_minimum_size.x=90
		var slider := HSlider.new(); slider.min_value=0; slider.max_value=1; slider.step=0.01; slider.custom_minimum_size.x=290
		slider.value=world.audio.get(kind+"_volume"); row.add_child(slider)
		slider.value_changed.connect(func(value: float): world.audio.set_volume(kind,value))
	_button(column, "Save adventure", func():
		if world.session_save.save_now(): world.hud.announce("Adventure saved","Location, resources, equipment and quest progress saved.")
		elif not world.player.character.persist:
			var recovery:=recovery_message()
			world.hud.announce("Saving disabled",recovery if not recovery.is_empty() else "Saving is disabled in this isolated preview."))
	_button(column, "Save and quit", func(): world.session_save.quit_game())
	_label(column, "WASD Move · Mouse Look · Shift Sprint · Space Jump\nV Camera · E Inspect · H Controls · F3 Performance", 13, INK)
	pause_panel.visible = false

func recovery_message() -> String:
	if world.player.migration_status == "blocked":
		return "The previous adventure could not be safely copied into Frostmere. Saving is disabled. Quit and back up both user-data folders before recovery; the original SkyrimCraft • Frostmere files have not been changed. See the save migration guide before removing any migration marker or files."
	var character_status: String=world.player.character.save_store.status
	var atlas_status: String=world.atlas.save_store.status
	if character_status=="blocked" or atlas_status=="blocked":
		return "A save could not be safely loaded, or was written by a newer version. Character and atlas saving are disabled for this session. Existing files are unchanged. Quit and back up the save folder before repairing files or using the matching game version."
	if character_status=="recovered" or atlas_status=="recovered":
		var parts: PackedStringArray=[]
		if character_status=="recovered": parts.append("character")
		if atlas_status=="recovered": parts.append("atlas")
		return "Restored the previous valid "+" and ".join(parts)+" backup. Some recent progress may be missing. Saving can continue; rejected primary files will be preserved with a .corrupt suffix. Character and atlas backups are separate snapshots."
	if world.player.migration_status == "migrated":
		return "Your previous adventure was copied into the Frostmere save folder. The original SkyrimCraft • Frostmere files are unchanged. Future saves belong to Frostmere; older builds will not see new progress."
	return ""

func character_recovery_clear() -> bool:
	return world.player.character.persist and world.player.character.save_store.status != "recovered" and world.atlas.save_store.status != "recovered"

func show_recovery_notice() -> void:
	var message:=recovery_message()
	if message.is_empty(): return
	world.player.set_paused(true)
	var dialog:=AcceptDialog.new()
	dialog.title="Save recovery"
	dialog.dialog_text=message
	dialog.get_label().autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	dialog.get_label().custom_minimum_size=Vector2(520,130)
	dialog.min_size=Vector2i(560,220)
	dialog.ok_button_text="Continue without saving" if not world.player.character.persist else "Continue with recovered save"
	if world.player.migration_status == "migrated" and character_recovery_clear(): dialog.ok_button_text="Continue adventure"
	dialog.add_button("Quit",true,"quit")
	dialog.custom_action.connect(func(_action: String): get_tree().quit())
	dialog.confirmed.connect(func(): world.player.set_paused(false); dialog.queue_free())
	dialog.canceled.connect(func(): world.player.set_paused(false); dialog.queue_free())
	add_child(dialog)
	dialog.popup_centered()

func _button(parent: Node, text: String, callback: Callable) -> void:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size.y = 44
	button.add_theme_font_size_override("font_size", 16)
	button.add_theme_stylebox_override("normal", _panel())
	button.pressed.connect(callback)
	parent.add_child(button)

func announce(title: String, detail: String) -> void:
	notice_title.text = title
	notice_detail.text = detail
	notice_time = 5.0
	notice.visible = true
	notice.modulate.a = 1.0

func _process(delta: float) -> void:
	var player: CharacterBody3D = world.player
	combat_panel.visible=not (is_instance_valid(world.intro) and world.intro.active)
	pause_panel.visible = player.paused and not player.character_menu_open and not player.map_open and not player.workshop_open and not player.dialog_open and not player.shop_open
	if Input.is_action_just_pressed("help") and not player.paused:
		controls.visible = not controls.visible
	if Input.is_action_just_pressed("performance"):
		show_performance = not show_performance
	performance.visible = show_performance
	performance.text = "%d FPS  ·  %s  ·  %s blocks" % [Engine.get_frames_per_second(), RenderingServer.get_video_adapter_name(), world.block_count]
	var finish_target: CharacterBody3D = player.nearby_finisher()
	finisher_hint.text = "X · Finish " + finish_target.title if finish_target != null else ""
	finisher_hint.visible = finish_target != null
	power_bar.value = player.power
	power_label.text = ("SUNDERING STRIKE" if player.power_move=="sunder" else "WHIRLWIND ACTIVE") if player.power_remaining > 0 else "READY · G Spin / Shift+G Sunder" if player.power >= 100 else "POWER %d / 100 · Damage & parries charge" % player.power
	mode.text = "THIRD PERSON  /  V" if player.third_person else "FIRST PERSON  /  V"
	objective.visible = not player.map_open and not player.character_menu_open and not player.paused
	if is_instance_valid(world.intro) and world.intro.active: objective.visible=false
	var next_objective := ""
	if world.atlas.waypoint != "":
		var target: Vector3 = world.atlas.target_position()
		var offset: Vector3 = target - player.position
		var heading := fposmod(rad_to_deg(atan2(offset.x, -offset.z)), 360.0)
		var directions := ["N", "NE", "E", "SE", "S", "SW", "W", "NW"]
		next_objective = "%s\n%s · %.0f m  /  M Map" % [world.atlas.waypoint_text(), directions[int(round(heading / 45.0)) % 8], Vector2(offset.x, offset.z).length()]
	if is_instance_valid(world.adventure) and (world.adventure.inside or (not world.adventure.state.adventure.rewarded and (world.adventure.state.adventure.accepted or world.atlas.waypoint == ""))):
		next_objective = "AN EMBER BENEATH OLDWATCH\n" + world.adventure.objective() + "\n%.0f m · M Journal" % player.global_position.distance_to(world.adventure.target())
	if is_instance_valid(world.stonewake) and world.stonewake.available() and player.character.adventure.rewarded and not player.character.stonewake.rewarded:
		next_objective = "STONEWAKE\n" + world.stonewake.objective() + "\n%.0f m · M Journal" % player.position.distance_to(world.stonewake.target())
	if is_instance_valid(world.mountain) and world.mountain.inside:
		next_objective = "WYRMKEEP · THE DIVIDED COUNCIL\n" + world.mountain.objective()
	if is_instance_valid(world.archive_chapter) and world.archive_chapter.inside:
		next_objective = "PINEHALL · THE MISSING ATLAS\n" + world.archive_chapter.objective()
	if is_instance_valid(world.shore) and world.shore.inside:
		next_objective="THE WRECK ON THE BLACK SHORE\n"+world.shore.objective()
	if is_instance_valid(world.lens) and world.lens.inside:
		next_objective="THE SKY BELOW THE SAND\n"+world.lens.objective()
	if is_instance_valid(world.roots) and world.roots.inside:
		next_objective="PACTS BENEATH THE ROOTS\n"+world.roots.objective()
	if is_instance_valid(world.choir) and world.choir.inside:
		next_objective="A SONG THROUGH THE STONE\n"+world.choir.objective()
	if is_instance_valid(world.convergence) and world.convergence.inside:
		next_objective="THE ROADS CONVERGE\n"+world.convergence.objective()
	if is_instance_valid(world.threshold) and world.threshold.inside:
		next_objective="BEYOND THE FIRST THRESHOLD\n"+world.threshold.objective()
	if is_instance_valid(world.winter) and world.winter.inside:
		next_objective="THE WINTER SIEGE\n"+world.winter.objective()
	if is_instance_valid(world.seal) and world.seal.inside:
		next_objective="THE BROKEN SEAL\n"+world.seal.objective()
	if "last_furnace" in player.character.story_completed and player.position.length()<160:
		next_objective="A LIGHT BROUGHT HOME\nExplore the holds, collect designs and improve your equipment"
	var next_vitals := "HEALTH %d / %d   MAGICKA %d / %d\nArrows %d · Healing draughts %d · Gold %d" % [player.health, player.derived.health, player.magicka, player.derived.magicka, player.character.materials.get("arrow", 0), player.character.consumables.get("healing_draught", 0), player.character.gold]
	if is_instance_valid(world.realms) and world.realms.inside:
		var realm: Dictionary = world.realms.definitions[world.realms.current]
		next_objective = realm.name + "\n" + realm.act + "\n" + world.realms.objective()
	if is_instance_valid(world.session_save):
		var guidance: String=CampaignGuide.text_for(world)
		if guidance!="": next_objective=guidance
	next_vitals += "\nQ: " + spell_hint(player.character.active_spell) + " · B change"
	if player.character.item_at("main_hand").get("family", "") == "machine_gun":
		next_vitals += "\nRounds %d" % player.character.materials.get(player.character.item_at("main_hand").get("ammo_type","hell_round"), 0)
	if player.character.item_at("main_hand").get("effect", "") == "chain_lightning": next_vitals += "\nLMB: " + spell_hint("chain_lightning")
	# Assign each completed string once. Intermediate empty/partial text forced
	# the labels to invalidate layout even when their final content was unchanged.
	objective.text = next_objective
	vitals.text = next_vitals
	stamina.max_value = player.derived.stamina
	stamina.value = player.stamina
	var bearing := fposmod(-rad_to_deg(player.rotation.y), 360.0)
	var directions := ["N", "NE", "E", "SE", "S", "SW", "W", "NW"]
	compass.text = "·     ─────     %s     ─────     ·" % directions[int(round(bearing / 45.0)) % 8]
	if not player.paused:
		notice_time -= delta
	notice.modulate.a = clampf(notice_time, 0, 1)
	notice.visible = notice_time > 0
	prompt.text = world.interaction_prompt() if not player.paused else ""

func spell_hint(id: String) -> String:
	var spell: Dictionary=world.player.character.spell_definition(id)
	var cost: String=("%.1f" % world.player.character.spell_cost(float(spell.cost))).trim_suffix(".0")
	return "%s · %s magicka" % [spell.name,cost]
