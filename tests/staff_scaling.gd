extends SceneTree
const State=preload("res://scripts/character_state.gd")
const Projectile=preload("res://scripts/projectile.gd")
var checks:=0
var failures:=0
func _initialize() -> void: call_deferred("run")
func check(ok: bool,label: String) -> void:
	checks+=1
	if ok: print("PASS "+label)
	else: failures+=1; push_error("FAIL "+label)
func run() -> void:
	var s=State.new()
	for slot in s.equipment: s.equipment[slot]=""
	var unarmed: int=s.stats().spell_power
	s.equip(s.add_item("iron_sword",5),"main_hand")
	check(s.stats().spell_power==unarmed,"Tempered physical weapons do not amplify spells")
	for id in s.items:
		if s.items[id].get("family","")!="staff": continue
		var uid: String=s.add_item(id)
		s.equip(uid,"main_hand")
		var base: int=s.stats().spell_power
		var a: Dictionary=s.attributes()
		check(base==20+a.intellect*2+a.willpower+floori(float(s.items[id].damage)/2),"Equipped staff contributes its base damage: "+id)
		for rank in range(1,6):
			for material in s.temper_cost(uid): s.materials[material]=999
			check(s.improve(uid,"forge").begins_with("Improved") and s.stats().spell_power==base+rank,"Actual temper improves magic: %s rank %d" % [id,rank])
		var stats_before: Dictionary=s.stats()
		check(s.improve(uid,"forge")=="Already Legendary." and s.stats()==stats_before,"Legendary cannot over-upgrade: "+id)
	var uid: String=s.add_item("iron_staff",5); s.equip(uid,"main_hand")
	var before_perk: int=s.stats().spell_power
	s.skills.xp.magic=100; s.skills.perks.append("kindled_mind")
	check(s.stats().spell_power==roundi(before_perk*1.1),"Kindled Mind includes staff contribution exactly once")
	check(s.save_to("user://staff-scaling-test.json"),"Upgraded caster saves")
	var loaded=State.new()
	check(loaded.load_from("user://staff-scaling-test.json") and loaded.stats()==s.stats(),"Staff contribution survives save/load without new fields")
	s.unequip("main_hand")
	check(s.stats().spell_power==roundi(unarmed*1.1),"Unequipping removes staff contribution")
	var w=load("res://scenes/main.tscn").instantiate(); root.add_child(w)
	for i in range(6): await physics_frame
	var p=w.player; p.set_physics_process(false); s=p.character
	check(not s.persist,"Live cast fixture is isolated")
	uid=s.add_item("iron_staff"); s.equip(uid,"main_hand")
	var power: int=p.derived.spell_power
	for material in s.temper_cost(uid): s.materials[material]=999
	check(s.improve(uid,"forge").begins_with("Improved") and p.derived.spell_power==power+1,"Equipped upgrade refreshes live player spell power")
	for spell in s.realm_data.spells:
		if spell.id not in s.known_spells: s.known_spells.append(spell.id)
		p.spell_cooldown=0; p.attack_cooldown=0; p.magicka=100
		check(p.cast_spell(spell.id),"Actual upgraded cast accepted: "+spell.id)
		var bolts: Array=[]
		for child in w.adventure.get_children():
			if child is Projectile: bolts.append(child)
		var correct: bool=bolts.size()==(3 if spell.id=="starfall" else 1)
		for bolt in bolts:
			correct=correct and is_equal_approx(bolt.damage,(power+1)*float(spell.scale)) and bolt.magic
			w.adventure.remove_child(bolt); bolt.queue_free()
		check(correct,"Spell projectiles use upgraded power: "+spell.id)
		check(is_equal_approx(p.magicka,100-s.spell_cost(float(spell.cost))) and is_equal_approx(p.spell_cooldown,float(spell.cooldown)),"Spell resource cost and cadence preserved: "+spell.id)
	var workshop=w.hud.workshop
	workshop.selected=uid; workshop.mode="Improve"; workshop.show_detail()
	check("adds +1 spell power" in workshop.detail.text and "while equipped" in workshop.detail.text,"Crafting explains current and next magic benefit")
	w.queue_free(); await process_frame
	print("STAFF_SCALING_COMPLETE checks=%d failures=%d" % [checks,failures]); quit(1 if failures else 0)
