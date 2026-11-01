extends SceneTree
const State = preload("res://scripts/atlas_state.gd")
var failures := 0
var checks := 0
var visiting: Dictionary = {}
var visited: Dictionary = {}

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, message: String) -> void:
	checks += 1
	if condition:
		print("PASS " + message)
	else:
		failures += 1
		push_error("FAIL " + message)

func acyclic(id: String, quests: Dictionary) -> bool:
	if visiting.has(id):
		return false
	if visited.has(id):
		return true
	visiting[id] = true
	for required: String in quests[id].requires:
		if not quests.has(required) or not acyclic(required, quests):
			return false
	visiting.erase(id)
	visited[id] = true
	return true

func frames(count: int = 2) -> void:
	for i in range(count):
		await process_frame

func run() -> void:
	var atlas := State.new()
	check(atlas.regions.size() == 8 and atlas.locations.size() == 16 and atlas.factions.size() == 7 and atlas.quests.size() == 51, "World catalog has eight regions, sixteen locations, seven factions and fifty-one quests")
	var references := true
	var geography := true
	for location: Dictionary in atlas.data.locations:
		references = references and atlas.regions.has(location.region) and atlas.factions.has(location.faction)
		var points := PackedVector2Array()
		for p: Array in atlas.regions[location.region].polygon:
			points.append(Vector2(p[0], p[1]))
		if not Geometry2D.is_point_in_polygon(Vector2(location.point[0], location.point[1]), points):
			print("LOCATION_OUTSIDE_REGION ", location.id)
			geography = false
	check(references, "All locations reference defined regions and factions")
	check(geography, "Location markers lie inside their assigned biome")
	var faction_refs := true
	for faction: Dictionary in atlas.data.factions:
		faction_refs = faction_refs and atlas.locations.has(faction.home) and faction.ranks.size() == 3
		for kind in ["allies", "rivals"]:
			for other: String in faction[kind]:
				faction_refs = faction_refs and atlas.factions.has(other) and faction.id in atlas.factions[other][kind]
	check(faction_refs, "Faction homes, ranks, and reciprocal relationships are valid")
	var graph_valid := true
	for quest: Dictionary in atlas.data.quests:
		graph_valid = graph_valid and atlas.locations.has(quest.location) and (quest.faction == "" or atlas.factions.has(quest.faction)) and acyclic(quest.id, atlas.quests)
	check(graph_valid, "Quest prerequisites are valid and acyclic")
	var roads_valid := true
	for road: Dictionary in atlas.data.routes:
		roads_valid = roads_valid and atlas.locations.has(road.start) and atlas.locations.has(road.end)
	check(roads_valid, "All travel routes connect defined places")
	check(not atlas.start_quest("stonewake"), "Planned quest cannot be started")
	check(not atlas.set_waypoint("dunewell"), "Planned town cannot become a walking waypoint")
	check(not atlas.record_event("inspect_forge"), "Survey events do not progress an unstarted quest")
	check(atlas.start_quest("oldwatch_survey") and atlas.waypoint == "forge", "Survey starts at forge objective")
	check(not atlas.record_event("inspect_relic"), "Out-of-order objective rejected")
	check(atlas.record_event("inspect_forge") and atlas.survey_stage == 1 and atlas.waypoint == "crossing", "Forge advances survey to crossing")
	atlas.start_quest("oldwatch_survey")
	check(atlas.survey_stage == 1, "Retracking does not reset quest progress")
	atlas.set_waypoint("hall")
	check(atlas.waypoint_text() == "Ember Hall", "Manual waypoint uses its own destination label")
	atlas.record_event("reach_crossing")
	check(atlas.waypoint == "stones" and atlas.target_position().is_equal_approx(Vector3(31, 0, -33)), "Relic objective tracks actual interaction point")
	check(atlas.record_event("inspect_relic") and atlas.survey_complete() and atlas.waypoint == "", "Survey completes once and clears its tracker")
	check(not atlas.record_event("inspect_relic") and not atlas.start_quest("oldwatch_survey"), "Completed quest cannot be rewarded or restarted repeatedly")
	atlas.visit("stones")
	var save_path := ProjectSettings.globalize_path("res://build/atlas-test.json")
	check(atlas.save_to(save_path), "Atlas progress saves")
	var restored := State.new()
	check(restored.load_from(save_path) and restored.survey_complete() and restored.visits.has("stones"), "Quest completion and discoveries survive reload")
	var file := FileAccess.open(save_path, FileAccess.WRITE)
	file.store_string('{"version":1,"visits":{},"waypoint":"dunewell","survey_started":true,"survey_stage":1}')
	file.close()
	check(not restored.load_from(save_path) and restored.survey_complete(), "Invalid save rejected without partial mutation")
	DirAccess.remove_absolute(save_path)
	var world: Node3D = load("res://scenes/main.tscn").instantiate()
	root.add_child(world)
	await frames(3)
	var player: CharacterBody3D = world.player
	var menu: Control = world.hud.world_map
	var canvas: Control = menu.canvas
	check(not world.atlas.persist, "Automated map session does not write real progress")
	var key := InputEventKey.new()
	key.physical_keycode = KEY_M
	key.pressed = true
	player._unhandled_input(key)
	await frames()
	check(menu.visible and player.paused and not world.hud.pause_panel.visible, "M opens map and pauses without pause overlay")
	check(menu.quest_list.item_count == 51, "Quest journal displays the full outline")
	menu.quest_filter.select(1)
	menu.quest_filter.item_selected.emit(1)
	check(menu.quest_list.item_count == 13, "Primary-timeline filter shows thirteen chapters")
	check(menu.quest_action.disabled, "Planned main quest has no start action")
	menu.quest_filter.select(2)
	menu.quest_filter.item_selected.emit(2)
	check(menu.quest_list.item_count == 21, "Faction filter shows seven three-chapter arcs")
	var source := Vector2(445, 455)
	check(canvas.screen_to_map(canvas.map_to_screen(source)).distance_to(source) < 0.001, "Map coordinate transform round trips")
	canvas.zoom_at(2, canvas.size / 2)
	check(canvas.zoom == 2 and canvas.pan.length() < 0.01, "Center zoom preserves map center")
	canvas.zoom_at(20, canvas.size / 2)
	check(canvas.zoom == 4, "Zoom respects maximum")
	canvas.reset_view()
	canvas._pick(canvas.map_to_screen(source))
	check(menu.selected_id == "frostmere" and not menu.place_action.disabled, "Clicking playable marker opens its dossier")
	canvas._pick(canvas.map_to_screen(Vector2(901, 534)))
	check(menu.selected_id == "dunewell" and menu.place_action.disabled, "Clicking planned marker cannot trigger travel")
	menu.set_view(true)
	check(canvas.local_view and menu.selected_kind == "site", "Local-map button changes to playable survey")
	menu._selected("site", "hall")
	menu.place_action.pressed.emit()
	check(world.atlas.waypoint == "hall", "Local place action sets walking waypoint")
	menu.survey_action.pressed.emit()
	check(world.atlas.survey_started and world.atlas.waypoint == "forge", "Survey button starts actual local quest")
	check(not world.inspect_atlas_site("inspect_forge"), "Interaction cannot progress while map is open")
	key.physical_keycode = KEY_C
	player._unhandled_input(key)
	await frames()
	check(player.character_menu_open and not player.map_open and not menu.visible, "C switches from map to character screen without stacked overlays")
	key.physical_keycode = KEY_M
	player._unhandled_input(key)
	await frames()
	check(player.map_open and not player.character_menu_open, "M switches from character screen back to map")
	key.physical_keycode = KEY_ESCAPE
	player._unhandled_input(key)
	await frames()
	check(not player.paused and not player.map_open, "Escape closes map and resumes world")
	check(not world.inspect_atlas_site("inspect_forge"), "Remote forge interaction cannot advance quest")
	player.position = Vector3(-5.8, 0.15, -9)
	player.velocity = Vector3.ZERO
	Input.action_press("interact")
	await frames(3)
	Input.action_release("interact")
	check(world.atlas.survey_stage == 1, "Actual E action near forge advances survey")
	world.hud.workshop.close()
	player.position = Vector3(14, 0.75, -16)
	player.velocity = Vector3.ZERO
	await frames(3)
	check(world.atlas.survey_stage == 2, "Walking onto bridge advances the crossing objective")
	player.position = Vector3(31, 0.15, -31)
	player.velocity = Vector3.ZERO
	Input.action_press("interact")
	await frames(3)
	Input.action_release("interact")
	check(world.atlas.survey_complete(), "Actual relic inspection completes local quest")
	world.queue_free()
	await frames()
	print("ATLAS_COMPLETE checks=%d failures=%d" % [checks, failures])
	quit(1 if failures else 0)
