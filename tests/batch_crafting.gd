extends SceneTree
const State=preload("res://scripts/character_state.gd")
var checks:=0
var failures:=0
func _initialize() -> void: call_deferred("run")
func check(ok: bool,label: String) -> void:
	checks+=1
	if ok: print("PASS "+label)
	else: failures+=1; push_error("FAIL "+label)
func snapshot(s: RefCounted) -> Dictionary:
	return {"materials":s.materials.duplicate(true),"consumables":s.consumables.duplicate(true),"inventory":s.inventory.duplicate(true),"skills":s.skills.duplicate(true),"xp":s.craft_xp}
func fund(s: RefCounted,r: Dictionary) -> void:
	if r.unlock not in s.blueprints: s.blueprints.append(r.unlock)
	for id in r.cost: s.materials[id]=int(r.cost[id])*10
func run() -> void:
	var catalog=State.new()
	for r in catalog.crafting.recipes:
		if not catalog.recipe_batchable(r): continue
		var single=State.new(); var batch=State.new(); fund(single,r); fund(batch,r)
		for i in range(10): single.craft_recipe(r.id,r.station)
		var result: String=batch.craft_recipe(r.id,r.station,10)
		check(result.begins_with("Created") and snapshot(single)==snapshot(batch),"Ten-batch output, cost and XP equal ten singles: "+r.id)
	var s=State.new(); var arrow: Dictionary=s.definition("recipes","craft_arrows"); fund(s,arrow)
	var before:=snapshot(s)
	for count in [0,-1,11,1000000]: s.craft_recipe("craft_arrows","forge",count)
	check(snapshot(s)==before,"Out-of-range batch requests change nothing")
	s.craft_recipe("craft_arrows","alchemy",5)
	check(snapshot(s)==before,"Wrong workstation cannot batch craft")
	s.blueprints.erase(arrow.unlock); s.craft_recipe("craft_arrows","forge",5)
	check(snapshot(s)==before,"Locked blueprint cannot batch craft")
	s.blueprints.append(arrow.unlock); s.materials.wood=4; before=snapshot(s)
	s.craft_recipe("craft_arrows","forge",5)
	check(snapshot(s)==before,"Insufficient total supplies reject the whole batch")
	for id in ["forge_transit_regulator","craft_cinder_ward"]:
		var recipe: Dictionary=s.definition("recipes",id); fund(s,recipe); before=snapshot(s)
		s.craft_recipe(id,recipe.station,5)
		check(snapshot(s)==before,"Story component stays single-craft: "+id)
	var gear: Dictionary={}
	for recipe in s.crafting.recipes:
		if recipe.output_kind=="gear": gear=recipe; break
	fund(s,gear); before=snapshot(s); s.craft_recipe(gear.id,gear.station,5)
	check(snapshot(s)==before,"Owned equipment stays single-craft")
	var w=load("res://scenes/main.tscn").instantiate(); root.add_child(w)
	for i in range(6): await physics_frame
	var p=w.player; var menu=w.hud.workshop; p.set_physics_process(false)
	check(not p.character.persist,"Batch UI fixture is isolated")
	p.position=Vector3(-4,.15,-11); fund(p.character,arrow)
	menu.open("forge"); menu.mode="Forge"; menu.selected="craft_arrows"; menu.show_detail()
	var five: Button
	for child in menu.actions.get_children():
		if child is Button and child.text.begins_with("Craft 5 batches"): five=child
	check(five!=null and not five.disabled and five.text.contains("60"),"UI exposes exact five-batch arrow yield")
	var old_arrows: int=p.character.materials.get("arrow",0)
	five.pressed.emit()
	check(p.character.materials.arrow==old_arrows+60 and menu.status.text.contains("5 batches"),"Actual batch button crafts correct quantity once")
	menu.show_detail()
	for child in menu.actions.get_children():
		if child is Button and child.text.begins_with("Craft 5 batches"): five=child
	p.position=Vector3(100,0,100); before=snapshot(p.character); five.pressed.emit()
	check(snapshot(p.character)==before,"Stale batch button rechecks workstation proximity")
	w.queue_free(); await process_frame
	print("BATCH_CRAFTING_COMPLETE checks=%d failures=%d" % [checks,failures]); quit(1 if failures else 0)
