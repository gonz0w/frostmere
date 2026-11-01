extends "res://tools/benchmark_regions.gd"
func run() -> void:
	assert(DisplayServer.get_name()!="headless" and "--capture" in OS.get_cmdline_user_args())
	var w=load("res://scenes/main.tscn").instantiate(); root.add_child(w); w.capture_done=true; w.audio.enabled=false
	for i in range(8): await physics_frame
	var p=w.player
	assert(not p.character.persist and not w.atlas.persist)
	p.set_physics_process(false); p.set_process_unhandled_input(false); p.avatar.hide(); p.first_person_hands.hide()
	p.character.story_completed.append("stonewake")
	var camera=Camera3D.new(); w.add_child(camera); camera.current=true
	var report: Dictionary={"gpu":RenderingServer.get_video_adapter_name(),"engine":Engine.get_version_info().string,"renderer":RenderingServer.get_current_rendering_method(),"driver":RenderingServer.get_current_rendering_driver_name(),"viewport":str(root.size),"vsync":DisplayServer.window_get_vsync_mode(),"blocks":w.block_count,"samples":{},"method":"2 s warmup per scenario. Pinehall: 8 s scripted moving camera, stationary player. Colossus: 12 s orbiting camera, actual enemy AI against a stationary invulnerable target, no player attacks; authored cooldowns retained. Audio silent. Frame intervals use wall clock. Static memory is Godot allocator usage, not RSS/VRAM. One development-build run, not M1 or human gameplay validation."}
	assert(w.archive_chapter.enter()); w.hud.notice_time=0
	var center: Vector3=w.archive_chapter.ORIGIN+Vector3(34,4,-54)
	var moving:=func(t: float):
		camera.position=center+Vector3(sin(t*.45)*6,1,cos(t*.45)*8)
		camera.look_at(center)
	report.samples.pinehall_moving=await sample(camera,Vector3.ZERO,center+Vector3.BACK*8,center,moving,8)
	print("ACTIVITY_SAMPLE pinehall_moving "+JSON.stringify(report.samples.pinehall_moving))
	w.archive_chapter.leave(); p.set_paused(false)
	var e=w.wilderness.enemies[11]; p.position=e.home+Vector3.BACK*4; p.invulnerable=1000; e.slam_cooldown=0
	var impacts: Array[int]=[0]
	w.wilderness.child_entered_tree.connect(func(node):
		if node.get_script()==preload("res://scripts/ground_slam_effect.gd"): impacts[0]+=1)
	var orbit:=func(t: float):
		camera.position=e.global_position+Vector3(sin(t*.35)*8,3,cos(t*.35)*8)
		camera.look_at(e.global_position+Vector3.UP*2)
	report.samples.colossus_active=await sample(camera,Vector3.ZERO,e.global_position+Vector3(0,3,8),e.global_position+Vector3.UP*2,orbit,12)
	report["slam_impacts_including_warmup"]=impacts[0]
	assert(impacts[0]>=2,"Combat scenario must include multiple actual slams")
	assert(not e.dead and not p.paused)
	print("ACTIVITY_SAMPLE colossus_active "+JSON.stringify(report.samples.colossus_active))
	var output=FileAccess.open("res://build/activity-performance.json",FileAccess.WRITE); assert(output!=null); output.store_string(JSON.stringify(report,"\t")); output.close()
	print("ACTIVITY_BENCHMARK_COMPLETE "+JSON.stringify(report)); w.queue_free(); await process_frame; quit()
