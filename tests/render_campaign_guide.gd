extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var w=load("res://scenes/main.tscn").instantiate(); root.add_child(w); w.capture_done=true
	for i in range(6): await physics_frame
	assert(not w.player.character.persist and not w.atlas.persist)
	w.player.set_physics_process(false)
	w.player.character.story_completed=["stonewake","council","archive"]
	w.player.character.adventure.rewarded=true
	w.player.character.stonewake.rewarded=true
	w.hud.notice_time=0
	for i in range(4): await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://build/campaign-open-paths.png")
	w.hud.world_map.selected_quest="lens"
	w.hud.world_map.tabs.current_tab=2
	w.player.map_open=true; w.player.set_paused(true)
	w.hud.world_map._show_quest(); w.hud.world_map._refresh()
	for i in range(4): await process_frame
	w.hud.world_map.quest_text.get_v_scroll_bar().value=w.hud.world_map.quest_text.get_v_scroll_bar().max_value
	for i in range(2): await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://build/campaign-route-journal.png")
	print("CAMPAIGN_GUIDE_RENDER_COMPLETE"); quit()
