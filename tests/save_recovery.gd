extends SceneTree
const State=preload("res://scripts/character_state.gd")
const Atlas=preload("res://scripts/atlas_state.gd")
var checks:=0
var failures:=0
const BASE="user://save-recovery-fixture/"
func _initialize() -> void: call_deferred("run")
func check(ok: bool, label: String) -> void:
	checks+=1
	if not ok: failures+=1; push_error("FAIL "+label)
	else: print("PASS "+label)
func write(path: String,text: String) -> void:
	var f=FileAccess.open(path,FileAccess.WRITE); assert(f!=null); f.store_string(text); f.close()
func clean() -> void:
	DirAccess.make_dir_recursive_absolute(BASE)
	for name in DirAccess.get_files_at(BASE): DirAccess.remove_absolute(BASE+name)
func run() -> void:
	clean()
	var path=BASE+"character.json"
	var a=State.new(); a.character_name="Last good"; a.gold=321
	check(a.save_to(path),"Initial valid save")
	var first=FileAccess.get_file_as_string(path)
	a.character_name="Latest"; a.gold=654
	check(a.save_to(path),"Second valid save")
	check(FileAccess.file_exists(path+".bak"),"Second save retains last-good backup")
	write(path,"{truncated")
	var b=State.new()
	if not b.has_method("load_with_recovery"):
		check(false,"Recovery interface exists")
	else:
		check(b.load_with_recovery(path),"Corrupt primary recovers validated backup")
		check(b.character_name=="Last good" and b.gold==321,"Recovered inventory/progress state is previous generation")
		check(b.save_to(path),"Recovered state can save without replacing backup with corruption")
		check(FileAccess.get_file_as_string(path+".bak")==first,"Last-good backup preserved after corrupt recovery")
		check(FileAccess.get_file_as_string(path+".corrupt")=="{truncated","Corrupt primary preserved for diagnosis")
		write(path,'{"version":999}')
		var c=State.new()
		check(not c.load_with_recovery(path),"Future version does not silently downgrade to backup")
		check(not c.save_to(path) and FileAccess.get_file_as_string(path)=='{"version":999}',"Future primary cannot be overwritten")
		write(path,"bad"); write(path+".bak","bad backup")
		check(not c.load_with_recovery(path) and not c.save_to(path),"No valid copy blocks writes")
		DirAccess.remove_absolute(path); DirAccess.remove_absolute(path+".bak")
		write(path+".tmp","interrupted")
		var d=State.new()
		check(not d.load_with_recovery(path) and not d.save_to(path),"Only interrupted temp is preserved, not replaced as new game")
	var retry=State.new(); var rp=BASE+"first-retry.json"
	retry.allocated.strength=999
	check(not retry.save_to(rp),"Invalid first save rejected")
	retry.allocated.strength=0
	check(retry.save_to(rp),"Same session retries its own failed first save")
	# Failed replacement and invalid candidate must leave both durable copies intact.
	var fp=BASE+"failure.json"; var good=State.new()
	check(good.save_to(fp),"Failure fixture first save")
	good.gold=999; check(good.save_to(fp),"Failure fixture backup")
	var primary=FileAccess.get_file_as_string(fp); var backup=FileAccess.get_file_as_string(fp+".bak")
	good.allocated.strength=999
	check(not good.save_to(fp),"Invalid outgoing state fails schema validation")
	check(FileAccess.get_file_as_string(fp)==primary and FileAccess.get_file_as_string(fp+".bak")==backup,"Invalid candidate preserves both durable files")
	good.allocated.strength=0
	DirAccess.remove_absolute(fp+".tmp")
	DirAccess.make_dir_absolute(fp+".bak.tmp")
	check(not good.save_to(fp),"Unavailable backup destination rejects save")
	check(FileAccess.get_file_as_string(fp)==primary and FileAccess.get_file_as_string(fp+".bak")==backup,"Backup failure preserves last good copies")
	DirAccess.remove_absolute(fp+".bak.tmp")
	if OS.get_name()!="Windows":
		write(fp+".tmp","read only")
		check(FileAccess.set_unix_permissions(fp+".tmp",FileAccess.UNIX_READ_OWNER)==OK,"Set isolated read-only temp permissions")
		check(not good.save_to(fp),"Permission failure rejects save")
		check(FileAccess.get_file_as_string(fp)==primary and FileAccess.get_file_as_string(fp+".bak")==backup,"Permission failure preserves both durable files")
		FileAccess.set_unix_permissions(fp+".tmp",FileAccess.UNIX_READ_OWNER|FileAccess.UNIX_WRITE_OWNER)
	else: print("SKIP Unix permission fault on Windows")
	check(good.load_with_recovery(fp) and good.save_store.status=="loaded","Valid primary wins over abandoned temp")
	check(good.save_to(fp),"Retry after filesystem repair succeeds")
	DirAccess.remove_absolute(fp)
	var missing=State.new()
	check(missing.load_with_recovery(fp) and missing.save_store.status=="recovered","Missing primary recovers backup")
	var future=BASE+"future-backup.json"; var fstate=State.new()
	check(fstate.save_to(future),"Future backup fixture")
	write(future+".bak",'{"version":999}')
	check(not fstate.load_with_recovery(future) and fstate.save_store.status=="blocked","Newer backup disables writes even beside valid primary")
	# Earlier character schema remains readable and migrates through the validator.
	var legacy=BASE+"legacy.json"
	write(legacy,JSON.stringify({"version":1,"name":"Legacy","origin":"frostkin","archetype":"warrior","allocated":{},"equipment":{}}))
	var old=State.new()
	check(old.load_with_recovery(legacy) and old.character_name=="Legacy","Legacy v1 still loads")
	check(old.save_to(legacy),"Legacy v1 can write current schema with original retained")
	check(JSON.parse_string(FileAccess.get_file_as_string(legacy+".bak")).version==1,"Legacy backup preserves original version")
	# Atlas has the same contract but its own validator and saved state.
	var atlas=Atlas.new(); var ap=BASE+"atlas.json"
	atlas.survey_started=true; atlas.survey_stage=1
	check(atlas.save_to(ap),"Atlas initial save")
	atlas.survey_stage=2; check(atlas.save_to(ap),"Atlas second save")
	write(ap,"truncated")
	var restored=Atlas.new()
	if restored.has_method("load_with_recovery"):
		check(restored.load_with_recovery(ap) and restored.survey_stage==1,"Atlas backup restores validated survey progress")
	else: check(false,"Atlas recovery interface exists")
	clean()
	print("SAVE_RECOVERY_COMPLETE checks=%d failures=%d"%[checks,failures]); quit(1 if failures else 0)
