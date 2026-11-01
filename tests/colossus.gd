extends SceneTree
var checks := 0
var failures := 0
func _initialize() -> void: call_deferred("run")
func check(ok: bool, label: String) -> void:
	checks += 1
	if ok: print("PASS " + label)
	else: failures += 1; push_error("FAIL " + label)
func run() -> void:
	var world = load("res://scenes/main.tscn").instantiate(); root.add_child(world)
	for i in range(6): await physics_frame
	var p = world.player; var giant = world.wilderness.enemies[11]
	p.set_physics_process(false)
	for e in world.wilderness.enemies: e.set_physics_process(false)
	p.position = giant.home + Vector3(0,0,4); p.invulnerable = 0; p.blocking = false
	giant.slam_cooldown = 0; giant._physics_process(.01)
	check(giant.slam_remaining == 1.5 and giant.warning.visible,"Nearby colossus starts visible warning before damage")
	var hp: float = p.health
	giant._physics_process(.7)
	check(p.health == hp and giant.slam_remaining > 0,"Warning allows reaction time")
	check(giant.slam_arms.size()==2 and giant.slam_arms[0].rotation.x>1,"Warning raises both stone arms")
	p.position = giant.home + Vector3(0,0,6)
	giant._physics_process(.81)
	check(p.health == hp and not giant.warning.visible and giant.slam_cooldown == 7,"Leaving ring avoids impact and starts recovery")
	check(giant.slam_recoil>0 and giant.rig.position.y<0 and giant.slam_arms[0].position.y<3.35,"Resolved slam drives arms down into impact pose")
	giant._physics_process(.41)
	check(giant.slam_recoil==0 and giant.rig.position.y==0 and giant.slam_arms[0].rotation.x==0,"Slam pose settles during cooldown")
	p.position = giant.home + Vector3(0,0,4); giant.start_slam(); giant._physics_process(1.51)
	check(p.health < hp and giant.slam_remaining == 0,"Remaining inside ring takes damage")
	p.invulnerable = 0; hp = p.health; giant._physics_process(.2)
	check(p.health == hp,"Completed slam cannot hit a second time")
	var wall := StaticBody3D.new(); wall.collision_layer=1; world.add_child(wall)
	var shape := CollisionShape3D.new(); var box := BoxShape3D.new(); box.size=Vector3(4,5,.5); shape.shape=box; wall.add_child(shape)
	wall.global_position=giant.global_position+Vector3(0,2,2)
	await physics_frame
	p.invulnerable=0; hp=p.health; giant.start_slam(); giant._physics_process(1.51)
	check(p.health==hp,"Solid cover prevents area damage through walls")
	wall.queue_free(); await physics_frame
	p.rotation=Vector3.ZERO; p.blocking=true; p.parry_window=.22; p.stamina=p.derived.stamina; p.invulnerable=0
	giant.start_slam(); giant._physics_process(1.51)
	check(p.health<hp and p.stamina<p.derived.stamina and giant.stagger_time==0,"Guard reduces slam but perfect-parry timing cannot negate area impact")
	p.blocking=false; p.health=p.derived.health; hp=p.health; p.invulnerable=0
	giant.health = giant.maximum_health*.5
	giant.start_slam(); giant._physics_process(1.51)
	check(giant.awakened and giant.slam_cooldown == 4 and is_equal_approx(hp-p.health,48.0*100.0/(100.0+float(p.derived.armor)*1.5)),"Half health activates stronger faster slam cycle")
	giant._physics_process(.01)
	check(giant.label.text.begins_with("Awakened"),"Second phase is named on enemy label")
	p.health = p.derived.health; p.invulnerable = 0
	giant.start_slam(); p.set_paused(true); giant._physics_process(.1)
	check(giant.slam_remaining == 0 and not giant.warning.visible,"Opening a menu cancels telegraph safely")
	check(giant.slam_recoil==0 and giant.slam_arms[0].rotation.x==0,"Menu clears arm pose and recoil")
	p.set_paused(false); giant.start_slam(); giant.execution_locked = true; giant._physics_process(.1)
	check(giant.slam_remaining == 0 and not giant.warning.visible,"Finisher lock cancels pending slam")
	giant.execution_locked = false; giant.start_slam(); world.adventure.enter(); giant._physics_process(.1)
	check(not giant.warning.visible and not giant.visible,"Chapter travel clears world warning and creature")
	world.adventure.leave(); p.set_paused(false); p.position=giant.home+Vector3(0,0,4)
	giant.start_slam(); p.position=Vector3.ZERO; giant._physics_process(.1)
	check(giant.slam_remaining == 0,"Retreat into village cancels pending slam")
	p.position=giant.home+Vector3(0,0,4); giant.start_slam(); giant.parried()
	check(giant.slam_remaining == 0 and not giant.warning.visible,"Stagger cleanup removes telegraph")
	giant.stagger_time=0; giant.start_slam(); giant.receive_damage(10000,p,"","melee")
	check(giant.dead and not giant.warning.visible and giant.slam_remaining == 0,"Killing during warning prevents posthumous impact")
	p.position=giant.position+Vector3.BACK
	check(world.wilderness.loot() and "wild_11" in p.character.wilderness.looted,"Upgraded encounter retains hunt proof and normal harvest")
	world.queue_free(); await process_frame
	print("COLOSSUS_COMPLETE checks=%d failures=%d" % [checks,failures]); quit(1 if failures else 0)
