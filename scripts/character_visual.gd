extends Node3D
## Reusable modular voxel rig for the player, character preview, and future NPCs.
const Blocks = preload("res://scripts/blocks.gd")
const Armor = preload("res://scripts/refined_armor.gd")
var left_leg: Node3D
var right_leg: Node3D
var left_arm: Node3D
var right_arm: Node3D
var b: RefCounted

func build(state: RefCounted) -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()
	b = Blocks.new()
	b.spatial_batching=false
	for material: StandardMaterial3D in b.materials.values():
		material.uv1_world_triplanar = false
	var origin: Dictionary = state.origins[state.origin_id]
	b.materials.skin.albedo_color = Color(origin.skin)
	for slot: String in ["head", "chest", "hands", "legs", "feet"]:
		var item: Dictionary = state.item_at(slot)
		var material: StandardMaterial3D = b.materials.iron.duplicate()
		material.albedo_color = Color(item.get("color", "51483e"))
		material.roughness = 0.55 if item.get("weight_class") == "heavy" else 0.95
		preload("res://scripts/equipment_surface.gd").apply(material,item)
		b.materials[slot] = material
	var breadth: float = {"lean": 0.90, "balanced": 1.0, "broad": 1.12}[state.frame_id]
	var stature := 0.90 if origin.shape == "dwarf" else 1.0
	scale = Vector3(breadth, stature, 1.0)
	# Underclothes remain when an armor slot is empty.
	b.add("cloth", Vector3(0, 1.08, 0), Vector3(0.53, 0.63, 0.31))
	var chest: Dictionary = state.item_at("chest")
	if not chest.is_empty():
		b.add("chest", Vector3(0, 1.12, 0), Vector3(0.57, 0.59, 0.36))
		if chest.get("effect", "") == "healing_bonus":
			for side in [-1,1]:
				for leaf in range(5):
					b.add("pine_light", Vector3(side*(0.07+leaf*0.027),1.35-leaf*0.085,-0.245),Vector3(0.1,0.045,0.04))
		Armor.torso(b, chest)
		preload("res://scripts/equipment_identity.gd").armor(b,chest,"chest")
		if chest.family in ["leather", "iron", "chain"]:
			Armor.collar(b)
		if chest.family == "chain":
			for row in range(6):
				for col in range(8):
					b.add("iron", Vector3(-0.21 + col * 0.06, 1.30 - row * 0.065, 0.24), Vector3(0.035, 0.045, 0.02))
		if chest.family in ["crystal", "obsidian"]:
			for i in range(5):
				b.add("gold" if chest.family == "obsidian" else "snow", Vector3(0, 1.35 - i * 0.10, 0.245), Vector3(0.08, 0.06, 0.04))
	b.add("timber", Vector3(0, 0.86, 0), Vector3(0.61, 0.08, 0.41))
	b.add("gold", Vector3(0, 0.86, -0.23), Vector3(0.11, 0.10, 0.025))
	preload("res://scripts/refined_faces.gd").build(b,origin,not state.item_at("head").is_empty())
	var head: Dictionary = state.item_at("head")
	if not head.is_empty():
		b.add("head", Vector3(0, 1.68, 0.20), Vector3(0.43, 0.34, 0.07))
		for side in [-1.0, 1.0]:
			if origin.shape in ["elf","orc"]:
				for y in [1.565,1.815]: b.add("head",Vector3(side*.21,y,.04),Vector3(.075,.09,.36))
			else: b.add("head", Vector3(side * 0.21, 1.69, 0.04), Vector3(0.075, 0.33, 0.36))
		for tier in range(3):
			b.add("head", Vector3(0, 1.86 + tier * 0.035, 0), Vector3(0.43 - tier * 0.065, 0.045, 0.43 - tier * 0.05))
		if head.family in ["steel", "obsidian", "crystal"] and origin.shape!="cat":
			for side in [-1.0, 1.0]:
				for step in range(3):
					b.add("head", Vector3(side * (0.23 + step * 0.05), 1.89 + step * 0.065, 0.02), Vector3(0.08 - step * 0.014, 0.09, 0.09))
		if head.family == "aether":
			for side in [-1, 1]:
				for tier in range(5):
					b.add("snow", Vector3(side * (0.23 + tier * 0.025), 1.82 + tier * 0.06, 0.08), Vector3(0.07, 0.07, 0.12))
		if head.family == "cinder":
			var muzzle: float=-.10 if origin.shape in ["cat","lizard","orc"] else 0.0
			b.add("coal", Vector3(0, 1.65, -0.23+muzzle), Vector3(0.38, 0.24, 0.10))
			b.add("window", Vector3(0, 1.72, -0.29+muzzle), Vector3(0.30, 0.04, 0.03))
			for side in [-1, 1]: b.add("iron", Vector3(side * 0.13, 1.59, -0.30+muzzle), Vector3(0.06, 0.10, 0.07))
		Armor.helmet(b, head)
		preload("res://scripts/equipment_identity.gd").armor(b,head,"head")
	var amulet: Dictionary = state.item_at("amulet")
	preload("res://scripts/equipment_identity.gd").jewelry(b,amulet)
	b.finish(self)
	left_leg = _limb(Vector3(-0.16, 0.77, 0), true, state)
	right_leg = _limb(Vector3(0.16, 0.77, 0), true, state)
	left_arm = _limb(Vector3(-0.43, 1.37, 0), false, state)
	right_arm = _limb(Vector3(0.43, 1.37, 0), false, state)
	var main_mount := Node3D.new()
	main_mount.position = Vector3(0, -0.56, -0.05)
	right_arm.add_child(main_mount)
	make_weapon(main_mount, state.item_at("main_hand"))
	var off_mount := Node3D.new()
	off_mount.position = Vector3(0, -0.56, -0.05)
	left_arm.add_child(off_mount)
	make_weapon(off_mount, state.item_at("off_hand"))

func _limb(origin: Vector3, leg: bool, state: RefCounted) -> Node3D:
	var limb := Node3D.new()
	limb.position = origin
	add_child(limb)
	if leg:
		preload("res://scripts/equipment_identity.gd").skirt(b,state.item_at("chest"))
		var key := "cloth" if state.item_at("legs").is_empty() else "legs"
		b.add(key, Vector3(0, -0.25, 0), Vector3(0.24, 0.48, 0.26))
		var feet := "timber" if state.item_at("feet").is_empty() else "feet"
		for step in range(3):
			b.add(feet, Vector3(0, -0.55 - step * 0.075, -step * 0.025), Vector3(0.26, 0.09, 0.28 + step * 0.035))
		if state.item_at("legs").get("weight_class", "") == "heavy":
			for row in range(4):
				b.add("legs", Vector3(0, -0.13 - row * 0.085, -0.145), Vector3(0.21, 0.075, 0.04))
	else:
		b.add("cloth", Vector3(0, -0.20, 0), Vector3(0.22, 0.4, 0.27))
		if not state.item_at("chest").is_empty():
			for row in range(3):
				b.add("chest", Vector3(0, -row * 0.065, 0), Vector3(0.31 - row * 0.025, 0.085, 0.35 - row * 0.025) if state.item_at("chest").get("weight_class", "") == "heavy" else Vector3(0.25 - row * 0.012, 0.07, 0.29 - row * 0.01))
		if state.item_at("chest").get("family", "") == "aether":
			for tier in range(4): b.add("snow", Vector3(0, 0.06 + tier * 0.055, 0), Vector3(0.34 - tier * 0.055, 0.06, 0.34 - tier * 0.04))
		if state.item_at("chest").get("family", "") == "cinder":
			b.add("iron", Vector3(0, 0.06, 0), Vector3(0.40, 0.18, 0.40))
			for vent in range(3): b.add("window", Vector3(-0.09 + vent * 0.09, 0.06, -0.21), Vector3(0.04, 0.07, 0.025))
		var glove := "skin" if state.item_at("hands").is_empty() else "hands"
		Armor.hand(b, glove, glove != "skin", false,-1.0 if origin.x>0 else 1.0)
		preload("res://scripts/equipment_identity.gd").hand_details(b,state.item_at("hands"),glove,false)
	Armor.limb(b, state, leg)
	if leg:
		for slot in ["legs","feet"]: preload("res://scripts/equipment_identity.gd").limb(b,state.item_at(slot),slot)
	elif origin.x>0: preload("res://scripts/equipment_identity.gd").jewelry(b,state.item_at("ring"),false,true)
	b.finish(limb)
	return limb

static func make_weapon(parent: Node3D, item: Dictionary) -> void:
	if item.is_empty():
		return
	var vox := Blocks.new()
	vox.spatial_batching=false
	var material: StandardMaterial3D = vox.materials.iron.duplicate()
	material.albedo_color = Color(item.get("color", "7c858c"))
	material.roughness = maxf(0.2, 0.48 - int(item.get("quality", 0)) * 0.05)
	preload("res://scripts/equipment_surface.gd").apply(material,item)
	vox.materials.gear = material
	preload("res://scripts/refined_equipment.gd").build(vox,item)
	vox.finish(parent)

static func make_first_person_arm(parent: Node3D, state: RefCounted, main_hand: bool=true) -> void:
	var vox := Blocks.new()
	vox.spatial_batching=false
	var glove: Dictionary = state.item_at("hands")
	var material: StandardMaterial3D = vox.materials.skin.duplicate()
	material.albedo_color = Color(glove.get("color", state.origins[state.origin_id].skin))
	if not glove.is_empty(): preload("res://scripts/equipment_surface.gd").apply(material,glove)
	vox.materials.hand = material
	Armor.hand(vox, "hand", not glove.is_empty(), true,-1.0 if main_hand else 1.0)
	preload("res://scripts/equipment_identity.gd").hand_details(vox,glove,"hand",true)
	if main_hand: preload("res://scripts/equipment_identity.gd").jewelry(vox,state.item_at("ring"),true,true)
	vox.add("cloth", Vector3(0, -0.09, 0.35), Vector3(0.21, 0.20, 0.21))
	vox.finish(parent)
