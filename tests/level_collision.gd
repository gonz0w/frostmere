extends SceneTree

var failures := 0
var world: Node3D
var player: CharacterBody3D

func _initialize() -> void:
	run.call_deferred()

func check(condition: bool, label: String) -> void:
	if not condition:
		failures += 1
		push_error(label)

func blocks(start: Vector3, motion: Vector3) -> bool:
	return player.test_move(Transform3D(Basis.IDENTITY, start), motion)

# Match the actual batched porch surface to the physical support beneath it.
func porch_matches(point: Vector3) -> bool:
	for path_mesh in world.get_children():
		if not path_mesh is MultiMeshInstance3D or not path_mesh.name.begins_with("Blocks_path"):
			continue
		for index in range(path_mesh.multimesh.instance_count):
			var piece: Transform3D = path_mesh.multimesh.get_instance_transform(index)
			var size := piece.basis.get_scale()
			if not is_equal_approx(size.x, 2.3) or not is_equal_approx(piece.origin.x, point.x):
				continue
			if absf(piece.origin.z - point.z) > size.z / 2:
				continue
			var ray := PhysicsRayQueryParameters3D.create(point + Vector3.UP, point - Vector3.UP, 1)
			var support := world.get_world_3d().direct_space_state.intersect_ray(ray)
			if support.is_empty():
				return false
			var top := piece.origin.y + size.y / 2
			# The lowest tread can disappear into the existing ground.
			return top <= support.position.y + .05
	return false

func run() -> void:
	if DisplayServer.get_name() != "headless" and "--capture" not in OS.get_cmdline_user_args():
		quit(1)
		return
	world = load("res://scenes/main.tscn").instantiate()
	root.add_child(world)
	world.capture_done = true
	player = world.player
	if player.character.persist or world.atlas.persist:
		quit(1)
		return
	player.set_physics_process(false)
	for frame in range(5):
		await physics_frame
	for record in world.building_records:
		var origin: Vector3 = record.origin
		var front: float = record.depth / 2.0
		if DisplayServer.get_name() != "headless":
			check(porch_matches(origin + Vector3(0, 0, front + .26)), record.id + " inner tread is supported")
			check(porch_matches(origin + Vector3(0, 0, front + 1.36)), record.id + " outer tread is supported")
		check(blocks(origin + Vector3(0, .29, front + .23), Vector3.DOWN * .15), record.id + " inner porch support")
		check(blocks(origin + Vector3(0, .03, front + 1.37), Vector3.DOWN * .18), record.id + " outer porch support")
		check(not blocks(origin + Vector3(0, .3, front + 1), Vector3(0, 0, -1.6)), record.id + " door clearance above the ramp")
		check(blocks(origin + Vector3(0, .4, -front - .85), Vector3(0, 0, 1.4)), record.id + " rear wall")
	for realm in [world.realms.roots.aeralis, world.realms.roots.crucible]:
		for seam in [4.5, -.5, -17.5, -23.5]:
			check(blocks(realm.position + Vector3(0, .2, seam), Vector3.DOWN * .35), "Realm bridge support at " + str(seam))
	check(blocks(world.archive_chapter.ORIGIN + Vector3(2.95, .05, -26.8), Vector3(0, 0, -.5)), "Pinehall archive projecting jamb")
	check(blocks(world.mountain.ORIGIN + Vector3(4, .05, -64.7), Vector3(0, 0, -1.1)), "Wyrmkeep outpost crate")
	check(blocks(world.shore.ORIGIN + Vector3(-23, .22, 26), Vector3.DOWN * .1), "Saltbreak dock continuous deck")
	check(blocks(world.convergence.ORIGIN + Vector3(15, .02, 25.3), Vector3(0, 0, -1.1)), "Mirewatch forge pedestal")
	check(blocks(world.threshold.ORIGIN + Vector3(10, .05, 27.3), Vector3(0, 0, -1.1)), "Station fabrication pedestal")
	for chapter in [world.threshold, world.convergence]:
		var forge: Vector3 = chapter.ORIGIN + chapter.NODES.forge
		chapter.inside = true
		player.global_position = forge + Vector3(0, .05, 1.3)
		check(chapter.station_nearby() == "forge", "Forge usable from a standing position")
		check(world.session_save.supported_position(player.global_position, player), "Forge approach is safe to resume")
		check(not world.session_save.supported_position(forge + Vector3.UP * .1, player), "Forge interior cannot be resumed")
		chapter.inside = false
	var gate_approach: Vector3 = world.threshold.ORIGIN + Vector3(0, .08, -41)
	check(blocks(gate_approach, Vector3(0, 0, -4)), "Station air gate blocks before repair")
	world.threshold.state.threshold.air = true
	world.threshold._refresh()
	await physics_frame
	check(not blocks(gate_approach, Vector3(0, 0, -4)), "Station air gate clears after repair")
	var sky: Vector3 = world.realms.roots.aeralis.position
	check(blocks(sky + Vector3(-7, .05, 11.5), Vector3(0, 0, -1.2)), "Aeralis crystal base")
	var furnace: Vector3 = world.realms.roots.crucible.position
	check(blocks(furnace + Vector3(6, .05, -38.5), Vector3(0, 0, -1.3)), "Crucible rear iron pillar")
	print("LEVEL_COLLISION_COMPLETE failures=%d" % failures)
	quit(1 if failures else 0)
