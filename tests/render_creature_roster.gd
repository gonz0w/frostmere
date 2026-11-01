extends SceneTree
const Pose=preload("res://scripts/defeat_motion.gd")
func _initialize() -> void: call_deferred("run")
func run() -> void:
	assert(DisplayServer.get_name()!="headless" and "--capture" in OS.get_cmdline_user_args())
	var w=load("res://scenes/main.tscn").instantiate(); root.add_child(w); w.capture_done=true; w.audio.enabled=false
	for i in range(8): await physics_frame
	assert(not w.player.character.persist and not w.atlas.persist)
	w.hide(); w.set_process(false)
	for n in w.find_children("*","Node",true,false):
		n.set_process(false); n.set_physics_process(false)
		if n is CanvasLayer: n.hide()
	var stage=Node3D.new(); root.add_child(stage)
	var env=WorldEnvironment.new(); var settings=Environment.new()
	settings.background_mode=Environment.BG_COLOR; settings.background_color=Color("202a34")
	settings.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR; settings.ambient_light_color=Color("c9dae5"); settings.ambient_light_energy=.65
	env.environment=settings
	# Remove the gameplay environment from this gallery viewport.
	for child in w.get_children():
		if child is WorldEnvironment: child.environment=null
	stage.add_child(env)
	var sun=DirectionalLight3D.new(); sun.rotation_degrees=Vector3(-35,-35,0); sun.light_energy=1.7; stage.add_child(sun)
	var camera=Camera3D.new(); stage.add_child(camera); camera.current=true; camera.projection=Camera3D.PROJECTION_ORTHOGONAL
	var roster={"wolf":w.wilderness.enemies[0],"boar":w.wilderness.enemies[3],"colossus":w.wilderness.enemies[11],"rimefang":w.wilderness.enemies[12],"hollow_warden":w.roots.enemies[3],"hull_warden":w.shore.enemies[6],"cantor":w.choir.enemies[4],"meridian_keeper":w.lens.enemies[4],"hullcarver":w.threshold.enemies[5],"prismwing":w.realms.enemies[2],"furnace_maw":w.realms.enemies[5]}
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://build/creature-review"))
	var report={}
	for id in roster:
		var e=roster[id]; var neutral=Pose.capture(e.rig)
		report[id]={"title":e.title,"poses":[]}
		for state in ["idle","warning","finisher","defeated"]:
			for node in neutral: node.transform=neutral[node]
			e.dead=false; e.execution_locked=false; e.execution_progress=0; e.windup=0
			if state=="warning":
				e.windup=.3
				match id:
					"wolf","boar": e.update_bite_pose()
					"colossus": e.slam_remaining=.35; e.update_slam_pose(); e.slam_remaining=0
					"rimefang": e.charge_warning=.3; e.update_charge_pose(); e.charge_warning=0
					"hullcarver","prismwing": e.update_pose()
					"hull_warden": e.update_shell()
					"furnace_maw": e.vent_pending=true; e.update_pose(); e.vent_pending=false
					_:
						preload("res://scripts/creature_presentation.gd").live(e,"cantor" if id=="cantor" else "solar" if id=="meridian_keeper" else "warden")
						if id=="cantor":
							for i in range(e.wings.size()): e.wings[i].rotation.z=(-1 if i==0 else 1)*.3
			elif state=="finisher": e.execution_locked=true; e.set_execution_pose(.75)
			elif state=="defeated": e.dead=true; e._show_corpse()
			var model=e.rig.duplicate(); stage.add_child(model); model.show()
			var small: bool=id in ["wolf","boar"]
			camera.position=Vector3(7,5,-9)*( .3 if small else 1.0)
			camera.look_at(Vector3(0,.72 if small else 2.0 if id=="colossus" else 1.7,0))
			camera.size=2.4 if small else 9.5 if id=="prismwing" else 7.5
			for i in range(4): await process_frame
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("res://build/creature-review/"+id+"-"+state+".png")
			report[id].poses.append(state); model.queue_free(); await process_frame
	var stag=w.roots.stag.duplicate(); stage.add_child(stag); stag.position=Vector3.ZERO; stag.show()
	camera.position=Vector3(3,2.5,-4); camera.look_at(Vector3(0,1.4,0)); camera.size=4
	for i in range(4): await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://build/creature-review/shadowless_stag-idle.png")
	report.shadowless_stag={"title":"Shadowless Stag","poses":["idle"]}
	var output=FileAccess.open("res://build/creature-review/manifest.json",FileAccess.WRITE); output.store_string(JSON.stringify(report,"\t")); output.close()
	print("CREATURE_ROSTER_RENDER_COMPLETE models=%d" % report.size()); quit()
