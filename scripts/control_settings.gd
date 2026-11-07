extends RefCounted
signal changed
const PATH="user://controls-v1.json"
const DEFAULT_KEYS={"move_forward":KEY_W,"move_back":KEY_S,"move_left":KEY_A,"move_right":KEY_D,
	"jump":KEY_SPACE,"sprint":KEY_SHIFT,"camera_toggle":KEY_V,"respawn":KEY_R,
	"cycle_spell":KEY_B,"spell":KEY_Q,"heal":KEY_F,"inventory":KEY_I,"interact":KEY_E,
	"character":KEY_C,"world_map":KEY_M,"help":KEY_H,"performance":KEY_F3,
	"skills":KEY_K,"finisher":KEY_X,"power_spin":KEY_G,"power_sunder":KEY_G}
const TITLES={"move_forward":"Move forward","move_back":"Move backward","move_left":"Move left","move_right":"Move right",
	"jump":"Jump","sprint":"Sprint","camera_toggle":"First / third person","respawn":"Return to trail",
	"cycle_spell":"Cycle spell","spell":"Cast spell","heal":"Heal","inventory":"Inventory / crafting",
	"interact":"Interact","character":"Character / equipment","world_map":"Map / journal","help":"Show controls",
	"performance":"Performance display","skills":"Skills","finisher":"Finish creature","power_spin":"Whirlwind",
	"power_sunder":"Sundering strike","attack":"Attack","block":"Block"}
var bindings: Dictionary={}
var sensitivity:=0.0023
var invert_y:=false
var load_warning:=""
var labels: Dictionary={}
func _init() -> void: restore_defaults()
func restore_defaults() -> void:
	bindings.clear(); labels.clear()
	for action in DEFAULT_KEYS: bindings[action]={"type":"key","code":DEFAULT_KEYS[action],"shift":action=="power_sunder"}
	bindings.attack={"type":"mouse","code":MOUSE_BUTTON_LEFT,"shift":false}
	bindings.block={"type":"mouse","code":MOUSE_BUTTON_RIGHT,"shift":false}
	sensitivity=0.0023; invert_y=false
	changed.emit()
func from_event(event: InputEvent) -> Dictionary:
	if event is InputEventKey:
		if event.ctrl_pressed or event.alt_pressed or event.meta_pressed: return {}
		var code=event.physical_keycode if event.physical_keycode!=0 else event.keycode
		return {"type":"key","code":code,"shift":event.shift_pressed and code!=KEY_SHIFT}
	if event is InputEventMouseButton:
		if event.ctrl_pressed or event.alt_pressed or event.meta_pressed: return {}
		return {"type":"mouse","code":event.button_index,"shift":event.shift_pressed}
	return {}
func valid_binding(binding: Dictionary) -> bool:
	if binding.size()!=3 or not binding.has_all(["type","code","shift"]): return false
	if typeof(binding.shift)!=TYPE_BOOL or typeof(binding.code) not in [TYPE_INT,TYPE_FLOAT]: return false
	if not is_finite(float(binding.code)) or float(binding.code)!=floor(float(binding.code)): return false
	var code=int(binding.code)
	if binding.type=="mouse": return code in [MOUSE_BUTTON_LEFT,MOUSE_BUTTON_RIGHT,MOUSE_BUTTON_MIDDLE,MOUSE_BUTTON_XBUTTON1,MOUSE_BUTTON_XBUTTON2]
	if binding.type!="key" or code in [KEY_ESCAPE,KEY_TAB,KEY_ENTER,KEY_KP_ENTER,KEY_CTRL,KEY_ALT,KEY_META]: return false
	return ((code>=KEY_SPACE and code<=KEY_ASCIITILDE) or (code>=KEY_SPECIAL and code<=KEY_LAUNCHF)) and not (code==KEY_SHIFT and binding.shift)
func conflicts(action: String,binding: Dictionary,other: String,other_binding: Dictionary) -> bool:
	if binding.type!=other_binding.type or binding.code!=other_binding.code: return false
	# These two actions explicitly use exact matching to preserve G / Shift+G.
	if action in ["power_spin","power_sunder"] and other in ["power_spin","power_sunder"] and binding.shift!=other_binding.shift: return false
	return true
func rebind(action: String,event: InputEvent) -> String:
	if not bindings.has(action): return "Unknown action."
	var binding=from_event(event)
	if not valid_binding(binding): return "Use a key or mouse button. Escape, Tab, Enter and Ctrl/Alt/Meta shortcuts stay reserved for menus."
	for other in bindings:
		if other!=action and conflicts(action,binding,other,bindings[other]): return "Already used by "+TITLES[other]+". Choose another binding first."
	bindings[action]=binding; apply(); return ""
func make_event(binding: Dictionary) -> InputEvent:
	var event: InputEventWithModifiers
	if binding.type=="key":
		event=InputEventKey.new(); event.physical_keycode=int(binding.code)
	else:
		event=InputEventMouseButton.new(); event.button_index=int(binding.code)
	event.shift_pressed=binding.shift
	return event
func apply() -> void:
	labels.clear()
	for action in bindings:
		if not InputMap.has_action(action): InputMap.add_action(action)
		InputMap.action_erase_events(action); InputMap.action_add_event(action,make_event(bindings[action]))
	if not InputMap.has_action("pause"): InputMap.add_action("pause")
	InputMap.action_erase_events("pause")
	var escape=InputEventKey.new(); escape.physical_keycode=KEY_ESCAPE
	InputMap.action_add_event("pause",escape)
	changed.emit()
func label(action: String) -> String:
	if action=="pause": return "Esc"
	if labels.has(action): return labels[action]
	var b: Dictionary=bindings[action]
	var text: String
	if b.type=="mouse": text={1:"LMB",2:"RMB",3:"MMB",8:"Mouse 4",9:"Mouse 5"}.get(int(b.code),"Mouse "+str(b.code))
	else:
		var code=int(b.code) if DisplayServer.get_name()=="headless" else DisplayServer.keyboard_get_keycode_from_physical(int(b.code))
		text=OS.get_keycode_string(code if code!=0 else int(b.code))
	labels[action]=("Shift+" if b.shift else "")+text
	return labels[action]
func movement_label() -> String:
	return "/".join([label("move_forward"),label("move_left"),label("move_back"),label("move_right")])
func format_prompt(text: String) -> String:
	# Replace authored hints with tokens first so swapped labels cannot cascade.
	var hints={"[ E ]":"[ {interact} ]","E ·":"{interact} ·","WASD":"{movement}",
		"M Map":"{world_map} Map","M Journal":"{world_map} Journal",
		"LMB":"{attack}","RMB":"{block}","Q:":"{spell}:","B change":"{cycle_spell} change",
		"Q Emberbolt":"{spell} Emberbolt","F healing":"{heal} healing","F:":"{heal}:","I:":"{inventory}:"}
	for hint in hints: text=text.replace(hint,hints[hint])
	for action in bindings: text=text.replace("{"+action+"}",label(action))
	return text.replace("{movement}",movement_label())

func save_to(path: String) -> bool:
	var file=FileAccess.open(path+".tmp",FileAccess.WRITE)
	if file==null: return false
	file.store_string(JSON.stringify({"version":1,"bindings":bindings,"sensitivity":sensitivity,"invert_y":invert_y}))
	file.flush(); var error=file.get_error(); file.close()
	if error!=OK: return false
	return DirAccess.rename_absolute(path+".tmp",path)==OK
func load_from(path: String) -> bool:
	if not FileAccess.file_exists(path): return false
	var parser=JSON.new()
	if parser.parse(FileAccess.get_file_as_string(path))!=OK or not parser.data is Dictionary: return false
	var data: Dictionary=parser.data
	if data.get("version")!=1 or not data.get("bindings") is Dictionary or typeof(data.get("invert_y"))!=TYPE_BOOL: return false
	var value: Variant=data.get("sensitivity")
	if typeof(value) not in [TYPE_INT,TYPE_FLOAT] or not is_finite(float(value)) or value<0.0002 or value>0.01: return false
	var incoming: Dictionary=data.bindings
	if incoming.size()!=bindings.size(): return false
	var seen: Dictionary={}
	for action in bindings:
		if not incoming.get(action) is Dictionary or not valid_binding(incoming[action]): return false
		for other in seen:
			if conflicts(action,incoming[action],other,seen[other]): return false
		seen[action]=incoming[action]
	bindings=incoming.duplicate(true); sensitivity=float(value); invert_y=data.invert_y
	apply(); return true
