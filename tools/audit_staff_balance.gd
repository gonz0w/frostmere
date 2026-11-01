extends SceneTree
const State=preload("res://scripts/character_state.gd")
func _initialize() -> void:
	var s=State.new(); s.set_identity("Audit","frostkin","mage","balanced")
	for slot in s.equipment: s.equipment[slot]=""
	var lines: PackedStringArray=["# Staff upgrade baseline", "", "Frostkin mage, no allocated points, perks, enchantments or other equipment. Runtime stats include each staff's innate attribute bonuses. Ordinary and Legendary are comparison endpoints, not assumptions about when players can afford them.", "", "| Staff | Ordinary spell power | Legendary spell power | Legendary Emberbolt | Legendary Soulfire |", "| --- | ---: | ---: | ---: | ---: |"]
	for id in s.items:
		if s.items[id].get("family","")!="staff": continue
		s.equip(s.add_item(id),"main_hand"); var base: int=s.stats().spell_power
		s.equip(s.add_item(id,5),"main_hand"); var power: int=s.stats().spell_power
		lines.append("| %s | %d | %d | %.2f | %.2f |" % [s.items[id].name,base,power,power*float(s.spell_definition("emberbolt").scale),power*float(s.spell_definition("soulfire").scale)])
	lines.append("\nSpell values are raw damage per projectile before mitigation. Soulfire remains locked until learned; equipping or upgrading a staff does not unlock spells. Starfall emits three projectiles; chain and piercing spells keep their existing secondary-target reductions. Costs and cooldowns are unchanged.")
	lines.append("\nPreviously, staff base damage and quality contributed zero spell power; only attribute bonuses affected casting. Equipped staves now add floor(base damage / 2), including tempered damage, before Kindled Mind. Every quality rank adds one power before perks. This improves the collecting/upgrading loop without changing enemy HP. It is not an encounter-duration or player-success measurement; movement, misses, regeneration, mitigation, enemy mechanics and spell access remain important.")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://build"))
	var file=FileAccess.open("res://build/staff-combat-baseline.md",FileAccess.WRITE)
	file.store_string("\n".join(lines)+"\n"); file.close()
	print("STAFF_BALANCE_AUDIT_COMPLETE"); quit()
