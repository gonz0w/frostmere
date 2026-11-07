extends RefCounted
## Copy-only identity migration. A pending transaction always disables saving.
const LEGACY="SkyrimCraft • Frostmere"
const DONE="identity-migration-v1.txt"
const PENDING=".identity-migration-pending"
const COMPLETE="Frostmere identity migration v1 complete\n"

static func before_load(isolated: bool) -> String:
	# Custom directories belong to their caller (including native QA fixtures).
	if isolated or ProjectSettings.get_setting("application/config/use_custom_user_dir",false): return "isolated"
	return migrate_sibling(OS.get_user_data_dir())

static func migrate_sibling(destination: String) -> String:
	if destination.get_file()!="Frostmere": return "blocked"
	return migrate(destination.get_base_dir().path_join(LEGACY),destination)

static func profile_file(name: String) -> bool:
	return name=="audio.cfg" or name=="character-v1.json" or name.begins_with("character-v1.json.") or name=="atlas-progress-v1.json" or name.begins_with("atlas-progress-v1.json.")

static func exists(path: String) -> bool:
	return FileAccess.file_exists(path) or DirAccess.dir_exists_absolute(path)

static func migrate(source: String, destination: String) -> String:
	source=ProjectSettings.globalize_path(source); destination=ProjectSettings.globalize_path(destination)
	var pending=destination.path_join(PENDING); var done=destination.path_join(DONE)
	if exists(pending): return "blocked"
	if DirAccess.dir_exists_absolute(done): return "blocked"
	if exists(done): return "complete" if FileAccess.get_file_as_string(done)==COMPLETE else "blocked"
	if not exists(source): return "none"
	var old=DirAccess.open(source); var target=DirAccess.open(destination)
	if old==null or target==null: return "blocked"
	# Never combine snapshots from two adventures, even when one file is invalid.
	var existing=false
	for name in target.get_files()+target.get_directories():
		if profile_file(name): existing=true
	var files: PackedStringArray=[]
	if not existing:
		for name in old.get_directories():
			if profile_file(name): return "blocked"
		for name in old.get_files():
			if profile_file(name):
				if old.is_link(name): return "blocked"
				files.append(name)
		if files.is_empty(): return "none"
	# Directory creation provides an exclusive transaction guard. Leave it on any
	# failure; a later process must not load a partially copied profile.
	if DirAccess.make_dir_absolute(pending)!=OK: return "blocked"
	for name in files:
		var origin=source.path_join(name); var staged=pending.path_join(name)
		if DirAccess.copy_absolute(origin,staged)!=OK: return "blocked"
		if FileAccess.get_sha256(origin).is_empty() or FileAccess.get_sha256(origin)!=FileAccess.get_sha256(staged): return "blocked"
	for name in files:
		if exists(destination.path_join(name)): return "blocked"
		if DirAccess.rename_absolute(pending.path_join(name),destination.path_join(name))!=OK: return "blocked"
	var marker=FileAccess.open(done,FileAccess.WRITE)
	if marker==null: return "blocked"
	marker.store_string(COMPLETE); marker.flush()
	var error=marker.get_error(); marker.close()
	if error!=OK or FileAccess.get_file_as_string(done)!=COMPLETE: return "blocked"
	if DirAccess.remove_absolute(pending)!=OK: return "blocked"
	return "existing" if existing else "migrated"
