extends SceneTree
var checks:=0
var failures:=0
func _initialize() -> void: call_deferred("run")
func check(ok: bool,label: String) -> void:
	checks+=1
	if ok: print("PASS "+label)
	else: failures+=1; push_error("FAIL "+label)
func talk(t: Node,p: Node,clan: String) -> void:
	t.close_dialog(); p.set_paused(false); p.position=t.ORIGIN+t.NODES[clan]+Vector3.BACK; t.open_dialog(clan)
func run() -> void:
	var world=load("res://scenes/main.tscn").instantiate(); root.add_child(world); world.capture_done=true; world.audio.enabled=false
	for i in range(6): await physics_frame
	assert(not world.player.character.persist and not world.atlas.persist)
	var p=world.player; var s=p.character; var t=world.mountain
	p.set_physics_process(false)
	s.story_completed.append("stonewake"); s.story_completed.append("council"); t.enter()
	for e in t.enemies: e.set_physics_process(false)
	s.mountain={"accepted":true,"heard":["stoneguard","stormweaver"],"ledger":true,"settlement":"accord","clan":"stoneguard","wards":["west","south","east"],"rank":2,"services":["supply_west","supply_east"],"reputation":{"stoneguard":50,"stormweaver":50},"defeated":["pass_0","pass_1","pass_2"],"looted":[],"expedition":true}
	s.wilderness={"defeated":["wild_11","wild_12"],"looted":["wild_11","wild_12"]}
	talk(t,p,"stoneguard")
	for i in range(5): await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://build/clan-voice-choice.png")
	t.act("mandate:holds")
	for i in range(5): await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://build/clan-voice-complete.png")
	print("CLAN_VOICE_RENDER_COMPLETE"); quit()
