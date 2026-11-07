extends PanelContainer
var world: Node3D
var awaiting:=""
var buttons: Dictionary={}
var message: Label
var sensitivity: HSlider
var inverted: CheckBox
func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var style=world.hud._panel(); style.bg_color=Color(0.045,0.07,0.085,1)
	add_theme_stylebox_override("panel",style)
	var margin=MarginContainer.new(); add_child(margin)
	for side in ["left","right","top","bottom"]: margin.add_theme_constant_override("margin_"+side,24)
	var column=VBoxContainer.new(); column.add_theme_constant_override("separation",10); margin.add_child(column)
	world.hud._label(column,"CONTROLS",26,world.hud.INK)
	message=world.hud._label(column,"Choose an action, then press a key or mouse button. Esc cancels binding.",14,world.hud.GOLD)
	message.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	var scroll=ScrollContainer.new(); scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL; column.add_child(scroll)
	var list=VBoxContainer.new(); list.size_flags_horizontal=Control.SIZE_EXPAND_FILL; scroll.add_child(list)
	for action in world.controls.bindings:
		var row=HBoxContainer.new(); list.add_child(row)
		var title=world.hud._label(row,world.controls.TITLES[action],16,world.hud.INK); title.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		var button=Button.new(); button.custom_minimum_size=Vector2(170,36); row.add_child(button); buttons[action]=button
		button.pressed.connect(func():
			awaiting=action; message.text="Binding "+world.controls.TITLES[action]+" — press a key/button; Esc cancels. Hold Shift for a combination, or release Shift to bind it alone.")
	world.hud._label(column,"Mouse sensitivity",15,world.hud.INK)
	sensitivity=HSlider.new(); sensitivity.min_value=0.0002; sensitivity.max_value=0.01; sensitivity.step=0.0001; column.add_child(sensitivity)
	sensitivity.value_changed.connect(func(value: float): world.controls.sensitivity=value; save_settings())
	inverted=CheckBox.new(); inverted.text="Invert vertical mouse look"; column.add_child(inverted)
	inverted.toggled.connect(func(value: bool): world.controls.invert_y=value; save_settings())
	var note=world.hud._label(column,"Physical key positions; labels follow your keyboard layout. Esc / Tab / Enter keep menu navigation available.",13,world.hud.GOLD)
	note.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	var actions=HBoxContainer.new(); column.add_child(actions)
	world.hud._button(actions,"Restore defaults",func(): world.controls.restore_defaults(); world.controls.apply(); refresh(); save_settings())
	world.hud._button(actions,"Back to pause menu",close_menu)
	world.controls.changed.connect(refresh)
	refresh(); hide()
func refresh() -> void:
	for action in buttons: buttons[action].text=world.controls.label(action)
	sensitivity.set_value_no_signal(world.controls.sensitivity)
	inverted.set_pressed_no_signal(world.controls.invert_y)
func open_menu() -> void:
	awaiting=""; refresh(); show(); world.player.set_paused(true)
	message.text=world.controls.load_warning if not world.controls.load_warning.is_empty() else "Choose an action, then press a key or mouse button. Esc cancels binding."
	buttons.values()[0].grab_focus()
func close_menu() -> void:
	awaiting=""; hide()
func save_settings() -> void:
	if not world.player.character.persist:
		message.text="Applied for this session. Saving settings is disabled in this preview or recovery session."
	elif world.controls.save_to(world.controls.PATH):
		world.controls.load_warning=""; message.text="Controls saved."
	else: message.text="Applied for this session, but controls could not be saved. Check folder permissions and disk space."
func _input(event: InputEvent) -> void:
	if not visible: return
	if event is InputEventKey and event.pressed and event.physical_keycode==KEY_ESCAPE:
		if awaiting.is_empty(): close_menu()
		else: awaiting=""; message.text="Binding cancelled."
		get_viewport().set_input_as_handled(); return
	if awaiting.is_empty(): return
	if event is InputEventKey:
		if event.echo: get_viewport().set_input_as_handled(); return
		if event.physical_keycode==KEY_SHIFT and event.pressed: get_viewport().set_input_as_handled(); return
		if not event.pressed and event.physical_keycode!=KEY_SHIFT: return
	elif not (event is InputEventMouseButton and event.pressed): return
	get_viewport().set_input_as_handled()
	var error: String=world.controls.rebind(awaiting,event)
	awaiting=""
	if error.is_empty(): save_settings()
	else: message.text=error
