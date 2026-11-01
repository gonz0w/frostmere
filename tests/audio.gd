extends SceneTree
var checks:=0
var failures:=0
func _initialize() -> void: call_deferred("run")
func check(ok: bool, label: String) -> void:
	checks+=1
	if ok: print("PASS "+label)
	else: failures+=1; push_error("FAIL "+label)
func run() -> void:
	var world: Node3D=load("res://scenes/main.tscn").instantiate(); root.add_child(world)
	await physics_frame
	var a: Node=world.audio
	a.set_process(false)
	check(not world.player.character.persist,"Audio fixture uses isolated character")
	check(a.streams.size()==41,"Nine scores and thirty-two effects load")
	var manifest: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/audio/manifest.json"))
	for id in a.TRACKS:
		var stream: AudioStreamWAV=a.streams[id]
		var loop_seconds: float = float(stream.loop_end - stream.loop_begin) / stream.mix_rate
		check(stream.stereo and stream.loop_mode==AudioStreamWAV.LOOP_FORWARD and stream.loop_begin==0 and absf(loop_seconds-float(manifest[id].seconds))<.05 and absf(stream.get_length()-float(manifest[id].seconds))<.05,"Full stereo loop matches authored duration: "+id)
	for place in ["north","aeralis","crucible","station"]:
		check(a.choose_track(place,false)!=a.choose_track(place,true),"Distinct exploration and battle cues: "+place)
	check(a.zone()=="north","Home world starts with Nordic music")
	a.transition("wander"); var slot: int=a.active
	a.transition("wander"); check(a.active==slot,"Repeated state does not restart music")
	a.transition("battle"); check(a.active!=slot and a.fade==0,"Track change begins crossfade on second voice")
	a._process(2.1); check(a.fade==1,"Fade reaches a stable endpoint")
	a.cooldowns.clear(); a.sfx("hit"); var count: int=a.effect_count
	a.sfx("hit"); check(a.effect_count==count,"Repeated impact sounds are rate limited")
	a._process(.2); a.sfx("hit"); check(a.effect_count==count+1,"Impact voice becomes available after cooldown")
	a.sfx("missing"); check(a.effect_count==count+1,"Unknown cues cannot consume voices")
	check(a.voices.size()==12 and a.music.size()==2,"Voice allocation is bounded")
	var sliders: Array = world.hud.pause_panel.find_children("*", "HSlider", true, false)
	check(sliders.size()==3,"Pause menu exposes master, music and effects controls")
	sliders[1].value=0.42
	check(is_equal_approx(a.music_volume,0.42),"Music slider controls its own bus")
	a.cooldowns.clear(); world.hud.workshop.result("Equipped.")
	check(a.last_effect=="interact","Successful equipment change uses a confirmation cue")
	var save_before: String=FileAccess.get_file_as_string(a.SETTINGS) if FileAccess.file_exists(a.SETTINGS) else ""
	a.set_volume("music",-1); check(a.music_volume==0 and AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Music"))<=-80,"Music can be muted independently")
	a.set_volume("effects",2); check(a.effects_volume==1,"Volume input is clamped")
	var save_after: String=FileAccess.get_file_as_string(a.SETTINGS) if FileAccess.file_exists(a.SETTINGS) else ""
	check(save_before==save_after,"Preview volume changes do not overwrite saved preferences")
	world.adventure.enter(); world.player.set_paused(false)
	for e in world.adventure.enemies: e.set_physics_process(false)
	var enemy: CharacterBody3D=world.adventure.enemies[0]
	enemy.position=Vector3(0,0.05,0)
	world.player.global_position=enemy.global_position+Vector3(0,0,3)
	await physics_frame
	a.scan_time=0; a._process(.25)
	check(a.combat_hold>0 and a.current_track=="battle","Visible engaged enemy selects battle music")
	world.player.set_paused(true); var hold: float=a.combat_hold; a._process(1)
	check(a.combat_hold==hold,"Menus freeze combat release timer")
	world.player.set_paused(false); world.adventure.leave(); world.player.position=Vector3.ZERO; a._process(6.1)
	check(a.current_track=="wander","Leaving combat returns to exploration after release delay")
	for id in ["aeralis","crucible"]:
		check(world.realms.enter(id,true),"Isolated realm entry: "+id)
		a._process(0); check(a.zone()==id and a.current_track==id,"Realm entry switches its soundtrack: "+id)
		a.engage(); a._process(0); check(a.current_track==id+"_battle","Realm battle keeps its musical identity: "+id)
		world.realms.leave(); a._process(0)
	world.queue_free(); await process_frame
	print("AUDIO_COMPLETE checks=%d failures=%d" % [checks,failures]); quit(1 if failures else 0)
