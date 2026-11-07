extends Node3D
var adventure: Node3D
var direction := Vector3.FORWARD
var speed := 22.0
var damage := 10.0
var hostile := false
var shooter: CollisionObject3D
var lifetime := 3.0
var magic := false
var training_skill: String=""
var critical := false
var chain := 0
var pierces := 0
var pierced: Array[RID] = []
var tint := Color.TRANSPARENT

func _ready() -> void:
	if not hostile and shooter==adventure.world.player: training_skill="magic" if magic else "marksman"
	if training_skill == "marksman": critical = shooter.roll_weapon_critical()
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(0.12, 0.12, 0.3) if magic else Vector3(0.04, 0.04, 0.65)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color("fb9e61") if hostile else Color("8fd4ef") if magic else Color("c3ae8e")
	if tint.a > 0: mat.albedo_color = tint
	mat.emission_enabled = magic
	mat.emission = mat.albedo_color
	mat.emission_energy_multiplier = 2.0
	if adventure.world.accessibility.reduced_flashes:
		mat.emission_enabled=false; mat.albedo_color=mat.albedo_color.darkened(.3)
	box.material = mat
	mesh.mesh = box
	add_child(mesh)
	look_at(global_position + direction)

func _physics_process(delta: float) -> void:
	if adventure.world.player.paused:
		return
	lifetime -= delta
	if lifetime <= 0:
		queue_free()
		return
	var destination := global_position + direction * speed * delta
	var query := PhysicsRayQueryParameters3D.create(global_position, destination, 1 | 2 | 4)
	var ignored: Array[RID]=pierced.duplicate()
	if is_instance_valid(shooter): ignored.append(shooter.get_rid())
	query.exclude=ignored
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	if not hit.is_empty():
		var body: Object = hit.collider
		if hostile and body == adventure.world.player:
			body.receive_damage(damage, global_position)
		elif not hostile and body.has_method("receive_damage") and body != adventure.world.player:
			body.receive_damage(damage, shooter,"",training_skill,critical)
			if pierces>0 and body is CollisionObject3D:
				pierces-=1; damage*=0.7; pierced.append(body.get_rid())
				global_position=hit.position+direction*.01
				return
			if chain > 0 and is_instance_valid(shooter) and shooter.has_method("chain_lightning"):
				shooter.chain_lightning(body, damage, chain)
		if not body.has_method("receive_damage"): adventure.world.audio.sfx("spell" if magic else "block")
		queue_free()
		return
	global_position = destination
