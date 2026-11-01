extends SceneTree
var w: Node3D
var camera: Camera3D
var manifest: Array=[]
func _initialize() -> void: call_deferred("run")
func hide_labels(node: Node) -> void:
	if node is Label3D and not node.has_meta("architecture_sign"): node.hide()
	if node is CanvasLayer: node.hide()
	for child in node.get_children(): hide_labels(child)
func capture(id: String,title: String,group: String,at: Vector3,target: Vector3) -> void:
	camera.position=at; camera.look_at(target)
	for i in range(5): await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_jpg("res://build/building-review/"+id+".jpg",.93)
	manifest.append({"id":id,"title":title,"group":group,"file":id+".jpg"})
func run() -> void:
	assert("--capture" in OS.get_cmdline_user_args() and DisplayServer.get_name()!="headless")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://build/building-review"))
	root.size=Vector2i(1280,800)
	w=load("res://scenes/main.tscn").instantiate(); root.add_child(w); w.capture_done=true
	for i in range(6): await physics_frame
	assert(not w.player.character.persist and not w.atlas.persist)
	w.process_mode=Node.PROCESS_MODE_DISABLED
	hide_labels(w); w.player.hide()
	camera=Camera3D.new(); root.add_child(camera); camera.current=true; camera.fov=68; camera.far=450
	for r in w.building_records:
		var o: Vector3=r.origin; var width: float=r.width; var depth: float=r.depth; var height: float=r.height
		var exterior_offset=Vector3(width*.35,height+3,depth/2+width*1.05+5)
		if r.id=="weaver": exterior_offset=Vector3(3,3,depth/2+7)
		if r.id=="harbormaster": exterior_offset=Vector3(-width*.65,height+2,depth/2+width*.7)
		await capture(r.id+"-exterior",r.name+" · exterior",r.region.capitalize(),o+exterior_offset,o+Vector3(0,height*.9,0))
		await capture(r.id+"-door",r.name+" · street approach",r.region.capitalize(),o+Vector3(-2.4,1.8,depth/2+5),o+Vector3(0,2.7,depth/2))
		await capture(r.id+"-interior",r.name+" · interior","Interiors",o+Vector3(minf(width/2-.7,1.6),1.9,depth/2-1),o+Vector3(-.25,1.5,-depth*.28))
		await capture(r.id+"-workroom",r.name+" · workroom details","Interiors",o+Vector3(-minf(width/2-.8,1.6),1.75,depth/2-1.3),o+Vector3(width/2-.6,1.4,0))
	await capture("frostmere-street","Frostmere · shop street","Town views",Vector3(-1,2.2,17),Vector3(-7,4,-9))
	await capture("frostmere-hall","Frostmere · Ember Hall","Town views",Vector3(10,4,-27),Vector3(1,5,-45))
	await capture("wyrmkeep-square","Wyrmkeep · clan halls","Town views",Vector3(805,6,12),Vector3(800,6,-24))
	await capture("pinehall-lanes","Pinehall · faction houses","Town views",Vector3(-799,4,31),Vector3(-800,4,1))
	await capture("fortress","Frostmere · distant keep","Landmarks",Vector3(32,22,-45),Vector3(1,24,-88))
	await capture("station-arrival","First Threshold · arrival compartment","Landmarks",Vector3(2242,2,37),Vector3(2251,3,18))
	await capture("station-salvage","First Threshold · salvage compartment","Landmarks",Vector3(2242,2,-11),Vector3(2255,3,-21))
	await capture("station-command","First Threshold · command compartment","Landmarks",Vector3(2242,2,-58),Vector3(2255,3,-72))
	for id in ["aeralis","crucible"]:
		w.realms.enter(id,true); hide_labels(w)
		var origin: Vector3=w.realms.roots[id].global_position
		await capture(id+"-arrival",("Aeralis" if id=="aeralis" else "The Crucible")+" · arrival architecture","Landmarks",origin+Vector3(0,2,20),origin+Vector3(7,3,9))
		await capture(id+"-terrace",("Aeralis" if id=="aeralis" else "The Crucible")+" · middle terrace","Landmarks",origin+Vector3(0,2,-3),origin+Vector3(-8,4,-12))
		await capture(id+"-sanctum",("Aeralis" if id=="aeralis" else "The Crucible")+" · sanctum architecture","Landmarks",origin+Vector3(2,3,-25),origin+Vector3(0,7,-39))
	var file=FileAccess.open("res://build/building-review/manifest.json",FileAccess.WRITE); file.store_string(JSON.stringify(manifest,"\t")); file.close()
	print("BUILDING_REVIEW_COMPLETE captures=%d buildings=%d"%[manifest.size(),w.building_records.size()]); quit()
