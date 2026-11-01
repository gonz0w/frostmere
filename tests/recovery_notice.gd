extends SceneTree
const State=preload("res://scripts/character_state.gd")
const Atlas=preload("res://scripts/atlas_state.gd")
func _initialize() -> void: call_deferred("run")
func run() -> void:
	assert(OS.get_user_data_dir().ends_with("Frostmere-Recovery-QA"))
	assert(DisplayServer.get_name()!="headless")
	var args=OS.get_cmdline_user_args()
	if "--prepare" in args:
		for name in DirAccess.get_files_at("user://"):
			if name.begins_with("character-v1.json") or name.begins_with("atlas-progress-v1.json"):
				DirAccess.remove_absolute("user://"+name)
		var c=State.new(); c.intro_completed=true; c.character_name="Native recovery"
		assert(c.save_to(State.SAVE_PATH)); c.gold=777; assert(c.save_to(State.SAVE_PATH))
		var a=Atlas.new(); assert(a.save_to(Atlas.SAVE_PATH)); assert(a.save_to(Atlas.SAVE_PATH))
		var f=FileAccess.open(State.SAVE_PATH,FileAccess.WRITE); f.store_string("corrupt native primary"); f.close()
		print("RECOVERY_NOTICE_PREPARED"); quit(); return
	if "--blocked" in args:
		var f=FileAccess.open(Atlas.SAVE_PATH,FileAccess.WRITE); f.store_string('{"version":999}'); f.close()
	var world=load("res://scenes/main.tscn").instantiate(); root.add_child(world)
	world.capture_done=true; world.audio.enabled=false
	for i in range(10): await physics_frame
	var blocked="--blocked" in args
	assert(world.player.character.persist==not blocked and world.atlas.persist==not blocked)
	assert(world.player.character.save_store.status=="recovered")
	assert(world.player.character.character_name=="Native recovery")
	var notice: AcceptDialog
	for child in world.hud.get_children():
		if child is AcceptDialog: notice=child
	assert(notice!=null and notice.visible)
	assert(notice.ok_button_text==("Continue without saving" if blocked else "Continue with recovered save"))
	await create_timer(1).timeout
	root.get_texture().get_image().save_png("res://build/recovery-"+("blocked" if blocked else "notice")+".png")
	notice.confirmed.emit(); await process_frame
	print("RECOVERY_NOTICE_COMPLETE blocked=%s failures=0"%blocked)
	world.queue_free(); await process_frame; quit()
