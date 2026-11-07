extends SceneTree
## Run only in a copied project with the named custom user directory.
const Migration=preload("res://scripts/save_migration.gd")
const State=preload("res://scripts/character_state.gd")
const Atlas=preload("res://scripts/atlas_state.gd")
func _initialize() -> void: call_deferred("run")
func run() -> void:
	assert(OS.get_user_data_dir().ends_with("Frostmere-Migration-QA"))
	assert(ProjectSettings.get_setting("application/config/use_custom_user_dir",false))
	assert(DisplayServer.get_name()!="headless")
	var old="user://historical-fixture"
	if "--prepare" in OS.get_cmdline_user_args():
		assert(DirAccess.make_dir_recursive_absolute(old)==OK)
		var c=State.new(); c.character_name="Native migration"; c.gold=777; c.intro_completed=true
		assert(c.save_to(old+"/character-v1.json"))
		var a=Atlas.new(); a.survey_started=true; a.survey_stage=1; a.visits["crossing"]=true
		assert(a.save_to(old+"/atlas-progress-v1.json"))
		assert(Migration.migrate(old,"user://")=="migrated")
		print("NATIVE_MIGRATION_PREPARED"); quit(); return
	assert(Migration.migrate(old,"user://")=="complete")
	var world=load("res://scenes/main.tscn").instantiate(); root.add_child(world)
	world.capture_done=true; world.audio.enabled=false
	for i in range(10): await physics_frame
	assert(world.player.migration_status=="isolated") # Custom QA dirs do not scan real historical saves.
	assert(world.player.character.persist and world.atlas.persist)
	assert(world.player.character.character_name=="Native migration" and world.player.character.gold==777)
	assert(world.atlas.survey_stage==1 and world.atlas.visits.has("crossing"))
	assert(world.player.character.save_to(State.SAVE_PATH) and world.atlas.save_to(Atlas.SAVE_PATH))
	assert(State.new().load_from(old+"/character-v1.json"))
	print("NATIVE_MIGRATION_COMPLETE failures=0")
	world.queue_free(); await process_frame; quit()
