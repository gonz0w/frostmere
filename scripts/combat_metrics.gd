extends Node
## Opt-in, local-only QA records. Never part of character saves.
const LOG_PATH = "user://combat-playtests.jsonl"
const IDLE_SECONDS = 10.0
var world: Node3D
var enabled := false
var output_path := LOG_PATH
var current: Dictionary = {}
var idle := 0.0
var last_record: Dictionary = {}
func _ready() -> void:
	enabled = "--combat-metrics" in OS.get_cmdline_user_args()
func snapshot() -> Dictionary:
	var p = world.player; var s = p.character
	var gear := {}
	for slot in s.equipment:
		var uid: String = s.equipment[slot]
		if s.inventory.has(uid): gear[slot] = s.inventory[uid].duplicate(true)
	return {"health": p.health, "stamina": p.stamina, "magicka": p.magicka,
		"archetype": s.archetype_id, "origin": s.origin_id, "stats": p.derived.duplicate(true), "equipment": gear}
func event(kind: String, amount: float = 0.0, id: String = "") -> void:
	if not enabled: return
	var area: String = world.session_save.area()
	if not current.is_empty() and current.area != area: finish("travel")
	if not enabled: return
	if current.is_empty():
		if kind not in ["damage_taken", "damage_dealt", "parry", "ammo", "attack"]: return
		current = {"schema": 1, "started_utc": Time.get_datetime_string_from_system(true), "area": area,
			"active_seconds": 0.0, "start": snapshot(), "damage_taken": 0.0, "damage_dealt": 0.0,
			"kills": 0, "parries": 0, "consumables": {}, "restoration": {}, "ammo": {}, "attacks": {}, "targets": []}
	if kind in ["damage_taken", "damage_dealt", "parry", "ammo", "attack", "consume"]: idle = 0.0
	match kind:
		"damage_taken", "damage_dealt": current[kind] += amount
		"kill": current.kills += 1
		"parry": current.parries += 1
		"ammo": current.ammo[id] = int(current.ammo.get(id, 0)) + int(amount)
		"attack": current.attacks[id] = int(current.attacks.get(id, 0)) + 1
		"consume":
			current.consumables[id] = int(current.consumables.get(id, 0)) + 1
			current.restoration[id] = float(current.restoration.get(id, 0)) + amount
	if kind == "damage_dealt" and id != "" and id not in current.targets: current.targets.append(id)
func _process(delta: float) -> void:
	if not enabled or current.is_empty(): return
	if current.area != world.session_save.area(): finish("travel"); return
	if world.player.paused: return
	# Remove slow-motion scaling; menu time never enters the active clock.
	var elapsed := delta / maxf(Engine.time_scale, 0.001)
	current.active_seconds += elapsed; idle += elapsed
	if idle >= IDLE_SECONDS: finish("disengaged")
func finish(outcome: String) -> void:
	if current.is_empty(): return
	current.outcome = outcome; current.end = snapshot(); current.end_area = world.session_save.area()
	# Exclude the inactivity tail used to decide that fighting stopped.
	current.active_seconds = maxf(0.0, current.active_seconds - idle)
	last_record = current.duplicate(true); current = {}; idle = 0.0
	var f: FileAccess
	if FileAccess.file_exists(output_path):
		f = FileAccess.open(output_path, FileAccess.READ_WRITE)
		if f != null: f.seek_end()
	else: f = FileAccess.open(output_path, FileAccess.WRITE)
	if f == null:
		enabled = false; push_warning("Combat playtest logging stopped: cannot open local log."); return
	if f.get_length() > 4 * 1024 * 1024:
		enabled = false; push_warning("Combat playtest log reached 4 MB; move it before recording another session."); return
	f.store_line(JSON.stringify(last_record)); f.close()
func _exit_tree() -> void:
	if not current.is_empty(): finish("session_end")
