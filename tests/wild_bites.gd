extends SceneTree
var checks:=0
var failures:=0
func _initialize() -> void: call_deferred("run")
func check(ok: bool,label: String) -> void:
	checks+=1
	if not ok: failures+=1; push_error("FAIL "+label)
func run() -> void:
	var w=load("res://scenes/main.tscn").instantiate(); root.add_child(w)
	for i in range(6): await physics_frame
	var p=w.player; p.set_process(false); p.set_physics_process(false)
	for e in w.wilderness.enemies: e.set_physics_process(false)
	for e in [w.wilderness.enemies[0],w.wilderness.enemies[3]]:
		p.position=e.home+Vector3.BACK*1.5; p.invulnerable=0; e.cooldown=0
		var hp: float=p.health
		e._physics_process(.01); e._physics_process(.4)
		check(p.health==hp and e.bite_head.position.z>-.82 and e.bite_jaw.rotation.x<-.2,e.species+" draws back and opens jaw before damage")
		e._physics_process(.26)
		check(p.health<hp and e.bite_head.position.z<-.82 and e.bite_recoil>0,e.species+" bite snaps forward on the damage frame")
		e._physics_process(.23)
		check(e.bite_recoil==0 and e.bite_jaw.rotation.x==0,e.species+" recovery closes jaw")
		e.windup=.2; e.update_bite_pose(); p.set_paused(true); e._physics_process(.1)
		check(e.windup==0 and is_equal_approx(e.bite_head.position.z,-.82) and e.bite_jaw.rotation.x==0,e.species+" menu clears bite pose")
		p.set_paused(false); e.cooldown=0; p.position=e.home+Vector3.BACK*1.5
		e._physics_process(.01); hp=p.health; p.position=e.home+Vector3.BACK*3; e._physics_process(.66)
		check(p.health==hp,e.species+" retreat still avoids the bite")
	w.queue_free(); await process_frame
	print("WILD_BITES_COMPLETE checks=%d failures=%d" % [checks,failures]); quit(1 if failures else 0)
