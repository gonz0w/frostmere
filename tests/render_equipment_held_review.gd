extends SceneTree
var manifest: Array=[]
func _initialize() -> void: call_deferred("run")
func run() -> void:
	assert("--capture" in OS.get_cmdline_user_args())
	root.size=Vector2i(960,600)
	var w=load("res://scenes/main.tscn").instantiate(); root.add_child(w); w.capture_done=true
	for i in range(6): await physics_frame
	var p=w.player; var s=p.character
	assert(not s.persist and not w.atlas.persist)
	p.position=Vector3(0,.2,12); p.rotation=Vector3.ZERO; p.pivot.rotation=Vector3.ZERO
	p.set_physics_process(false); p.set_process_unhandled_input(false)
	var families=["cloth","fur","leather","iron","chain","steel","obsidian","crystal","aether","cinder"]
	var index=0
	for item in s.catalog.items:
		if item.slot not in ["main_hand","off_hand"]: continue
		s.origin_id=s.origins.keys()[index%8]; s.frame_id=["lean","balanced","broad"][index%3]
		for slot in s.equipment: s.unequip(slot)
		var family: String=families[index%10]
		for slot in ["head","chest","hands","legs","feet"]: s.equip(s.add_item(family+"_"+slot),slot)
		s.equip(s.add_item(item.id,2,"vigor"),item.slot)
		for third in [false,true]:
			p.set_third_person(third)
			for i in range(5): await physics_frame
			await RenderingServer.frame_post_draw
			var id="held-"+item.id+("-third" if third else "-first")
			root.get_texture().get_image().save_jpg("res://build/equipment-review/"+id+".jpg",.91)
			manifest.append({"id":id,"title":item.name+" · "+s.origin_id+" / "+s.frame_id+" / "+family,"group":"Third person" if third else "First person","file":id+".jpg"})
		index+=1
	var file=FileAccess.open("res://build/equipment-review/held-manifest.json",FileAccess.WRITE); file.store_string(JSON.stringify(manifest,"\t")); file.close()
	print("EQUIPMENT_HELD_REVIEW_COMPLETE captures=%d" % manifest.size()); quit()
