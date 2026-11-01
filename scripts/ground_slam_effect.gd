extends "res://scripts/monster_effect.gd"
static var debris_meshes: Array[BoxMesh]=[]
# Terrain-following cosmetic debris; no collision or damage.
func _process(delta: float) -> void:
	super._process(delta)
	if is_queued_for_deletion() or not visible: return
	for i in range(chips.size()):
		var outward: Vector3=destinations[i]*(.45+age*1.4)
		var at:=global_position+outward
		chips[i].global_position=Vector3(at.x,world.Terrain.height_at(at.x,at.z)+.15+sin(PI*age/lifetime)*(.45+(i%4)*.12),at.z)
		chips[i].rotation=Vector3(age*3,age*(i%3-1)*4,age*2)
static func spawn(actor: Node3D, origin: Vector3) -> Node3D:
	var effect=load("res://scripts/ground_slam_effect.gd").new()
	effect.world=actor.adventure.world; effect.controller=actor.adventure
	effect.name="GroundSlamDebris"; actor.adventure.add_child(effect); effect.global_position=origin
	if debris_meshes.is_empty():
		for earth in [false,true]:
			var mat=StandardMaterial3D.new(); mat.albedo_color=Color("79644a") if earth else Color("788474")
			var mesh=BoxMesh.new(); mesh.size=Vector3(.34,.16,.3) if earth else Vector3(.23,.28,.23); mesh.material=mat
			debris_meshes.append(mesh)
	for i in range(24):
		var chip=MeshInstance3D.new(); chip.mesh=debris_meshes[1 if i%3==0 else 0]
		effect.add_child(chip); effect.chips.append(chip)
		var angle:=TAU*i/24.0
		effect.destinations.append(Vector3(cos(angle),0,sin(angle))*(1.2+(i%3)*.3))
	effect._process(0)
	return effect
