extends RefCounted
## Per-file verified replacement. Never treats an abandoned temp as a new profile.
var status := "new"
var blocked: Dictionary = {}
var recovered: Dictionary = {}
var pending: Dictionary = {}

func future_version(path: String, maximum: int) -> bool:
	if not FileAccess.file_exists(path): return false
	var parser=JSON.new()
	if parser.parse(FileAccess.get_file_as_string(path))!=OK or not parser.data is Dictionary: return false
	var version: Variant=parser.data.get("version")
	return typeof(version) in [TYPE_INT,TYPE_FLOAT] and version>maximum

func load_recover(path: String, loader: Callable, maximum: int) -> bool:
	path=ProjectSettings.globalize_path(path)
	status="blocked"; blocked[path]=true; recovered.erase(path); pending.erase(path)
	if future_version(path,maximum) or future_version(path+".bak",maximum): return false
	if loader.call(path):
		status="loaded"; blocked.erase(path); return true
	if future_version(path+".bak",maximum): return false
	if loader.call(path+".bak"):
		status="recovered"; blocked.erase(path); recovered[path]=true; return true
	if not FileAccess.file_exists(path) and not FileAccess.file_exists(path+".bak") and not FileAccess.file_exists(path+".tmp") and not DirAccess.dir_exists_absolute(path):
		status="new"; blocked.erase(path)
	return false

func write_verified(path: String, text: String, validator: Callable) -> bool:
	var file=FileAccess.open(path,FileAccess.WRITE)
	if file==null: return false
	file.store_string(text); file.flush()
	var error=file.get_error(); file.close()
	return error==OK and validator.call(path)

func save(path: String, text: String, validator: Callable, maximum: int) -> bool:
	path=ProjectSettings.globalize_path(path)
	if blocked.has(path) or future_version(path,maximum) or future_version(path+".bak",maximum): return false
	var exists:=FileAccess.file_exists(path)
	var valid: bool=exists and validator.call(path)
	if exists and not valid and not recovered.has(path): return false
	if not exists and not recovered.has(path) and (FileAccess.file_exists(path+".bak") or (FileAccess.file_exists(path+".tmp") and not pending.has(path))): return false
	pending[path]=true
	if not write_verified(path+".tmp",text,validator): return false
	if valid:
		# Complete and validate a new backup before replacing either durable file.
		if not write_verified(path+".bak.tmp",FileAccess.get_file_as_string(path),validator): return false
		if DirAccess.rename_absolute(path+".bak.tmp",path+".bak")!=OK: return false
	elif exists:
		# Preserve the exact rejected bytes; do not overwrite an earlier diagnosis.
		var rejected:=path+".corrupt"
		var index:=0
		while FileAccess.file_exists(rejected) or DirAccess.dir_exists_absolute(rejected):
			index+=1; rejected=path+".corrupt."+str(index)
		if DirAccess.copy_absolute(path,rejected)!=OK: return false
	if DirAccess.rename_absolute(path+".tmp",path)!=OK: return false
	recovered.erase(path); pending.erase(path)
	return true
