extends SceneTree
const Detail=preload("res://scripts/winter_ground_detail.gd")
var checks:=0
var failures:=0
func _initialize() -> void: call_deferred("run")
func check(ok: bool,label: String) -> void:
	checks+=1
	if not ok: failures+=1; push_error("FAIL "+label)
func run() -> void:
	var w=load("res://scenes/main.tscn").instantiate(); root.add_child(w)
	for i in range(6): await physics_frame
	w.player.set_physics_process(false)
	check(Detail.pieces().size()==75,"Ground detail stays within 75-block budget")
	for i in range(Detail.ROCKS.size()):
		var at: Vector3=w.mountain.ORIGIN+Detail.ROCKS[i]
		var ray=PhysicsRayQueryParameters3D.create(at+Vector3.UP*2,at+Vector3.DOWN,1)
		var hit=w.player.get_world_3d().direct_space_state.intersect_ray(ray)
		check(not hit.is_empty() and is_equal_approx(hit.position.y,.64+(i%3)*.12),"Snow-capped rock has matching physical top")
		check(w.footstep_at(at+Vector3.UP*(.64+(i%3)*.12))=="step_snow","Rock snow cap selects snowy footsteps")
	for site in Detail.Pines.SITES:
		var at: Vector3=w.mountain.ORIGIN+Vector3(site.x+.8,.27,site.z)
		check(w.footstep_at(at)=="step_snow" and w.session_save.supported_position(at+Vector3.UP*.05,w.player),"Drift supports player and snowy footsteps")
	w.queue_free(); await process_frame
	print("WINTER_GROUND_COMPLETE checks=%d failures=%d" % [checks,failures]); quit(1 if failures else 0)
