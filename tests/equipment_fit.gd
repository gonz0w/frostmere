extends SceneTree
const State=preload("res://scripts/character_state.gd")
const Visual=preload("res://scripts/character_visual.gd")
var checks:=0
var failures:=0
func _initialize() -> void: call_deferred("run")
func check(ok: bool,message: String) -> void:
	checks+=1
	if not ok: failures+=1; push_error("FAIL "+message)
func run() -> void:
	var s=State.new(); assert(not s.persist)
	var families=["cloth","fur","leather","iron","chain","steel","obsidian","crystal","aether","cinder"]
	var owned={}
	for item in s.catalog.items: owned[item.id]=s.add_item(item.id)
	var rig=Visual.new(); root.add_child(rig)
	for origin in s.origins:
		s.origin_id=origin
		for frame in ["lean","balanced","broad"]:
			s.frame_id=frame
			for family in families:
				for slot in ["head","chest","hands","legs","feet"]: s.equip(owned[family+"_"+slot],slot)
				var stats=s.stats().duplicate(true); var inventory=s.inventory.duplicate(true)
				rig.build(s)
				var valid=rig.scale.is_finite() and rig.left_arm.get_parent()==rig and rig.right_leg.get_parent()==rig
				for mesh in rig.find_children("*","MultiMeshInstance3D",true,false):
					for i in range(mesh.multimesh.instance_count):
						var t=mesh.multimesh.get_instance_transform(i)
						valid=valid and t.origin.is_finite() and t.basis.is_finite() and absf(t.basis.determinant())>0
				check(valid and s.stats()==stats and s.inventory==inventory,origin+" "+frame+" "+family+" valid geometry without stat/inventory mutation")
				if family!="cinder":
					var clear=true
					for mesh in rig.get_children():
						if mesh is MultiMeshInstance3D and String(mesh.name).begins_with("Blocks_head@"):
							for i in range(mesh.multimesh.instance_count):
								var bounds=mesh.multimesh.get_instance_transform(i)*AABB(Vector3.ONE*-.5,Vector3.ONE)
								for side in [-1,1]: clear=clear and not bounds.has_point(Vector3(side*.1,1.705,-.193))
					check(clear,origin+" "+frame+" "+family+" open helmet leaves eye centers clear")
				await process_frame
	# Repeated mixed equipment changes exercise old-part removal and independently worn slots.
	for i in range(24):
		s.origin_id=s.origins.keys()[i%8]; s.frame_id=["lean","balanced","broad"][i/8]
		for pair in [["head","cinder_head"],["chest","briar_vestment"],["hands","crystal_hands"],["legs","steel_legs"],["feet","pathfinder_feet"]]: s.equip(owned[pair[1]],pair[0])
		rig.build(s); rig.left_leg.rotation.x=.6; rig.right_leg.rotation.x=-.6
		check(rig.left_leg.get_child_count()>0 and rig.right_leg.get_child_count()>0 and s.item_at("chest").base_id=="briar_vestment","Mixed outfit survives rebuild "+str(i))
		await process_frame
	rig.queue_free(); await process_frame
	print("EQUIPMENT_FIT_COMPLETE checks=%d failures=%d" % [checks,failures]); quit(1 if failures else 0)
