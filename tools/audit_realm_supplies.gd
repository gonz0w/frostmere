extends SceneTree
const State=preload("res://scripts/character_state.gd")
const Realms=preload("res://scripts/realms.gd")
func _initialize() -> void:
	var lines: PackedStringArray=["# Realm supply budgets", "", "Runtime Frostkin ranger bow damage, with no other gear, allocated points, training, perks, criticals, enchantments or finishers. Aeralis has two 90-HP sentries and a 240-HP guardian with 0.8 damage taken. The Crucible has two 125-HP sentries and a 340-HP guardian: 0.8 × 0.6 through closed shutters, 0.8 × 1.35 during exposure. Counts round up separately for each enemy; this is an ideal hit budget, not a measured fight duration or accuracy study.", "", "| Realm | Bow | Quality | Damage | Hits: exposed | Hits: closed | Reserve | Miss allowance: closed |", "| --- | --- | ---: | ---: | ---: | ---: | ---: | ---: |"]
	for realm in ["aeralis","crucible"]:
		for base in ["iron_bow","steel_bow","amberbough_bow"]:
			for quality in [0,2]:
				var s=State.new(); s.set_identity("Audit","frostkin","ranger","balanced")
				for slot in s.equipment: s.equipment[slot]=""
				s.equip(s.add_item(base,quality),"main_hand")
				var damage: float=s.stats().damage
				var troops:=90 if realm=="aeralis" else 125
				var boss:=240 if realm=="aeralis" else 340
				var exposed:=2*ceili(troops/damage)+ceili(boss/(damage*.8*(1 if realm=="aeralis" else 1.35)))
				var closed:=2*ceili(troops/damage)+ceili(boss/(damage*.8*(1 if realm=="aeralis" else .6)))
				var supply: int=Realms.SUPPORT_KITS[realm].arrows
				lines.append("| %s | %s | %d | %.0f | %d | %d | %d | %d |" % [realm,s.items[base].name,quality,damage,exposed,closed,supply,supply-closed])
	lines.append("\nAttunement previously granted zero arrows and magicka draughts. Aeralis now adds 36 arrows and 2 draughts (up to 100 magicka); the Crucible adds 48 arrows and 3 draughts (up to 150 magicka). These are once-per-realm additions using existing attunement flags, not repeatable refills. Claimed attunements in old saves stay claimed. The Crucible's existing 160 Infernal Rounds are unchanged. Extra supplies from home and crafting remain available; early bows still leave little margin against closed shutters.")
	var f=FileAccess.open("res://build/realm-supply-baseline.md",FileAccess.WRITE); f.store_string("\n".join(lines)+"\n"); f.close()
	print("REALM_SUPPLY_AUDIT_COMPLETE builds=12"); quit()
