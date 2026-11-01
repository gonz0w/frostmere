extends SceneTree
var w: Node3D
func _initialize() -> void: call_deferred("run")
func run() -> void:
	assert(DisplayServer.get_name()!="headless" and "--capture" in OS.get_cmdline_user_args())
	root.size=Vector2i(1280,800)
	w=load("res://scenes/main.tscn").instantiate(); root.add_child(w); w.capture_done=true; w.audio.enabled=false
	for i in range(8): await physics_frame
	var p=w.player; assert(not p.character.persist and not w.atlas.persist)
	p.set_physics_process(true); p.set_process_unhandled_input(false)
	var report={"gpu":RenderingServer.get_video_adapter_name(),"engine":Engine.get_version_info().string,"samples":{},"method":"1280x800, actual player camera and 450 m far plane. Each realm: boss and both adds use real AI around a stationary invulnerable player. 2 s warmup plus 8 s measurement per camera; scripted attacks every .8 s. Enemy health enlarged to retain the group. No manual damage injection; not a balance test, human playthrough, or M1 result."}
	for id in ["aeralis","crucible"]:
		assert(w.realms.enter(id,true)); w.realms.preview_kit(id)
		var group: Array=[]
		for e in w.realms.enemies:
			if e.enemy_id.begins_with(id): group.append(e)
		var boss: CharacterBody3D=group[2]
		for third in [false,true]:
			p.set_third_person(third); p.camera.make_current(); p.rotation=Vector3.ZERO; p.pivot.rotation.x=.03
			p.position=boss.home+Vector3(0,.2,8); p.invulnerable=1000; p.health=p.derived.health
			for i in range(group.size()):
				var e: CharacterBody3D=group[i]; e.health=10000; e.maximum_health=10000; e.global_position=boss.home+Vector3((i-0.5)*7,0,4) if i<2 else boss.home; e.cooldown=0; e.stagger_time=0; e.windup=0
			w.hud.notice_time=0
			var start:=Time.get_ticks_usec(); var previous:=start
			var times: Array[float]=[]; var warnings: Dictionary={}; var last: Dictionary={}; var attacks:=0; var next_attack:=0.0
			while Time.get_ticks_usec()-start<10000000:
				var elapsed: float=(Time.get_ticks_usec()-start)/1000000.0
				if elapsed>=next_attack:
					if p.attack(): attacks+=1
					next_attack=elapsed+.8
				for e in group:
					if e.windup>0 and not last.get(e.enemy_id,false): warnings[e.enemy_id]=int(warnings.get(e.enemy_id,0))+1
					last[e.enemy_id]=e.windup>0
				await process_frame
				var now:=Time.get_ticks_usec()
				if elapsed>=2: times.append((now-previous)/1000.0)
				previous=now
			assert(times.size()>100 and warnings.size()>=2 and attacks>0)
			times.sort()
			var key: String=id+("_third" if third else "_first")
			report.samples[key]={"frames":times.size(),"median_ms":times[times.size()/2],"p95_ms":times[ceili(times.size()*.95)-1],"p99_ms":times[ceili(times.size()*.99)-1],"windups":warnings,"player_attacks":attacks}
			print("GROUP_SAMPLE "+key+" "+JSON.stringify(report.samples[key]))
		w.realms.leave()
	var f=FileAccess.open("res://build/presentation-review/group-performance.json",FileAccess.WRITE); f.store_string(JSON.stringify(report,"\t")); f.close()
	print("PRESENTATION_GROUP_COMPLETE"); quit()
