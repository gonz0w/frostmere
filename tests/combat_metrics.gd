extends SceneTree
var checks := 0
var failures := 0
func _initialize() -> void: call_deferred("run")
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures += 1; push_error("FAIL " + label)
func run() -> void:
	var w = load("res://scenes/main.tscn").instantiate(); root.add_child(w)
	for i in range(8): await physics_frame
	var p = w.player; var m = w.combat_metrics; var s = p.character
	p.set_physics_process(false); m.set_process(false)
	check(not s.persist and not w.atlas.persist and not m.enabled, "Normal isolated run has no recording")
	m.output_path = "user://combat-metrics-test.jsonl"
	if FileAccess.file_exists(m.output_path): DirAccess.remove_absolute(m.output_path)
	p.invulnerable = 0; p.receive_damage(10, p.position + Vector3.FORWARD)
	check(m.current.is_empty() and not FileAccess.file_exists(m.output_path), "Disabled hooks write nothing")
	m.enabled = true; p.health = p.derived.health; p.invulnerable = 0
	var hp: float = p.health
	p.receive_damage(20, p.position + Vector3.FORWARD)
	check(m.current.start.health == hp and is_equal_approx(m.current.damage_taken, hp-p.health), "Incoming damage records pre-hit vitals and actual mitigation")
	var damage: float = m.current.damage_taken
	p.receive_damage(20, p.position + Vector3.FORWARD)
	check(m.current.damage_taken == damage, "Invulnerability does not count rejected hits")
	m._process(2); p.set_paused(true); m._process(100)
	check(m.current.active_seconds == 2, "Menus excluded from timing")
	p.set_paused(false); Engine.time_scale = 0.25; m._process(0.5); Engine.time_scale = 1
	check(m.current.active_seconds == 4, "Slow motion measures real active seconds")
	s.consumables.healing_draught = 2; s.consume("healing_draught", p)
	check(m.current.consumables.healing_draught == 1 and is_equal_approx(m.current.restoration.healing_draught, damage), "Potion counts actual healing, not nominal capacity")
	s.consume("healing_draught", p)
	check(m.current.consumables.healing_draught == 1, "Full-health rejection does not count as use")
	s.equip(s.add_item("iron_bow"), "main_hand"); s.materials.arrow = 2; p.attack_cooldown = 0
	check(p.attack() and m.current.ammo.arrow == 1, "Actual arrow spending is logged")
	check(not p.attack() and m.current.ammo.arrow == 1, "Rejected attack does not spend logged ammo")
	p.magicka = p.derived.magicka; p.spell_cooldown = 0
	check(p.cast_spell("emberbolt") and m.current.attacks.emberbolt == 1, "Actual spell cast logged")
	check(not p.cast_spell("emberbolt") and m.current.attacks.emberbolt == 1, "Rejected spell is not counted")
	w.adventure.clear_projectiles()
	m._process(10)
	check(m.current.is_empty() and m.last_record.outcome == "disengaged" and m.last_record.active_seconds == 4, "Inactivity closes without assuming victory and trims idle tail")
	var f = FileAccess.open(m.output_path, FileAccess.READ)
	var saved = JSON.parse_string(f.get_line()); f.close()
	check(saved.schema == 1 and saved.ammo.arrow == 1 and saved.end.health == p.health, "Record is readable JSON with final vitals")
	w.adventure.enter()
	for e in w.adventure.enemies: e.set_physics_process(false)
	var target = w.adventure.enemies[0]; target.health = 1
	target.receive_damage(10, p)
	check(m.current.damage_dealt == 1 and m.current.kills == 1 and target.enemy_id in m.current.targets, "Enemy hook caps overkill and records target/kill")
	w.adventure.leave(); m._process(0.1)
	check(m.last_record.outcome == "travel" and m.current.is_empty(), "Travel splits area records")
	p.invulnerable = 0; p.health = 1; p.receive_damage(1000, p.position + Vector3.FORWARD)
	check(m.last_record.outcome == "death" and m.last_record.end.health == 0 and p.health > 0, "Death captured before respawn restoration")
	f = FileAccess.open(m.output_path, FileAccess.READ); var records := 0
	while not f.eof_reached():
		var line: String = f.get_line()
		if not line.is_empty(): check(JSON.parse_string(line) is Dictionary, "Every appended line is valid JSON"); records += 1
	f.close(); check(records == 3, "Records append without overwriting prior attempts")
	m.enabled = false
	w.queue_free(); await process_frame
	print("COMBAT_METRICS_COMPLETE checks=%d failures=%d" % [checks, failures]); quit(1 if failures else 0)
