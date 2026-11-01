extends SceneTree
const VIEWS = [
 ["frostmere","Market green",Vector3(2,2.3,20),Vector3(-10,2.4,3)],
 ["frostmere","Riverside",Vector3(6,2.1,4),Vector3(24,2,-9)],
 ["frostmere","Northern foothills",Vector3(28,3,-39),Vector3(36,5,-65)],
 ["mountain","Wyrmkeep approach",Vector3(800,2.4,38),Vector3(805,3,-6)],
 ["mountain","Clan gardens",Vector3(800,2.3,-5),Vector3(821,3,-16)],
 ["mountain","Pass ridges",Vector3(810,3,-45),Vector3(835,12,-76)],
 ["archive_chapter","Pinehall lanes",Vector3(-799,2.3,39),Vector3(-813,3,14)],
 ["archive_chapter","Woodland trail",Vector3(-800,2.1,-12),Vector3(-822,4,-31)],
 ["shore","Saltbreak harbor",Vector3(-1179,2.4,42),Vector3(-1170,3,12)],
 ["shore","Tide pools",Vector3(-1197,2.2,25),Vector3(-1210,1,0)],
 ["shore","Black shore cliffs",Vector3(-1170,2.4,-23),Vector3(-1150,8,-46)],
 ["lens","Sunken Lens camp",Vector3(1200,2.3,40),Vector3(1182,3,18)],
 ["lens","Wind-carved mesas",Vector3(1210,2.2,4),Vector3(1238,5,-15)],
 ["roots","Amberweald settlement",Vector3(1440,2.2,39),Vector3(1425,3,17)],
 ["roots","Copper canopy",Vector3(1440,2.1,-5),Vector3(1418,7,-24)],
 ["choir","Ash pilgrimage",Vector3(1680,2.3,39),Vector3(1665,3,18)],
 ["choir","Caldera cliffs",Vector3(1680,2.5,-16),Vector3(1710,7,-36)],
 ["convergence","Mirewatch landing",Vector3(1920,2.2,38),Vector3(1900,2,18)],
 ["convergence","Reed marsh",Vector3(1920,2,-10),Vector3(1900,1,-35)],
 ["winter","Northwatch shelter",Vector3(2480,2.3,39),Vector3(2461,3,25)],
 ["winter","Siege landscape",Vector3(2480,2.4,-15),Vector3(2500,10,-58)],
 ["threshold","Station arrival",Vector3(2241,2,37),Vector3(2251,3,16)],
 ["threshold","Salvage corridor",Vector3(2241,2,-9),Vector3(2255,3,-22)],
 ["aeralis","Crystal terrace",Vector3(1200,162,18),Vector3(1192,164,-4)],
 ["aeralis","Floating island gardens",Vector3(1200,162,-3),Vector3(1178,165,-30)],
 ["crucible","Foundry descent",Vector3(1600,2,18),Vector3(1612,4,-8)],
 ["crucible","Furnace landscape",Vector3(1600,3,-20),Vector3(1619,7,-37)]
]
var w: Node3D
var camera: Camera3D
var manifest: Array=[]
func _initialize() -> void: call_deferred("run")
func hide_labels(n: Node) -> void:
	if n is Label3D and not n.has_meta("architecture_sign"): n.hide()
	if n is CanvasLayer: n.hide()
	for c in n.get_children(): hide_labels(c)
func run() -> void:
	assert(DisplayServer.get_name()!="headless" and "--capture" in OS.get_cmdline_user_args())
	var phase := "before" if "--before" in OS.get_cmdline_user_args() else "after"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://build/landscape-review/"+phase))
	root.size=Vector2i(1280,800)
	w=load("res://scenes/main.tscn").instantiate(); root.add_child(w); w.capture_done=true
	for i in range(5): await physics_frame
	assert(not w.player.character.persist and not w.atlas.persist)
	for id in w.atlas.quests:
		if id not in w.player.character.story_completed: w.player.character.story_completed.append(id)
	w.process_mode=Node.PROCESS_MODE_DISABLED; hide_labels(w); w.player.hide()
	camera=Camera3D.new(); root.add_child(camera); camera.current=true; camera.fov=68; camera.far=450
	var active := "frostmere"
	for i in range(VIEWS.size()):
		if i==1: continue # This legacy camera sits inside the expanded riverside shop.
		var v: Array=VIEWS[i]; var id: String=v[0]
		if id!=active:
			if active in ["aeralis","crucible"]: w.realms.leave()
			elif active!="frostmere": w.get(active).leave()
			if id in ["aeralis","crucible"]: assert(w.realms.enter(id,true))
			elif id!="frostmere": assert(w.get(id).enter())
			active=id; hide_labels(w)
		camera.position=v[2]; camera.look_at(v[3])
		for j in range(5): await process_frame
		await RenderingServer.frame_post_draw
		var file: String="%02d-%s.jpg"%[i,id]
		root.get_texture().get_image().save_jpg("res://build/landscape-review/"+phase+"/"+file,.91)
		manifest.append({"region":id,"title":v[1],"file":file})
	var f=FileAccess.open("res://build/landscape-review/manifest.json",FileAccess.WRITE); f.store_string(JSON.stringify(manifest,"\t")); f.close()
	print("LANDSCAPE_REVIEW_COMPLETE %s %d views"%[phase,manifest.size()]); quit()
