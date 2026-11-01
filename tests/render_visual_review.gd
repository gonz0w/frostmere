extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	if "--capture" not in OS.get_cmdline_user_args(): quit(1); return
	var w=load("res://scenes/main.tscn").instantiate(); root.add_child(w); w.capture_done=true
	for i in range(6): await physics_frame
	assert(not w.player.character.persist and not w.atlas.persist)
	w.player.set_physics_process(false); w.player.visible=false
	for layer in w.find_children("*","CanvasLayer",true,false): layer.visible=false
	for actor in w.wilderness.enemies: actor.set_physics_process(false)
	var s=preload("res://scripts/character_state.gd").new(); s.persist=false
	for slot in ["head","chest","hands","legs","feet"]: s.equip(s.add_item("iron_"+slot),slot)
	s.equip(s.add_item("steel_sword",2,"vigor"),"main_hand"); s.equip(s.add_item("iron_shield"),"off_hand")
	var hero=preload("res://scripts/character_visual.gd").new(); w.add_child(hero); hero.build(s)
	hero.position=Vector3(-8.7,.25,0); hero.rotation.y=3.35
	var beast=w.wilderness.enemies[12]; beast.position=Vector3(-3,.25,-4); beast.rotation.y=2.65
	beast.label.visible=false
	var camera=Camera3D.new(); w.add_child(camera); camera.position=Vector3(-7,2.5,2.8); camera.look_at(Vector3(-7,1.6,-3.0)); camera.fov=65; camera.current=true
	for i in range(12): await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://build/visual-review.png")
	print("VISUAL_REVIEW_RENDER_COMPLETE"); quit()
