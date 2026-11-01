extends SceneTree
## Controlled damage samples, not an automated full campaign playthrough.
var checks := 0
var failures := 0
var rows := 0
func _initialize() -> void: call_deferred("run")
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures += 1; push_error("FAIL " + label)
func run() -> void:
	var w = load("res://scenes/main.tscn").instantiate(); root.add_child(w)
	for i in range(8): await physics_frame
	var p = w.player; var s = p.character; var r = w.realms
	p.set_physics_process(false); p.set_process_unhandled_input(false)
	check(not s.persist and not w.atlas.persist, "Profile persistence disabled")
	for enemy in r.enemies: enemy.set_physics_process(false)
	s.story_completed.assign(["threshold", "returning_light", "winter_siege", "broken_seal"])
	var lines: PackedStringArray = ["# Healing pressure baseline", "", "All eight Frostkin playstyles, zero allocated attributes or training/perks. Kits: starting loadout at ordinary quality; the same loadout at Exquisite quality (3); and that Exquisite loadout with a Groveheart Vest. These are controlled comparisons, not recommended progression gear or evidence that every character acquires this quest reward. Attacks use live Prismwing bite and Maw rupture methods. Each sample starts at full health/stamina, with no parry, evasion or simultaneous attackers. Equivalent hits are damage ratios, not timed survival predictions.", "", "| Playstyle | Kit | Attack | HP | Armor | Hit damage | Hits to defeat | Potion capacity | Hits restored / potion | Guard damage | Guard stamina |", "| --- | --- | --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |"]
	for archetype in s.archetypes:
		for kit in ["ordinary", "exquisite", "healing vest"]:
			s.set_identity("Healing audit", "frostkin", archetype, "balanced")
			for slot in s.equipment: s.equipment[slot] = ""
			for slot in s.archetypes[archetype].loadout:
				var id: String = s.archetypes[archetype].loadout[slot]
				if id != "": s.equipment[slot] = s.add_item(id, 0 if kit == "ordinary" else 3)
			if kit == "healing vest": s.equipment.chest = s.add_item("groveheart_chest", 3)
			p._character_changed()
			for attack in ["Prismwing bite", "Maw rupture", "Maw enraged rupture"]:
				r.enter("aeralis" if attack == "Prismwing bite" else "crucible")
				var e = r.enemies[2 if attack == "Prismwing bite" else 5]
				e.health = e.maximum_health * (0.5 if attack == "Maw enraged rupture" else 1.0)
				p.position = e.global_position + Vector3.BACK * 3; p.rotation = Vector3.ZERO
				p.health = p.derived.health; p.stamina = p.derived.stamina
				p.invulnerable = 0; p.blocking = false; p.parry_window = 0
				strike(e, attack, p)
				var damage: float = p.derived.health - p.health
				check(damage > 0 and p.health > 0, "Attack lands without lethal reset: " + archetype + kit + attack)
				var guard_damage := "—"; var guard_cost := "—"
				if p.can_block():
					p.health = p.derived.health; p.stamina = p.derived.stamina; p.invulnerable = 0; p.blocking = true
					strike(e, attack, p)
					var blocked: float = p.derived.health - p.health
					check(blocked > 0 and blocked < damage and p.stamina < p.derived.stamina, "Facing guard trades stamina for lower damage")
					guard_damage = String.num(blocked, 2); guard_cost = String.num(p.derived.stamina - p.stamina, 2)
					# No stamina must take the full hit and enter recovery.
					p.health = p.derived.health; p.stamina = 0; p.invulnerable = 0; p.blocking = true
					strike(e, attack, p)
					check(is_equal_approx(p.derived.health - p.health, damage) and not p.blocking and p.guard_recovery > 0, "Depleted guard breaks without reducing damage")
				p.blocking = false; p.health = 1; s.consumables.healing_draught = 2
				var preview: Dictionary = s.consumable_preview("healing_draught", p)
				var message: String = s.consume("healing_draught", p)
				check(message.begins_with("Used") and is_equal_approx(p.health - 1, preview.actual) and s.consumables.healing_draught == 1, "Real recovery matches preview and spends one potion")
				lines.append("| %s | %s | %s | %.0f | %.0f | %.2f | %d | %.2f | %.2f | %s | %s |" % [archetype, kit, attack, p.derived.health, p.derived.armor, damage, ceili(p.derived.health / maxf(damage, 0.001)), preview.restore, preview.actual / maxf(damage, 0.001), guard_damage, guard_cost])
				rows += 1; r.leave()
	lines.append("\nPotion capacity includes equipped healing bonuses. Hits restored uses actual restoration at 1 HP, divided by one unblocked hit. Guard columns use a full stamina pool facing the source with parries disabled; a dash means the loadout cannot block. Holding guard does not regenerate stamina. Damage values do not include enemy frequency, movement, missed attacks, potion inventory availability or player decisions. No damage, healing or cooldown tuning is made by this audit.")
	if failures == 0:
		var f = FileAccess.open("res://build/healing-pressure-baseline.md", FileAccess.WRITE)
		f.store_string("\n".join(lines) + "\n"); f.close()
	w.queue_free(); await process_frame
	print("HEALING_PRESSURE_AUDIT_COMPLETE rows=%d checks=%d failures=%d" % [rows, checks, failures]); quit(1 if failures else 0)
func strike(enemy: Node, attack: String, player: Node) -> void:
	if attack == "Prismwing bite":
		enemy.begin_bite(player.global_position - enemy.global_position); enemy.resolve_bite()
	else:
		enemy.begin_vent(); enemy.resolve_vent()
