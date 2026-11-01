extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var scene=Node3D.new(); root.add_child(scene)
	var env=WorldEnvironment.new(); var settings=Environment.new()
	settings.background_mode=Environment.BG_COLOR; settings.background_color=Color("202a34")
	settings.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR; settings.ambient_light_color=Color("c9dae5"); settings.ambient_light_energy=.65
	env.environment=settings; scene.add_child(env)
	var light=DirectionalLight3D.new(); light.rotation_degrees=Vector3(-35,-35,0); light.light_energy=1.7; scene.add_child(light)
	var s=preload("res://scripts/character_state.gd").new()
	var ids=["iron_bow","lantern_conductor","station_rifle","cinder_gun"]
	for i in range(ids.size()):
		var mount=Node3D.new(); scene.add_child(mount); mount.position=Vector3((i-1.5)*1.25,0,0)
		if i>=2: mount.rotation.y=1.1; mount.position.y=.45; mount.scale=Vector3.ONE*.85
		if i==0: mount.rotation.y=1.0
		var uid: String=s.add_item(ids[i],2 if i%2 else 0,"vigor" if i%2 else "")
		if i%2: s.inventory[uid].gem="sapphire"
		preload("res://scripts/character_visual.gd").make_weapon(mount,s.describe_item(uid))
		var pieces:=0; var batches:=0
		for child in mount.get_children():
			if child is MultiMeshInstance3D: pieces+=child.multimesh.instance_count; batches+=1
		print("EQUIPMENT_DETAIL %s cuboids=%d batches=%d" % [ids[i],pieces,batches])
		var label=Label3D.new(); label.text=s.items[ids[i]].name; label.font_size=32; label.pixel_size=.0025; label.position=Vector3(mount.position.x,-.85,0); label.billboard=BaseMaterial3D.BILLBOARD_ENABLED; scene.add_child(label)
	var camera=Camera3D.new(); scene.add_child(camera); camera.position=Vector3(.5,1.6,-5); camera.look_at(Vector3(0,.3,0)); camera.projection=Camera3D.PROJECTION_ORTHOGONAL; camera.size=3.5; camera.current=true
	for i in range(5): await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://build/refined-ranged.png")
	print("REFINED_RANGED_RENDER_COMPLETE"); quit()
