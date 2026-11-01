extends "res://tests/winter.gd"
func run() -> void:
	world=load("res://scenes/main.tscn").instantiate(); root.add_child(world); await frames(8)
	c=world.winter; p=world.player; s=p.character; p.set_physics_process(false)
	check(not s.persist and not world.atlas.persist,"Isolated siege recovery fixture")
	s.story_completed.append("returning_light"); check(c.enter(),"Qualified fort entry")
	for enemy in c.enemies: enemy.set_physics_process(false)
	talk("keeper"); check(c.act("accept"),"Accept defense")
	talk("ward"); check(not c.act("spare_repair"),"No recovery before scouts cleared")
	c.close_dialog(); p.set_paused(false)
	for i in range(3): c.enemies[i].receive_damage(10000,p)
	talk("ward"); check(not c.act("spare_repair"),"Original repair stores must be collected")
	talk("supplies"); check(c.act("supplies"),"Collect original stock")
	check(s.save_to("user://winter-recovery-ready.json"),"Save repair checkpoint")
	var loaded=State.new()
	for site in ["ward","ballista"]:
		check(s.load_from("user://winter-recovery-ready.json"),"Reload before independent repair case")
		talk(site); check(not c.spare_repair_available(site) and not c.act("spare_repair"),"Affordable repairs use ordinary materials: "+site)
		var mat: String="rune_dust" if site=="ward" else "steel_ingot"
		s.materials[mat]=0; talk(site)
		check(c.spare_repair_available(site),"Spent stock enables fitted spare: "+site)
		var before: Dictionary=s.materials.duplicate(true); var gold: int=s.gold; var count: int=s.inventory.size(); var xp: int=s.craft_xp
		var pos: Vector3=p.position; p.position+=Vector3.RIGHT*8
		check(not c.act("spare_repair"),"Remote spare cannot install")
		p.position=pos
		var pressed:=false
		for b in c.options.get_children():
			if b.text=="Install the garrison’s fitted spare": b.pressed.emit(); pressed=true; break
		check(pressed and site in s.winter.repairs,"Actual spare button repairs defense: "+site)
		check(s.materials==before and s.gold==gold and s.inventory.size()==count and s.craft_xp==xp,"Spare grants no materials, money, gear or crafting XP")
		check(not c.act("spare_repair") and not c.act("repair"),"Neither repair path repeats")
		check(s.save_to("user://winter-recovered.json") and loaded.load_from("user://winter-recovered.json") and site in loaded.winter.repairs,"Recovered defense survives load")
		check(s.load_from("user://winter-recovered.json") and not c.act("spare_repair"),"Reload cannot duplicate a spare")
	# Both spares can rescue a completely spent intermission without changing assault gates.
	s.load_from("user://winter-recovery-ready.json")
	for mat in ["steel_ingot","crystal","rune_dust"]: s.materials[mat]=0
	talk("ward"); check(c.act("spare_repair"),"Recover first defense from empty reserves")
	talk("keeper"); check(not c.act("assault"),"One recovered defense is insufficient")
	talk("ballista"); check(c.act("spare_repair"),"Recover second defense from empty reserves")
	talk("keeper"); p.health=10; p.magicka=0
	check(c.act("assault") and s.winter.assault and p.health==p.derived.health and p.magicka==p.derived.magicka,"Recovered repairs unlock normal ward restoration and assault")
	check(not c.act("assault"),"Assault restoration remains one-time")
	world.queue_free(); await process_frame
	print("WINTER_RECOVERY_COMPLETE checks=%d failures=%d" % [checks,failures]); quit(1 if failures else 0)
