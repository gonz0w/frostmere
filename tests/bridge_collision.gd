extends SceneTree

func _initialize() -> void:
	run.call_deferred()

func run() -> void:
	if DisplayServer.get_name() != "headless" and "--capture" not in OS.get_cmdline_user_args():
		push_error("Use headless mode or --capture for the bridge fixture")
		quit(1)
		return
	var world = load("res://scenes/main.tscn").instantiate()
	root.add_child(world)
	world.capture_done = true
	var player: CharacterBody3D = world.player
	if player.character.persist or world.atlas.persist:
		push_error("Bridge fixture requires an isolated profile")
		quit(1)
		return
	player.set_physics_process(false)
	for frame in range(5):
		await physics_frame
	var failures := 0
	for direction in [-1, 1]:
		# The real player capsule must hit the high crest parapet at jump height.
		if not player.test_move(Transform3D(Basis.IDENTITY, Vector3(14, 1.43, -16)), Vector3(0, 0, direction * 3)):
			push_error("Crest parapet failed to block the player capsule")
			failures += 1
		# Near the approach the cap is lower, so the same kind of sweep clears it.
		if player.test_move(Transform3D(Basis.IDENTITY, Vector3(9.5, 1.06, -16)), Vector3(0, 0, direction * 3)):
			push_error("Approach parapet blocks above the visible cap")
			failures += 1
	player.global_position = Vector3(9.5, .2, -16)
	for destination in [18.5, 9.5]:
		for frame in range(180):
			var remaining := float(destination) - player.position.x
			if absf(remaining) < .10:
				break
			player.velocity = Vector3(signf(remaining) * 4, -2, 0)
			player.move_and_slide()
			await physics_frame
		if absf(player.position.x - float(destination)) >= .10 or player.position.y < 0:
			push_error("Player could not cross the supported bridge deck")
			failures += 1
	print("BRIDGE_COLLISION_COMPLETE failures=%d" % failures)
	quit(1 if failures else 0)
