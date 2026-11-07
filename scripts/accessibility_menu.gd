extends PanelContainer
var world: Node3D
var message: Label
var ui_size: OptionButton
var subtitle_size: OptionButton
var toggles: Dictionary={}
func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var style=world.hud._panel(); style.bg_color=Color(0.045,0.07,0.085,1)
	add_theme_stylebox_override("panel",style)
	var margin=MarginContainer.new(); add_child(margin)
	for side in ["left","right","top","bottom"]: margin.add_theme_constant_override("margin_"+side,24)
	var column=VBoxContainer.new(); column.add_theme_constant_override("separation",16); margin.add_child(column)
	world.hud._label(column,"ACCESSIBILITY",26,world.hud.INK)
	message=world.hud._label(column,"Presentation preferences; combat timing and damage stay the same.",16,world.hud.GOLD)
	message.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	var scroll=ScrollContainer.new(); scroll.follow_focus=true; scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL; column.add_child(scroll)
	var list=VBoxContainer.new(); list.size_flags_horizontal=Control.SIZE_EXPAND_FILL; list.add_theme_constant_override("separation",16); scroll.add_child(list)
	world.hud._label(list,"HUD, menu and dialogue text size",18,world.hud.INK)
	ui_size=OptionButton.new(); list.add_child(ui_size)
	for value in ["100%","125%","150%"]: ui_size.add_item(value)
	ui_size.item_selected.connect(func(index: int): world.accessibility.ui_scale=[1.0,1.25,1.5][index]; update_settings())
	world.hud._label(list,"Opening subtitle size",18,world.hud.INK)
	subtitle_size=OptionButton.new(); list.add_child(subtitle_size)
	for value in ["100%","125%","150%"]: subtitle_size.add_item(value)
	subtitle_size.item_selected.connect(func(index: int): world.accessibility.subtitle_scale=[1.0,1.25,1.5][index]; update_settings())
	var names={"subtitle_backdrop":"High-contrast opening subtitles","reduced_motion":"Reduce weapon and fragment motion","reduced_flashes":"Reduce cosmetic flashes","show_fragments":"Show finisher fragments"}
	for id in names:
		var toggle=CheckBox.new(); toggle.text=names[id]; toggle.add_theme_font_size_override("font_size",18); list.add_child(toggle); toggles[id]=toggle
		toggle.toggled.connect(func(value: bool): world.accessibility.set(id,value); update_settings())
	var note=world.hud._label(list,"Reduced motion softens first-person weapon poses and fragment rotation. Reduced flashes steadies the opening ward and dims lightning, projectiles and finisher effects. Hiding fragments removes the finishing burst, not enemies or combat animations.",16,world.hud.INK)
	note.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	var actions=HBoxContainer.new(); column.add_child(actions)
	world.hud._button(actions,"Restore defaults",func(): world.accessibility.restore_defaults(); update_settings())
	world.hud._button(actions,"Back to pause menu",close_menu)
	world.accessibility.changed.connect(refresh); refresh(); hide()
func refresh() -> void:
	ui_size.select([1.0,1.25,1.5].find(world.accessibility.ui_scale))
	subtitle_size.select([1.0,1.25,1.5].find(world.accessibility.subtitle_scale))
	for id in toggles: toggles[id].set_pressed_no_signal(world.accessibility.get(id))
func open_menu() -> void:
	refresh(); show(); world.player.set_paused(true); ui_size.grab_focus()
	message.text=world.accessibility.load_warning if not world.accessibility.load_warning.is_empty() else "Presentation preferences; combat timing and damage stay the same."
func close_menu() -> void: hide()
func update_settings() -> void:
	world.accessibility.changed.emit()
	if not world.player.character.persist: message.text="Applied for this session. Settings persistence is disabled in previews and recovery sessions."
	elif world.accessibility.save_to(world.accessibility.PATH): world.accessibility.load_warning=""; message.text="Accessibility preferences saved."
	else: message.text="Applied for this session, but settings could not be saved. Check folder permissions and disk space."
func _input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("pause"):
		close_menu(); get_viewport().set_input_as_handled()
