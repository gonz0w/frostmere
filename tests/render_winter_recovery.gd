extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var w=load("res://scenes/main.tscn").instantiate(); root.add_child(w); w.capture_done=true
	for i in range(8): await physics_frame
	var p=w.player; var c=w.winter; var s=p.character
	assert(not s.persist and not w.atlas.persist)
	s.story_completed.append("returning_light"); c.enter(); p.set_physics_process(false); p.set_process_unhandled_input(false)
	for enemy in c.enemies: enemy.set_physics_process(false)
	s.winter.accepted=true; s.winter.supplies=true; s.winter.defeated=["winter_0","winter_1","winter_2"]
	s.materials.crystal=0; s.materials.rune_dust=0; s.materials.steel_ingot=0
	p.position=c.ORIGIN+c.NODES.ward+Vector3(0,.1,1.3); c.open_dialog("ward")
	for i in range(5): await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://build/winter-fitted-spare.png")
	print("WINTER_RECOVERY_RENDER_COMPLETE"); quit()
