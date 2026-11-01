extends SceneTree
var failures:=0
func _initialize() -> void: call_deferred("run")
func check(value: bool, message: String) -> void:
	if not value: failures+=1; push_error("FAIL "+message)
func run() -> void:
	var w=load("res://scenes/main.tscn").instantiate(); root.add_child(w); w.capture_done=true
	for i in range(6): await physics_frame
	assert(not w.player.character.persist and not w.atlas.persist)
	var journal=w.hud.world_map
	journal._refresh()
	check(not "most quest lines are planned" in journal.status.text,"Fresh-player journal must not call implemented quests planned")
	journal.selected_quest="roots"; journal._show_quest()
	check(not "Coven rank quests remain planned" in journal.quest_text.text,"Roots journal must not call implemented Coven ranks planned")
	if "--capture" in OS.get_cmdline_user_args():
		w.player.map_open=true; w.player.set_paused(true); journal.show(); journal.tabs.current_tab=2
		for i in range(6): await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://build/owner-review/journal.png")
	w.queue_free(); await process_frame
	print("JOURNAL_PRESENTATION_COMPLETE checks=2 failures=%d"%failures); quit(1 if failures else 0)
