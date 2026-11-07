extends SceneTree
const Settings=preload("res://scripts/accessibility_settings.gd")
func _initialize() -> void: call_deferred("run")
func run() -> void:
	assert(DisplayServer.get_name()=="headless" or "--capture" in OS.get_cmdline_user_args())
	var settings=Settings.new(); assert(settings.ui_scale==1.0)
	var world=load("res://scenes/main.tscn").instantiate(); root.add_child(world); world.capture_done=true
	for i in range(6): await physics_frame
	if world.intro.active: world.intro.finish()
	var old_size: int=world.hud.vitals.get_theme_font_size("font_size")
	world.accessibility.ui_scale=1.5; world.accessibility.changed.emit()
	await process_frame; await process_frame
	assert(world.hud.vitals.get_theme_font_size("font_size")==roundi(old_size*1.5))
	assert(world.hud.workshop.get_node_or_null("AccessibleScroll")!=null)
	assert(world.hud.character_menu.get_node_or_null("AccessibleScroll")!=null)
	assert(world.adventure.dialog.get_node_or_null("AccessibleScroll")!=null)
	var dynamic=Label.new(); dynamic.text="New quest text"; dynamic.add_theme_font_size_override("font_size",20); world.hud.workshop.add_child(dynamic)
	await process_frame; await process_frame
	assert(dynamic.get_theme_font_size("font_size")==30)
	world.accessibility.changed.emit(); assert(dynamic.get_theme_font_size("font_size")==30)
	world.accessibility.ui_scale=1.0; world.accessibility.changed.emit(); assert(dynamic.get_theme_font_size("font_size")==20)
	dynamic.queue_free()
	var rich=RichTextLabel.new(); rich.bbcode_enabled=true; rich.text="[font_size=20]Heading[/font_size]"; world.hud.add_child(rich)
	await process_frame; await process_frame
	world.accessibility.ui_scale=1.5; world.accessibility.changed.emit()
	assert(rich.text.contains("font_size=30"))
	world.accessibility.changed.emit(); assert(rich.text.contains("font_size=30"))
	rich.text="[font_size=24]Updated heading[/font_size]"
	await process_frame; await process_frame
	assert(rich.text.contains("font_size=36")); rich.queue_free()
	var enemy=world.adventure.enemies[0]; enemy.windup=.5; enemy._update_label(); assert(enemy.label.text.contains("ATTACK"))
	enemy.stagger_time=.5; enemy._update_label(); assert(enemy.label.text.contains("STAGGERED"))
	world.accessibility.ui_scale=1.5; world.accessibility.changed.emit()
	await process_frame; await process_frame
	var viewport_rect=Rect2(Vector2.ZERO,root.get_visible_rect().size)
	for panel in [world.hud.controls,world.hud.combat_panel,world.hud.objective]:
		assert(viewport_rect.encloses(panel.get_global_rect()))
	assert(viewport_rect.encloses(world.hud.prompt.get_global_rect()))
	assert(is_equal_approx(world.hud.prompt.get_global_rect().get_center().x,viewport_rect.get_center().x))
	var picker=world.hud.accessibility_menu.ui_size
	assert(picker.get_popup().get_theme_font_size("font_size")==roundi(picker.get_popup().get_meta("base_font_size")*1.5))
	world.player.set_paused(true)
	await process_frame; await process_frame
	var scroll=world.hud.pause_panel.get_node("AccessibleScroll")
	var buttons=world.hud.pause_panel.find_children("*","Button",true,false)
	buttons[-1].grab_focus()
	await process_frame; await process_frame
	assert(scroll.follow_focus)
	assert(scroll.get_global_rect().intersects(buttons[-1].get_global_rect()))
	scroll.scroll_vertical=0
	world.player.workshop_open=true
	await process_frame; await process_frame
	var nested=world.hud.workshop.actions.get_parent().get_parent()
	var end_button=Button.new(); end_button.text="Last action"; world.hud.workshop.actions.add_child(end_button)
	end_button.custom_minimum_size.y=1000
	await process_frame; await process_frame
	end_button.grab_focus()
	await process_frame; await process_frame
	assert(nested.follow_focus and nested.scroll_vertical>0)
	end_button.queue_free(); world.player.workshop_open=false
	if DisplayServer.get_name()!="headless":
		var folder="res://build/ui-scaling/"+str(root.size.x)+"x"+str(root.size.y); DirAccess.make_dir_recursive_absolute(folder)
		for screen in ["hud","pause","workshop","character","map","dialogue","accessibility"]:
			world.player.set_paused(screen!="hud")
			world.player.workshop_open=screen=="workshop"; world.player.character_menu_open=screen=="character"; world.player.map_open=screen=="map"; world.player.dialog_open=screen=="dialogue"
			world.adventure.dialog.visible=screen=="dialogue"
			if screen=="dialogue": world.adventure.dialog_text.text="A readable conversation. ".repeat(80)
			world.hud.accessibility_menu.visible=screen=="accessibility"
			await create_timer(.3).timeout
			root.get_texture().get_image().save_png(folder+"/"+screen+".png")
	world.queue_free(); await process_frame
	print("UI_SCALING_COMPLETE failures=0"); quit()
