extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var w=load("res://scenes/main.tscn").instantiate(); root.add_child(w)
	for i in range(8): await physics_frame
	if not w.intro.active or w.player.character.persist or w.atlas.persist or not w.session_save.capture().is_empty():
		push_error("Intro preview startup/isolation failed"); quit(1); return
	w.intro.finish()
	if w.player.character.persist or not w.player.character.intro_completed or w.player.position!=w.player.spawn_point:
		push_error("Intro preview handoff failed"); quit(1); return
	print("INTRO_PREVIEW_COMPLETE startup=passed isolation=passed handoff=passed"); quit()
