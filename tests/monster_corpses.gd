extends SceneTree
var checks:=0
var failures:=0
func _initialize() -> void: call_deferred("run")
func check(ok: bool,label: String) -> void:
	checks+=1
	if ok: print("PASS "+label)
	else: failures+=1; push_error("FAIL "+label)
func pose(node: Node3D) -> Array:
	var result: Array=[node.transform,node.visible]
	for child in node.get_children():
		if child is Node3D: result.append_array(pose(child))
	return result
func run() -> void:
	var world=load("res://scenes/main.tscn").instantiate(); root.add_child(world)
	for i in range(6): await physics_frame
	var p=world.player; var r=world.realms; var t=world.threshold
	p.set_physics_process(false); p.set_process(false)
	p.character.threshold.power=true; p.character.threshold.air=true
	for e in r.enemies+t.enemies: e.set_physics_process(false)
	for e in [t.enemies[5],r.enemies[2],r.enemies[5]]:
		e.adventure.inside=true
		if e.adventure==r: r.current="aeralis" if e==r.enemies[2] else "crucible"
		e.health=5; e.windup=.3
		e.update_pose()
		var before: Transform3D=e.rig.transform
		e.receive_damage(100,p)
		var motion=e.get_node("DefeatMotion"); motion.set_process(false)
		check(e.rig.transform==before,e.title+" collapse starts from the live pose")
		motion._process(motion.duration*.4)
		check(e.rig.transform!=before and not motion.is_queued_for_deletion(),e.title+" collapse passes through an intermediate pose")
		var midway:=pose(e.rig)
		p.set_paused(true); e._physics_process(.1); motion._process(1)
		check(pose(e.rig)==midway,e.title+" menu freezes collapse")
		p.set_paused(false)
		if e==r.enemies[5]:
			r.current="aeralis"; motion._process(.01); r.current="crucible"
		else: motion._process(1)
		check(motion.is_queued_for_deletion(),e.title+" collapse finishes or settles on travel")
		check(e.dead and e.collision_layer==0 and e.collision_mask==0,e.title+" defeat disables collision")
		check(e.rig.rotation==Vector3.ZERO and e.rig.position.y<0,e.title+" settles instead of using humanoid side-roll")
		var settled:=pose(e.rig)
		e._physics_process(.1)
		check(pose(e.rig)==settled,e.title+" attack updates preserve the corpse")
		p.set_paused(true); e._physics_process(.1); p.set_paused(false)
		check(pose(e.rig)==settled,e.title+" menu preserves the corpse")
		var restored=e.get_script().new()
		restored.adventure=e.adventure; restored.enemy_id=e.enemy_id; restored.progress=e.progress
		e.adventure.add_child(restored); restored.set_physics_process(false)
		check(restored.dead and pose(restored.rig)==settled,e.title+" saved defeat reconstructs the same pose")
		restored.queue_free()
	check(not t.enemies[5].charge.visible and absf(t.enemies[5].legs[0].rotation.z)>.5,"Hullcarver folds legs and extinguishes charge")
	check(not r.enemies[2].shards[4].visible and r.enemies[2].head.rotation.x<0,"Prismwing retains broken feathers and lowered head")
	check(not r.enemies[5].vent.visible and r.enemies[5].bellows[0].scale.y<1,"Maw clears rupture and compresses bellows")
	world.queue_free(); await process_frame
	print("MONSTER_CORPSES_COMPLETE checks=%d failures=%d" % [checks,failures]); quit(1 if failures else 0)
