extends SceneTree
# Run natively with -- --capture. Fixed views, idle game logic, isolated saves.
func _initialize() -> void: call_deferred("run")
func sample(camera: Camera3D, origin: Vector3, eye: Vector3, target: Vector3, animate: Callable = Callable(), seconds: float = 5.0) -> Dictionary:
	camera.position=origin+eye; camera.look_at(origin+target)
	var warmup:=Time.get_ticks_usec()
	while Time.get_ticks_usec()-warmup<2000000:
		if animate.is_valid(): animate.call((Time.get_ticks_usec()-warmup)/1000000.0)
		await process_frame
	var times: Array[float]=[]
	var cpu: Array[float]=[]
	var started:=Time.get_ticks_usec(); var previous:=started
	while Time.get_ticks_usec()-started<int(seconds*1000000):
		if animate.is_valid(): animate.call((Time.get_ticks_usec()-warmup)/1000000.0)
		await process_frame
		var now:=Time.get_ticks_usec()
		times.append((now-previous)/1000.0); previous=now
		cpu.append(Performance.get_monitor(Performance.TIME_PROCESS)*1000)
	times.sort(); cpu.sort()
	assert(times.size()>10)
	return {"frames":times.size(),"median_ms":times[times.size()/2],"p95_ms":times[mini(times.size()-1,ceili(times.size()*.95)-1)],"p99_ms":times[mini(times.size()-1,ceili(times.size()*.99)-1)],"process_median_ms":cpu[cpu.size()/2],"static_memory_mib":Performance.get_monitor(Performance.MEMORY_STATIC)/1048576.0,"draw_calls":Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)}
func run() -> void:
	assert(DisplayServer.get_name()!="headless","Use native rendering for frame measurements")
	assert("--capture" in OS.get_cmdline_user_args(),"Use isolated capture mode")
	var w=load("res://scenes/main.tscn").instantiate(); root.add_child(w); w.capture_done=true; w.audio.enabled=false
	for i in range(8): await physics_frame
	var p=w.player
	assert(not p.character.persist and not w.atlas.persist)
	p.set_physics_process(false); p.set_process_unhandled_input(false); p.avatar.hide(); p.first_person_hands.hide()
	p.character.story_completed.append("stonewake")
	var camera=Camera3D.new(); w.add_child(camera); camera.current=true
	var report: Dictionary={"gpu":RenderingServer.get_video_adapter_name(),"engine":Engine.get_version_info().string,"renderer":RenderingServer.get_current_rendering_method(),"driver":RenderingServer.get_current_rendering_driver_name(),"viewport":str(root.size),"vsync":DisplayServer.window_get_vsync_mode(),"blocks":w.block_count,"samples":{},"method":"Each fixed view: 2 s warmup, 5 s wall-clock frame intervals. Idle world logic, player movement/input disabled, audio silent. One development-build run; not a moving/combat or M1 benchmark. Static memory is Godot allocator usage, not total process RAM or VRAM."}
	for region in ["frostmere","pinehall","wyrmkeep"]:
		var result: Dictionary
		if region=="frostmere": result=await sample(camera,Vector3.ZERO,Vector3(24,6,25),Vector3(0,2,-8))
		elif region=="pinehall":
			assert(w.archive_chapter.enter()); w.hud.notice_time=0
			result=await sample(camera,w.archive_chapter.ORIGIN,Vector3(25,3,-43),Vector3(36,6,-58))
		else:
			w.archive_chapter.leave(); assert(w.mountain.enter()); w.hud.notice_time=0
			result=await sample(camera,w.mountain.ORIGIN,Vector3(30,3,48),Vector3(40,3,30))
		report.samples[region]=result
		print("REGION_SAMPLE "+region+" "+JSON.stringify(result))
	var output=FileAccess.open("res://build/region-performance.json",FileAccess.WRITE); assert(output!=null); output.store_string(JSON.stringify(report,"\t")); output.close()
	print("REGION_BENCHMARK_COMPLETE "+JSON.stringify(report)); w.queue_free(); await process_frame; quit()
