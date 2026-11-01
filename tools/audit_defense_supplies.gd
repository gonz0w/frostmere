extends SceneTree
const State=preload("res://scripts/character_state.gd")
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var w=load("res://scenes/main.tscn").instantiate(); root.add_child(w)
	for i in range(8): await physics_frame
	var p=w.player; p.set_physics_process(false)
	assert(not p.character.persist and not w.atlas.persist)
	p.character.story_completed.append("returning_light"); p.character.story_completed.append("winter_siege")
	var lines: PackedStringArray=["# Siege and underworks ammunition budgets", "", "Frostkin ranger, specified weapon only, no other equipment, allocated points, perks, criticals, training or finishers. Damage is measured through each live enemy's receive_damage method with no player training source. Hit budgets round up per enemy. Winter includes the ballista's actual 100-HP reduction; its intermission ward already restores health and magicka. This is an ideal hit budget, not observed player accuracy or campaign duration.", "", "| Chapter | Weapon | Quality | Damage | Required hits | Reserve | Miss allowance |", "| --- | --- | ---: | ---: | ---: | ---: | ---: |"]
	for area in ["winter","seal"]:
		var c=w.get(area); c.enter()
		for enemy in c.enemies: enemy.set_physics_process(false)
		if area=="winter":
			p.character.winter.accepted=true; p.character.winter.assault=true
		else:
			p.character.seal.accepted=true; p.character.seal.valves=["intake","exhaust"]; p.character.seal.plans=true
		c._refresh()
		for entry in [["iron_bow",0],["steel_bow",2],["amberbough_bow",2],["station_rifle",1]]:
			var s=State.new(); s.set_identity("Audit","frostkin","ranger","balanced")
			for slot in s.equipment: s.equipment[slot]=""
			s.equip(s.add_item(entry[0],entry[1]),"main_hand")
			var damage: float=s.stats().damage; var hits:=0
			for enemy in c.enemies:
				var before: float=enemy.health; enemy.receive_damage(damage)
				var actual: float=before-enemy.health
				assert(actual>0)
				hits+=ceili(before/actual); enemy.health=before
			var reserve:=120 if entry[0]=="station_rifle" else 60
			lines.append("| %s | %s | %d | %.0f | %d | %d | %d |" % [area,s.items[entry[0]].name,entry[1],damage,hits,reserve,reserve-hits])
		c.leave()
	lines.append("\nBoth reserved stores previously contained no ammunition or magicka draughts. Each now adds 60 arrows and 120 Station Rounds. Winter supplies two magicka draughts (up to 100 magicka); Broken Seal supplies three (up to 150). These are one-time supplements. Required repair/ward ingredients, combat stats, normal loot and the existing component/spare recovery paths remain unchanged. Claimed stores in old saves do not refill.")
	var f=FileAccess.open("res://build/defense-supply-baseline.md",FileAccess.WRITE); f.store_string("\n".join(lines)+"\n"); f.close()
	w.queue_free(); await process_frame
	print("DEFENSE_SUPPLY_AUDIT_COMPLETE builds=8"); quit()
