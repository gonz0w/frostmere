extends SceneTree
func _initialize() -> void: call_deferred("run")
func key(code: int) -> InputEventKey:
	var event=InputEventKey.new(); event.physical_keycode=code; event.pressed=true; return event
func run() -> void:
	assert(DisplayServer.get_name()=="headless" or "--capture" in OS.get_cmdline_user_args())
	var world=load("res://scenes/main.tscn").instantiate(); root.add_child(world)
	world.capture_done=true
	for i in range(5): await physics_frame
	assert(not world.player.character.persist and not world.atlas.persist)
	var menu=world.hud.controls_menu
	menu.open_menu(); await process_frame
	assert(menu.visible and world.player.paused and Input.mouse_mode==Input.MOUSE_MODE_VISIBLE)
	menu.buttons.interact.pressed.emit(); menu._input(key(KEY_J))
	assert(world.controls.label("interact")=="J" and menu.buttons.interact.text=="J")
	assert(menu.message.text.contains("session"))
	assert(world.hud.guide_labels[0].text.contains("J Use"))
	menu.buttons.inventory.pressed.emit(); menu._input(key(KEY_J))
	assert(menu.message.text.contains("Already used") and world.controls.label("inventory")=="I")
	menu.buttons.interact.pressed.emit(); menu._input(key(KEY_ESCAPE))
	assert(menu.visible and menu.awaiting.is_empty() and world.controls.label("interact")=="J")
	menu.inverted.set_pressed(true); menu.sensitivity.value=0.004
	assert(world.controls.invert_y and is_equal_approx(world.controls.sensitivity,0.004))
	menu._input(key(KEY_ESCAPE)); assert(not menu.visible and world.player.paused)
	if DisplayServer.get_name()=="headless":
		world.player.set_paused(false)
		var before: bool=world.player.third_person
		assert(world.controls.rebind("camera_toggle",key(KEY_U)).is_empty())
		world.player._unhandled_input(key(KEY_V)); assert(world.player.third_person==before)
		world.player._unhandled_input(key(KEY_U)); assert(world.player.third_person!=before)
		# Headless display cannot capture a mouse; exercise the shared look calculation.
		var motion=InputEventMouseMotion.new(); motion.relative=Vector2(0,10)
		var pitch: float=world.player.pivot.rotation.x
		world.player.apply_look(motion.relative); assert(world.player.pivot.rotation.x>pitch)
		world.controls.invert_y=false; pitch=world.player.pivot.rotation.x
		world.player.apply_look(motion.relative); assert(world.player.pivot.rotation.x<pitch)
		world.player._notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
		assert(world.player.paused and Input.mouse_mode==Input.MOUSE_MODE_VISIBLE)
	assert(world.controls.rebind("spell",key(KEY_P)).is_empty())
	assert(world.controls.rebind("cycle_spell",key(KEY_O)).is_empty())
	world.hud._process(0)
	assert(world.hud.vitals.text.contains("P:") and world.hud.vitals.text.contains("O change"))
	world.player.character.intro_completed=false
	assert(world.intro.start())
	menu.open_menu(); world.intro.advance(0)
	assert(not world.intro.overlay.visible)
	if DisplayServer.get_name()!="headless":
		await create_timer(1).timeout
		assert(DirAccess.make_dir_recursive_absolute("res://build/controls")==OK)
		root.get_texture().get_image().save_png("res://build/controls/menu.png")
	world.queue_free(); await process_frame
	print("CONTROL_INPUT_COMPLETE failures=0"); quit()
