extends SceneTree
var count := 0
var invalid := false
func walk(path: String) -> void:
	for file in DirAccess.get_files_at(path):
		var full := path.path_join(file)
		var relative := full.trim_prefix("res://")
		var top := relative.get_slice("/", 0)
		if top not in ["assets", "data", "scenes", "scripts", "shaders", ".godot", "project.binary"] or relative.begins_with(".godot/editor/"):
			push_error("Unexpected packaged file: " + relative)
			invalid = true
		count += 1
	for directory in DirAccess.get_directories_at(path):
		walk(path.path_join(directory))
func _initialize() -> void:
	walk("res://")
	if invalid or count == 0 or not ResourceLoader.exists("res://scenes/main.tscn"):
		quit(1)
		return
	print("PACK_CONTENTS_OK files=", count)
	quit()
