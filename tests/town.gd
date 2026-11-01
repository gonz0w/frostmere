extends SceneTree
const Town=preload("res://scripts/town_layout.gd")
var checks:=0
var failures:=0
func _initialize() -> void: call_deferred("run")
func check(ok: bool,label: String) -> void:
	checks+=1
	if ok: print("PASS "+label)
	else: failures+=1; push_error("FAIL "+label)
func run() -> void:
	var world=load("res://scenes/main.tscn").instantiate(); root.add_child(world)
	for i in range(5): await physics_frame
	var p=world.player; p.set_physics_process(false); p.collision_mask=1
	for e in world.wilderness.enemies: e.set_physics_process(false)
	check(Town.HOMES.size()==3 and Town.HOMES[0].x == -17,"Moved home and two new homes have authored staggered locations")
	for index in range(3):
		var home: Vector3=Town.HOMES[index]
		var depth: float=9 if index==0 else 6 if index==1 else 5
		p.position=home+Vector3(0,.15,depth/2+2); p.velocity=Vector3.ZERO
		for step in range(100):
			p.velocity=Vector3(0,-1,-3); p.move_and_slide(); await physics_frame
			if p.position.z < home.z+depth/2-.8: break
		check(p.position.z < home.z+depth/2-.8 and p.position.y>.1,"New/moved home doorway is traversable: "+str(index))
		check(world.wilderness.town_safe(p.position),"Home interior remains protected from wildlife: "+str(index))
	check(Town.path_at(-17,-24) and Town.path_at(-18,23) and Town.path_at(5,24),"All new door approaches connect to lanes")
	check(Town.path_at(0,17) and Town.path_at(0,-18),"Main walking spine remains connected")
	for entry in p.character.crafting.nodes:
		var at=Vector3(entry.position[0],.15,entry.position[2])
		check(world.session_save.supported_position(at,p),"Gathering approach stays clear: "+entry.id)
	p.position=Vector3(0,.15,17); p.velocity=Vector3.ZERO
	for step in range(210):
		p.velocity=Vector3(0,-1,-3); p.move_and_slide(); await physics_frame
	check(p.position.z<7,"Main arrival route remains walkable past new street furniture")
	world.queue_free(); await process_frame
	print("TOWN_COMPLETE checks=%d failures=%d" % [checks,failures]); quit(1 if failures else 0)
