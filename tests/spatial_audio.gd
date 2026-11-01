extends SceneTree
var checks:=0
var failures:=0
func _initialize() -> void: call_deferred("run")
func check(ok: bool,label: String) -> void:
	checks+=1
	if ok: print("PASS "+label)
	else: failures+=1; push_error("FAIL "+label)
func run() -> void:
	var w=load("res://scenes/main.tscn").instantiate(); root.add_child(w)
	for i in range(4): await physics_frame
	var a=w.audio; var p=w.player; var c=w.adventure; var e=c.enemies[0]
	p.set_physics_process(false); a.set_process(false)
	for actor in c.enemies: actor.set_physics_process(false)
	c.inside=true; p.set_paused(false); e.global_position=p.global_position+Vector3.LEFT*6
	check(a.spatial_voices.size()==6,"Spatial voice pool is fixed")
	a.warning_at("root_warning",e)
	check(a.spatial_sources.size()==1 and a.spatial_voices[0].stream==a.streams.root_warning,"Warning routes to positional pool")
	check(a.spatial_voices[0].bus=="Effects" and a.spatial_voices[0].max_distance==32,"Warning uses effects volume and bounded range")
	e.global_position+=Vector3.RIGHT*2; a.update_spatial()
	check(a.spatial_voices[0].global_position.is_equal_approx(e.global_position+Vector3.UP*1.5),"Sound follows moving creature")
	var count: int=a.effect_count; a.warning_at("root_warning",e)
	check(a.effect_count==count,"Spatial warnings respect cooldown")
	for reason in ["menu","travel","death","execution","stagger"]:
		a.cooldowns.clear(); a.warning_at("root_warning",e)
		if reason=="menu": p.set_paused(true)
		elif reason=="travel": c.inside=false
		elif reason=="death": e.dead=true
		elif reason=="execution": e.execution_locked=true
		else: e.stagger_time=1
		a.update_spatial(); check(a.spatial_sources.is_empty(),"Interruption releases source: "+reason)
		p.set_paused(false); c.inside=true; e.dead=false; e.execution_locked=false; e.stagger_time=0
	a.cooldowns.clear(); e.global_position=p.global_position+Vector3.RIGHT*33; count=a.effect_count; a.warning_at("root_warning",e)
	check(a.effect_count==count,"Distant sources cannot allocate warnings")
	e.global_position=p.global_position+Vector3.LEFT*6; a.warning_at("root_warning",e); c.enemies.erase(e); e.queue_free(); await process_frame; a.update_spatial()
	check(a.spatial_sources.is_empty(),"Freed creature references clear safely")
	w.queue_free(); await process_frame
	print("SPATIAL_AUDIO_COMPLETE checks=%d failures=%d" % [checks,failures]); quit(1 if failures else 0)
