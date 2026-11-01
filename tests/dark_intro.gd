extends SceneTree
const State=preload("res://scripts/character_state.gd")
var checks:=0
var failures:=0
func _initialize() -> void: call_deferred("run")
func check(ok: bool,label: String) -> void:
	checks+=1
	if ok: print("PASS "+label)
	else: failures+=1; push_error("FAIL "+label)
func run() -> void:
	var w=load("res://scenes/main.tscn").instantiate(); root.add_child(w)
	for i in range(6): await physics_frame
	var p=w.player; var intro=w.intro; var state=p.character
	p.set_physics_process(false); intro.set_process(false)
	check(not state.persist and not intro.active,"Automated QA does not auto-start or persist opening")
	var env=p.camera.environment
	check(intro.start() and not intro.start(),"New character starts opening exactly once")
	for i in range(3): await physics_frame
	check(w.session_save.supported_position(p.position,p),"Opening spawn has walkable collision support")
	var route_clear:=true
	for z in range(-13,9):
		if not w.session_save.supported_position(intro.ORIGIN+Vector3(1.3,.1,z),p): route_clear=false
	check(route_clear,"Walkable route passes lantern and reaches the arch")
	check(w.audio.zone()=="intro" and w.audio.choose_track("intro",true)=="intro","Opening uses its own score regardless of combat meter")
	check(not intro.interact(),"Lantern cannot be activated from the starting point")
	check(w.session_save.capture().is_empty(),"Interrupted opening does not save off-map coordinates")
	p.position=intro.ORIGIN+Vector3(0,.1,-2)
	check(w.interaction_prompt().contains("lantern"),"Lantern instruction reaches the ordinary HUD")
	w.interact_nearby()
	check(intro.stage==1 and intro.creature.visible,"Actual interaction reveals enormous ward-side shape")
	check(w.audio.last_effect=="ward_approach","Lantern reveal starts its dedicated low ward cue")
	var cue: AudioStreamPlayer=w.audio.voices[0]
	cue.stream=w.audio.streams.ward_approach; cue.play()
	p.set_paused(true); intro.advance(10)
	check(intro.stage==1 and intro.reveal_time==0,"Menus freeze reveal")
	check(cue.stream_paused,"Pause freezes the reveal cue with the creature")
	p.set_paused(false); intro.advance(3)
	check(not cue.stream_paused,"Resume releases the reveal cue")
	var near_pose: Vector3=intro.creature.position
	var head_pose: Vector3=intro.head.rotation
	check(near_pose.z > -30 and intro.jaw.rotation.x>0,"Creature approaches and opens articulated jaw")
	p.set_paused(true); intro.advance(3)
	check(intro.creature.position==near_pose and intro.head.rotation==head_pose,"Menus freeze creature choreography")
	p.set_paused(false); intro.advance(3)
	check(intro.creature.position.z<near_pose.z and intro.creature.position.y<0 and intro.creature.visible,"Creature withdraws into fog before disappearing")
	intro.advance(2)
	check(intro.stage==2 and not intro.creature.visible,"Reveal completes and unlocks road interaction")
	check(w.audio.last_effect=="ward_holds","Retreat resolves with the ward-holds cue")
	var cue_count: int=w.audio.effect_count
	intro.advance(.1)
	check(w.audio.effect_count==cue_count,"Completed reveal cannot repeat its resolution sound")
	check(not intro.interact(),"Road transition requires reaching the arch")
	p.position=intro.ORIGIN+Vector3(0,.1,-13)
	check(intro.interact() and not intro.active and state.intro_completed,"Arch completes opening")
	check(not cue.playing and not cue.stream_paused,"Village handoff clears opening cues")
	check(p.position==p.spawn_point and p.camera.environment==env and is_equal_approx(intro.sun.light_energy,intro.sun_energy),"Return restores village location, environment and sunlight")
	check(not state.adventure.accepted and state.story_completed.is_empty(),"Opening leaves first quest and later realm gates intact")
	check(not intro.start() and w.audio.zone()=="north","Completed opening stays bypassed and Nordic score resumes")
	intro.advance(.3)
	check(intro.arrival_cover.color.a>0 and intro.arrival_cover.color.a<1,"Village arrival fades into view")
	p.set_paused(true); var fade_time: float=intro.arrival_time; intro.advance(2)
	check(intro.arrival_time==fade_time and not intro.arrival.visible,"Pause freezes arrival fade and leaves menus visible")
	p.set_paused(false); intro.advance(1)
	check(intro.arrival==null,"Arrival overlay is removed after fade")
	var path="user://dark-intro-test.json"
	for suffix in ["", ".tmp", ".bak", ".bak.tmp"]: DirAccess.remove_absolute(path+suffix)
	check(state.save_to(path),"Completed opening saves")
	var loaded=State.new()
	check(loaded.load_from(path) and loaded.intro_completed,"Completion round-trips")
	var data: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(path))
	data.erase("intro_completed"); write(path,data)
	check(loaded.load_from(path) and loaded.intro_completed,"Legacy profiles bypass opening")
	data.intro_completed="yes"; write(path,data)
	check(not loaded.load_from(path),"Malformed opening flag is rejected")
	# Restore the valid fixture; ordinary saves must not overwrite rejected primary data.
	data.intro_completed=true; write(path,data)
	state.intro_completed=false; intro.start()
	var event:=InputEventKey.new(); event.physical_keycode=KEY_TAB; event.pressed=true
	intro._unhandled_input(event)
	check(not intro.active and state.intro_completed,"Tab skips opening and records completion")
	state.intro_completed=false; intro.start(); p.position=intro.ORIGIN+Vector3(3,-5,2); p.respawn()
	check(intro.active and p.position==intro.ORIGIN+Vector3(0,.1,8),"Return key recovers within opening")
	check(state.save_to(path) and loaded.load_from(path) and not loaded.intro_completed and loaded.session.is_empty(),"Incomplete opening saves safely for restart")
	intro.finish()
	for suffix in ["", ".tmp", ".bak", ".bak.tmp"]: DirAccess.remove_absolute(path+suffix)
	w.queue_free(); await process_frame
	print("DARK_INTRO_COMPLETE checks=%d failures=%d" % [checks,failures]); quit(1 if failures else 0)
func write(path: String,data: Dictionary) -> void:
	var f:=FileAccess.open(path,FileAccess.WRITE); f.store_string(JSON.stringify(data)); f.close()
