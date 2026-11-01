extends SceneTree
const State=preload("res://scripts/character_state.gd")
const Atlas=preload("res://scripts/atlas_state.gd")
const BASE="user://recovery-restart-fixture/"
func _initialize() -> void: call_deferred("run")
func run() -> void:
	assert(DisplayServer.get_name()=="headless")
	assert(DirAccess.make_dir_recursive_absolute(BASE)==OK)
	var cp=BASE+"character.json"; var ap=BASE+"atlas.json"
	if "--prepare" in OS.get_cmdline_user_args():
		for name in DirAccess.get_files_at(BASE): DirAccess.remove_absolute(BASE+name)
		var c=State.new(); c.character_name="Restart proof"; c.gold=777
		var uid=c.add_item("iron_sword"); c.inventory[uid].quality=2; c.equip(uid,"main_hand")
		c.adventure.accepted=true
		assert(c.save_to(cp)); c.gold=888; assert(c.save_to(cp))
		var a=Atlas.new(); a.survey_started=true; a.survey_stage=1; a.visits["crossing"]=true
		assert(a.save_to(ap)); a.survey_stage=2; assert(a.save_to(ap))
		for path in [cp,ap]:
			var f=FileAccess.open(path,FileAccess.WRITE); f.store_string("interrupted primary"); f.close()
		print("RECOVERY_RESTART_PREPARED")
	else:
		var c=State.new(); var a=Atlas.new()
		assert(c.load_with_recovery(cp) and a.load_with_recovery(ap))
		assert(c.character_name=="Restart proof" and c.gold==777 and c.adventure.accepted)
		assert(c.inventory[c.equipment.main_hand].quality==2)
		assert(a.survey_stage==1 and a.visits.has("crossing"))
		assert(c.save_to(cp) and a.save_to(ap))
		assert(State.new().load_from(cp) and Atlas.new().load_from(ap))
		for name in DirAccess.get_files_at(BASE): DirAccess.remove_absolute(BASE+name)
		print("RECOVERY_RESTART_COMPLETE failures=0")
	quit()
