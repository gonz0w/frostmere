extends SceneTree
func _initialize() -> void: call_deferred("run")
func capture(name: String) -> void:
	for i in range(5): await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://build/"+name+".png")
func run() -> void:
	var world=load("res://scenes/main.tscn").instantiate(); root.add_child(world); world.capture_done=true; world.audio.enabled=false
	for i in range(8): await physics_frame
	var p=world.player; var c=world.threshold; var e=c.enemies[5]
	assert(not p.character.persist and not world.atlas.persist)
	p.character.story_completed.append("convergence"); c.enter(); p.character.threshold.power=true; p.character.threshold.air=true
	p.set_physics_process(false); p.set_process_unhandled_input(false)
	for actor in c.enemies: actor.set_physics_process(false)
	p.position=e.home+Vector3(0,0,9); p.rotation=Vector3.ZERO; p.pivot.rotation.x=.04; p.set_third_person(false); world.hud.notice_time=0
	e.visible=true; e.rotation.y=PI; e.update_shell(); await capture("hullcarver-armored")
	e.windup=.2; e.update_shell(); await capture("hullcarver-charge")
	e.windup=0; e.exposed=3; e.spit_recoil=.35; e.update_shell(); await capture("hullcarver-recoil")
	e.spit_recoil=0
	e.exposed=3; e.update_shell(); await capture("hullcarver-core")
	print("HULLCARVER_RENDER_COMPLETE"); quit()
