extends SceneTree
const State=preload("res://scripts/character_state.gd")
func _initialize() -> void:
	var lines: PackedStringArray=["# Station ammunition pressure", "", "Frostkin ranger, bow only, no allocated attributes, perks, training, enchantments, criticals or finishers. Five 100-HP troopers and the 380-HP Hullcarver. Boss mitigation is 0.8, multiplied by 0.65 through its shell or 1.5 during exposure. Counts round up per target; these are ideal hit budgets, not measured player accuracy or fight duration.", "", "| Bow | Quality | Damage | Arrows with exposed-core hits | Arrows through closed shell | 60-arrow reserve miss allowance (closed shell) |", "| --- | ---: | ---: | ---: | ---: | ---: |"]
	for base in ["iron_bow","steel_bow","amberbough_bow"]:
		for quality in [0,2]:
			var s=State.new(); s.set_identity("Audit","frostkin","ranger","balanced")
			for slot in s.equipment: s.equipment[slot]=""
			s.equip(s.add_item(base,quality),"main_hand")
			var damage: float=s.stats().damage
			var exposed:=5*ceili(100/damage)+ceili(380/(damage*.8*1.5))
			var closed:=5*ceili(100/damage)+ceili(380/(damage*.8*.65))
			lines.append("| %s | %d | %.0f | %d | %d | %d |" % [s.items[base].name,quality,damage,exposed,closed,60-closed])
	lines.append("\nPreviously both caches supplied zero arrows and zero magicka draughts. The emergency locker now adds 36 arrows and two magicka draughts; cargo adds 24 arrows and one draught. Each draught restores up to 50 magicka, so the total reserve restores up to 150. Rifle ammunition, recipes, enemies and all other rewards are unchanged. Existing collected caches do not refill, and no free repeatable supply source is added. Players can still arrive with their own supplies, craft, return home or use the emergency rifle.")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://build"))
	var f=FileAccess.open("res://build/station-supply-baseline.md",FileAccess.WRITE); f.store_string("\n".join(lines)+"\n"); f.close()
	print("STATION_SUPPLY_AUDIT_COMPLETE builds=6"); quit()
