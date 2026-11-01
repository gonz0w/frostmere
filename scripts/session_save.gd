extends Node
const State=preload("res://scripts/character_state.gd")
const AREAS=["seal","winter","threshold","convergence","choir","roots","lens","shore","archive_chapter","mountain","adventure"]
var world: Node3D
var ready_to_save:=false
var restoring:=false
var elapsed:=0.0
func _ready() -> void:
	call_deferred("initialize")
func initialize() -> void:
	var saved: Dictionary=world.player.character.session.duplicate(true)
	await get_tree().physics_frame
	await get_tree().physics_frame
	if world.player.character.persist: restore(saved)
	world.player.character.session_provider=Callable(self,"capture")
	ready_to_save=true
	if world.player.character.persist: get_tree().auto_accept_quit=false
	if (world.player.character.persist or "--intro-preview" in OS.get_cmdline_user_args()) and not world.player.character.intro_completed:
		world.intro.start()
	world.hud.show_recovery_notice()
func area() -> String:
	if world.realms.inside: return world.realms.current
	for id: String in AREAS:
		if world.get(id).inside: return id
	return "home"
func vec(v: Vector3) -> Array: return [v.x,v.y,v.z]
func vector(v: Array) -> Vector3: return Vector3(v[0],v[1],v[2])
func capture() -> Dictionary:
	if is_instance_valid(world.intro) and world.intro.active: return {}
	if restoring: return world.player.character.session.duplicate(true)
	var p: CharacterBody3D=world.player
	if p.health<=0: return {}
	var actors: Array=[]
	for enemy in world.combat_enemies():
		if not enemy.dead and enemy.global_position.distance_to(p.position)<180: actors.append({"id":enemy.enemy_id,"position":vec(enemy.global_position),"health":enemy.health})
	return {"area":area(),"position":vec(p.position),"yaw":p.rotation.y,"pitch":p.pivot.rotation.x,"third_person":p.third_person,"health":p.health,"magicka":p.magicka,"stamina":p.stamina,"enemies":actors}
func supported_position(position: Vector3,body: CollisionObject3D) -> bool:
	var query:=PhysicsRayQueryParameters3D.create(position+Vector3.UP*.4,position-Vector3.UP*1.2,1,[body.get_rid()])
	var hit: Dictionary=world.get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty() or hit.normal.y<.6: return false
	var shape:=CapsuleShape3D.new(); shape.radius=.32; shape.height=1.6
	var check:=PhysicsShapeQueryParameters3D.new(); check.shape=shape; check.transform=Transform3D(Basis(),position+Vector3.UP*1.0); check.collision_mask=1; check.exclude=[body.get_rid()]
	return world.get_world_3d().direct_space_state.intersect_shape(check,1).is_empty()
func restore(saved: Dictionary) -> bool:
	if saved.is_empty() or not State.valid_session(saved): return false
	restoring=true
	var p: CharacterBody3D=world.player
	p.set_paused(false)
	if world.realms.inside: world.realms.leave()
	for id: String in AREAS:
		if world.get(id).inside: world.get(id).leave()
	var entered:=true
	if saved.area in ["aeralis","crucible"]: entered=world.realms.enter(saved.area,false)
	elif saved.area in AREAS:
		var chapter: Node3D=world.get(saved.area)
		if saved.area=="adventure": chapter.enter(); entered=chapter.inside
		else: entered=chapter.enter()
	if not entered:
		restoring=false; world.hud.announce("Returned to Frostmere","This saved area is no longer available. Your equipment and quest progress are preserved."); return false
	var target:=vector(saved.position)
	# Scene-authored area entrances are the fallback for airborne or obstructed saves.
	var anchor: Vector3=p.position if saved.area!="home" else Vector3.ZERO
	if target.distance_to(anchor)<180 and supported_position(target,p): p.position=target
	p.rotation.y=saved.yaw; p.pivot.rotation.x=clampf(saved.pitch,-1.4,1.4); p.set_third_person(saved.third_person)
	p.health=clampf(saved.health,1,p.derived.health); p.magicka=clampf(saved.magicka,0,p.derived.magicka); p.stamina=clampf(saved.stamina,0,p.derived.stamina); p.velocity=Vector3.ZERO
	for record: Dictionary in saved.enemies:
		for enemy in world.combat_enemies():
			if enemy.enemy_id==record.id and not enemy.dead:
				var location:=vector(record.position)
				if location.distance_to(enemy.home)<100 and supported_position(location,enemy): enemy.global_position=location
				enemy.health=clampf(record.health,1,enemy.maximum_health); enemy.velocity=Vector3.ZERO; enemy._update_label()
	p.invulnerable=2
	restoring=false; world.hud.notice_time=0
	return true
func save_now() -> bool:
	if not ready_to_save or restoring or not world.player.character.persist: return false
	var success: bool=world.player.character.save_to(State.SAVE_PATH)
	if not success: world.hud.announce("Save failed","Your adventure is still running. Try Save adventure again before quitting.")
	return success
func quit_game() -> void:
	if world.player.character.persist and not save_now(): return
	get_tree().quit()
func _notification(what: int) -> void:
	if what==NOTIFICATION_WM_CLOSE_REQUEST and ready_to_save and world.player.character.persist: quit_game()
func _process(delta: float) -> void:
	if not ready_to_save or not world.player.character.persist: return
	elapsed+=delta
	if elapsed>=15:
		elapsed=0; save_now()
