extends SceneTree

var failures := 0
var world: Node3D
var player: CharacterBody3D

func _initialize() -> void:
	call_deferred("_run")

func _check(condition: bool, message: String) -> void:
	if condition:
		print("PASS " + message)
	else:
		push_error("FAIL " + message)
		failures += 1

func _frames(count: int) -> void:
	for i in range(count):
		await physics_frame

func _run() -> void:
	world = load("res://scenes/main.tscn").instantiate()
	root.add_child(world)
	await _frames(30)
	player = world.player
	_check(world.block_count > 5000, "Scene builds batched voxel environment")
	_check(player.is_on_floor(), "Player settles on ground")
	_check(player.third_person and player.avatar.visible, "Starts in third person")
	player.set_third_person(false)
	await _frames(2)
	_check(not player.avatar.visible and player.spring.spring_length == 0, "First person hides avatar and retracts camera")
	player.set_third_person(true)
	_check(player.avatar.visible and player.spring.spring_length > 4, "Third person restores avatar and camera")
	Input.action_press("jump")
	await _frames(8)
	Input.action_release("jump")
	_check(player.position.y > 0.35, "Jump lifts player off ground")
	await _frames(65)
	_check(player.is_on_floor(), "Jump lands back on ground")
	var start := player.position
	Input.action_press("move_forward")
	await _frames(90)
	Input.action_release("move_forward")
	_check(player.position.z < start.z - 5, "Forward movement traverses trail")
	var before_sprint: float = player.stamina
	Input.action_press("sprint")
	Input.action_press("move_forward")
	await _frames(30)
	Input.action_release("sprint")
	Input.action_release("move_forward")
	_check(player.stamina < before_sprint - 1, "Sprint consumes stamina")
	player.set_paused(true)
	var paused_position := player.position
	Input.action_press("move_forward")
	await _frames(10)
	Input.action_release("move_forward")
	_check(player.position.is_equal_approx(paused_position), "Pause stops player movement")
	player.set_paused(false)
	player.position = Vector3(6.5, 0.1, -16)
	player.velocity = Vector3.ZERO
	player.rotation.y = -PI / 2
	await _frames(10)
	Input.action_press("move_forward")
	await _frames(215)
	Input.action_release("move_forward")
	_check(player.position.x > 20 and player.position.y > -0.3, "Player walks across entire bridge without jumping")
	print("BRIDGE_END ", player.position)
	player.position = Vector3(-10, 0.1, -1.5)
	player.velocity = Vector3.ZERO
	player.rotation.y = 0
	await _frames(5)
	Input.action_press("move_forward")
	await _frames(52)
	Input.action_release("move_forward")
	_check(player.position.z < -4.2 and player.position.y > 0.1, "Player walks through doorway onto interior floor")
	print("HOUSE_END ", player.position)
	# Approach a side wall from outside; it must stop the capsule.
	player.position = Vector3(-3.8, 0.2, -8)
	player.velocity = Vector3.ZERO
	player.rotation.y = PI / 2
	await _frames(5)
	Input.action_press("move_forward")
	await _frames(55)
	Input.action_release("move_forward")
	_check(player.position.x > -5.65, "House wall blocks movement")
	player.respawn()
	await _frames(10)
	_check(player.position.distance_to(player.spawn_point) < 0.5, "Return-to-trail restores safe spawn")
	player.position = Vector3(31, 0.2, -30)
	await _frames(3)
	_check(world.discovered.has("The Watcher's Stones"), "Ruin landmark can be discovered")
	world.queue_free()
	await process_frame
	print("SMOKE_COMPLETE failures=%d" % failures)
	quit(1 if failures else 0)
