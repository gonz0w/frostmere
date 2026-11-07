extends SceneTree
const Settings=preload("res://scripts/accessibility_settings.gd")
func _initialize() -> void: call_deferred("run")
func run() -> void:
	assert(DisplayServer.get_name()=="headless" or "--capture" in OS.get_cmdline_user_args())
	var s=Settings.new(); s.subtitle_scale=1.5; s.subtitle_backdrop=true; s.reduced_motion=true; s.reduced_flashes=true; s.show_fragments=false
	const PATH="res://build/accessibility-fixture.json"
	assert(DirAccess.make_dir_recursive_absolute("res://build")==OK)
	assert(s.save_to(PATH))
	var copy=Settings.new(); assert(copy.load_from(PATH) and copy.subtitle_scale==1.5 and copy.reduced_motion and not copy.show_fragments)
	var original=FileAccess.get_file_as_string(PATH)
	assert(DirAccess.make_dir_absolute(PATH+".tmp")==OK)
	assert(not s.save_to(PATH) and FileAccess.get_file_as_string(PATH)==original)
	DirAccess.remove_absolute(PATH+".tmp")
	var f=FileAccess.open(PATH,FileAccess.WRITE); f.store_string('{"version":999}'); f.close()
	assert(not copy.load_from(PATH) and copy.subtitle_scale==1.5)
	DirAccess.remove_absolute(PATH)
	copy.restore_defaults(); assert(copy.subtitle_scale==1.0 and not copy.reduced_motion and copy.show_fragments)
	var world=load("res://scenes/main.tscn").instantiate(); root.add_child(world); world.capture_done=true
	for i in range(5): await physics_frame
	assert(not world.player.character.persist)
	var menu=world.hud.accessibility_menu; menu.open_menu()
	menu.toggles.reduced_motion.set_pressed(true); menu.toggles.reduced_flashes.set_pressed(true)
	menu.toggles.show_fragments.set_pressed(false); menu.toggles.subtitle_backdrop.set_pressed(true)
	menu.subtitle_size.select(2); menu.subtitle_size.item_selected.emit(2)
	assert(world.accessibility.subtitle_scale==1.5 and world.accessibility.reduced_motion and not world.accessibility.show_fragments)
	assert(menu.message.text.contains("session"))
	world.player.character.intro_completed=false; assert(world.intro.start())
	world.intro.pose_reveal(); assert(is_equal_approx(world.intro.light.light_energy,2.6))
	assert(world.intro.subtitle.get_theme_font_size("font_size")==27)
	assert(world.intro.subtitle.has_theme_stylebox_override("normal"))
	var effect=preload("res://scripts/finisher_effect.gd").spawn(world.adventure.enemies[0],"sweep",Vector3.FORWARD)
	assert(effect==null)
	menu.close_menu(); world.player.set_paused(false)
	world.player.power=100; assert(world.player.activate_power())
	var timing=Engine.time_scale
	world.player.update_power(.3)
	assert(absf(world.player.first_person_hands.rotation.z-world.player.power_hands_z)<.15 and Engine.time_scale==timing)
	world.player.cancel_power(); assert(Engine.time_scale==1.0)
	if DisplayServer.get_name()!="headless":
		assert(DirAccess.make_dir_recursive_absolute("res://build/accessibility")==OK)
		await create_timer(.3).timeout
		root.get_texture().get_image().save_png("res://build/accessibility/subtitles.png")
		menu.open_menu(); await create_timer(.3).timeout
		root.get_texture().get_image().save_png("res://build/accessibility/settings.png")
		menu.close_menu(); await create_timer(.3).timeout
		root.get_texture().get_image().save_png("res://build/accessibility/pause.png")
	menu.open_menu()
	var escape=InputEventKey.new(); escape.physical_keycode=KEY_ESCAPE; escape.pressed=true
	menu._input(escape); assert(not menu.visible and world.player.paused)
	world.queue_free(); await process_frame
	print("ACCESSIBILITY_COMPLETE failures=0"); quit()
