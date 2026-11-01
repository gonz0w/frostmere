extends SceneTree
const Effect=preload("res://scripts/ground_slam_effect.gd")
var checks:=0
var failures:=0
func _initialize() -> void: call_deferred("run")
func check(ok: bool,label: String) -> void:
	checks+=1
	if not ok: failures+=1; push_error("FAIL "+label)
func run() -> void:
	var w=load("res://scenes/main.tscn").instantiate(); root.add_child(w)
	for i in range(6): await physics_frame
	var p=w.player; var e=w.wilderness.enemies[11]
	p.set_process(false); p.set_physics_process(false)
	for actor in w.wilderness.enemies: actor.set_physics_process(false)
	p.position=e.home+Vector3.BACK*6
	e.start_slam(); e._physics_process(.7)
	check(not w.wilderness.has_node("GroundSlamDebris"),"Warning has no premature debris")
	e._physics_process(.81)
	var effect=w.wilderness.get_node("GroundSlamDebris"); effect.set_process(false)
	check(effect.chips.size()==24,"Resolved missed slam emits bounded debris")
	var hp: float=p.health
	effect._process(.2)
	var grounded:=true
	for chip in effect.chips:
		grounded=grounded and chip.global_position.y>w.Terrain.height_at(chip.global_position.x,chip.global_position.z)
	check(grounded and p.health==hp,"Debris rises above terrain without additional damage")
	var at: Vector3=effect.chips[0].position
	p.set_paused(true); effect._process(.2)
	check(is_equal_approx(effect.age,.2) and effect.chips[0].position==at and not effect.visible,"Menu hides and freezes debris")
	p.set_paused(false); effect._process(.1)
	check(effect.visible and effect.chips[0].position!=at,"Debris resumes after menu")
	effect._process(.4); check(effect.is_queued_for_deletion(),"Debris expires within its short lifetime")
	var leaving=Effect.spawn(e,e.global_position); leaving.set_process(false)
	w.adventure.enter(); leaving._process(.01)
	check(leaving.is_queued_for_deletion(),"Leaving the wilderness removes debris")
	w.queue_free(); await process_frame
	print("GROUND_SLAM_EFFECT_COMPLETE checks=%d failures=%d" % [checks,failures]); quit(1 if failures else 0)
