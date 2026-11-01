extends SceneTree
func _initialize() -> void: call_deferred("run")
func capture(name: String) -> void:
	for i in range(5): await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://build/"+name+".png")
func run() -> void:
	var world=load("res://scenes/main.tscn").instantiate(); root.add_child(world); world.capture_done=true; world.audio.enabled=false
	for i in range(8): await physics_frame
	var p=world.player; var r=world.realms; var e=r.enemies[5]
	assert(not p.character.persist and not world.atlas.persist)
	r.enter("crucible",true); p.set_physics_process(false); p.set_process_unhandled_input(false)
	for actor in r.enemies: actor.set_physics_process(false)
	p.position=e.global_position+Vector3(0,0,8); p.rotation=Vector3.ZERO; p.pivot.rotation.x=.03; p.set_third_person(false); world.hud.notice_time=0
	e.visible=true; e.rotation.y=PI; await capture("furnace-maw")
	e.begin_vent(); p.position+=Vector3(0,1,3); p.pivot.rotation.x=-.2; e.resolve_vent()
	var effect=e.get_parent().get_children().filter(func(n): return n.get_script()==preload("res://scripts/monster_effect.gd"))[-1]
	effect.set_process(false); effect._process(.2); await capture("furnace-eruption")
	print("MONSTER_EFFECTS_RENDER_COMPLETE"); quit()
