extends SceneTree
func _initialize() -> void: call_deferred("run")
func capture(path: String) -> void:
	for i in range(18): await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://build/"+path+".png")
func run() -> void:
	var world: Node3D=load("res://scenes/main.tscn").instantiate(); root.add_child(world); world.capture_done=true; world.audio.enabled=false
	for i in range(5): await physics_frame
	var p: CharacterBody3D=world.player; var menu: Control=world.skills_menu
	assert(not p.character.persist and not world.atlas.persist)
	menu.open_menu(); await capture("skills-starting")
	for skill in ["melee","marksman","magic","crafting"]: p.character.train(skill,400)
	menu.refresh(); await capture("skills-melee")
	menu.rows.get_child(2).pressed.emit(); assert(p.character.has_perk("heavy_hand")); await capture("skills-learned")
	menu.selected="crafting"; menu.refresh(); await capture("skills-crafting")
	menu.selected="magic"; menu.refresh(); await capture("skills-magic")
	assert(p.character.save_to("user://skills-preview-check.json"))
	var loaded=preload("res://scripts/character_state.gd").new(); assert(loaded.load_from("user://skills-preview-check.json")); DirAccess.remove_absolute("user://skills-preview-check.json")
	world.queue_free(); await process_frame; print("SKILLS_RENDERS_COMPLETE"); quit()
