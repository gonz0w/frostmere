extends SceneTree
const State = preload("res://scripts/character_state.gd")
const Visual = preload("res://scripts/character_visual.gd")
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var stage := Node3D.new()
	root.add_child(stage)
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("18222c")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("c1d2e5")
	env.ambient_light_energy = 0.5
	var world_env := WorldEnvironment.new()
	world_env.environment = env
	stage.add_child(world_env)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-30, -25, 0)
	stage.add_child(light)
	var camera := Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 6.4
	camera.position = Vector3(0, 3.0, 10)
	stage.add_child(camera)
	var state := State.new()
	var armor := ["fur", "steel", "leather", "cloth", "chain", "iron", "obsidian", "crystal"]
	var weapons := ["iron_battleaxe", "steel_sword", "iron_bow", "crystal_staff", "steel_mace", "iron_axe", "obsidian_dagger", "crystal_greatsword"]
	for i in range(8):
		state.set_identity("Preview", state.catalog.origins[i].id, state.catalog.archetypes[i].id, "balanced")
		for slot in ["head", "chest", "hands", "legs", "feet"]:
			state.equip(state.add_item(armor[i] + "_" + slot), slot)
		state.unequip("off_hand")
		state.equip(state.add_item(weapons[i]), "main_hand")
		var model := Visual.new()
		model.position = Vector3(-3.6 + (i % 4) * 2.4, 3.6 if i < 4 else 0.5, 0)
		model.rotation.y = 2.95
		stage.add_child(model)
		model.build(state)
		var label := Label3D.new()
		label.position = model.position + Vector3(0, -0.25, 0)
		label.font_size = 30
		label.pixel_size = 0.008
		label.outline_size = 0
		label.modulate = Color("c8b382")
		label.text = state.origins[state.origin_id].name + "\n" + armor[i].capitalize()
		stage.add_child(label)
	for i in range(20):
		await process_frame
	await RenderingServer.frame_post_draw
	var path := ProjectSettings.globalize_path("res://build/character-gallery.png")
	root.get_texture().get_image().save_png(path)
	print("GALLERY_SAVED " + path)
	quit()
