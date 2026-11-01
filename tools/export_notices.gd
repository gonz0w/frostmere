extends SceneTree
func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() != 1:
		quit(1)
		return
	var file := FileAccess.open(args[0], FileAccess.WRITE)
	if file == null:
		quit(1)
		return
	file.store_string("GODOT ENGINE AND THIRD-PARTY NOTICES\n\n" + Engine.get_license_text() + "\n\n" + JSON.stringify(Engine.get_copyright_info(), "\t") + "\n\n" + JSON.stringify(Engine.get_license_info(), "\t"))
	file.close()
	quit()
