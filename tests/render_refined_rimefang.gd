extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var scene=Node3D.new(); root.add_child(scene)
	var env=WorldEnvironment.new(); var settings=Environment.new()
	settings.background_mode=Environment.BG_COLOR; settings.background_color=Color("202a34")
	settings.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR; settings.ambient_light_color=Color("c9dae5"); settings.ambient_light_energy=.65
	env.environment=settings; scene.add_child(env)
	var light=DirectionalLight3D.new(); light.rotation_degrees=Vector3(-35,-35,0); light.light_energy=1.7; scene.add_child(light)
	var beast=preload("res://scripts/frost_beast.gd").new()
	beast.rig=Node3D.new(); scene.add_child(beast.rig)
	preload("res://scripts/refined_frost_beast.gd").build(beast)
	beast.rig.rotation.y=.20
	var camera=Camera3D.new(); scene.add_child(camera); camera.position=Vector3(3,2.2,-4); camera.look_at(Vector3(0,.75,-.12)); camera.projection=Camera3D.PROJECTION_ORTHOGONAL; camera.size=2.25; camera.current=true
	for i in range(5): await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://build/refined-rimefang.png")
	beast.free()
	print("REFINED_RIMEFANG_RENDER_COMPLETE"); quit()
