extends "res://tools/benchmark_regions.gd"
func run() -> void:
	assert(DisplayServer.get_name()!="headless" and "--capture" in OS.get_cmdline_user_args())
	var w=load("res://scenes/main.tscn").instantiate(); root.add_child(w); w.capture_done=true; w.audio.enabled=false
	for i in range(8): await physics_frame
	assert(not w.player.character.persist and not w.atlas.persist)
	w.player.set_physics_process(false); w.player.set_process_unhandled_input(false); w.player.hide()
	var camera=Camera3D.new(); w.add_child(camera); camera.current=true
	var report={"gpu":RenderingServer.get_video_adapter_name(),"engine":Engine.get_version_info().string,"renderer":RenderingServer.get_current_rendering_method(),"viewport":str(root.size),"vsync":DisplayServer.window_get_vsync_mode(),"blocks":w.block_count,"samples":{},"method":"Fixed architectural views; 2 s warmup then 5 s wall-clock frame intervals per view. Idle game logic, normal shadows, silent audio, player input disabled. Single M5 development run. Not a before/after comparison, moving/combat benchmark, or M1 sign-off."}
	for shot in [["frostmere_street",Vector3(-1,2.2,17),Vector3(-7,4,-9)],["outfitter_interior",Vector3(-8.4,1.9,-4.5),Vector3(-10.25,1.5,-10.5)],["wyrmkeep_halls",Vector3(805,6,12),Vector3(800,6,-24)],["pinehall_houses",Vector3(-799,4,31),Vector3(-800,4,1)]]:
		w.player.position=shot[1]
		var result=await sample(camera,Vector3.ZERO,shot[1],shot[2])
		report.samples[shot[0]]=result; print("BUILDING_SAMPLE "+shot[0]+" "+JSON.stringify(result))
	var file=FileAccess.open("res://build/building-review/performance.json",FileAccess.WRITE); file.store_string(JSON.stringify(report,"\t")); file.close()
	print("BUILDING_BENCHMARK_COMPLETE"); quit()
