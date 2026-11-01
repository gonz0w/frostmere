extends SceneTree
var checks:=0
var failures:=0
func _initialize() -> void: call_deferred("run")
func check(ok: bool,label: String) -> void:
	checks+=1
	if ok: print("PASS "+label)
	else: failures+=1; push_error("FAIL "+label)
func run() -> void:
	var world=load("res://scenes/main.tscn").instantiate(); root.add_child(world)
	for i in range(6): await physics_frame
	var p=world.player; var r=world.realms
	p.set_physics_process(false); p.set_process(false)
	for e in r.enemies: e.set_physics_process(false)
	for entry in [[world.threshold.enemies[5],"alien","637c84"],[r.enemies[2],"crystal","a8e6f4"],[r.enemies[5],"furnace","583b3c"]]:
		var e=entry[0]; e.finisher_burst("crush")
		var bursts=e.adventure.get_children().filter(func(n): return n.has_meta("finisher_surface"))
		var burst=bursts[-1]
		check(burst.get_meta("finisher_surface")==entry[1] and burst.get_child(0).mesh.material.albedo_color.is_equal_approx(Color(entry[2])),entry[1]+" finisher uses its own fragment material")
		burst.set_process(false)
		var was_inside: bool=e.adventure.inside
		e.adventure.inside=true
		burst._process(.1)
		check(burst.chips[0].position.length()>0 and burst.chips[0].rotation.length()>0,entry[1]+" fragments travel and tumble")
		var before: Vector3=burst.chips[0].position
		p.set_paused(true); burst._process(.2)
		check(is_equal_approx(burst.age,.1) and burst.chips[0].position==before and not burst.visible,entry[1]+" menu freezes and hides fragments")
		p.set_paused(false); burst._process(.1)
		check(burst.visible and burst.chips[0].position!=before,entry[1]+" fragments resume after menu")
		burst._process(.5)
		check(burst.is_queued_for_deletion(),entry[1]+" fragments expire")
		e.adventure.inside=was_inside
		if entry[1]=="crystal": check(burst.get_child(0).mesh.size.y>burst.get_child(0).mesh.size.x,"Crystal impact produces elongated shards")
	r.enter("crucible",true)
	var departing=preload("res://scripts/finisher_effect.gd").spawn(r.enemies[5],"thrust",Vector3.RIGHT)
	departing.set_process(false); r.current="aeralis"; departing._process(.01)
	check(departing.is_queued_for_deletion(),"Realm change clears finisher fragments")
	r.current="crucible"
	var e=r.enemies[5]; p.position=e.global_position+Vector3.BACK*7; p.invulnerable=0
	e.begin_vent(); e._physics_process(1.51)
	var effects=e.get_parent().get_children().filter(func(n): return n.get_script()==preload("res://scripts/monster_effect.gd"))
	check(effects.size()==1,"Actual rupture spawns one cosmetic eruption")
	var effect=effects[0]; effect.set_process(false); var hp: float=p.health
	effect._process(.2)
	check(effect.chips[0].position.y>0 and p.health==hp,"Eruption rises without applying extra damage")
	p.set_paused(true); var age: float=effect.age; effect._process(.2)
	check(effect.age==age and not effect.visible,"Menu hides and freezes cosmetic eruption")
	p.set_paused(false); effect._process(.01)
	check(effect.visible,"Resume restores cosmetic effect")
	effect._process(1)
	check(effect.is_queued_for_deletion(),"Effect cleans itself after its short lifetime")
	var other=preload("res://scripts/monster_effect.gd").eruption(e,e.global_position)
	r.current="aeralis"; other._process(.01)
	check(other.is_queued_for_deletion(),"Realm travel removes remaining eruption")
	world.queue_free(); await process_frame
	print("MONSTER_EFFECTS_COMPLETE checks=%d failures=%d" % [checks,failures]); quit(1 if failures else 0)
