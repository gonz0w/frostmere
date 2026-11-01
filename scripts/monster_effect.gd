extends Node3D
# Cosmetic only: no collision, damage or persistent state.
var world: Node3D
var controller: Node3D
var realm := ""
var age := 0.0
var lifetime := .65
var chips: Array[MeshInstance3D]=[]
var destinations: Array[Vector3]=[]
func _process(delta: float) -> void:
	if not is_instance_valid(controller): queue_free(); return
	if not controller.inside or (realm!="" and controller.current!=realm): queue_free(); return
	visible=not world.player.paused
	if world.player.paused: return
	age+=delta
	if age>=lifetime: queue_free(); return
	for i in range(chips.size()):
		chips[i].position=destinations[i]*minf(1,age/.35)
		chips[i].scale=Vector3.ONE*(1.0-age/lifetime)
static func eruption(actor: Node3D, origin: Vector3) -> Node3D:
	var effect=load("res://scripts/monster_effect.gd").new()
	effect.world=actor.adventure.world; effect.controller=actor.adventure; effect.realm="crucible"
	actor.get_parent().add_child(effect); effect.global_position=origin
	var mat:=StandardMaterial3D.new(); mat.albedo_color=Color("ff793e"); mat.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
	for i in range(16):
		var chip:=MeshInstance3D.new(); var mesh:=BoxMesh.new(); mesh.size=Vector3(.22,.5,.22); mesh.material=mat; chip.mesh=mesh
		effect.add_child(chip); effect.chips.append(chip)
		var angle:=TAU*i/16.0
		effect.destinations.append(Vector3(cos(angle)*2, .6+(i%4)*.3,sin(angle)*2))
	return effect
