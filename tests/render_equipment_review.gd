extends SceneTree
const State=preload("res://scripts/character_state.gd")
const Visual=preload("res://scripts/character_visual.gd")
const Identity=preload("res://scripts/equipment_identity.gd")
const FAMILIES=["cloth","fur","leather","iron","chain","steel","obsidian","crystal","aether","cinder"]
var stage: Node3D
var camera: Camera3D
var manifest: Array=[]
func _initialize() -> void: call_deferred("run")
func capture(id: String,title: String,group: String,model: Node3D,target: Vector3,size: float) -> void:
	stage.add_child(model)
	camera.position=target+Vector3(2.2,1.1,-5); camera.look_at(target); camera.size=size
	for i in range(3): await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_jpg("res://build/equipment-review/"+id+".jpg",.91)
	manifest.append({"id":id,"title":title,"group":group,"file":id+".jpg"})
	stage.remove_child(model); model.queue_free(); await process_frame
func outfit(s: RefCounted,family: String) -> void:
	for slot in s.equipment: s.unequip(slot)
	for slot in ["head","chest","hands","legs","feet"]: s.equip(s.add_item(family+"_"+slot),slot)
func run() -> void:
	assert(DisplayServer.get_name()!="headless")
	root.size=Vector2i(960,600)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://build/equipment-review"))
	stage=Node3D.new(); root.add_child(stage)
	var env=WorldEnvironment.new(); var settings=Environment.new()
	settings.background_mode=Environment.BG_COLOR; settings.background_color=Color("202a34")
	settings.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR; settings.ambient_light_color=Color("c9dae5"); settings.ambient_light_energy=.65; env.environment=settings; stage.add_child(env)
	var light=DirectionalLight3D.new(); light.rotation_degrees=Vector3(-35,-35,0); light.light_energy=1.7; stage.add_child(light)
	camera=Camera3D.new(); stage.add_child(camera); camera.projection=Camera3D.PROJECTION_ORTHOGONAL; camera.current=true
	var s=State.new(); assert(not s.persist)
	for family in FAMILIES:
		outfit(s,family)
		for pose in ["front","back","stride"]:
			var rig=Visual.new(); rig.build(s)
			if pose=="back": rig.rotation.y=PI
			if pose=="stride": rig.left_leg.rotation.x=.6; rig.right_leg.rotation.x=-.6; rig.right_arm.rotation.x=-.5
			await capture("armor-"+family+"-"+pose,family.capitalize()+" · "+pose,"Armor sets",rig,Vector3(0,1.02,0),2.55)
	for origin in s.origins:
		s.origin_id=origin
		for slot in s.equipment: s.unequip(slot)
		var face=Visual.new(); face.build(s)
		await capture("face-"+origin,s.origins[origin].name,"Faces",face,Vector3(0,1.70*(.9 if s.origins[origin].shape=="dwarf" else 1.0),-.03),1.1)
		for family in FAMILIES:
			outfit(s,family); var rig=Visual.new(); rig.build(s)
			await capture("helmet-"+origin+"-"+family,s.origins[origin].name+" · "+family,"Helmet fit",rig,Vector3(0,1.70*(.9 if s.origins[origin].shape=="dwarf" else 1.0),-.02),1.0)
		for frame in ["lean","balanced","broad"]:
			s.frame_id=frame; outfit(s,"steel")
			for pair in [["head","cinder_head"],["chest","briar_vestment"],["hands","crystal_hands"],["feet","pathfinder_feet"]]: s.equip(s.add_item(pair[1]),pair[0])
			var rig=Visual.new(); rig.build(s); rig.left_leg.rotation.x=.6; rig.right_leg.rotation.x=-.6; rig.right_arm.rotation.x=-.5
			await capture("mixed-"+origin+"-"+frame,s.origins[origin].name+" · "+frame,"Mixed fit",rig,Vector3(0,1,0),2.65)
		s.frame_id="balanced"
	s.origin_id="frostkin"
	for item in s.catalog.items:
		var slot: String=item.slot
		if slot in ["main_hand","off_hand"]:
			var model=Node3D.new(); Visual.make_weapon(model,item)
			if item.family in ["sword","dagger","greatsword","axe","battleaxe","mace","machine_gun"]: model.rotation.x=PI/2
			var target=Vector3(0,.5,0); var zoom=2.6
			if item.family in ["greatsword","battleaxe"]: target.y=.65; zoom=3.1
			elif item.family=="staff": target.y=.2; zoom=3.3
			elif item.family=="bow": target.y=0; zoom=2.6
			elif item.family=="shield": target.y=.2; zoom=1.3
			elif item.family=="focus": target.y=.15; zoom=1.0
			elif item.family=="dagger": target.y=.2; zoom=1.6
			await capture("gear-"+item.id,item.name,"Weapons & shields",model,target,zoom)
		elif slot in ["ring","amulet"]:
			var model=Node3D.new(); var v=preload("res://scripts/blocks.gd").new(); v.spatial_batching=false; Identity.jewelry(v,item,false,slot=="ring"); v.finish(model)
			await capture("gear-"+item.id,item.name,"Jewelry",model,Vector3(.02,-.59,.04) if slot=="ring" else Vector3(0,1.24,-.32),.15 if slot=="ring" else .5)
		elif item.id!=item.family+"_"+slot:
			outfit(s,item.family); s.equip(s.add_item(item.id),slot); var rig=Visual.new(); rig.build(s)
			await capture("gear-"+item.id,item.name,"Named armor",rig,Vector3(0,1,0),2.6)
	var out=FileAccess.open("res://build/equipment-review/manifest.json",FileAccess.WRITE); out.store_string(JSON.stringify(manifest,"\t")); out.close()
	print("EQUIPMENT_REVIEW_RENDER_COMPLETE captures=%d" % manifest.size()); quit()
