extends SceneTree
const State=preload("res://scripts/character_state.gd")
const Trade=preload("res://scripts/trade.gd")
var checks:=0
var failures:=0
var w: Node3D
func _initialize() -> void: call_deferred("run")
func check(ok: bool,label: String) -> void:
	checks+=1
	if ok: print("PASS "+label)
	else: failures+=1; push_error("FAIL "+label)
func talk(c: Node3D, id: String) -> void:
	c.close_dialog(); w.player.set_paused(false); w.player.position=c.ORIGIN+c.NODES[id]+Vector3(0,.1,1.4); c.open_dialog(id)
func run() -> void:
	w=load("res://scenes/main.tscn").instantiate(); root.add_child(w)
	for i in range(6): await physics_frame
	w.player.set_physics_process(false)
	var s=w.player.character
	check(not s.persist and not w.atlas.persist,"Recovery QA is isolated")
	for component in ["transit_regulator","cinder_ward"]:
		var c: Node3D=w.convergence if component=="transit_regulator" else w.seal
		var recipe_id: String="forge_transit_regulator" if component=="transit_regulator" else "craft_cinder_ward"
		var recipe: Dictionary=s.definition("recipes",recipe_id)
		s.story_completed=["roots","tides","lens","choir","returning_light","winter_siege"]
		w.player.set_paused(false); c.enter()
		for enemy in c.enemies: enemy.set_physics_process(false)
		talk(c,"supplies")
		check(not c.act("recover_component"),"Cannot recover before chapter acceptance: "+component)
		talk(c,"keeper"); c.act("accept")
		talk(c,"supplies"); c.act("supplies")
		for material in recipe.cost: s.materials[material]=0
		check(not c.act("recover_component"),"Spent supplies alone cannot bypass learning the design: "+component)
		if component=="transit_regulator":
			for evidence in c.REQUIRED: talk(c,evidence); c.act("evidence")
		else:
			s.seal.valves=["intake","exhaust"]; s.seal.defeated=["seal_0","seal_1","seal_2","seal_3"]
			talk(c,"plans"); c.act("plans")
		talk(c,"supplies")
		check(s.story_recovery_available(component) and c.description.text.contains("damaged"),"Supply chest explains available emergency rebuild: "+component)
		var progress: Dictionary=s.convergence if component=="transit_regulator" else s.seal
		progress.supplies=false
		check(not s.story_recovery_available(component),"Original supply pickup is required even with learned design: "+component)
		progress.supplies=true
		for material in recipe.cost: s.materials[material]=recipe.cost[material]
		check(not s.story_recovery_available(component),"Affordable recipe keeps normal crafting path: "+component)
		for material in recipe.cost: s.materials[material]=0
		var gold: int=s.gold; var xp: int=s.craft_xp; var skill: Dictionary=s.skills.duplicate(true); var before: Dictionary=s.materials.duplicate(true)
		w.player.position+=Vector3(10,0,0)
		check(not c.act("recover_component"),"Recovery rechecks proximity: "+component)
		talk(c,"keeper"); check(not c.act("recover_component"),"Recovery requires supply chest: "+component)
		talk(c,"supplies")
		var action: Button
		for button in c.options.get_children():
			if button is Button and button.text.begins_with("Rebuild 1"): action=button
		check(action!=null,"Actual recovery button is offered: "+component)
		if action: action.pressed.emit()
		check(s.materials.get(component,0)==1 and not c.act("recover_component"),"Recovery grants one component and cannot repeat: "+component)
		check(c.description.text.contains("is ready"),"Chest confirms recovery and next action: "+component)
		before[component]=1
		check(s.materials==before and s.gold==gold and s.craft_xp==xp and s.skills==skill,"No raw materials, gold or XP are generated: "+component)
		var trade=Trade.new(s)
		check(trade.sell("outfitter","material",component,1)=="This item cannot be sold." and s.materials[component]==1,"Recovered component cannot be sold: "+component)
		var path="user://recovery-test.json"
		check(s.save_to(path),"Recovery inventory saves: "+component)
		var loaded=State.new()
		check(loaded.load_from(path) and loaded.materials.get(component,0)==1 and not loaded.story_recovery_available(component),"Save reload preserves component and duplicate guard: "+component)
		DirAccess.remove_absolute(path)
		if component=="transit_regulator":
			talk(c,"rig"); check(c.act("install") and s.convergence.installed,"Recovered regulator installs through normal quest action")
		else:
			talk(c,"seal"); check(not c.act("bind"),"Recovered ward does not bypass boss defeat")
			s.seal.defeated.append("seal_4"); check(c.act("bind") and s.seal.bound,"Recovered ward binds through normal quest action")
		check(s.materials[component]==0 and not s.story_recovery_available(component),"Consumed component cannot regenerate after objective: "+component)
		c.close_dialog(); w.player.set_paused(false); c.leave()
	# Independently verify the fallback stays unavailable while ordinary crafting is affordable.
	s.convergence.installed=false; s.materials.transit_regulator=0
	var recipe: Dictionary=s.definition("recipes","forge_transit_regulator")
	for material in recipe.cost: s.materials[material]=recipe.cost[material]
	check(not s.story_recovery_available("transit_regulator"),"Sufficient ingredients retain normal forge requirement")
	w.queue_free(); await process_frame
	print("STORY_RECOVERY_COMPLETE checks=%d failures=%d" % [checks,failures]); quit(1 if failures else 0)
