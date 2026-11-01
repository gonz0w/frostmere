extends SceneTree
const Fragments=preload("res://scripts/finisher_effect.gd")
const Eruption=preload("res://scripts/monster_effect.gd")
const Ground=preload("res://scripts/ground_slam_effect.gd")
var include_intro:=false

func _initialize() -> void: call_deferred("run")
func settle() -> void:
	for i in range(3): await process_frame
func metrics() -> Dictionary:
	return {"nodes":Performance.get_monitor(Performance.OBJECT_NODE_COUNT),"orphans":Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT),"resources":Performance.get_monitor(Performance.OBJECT_RESOURCE_COUNT),"static_memory_mib":Performance.get_monitor(Performance.MEMORY_STATIC)/1048576.0}
func cycle(w: Node3D) -> void:
	assert(w.archive_chapter.enter()); await create_timer(.2).timeout
	w.archive_chapter.leave(); assert(w.mountain.enter()); await create_timer(.2).timeout
	assert(w.realms.enter("crucible",true))
	var maw=w.realms.enemies[5]
	var eruption=Eruption.eruption(maw,maw.global_position)
	var shell=Fragments.spawn(maw,"crush",Vector3.FORWARD)
	w.player.set_paused(true); await settle()
	assert(not eruption.visible and not shell.visible)
	w.player.set_paused(false); await create_timer(.2).timeout
	assert(w.realms.enter("aeralis",true)); await settle()
	assert(not is_instance_valid(eruption) and not is_instance_valid(shell))
	var crystal=Fragments.spawn(w.realms.enemies[2],"sweep",Vector3.RIGHT)
	w.realms.leave(); await settle(); assert(not is_instance_valid(crystal))
	var debris=Ground.spawn(w.wilderness.enemies[11],w.wilderness.enemies[11].home)
	await create_timer(.8).timeout; await settle(); assert(not is_instance_valid(debris))
	if include_intro:
		w.player.character.intro_completed=false
		assert(w.intro.start())
		w.player.position=w.intro.ORIGIN+Vector3(0,.1,-2)
		assert(w.intro.interact()); w.intro.advance(8.1)
		assert(w.intro.stage==2)
		w.intro.finish(); w.intro.advance(1); await settle()

func run() -> void:
	assert(DisplayServer.get_name()!="headless" and "--capture" in OS.get_cmdline_user_args())
	include_intro="--intro-cycles" in OS.get_cmdline_user_args()
	var cycles:=30
	var report_path:="res://build/region-lifecycle.json"
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--cycles="): cycles=clampi(int(arg.trim_prefix("--cycles=")),1,1200)
		if arg.begins_with("--report="): report_path="res://build/"+arg.trim_prefix("--report=")+".json"
	var started:=Time.get_ticks_msec()
	var w=load("res://scenes/main.tscn").instantiate(); root.add_child(w); w.capture_done=true; w.audio.enabled=false
	for i in range(8): await physics_frame
	var p=w.player; assert(not p.character.persist and not w.atlas.persist)
	p.set_physics_process(false); p.set_process_unhandled_input(false); p.invulnerable=10000
	p.character.story_completed.append("stonewake")
	# Prevent unrelated enemy attacks from changing the settled node count.
	for e in w.wilderness.enemies+w.realms.enemies+w.archive_chapter.enemies+w.mountain.enemies: e.set_physics_process(false)
	for i in range(3): await cycle(w)
	var baseline:=metrics(); var samples: Array[Dictionary]=[]
	for i in range(cycles):
		await cycle(w)
		var current:=metrics(); samples.append(current)
		assert(current.nodes==baseline.nodes,"Settled node count grew after travel/effect cleanup")
		assert(current.orphans==baseline.orphans,"Orphan nodes grew")
		if (i+1)%10==0: print("LIFECYCLE_PROGRESS cycles=%d %s" % [i+1,JSON.stringify(current)])
	var report: Dictionary={"gpu":RenderingServer.get_video_adapter_name(),"engine":Engine.get_version_info().string,"seconds":(Time.get_ticks_msec()-started)/1000.0,"warmup_cycles":3,"measured_cycles":cycles,"intro_rebuild_each_cycle":include_intro,"baseline":baseline,"samples":samples,"method":"Native isolated profile, three warmup cycles then the recorded number of measured cycles through Pinehall, Wyrmkeep, Crucible, Aeralis and home. Four effects spawned per cycle; pause, travel cancellation and natural expiry checked. Enemy attacks disabled to isolate lifecycle counts. Static memory is Godot allocator usage, not RSS/VRAM. This short stress run does not establish hours-long save/session stability."}
	var file=FileAccess.open(report_path,FileAccess.WRITE); assert(file!=null); file.store_string(JSON.stringify(report,"\t")); file.close()
	print("LIFECYCLE_COMPLETE "+JSON.stringify({"seconds":report.seconds,"baseline":baseline,"final":samples[-1]}))
	w.queue_free(); await process_frame; quit()
