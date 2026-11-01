extends RefCounted
signal changed
const SAVE_PATH := "user://atlas-progress-v1.json"
var data: Dictionary
var regions: Dictionary = {}
var locations: Dictionary = {}
var factions: Dictionary = {}
var quests: Dictionary = {}
var sites: Dictionary = {}
var visits: Dictionary = {"trail": true}
var waypoint := ""
var survey_started := false
var survey_stage := 0
var persist := false
var save_error := false

func _init() -> void:
	data = JSON.parse_string(FileAccess.get_file_as_string("res://data/world_atlas.json"))
	for region: Dictionary in data.regions:
		regions[region.id] = region
	for location: Dictionary in data.locations:
		locations[location.id] = location
	for faction: Dictionary in data.factions:
		factions[faction.id] = faction
	for quest: Dictionary in data.quests:
		quests[quest.id] = quest
	for site: Dictionary in data.local_sites:
		sites[site.id] = site

func _commit() -> void:
	if persist:
		save_error = not save_to(SAVE_PATH)
	changed.emit()

func set_waypoint(id: String) -> bool:
	if id != "" and not sites.has(id):
		return false
	waypoint = id
	_commit()
	return true

func visit(id: String) -> void:
	if sites.has(id) and not visits.has(id):
		visits[id] = true
		_commit()

func start_quest(id: String) -> bool:
	if id != "oldwatch_survey" or survey_complete():
		return false
	survey_started = true
	waypoint = data.local_quest_steps[survey_stage].site
	_commit()
	return true

func survey_complete() -> bool:
	return survey_started and survey_stage == data.local_quest_steps.size()

func record_event(event: String) -> bool:
	if not survey_started or survey_complete() or data.local_quest_steps[survey_stage].event != event:
		return false
	survey_stage += 1
	waypoint = "" if survey_complete() else data.local_quest_steps[survey_stage].site
	_commit()
	return true

func objective_text() -> String:
	if survey_complete():
		return "The Oldwatch Survey — complete"
	if not survey_started:
		return ""
	return data.local_quest_steps[survey_stage].text

func target_position() -> Vector3:
	if waypoint == "":
		return Vector3.ZERO
	var position: Array = sites[waypoint].position
	if survey_started and not survey_complete() and waypoint == data.local_quest_steps[survey_stage].site:
		position = data.local_quest_steps[survey_stage].position
	return Vector3(position[0], position[1], position[2])

func quests_at(id: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for quest: Dictionary in data.quests:
		if quest.location == id:
			result.append(quest)
	return result

func save_to(path: String) -> bool:
	path = ProjectSettings.globalize_path(path)
	var file := FileAccess.open(path + ".tmp", FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify({"version": 1, "visits": visits, "waypoint": waypoint, "survey_started": survey_started, "survey_stage": survey_stage}, "\t"))
	file.close()
	return DirAccess.rename_absolute(path + ".tmp", path) == OK

func load_from(path: String) -> bool:
	if not FileAccess.file_exists(path):
		return false
	var parser := JSON.new()
	if parser.parse(FileAccess.get_file_as_string(path)) != OK or not parser.data is Dictionary:
		return false
	var value: Dictionary = parser.data
	if value.get("version") != 1 or not value.get("visits") is Dictionary or not value.get("waypoint") is String or not value.get("survey_started") is bool:
		return false
	var stage: Variant = value.get("survey_stage")
	if typeof(stage) not in [TYPE_INT, TYPE_FLOAT] or stage != floorf(stage) or stage < 0 or stage > data.local_quest_steps.size():
		return false
	if stage > 0 and not value.survey_started:
		return false
	if value.waypoint != "" and not sites.has(value.waypoint):
		return false
	for id: Variant in value.visits:
		if not sites.has(id) or value.visits[id] != true:
			return false
	visits = value.visits.duplicate()
	waypoint = value.waypoint
	survey_started = value.survey_started
	survey_stage = int(stage)
	changed.emit()
	return true

func waypoint_text() -> String:
	if waypoint == "":
		return ""
	if survey_started and not survey_complete() and waypoint == data.local_quest_steps[survey_stage].site:
		return objective_text()
	return sites[waypoint].name
