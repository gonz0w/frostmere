extends SceneTree
func _initialize() -> void: call_deferred("run")
func capture(path: String) -> void:
	for i in range(18): await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://build/"+path+".png")
func talk(c: Node3D,p: CharacterBody3D,id: String) -> void:
	c.close_dialog(); p.set_paused(false); p.position=c.ORIGIN+c.NODES[id]+Vector3(0,.1,1.4); c.open_dialog(id)
func run() -> void:
	var world: Node3D=load("res://scenes/main.tscn").instantiate(); root.add_child(world); world.capture_done=true; world.audio.enabled=false
	var p: CharacterBody3D=world.player; var c: Node3D=world.seal
	assert(not p.character.persist and not world.atlas.persist)
	assert(p.character.save_to("user://seal-preview-check.json"))
	var loaded=preload("res://scripts/character_state.gd").new(); assert(loaded.load_from("user://seal-preview-check.json")); DirAccess.remove_absolute("user://seal-preview-check.json")
	world.hud.notice_time=0
	for enemy in c.enemies: enemy.set_physics_process(false)
	await capture("seal-arrival")
	talk(c,p,"keeper"); await capture("seal-briefing"); assert(c.act("accept"))
	talk(c,p,"supplies"); assert(c.act("supplies")); c.close_dialog(); p.set_paused(false)
	for i in [0,1]: c.enemies[i].receive_damage(10000,p)
	talk(c,p,"intake"); assert(c.act("valve")); talk(c,p,"exhaust"); assert(c.act("valve"))
	c.close_dialog(); p.set_paused(false); p.position=c.ORIGIN+Vector3(0,.2,-25); p.rotation=Vector3.ZERO; p.set_third_person(false)
	await capture("seal-underworks")
	for i in [2,3]: c.enemies[i].receive_damage(10000,p)
	talk(c,p,"plans"); assert(c.act("plans")); c.close_dialog(); p.set_paused(false)
	p.position=c.ORIGIN+c.NODES.forge+Vector3(0,.1,1.4); world.hud.workshop.open("forge"); world.hud.workshop.search.text="Cinder Ward"; world.hud.workshop.refresh()
	await capture("seal-forge"); world.hud.workshop.actions.get_child(0).pressed.emit(); world.hud.workshop.close()
	p.position=c.ORIGIN+Vector3(0,.2,-44); await capture("seal-guardian")
	c.enemies[4].receive_damage(10000,p); talk(c,p,"seal"); assert(c.act("bind")); talk(c,p,"keeper"); assert(c.act("reward")); await capture("seal-victory")
	c.close_dialog(); p.set_paused(false); p.position=c.ORIGIN+Vector3(0,.2,-59); await capture("seal-crossing")
	p.map_open=true; p.set_paused(true); world.hud.world_map.set_view(true); await capture("seal-map")
	world.queue_free(); await process_frame; print("SEAL_RENDERS_COMPLETE"); quit()
