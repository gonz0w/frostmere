extends Node3D
const Creature = preload("res://scripts/wild_creature.gd")
const SITES = [Vector3(-28,0,-20),Vector3(-30,0,-23),Vector3(-26,0,-25),Vector3(36,0,-7),Vector3(38,0,-10),Vector3(34,0,-6),Vector3(-24,0,-58),Vector3(-27,0,-60),Vector3(-22,0,-62),Vector3(33,0,-52),Vector3(36,0,-55),Vector3(-5,0,-65),Vector3(34,0,18)]
var world: Node3D
var state: RefCounted
var enemies: Array[CharacterBody3D] = []
var inside: bool:
	get: return is_instance_valid(world.session_save) and world.session_save.area() == "home"
var feedback: String:
	get: return world.adventure.feedback
	set(value): world.adventure.feedback = value
var feedback_time: float:
	get: return world.adventure.feedback_time
	set(value): world.adventure.feedback_time = value
func _ready() -> void:
	state = world.player.character
	for i in range(SITES.size()):
		var e = preload("res://scripts/mossbound_colossus.gd").new() if i == 11 else preload("res://scripts/frost_beast.gd").new() if i == 12 else Creature.new(); e.adventure = self; e.enemy_id = "wild_%d" % i; e.species = "frostbeast" if i == 12 else "golem" if i == 11 else "boar" if i in [3,4,5,9,10] else "wolf"
		e.title = {"frostbeast":"Rimefang, the Frostmaw", "wolf":"Frostfang Wolf", "boar":"Bristleback Boar", "golem":"The Mossbound Colossus"}[e.species]
		e.progress = state.wilderness; e.position = SITES[i] + Vector3.UP * (0.2 + world.Terrain.height_at(SITES[i].x,SITES[i].z)); add_child(e); enemies.append(e)
func line_clear(a: Vector3, b: Vector3, source: CollisionObject3D, target: CollisionObject3D) -> bool:
	return world.adventure.line_clear(a, b, source, target)
func mark_defeated(id: String) -> void:
	if id not in state.wilderness.defeated: state.wilderness.defeated.append(id); state._commit()
func nearby_loot() -> CharacterBody3D:
	if not inside: return null
	for e in enemies:
		if e.dead and e.enemy_id not in state.wilderness.looted and e.global_position.distance_to(world.player.global_position) < 3: return e
	return null
func loot() -> bool:
	if world.player.paused: return false
	var e = nearby_loot()
	if e == null: return false
	state.wilderness.looted.append(e.enemy_id)
	var drops = {"iron_ore":8, "steel_ingot":2} if e.species == "golem" else {"hide":2, "raw_meat":2}
	if e.species == "frostbeast": drops={"hide":8,"crystal":4,"steel_ingot":3}
	for id in drops: state.materials[id] = int(state.materials.get(id,0)) + drops[id]
	state.gold += 100 if e.species == "frostbeast" else 80 if e.species == "golem" else 8
	state._commit(); e._update_label()
	feedback = "Recovered " + e.title + " crafting materials"; feedback_time = 2
	return true

func town_safe(position: Vector3) -> bool:
	return (position.x > -25 and position.x < 9 and position.z > -12 and position.z < 29) or (position.x > -22 and position.x < -12 and position.z > -37 and position.z < -23) or (position.x > -19 and position.x < 9 and position.z > -58 and position.z < 16) or (position.x > 8 and position.x < 23 and absf(position.z + 16) < 7)
