extends "res://tools/benchmark_regions.gd"
const SHOTS=preload("res://tests/render_landscape_review.gd").VIEWS
func run() -> void:
	assert(DisplayServer.get_name()!="headless" and "--capture" in OS.get_cmdline_user_args())
	root.size=Vector2i(1280,800)
	var w=load("res://scenes/main.tscn").instantiate(); root.add_child(w); w.capture_done=true; w.audio.enabled=false
	for i in range(8): await physics_frame
	assert(not w.player.character.persist and not w.atlas.persist)
	w.player.set_physics_process(false); w.player.set_process_unhandled_input(false); w.player.hide()
	for id in w.atlas.quests:
		if id not in w.player.character.story_completed: w.player.character.story_completed.append(id)
	var camera=Camera3D.new(); root.add_child(camera); camera.current=true; camera.fov=68; camera.far=450
	var report={"gpu":RenderingServer.get_video_adapter_name(),"engine":Engine.get_version_info().string,"viewport":str(root.size),"blocks":w.block_count,"samples":{},"method":"M5 native Metal Mobile, 1280x800, 450 m gameplay draw distance, 68 degree review-camera FOV. 2 s warmup then 5 s camera motion at each viewpoint, live idle game logic, player movement/input disabled and audio silent. Single current-build run; no baseline comparison, combat or M1 claim."}
	var active: String="frostmere"
	for index in [0,3,6,8,12,14,16,18,20,22,24,25]:
		var v: Array=SHOTS[index]; var id: String=v[0]
		if id!=active:
			if active in ["aeralis","crucible"]: w.realms.leave()
			elif active!="frostmere": w.get(active).leave()
			if id in ["aeralis","crucible"]: assert(w.realms.enter(id,true))
			elif id!="frostmere": assert(w.get(id).enter())
			active=id
		w.hud.notice_time=0
		var motion=func(t: float):
			camera.position=v[2]+Vector3(sin(t*.45)*1.4,0,cos(t*.45)*.5)
			camera.look_at(v[3])
		var result=await sample(camera,Vector3.ZERO,v[2],v[3],motion,5)
		report.samples[id]=result; print("LANDSCAPE_SAMPLE "+id+" "+JSON.stringify(result))
	var f=FileAccess.open("res://build/landscape-review/performance.json",FileAccess.WRITE); f.store_string(JSON.stringify(report,"\t")); f.close()
	print("LANDSCAPE_BENCHMARK_COMPLETE"); quit()
