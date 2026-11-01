extends Node3D

const Town = preload("res://scripts/town_layout.gd")
const Terrain = preload("res://scripts/terrain_profile.gd")
const Blocks = preload("res://scripts/blocks.gd")
const Player = preload("res://scripts/player.gd")
const HUD = preload("res://scripts/hud.gd")
const Adventure = preload("res://scripts/adventure.gd")
const BuildingDetail = preload("res://scripts/refined_buildings.gd")
var building_records: Array=[]
const Shops = preload("res://scripts/shops.gd")
const Realms = preload("res://scripts/realms.gd")
const Stonewake = preload("res://scripts/stonewake.gd")
const Mountain = preload("res://scripts/mountain.gd")
const ArchiveChapter = preload("res://scripts/archive_chapter.gd")
var road_quests: Node3D
var hunts: Node3D
var wilderness: Node3D
var skills_menu: ColorRect
var session_save: Node
var combat_metrics: Node
var seal: Node3D
var winter: Node3D
var threshold: Node3D
var convergence: Node3D
var choir: Node3D
var roots: Node3D
var lens: Node3D
var shore: Node3D
var audio: Node
var archive_chapter: Node3D
var mountain: Node3D
var stonewake: Node3D
var realms: Node3D
var shops: Node3D
var adventure: Node3D
const AtlasState = preload("res://scripts/atlas_state.gd")
var atlas := AtlasState.new()

var blocks := Blocks.new()
var rng := RandomNumberGenerator.new()
var player: CharacterBody3D
var hud: CanvasLayer
var block_count := 0
var tree_sites: Array[Dictionary] = []
var landmarks: Array[Dictionary] = []
var discovered: Dictionary = {}
var elapsed := 0.0
var capture_done := false
var intro: Node3D
var gathering_props: Dictionary = {}
var step_paths: Dictionary = {}
var step_snow: Dictionary = {}
var frame_samples: Array[float] = []

func _ready() -> void:
	rng.seed = 4917
	_inputs()
	_environment()
	_terrain()
	_village()
	_forest()
	_mountains()
	_bridge()
	preload("res://scripts/refined_riverbank.gd").new().build(self)
	_ruins()
	block_count = blocks.finish(self)
	player = Player.new()
	add_child(player)
	audio = preload("res://scripts/audio_director.gd").new()
	audio.world = self
	add_child(audio)
	_crafting_props()
	atlas.persist = player.character.persist
	if atlas.persist:
		atlas.load_with_recovery(AtlasState.SAVE_PATH)
		if atlas.save_store.status == "blocked":
			atlas.persist=false; player.character.persist=false
	hud = HUD.new()
	hud.world = self
	add_child(hud)
	adventure = Adventure.new()
	adventure.world = self
	add_child(adventure)
	shops = Shops.new()
	shops.world = self
	add_child(shops)
	realms = Realms.new()
	realms.world = self
	add_child(realms)
	stonewake = Stonewake.new()
	stonewake.world = self
	add_child(stonewake)
	mountain = Mountain.new()
	mountain.world = self
	add_child(mountain)
	archive_chapter = ArchiveChapter.new()
	archive_chapter.world = self
	add_child(archive_chapter)
	shore=preload("res://scripts/shore.gd").new()
	shore.world=self
	add_child(shore)
	lens=preload("res://scripts/lens.gd").new()
	lens.world=self
	add_child(lens)
	roots=preload("res://scripts/roots.gd").new()
	roots.world=self
	add_child(roots)
	choir=preload("res://scripts/choir.gd").new()
	choir.world=self
	add_child(choir)
	convergence=preload("res://scripts/convergence.gd").new()
	convergence.world=self
	add_child(convergence)
	threshold=preload("res://scripts/threshold.gd").new()
	threshold.world=self
	add_child(threshold)
	winter=preload("res://scripts/winter.gd").new()
	winter.world=self
	add_child(winter)
	seal=preload("res://scripts/seal.gd").new()
	seal.world=self
	add_child(seal)
	realms.ending=preload("res://scripts/campaign_ending.gd").new()
	realms.ending.world=self
	realms.add_child(realms.ending)
	if ("--mountain-preview" in OS.get_cmdline_user_args() or "--archive-preview" in OS.get_cmdline_user_args() or "--shore-preview" in OS.get_cmdline_user_args() or "--lens-preview" in OS.get_cmdline_user_args() or "--roots-preview" in OS.get_cmdline_user_args() or "--choir-preview" in OS.get_cmdline_user_args() or "--convergence-preview" in OS.get_cmdline_user_args() or ("--threshold-preview" in OS.get_cmdline_user_args() or ("--winter-preview" in OS.get_cmdline_user_args() or "--seal-preview" in OS.get_cmdline_user_args()))) and not player.character.persist:
		adventure.accept_quest()
		adventure.mark_defeated("captain")
		adventure.loot_enemy("captain")
		adventure.reward_quest()
		for enemy: CharacterBody3D in adventure.enemies:
			if enemy.enemy_id == "captain":
				enemy.dead = true
				enemy._show_corpse()
				enemy._update_label()
		player.character.stonewake = {"accepted": true, "wards": ["hearth", "tide", "sky"], "awakened": true, "rewarded": false}
		stonewake.reward()
		player.character.consumables.healing_draught = 6
		player.character.materials.arrow = 40
		player.character.add_item("iron_bow")
		if "--shore-preview" in OS.get_cmdline_user_args() or "--lens-preview" in OS.get_cmdline_user_args():
			player.character.archive={"accepted":true,"heard":["lantern","briar"],"atlas":true,"recipient":"lantern","caches":[],"defeated":["archive_3"],"looted":[],"reputation":{"lantern":25,"briar":-10}}
			player.character.story_completed.append("archive")
			player.character.equip(player.character.add_item("steel_sword",2,"fleet"),"main_hand")
			player.character.consumables.healing_draught=12
			adventure.grant_materials({"steel_ingot":10,"leather":6,"crystal":6})
			if "--lens-preview" in OS.get_cmdline_user_args(): lens.enter()
			else: shore.enter()
		elif "--convergence-preview" in OS.get_cmdline_user_args() or ("--threshold-preview" in OS.get_cmdline_user_args() or ("--winter-preview" in OS.get_cmdline_user_args() or "--seal-preview" in OS.get_cmdline_user_args())):
			player.character.story_completed.append_array(["council","archive","roots","tides","lens","choir"])
			player.character.mountain={"accepted":true,"heard":["stoneguard","stormweaver"],"ledger":true,"settlement":"accord","clan":"","wards":[],"rank":0,"services":[],"reputation":{"stoneguard":10,"stormweaver":10},"defeated":["pass_0","pass_1","pass_2"],"looted":[]}
			player.character.archive={"accepted":true,"heard":["lantern","briar"],"atlas":true,"recipient":"lantern","caches":[],"defeated":["archive_3"],"looted":[],"reputation":{"lantern":25,"briar":-10}}
			player.character.lens={"accepted":true,"rotations":{"dawn":1,"dusk":3,"crown":0},"activated":true,"chart":true,"rewarded":true,"caches":[],"defeated":["lens_4"],"looted":[]}
			player.character.choir={"accepted":true,"song":["ember","ash","stone"],"activated":true,"record":true,"rewarded":true,"caches":[],"defeated":["choir_4"],"looted":[]}

			player.character.roots={"accepted":true,"heard":["keeper","steward"],"cleansed":["spring","stone","seed"],"choice":"wild","record":true,"rewarded":true,"caches":[],"defeated":["roots_0","roots_1","roots_2","roots_3"],"looted":[]}
			player.character.shore={"accepted":true,"heard":["harbor","salvager"],"relays":["pump","relay"],"caches":[],"identified":[],"log":true,"core":true,"choice":"harbor","rewarded":true,"defeated":["shore_6"],"looted":[]}
			player.character.equip(player.character.add_item("steel_sword",2,"fleet"),"main_hand")
			player.character.consumables.healing_draught=12
			if ("--threshold-preview" in OS.get_cmdline_user_args() or ("--winter-preview" in OS.get_cmdline_user_args() or "--seal-preview" in OS.get_cmdline_user_args())):
				player.character.convergence={"accepted":true,"evidence":["roots","tides","lens","choir"],"supplies":true,"installed":true,"calibrated":true,"rewarded":true,"defeated":["convergence_0","convergence_1","convergence_2"],"looted":[]}
				player.character.story_completed.append("convergence")
				if ("--winter-preview" in OS.get_cmdline_user_args() or "--seal-preview" in OS.get_cmdline_user_args()):
					player.character.story_completed.append_array(["threshold","returning_light"])
					player.character.threshold={"accepted":true,"locker":true,"cargo":true,"power":true,"air":true,"record":true,"rewarded":true,"defeated":["threshold_0","threshold_1","threshold_2","threshold_3","threshold_4","threshold_5"],"looted":[]}
					player.character.realm_progress.defeated.append("aeralis_regent")
					player.character.realm_progress.looted.append("aeralis_regent")
					player.character.realm_progress.completed.append("aeralis")
					realms.attune("aeralis")
					if "--seal-preview" in OS.get_cmdline_user_args():
						player.character.winter={"accepted":true,"supplies":true,"repairs":["ward","ballista"],"assault":true,"orders":true,"rewarded":true,"defeated":["winter_0","winter_1","winter_2","winter_3","winter_4","winter_5"],"looted":[]}
						player.character.story_completed.append("winter_siege")
						seal.enter()
					else: winter.enter()
				else: threshold.enter()
				for pair in [[winter,player.character.winter],[threshold,player.character.threshold],[realms,player.character.realm_progress],[mountain,player.character.mountain],[archive_chapter,player.character.archive],[shore,player.character.shore],[lens,player.character.lens],[roots,player.character.roots],[choir,player.character.choir],[convergence,player.character.convergence]]:
					for enemy in pair[0].enemies:
						enemy.progress=pair[1]
						if enemy.enemy_id in enemy.progress.defeated:
							enemy.dead=true; enemy._show_corpse(); enemy._update_label()

			else: convergence.enter()
		elif "--choir-preview" in OS.get_cmdline_user_args():
			player.character.mountain={"accepted":true,"heard":["stoneguard","stormweaver"],"ledger":true,"settlement":"accord","clan":"","wards":[],"rank":0,"services":[],"reputation":{"stoneguard":10,"stormweaver":10},"defeated":["pass_0","pass_1","pass_2"],"looted":[]}
			player.character.story_completed.append("council")
			player.character.equip(player.character.add_item("steel_sword",2,"fleet"),"main_hand")
			player.character.consumables.healing_draught=12
			choir.enter()
		elif "--roots-preview" in OS.get_cmdline_user_args():
			player.character.equip(player.character.add_item("steel_sword",2,"fleet"),"main_hand")
			player.character.consumables.healing_draught=12
			roots.enter()
		elif "--archive-preview" in OS.get_cmdline_user_args(): archive_chapter.enter()
		else: mountain.enter()
	if "--story-preview" in OS.get_cmdline_user_args() and not player.character.persist:
		adventure.accept_quest()
		adventure.mark_defeated("captain")
		for enemy: CharacterBody3D in adventure.enemies:
			if enemy.enemy_id == "captain":
				enemy.dead = true
				enemy._show_corpse()
				enemy._update_label()
		adventure.loot_enemy("captain")
		adventure.reward_quest()
		player.position = Stonewake.KEEPER + Vector3(0, 0.15, 1.6)
		player.rotation.y = 0
	if "--crystal-preview" in OS.get_cmdline_user_args() or "--hell-preview" in OS.get_cmdline_user_args():
		var destination := "crucible" if "--hell-preview" in OS.get_cmdline_user_args() else "aeralis"
		realms.enter(destination, true)
		realms.preview_kit(destination)
	if "--shops" in OS.get_cmdline_user_args():
		player.position = Vector3(-10, 0.3, -5.8)
		shops.open("outfitter")
	if "--dungeon" in OS.get_cmdline_user_args():
		if player._automated_render():
			adventure.accept_quest()
		adventure.enter()
	if "--adventure" in OS.get_cmdline_user_args():
		player.position = Adventure.SMITH + Vector3(1.5, 0.15, 0)
		adventure.open_dialog()
	if "--workshop" in OS.get_cmdline_user_args():
		player.position = Vector3(-4, 0.15, -11)
		hud.workshop.open("forge")
	if "--character-menu" in OS.get_cmdline_user_args():
		player.character_menu_open = true
		player.set_paused(true)
	if "--world-map" in OS.get_cmdline_user_args():
		player.map_open = true
		player.character_menu_open = false
		player.set_paused(true)
	if "--local-map" in OS.get_cmdline_user_args():
		player.map_open = true
		player.set_paused(true)
		hud.world_map.set_view(true)
	if "--first-person" in OS.get_cmdline_user_args():
		player.set_third_person(false)
	landmarks = [
		{"name": "Frostmere", "position": Vector3(0, 0, -8), "radius": 15.0, "detail": "A hearth at the edge of the wild."},
		{"name": "The Ember Hall", "position": Vector3(-1, 0, -36), "radius": 9.0, "detail": "Timber, stone, and the promise of shelter."},
		{"name": "Oldwatch Crossing", "position": Vector3(14, 0, -16), "radius": 6.0, "detail": "Beyond the river, the old road climbs."},
		{"name": "The Watcher's Stones", "position": Vector3(31, 0, -30), "radius": 8.0, "detail": "The ancient watchstone network listens."}
	]
	skills_menu=preload("res://scripts/skills_menu.gd").new(); skills_menu.world=self; hud.add_child(skills_menu)
	wilderness=preload("res://scripts/wilderness.gd").new(); wilderness.world=self; add_child(wilderness)
	hunts=preload("res://scripts/hunt_board.gd").new(); hunts.world=self; add_child(hunts)
	road_quests=preload("res://scripts/road_quests.gd").new(); road_quests.world=self; add_child(road_quests)
	session_save=preload("res://scripts/session_save.gd").new(); session_save.world=self; add_child(session_save)
	combat_metrics=preload("res://scripts/combat_metrics.gd").new(); combat_metrics.world=self; add_child(combat_metrics)
	intro=preload("res://scripts/dark_intro.gd").new(); intro.world=self; add_child(intro)
	preload("res://scripts/regional_landscape.gd").new().build(self)
	print("FROSTMERE_READY blocks=%d landmarks=%d" % [block_count, landmarks.size()])

func _inputs() -> void:
	var bindings := {"move_forward": KEY_W, "move_back": KEY_S, "move_left": KEY_A,
		"move_right": KEY_D, "jump": KEY_SPACE, "sprint": KEY_SHIFT,
		"camera_toggle": KEY_V, "pause": KEY_ESCAPE, "respawn": KEY_R,
		"cycle_spell": KEY_B, "spell": KEY_Q, "heal": KEY_F, "inventory": KEY_I, "interact": KEY_E, "character": KEY_C, "world_map": KEY_M, "help": KEY_H, "performance": KEY_F3}
	for action: String in bindings:
		if not InputMap.has_action(action): InputMap.add_action(action)
		var event := InputEventKey.new()
		event.physical_keycode = bindings[action]
		if not InputMap.action_has_event(action, event): InputMap.action_add_event(action, event)

	for action in ["attack", "block"]:
		if not InputMap.has_action(action): InputMap.add_action(action)
		var mouse := InputEventMouseButton.new()
		mouse.button_index = MOUSE_BUTTON_LEFT if action == "attack" else MOUSE_BUTTON_RIGHT
		if not InputMap.action_has_event(action, mouse): InputMap.action_add_event(action, mouse)

func _environment() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	var sky_material := ProceduralSkyMaterial.new()
	sky_material.sky_top_color = Color("527991")
	sky_material.sky_horizon_color = Color("c7d4d4")
	sky_material.ground_bottom_color = Color("40515a")
	sky_material.ground_horizon_color = Color("a7babe")
	sky_material.sky_curve = 0.65
	sky.sky_material = sky_material
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("bacbd3")
	env.ambient_light_energy = 0.38
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.fog_enabled = true
	env.fog_light_color = Color("b4c5cf")
	env.fog_density = 0.0018
	var environment := WorldEnvironment.new()
	environment.environment = env
	add_child(environment)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-38, -38, 0)
	sun.light_color = Color("ffe2b1")
	sun.light_energy = 1.0
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 100
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS
	add_child(sun)

func _solid(center: Vector3, size: Vector3, surface: String="stone") -> void:
	var body := StaticBody3D.new()
	body.position = center
	body.set_meta("footstep",surface)
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	collision.shape = shape
	body.add_child(collision)
	add_child(body)

func _terrain() -> void:
	# Broad collision slabs keep navigation stable; decorative top blocks remain batched.
	_solid(Vector3(-31, -1.1, -30), Vector3(82, 2, 140),"terrain")
	_solid(Vector3(47, -1.1, -30), Vector3(58, 2, 140),"terrain")
	_solid(Vector3(14, -2.3, -30), Vector3(8, 1, 140))
	var slopes := StaticBody3D.new(); slopes.name = "WildernessSlopes"; slopes.set_meta("footstep","terrain")
	var shape := ConcavePolygonShape3D.new(); shape.set_faces(Terrain.collision_vertices())
	var collider := CollisionShape3D.new(); collider.shape = shape; slopes.add_child(collider); add_child(slopes)
	# One-metre voxel columns preserve the block silhouette above walkable slopes.
	for x in range(-70, 76):
		for z in range(-100, 40):
			if x >= 10 and x < 18:
				continue
			var path: bool = Town.path_at(x+0.5,z+0.5) or (absf(z + 16.5) < 2.5 and x > -3 and x < 35) or (absf(x - 30.5) < 2.5 and z < -15 and z > -34)
			var rise := Terrain.height_at(x+0.5,z+0.5)
			path = path or Terrain.path_at(x+0.5,z+0.5)
			if path: step_paths[Vector2i(x,z)]=true
			if rise > 0.01: blocks.add("earth", Vector3(x+0.5,rise/2.0-0.23,z+0.5),Vector3(1,rise+0.25,1))
			blocks.add("earth" if path else "grass", Vector3(x + 0.5, rise-0.22, z + 0.5), Vector3(1, 0.25, 1))
			if x == 9 or x == 18:
				blocks.add("earth", Vector3(x + 0.5, -1.0, z + 0.5), Vector3(1, 1.4, 1))
			if not path and rng.randf() < 0.12:
				for patch in range(3):
					var depth:=rng.randf_range(0.25,0.65)
					blocks.add("snow", Vector3(x + 0.25 + patch * 0.22, rise-0.06, z + 0.5), Vector3(0.3, 0.05, depth))
					var cell:=Vector2i(x,z)
					if not step_snow.has(cell): step_snow[cell]=[]
					step_snow[cell].append(Rect2(x+.10+patch*.22,z+.5-depth/2,.3,depth))
			if path:
				# Close-set small cobbles replace giant flat checkerboard path tiles.
				for row in range(3):
					for col in range(3):
						var p := Vector3(x + 0.16 + col * 0.33, rise-0.08, z + 0.16 + row * 0.33)
						p.x += rng.randf_range(-0.025, 0.025)
						blocks.add("path" if rng.randf() > 0.3 else "stone", p, Vector3(rng.randf_range(0.27, 0.31), rng.randf_range(0.04, 0.07), rng.randf_range(0.26, 0.31)))
			elif abs(x) < 34 and z > -60 and rng.randf() < 0.3:
				for blade in range(3):
					blocks.add("grass_dark", Vector3(x + rng.randf(), rise-0.02, z + rng.randf()), Vector3(0.055, rng.randf_range(0.10, 0.22), 0.055))
	var water := MeshInstance3D.new()
	water.name = "River"
	var mesh := PlaneMesh.new()
	mesh.size = Vector2(7.8, 140)
	water.mesh = mesh
	water.position = Vector3(14, -0.55, -30)
	var shader := Shader.new()
	shader.code = """
shader_type spatial;
render_mode cull_disabled;
void fragment() {
    vec2 p = UV * vec2(7.8, 140.0);
    float drift = p.y * 9.0 + TIME * 1.1;
    float ripples = smoothstep(0.76, 0.98, sin(drift + sin(p.x * 6.0 + p.y * 0.7)));
    float broken = smoothstep(-0.25, 0.65, sin(p.x * 8.0 - p.y * 2.3 + TIME * 0.4));
    float current = sin(p.x * 2.7 + p.y * 0.35 + TIME * 0.18) * 0.025;
    ALBEDO = mix(vec3(0.105, 0.255, 0.30), vec3(0.25, 0.43, 0.46), ripples * broken * 0.32) + current;
    ROUGHNESS = 0.32 + ripples * 0.04;
    METALLIC = 0.12;
}
"""
	var water_material := ShaderMaterial.new()
	water_material.shader = shader
	water.material_override = water_material
	add_child(water)
	# Shore boulders; keep the bridge approach clear.
	for z in range(-85, 35, 3):
		if abs(z + 16) < 6:
			continue
		for x in [9.0, 19.0]:
			var height := rng.randf_range(0.3, 0.85)
			# Preserve the original RNG stream for later forest placement.
			if z>=-11 and z<=11: continue
			for row in range(3):
				for col in range(4):
					var h := height * (1.0 - absf(col - 1.5) * 0.2 - absf(row - 1.0) * 0.12)
					var p := Vector3(x + (col - 1.5) * 0.3, h / 2 - 0.2, z + (row - 1) * 0.4)
					blocks.add("stone_dark" if col % 2 else "stone", p, Vector3(0.3, h, 0.4))
					if row == 1:
						blocks.add("snow", p + Vector3(0, h / 2 + 0.01, 0), Vector3(0.28, 0.04, 0.38))
	# Contain the small prototype with stepped rocky foothills.
	for z in range(-70, 36, 4):
		for x in [-38.0, 46.0]:
			var height := rng.randf_range(2.0, 5.0)
			blocks.add("stone_dark", Vector3(x, height / 2.0 - 0.1, z), Vector3(5, height, 4))
			blocks.add("snow", Vector3(x, height, z), Vector3(4.8, 0.18, 3.9))
			_solid(Vector3(x, height / 2.0, z), Vector3(5, height, 4))

func _village() -> void:
	_house(Vector3(-10, 0, -8), 8, 9, 4.0, false, "outfitter")
	_house(Town.HOMES[0], 7, 9, 4.2, false, "runesmith")
	_house(Town.HOMES[1], 6, 6, 3.5, false, "weaver")
	_house(Town.HOMES[2], 4, 5, 3.2, false, "cottage")
	Town.new().build(self)
	_house(Vector3(1, 0, -45), 11, 13, 5.0, true, "ember_hall")
	_house(Vector3(6, 0, 6), 5, 6, 3.1, false, "apothecary")
	preload("res://scripts/refined_outfitter.gd").new().build(self)
	for position in [Vector3(-3, 0, 12), Vector3(4, 0, -8), Vector3(-3, 0, -27), Vector3(7, 0, -35), Vector3(22, 0, -16)]:
		_lantern(position)
	for i in range(7):
		var p := Vector3(-5.8, 0.36, 2.5 + i * 0.62)
		blocks.add("timber", p, Vector3(0.16, 1.4, 0.16))
	blocks.add("wood", Vector3(-5.8, 0.63, 4.3), Vector3(0.13, 0.16, 4.5))
	blocks.add("wood", Vector3(-5.8, 0.14, 4.3), Vector3(0.13, 0.16, 4.5))
	_solid(Vector3(-5.8, 0.5, 4.3), Vector3(0.25, 1.2, 4.5))
	# The village forge and tempering anvil.
	blocks.add("stone_dark", Vector3(-5.8, 0.4, -11), Vector3(1.5, 0.9, 1.5))
	blocks.add("coal", Vector3(-5.8, 0.89, -11), Vector3(1.25, 0.08, 1.25))
	for i in range(8):
		blocks.add("window", Vector3(-5.8 + rng.randf_range(-0.4, 0.4), 0.97, -11 + rng.randf_range(-0.4, 0.4)), Vector3(0.18, 0.12, 0.18))
	blocks.add("timber", Vector3(-5.6, 0.30, -13), Vector3(0.6, 0.7, 0.6))
	blocks.add("iron", Vector3(-5.6, 0.8, -13), Vector3(0.9, 0.28, 0.38))
	_solid(Vector3(-5.8, 0.5, -11), Vector3(1.5, 1, 1.5))
	_sign(Vector3(3.5, 0, 11.0))

func _house(origin: Vector3, width: float, depth: float, height: float, grand: bool, identity: String) -> void:
	BuildingDetail.new().build(self,origin,width,depth,height,grand,identity)

func _warm_light(p: Vector3, radius: float, energy: float) -> void:
	var light := OmniLight3D.new()
	light.position = p
	light.light_color = Color("ffb461")
	light.light_energy = energy
	light.omni_range = radius
	add_child(light)

func _lantern(p: Vector3, post: bool = true) -> void:
	if post:
		blocks.add("timber", p + Vector3(0, 1.65, 0), Vector3(0.20, 3.3, 0.20))
		blocks.add("timber", p + Vector3(0.34, 3.2, 0), Vector3(0.85, 0.17, 0.17))
		_solid(p + Vector3(0, 1.5, 0), Vector3(0.24, 3.0, 0.24))
	var point := p + Vector3(0.55 if post else 0.0, 2.65 if post else 2.0, 0)
	blocks.add("window", point, Vector3(0.26, 0.4, 0.26))
	for y in [-0.24, 0.24]:
		blocks.add("iron", point + Vector3(0, y, 0), Vector3(0.38, 0.09, 0.38))
	for x in [-0.16, 0.16]:
		for z in [-0.16, 0.16]:
			blocks.add("iron", point + Vector3(x, 0, z), Vector3(0.045, 0.44, 0.045))
	_warm_light(point, 4.0, 1.6)

func _sign(p: Vector3) -> void:
	blocks.add("timber", p + Vector3(0, 1.2, 0), Vector3(0.18, 2.4, 0.18))
	blocks.add("wood", p + Vector3(0, 1.95, 0), Vector3(2.0, 0.55, 0.14))
	var label := Label3D.new()
	label.text = "F R O S T M E R E"
	label.font_size = 38
	label.pixel_size = 0.002
	label.position = p + Vector3(0, 1.95, 0.085)
	label.modulate = Color("e6d5ac")
	label.outline_size = 0
	add_child(label)

func _tree(p: Vector3, height: float) -> void:
	if Vector2(p.x-34,p.z-18).length()<12: return
	# Check actual jittered trunk positions, including the flat approaches to hill paths.
	for hill: Vector4 in Terrain.HILLS:
		if absf(p.z-hill.y)<hill.w+3 and absf(p.x-hill.x-sin((p.z-hill.y)*.25)*1.8)<2.5: return
	p.y += Terrain.height_at(p.x,p.z)
	tree_sites.append({"position": p, "height": height})
	blocks.add("timber", p + Vector3(0, height * 0.45, 0), Vector3(0.36, height * 0.9, 0.36))
	_solid(p + Vector3(0, 1.8, 0), Vector3(0.55, 3.6, 0.55))
	for root_index in range(4):
		var angle := root_index * PI / 2
		blocks.add("timber", p + Vector3(cos(angle) * 0.24, 0.12, sin(angle) * 0.24), Vector3(0.22, 0.3, 0.22))
	var levels := int(height / 0.325)
	for level in range(levels):
		var y := 1.3 + level * 0.325
		var fraction := 1.0 - float(level) / levels
		var radius := fraction * height * 0.25 + 0.10
		blocks.add("pine", p + Vector3(0, y, 0), Vector3(maxf(0.2, radius * 0.65), 0.38, maxf(0.2, radius * 0.65)))
		for branch_index in range(6):
			var angle := branch_index * TAU / 6 + (level % 2) * 0.4
			var reach := radius * rng.randf_range(0.8, 1.12)
			for segment in range(maxi(1, int(reach / 0.25))):
				var distance := segment * 0.25
				var cluster := p + Vector3(cos(angle) * distance, y - distance * 0.17, sin(angle) * distance)
				var size := maxf(0.18, 0.38 - distance * 0.065)
				blocks.add("pine_light" if (branch_index + level) % 5 == 0 else "pine", cluster, Vector3(size, 0.25, size))
				if level % 5 == 0 and rng.randf() < 0.45:
					blocks.add("snow", cluster + Vector3(0, 0.14, 0), Vector3(size * 0.9, 0.045, size * 0.85))
	blocks.add("pine_light", p + Vector3(0, 1.3 + levels * 0.325, 0), Vector3(0.16, 0.30, 0.16))

func _forest() -> void:
	for x in range(-32, 44, 5):
		for z in range(-72, 31, 5):
			if Town.clearing(x,z): continue
			if x > -19 and x < 9 and z < 16 and z > -58:
				continue
			if x > 7 and x < 22:
				continue
			if x > 20 and (abs(z + 16) < 5 or (x > 24 and x < 38 and z < -20 and z > -40)):
				continue
			if abs(x) < 5 or rng.randf() < 0.32:
				continue
			if Terrain.path_at(x,z) or Terrain.path_at(x-2,z) or Terrain.path_at(x+2,z): continue
			var habitat_clear := false
			for site: Vector3 in preload("res://scripts/wilderness.gd").SITES:
				if Vector2(x-site.x,z-site.z).length()<5: habitat_clear=true
			if habitat_clear: continue
			_tree(Vector3(x + rng.randf_range(-1, 1), 0, z + rng.randf_range(-1, 1)), rng.randf_range(5.5, 10.5))
	for i in range(260):
		var p := Vector3(rng.randf_range(-33, 43), 0.08, rng.randf_range(-68, 30))
		if (p.x > 8 and p.x < 20) or absf(p.x) < 3 or absf(p.z + 16) < 3:
			continue
		if p.x > -16 and p.x < 8 and p.z < 11:
			continue
		p.y += Terrain.height_at(p.x,p.z)
		blocks.add("grass_dark", p, Vector3(0.2, rng.randf_range(0.18, 0.45), 0.2))
		if i % 6 == 0:
			blocks.add("stone", p, Vector3(0.8, 0.4, 0.65))

func _mountains() -> void:
	for peak in [Vector3(-58, 50, -100), Vector3(-24, 65, -126), Vector3(28, 57, -124), Vector3(65, 75, -137), Vector3(-88, 48, -44), Vector3(97, 54, -66)]:
		for gx in range(-24, 25):
			for gz in range(-20, 21):
				var dx := gx * 1.5
				var dz := gz * 1.5
				var distance := Vector2(dx, dz * 1.15).length()
				var ridge := sin(dx * 0.22 + peak.x) * 3.5 + cos(dz * 0.26) * 3.0 + sin((dx + dz) * 0.53) * 1.8
				var height: float = floorf(maxf(0.0, peak.y * (1.0 - distance / 43.0) + ridge) / 0.75) * 0.75
				if height < 1:
					continue
				var p := Vector3(peak.x + dx, height / 2.0 - 1, peak.z + dz)
				blocks.add("stone" if height > peak.y * 0.38 else "stone_dark", p, Vector3(1.51, height, 1.51))
				if height > peak.y * 0.42 + sin(dx * 0.3) * 4:
					blocks.add("snow", Vector3(p.x, height - 0.8, p.z), Vector3(1.51, 0.25, 1.51))
	# Distant fortress silhouette, deliberately distinct from the explorable ruins.
	for x in [-10.0, 1.0, 12.0]:
		blocks.add("stone_dark", Vector3(x, 17, -88), Vector3(5, 26, 5))
		for dx in [-2.0, 0.0, 2.0]:
			for dz in [-2.0, 2.0]:
				blocks.add("stone", Vector3(x + dx, 31, -88 + dz), Vector3(1.1, 2.0, 1.1))
	blocks.add("stone_dark", Vector3(1, 14, -88), Vector3(25, 12, 3))
	for tier in range(9):
		blocks.add("stone_dark", Vector3(1, tier * 0.8, -88), Vector3(44 - tier * 2.4, 1.0, 25 - tier))

	# Readable stone courses and window recesses on the distant fortress as well.
	for x in [-10.0, 1.0, 12.0]:
		for row in range(32):
			for col in range(6):
				var offset := -2.1 + col * 0.84
				for side in [-1, 1]:
					blocks.add("stone" if (row + col) % 4 else "stone_dark", Vector3(x + offset, 4.4 + row * 0.8, -88 + side * 2.54), Vector3(0.80, 0.76, 0.16))
					blocks.add("stone", Vector3(x + side * 2.54, 4.4 + row * 0.8, -88 + offset), Vector3(0.16, 0.76, 0.80))
		for y in [12, 20, 28]:
			blocks.add("stone", Vector3(x, y, -88), Vector3(5.5, 0.3, 5.5))
			blocks.add("coal", Vector3(x, y - 2, -85.34), Vector3(0.52, 1.8, 0.04))
			for side in [-1, 1]:
				blocks.add("stone_dark", Vector3(x + side * 0.4, y - 2, -85.26), Vector3(0.22, 2.1, 0.22))
		blocks.add("snow", Vector3(x, 30.15, -88), Vector3(4.7, 0.2, 4.7))

	preload("res://scripts/landmark_architecture.gd").fortress(blocks)

func _bridge() -> void:
	# Broad, gently stepped deck has <= 0.12 m risers so movement needs no stair special case.
	for i in range(48):
		var x := 8.0 + i * 0.25
		var y := -0.1 + (1.0 - absf(x - 14.0) / 6.0) * 0.85
		for tile in range(11):
			blocks.add("stone", Vector3(x, y - 0.1, -18 + tile * 0.4), Vector3(0.25, 0.2, 0.39))
		for z in [-18.2, -13.8]:
			for row in range(4):
				blocks.add("stone_dark" if (row + i) % 3 else "stone", Vector3(x, y + 0.10 + row * 0.175, z), Vector3(0.24, 0.165, 0.4))
			blocks.add("stone", Vector3(x, y + 0.75, z), Vector3(0.26, 0.09, 0.49))
	# Smooth invisible ramp collision overlays shallow decorative stair increments.
	for side in [-1.0, 1.0]:
		var body := StaticBody3D.new()
		body.position = Vector3(14 + side * 3, 0.245, -16)
		body.rotation.z = -side * atan(0.85 / 6.0)
		var collision := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = Vector3(6.1, 0.16, 4.3)
		collision.shape = shape
		body.add_child(collision)
		add_child(body)
	for z in [-18.2, -13.8]:
		_solid(Vector3(14, 0.70, z), Vector3(12, 1.4, 0.4))
	for x in [10.0, 18.0]:
		blocks.add("stone_dark", Vector3(x, -0.65, -16), Vector3(1.3, 2.2, 4.5))

func _ruins() -> void:
	for x in [27.0, 35.0]:
		for z in [-28.0, -36.0]:
			var height := 5.8 if z == -28 else 4.2
			for level in range(int(height / 0.5)):
				blocks.add("stone", Vector3(x, level * 0.5 + 0.25, z), Vector3(1.3 if level % 3 else 1.5, 0.49, 1.3))
			_solid(Vector3(x, height / 2, z), Vector3(1.4, height, 1.4))
	blocks.add("stone_dark", Vector3(31, 5.5, -28), Vector3(8, 1, 1.4))
	blocks.add("stone", Vector3(31, 6.1, -28), Vector3(5.7, 0.3, 1.6))
	for i in range(9):
		blocks.add("stone_dark", Vector3(26 + i, 0.15, -38), Vector3(0.85, rng.randf_range(0.3, 1.7), 1.0))
	blocks.add("stone_dark", Vector3(31, 0.5, -33), Vector3(1.5, 1, 1.5))
	blocks.add("iron", Vector3(31, 1.08, -33), Vector3(1.7, 0.16, 1.7))
	_solid(Vector3(31, 0.6, -33), Vector3(1.7, 1.2, 1.7))
	blocks.add("gold", Vector3(31, 1.35, -33), Vector3(0.25, 0.4, 0.25))

func _process(delta: float) -> void:
	elapsed += delta
	if not is_instance_valid(player):
		return
	if not player.paused:
		update_atlas_progress()
	for landmark in landmarks:
		if not discovered.has(landmark.name) and player.position.distance_to(landmark.position) < landmark.radius:
			discovered[landmark.name] = true
			hud.announce(landmark.name, landmark.detail)
	if Input.is_action_just_pressed("interact") and not player.paused:
		interact_nearby()
	# Automated render mode produces a reproducible screenshot of our own app.
	if "--benchmark" in OS.get_cmdline_user_args():
		if elapsed > 2.0:
			frame_samples.append(delta * 1000.0)
		if elapsed > 10.0:
			frame_samples.sort()
			var report := "GPU: %s\nRenderer: Mobile / Metal\nViewport: %s\nBlocks: %d\nStationary spawn sample after 2 s warmup: %d frames\nMedian frame: %.2f ms\np95 frame: %.2f ms\nThis is a development-build sample on this machine, not an M1 benchmark.\n" % [RenderingServer.get_video_adapter_name(), get_viewport().size, block_count, frame_samples.size(), frame_samples[frame_samples.size() / 2], frame_samples[int(frame_samples.size() * 0.95)]]
			DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://build"))
			var output := FileAccess.open("res://build/performance.txt", FileAccess.WRITE)
			output.store_string(report)
			print(report)
			get_tree().quit()
	if "--capture" in OS.get_cmdline_user_args() and elapsed > 3.0 and not capture_done:
		capture_done = true
		_capture()

func _capture() -> void:
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	if "--package-smoke" in OS.get_cmdline_user_args():
		preload("res://scripts/package_smoke.gd").capture(self, image)
		return
	var filename := "aeralis-preview.png" if "--crystal-preview" in OS.get_cmdline_user_args() else "crucible-preview.png" if "--hell-preview" in OS.get_cmdline_user_args() else "oldwatch-dungeon.png" if "--dungeon" in OS.get_cmdline_user_args() else "workshop.png" if "--workshop" in OS.get_cmdline_user_args() else "world-map.png" if "--world-map" in OS.get_cmdline_user_args() else "local-map.png" if "--local-map" in OS.get_cmdline_user_args() else "character-armory.png" if "--character-menu" in OS.get_cmdline_user_args() else "first-person-gear.png" if "--first-person" in OS.get_cmdline_user_args() else "frostmere-preview.png"
	var path := ProjectSettings.globalize_path("res://build/" + filename)
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	image.save_png(path)
	print("CAPTURE_SAVED " + path)
	if "--benchmark" not in OS.get_cmdline_user_args():
		get_tree().quit()

func update_atlas_progress() -> void:
	for site: Dictionary in atlas.data.local_sites:
		var p: Array = site.position
		if player.position.distance_to(Vector3(p[0], p[1], p[2])) < 5.0:
			atlas.visit(site.id)
	if player.position.distance_to(Vector3(14, 0, -16)) < 4.0:
		if atlas.record_event("reach_crossing"):
			hud.announce("Crossing surveyed", atlas.objective_text())

func inspect_atlas_site(event: String) -> bool:
	if player.paused:
		return false
	var position := Vector3(-5.8, 0, -11) if event == "inspect_forge" else Vector3(31, 0, -33)
	if event not in ["inspect_forge", "inspect_relic"] or player.position.distance_to(position) >= 3.0:
		return false
	return atlas.record_event(event)

func station_nearby() -> String:
	if is_instance_valid(seal) and seal.inside: return seal.station_nearby()
	if is_instance_valid(winter) and winter.inside: return winter.station_nearby()
	if is_instance_valid(threshold) and threshold.inside: return threshold.station_nearby()
	if is_instance_valid(convergence) and convergence.inside: return convergence.station_nearby()
	if is_instance_valid(choir) and choir.inside: return choir.station_nearby()
	if is_instance_valid(roots) and roots.inside: return roots.station_nearby()
	if is_instance_valid(lens) and lens.inside: return lens.station_nearby()
	if is_instance_valid(shore) and shore.inside: return shore.station_nearby()
	if is_instance_valid(archive_chapter) and archive_chapter.inside: return archive_chapter.station_nearby()
	if is_instance_valid(mountain) and mountain.inside: return mountain.station_nearby()
	if is_instance_valid(realms) and realms.inside: return realms.station_nearby()
	for entry: Dictionary in player.character.crafting.stations:
		var p: Array = entry.position
		if player.position.distance_to(Vector3(p[0], p[1], p[2])) < 3.0:
			return entry.id
	return ""

func nearest_interaction() -> Dictionary:
	if is_instance_valid(seal):
		var foundry: Dictionary=seal.nearest()
		if not foundry.is_empty(): return foundry
	if is_instance_valid(winter):
		var siege: Dictionary=winter.nearest()
		if not siege.is_empty(): return siege
	if is_instance_valid(threshold):
		var crossing: Dictionary=threshold.nearest()
		if not crossing.is_empty(): return crossing
	if is_instance_valid(convergence):
		var expedition: Dictionary=convergence.nearest()
		if not expedition.is_empty(): return expedition
	if is_instance_valid(choir):
		var caldera: Dictionary=choir.nearest()
		if not caldera.is_empty(): return caldera
	if is_instance_valid(roots):
		var grove: Dictionary=roots.nearest()
		if not grove.is_empty(): return grove
	if is_instance_valid(lens):
		var observatory: Dictionary=lens.nearest()
		if not observatory.is_empty(): return observatory
	if is_instance_valid(shore):
		var coast: Dictionary=shore.nearest()
		if not coast.is_empty(): return coast
	if is_instance_valid(archive_chapter):
		var forest: Dictionary = archive_chapter.nearest()
		if not forest.is_empty(): return forest
	if is_instance_valid(mountain):
		var town: Dictionary = mountain.nearest()
		if not town.is_empty(): return town
	if is_instance_valid(stonewake):
		var story: Dictionary = stonewake.nearest()
		if not story.is_empty(): return story
	if is_instance_valid(realms):
		var portal: Dictionary = realms.nearest()
		if not portal.is_empty(): return portal
	if is_instance_valid(shops):
		var shop: String = shops.nearby()
		if shop != "":
			return {"kind": "shop", "id": shop, "text": "[ E ] Trade at " + shops.trade.shop(shop).name}
	if is_instance_valid(adventure):
		var extra: Dictionary = adventure.nearest()
		if not extra.is_empty():
			return extra
	var nearest := {}
	var distance := 3.0
	for group: String in ["stations", "nodes"]:
		for entry: Dictionary in player.character.crafting[group]:
			var p: Array = entry.position
			var d := player.position.distance_to(Vector3(p[0], p[1], p[2]))
			if d < distance:
				distance = d
				nearest = {"kind": group, "entry": entry}
	if player.position.distance_to(Vector3(31, 0, -33)) < distance:
		return {"kind": "relic"}
	return nearest

func interaction_prompt() -> String:
	if is_instance_valid(intro) and intro.active: return intro.prompt()
	if is_instance_valid(road_quests) and road_quests.nearby()!="": return "[ E ] "+road_quests.catalog.sites[road_quests.nearby()].name
	if is_instance_valid(hunts) and hunts.lodge_nearby()!="": return "[ E ] Investigate Lodge site"
	if is_instance_valid(hunts) and hunts.nearby(): return "[ E ] Read Hunters’ Board"
	if is_instance_valid(wilderness) and wilderness.nearby_loot() != null: return "[ E ] Harvest " + wilderness.nearby_loot().title
	var target := nearest_interaction()
	if target.is_empty():
		return ""
	if target.kind in ["adventure", "shop", "realm", "story", "mountain", "archive", "shore", "lens", "roots", "choir", "convergence", "threshold", "winter", "seal"]:
		return target.text
	if target.kind == "relic":
		return "[ E ] Examine relic"
	var entry: Dictionary = target.entry
	if target.kind == "nodes" and player.character.claims.has(entry.id):
		if not entry.has("cooldown"):
			return entry.name + " — emptied"
		var remaining := ceili(float(player.character.claims[entry.id]) + float(entry.cooldown) - Time.get_unix_time_from_system())
		if remaining > 0:
			return "%s — replenishes in %ds" % [entry.name, remaining]
	return "[ E ] %s %s" % ["Use" if target.kind == "stations" else "Gather", entry.name]

func interact_nearby() -> void:
	if is_instance_valid(intro) and intro.active:
		intro.interact()
		return
	if not player.paused and is_instance_valid(road_quests) and road_quests.nearby()!="": road_quests.open(); return
	if not player.paused and is_instance_valid(hunts) and hunts.lodge_nearby()!="": hunts.open_lodge(); return
	if not player.paused and is_instance_valid(hunts) and hunts.nearby(): hunts.open(); return
	if is_instance_valid(wilderness) and wilderness.loot(): return
	if player.paused:
		return
	var target := nearest_interaction()
	if target.is_empty():
		return
	audio.sfx("interact")
	if target.kind == "seal":
		seal.interact(target.id)
	elif target.kind == "winter":
		winter.interact(target.id)
	elif target.kind == "threshold":
		threshold.interact(target.id)
	elif target.kind == "convergence":
		convergence.interact(target.id)
	elif target.kind == "choir":
		choir.interact(target.id)
	elif target.kind == "roots":
		roots.interact(target.id)
	elif target.kind == "lens":
		lens.interact(target.id)
	elif target.kind == "shore":
		shore.interact(target.id)
	elif target.kind == "archive":
		archive_chapter.interact(target.id)
	elif target.kind == "mountain":
		mountain.interact(target.id)
	elif target.kind == "story":
		stonewake.interact(target.id)
	elif target.kind == "realm":
		realms.interact(target.id)
	elif target.kind == "shop":
		shops.open(target.id)
	elif target.kind == "adventure":
		adventure.interact(target.id)
	elif target.kind == "relic":
		inspect_atlas_site("inspect_relic")
		hud.announce("A fragment of the old world", "Oldwatch survey complete." if atlas.survey_complete() else "An ancient relic overlooks the crossing.")
	elif target.kind == "stations":
		if target.entry.id == "forge":
			inspect_atlas_site("inspect_forge")
		hud.workshop.open(target.entry.id)
	else:
		var message: String = player.character.gather(target.entry.id, Time.get_unix_time_from_system())
		audio.sfx("gather" if message.begins_with("Collected") else "error")
		hud.announce(target.entry.name, message)
		_refresh_gathering_props()

func _crafting_props() -> void:
	for entry: Dictionary in player.character.crafting.stations:
		var p: Array = entry.position
		var origin := Vector3(p[0], p[1], p[2])
		if entry.id != "forge":
			var prop := Node3D.new()
			prop.position = origin
			add_child(prop)
			blocks.piece(prop, "wood", Vector3(0, 0.85, 0), Vector3(1.5, 0.2, 0.8))
			for x in [-0.55, 0.55]:
				blocks.piece(prop, "timber", Vector3(x, 0.4, 0), Vector3(0.16, 0.8, 0.6))
			if entry.id == "enchant":
				blocks.piece(prop, "cloth", Vector3(0, 0.97, 0), Vector3(1.25, 0.04, 0.72))
				for x in [-0.45, 0, 0.45]:
					blocks.piece(prop, "window", Vector3(x, 1.12, 0), Vector3(0.12, 0.3, 0.12))
			elif entry.id == "alchemy":
				for x in [-0.45, 0, 0.45]:
					blocks.piece(prop, "pine_light", Vector3(x, 1.1, 0), Vector3(0.22, 0.3, 0.22))
					blocks.piece(prop, "gold", Vector3(x, 1.3, 0), Vector3(0.1, 0.1, 0.1))
			else:
				blocks.piece(prop, "coal", Vector3(0, 1.06, 0), Vector3(0.7, 0.22, 0.6))
				blocks.piece(prop, "window", Vector3(0, 1.18, 0), Vector3(0.5, 0.04, 0.4))
			_solid(origin + Vector3(0, 0.45, 0), Vector3(1.5, 0.9, 0.8))
		_craft_sign(origin, entry.name, Color("d9c69a"))
	for entry: Dictionary in player.character.crafting.nodes:
		var p: Array = entry.position
		var prop := Node3D.new()
		prop.position = Vector3(p[0], p[1], p[2])
		add_child(prop)
		gathering_props[entry.id] = prop
		if entry.kind in ["ore", "crystal"]:
			for i in range(5):
				blocks.piece(prop, "stone" if entry.kind == "ore" else "cloth", Vector3((i % 3 - 1) * 0.3, 0.15 + i * 0.08, (i / 3) * 0.25), Vector3(0.4, 0.35 + i * 0.08, 0.4))
				blocks.piece(prop, "gold" if entry.kind == "ore" else "window", Vector3((i % 3 - 1) * 0.3, 0.35 + i * 0.13, (i / 3) * 0.25), Vector3(0.13, 0.13, 0.13))
		elif entry.kind in ["herb", "mushroom"]:
			for i in range(6):
				var pos := Vector3((i % 3 - 1) * 0.25, 0.13, (i / 3) * 0.28)
				blocks.piece(prop, "pine", pos, Vector3(0.07, 0.26, 0.07))
				blocks.piece(prop, "pine_light" if entry.kind == "herb" else "cloth", pos + Vector3(0, 0.13, 0), Vector3(0.23, 0.08, 0.23))
		else:
			blocks.piece(prop, "wood", Vector3(0, 0.3, 0), Vector3(0.85, 0.6, 0.65))
			for x in [-0.3, 0.3]:
				blocks.piece(prop, "iron", Vector3(x, 0.31, 0), Vector3(0.08, 0.64, 0.69))
			blocks.piece(prop, "gold", Vector3(0, 0.38, 0.34), Vector3(0.12, 0.15, 0.05))
		_craft_sign(prop.position, entry.name, Color("a7bea0"))
	player.character.changed.connect(_refresh_gathering_props)
	_refresh_gathering_props()

func _craft_sign(origin: Vector3, text: String, tint: Color) -> void:
	var sign := Label3D.new()
	sign.position = origin + Vector3(0, 1.8, 0)
	sign.text = text
	sign.font_size = 26
	sign.pixel_size = 0.004
	sign.modulate = tint
	sign.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	sign.visibility_range_end = 12.0
	add_child(sign)

func _refresh_gathering_props() -> void:
	for id: String in gathering_props:
		var entry: Dictionary = player.character.definition("nodes", id)
		var empty: bool = player.character.claims.has(id) and not entry.has("cooldown")
		gathering_props[id].scale.y = 0.3 if empty else 1.0

func combat_enemies() -> Array:
	if is_instance_valid(seal) and seal.inside: return seal.enemies.filter(func(enemy): return seal.can_damage_enemy(enemy.enemy_id))
	if is_instance_valid(winter) and winter.inside: return winter.enemies.filter(func(enemy): return winter.can_damage_enemy(enemy.enemy_id))
	if is_instance_valid(threshold) and threshold.inside: return threshold.enemies.filter(func(enemy): return threshold.can_damage_enemy(enemy.enemy_id))
	if is_instance_valid(convergence) and convergence.inside: return convergence.enemies if convergence.state.convergence.installed else []
	if is_instance_valid(choir) and choir.inside: return choir.enemies
	if is_instance_valid(roots) and roots.inside: return roots.enemies
	if is_instance_valid(lens) and lens.inside: return lens.enemies
	if is_instance_valid(shore) and shore.inside: return shore.enemies
	if is_instance_valid(archive_chapter) and archive_chapter.inside: return archive_chapter.enemies
	if is_instance_valid(mountain) and mountain.inside: return mountain.enemies
	return realms.enemies if is_instance_valid(realms) and realms.inside else adventure.enemies if adventure.inside else wilderness.enemies if is_instance_valid(wilderness) else []

func terrain_step_at(at: Vector3) -> String:
	var cell:=Vector2i(floori(at.x),floori(at.z))
	if step_paths.has(cell): return "stone"
	for patch: Rect2 in step_snow.get(cell,[]):
		if patch.has_point(Vector2(at.x,at.z)): return "snow"
	return "grass"
func footstep_at(at: Vector3) -> String:
	var query:=PhysicsRayQueryParameters3D.create(at+Vector3.UP*.3,at-Vector3.UP*.65,1)
	var hit:=get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty(): return "step"
	var surface: String=hit.collider.get_meta("footstep","stone")
	if surface=="terrain": surface=terrain_step_at(hit.position)
	if surface=="wyrmkeep_ground":
		var local: Vector3=hit.position-mountain.ORIGIN
		surface="stone" if mountain.TownDetail.path_at(roundf(local.x),roundf(local.z)) else "snow"
	if surface=="pinehall_ground":
		var local: Vector3=hit.position-archive_chapter.ORIGIN
		surface=archive_chapter.CampDetail.surface_at(local.x,local.z)
	return "step_"+surface if surface in ["grass","snow","stone","wood","metal"] else "step"
