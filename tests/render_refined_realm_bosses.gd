extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	assert(DisplayServer.get_name()!="headless")
	var scene=Node3D.new(); root.add_child(scene)
	var env=WorldEnvironment.new(); var settings=Environment.new()
	settings.background_mode=Environment.BG_COLOR; settings.background_color=Color("202a34")
	settings.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR; settings.ambient_light_color=Color("c9dae5"); settings.ambient_light_energy=.65
	env.environment=settings; scene.add_child(env)
	var light=DirectionalLight3D.new(); light.rotation_degrees=Vector3(-35,-35,0); light.light_energy=1.7; scene.add_child(light)
	var camera=Camera3D.new(); scene.add_child(camera); camera.projection=Camera3D.PROJECTION_ORTHOGONAL; camera.current=true
	for id in ["furnace", "crystal"]:
		var beast=load("res://scripts/furnace_beast.gd" if id=="furnace" else "res://scripts/crystal_wyrm.gd").new()
		beast.rig=Node3D.new(); scene.add_child(beast.rig)
		load("res://scripts/refined_furnace_beast.gd" if id=="furnace" else "res://scripts/refined_crystal_wyrm.gd").build(beast)
		var batches=beast.rig.find_children("*", "MultiMeshInstance3D", true, false)
		var cubes:=0
		for part in batches: cubes+=part.multimesh.instance_count
		print("REALM_BOSS_GEOMETRY %s cubes=%d batches=%d" % [id,cubes,batches.size()])
		camera.position=Vector3(7,5,-9); camera.look_at(Vector3(0,1.7,.1)); camera.size=7.5 if id=="furnace" else 9.5
		for i in range(5): await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://build/refined-"+id+"-boss.png")
		beast.rig.queue_free(); beast.free(); await process_frame
	print("REFINED_REALM_BOSSES_RENDER_COMPLETE"); quit()
