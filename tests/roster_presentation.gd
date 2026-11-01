extends SceneTree
const Wild=preload("res://scripts/wild_creature.gd")
var checks:=0
var failures:=0
func _initialize() -> void: call_deferred("run")
func check(ok: bool,label: String) -> void:
	checks+=1
	if not ok: failures+=1; push_error("FAIL "+label)
	else: print("PASS "+label)
func pose(n: Node3D) -> Array:
	var result: Array=[n.transform,n.visible]
	for child in n.get_children():
		if child is Node3D: result.append_array(pose(child))
	return result
func run() -> void:
	var w=load("res://scenes/main.tscn").instantiate(); root.add_child(w)
	for i in range(6): await physics_frame
	var p=w.player; p.set_process(false); p.set_physics_process(false)
	assert(not p.character.persist and not w.atlas.persist)
	p.character.roots.cleansed=["spring","stone","seed"]; p.character.choir.activated=true; p.character.lens.activated=true
	var actors=[w.wilderness.enemies[0],w.wilderness.enemies[3],w.wilderness.enemies[11],w.wilderness.enemies[12],w.roots.enemies[3],w.shore.enemies[6],w.choir.enemies[4],w.lens.enemies[4]]
	for e in actors:
		e.set_physics_process(false); e.adventure.inside=true; p.position=e.global_position+Vector3.BACK*2
		e.windup=0; e.execution_progress=0; e.update_execution_pose()
		var neutral=pose(e.rig); var collision=e.transform; var health=e.health
		e.execution_locked=true; e.set_execution_pose(.7)
		check(pose(e.rig)!=neutral and e.transform==collision and e.health==health,e.title+" reaction moves model only")
		var reaction=pose(e.rig); e._physics_process(.01)
		check(pose(e.rig)==reaction,e.title+" physics preserves locked reaction")
		e.execution_locked=false; e.set_execution_pose(0)
		check(pose(e.rig)==neutral,e.title+" cancellation restores pose")
		e.health=1; e.receive_damage(10000,p)
		check(e.dead and e.has_node("DefeatMotion") and e.collision_layer==0,e.title+" death starts collapse and disables collision")
		var motion=e.get_node("DefeatMotion"); motion.set_process(false)
		var before=pose(e.rig); motion._process(.2)
		check(pose(e.rig)!=before,e.title+" collapse animates")
		var midway=pose(e.rig); p.set_paused(true); motion._process(2)
		check(pose(e.rig)==midway,e.title+" pause freezes collapse"); p.set_paused(false); motion._process(2)
		var settled=pose(e.rig); e._physics_process(.1)
		check(pose(e.rig)==settled,e.title+" corpse stable")
		var restored=e.get_script().new(); restored.adventure=e.adventure; restored.enemy_id=e.enemy_id; restored.progress=e.progress
		if e is Wild: restored.species=e.species
		e.adventure.add_child(restored); restored.set_physics_process(false)
		check(restored.dead and pose(restored.rig)==settled,e.title+" saved corpse reconstructed")
		restored.queue_free()
	w.queue_free(); await process_frame
	print("ROSTER_PRESENTATION_COMPLETE checks=%d failures=%d" % [checks,failures]); quit(1 if failures else 0)
