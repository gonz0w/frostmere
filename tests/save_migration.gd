extends SceneTree
const Migration=preload("res://scripts/save_migration.gd")
const State=preload("res://scripts/character_state.gd")
const Atlas=preload("res://scripts/atlas_state.gd")
const BASE="res://build/migration-fixture 雪/"
func _initialize() -> void: call_deferred("run")
func put(path: String, text: String) -> void:
	var f=FileAccess.open(path,FileAccess.WRITE); assert(f!=null); f.store_string(text); f.close()
func pair(id: String) -> Array:
	var old=BASE+id+"/"+Migration.LEGACY; var dest=BASE+id+"/Frostmere"
	assert(DirAccess.make_dir_recursive_absolute(old)==OK)
	assert(DirAccess.make_dir_recursive_absolute(dest)==OK)
	return [old,dest]
func clear_fixture(path: String) -> void:
	assert(path.begins_with(BASE))
	var dir=DirAccess.open(path)
	if dir==null: return
	dir.include_hidden=true
	for name in dir.get_files(): assert(dir.remove(name)==OK)
	for name in dir.get_directories():
		assert(not dir.is_link(name))
		clear_fixture(path.path_join(name))
	assert(DirAccess.remove_absolute(path)==OK)
func run() -> void:
	if "--prepare" in OS.get_cmdline_user_args(): clear_fixture(BASE)
	var p=pair("restart")
	if "--prepare" in OS.get_cmdline_user_args():
		var c=State.new(); c.character_name="Migration proof"; c.gold=777; c.intro_completed=true
		c.adventure.accepted=true
		var uid=c.add_item("iron_sword"); c.inventory[uid].quality=2; c.equip(uid,"main_hand")
		assert(c.save_to(p[0]+"/character-v1.json"))
		var a=Atlas.new(); a.survey_started=true; a.survey_stage=1; a.visits["crossing"]=true
		assert(a.save_to(p[0]+"/atlas-progress-v1.json"))
		put(p[0]+"/audio.cfg",'[audio]\nmaster=0.4\n')
		assert(Migration.migrate_sibling(p[1])=="migrated")
		print("MIGRATION_PREPARED"); quit(); return
	assert(Migration.migrate_sibling(p[1])=="complete")
	var c=State.new(); var a=Atlas.new()
	assert(c.load_with_recovery(p[1]+"/character-v1.json"))
	assert(c.character_name=="Migration proof" and c.gold==777 and c.adventure.accepted)
	assert(c.inventory[c.equipment.main_hand].quality==2)
	assert(a.load_with_recovery(p[1]+"/atlas-progress-v1.json") and a.survey_stage==1 and a.visits.has("crossing"))
	assert(FileAccess.get_file_as_bytes(p[0]+"/character-v1.json")==FileAccess.get_file_as_bytes(p[1]+"/character-v1.json"))
	assert(FileAccess.get_file_as_string(p[1]+"/audio.cfg").contains("0.4"))
	# Destination precedence is whole-profile; never merge an old atlas into a new character.
	p=pair("conflict"); put(p[0]+"/atlas-progress-v1.json","old atlas"); put(p[1]+"/character-v1.json","new character")
	assert(Migration.migrate_sibling(p[1])=="existing")
	assert(not FileAccess.file_exists(p[1]+"/atlas-progress-v1.json"))
	assert(FileAccess.get_file_as_string(p[1]+"/character-v1.json")=="new character")
	DirAccess.remove_absolute(p[1]+"/character-v1.json")
	assert(Migration.migrate_sibling(p[1])=="complete")
	# Failed/interrupted commit must not accept a partial destination as a complete profile.
	p=pair("pending"); put(p[0]+"/character-v1.json","old")
	assert(DirAccess.make_dir_absolute(p[1]+"/"+Migration.PENDING)==OK)
	put(p[1]+"/character-v1.json","partial")
	assert(Migration.migrate_sibling(p[1])=="blocked")
	assert(FileAccess.get_file_as_string(p[1]+"/character-v1.json")=="partial")
	# Preserve corrupt bytes, valid backups, abandoned temp and diagnostic siblings exactly.
	p=pair("recovery"); assert(c.save_to(p[0]+"/character-v1.json.bak"))
	for suffix in ["", ".tmp", ".bak.tmp", ".corrupt", ".corrupt.2"]: put(p[0]+"/character-v1.json"+suffix,"rejected bytes")
	put(p[0]+"/unrelated.txt","do not migrate")
	assert(Migration.migrate_sibling(p[1])=="migrated")
	var loaded=State.new(); assert(loaded.load_with_recovery(p[1]+"/character-v1.json") and loaded.save_store.status=="recovered")
	assert(FileAccess.get_file_as_string(p[1]+"/character-v1.json.corrupt.2")=="rejected bytes")
	assert(not FileAccess.file_exists(p[1]+"/unrelated.txt"))
	p=pair("future"); put(p[0]+"/character-v1.json",'{"version":999}')
	assert(Migration.migrate_sibling(p[1])=="migrated")
	loaded=State.new(); assert(not loaded.load_with_recovery(p[1]+"/character-v1.json") and loaded.save_store.status=="blocked")
	p=pair("write-failure"); put(p[0]+"/character-v1.json","original")
	assert(DirAccess.make_dir_absolute(p[1]+"/"+Migration.DONE)==OK)
	assert(Migration.migrate_sibling(p[1])=="blocked")
	assert(FileAccess.get_file_as_string(p[0]+"/character-v1.json")=="original")
	p=pair("empty"); assert(Migration.migrate_sibling(p[1])=="none")
	p=pair("bad-target"); put(p[1]+"/"+Migration.DONE,"invalid marker")
	assert(Migration.migrate_sibling(p[1])=="blocked")
	assert(Migration.before_load(true)=="isolated")
	print("MIGRATION_COMPLETE failures=0"); quit()
