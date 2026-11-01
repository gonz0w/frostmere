extends SceneTree
const Guide=preload("res://scripts/campaign_guide.gd")
var checks:=0
var failures:=0
func _initialize() -> void: call_deferred("run")
func check(ok: bool,label: String) -> void:
	checks+=1
	if ok: print("PASS "+label)
	else: failures+=1; push_error("FAIL "+label)
func ids(w: Node) -> Array:
	return Guide.routes(w).map(func(route): return route.id)
func run() -> void:
	var w=load("res://scenes/main.tscn").instantiate(); root.add_child(w)
	for i in range(6): await physics_frame
	w.player.set_physics_process(false)
	var s=w.player.character
	check(not s.persist and ids(w).is_empty(),"New profile keeps first adventure guidance")
	s.story_completed=["stonewake"]
	check(ids(w)==["council","archive","roots"],"Stonewake exposes three parallel paths")
	check(Guide.routes(w)[0].target==w.mountain.PASS,"Home route targets the actual pass")
	s.story_completed.append("council")
	check(ids(w)==["archive","roots","choir"],"Council handoff includes Pinehall and Caldera")
	s.story_completed.append("archive")
	check("lens" in ids(w) and "tides" in ids(w),"Lens and coast both available after archive")
	w.hud.world_map.selected_quest="lens"; w.hud.world_map._show_quest(); w.hud.world_map._refresh()
	check(w.hud.world_map.quest_text.text.contains("Route from Frostmere") and w.hud.world_map.status.text.contains("Sunken Lens"),"Journal directions and map list expose parallel routes")
	s.roots.accepted=true
	check(Guide.routes(w)[0].id=="roots","Accepted unfinished branch gets resume priority")
	s.roots.accepted=false
	check(not "convergence" in ids(w) and not "threshold" in ids(w),"Incomplete branches cannot suggest later crossings")
	var combinations_ok:=true
	var branches: Array=["roots","tides","lens","choir"]
	for mask in range(16):
		s.story_completed=["stonewake","council","archive"]
		for bit in range(4):
			if mask & (1<<bit): s.story_completed.append(branches[bit])
		var available: Array=ids(w)
		if available.is_empty() or ("convergence" in available)!=(mask==15): combinations_ok=false
		for bit in range(4):
			if (branches[bit] in available)==bool(mask & (1<<bit)): combinations_ok=false
	check(combinations_ok,"All sixteen branch-completion combinations retain correct next steps")
	s.story_completed=["stonewake","council","archive"]
	s.story_completed.append_array(["roots","tides","lens","choir"])
	check(ids(w)==["convergence"],"All four findings lead to Mirewatch")
	s.story_completed.append("convergence")
	check(ids(w)==["threshold"] and Guide.routes(w)[0].target==w.lens.TRAIL,"Home expedition handoff targets Lens entrance, not distant station")
	w.lens.inside=true; w.player.position=w.threshold.TRAIL+Vector3(0,0,4)
	check(Guide.text_for(w).contains("4 m") and Guide.text_for(w).contains("transit vault"),"Inside Lens guides the final leg to the transit vault")
	w.lens.inside=false; w.player.position=Vector3.ZERO
	s.story_completed.append("threshold")
	check(ids(w)==["returning_light"] and Guide.routes(w)[0].target==w.realms.vector(w.realms.definitions.aeralis.portal),"Station completion points to the Aeralis gate")
	s.story_completed.append("returning_light")
	check(ids(w)==["winter_siege"],"Aeralis return leads to the winter defense")
	s.story_completed.append("winter_siege")
	check(ids(w)==["broken_seal"],"Winter defense leads to the wardworks")
	s.story_completed.append("broken_seal")
	check(ids(w)==["last_furnace"],"Hell is suggested only after its actual gate requirements")
	w.hud._process(.01)
	check(w.hud.objective.text.contains("THE LAST FURNACE"),"Actual HUD displays late-campaign next destination")
	w.atlas.waypoint="forge"
	check(Guide.text_for(w)=="","Manual walking waypoint remains authoritative")
	w.atlas.waypoint=""; w.roots.inside=true
	check(Guide.text_for(w)=="","Other chapter objectives remain local")
	w.roots.inside=false
	s.story_completed.append("last_furnace")
	check(ids(w).is_empty(),"Ending does not repeat completed campaign routes")
	check(not s.adventure.accepted and s.realm_progress.completed.is_empty(),"Guidance does not grant quest progress or rewards")
	w.queue_free(); await process_frame
	print("CAMPAIGN_GUIDE_COMPLETE checks=%d failures=%d" % [checks,failures]); quit(1 if failures else 0)
