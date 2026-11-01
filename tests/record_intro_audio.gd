extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var w=load("res://scenes/main.tscn").instantiate(); root.add_child(w); w.capture_done=true
	# This verifies the native audio mixer, not scene rendering performance.
	RenderingServer.render_loop_enabled=false
	for i in range(8): await physics_frame
	var p=w.player; var a=w.audio
	assert(not p.character.persist and not w.atlas.persist)
	p.set_physics_process(false); p.set_process_unhandled_input(false)
	a.enabled=true; a.master_volume=.7; a.music_volume=.65; a.effects_volume=.8; a.apply_volumes()
	var started: bool=w.intro.start(); assert(started); p.position=w.intro.ORIGIN+Vector3(0,.1,-2)
	var recorder=AudioEffectRecord.new(); recorder.format=AudioStreamWAV.FORMAT_16_BITS
	var index: int=AudioServer.get_bus_effect_count(0); AudioServer.add_bus_effect(0,recorder)
	recorder.set_recording_active(true)
	await create_timer(2.2).timeout
	assert(a.current_track=="intro")
	var revealed: bool=w.intro.interact(); assert(revealed)
	await create_timer(8.3).timeout
	assert(w.intro.stage==2)
	w.intro.finish()
	await create_timer(2.2).timeout
	assert(a.current_track=="wander")
	recorder.set_recording_active(false)
	var recording: AudioStreamWAV=recorder.get_recording(); var peak:=0
	var samples: PackedByteArray=recording.data
	for i in range(0,samples.size(),2): peak=maxi(peak,absi(samples.decode_s16(i)))
	assert(recording.get_length()>12 and peak>100 and peak<32767)
	assert(recording.save_to_wav("res://build/intro-audio-engine.wav")==OK)
	AudioServer.remove_bus_effect(0,index)
	print("INTRO_AUDIO_RECORD_COMPLETE seconds=%.2f peak=%d" % [recording.get_length(),peak])
	w.queue_free(); await process_frame; quit()
