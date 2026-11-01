extends "res://tools/benchmark_regions.gd"
var report_path := "res://build/visual-polish-performance.json"
func log_summary(value: Dictionary) -> String:
	var compact := value.duplicate(true)
	compact.erase("trace")
	for group in ["samples", "warm_samples"]:
		for entry in compact.get(group, {}).values(): entry.erase("trace")
	return JSON.stringify(compact)
func run() -> void:
	assert(DisplayServer.get_name()!="headless" and "--capture" in OS.get_cmdline_user_args())
	var w=load("res://scenes/main.tscn").instantiate(); root.add_child(w); w.capture_done=true; w.audio.enabled=false
	for i in range(8): await physics_frame
	var p=w.player
	assert(not p.character.persist and not w.atlas.persist)
	p.set_physics_process(false); p.set_process_unhandled_input(false); p.set_third_person(true)
	var camera=Camera3D.new(); w.add_child(camera); camera.current=true; camera.far=450
	var report: Dictionary={"gpu":RenderingServer.get_video_adapter_name(),"engine":Engine.get_version_info().string,"renderer":RenderingServer.get_current_rendering_method(),"driver":RenderingServer.get_current_rendering_driver_name(),"viewport":str(root.size),"vsync":DisplayServer.window_get_vsync_mode(),"blocks":w.block_count,"samples":{},"warm_samples":{},"method":"Each scenario runs twice with the same camera path, 2 s warmup each: 8 s scripted moving cameras for river and village, 12 s Rimefang AI against stationary invulnerable player. First and repeat samples both retained; repeat is not an optimization claim. Normal world/HUD logic; silent audio. Wall-clock frame intervals. Static memory is Godot allocator usage, not RSS/VRAM. 450 m gameplay draw distance. One M5 development run, not M1 or a human playtest."}
	p.position=Vector3(0,.3,12)
	var river:=func(t: float):
		camera.position=Vector3(12+sin(t*.25)*2,2.5,-10+t*.8)
		camera.look_at(Vector3(21,1,2))
	report.samples.river_moving=await sample(camera,Vector3.ZERO,Vector3(12,2.5,-10),Vector3(21,1,2),river,8)
	print("POLISH_SAMPLE river "+log_summary(report.samples.river_moving))
	report.warm_samples.river_moving=await sample(camera,Vector3.ZERO,Vector3(12,2.5,-10),Vector3(21,1,2),river,8)
	var village:=func(t: float):
		camera.position=Vector3(-5,2,3-t*.35)
		camera.look_at(Vector3(-10,2,-7))
	report.samples.village_moving=await sample(camera,Vector3.ZERO,Vector3(-5,2,3),Vector3(-10,2,-7),village,8)
	print("POLISH_SAMPLE village "+log_summary(report.samples.village_moving))
	report.warm_samples.village_moving=await sample(camera,Vector3.ZERO,Vector3(-5,2,3),Vector3(-10,2,-7),village,8)
	var e=w.wilderness.enemies[12]; p.position=e.home+Vector3.BACK*8; p.invulnerable=1000; e.charge_cooldown=0
	var phases={"warnings":0,"charges":0,"warning_before":false,"charge_before":false}
	var combat:=func(t: float):
		if e.charge_warning>0 and not phases.warning_before: phases.warnings+=1
		if e.charge_remaining>0 and not phases.charge_before: phases.charges+=1
		phases.warning_before=e.charge_warning>0; phases.charge_before=e.charge_remaining>0
		camera.position=e.global_position+Vector3(sin(t*.25)*7,3,cos(t*.25)*7)
		camera.look_at(e.global_position+Vector3.UP*1.8)
	report.samples.rimefang_active=await sample(camera,Vector3.ZERO,e.position+Vector3(0,3,7),e.position+Vector3.UP*1.8,combat,12)
	assert(phases.warnings>=1 and phases.charges>=1 and not e.dead)
	report["observed_charge_phases"]=phases.duplicate()
	e.cancel_charge(); e.position=e.home; e.charge_cooldown=0; e.stagger_time=0; e.windup=0; p.position=e.home+Vector3.BACK*8
	phases.warnings=0; phases.charges=0; phases.warning_before=false; phases.charge_before=false
	report.warm_samples.rimefang_active=await sample(camera,Vector3.ZERO,e.position+Vector3(0,3,7),e.position+Vector3.UP*1.8,combat,12)
	assert(phases.warnings>=1 and phases.charges>=1 and not e.dead)
	report["repeat_charge_phases"]=phases
	var output=FileAccess.open(report_path,FileAccess.WRITE); assert(output!=null); output.store_string(JSON.stringify(report,"\t")); output.close()
	print("VISUAL_POLISH_BENCHMARK_COMPLETE "+log_summary(report)); w.queue_free(); await process_frame; quit()
