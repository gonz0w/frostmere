extends SceneTree
func _initialize() -> void: call_deferred("run")
func capture(path: String, frames: int=16) -> void:
	for i in range(frames): await process_frame
	await RenderingServer.frame_post_draw
	get_root().get_texture().get_image().save_png(path)
func run() -> void:
	var world: Node3D=load("res://scenes/main.tscn").instantiate(); root.add_child(world); world.capture_done=true
	assert(not world.player.character.persist and not world.atlas.persist)
	var c: Node3D=world.archive_chapter
	var p: CharacterBody3D=world.player
	if "stonewake" not in p.character.story_completed: p.character.story_completed.append("stonewake")
	c.enter(); world.hud.notice_time=0
	await capture("res://build/pinehall-arrival.png")
	p.position=c.ORIGIN+Vector3(0,0.2,-23); p.rotation=Vector3.ZERO
	await capture("res://build/ruined-archive.png")
	for enemy in c.enemies: enemy.set_physics_process(false)
	p.character.archive.accepted=true; p.character.archive.heard=["lantern","briar"]
	for enemy in c.enemies: enemy.receive_damage(10000)
	p.character.archive.atlas=true
	p.position=c.ORIGIN+c.NODES.lantern+Vector3(0,0.1,1.4); world.interact_nearby()
	await capture("res://build/atlas-recipient-choice.png")
	c.close_dialog(); p.set_paused(false)
	p.map_open=true; p.set_paused(true); world.hud.world_map.set_view(true)
	await capture("res://build/pinehall-map.png")
	world.queue_free(); await process_frame
	print("ARCHIVE_RENDERS_COMPLETE"); quit()
