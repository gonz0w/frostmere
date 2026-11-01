extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var scene=Node3D.new(); root.add_child(scene)
	var env=WorldEnvironment.new(); var settings=Environment.new()
	settings.background_mode=Environment.BG_COLOR; settings.background_color=Color("202a34")
	settings.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR; settings.ambient_light_color=Color("c9dae5"); settings.ambient_light_energy=.65
	env.environment=settings; scene.add_child(env)
	var light=DirectionalLight3D.new(); light.rotation_degrees=Vector3(-35,-35,0); light.light_energy=1.7; scene.add_child(light)
	var families=["steel","leather","cloth"]
	for i in range(families.size()):
		var s=preload("res://scripts/character_state.gd").new()
		s.persist=false
		for slot in ["head","chest","hands","legs","feet"]:
			s.equip(s.add_item(families[i]+"_"+slot),slot)
		s.unequip("main_hand"); s.unequip("off_hand")
		var rig=preload("res://scripts/character_visual.gd").new(); scene.add_child(rig)
		rig.build(s); rig.position=Vector3((i-1)*1.35,0,0); rig.rotation.y=-.25
		var label=Label3D.new(); label.text=families[i].capitalize(); label.font_size=32; label.pixel_size=.003; label.position=Vector3(rig.position.x,-.12,0); label.billboard=BaseMaterial3D.BILLBOARD_ENABLED; scene.add_child(label)
	var camera=Camera3D.new(); scene.add_child(camera); camera.position=Vector3(.3,2.2,-6); camera.look_at(Vector3(0,.95,0)); camera.projection=Camera3D.PROJECTION_ORTHOGONAL; camera.size=3.0; camera.current=true
	for i in range(5): await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://build/refined-armor.png")
	print("REFINED_ARMOR_RENDER_COMPLETE"); quit()
