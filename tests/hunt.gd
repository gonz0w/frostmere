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
	for i in range(5): await physics_frame
	var p=world.player; var h=world.hunts; var s=p.character
	p.set_physics_process(false)
	for e in world.wilderness.enemies: e.set_physics_process(false)
	check(not h.accept() and not h.claim("mossfang_blade"),"Remote board actions rejected")
	p.position=h.POSITION+Vector3.BACK
	world.interact_nearby()
	check(h.panel.visible and p.paused and p.dialog_open,"E opens physical hunt board")
	h.actions.get_child(0).pressed.emit()
	check(s.hunt.accepted and not h.accept(),"Accept button starts hunt once")
	check(not h.claim("mossfang_blade"),"Incomplete hunt cannot grant reward")
	h.close()
	for id in h.TARGETS:
		var e=world.wilderness.enemies.filter(func(x): return x.enemy_id==id)[0]
		p.position=e.global_position+Vector3.BACK
		e.receive_damage(10000,p,"","melee")
		check(world.wilderness.loot(),"Harvest actual target "+id)
	check(h.eligible() and h.completed_targets()==4,"Northern pack and colossus complete proof requirements")
	check(not h.claim("mossheart_amulet"),"Finished hunt still requires return to board")
	p.position=h.POSITION; h.open()
	var gold: int=s.gold; var count: int=s.inventory.size()
	h.actions.get_child(0).pressed.emit()
	check(s.hunt.reward=="mossfang_blade" and s.gold==gold+120 and s.inventory.size()==count+1,"Actual reward button grants chosen gear and gold")
	check("mossbound" in s.blueprints and not h.claim("mossheart_amulet"),"Both patterns unlocked without duplicate reward choice")
	var uid: String=""
	for id in s.inventory:
		if s.inventory[id].base_id=="mossfang_blade": uid=id
	check(s.inventory[uid].quality==1 and s.inventory[uid].favorite,"Quest heirloom starts Fine and protected as favorite")
	for m in s.crafting.materials: s.materials[m.id]=100
	check(s.craft_recipe("craft_mossheart_amulet","forge").begins_with("Created"),"Unchosen reward can be forged")
	var quality: int=s.inventory[uid].quality
	check(s.improve(uid,"forge").begins_with("Improved") and s.inventory[uid].quality==quality+1,"Reward supports real tempering")
	check(s.save_to("user://hunt-test.json"),"Completed hunt saves")
	var loaded=preload("res://scripts/character_state.gd").new()
	check(loaded.load_from("user://hunt-test.json") and loaded.hunt==s.hunt,"Hunt completion and reward survive reload")
	var data=JSON.parse_string(FileAccess.get_file_as_string("user://hunt-test.json"))
	data.wilderness.looted=[]
	check(not s.valid_hunt(data),"Reward record requires earned proofs")
	data.hunt={"accepted":false,"reward":"mossfang_blade"}
	check(not s.valid_hunt(data),"Unaccepted rewarded record rejected")
	s.hunt={"accepted":false,"reward":""}; h.close(); h.open()
	check(h.accept() and h.eligible(),"Existing harvests count when accepting later")
	check(h.claim("mossheart_amulet"),"Alternative reward branch works")
	var key=InputEventKey.new(); key.physical_keycode=KEY_ESCAPE; key.pressed=true; p._unhandled_input(key)
	check(not h.panel.visible and not p.paused,"Escape closes board and resumes exploration")
	DirAccess.remove_absolute("user://hunt-test.json")
	world.queue_free(); await process_frame
	print("HUNT_COMPLETE checks=%d failures=%d" % [checks,failures]); quit(1 if failures else 0)
