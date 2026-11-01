extends SceneTree
## Real casts and projectile collisions; stationary, high-health test targets, no enemy AI.
var checks:=0
var failures:=0
var rows: Array=[]
var w: Node3D
func _initialize() -> void: call_deferred("run")
func check(ok: bool,label: String) -> void:
	checks+=1
	if ok: print("PASS "+label)
	else: failures+=1; push_error("FAIL "+label)
func frames(n: int) -> void:
	for i in range(n): await physics_frame
func run() -> void:
	if DisplayServer.get_name()!="headless": push_error("Requires isolated headless fixture"); quit(1); return
	w=load("res://scenes/main.tscn").instantiate(); root.add_child(w); await frames(3)
	var p=w.player; var s=p.character; var a=w.adventure
	if s.persist: push_error("Refusing persistent profile"); quit(1); return
	p.set_physics_process(false); p.set_process_unhandled_input(false)
	s.set_identity("Projectile QA","frostkin","mage","balanced")
	for slot in s.equipment: s.equipment[slot]=""
	for slot in s.archetypes.mage.loadout:
		var base: String=s.archetypes.mage.loadout[slot]
		if base!="": s.equip(s.add_item(base),slot)
	s.equip(s.add_item("horizon_staff",2,"insight"),"main_hand")
	for spell in s.realm_data.spells:
		if spell.id not in s.known_spells: s.known_spells.append(spell.id)
	a.enter(); p.set_paused(false)
	for enemy in a.enemies: enemy.set_physics_process(false); enemy.position=Vector3(20,0,-25)
	p.position=Vector3(0,-29.95,2); p.rotation=Vector3.ZERO
	p.set_third_person(false); p.pivot.rotation=Vector3.ZERO; p.pivot.position.y=1.35
	for upgraded in [false,true]:
		if upgraded:
			s.train("magic",400)
			check(s.learn_perk("kindled_mind") and s.learn_perk("clear_channel"),"Level-five fixture learns both perks through eligibility checks")
		for id in ["emberbolt","chain_lightning","sunlance","starfall","soulfire"]:
			a.clear_projectiles()
			for i in range(3):
				a.enemies[i].position=Vector3(0,.05,-4-i*4)
				a.enemies[i].health=1000; a.enemies[i].maximum_health=1000
			if id=="chain_lightning":
				a.enemies[1].position=Vector3(2,.05,-5); a.enemies[2].position=Vector3(-2,.05,-5)
			await frames(3)
			p.magicka=p.derived.magicka; p.spell_cooldown=0; p.attack_cooldown=0
			var before: float=p.magicka
			var power: float=p.derived.spell_power
			var spell: Dictionary=s.spell_definition(id)
			check(p.cast_spell(id),"Cast accepted: %s perks=%s" % [id,upgraded])
			var cost: float=before-p.magicka
			check(is_equal_approx(cost,float(spell.cost)*(.8 if upgraded else 1)),"Actual cast spends discounted resource exactly: "+id)
			check(not p.cast_spell(id) and is_equal_approx(before-p.magicka,cost),"Repeated input cannot bypass cooldown or spend twice: "+id)
			await frames(65)
			var damage: Array=[]
			for i in range(3): damage.append(1000-a.enemies[i].health)
			var expected: Array=[power*float(spell.scale),0.0,0.0]
			if id=="starfall": expected[0]*=3
			elif id=="sunlance": expected[1]=expected[0]*.7
			elif id=="chain_lightning": expected[1]=expected[0]*.65; expected[2]=expected[1]*.65
			check(is_equal_approx(damage[0],expected[0]) and is_equal_approx(damage[1],expected[1]) and is_equal_approx(damage[2],expected[2]),"Projectile collision damage and target limits: %s perks=%s" % [id,upgraded])
			rows.append({"spell":id,"perks":upgraded,"power":power,"cost":cost,"damage":damage,"damage_per_magicka":(damage[0]+damage[1]+damage[2])/cost})
			p.magicka=cost-.01; p.spell_cooldown=0
			check(not p.cast_spell(id) and is_equal_approx(p.magicka,cost-.01),"Insufficient-resource rejection preserves magicka: "+id)
	# The live HUD must reflect the same discounted cost as the cast path.
	s.active_spell="starfall"
	s.equip(s.add_item("lantern_conductor",2,"insight"),"main_hand")
	await frames(2)
	check(w.hud.vitals.text.contains("Q: Starfall · 22.4 magicka"),"Selected-spell HUD shows actual discounted cost")
	check(w.hud.vitals.text.contains("LMB: Chain Lightning · 19.2 magicka"),"Conductor HUD reflects Clear Channel")
	check(s.refund_perk("clear_channel"),"Refund Clear Channel through normal rules")
	await frames(2)
	check(w.hud.vitals.text.contains("Q: Starfall · 28 magicka") and w.hud.vitals.text.contains("LMB: Chain Lightning · 24 magicka"),"HUD updates after refund and omits unnecessary decimal zeros")
	p.magicka=0; p.set_paused(true); p._physics_process(1)
	check(p.magicka==0,"Paused menus do not regenerate magicka")
	p.set_paused(false); p._physics_process(1)
	check(is_equal_approx(p.magicka,p.derived.magicka_regen),"Actual player tick applies the documented regeneration rate")
	var f=FileAccess.open("res://build/mage-projectile-results.json",FileAccess.WRITE)
	f.store_string(JSON.stringify({"checks":checks,"failures":failures,"rows":rows},"\t")); f.close()
	w.queue_free(); await process_frame
	print("MAGE_PROJECTILES_COMPLETE checks=%d failures=%d" % [checks,failures]); quit(1 if failures else 0)
