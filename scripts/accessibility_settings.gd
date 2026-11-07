extends RefCounted
signal changed
const PATH="user://accessibility-v1.json"
const FLAGS=["subtitle_backdrop","reduced_motion","reduced_flashes","show_fragments"]
var subtitle_scale:=1.0
var subtitle_backdrop:=false
var reduced_motion:=false
var reduced_flashes:=false
var show_fragments:=true
var load_warning:=""
func motion_factor() -> float: return .15 if reduced_motion else 1.0
func restore_defaults() -> void:
	subtitle_scale=1.0; subtitle_backdrop=false; reduced_motion=false; reduced_flashes=false; show_fragments=true
	changed.emit()
func save_to(path: String) -> bool:
	var data={"version":1,"subtitle_scale":subtitle_scale}
	for flag in FLAGS: data[flag]=get(flag)
	var file=FileAccess.open(path+".tmp",FileAccess.WRITE)
	if file==null: return false
	file.store_string(JSON.stringify(data)); file.flush()
	var error=file.get_error(); file.close()
	if error!=OK: return false
	return DirAccess.rename_absolute(path+".tmp",path)==OK
func load_from(path: String) -> bool:
	if not FileAccess.file_exists(path): return false
	var parser=JSON.new()
	if parser.parse(FileAccess.get_file_as_string(path))!=OK or not parser.data is Dictionary: return false
	var data: Dictionary=parser.data
	if data.get("version")!=1 or data.get("subtitle_scale") not in [1.0,1.25,1.5]: return false
	for flag in FLAGS:
		if typeof(data.get(flag))!=TYPE_BOOL: return false
	subtitle_scale=float(data.subtitle_scale)
	for flag in FLAGS: set(flag,data[flag])
	changed.emit(); return true
