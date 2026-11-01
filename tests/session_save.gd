extends SceneTree
const State=preload("res://scripts/character_state.gd")
var checks:=0
var failures:=0
func _initialize() -> void: call_deferred("run")
func check(ok: bool,label: String) -> void:
	checks+=1
	if ok: print("PASS "+label)
	else: failures+=1; push_error("FAIL "+label)
func frames(n: int=4) -> void:
	for i in range(n): await physics_frame
func run() -> void:
	var world: Node3D=load("res://scenes/main.tscn").instantiate(); root.add_child(world); await frames(5)
	var p: CharacterBody3D=world.player; var s: RefCounted=p.character; var session: Node=world.session_save
	check(session.ready_to_save and not s.persist,"Tests initialize session capture with persistence disabled")
	check(not session.save_now(),"Isolated sessions cannot write the regular save")
	for id in s.realm_data.story_ids:
		if id!="last_furnace": s.story_completed.append(id)
	for chapter in [world.adventure,world.realms,world.mountain,world.archive_chapter,world.shore,world.lens,world.roots,world.choir,world.convergence,world.threshold,world.winter,world.seal]:
		for enemy in chapter.enemies: enemy.set_physics_process(false)
	for id in ["home","adventure","mountain","archive_chapter","shore","lens","roots","choir","convergence","threshold","winter","seal","aeralis","crucible"]:
		var entry: Dictionary={"area":id,"position":[9999,0,0],"yaw":.6,"pitch":-.2,"third_person":false,"health":31,"magicka":22,"stamina":19,"enemies":[]}
		check(session.restore(entry) and session.area()==id,"Restore routes through correct area entry: "+id)
		await frames(10)
		p.health=31; p.magicka=22; p.stamina=19; p.rotation.y=.6; p.pivot.rotation.x=-.2; p.set_third_person(false)
		var saved: Dictionary=session.capture(); var location: Vector3=p.position
		check(State.valid_session(saved),"Captured session has valid schema: "+id)
		p.position+=Vector3(3,0,0); p.health=1
		check(session.restore(saved) and p.position.distance_to(location)<.1,"Exact grounded position restores: "+id)
		check(p.health==31 and p.magicka==22 and p.stamina==19 and not p.third_person and is_equal_approx(p.rotation.y,.6),"Resources and camera restore: "+id)
	var target: CharacterBody3D=world.realms.enemies[3]
	target.health=27
	var active: Dictionary=session.capture()
	target.health=target.maximum_health
	check(session.restore(active) and target.health==27,"Surviving enemy health restores")
	check(s.save_to("user://session-roundtrip.json"),"Session and character save in one file")
	var loaded:=State.new()
	check(loaded.load_from("user://session-roundtrip.json") and loaded.session.area=="crucible" and loaded.session.health==p.health,"Session round-trips with campaign progress")
	var data: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("user://session-roundtrip.json"))
	for issue in ["area","position","resource","camera","duplicate","enemy_health"]:
		var bad: Dictionary=data.duplicate(true)
		match issue:
			"area": bad.session.area="missing"
			"position": bad.session.position=[1,2]
			"resource": bad.session.health=-1
			"camera": bad.session.third_person="false"
			"duplicate": bad.session.enemies.append(bad.session.enemies[0])
			"enemy_health": bad.session.enemies[0].health="oops"
		var file:=FileAccess.open("user://session-invalid.json",FileAccess.WRITE); file.store_string(JSON.stringify(bad)); file.close()
		check(not loaded.load_from("user://session-invalid.json") and loaded.session.area=="crucible","Malformed session rejected before applying state: "+issue)
	data.erase("session")
	var file:=FileAccess.open("user://session-invalid.json",FileAccess.WRITE); file.store_string(JSON.stringify(data)); file.close()
	check(loaded.load_from("user://session-invalid.json") and loaded.session.is_empty(),"Older saves receive normal starting location")
	var unsafe: Dictionary=active.duplicate(true); unsafe.position=[1600,-30,0]
	check(session.restore(unsafe) and p.position.y>=0,"Falling save falls back to authored entrance")
	unsafe.position=[1600,0,-40]
	check(session.restore(unsafe) and session.supported_position(p.position,p),"Obstructed save retains a supported position")
	unsafe.area="winter"; s.story_completed.erase("returning_light")
	check(not session.restore(unsafe) and session.area()=="home","Unavailable area falls back without bypassing story gates")
	p.health=0; check(session.capture().is_empty(),"A death transition cannot save a dead player spawn")
	check(not State.valid_session({"area":"home"}),"Incomplete session records are rejected")
	for path in ["user://session-roundtrip.json","user://session-invalid.json"]: DirAccess.remove_absolute(path)
	world.queue_free(); await process_frame
	print("SESSION_COMPLETE checks=%d failures=%d" % [checks,failures]); quit(1 if failures else 0)
