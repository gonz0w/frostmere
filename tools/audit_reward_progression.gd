extends SceneTree
const State=preload("res://scripts/character_state.gd")
const PAIRS=[
	["berserker","crystal_greatsword","aether_greatsword","damage"],
	["mage","crystal_staff","aether_staff","spell_power"],
	["ranger","amberbough_bow","dawnforged_bow","damage"],
	["mage","cantors_staff","dawnforged_staff","spell_power"],
]
func _initialize() -> void:
	var lines: PackedStringArray=["# Later reward progression", "", "Runtime comparison at equal quality, Frostkin ancestry and the listed playstyle. No allocated points, other equipment, perks, gems or enchantments. Innate item attributes are included. Each pair is checked at all six qualities; this is a gear comparison, not a measured encounter-duration study.", "", "| Playstyle | Earlier gear → later reward | Stat | Ordinary | Legendary |", "| --- | --- | --- | --- | --- |"]
	var checks:=0
	for pair in PAIRS:
		var s=State.new(); s.set_identity("Audit","frostkin",pair[0],"balanced")
		for slot in s.equipment: s.equipment[slot]=""
		var endpoints: Array[String]=[]
		for quality in range(6):
			s.equip(s.add_item(pair[1],quality),"main_hand"); var earlier: int=s.stats()[pair[3]]
			s.equip(s.add_item(pair[2],quality),"main_hand"); var later: int=s.stats()[pair[3]]
			if later<=earlier:
				push_error("Reward progression regressed: %s quality %d" % [pair[2],quality]); quit(1); return
			checks+=1
			if quality in [0,5]: endpoints.append("%d → %d" % [earlier,later])
		lines.append("| %s | %s → %s | %s | %s | %s |" % [pair[0],s.items[pair[1]].name,s.items[pair[2]].name,pair[3],endpoints[0],endpoints[1]])
	lines.append("\nBase damage changes: Skybreaker 31 → 38, Starweaver Rod 22 → 32, Dawnforged Bow 25 → 30, Dawnforged Staff 24 → 32. Actual realm and ending rewards retain their existing quality, enchantment and favorite protection. Spell power uses the equipped staff contribution. Earlier heavily upgraded gear may still outperform a new untempered reward; unique effects and build specialization remain relevant.")
	lines.append("\nEnemy health, attacks, loot quantities, recipe costs and chapter gates are unchanged. Owned items derive their stats from catalog IDs, so existing copies receive the new values without replacing their quality or customizations. Real encounter pacing and larger reward-choice coverage remain open.")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://build"))
	var file=FileAccess.open("res://build/reward-progression.md",FileAccess.WRITE)
	file.store_string("\n".join(lines)+"\n"); file.close()
	print("REWARD_PROGRESSION_COMPLETE checks=%d failures=0" % checks); quit()
