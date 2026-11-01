extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var world: Node3D=load("res://scenes/main.tscn").instantiate(); root.add_child(world); world.capture_done=true
	assert(not world.player.character.persist)
	var a: Node=world.audio
	var recorder:=AudioEffectRecord.new(); recorder.format=AudioStreamWAV.FORMAT_16_BITS
	AudioServer.add_bus_effect(0,recorder)
	recorder.set_recording_active(true)
	await create_timer(3).timeout
	a.sfx("enchant")
	await create_timer(1).timeout
	recorder.set_recording_active(false)
	var recorded: AudioStreamWAV=recorder.get_recording()
	assert(recorded.data.size()>1000)
	var peak:=0
	for i in range(0,recorded.data.size(),2): peak=maxi(peak,absi(recorded.data.decode_s16(i)))
	assert(peak>100)
	recorded.save_to_wav("res://build/audio-engine-check.wav")
	AudioServer.remove_bus_effect(0,0)
	world.player.set_paused(true)
	for i in range(12): await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://build/audio-settings.png")
	print("AUDIO_RENDER_COMPLETE engine_peak=%d track=%s" % [peak,a.current_track])
	world.queue_free(); await process_frame; quit()
