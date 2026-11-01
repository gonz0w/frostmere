extends SceneTree
const State=preload("res://scripts/character_state.gd")
const Player=preload("res://scripts/player.gd")
func _initialize() -> void:
	var catalog=State.new()
	var lines: PackedStringArray=["# Early combat baseline", "", "Frostkin ancestry, zero allocated attribute points, default starting gear, no training/perks/upgrades. Values come from the runtime character stats and melee timing functions. This is a numerical baseline, not a measured player-success or real encounter-duration study.", "", "| Playstyle | HP | Armor | Main-hand damage | Basic melee DPS | Swing stamina | Unblocked Captain hits to defeat | Iron-bow arrows for all seven defenders |", "| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |"]
	for id in catalog.archetypes:
		var s=State.new(); s.set_identity("Audit","frostkin",id,"balanced")
		for slot in s.equipment: s.equipment[slot]=""
		for slot in s.archetypes[id].loadout:
			var gear: String=s.archetypes[id].loadout[slot]
			if gear!="": s.equipment[slot]=s.add_item(gear)
		var stats: Dictionary=s.stats()
		var p=Player.new(); p.character=s
		var melee: bool=s.item_at("main_hand").get("family","") not in ["bow","staff","focus"]
		var dps: String="%.1f" % (float(stats.damage)/p.melee_interval()) if melee else "—"
		var cost: String="%.0f" % p.melee_stamina_cost() if melee else "—"
		var lethal:=ceili(float(stats.health)/(27.0*100.0/(100.0+float(stats.armor)*1.5)))
		s.equipment.main_hand=s.add_item("iron_bow")
		var bow_damage: float=s.stats().damage
		var arrows:=2*ceili(65/bow_damage)+4*ceili(46/bow_damage)+ceili(190/(bow_damage*.8))
		lines.append("| %s | %d | %d | %d | %s | %s | %d | %d |" % [id,stats.health,stats.armor,stats.damage,dps,cost,lethal,arrows])
		p.free()
	lines.append("\nMelee DPS assumes every cooldown-limited hit lands, with no movement, criticals, enemy interruptions, stamina downtime, power attacks or finishers. Captain-hit counts assume no blocking/parrying/healing. Bow counts assume every arrow hits, no criticals, no training or mid-run equipment changes. Enemy baselines: two 65-HP guards, four 46-HP ranged enemies, and the 190-HP Captain with 20% mitigation.")
	lines.append("\nEdda supplies 30 arrows, three healing draughts and two magicka draughts on acceptance. Six non-boss loot drops add 36 arrows and six healing draughts; the optional alcove adds 12 arrows. These supplies require claiming the quest and looting. Their existence does not guarantee a successful run, especially with misses or unlooted bodies.")
	lines.append("\nChange: daggers now swing every 0.38 seconds for six stamina (four with Measured Swing), instead of 0.62 seconds for nine. Sword and two-handed timings, hit damage, enemies, loot and healing supplies are unchanged. The former starter rogue baseline was 10 / 0.62 = 16.1 basic melee DPS; the new baseline is 26.3, compared with the starter warrior's 25.8. High-tier dagger builds still need human balance testing.")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://build"))
	var file:=FileAccess.open("res://build/early-combat-baseline.md",FileAccess.WRITE)
	file.store_string("\n".join(lines)+"\n"); file.close()
	print("EARLY_BALANCE_AUDIT_COMPLETE playstyles=8"); quit()
