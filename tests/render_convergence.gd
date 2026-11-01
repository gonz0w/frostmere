extends SceneTree
func _initialize() -> void: call_deferred("run")
func capture(path: String) -> void:
	for i in range(18): await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://build/"+path+".png")
func run() -> void:
	var world: Node3D=load("res://scenes/main.tscn").instantiate(); root.add_child(world); world.capture_done=true; world.audio.enabled=false
	var p: CharacterBody3D=world.player; var c: Node3D=world.convergence
	assert(not p.character.persist and not world.atlas.persist)
	assert(p.character.save_to("user://convergence-preview-check.json"))
	var loaded=preload("res://scripts/character_state.gd").new(); assert(loaded.load_from("user://convergence-preview-check.json")); DirAccess.remove_absolute("user://convergence-preview-check.json")
	world.hud.notice_time=0
	for enemy in c.enemies: enemy.set_physics_process(false)
	await capture("mirewatch-arrival")
	p.character.convergence.accepted=true; p.position=c.ORIGIN+c.NODES.keeper+Vector3(0,.1,1.4); c.open_dialog("keeper")
	await capture("mirewatch-briefing")
	c.open_dialog("roots"); await capture("mirewatch-woodland-account")
	c.close_dialog(); p.set_paused(false); p.position=c.ORIGIN+Vector3(0,.2,-15); p.rotation=Vector3.ZERO
	await capture("mirewatch-calibration")
	p.character.convergence.evidence=c.REQUIRED.duplicate(); p.character.blueprints.append("transit_regulator")
	p.character.materials.steel_ingot=8; p.character.materials.crystal=6; p.character.materials.rune_dust=4
	p.position=c.ORIGIN+c.NODES.forge+Vector3(0,.1,1.4); world.hud.workshop.open("forge"); world.hud.workshop.search.text="Transit Regulator"; world.hud.workshop.refresh()
	await capture("mirewatch-forge"); world.hud.workshop.close()
	p.character.convergence.installed=true; p.character.convergence.calibrated=true
	for enemy in c.enemies:
		p.character.convergence.defeated.append(enemy.enemy_id); enemy.dead=true; enemy._show_corpse(); enemy._update_label()
	p.character._commit()
	p.position=c.ORIGIN+Vector3(0,.2,-53)
	await capture("mirewatch-beacon")
	p.map_open=true; p.set_paused(true); world.hud.world_map.set_view(true)
	await capture("mirewatch-map")
	world.queue_free(); await process_frame
	print("CONVERGENCE_RENDERS_COMPLETE"); quit()
