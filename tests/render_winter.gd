extends SceneTree
func _initialize() -> void: call_deferred("run")
func capture(path: String) -> void:
	for i in range(18): await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://build/"+path+".png")
func run() -> void:
	var world: Node3D=load("res://scenes/main.tscn").instantiate(); root.add_child(world); world.capture_done=true; world.audio.enabled=false
	var p: CharacterBody3D=world.player; var c: Node3D=world.winter
	assert(not p.character.persist and not world.atlas.persist)
	assert(p.character.save_to("user://winter-preview-check.json"))
	var loaded=preload("res://scripts/character_state.gd").new(); assert(loaded.load_from("user://winter-preview-check.json")); DirAccess.remove_absolute("user://winter-preview-check.json")
	world.hud.notice_time=0
	for enemy in c.enemies: enemy.set_physics_process(false)
	await capture("winter-arrival")
	p.position=c.ORIGIN+c.NODES.keeper+Vector3(0,.1,1.4); c.open_dialog("keeper")
	await capture("winter-briefing")
	c.act("accept"); c.close_dialog(); p.set_paused(false)
	p.position=c.ORIGIN+Vector3(0,.2,-8); p.rotation=Vector3.ZERO; p.set_third_person(false)
	await capture("winter-scouts")
	for i in range(3): c.enemies[i].receive_damage(10000,p)
	p.character.winter.repairs=["ward","ballista"]; p.character.winter.assault=true; p.character._commit()
	p.position=c.ORIGIN+Vector3(0,.2,-23)
	await capture("winter-assault")
	for i in range(3,6): c.enemies[i].receive_damage(10000,p)
	p.position=c.ORIGIN+c.NODES.orders+Vector3(0,.1,1.4); c.open_dialog("orders"); assert(c.act("orders"))
	c.close_dialog(); p.set_paused(false); p.position=c.ORIGIN+c.NODES.keeper+Vector3(0,.1,1.4); c.open_dialog("keeper"); assert(c.act("reward"))
	await capture("winter-victory")
	c.close_dialog(); p.set_paused(false); p.position=c.ORIGIN+c.NODES.forge+Vector3(0,.1,1.4); world.hud.workshop.open("forge"); world.hud.workshop.search.text="Northwatch"; world.hud.workshop.refresh()
	await capture("winter-forge"); world.hud.workshop.close()
	p.map_open=true; p.set_paused(true); world.hud.world_map.set_view(true)
	await capture("winter-map")
	world.queue_free(); await process_frame
	print("WINTER_RENDERS_COMPLETE"); quit()
