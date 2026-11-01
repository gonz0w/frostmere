extends "res://tools/benchmark_regions.gd"
func run() -> void:
	assert(DisplayServer.get_name()!="headless" and "--capture" in OS.get_cmdline_user_args())
	var w=load("res://scenes/main.tscn").instantiate(); root.add_child(w); w.capture_done=true; w.audio.enabled=false
	for i in range(8): await physics_frame
	var p=w.player; assert(not p.character.persist and not w.atlas.persist)
	p.set_physics_process(false); p.set_process_unhandled_input(false); p.set_third_person(true); p.invulnerable=1000
	var camera=Camera3D.new(); w.add_child(camera); camera.current=true; camera.far=450
	var report={"gpu":RenderingServer.get_video_adapter_name(),"engine":Engine.get_version_info().string,"renderer":RenderingServer.get_current_rendering_method(),"viewport":str(root.size),"vsync":DisplayServer.window_get_vsync_mode(),"samples":{},"method":"Current refined realm bosses, 450 m gameplay draw distance, 2 s warmup and 8 s orbit per realm. Real AI versus stationary invulnerable player, no player attacks, audio silent, isolated saves. Wall-clock intervals; not before/after, M1, crowd or full playtest evidence. Draw calls are the final frame, memory is Godot allocator usage."}
	for id in ["aeralis","crucible"]:
		assert(w.realms.enter(id,true))
		var e=w.realms.enemies[2 if id=="aeralis" else 5]
		p.position=e.global_position+Vector3.BACK*8; e.cooldown=0
		var observed={"windups":0,"was_winding":false}
		var orbit:=func(t: float):
			if e.windup>0 and not observed.was_winding: observed.windups+=1
			observed.was_winding=e.windup>0
			camera.position=e.global_position+Vector3(sin(t*.2)*8,3,cos(t*.2)*8)
			camera.look_at(e.global_position+Vector3.UP*1.8)
		var result=await sample(camera,Vector3.ZERO,e.global_position+Vector3(0,3,8),e.global_position+Vector3.UP*1.8,orbit,8)
		assert(observed.windups>=1 and not e.dead)
		result["observed_windups"]=observed.windups; report.samples[id]=result
	var output=FileAccess.open("res://build/presentation-review/realm-boss-performance.json",FileAccess.WRITE); assert(output!=null); output.store_string(JSON.stringify(report,"\t")); output.close()
	print("REFINED_REALM_BOSS_BENCHMARK_COMPLETE "+JSON.stringify(report)); w.queue_free(); await process_frame; quit()
