extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var w=load("res://scenes/main.tscn").instantiate(); root.add_child(w); w.capture_done=true
	RenderingServer.render_loop_enabled=false
	for i in range(8): await physics_frame
	var p=w.player; var a=w.audio; var r=w.realms; var t=w.threshold
	assert(not p.character.persist and not w.atlas.persist)
	p.set_process(false); p.set_physics_process(false); p.set_process_unhandled_input(false)
	for e in r.enemies+t.enemies: e.set_physics_process(false)
	p.character.threshold.power=true; p.character.threshold.air=true
	p.character.equip(p.character.add_item("iron_sword"),"main_hand")
	a.enabled=true; a.master_volume=.7; a.music_volume=0; a.effects_volume=.8; a.apply_volumes()
	var recorder=AudioEffectRecord.new(); recorder.format=AudioStreamWAV.FORMAT_16_BITS
	var index: int=AudioServer.get_bus_effect_count(0); AudioServer.add_bus_effect(0,recorder)
	recorder.set_recording_active(true)
	await create_timer(.2).timeout
	for e in [t.enemies[5],r.enemies[2],r.enemies[5]]:
		t.inside=e.adventure==t; r.inside=e.adventure==r
		if r.inside: r.current="aeralis" if e==r.enemies[2] else "crucible"
		e.health=5; p.position=e.global_position+Vector3.BACK*2; p.rotation=Vector3.ZERO
		a.cooldowns.clear(); assert(p.activate_finisher())
		await create_timer(.5).timeout
		p.update_finisher(.51); assert(e.dead)
		await create_timer(1.2).timeout
		p.cancel_finisher()
	recorder.set_recording_active(false)
	var recording: AudioStreamWAV=recorder.get_recording(); var peak:=0
	var samples: PackedByteArray=recording.data
	for i in range(0,samples.size(),2): peak=maxi(peak,absi(samples.decode_s16(i)))
	assert(recording.get_length()>5 and peak>100 and peak<32767)
	assert(recording.save_to_wav("res://build/finisher-audio-engine.wav")==OK)
	AudioServer.remove_bus_effect(0,index)
	print("FINISHER_AUDIO_RECORD_COMPLETE seconds=%.2f peak=%d" % [recording.get_length(),peak])
	w.queue_free(); await process_frame; quit()
