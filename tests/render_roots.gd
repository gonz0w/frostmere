extends SceneTree
func _initialize() -> void: call_deferred("run")
func capture(path: String) -> void:
	for i in range(18): await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://build/"+path+".png")
func run() -> void:
	var world: Node3D=load("res://scenes/main.tscn").instantiate(); root.add_child(world); world.capture_done=true; world.audio.enabled=false
	var p: CharacterBody3D=world.player; var c: Node3D=world.roots
	assert(not p.character.persist and not world.atlas.persist)
	assert(p.character.save_to("user://roots-preview-check.json"))
	var loaded=preload("res://scripts/character_state.gd").new(); assert(loaded.load_from("user://roots-preview-check.json")); DirAccess.remove_absolute("user://roots-preview-check.json")
	world.hud.notice_time=0
	for enemy in c.enemies: enemy.set_physics_process(false)
	await capture("stag-shrine-arrival")
	p.position=c.ORIGIN+Vector3(0,.2,-44); p.rotation=Vector3.ZERO
	await capture("stag-shrine-hollow-tree")
	p.position=c.ORIGIN+c.NODES.keeper+Vector3(0,.1,1.4); c.open_dialog("keeper")
	await capture("stag-shrine-proposal")
	c.close_dialog(); p.set_paused(false)
	p.character.roots.accepted=true; p.character.roots.cleansed=["spring","stone","seed"]; p.character.roots.heard=["keeper","steward"]; p.character.roots.defeated=["roots_0","roots_1","roots_2","roots_3"]
	for enemy in c.enemies: enemy.dead=true; enemy._show_corpse(); enemy._update_label()
	p.position=c.ORIGIN+c.NODES.heart+Vector3(0,.1,1.4); c.open_dialog("heart")
	await capture("stag-shrine-choice")
	c.close_dialog(); p.set_paused(false); p.position=c.ORIGIN+Vector3(0,.2,-25); p.rotation=Vector3.ZERO
	p.character.roots.choice="wild"; p.character._commit(); await capture("stag-shrine-wild")
	p.character.roots.choice="tended"; p.character._commit(); await capture("stag-shrine-tended")
	p.map_open=true; p.set_paused(true); world.hud.world_map.set_view(true)
	await capture("stag-shrine-map")
	world.queue_free(); await process_frame
	print("ROOTS_RENDERS_COMPLETE"); quit()
