extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var w=load("res://scenes/main.tscn").instantiate(); root.add_child(w); w.capture_done=true
	for i in range(5): await physics_frame
	var p=w.player; var a=w.audio; var e=w.adventure.enemies[0]
	assert(not p.character.persist and not w.atlas.persist)
	p.set_physics_process(false); p.set_process_unhandled_input(false); p.set_third_person(false); p.rotation=Vector3.ZERO; p.pivot.rotation=Vector3.ZERO
	for actor in w.combat_enemies(): actor.set_physics_process(false)
	for actor in w.adventure.enemies: actor.set_physics_process(false)
	a.set_process(false); a.enabled=true; a.master_volume=.7; a.effects_volume=.8; a.apply_volumes()
	for music in a.music: music.stop()
	w.adventure.inside=true; p.set_paused(false)
	var recorder:=AudioEffectRecord.new(); recorder.format=AudioStreamWAV.FORMAT_16_BITS; AudioServer.add_bus_effect(0,recorder)
	for side in [-1,1]:
		e.global_position=p.camera.global_position+Vector3(side*6,-1.5,-4)
		a.cooldowns.clear(); recorder.set_recording_active(true); a.warning_at("solar_warning",e)
		await create_timer(1.2).timeout
		recorder.set_recording_active(false)
		recorder.get_recording().save_to_wav("res://build/spatial-"+("left" if side<0 else "right")+".wav")
	AudioServer.remove_bus_effect(0,0)
	print("SPATIAL_RECORD_COMPLETE"); quit()
