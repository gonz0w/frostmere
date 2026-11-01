extends SceneTree
const State=preload("res://scripts/character_state.gd")
func _initialize() -> void: call_deferred("run")
func run() -> void:
	assert(OS.get_user_data_dir().ends_with("SkyrimCraft-Session-QA"))
	var preparing: bool="--save-session-fixture" in OS.get_cmdline_user_args()
	if preparing:
		var seed=State.new(); seed.intro_completed=true; assert(seed.save_to(State.SAVE_PATH))
	var world: Node3D=load("res://scenes/main.tscn").instantiate(); root.add_child(world); world.capture_done=true; world.audio.enabled=false
	world.player.set_physics_process(false); world.player.set_process_unhandled_input(false); Input.mouse_mode=Input.MOUSE_MODE_VISIBLE
	for i in range(10): await physics_frame
	var p: CharacterBody3D=world.player; var s=p.character
	assert(s.persist and world.session_save.ready_to_save)
	for e in world.wilderness.enemies+world.mountain.enemies: e.set_physics_process(false)
	if preparing:
		p.set_paused(false)
		var uid: String=s.add_item("iron_sword"); s.equip(uid,"main_hand"); s.inventory[uid].favorite=true
		for mat in s.crafting.materials: s.materials[mat.id]=1000
		assert(s.improve(uid,"forge").begins_with("Improved"))
		var wolf=world.wilderness.enemies[0]; p.position=wolf.global_position+Vector3.BACK
		wolf.receive_damage(1000,p,"","melee"); assert(world.wilderness.loot())
		s.story_completed.append("stonewake"); assert(world.mountain.enter())
		p.rotation.y=.75; p.pivot.rotation.x=-.2; p.set_third_person(false)
		p.set_paused(true); p.health=43; p.magicka=27; p.stamina=18
		assert(world.session_save.save_now())
		var expected: Dictionary={"session":s.session,"inventory":s.inventory,"equipment":s.equipment,"materials":s.materials,"gold":s.gold,"wilderness":s.wilderness}
		var f=FileAccess.open("user://expected-session.json",FileAccess.WRITE); f.store_string(JSON.stringify(expected)); f.close()
		# Simulate interruption before the temporary file replaces the valid primary save.
		f=FileAccess.open(State.SAVE_PATH+".tmp",FileAccess.WRITE); f.store_string('{"version":2,"inventory":'); f.close()
		print("SESSION_BOOT_SAVED_WITH_ABANDONED_TMP")
	else:
		p.set_paused(true)
		var expected: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("user://expected-session.json"))
		assert(FileAccess.file_exists(State.SAVE_PATH+".tmp"))
		assert(world.session_save.area()=="mountain")
		assert(p.position.distance_to(world.session_save.vector(expected.session.position))<.1)
		assert(p.health==43 and absf(p.magicka-27)<3 and absf(p.stamina-18)<5)
		assert(not p.third_person and is_equal_approx(p.rotation.y,.75))
		assert(JSON.parse_string(JSON.stringify(s.inventory))==expected.inventory)
		assert(s.equipment==expected.equipment)
		assert(JSON.parse_string(JSON.stringify(s.materials))==expected.materials and s.gold==expected.gold)
		assert(s.wilderness==expected.wilderness and world.wilderness.enemies[0].dead and not world.wilderness.enemies[0].label.visible)
		assert(world.session_save.save_now() and not FileAccess.file_exists(State.SAVE_PATH+".tmp"))
		print("SESSION_BOOT_RESTORED_AND_TMP_REPLACED")
	world.queue_free(); await process_frame; quit()
