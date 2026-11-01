extends SceneTree
const State=preload("res://scripts/character_state.gd")
const SAVE="user://save-cycle-stress.json"
var checks:=0
var failures:=0
func _initialize() -> void: call_deferred("run")
func check(ok: bool,label: String) -> void:
	checks+=1
	if not ok: failures+=1; push_error("FAIL "+label)
func run() -> void:
	var w=load("res://scenes/main.tscn").instantiate(); root.add_child(w)
	for i in range(6): await physics_frame
	var p=w.player; var s=p.character; var session=w.session_save
	p.set_physics_process(false); p.set_process(false)
	check(not s.persist and not session.save_now(),"Fixture cannot overwrite regular profile")
	for actor in w.wilderness.enemies+w.adventure.enemies+w.mountain.enemies+w.archive_chapter.enemies: actor.set_physics_process(false)
	s.story_completed.append("stonewake")
	for mat in s.crafting.materials: s.materials[mat.id]=1000
	var uid: String=s.add_item("iron_sword"); s.equip(uid,"main_hand"); s.inventory[uid].favorite=true
	check(s.improve(uid,"forge").begins_with("Improved"),"Real forge upgrade prepares roundtrip item")
	var wolf=w.wilderness.enemies[0]; p.position=wolf.global_position+Vector3.BACK
	wolf.receive_damage(1000,p,"","melee"); check(w.wilderness.loot(),"Real defeat and harvest establish one-time proof")
	var initial_gold: int=s.gold
	var initial_items: int=s.inventory.size()
	for cycle in range(24):
		var area: String=["home","archive_chapter","mountain","adventure"][cycle%4]
		var entry: Dictionary={"area":area,"position":[9999,0,0],"yaw":.3,"pitch":-.2,"third_person":cycle%2==0,"health":31,"magicka":22,"stamina":19,"enemies":[]}
		check(session.restore(entry),"Cycle %d enters %s" % [cycle,area])
		if cycle%4==0: s.add_item("iron_dagger")
		var expected_inventory: Dictionary=s.inventory.duplicate(true)
		var expected_materials: Dictionary=s.materials.duplicate(true)
		check(s.save_to(SAVE) and not FileAccess.file_exists(SAVE+".tmp"),"Atomic save replaces file without leftover temporary file")
		var loaded=State.new()
		check(loaded.load_from(SAVE),"Fresh state loads saved character")
		check(loaded.inventory==expected_inventory and loaded.equipment.main_hand==uid and loaded.materials==expected_materials,"Inventory IDs, upgrade, favorite, equipment and materials survive")
		check(loaded.wilderness==s.wilderness and loaded.gold==initial_gold,"Defeat, harvest and gold remain stable")
		check(loaded.save_to(SAVE),"Loaded state can be saved again")
		var again=State.new()
		check(again.load_from(SAVE) and again.inventory==loaded.inventory and again.next_id==s.next_id,"Second-generation serialization retains inventory identity")
		p.health=1; p.position=Vector3.ZERO
		check(session.restore(again.session) and session.area()==area and p.health==31 and p.magicka==22 and p.stamina==19,"Serialized session restores area and player resources")
		var corpse=wolf.get_script().new(); corpse.adventure=w.wilderness; corpse.enemy_id=wolf.enemy_id; corpse.progress=again.wilderness
		w.wilderness.add_child(corpse); corpse.set_physics_process(false)
		check(corpse.dead and not corpse.label.visible,"Loaded defeated and looted creature reconstructs without visible loot label")
		corpse.queue_free(); await process_frame
	check(s.inventory.size()==initial_items+6 and s.gold==initial_gold,"Only six intentional added items exist after repeated loads")
	w.adventure.leave(); p.set_paused(false); p.position=wolf.global_position+Vector3.BACK
	check(not w.wilderness.loot() and s.gold==initial_gold,"Returning after roundtrips cannot harvest the same creature again")
	DirAccess.remove_absolute(SAVE); DirAccess.remove_absolute(SAVE+".tmp")
	w.queue_free(); await process_frame
	print("SAVE_CYCLE_STRESS_COMPLETE cycles=24 checks=%d failures=%d" % [checks,failures]); quit(1 if failures else 0)
