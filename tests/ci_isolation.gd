extends SceneTree
# Verify the same headless startup path used by all CI world fixtures.
func _initialize() -> void: call_deferred("run")
func run() -> void:
	if DisplayServer.get_name() != "headless":
		push_error("Isolation fixture requires headless execution"); quit(1); return
	var world=load("res://scenes/main.tscn").instantiate()
	root.add_child(world)
	for i in range(6): await physics_frame
	if world.player.character.persist or world.atlas.persist or world.player.migration_status != "isolated":
		push_error("Normal profile persistence must be disabled in CI"); quit(1); return
	world.queue_free()
	await process_frame
	print("ISOLATION_COMPLETE failures=0")
	quit()
