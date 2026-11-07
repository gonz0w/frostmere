extends SceneTree
const Settings=preload("res://scripts/control_settings.gd")
func _initialize() -> void:
	var s=Settings.new()
	assert(s.bindings.has("skills") and s.bindings.has("finisher") and s.bindings.has("power_sunder"))
	var key=InputEventKey.new(); key.physical_keycode=KEY_J; key.pressed=true
	assert(s.rebind("interact",key).is_empty())
	assert(s.label("interact")=="J")
	assert(not s.rebind("inventory",key).is_empty())
	assert(s.label("inventory")=="I")
	key.shift_pressed=true
	assert(not s.rebind("inventory",key).is_empty())
	key.shift_pressed=false
	key.physical_keycode=KEY_ESCAPE
	assert(not s.rebind("interact",key).is_empty())
	var mouse=InputEventMouseButton.new(); mouse.button_index=MOUSE_BUTTON_MIDDLE; mouse.pressed=true
	assert(s.rebind("attack",mouse).is_empty())
	s.apply()
	Input.action_press("move_forward")
	s.apply()
	assert(not Input.is_action_pressed("move_forward"))
	assert(InputMap.action_get_events("attack").size()==1)
	assert(InputMap.action_get_events("attack")[0].button_index==MOUSE_BUTTON_MIDDLE)
	key.physical_keycode=KEY_P
	assert(s.rebind("spell",key).is_empty())
	assert(s.format_prompt("LMB attack · Q Emberbolt · F healing potion").contains("MMB attack · P Emberbolt"))
	assert(s.format_prompt("Q: Emberbolt · B change").begins_with("P:"))
	s.sensitivity=0.004; s.invert_y=true
	const PATH="res://build/control-settings-fixture.json"
	assert(DirAccess.make_dir_recursive_absolute("res://build")==OK)
	assert(s.save_to(PATH))
	var original=FileAccess.get_file_as_string(PATH)
	assert(DirAccess.make_dir_absolute(PATH+".tmp")==OK)
	assert(not s.save_to(PATH) and FileAccess.get_file_as_string(PATH)==original)
	DirAccess.remove_absolute(PATH+".tmp")
	var copy=Settings.new(); assert(copy.load_from(PATH))
	assert(copy.label("interact")=="J" and copy.invert_y and is_equal_approx(copy.sensitivity,0.004))
	assert(copy.format_prompt("[ E ] Use · M Map")=="[ J ] Use · M Map")
	var f=FileAccess.open(PATH,FileAccess.WRITE); f.store_string('{"version":999}'); f.close()
	assert(not copy.load_from(PATH) and copy.label("interact")=="J")
	copy.restore_defaults(); copy.apply()
	assert(copy.label("interact")=="E" and not copy.invert_y)
	assert(is_equal_approx(copy.sensitivity,0.0023))
	DirAccess.remove_absolute(PATH)
	print("CONTROL_SETTINGS_COMPLETE failures=0"); quit()
