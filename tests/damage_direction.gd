extends SceneTree
var checks:=0
var failures:=0
func _initialize() -> void: call_deferred("run")
func check(ok: bool,label: String) -> void:
	checks+=1
	if ok: print("PASS "+label)
	else: failures+=1; push_error("FAIL "+label)
func run() -> void:
	var w=load("res://scenes/main.tscn").instantiate(); root.add_child(w)
	for i in range(6): await physics_frame
	var p=w.player; var cue=w.hud.damage_direction
	p.set_physics_process(false); cue.set_process(false)
	check(not p.character.persist and not cue.visible,"Isolated fixture begins with no impact cue")
	p.rotation=Vector3.ZERO; p.blocking=false; p.invulnerable=0
	p.receive_damage(10,p.global_position+Vector3.RIGHT*5)
	check(cue.visible and cue.outcome=="HIT" and cue.direction().is_equal_approx(Vector2.RIGHT),"Actual right-hand hit creates directional cue")
	var source: Vector3=cue.source_position
	p.receive_damage(10,p.global_position+Vector3.LEFT*5)
	check(cue.source_position==source,"Invulnerability-rejected hit cannot replace the cue")
	p.rotation.y=PI/2
	check(cue.direction().is_equal_approx(Vector2.DOWN),"Indicator follows facing changes toward original impact location")
	p.rotation=Vector3.ZERO
	for pair in [[Vector3.FORWARD,Vector2.UP],[Vector3.BACK,Vector2.DOWN],[Vector3.LEFT,Vector2.LEFT]]:
		p.invulnerable=0; p.receive_damage(10,p.global_position+pair[0]*5)
		check(cue.direction().is_equal_approx(pair[1]),"Front, rear and left hits point correctly: "+str(pair[0]))
	p.character.equip(p.character.add_item("iron_sword"),"main_hand")
	p.character.equip(p.character.add_item("iron_shield"),"off_hand")
	p.invulnerable=0; p.blocking=true; p.parry_window=0; p.stamina=100
	p.receive_damage(10,p.global_position+Vector3.FORWARD*3)
	check(cue.outcome=="BLOCK","Shield block gets distinct labeled feedback")
	p.invulnerable=0; p.blocking=true; p.parry_window=.22; p.stamina=100
	var hp: float=p.health
	p.receive_damage(10,p.global_position+Vector3.FORWARD*3,w.adventure.enemies[0])
	check(cue.outcome=="PARRY" and p.health==hp,"Successful parry displays without health loss")
	p.invulnerable=0; p.parry_window=0; p.stamina=1; p.blocking=true
	p.receive_damage(10,p.global_position+Vector3.FORWARD*3)
	check(cue.outcome=="GUARD BROKEN","Exhausted guard identifies its failed defense")
	cue._process(.91)
	check(not cue.visible and cue.remaining==0,"Cue expires without lingering")
	p.invulnerable=0; p.receive_damage(1,p.global_position)
	check(cue.visible and cue.direction()==Vector2.ZERO,"Non-directional damage shows outcome without inventing a bearing")
	p.set_paused(true); cue._process(.01)
	check(not cue.visible and cue.remaining==0,"Menus clear previous combat feedback")
	p.set_paused(false); cue._process(.01)
	check(not cue.visible,"Returning from menu cannot resurrect stale cue")
	p.health=p.derived.health; p.invulnerable=0; p.receive_damage(100000,p.global_position+Vector3.BACK)
	check(not cue.visible,"Death clears cue before respawn")
	w.queue_free(); await process_frame
	print("DAMAGE_DIRECTION_COMPLETE checks=%d failures=%d" % [checks,failures]); quit(1 if failures else 0)
