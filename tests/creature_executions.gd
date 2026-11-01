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
	var p=world.player; var r=world.realms; var t=world.threshold
	p.set_process(false); p.set_physics_process(false)
	p.character.equip(p.character.add_item("iron_sword"),"main_hand")
	p.character.threshold.power=true; p.character.threshold.air=true
	for e in r.enemies+t.enemies: e.set_physics_process(false)
	for e in [t.enemies[5],r.enemies[2],r.enemies[5]]:
		t.inside=e.adventure==t; r.inside=e.adventure==r
		if r.inside: r.current="aeralis" if e==r.enemies[2] else "crucible"
		e.health=5; p.position=e.global_position+Vector3.BACK*2; p.rotation=Vector3.ZERO
		var location: Transform3D=e.transform
		var cue: String={"alien":"finish_shell","crystal":"finish_crystal","furnace":"finish_furnace"}[e.finisher_surface()]
		world.audio.cooldowns.clear()
		check(p.activate_finisher(),e.title+" starts execution")
		var neutral: Transform3D=e.rig.transform
		p.update_finisher(.25)
		var reaction: Transform3D=e.rig.transform
		check(world.audio.last_effect=="swing",e.title+" finisher impact cue does not play early")
		check(reaction!=neutral and e.health==5 and e.transform==location,e.title+" reacts before damage without moving collision")
		e._physics_process(.01)
		check(e.rig.transform==reaction,e.title+" reaction survives enemy physics")
		p.set_paused(true)
		check(not e.execution_locked and e.execution_progress==0 and e.rig.transform==neutral and not e.dead,e.title+" menu cancellation restores neutral pose")
		p.set_paused(false); p.activate_finisher(); p.update_finisher(.51)
		check(e.dead and e.has_node("DefeatMotion") and e.rig.transform!=neutral,e.title+" lethal frame hands reaction into collapse")
		check(world.audio.last_effect==cue,e.title+" lethal finisher selects its material sound")
		var played: int=world.audio.effect_count
		p.update_finisher(.05)
		check(world.audio.effect_count==played,e.title+" finisher cue plays once")
		var falling: Transform3D=e.rig.transform
		p.cancel_finisher()
		check(e.rig.transform==falling,e.title+" finisher cleanup preserves collapse")
	world.queue_free(); await process_frame
	print("CREATURE_EXECUTIONS_COMPLETE checks=%d failures=%d" % [checks,failures]); quit(1 if failures else 0)
