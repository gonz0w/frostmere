extends RefCounted

# Explicit --capture --package-smoke mode only; normal play never calls this.
static func capture(world: Node, image: Image) -> void:
	if world.player.character.persist or world.atlas.persist or world.audio.streams.size() != 35:
		push_error("Package QA persistence/audio validation failed")
		world.get_tree().quit(1)
		return
	for stream in world.audio.streams.values():
		if stream.get_length() <= 0:
			push_error("Empty packaged audio stream")
			world.get_tree().quit(1)
			return
	var folder := OS.get_environment("TMPDIR")
	if folder.is_empty(): folder = "user://"
	var screenshot := folder.path_join("frostmere-package.png")
	if image.save_png(screenshot) != OK:
		world.get_tree().quit(1)
		return
	var notices := FileAccess.open(folder.path_join("frostmere-third-party.txt"), FileAccess.WRITE)
	if notices == null:
		world.get_tree().quit(1)
		return
	notices.store_string("GODOT ENGINE AND THIRD-PARTY NOTICES\n\n" + Engine.get_license_text() + "\n\n" + JSON.stringify(Engine.get_copyright_info(), "\t") + "\n\n" + JSON.stringify(Engine.get_license_info(), "\t"))
	notices.close()
	print("PACKAGE_SMOKE_COMPLETE audio=35 persistence=disabled blocks=%d screenshot=%s" % [world.block_count, screenshot])
	world.get_tree().quit()
