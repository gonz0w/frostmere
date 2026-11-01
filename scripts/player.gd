extends CharacterBody3D

const CharacterState = preload("res://scripts/character_state.gd")
const CharacterVisual = preload("res://scripts/character_visual.gd")
const WALK_SPEED := 4.5
const RUN_SPEED := 7.5
const JUMP_SPEED := 6.0

var character := CharacterState.new()
var derived: Dictionary = {}
var first_person_hands: Node3D
var character_menu_open := false
var map_open := false
var workshop_open := false
var shop_open := false
var dialog_open := false
var attack_cooldown := 0.0
var attack_animation := 0.0
var spell_cooldown := 0.0
var finisher_target: CharacterBody3D
var finisher_remaining := 0.0
var finisher_impact := false
var finisher_arm := Vector3.ZERO
var finisher_hands := Vector3.ZERO
var finisher_hand_position := Vector3.ZERO
var finisher_move: Dictionary = {}
const FinisherMoves = preload("res://scripts/finisher_moves.gd")
var power := 0.0
var power_move := "whirlwind"
var power_hit := false
var power_damage := 0.0
var power_effect := ""
var power_remaining := 0.0
var power_time_scale := 1.0
var power_avatar_y := 0.0
var power_hands_z := 0.0
var power_arm_rotation := Vector3.ZERO
var combat_rng := RandomNumberGenerator.new()
var blocking := false
var parry_window := 0.0
var parry_cooldown := 0.0
var guard_recovery := 0.0
var guard_held := false
var invulnerable := 0.0
var health := 100.0
var magicka := 100.0
var pivot: Node3D
var spring: SpringArm3D
var camera: Camera3D
var avatar: Node3D
var left_leg: Node3D
var right_leg: Node3D
var left_arm: Node3D
var right_arm: Node3D
var third_person := true
var paused := false
var phase := 0.0
var stamina := 100.0
var spawn_point := Vector3(0, 0.15, 17)
var mouse_sensitivity := 0.0023

func _ready() -> void:
	name = "Player"
	position = spawn_point
	collision_layer = 2
	collision_mask = 1 | 4
	floor_snap_length = 0.4
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.31
	capsule.height = 1.8
	var collider := CollisionShape3D.new()
	collider.shape = capsule
	collider.position.y = 0.9
	add_child(collider)
	pivot = Node3D.new()
	pivot.position.x = 0.65
	pivot.position.y = 1.65
	pivot.rotation.x = -0.10
	add_child(pivot)
	spring = SpringArm3D.new()
	spring.spring_length = 4.4
	spring.margin = 0.18
	spring.collision_mask = 1
	spring.add_excluded_object(get_rid())
	var probe := SphereShape3D.new()
	probe.radius = 0.18
	spring.shape = probe
	pivot.add_child(spring)
	camera = Camera3D.new()
	camera.fov = 72
	camera.near = 0.08
	camera.far = 450
	camera.current = true
	spring.add_child(camera)
	var isolated := _automated_render() or DisplayServer.get_name() == "headless" or "--crystal-preview" in OS.get_cmdline_user_args() or "--hell-preview" in OS.get_cmdline_user_args() or "--story-preview" in OS.get_cmdline_user_args() or "--mountain-preview" in OS.get_cmdline_user_args() or "--archive-preview" in OS.get_cmdline_user_args() or "--shore-preview" in OS.get_cmdline_user_args() or "--lens-preview" in OS.get_cmdline_user_args() or "--roots-preview" in OS.get_cmdline_user_args() or "--choir-preview" in OS.get_cmdline_user_args() or "--convergence-preview" in OS.get_cmdline_user_args() or "--threshold-preview" in OS.get_cmdline_user_args() or "--winter-preview" in OS.get_cmdline_user_args() or "--seal-preview" in OS.get_cmdline_user_args()
	isolated = isolated or "--intro-preview" in OS.get_cmdline_user_args()
	if not isolated:
		character.load_from(CharacterState.SAVE_PATH)
	character.persist = not isolated
	derived = character.stats()
	stamina = derived.stamina
	health = derived.health
	magicka = derived.magicka
	_make_avatar()
	character.changed.connect(_character_changed)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if _automated_render() else Input.MOUSE_MODE_CAPTURED

func _automated_render() -> bool:
	return "--capture" in OS.get_cmdline_user_args() or "--benchmark" in OS.get_cmdline_user_args()

func _make_avatar() -> void:
	if is_instance_valid(avatar):
		remove_child(avatar)
		avatar.queue_free()
	avatar = CharacterVisual.new()
	add_child(avatar)
	avatar.build(character)
	avatar.visible = third_person
	left_leg = avatar.left_leg
	right_leg = avatar.right_leg
	left_arm = avatar.left_arm
	right_arm = avatar.right_arm
	if is_instance_valid(first_person_hands):
		camera.remove_child(first_person_hands)
		first_person_hands.queue_free()
	first_person_hands = Node3D.new()
	camera.add_child(first_person_hands)
	first_person_hands.visible = not third_person
	for slot in ["main_hand", "off_hand"]:
		var hand := Node3D.new()
		hand.position = Vector3(0.30 if slot == "main_hand" else -0.30, -0.38, -0.65)
		hand.rotation.x = -0.12
		hand.scale = Vector3.ONE * 0.65
		first_person_hands.add_child(hand)
		CharacterVisual.make_first_person_arm(hand, character,slot=="main_hand")
		CharacterVisual.make_weapon(hand, character.item_at(slot))

func _character_changed() -> void:
	var previous := derived
	derived = character.stats()
	stamina = minf(derived.stamina, stamina * float(derived.stamina) / maxf(1, previous.get("stamina", 100)))
	health = minf(derived.health, health * float(derived.health) / maxf(1, previous.get("health", 100)))
	magicka = minf(derived.magicka, magicka * float(derived.magicka) / maxf(1, previous.get("magicka", 100)))
	_make_avatar()

func _unhandled_input(event: InputEvent) -> void:
	if _automated_render():
		return
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode==KEY_K:
		if get_parent().skills_menu.visible: get_parent().skills_menu.close_menu()
		else: get_parent().skills_menu.open_menu()
		get_viewport().set_input_as_handled(); return
	if shop_open and (event.is_action_pressed("inventory") or event.is_action_pressed("character") or event.is_action_pressed("world_map") or event.is_action_pressed("pause")):
		get_parent().shops.close()
		if event.is_action_pressed("pause"):
			get_viewport().set_input_as_handled()
			return
	if dialog_open and (event.is_action_pressed("inventory") or event.is_action_pressed("character") or event.is_action_pressed("world_map") or event.is_action_pressed("pause")):
		if is_instance_valid(get_parent().skills_menu) and get_parent().skills_menu.visible: get_parent().skills_menu.close_menu()
		if is_instance_valid(get_parent().road_quests): get_parent().road_quests.close()
		if is_instance_valid(get_parent().hunts): get_parent().hunts.close()
		get_parent().adventure.close_dialog()
		if is_instance_valid(get_parent().realms.ending): get_parent().realms.ending.close_dialog()
		if is_instance_valid(get_parent().stonewake): get_parent().stonewake.close_dialog()
		if is_instance_valid(get_parent().mountain): get_parent().mountain.close_dialog()
		if is_instance_valid(get_parent().seal): get_parent().seal.close_dialog()
		if is_instance_valid(get_parent().winter): get_parent().winter.close_dialog()
		if is_instance_valid(get_parent().threshold): get_parent().threshold.close_dialog()
		if is_instance_valid(get_parent().convergence): get_parent().convergence.close_dialog()
		if is_instance_valid(get_parent().choir): get_parent().choir.close_dialog()
		if is_instance_valid(get_parent().roots): get_parent().roots.close_dialog()
		if is_instance_valid(get_parent().lens): get_parent().lens.close_dialog()
		if is_instance_valid(get_parent().shore): get_parent().shore.close_dialog()
		if is_instance_valid(get_parent().archive_chapter): get_parent().archive_chapter.close_dialog()
		if event.is_action_pressed("pause"):
			set_paused(false)
			get_viewport().set_input_as_handled()
			return
	if event.is_action_pressed("inventory"):
		if workshop_open:
			get_parent().hud.workshop.close()
		else:
			get_parent().hud.workshop.open()
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("world_map"):
		workshop_open = false
		map_open = not map_open
		character_menu_open = false
		set_paused(map_open)
		if map_open and (get_parent().adventure.inside or get_parent().realms.inside or get_parent().mountain.inside or get_parent().archive_chapter.inside or get_parent().shore.inside or get_parent().lens.inside or get_parent().roots.inside or get_parent().choir.inside or get_parent().convergence.inside or get_parent().threshold.inside or get_parent().winter.inside or get_parent().seal.inside):
			get_parent().hud.world_map.set_view(true)
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("character"):
		workshop_open = false
		map_open = false
		character_menu_open = not character_menu_open
		set_paused(character_menu_open)
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("pause"):
		if workshop_open:
			workshop_open = false
			set_paused(false)
		elif map_open:
			map_open = false
			set_paused(false)
		elif character_menu_open:
			character_menu_open = false
			set_paused(false)
		else:
			set_paused(not paused)
		get_viewport().set_input_as_handled()
	if paused:
		return
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotation.y -= event.relative.x * mouse_sensitivity
		pivot.rotation.x = clampf(pivot.rotation.x - event.relative.y * mouse_sensitivity, -1.25, 1.15)
	if event.is_action_pressed("camera_toggle"):
		set_third_person(not third_person)
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_X:
		activate_finisher()
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_G:
		activate_power("sunder" if event.shift_pressed else "whirlwind")
	if event.is_action_pressed("attack"):
		attack()
	if event.is_action_pressed("spell"):
		cast_spell()
	if event.is_action_pressed("cycle_spell"):
		character.cycle_spell()
		combat_feedback("Selected " + character.spell_definition(character.active_spell).name)
	if event.is_action_pressed("heal"):
		var message: String = character.consume("healing_draught", self)
		get_parent().audio.sfx("heal" if message.begins_with("Used") else "error")
		combat_feedback(message)
	if event.is_action_pressed("respawn"):
		if get_parent().adventure.inside:
			get_parent().adventure.leave()
		respawn()

func set_paused(value: bool) -> void:
	if value != paused and is_instance_valid(get_parent().audio): get_parent().audio.sfx("interact")
	if value:
		cancel_power(); cancel_finisher()
	paused = value
	if paused:
		blocking = false
		parry_window = 0
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if paused else Input.MOUSE_MODE_CAPTURED

func set_third_person(value: bool) -> void:
	third_person = value
	pivot.position.x = 0.65 if value else 0.0
	spring.spring_length = 4.4 if value else 0.0
	avatar.visible = value
	first_person_hands.visible = not value
	camera.position = Vector3.ZERO

func _notification(what: int) -> void:
	if "--capture" in OS.get_cmdline_user_args() or "--benchmark" in OS.get_cmdline_user_args():
		return
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and is_instance_valid(camera):
		set_paused(true)

func respawn() -> void:
	if is_instance_valid(get_parent().intro) and get_parent().intro.active:
		position = get_parent().intro.ORIGIN + Vector3(0,.1,8)
		velocity = Vector3.ZERO
		return
	cancel_power(); cancel_finisher(); power = 0
	if is_instance_valid(get_parent().seal) and get_parent().seal.inside: get_parent().seal.leave()
	if is_instance_valid(get_parent().winter) and get_parent().winter.inside: get_parent().winter.leave()
	if is_instance_valid(get_parent().threshold) and get_parent().threshold.inside: get_parent().threshold.leave()
	if is_instance_valid(get_parent().convergence) and get_parent().convergence.inside: get_parent().convergence.leave()
	if is_instance_valid(get_parent().choir) and get_parent().choir.inside: get_parent().choir.leave()
	if is_instance_valid(get_parent().roots) and get_parent().roots.inside: get_parent().roots.leave()
	if is_instance_valid(get_parent().lens) and get_parent().lens.inside: get_parent().lens.leave()
	if is_instance_valid(get_parent().shore) and get_parent().shore.inside: get_parent().shore.leave()
	if is_instance_valid(get_parent().archive_chapter) and get_parent().archive_chapter.inside: get_parent().archive_chapter.leave()
	if is_instance_valid(get_parent().mountain) and get_parent().mountain.inside: get_parent().mountain.leave()
	if is_instance_valid(get_parent().realms) and get_parent().realms.inside:
		get_parent().realms.leave()
	if is_instance_valid(get_parent().adventure) and get_parent().adventure.inside:
		get_parent().adventure.leave()
	position = spawn_point
	velocity = Vector3.ZERO
	rotation = Vector3.ZERO
	pivot.rotation.x = -0.1

func _physics_process(delta: float) -> void:
	if paused:
		return
	if finisher_remaining > 0:
		velocity = Vector3.ZERO
		return
	attack_cooldown = maxf(0, attack_cooldown - delta)
	spell_cooldown = maxf(0, spell_cooldown - delta)
	attack_animation = maxf(0, attack_animation - delta)
	invulnerable = maxf(0, invulnerable - delta)
	update_guard(delta, Input.is_action_pressed("block"))
	if not _automated_render() and character.item_at("main_hand").get("family", "") == "machine_gun" and Input.is_action_pressed("attack"):
		attack()
	var input := Vector2.ZERO if _automated_render() else Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction := basis * Vector3(input.x, 0, input.y)
	var running := Input.is_action_pressed("sprint") and input.length() > 0.1 and stamina > 1.0
	var speed: float = (RUN_SPEED if running else WALK_SPEED) * derived.speed * (0.45 if blocking else 1.0)
	stamina = clampf(stamina + (-float(derived.sprint_cost) if running else 0.0 if blocking else float(derived.stamina_regen)) * delta, 0, derived.stamina)
	magicka = minf(derived.magicka, magicka + float(derived.magicka_regen) * delta)
	velocity.x = move_toward(velocity.x, direction.x * speed, 24.0 * delta)
	velocity.z = move_toward(velocity.z, direction.z * speed, 24.0 * delta)
	if not is_on_floor():
		velocity.y -= 18.0 * delta
	elif Input.is_action_just_pressed("jump"):
		velocity.y = JUMP_SPEED
	move_and_slide()
	var moving := Vector2(velocity.x, velocity.z).length()
	phase += delta * moving * 2.3
	var swing := sin(phase) * minf(moving / 7.5, 0.8)
	left_leg.rotation.x = swing
	right_leg.rotation.x = -swing
	left_arm.rotation.x = -swing * 0.55
	right_arm.rotation.x = -sin(attack_animation / 0.35 * PI) * 1.8 if attack_animation > 0 else swing * 0.55
	if blocking:
		left_arm.rotation.x = -1.5
	first_person_hands.rotation.x = -sin(attack_animation / 0.35 * PI) * 0.65 if attack_animation > 0 else -0.25 if blocking else 0.0
	if is_instance_valid(get_parent().realms) and get_parent().realms.inside:
		get_parent().realms.check_fall()
	elif is_instance_valid(get_parent().seal) and get_parent().seal.inside:
		get_parent().seal.check_fall()
	elif is_instance_valid(get_parent().winter) and get_parent().winter.inside:
		get_parent().winter.check_fall()
	elif is_instance_valid(get_parent().threshold) and get_parent().threshold.inside:
		get_parent().threshold.check_fall()
	elif is_instance_valid(get_parent().convergence) and get_parent().convergence.inside:
		get_parent().convergence.check_fall()
	elif is_instance_valid(get_parent().choir) and get_parent().choir.inside:
		get_parent().choir.check_fall()
	elif is_instance_valid(get_parent().roots) and get_parent().roots.inside:
		get_parent().roots.check_fall()
	elif is_instance_valid(get_parent().lens) and get_parent().lens.inside:
		get_parent().lens.check_fall()
	elif is_instance_valid(get_parent().shore) and get_parent().shore.inside:
		get_parent().shore.check_fall()
	elif is_instance_valid(get_parent().mountain) and get_parent().mountain.inside:
		get_parent().mountain.check_fall()
	elif is_instance_valid(get_parent().archive_chapter) and get_parent().archive_chapter.inside:
		get_parent().archive_chapter.check_fall()
	elif (position.y < -12 and not get_parent().adventure.inside) or position.y < -40 or absf(position.x) > 95 or absf(position.z) > 130:
		respawn()

func combat_feedback(message: String) -> void:
	get_parent().adventure.feedback = message
	get_parent().adventure.feedback_time = 1.6

func can_block() -> bool:
	var family: String = character.item_at("main_hand").get("family", "")
	return character.item_at("off_hand").get("family", "") == "shield" or family in ["sword", "dagger", "axe", "mace", "greatsword", "battleaxe"]

func melee_interval() -> float:
	var weapon: Dictionary=character.item_at("main_hand")
	if weapon.get("family","")=="dagger": return .38
	return .85 if weapon.get("two_handed",false) else .62

func melee_stamina_cost() -> float:
	if character.item_at("main_hand").get("family","")=="dagger":
		return 4.0 if character.has_perk("measured_swing") else 6.0
	return 6.0 if character.has_perk("measured_swing") else 9.0

func attack() -> bool:
	if paused or health <= 0 or attack_cooldown > 0 or blocking or power_remaining > 0 or finisher_remaining > 0:
		return false
	var weapon: Dictionary = character.item_at("main_hand")
	if weapon.get("effect", "") == "chain_lightning": return cast_spell("chain_lightning")
	if weapon.get("family", "") in ["staff", "focus"]:
		return cast_spell()
	if weapon.get("family", "") == "machine_gun":
		var ammo: String=weapon.get("ammo_type","hell_round")
		if int(character.materials.get(ammo, 0)) <= 0:
			combat_feedback("No "+character.definition("materials",ammo).name+" · press more at a forge")
			return false
		character.materials[ammo] -= 1
		record_combat("ammo", 1, ammo)
		# Persist ammo without rebuilding the entire avatar for each automatic round.
		if character.persist and not character.save_to(CharacterState.SAVE_PATH):
			character.last_error = "Ammo changed, but saving failed."
		shoot(float(derived.damage), false, Color("f9bd68"))
		get_parent().audio.sfx("gun")
		attack_cooldown = float(weapon.get("fire_interval",0.12))*(.85 if character.has_perk("quick_release") else 1.0)
	elif weapon.get("family", "") == "bow":
		if int(character.materials.get("arrow", 0)) <= 0:
			combat_feedback("No arrows · fletch more at the forge")
			return false
		character.materials.arrow -= 1
		record_combat("ammo", 1, "arrow")
		character._commit()
		shoot(float(derived.damage), false)
		get_parent().audio.sfx("bow")
		attack_cooldown = 0.85*(.85 if character.has_perk("quick_release") else 1.0)
	else:
		var swing_cost:=melee_stamina_cost()
		if stamina < swing_cost:
			combat_feedback("Not enough stamina to swing")
			return false
		get_parent().audio.sfx("swing")
		stamina -= swing_cost
		record_combat("attack", 1, "melee")
		attack_cooldown = melee_interval()
		var critical := roll_weapon_critical()
		var reach := 3.1 if weapon.get("two_handed", false) else 2.6
		var adventure: Node3D = get_parent().adventure
		for enemy: CharacterBody3D in get_parent().combat_enemies():
			if enemy.dead:
				continue
			var offset: Vector3 = enemy.global_position - global_position
			offset.y = 0
			if offset.length() <= reach and (-global_basis.z).dot(offset.normalized()) > 0.45 and adventure.line_clear(global_position + Vector3.UP, enemy.global_position + Vector3.UP, self, enemy):
				enemy.receive_damage(float(derived.damage), self, weapon.get("effect", ""),"melee",critical)
	attack_animation = 0.35
	return true

func cast_spell(spell_id: String = "") -> bool:
	if paused or health <= 0 or spell_cooldown > 0 or blocking or power_remaining > 0 or finisher_remaining > 0:
		return false
	if spell_id == "": spell_id = character.active_spell
	if spell_id not in character.known_spells and not (spell_id == "chain_lightning" and character.item_at("main_hand").get("effect", "") == "chain_lightning"): return false
	var spell: Dictionary = character.spell_definition(spell_id)
	var cost: float=character.spell_cost(float(spell.cost))
	if magicka < cost:
		combat_feedback("%s needs %d magicka" % [spell.name, ceili(cost)])
		return false
	get_parent().audio.sfx("spell")
	magicka -= cost
	record_combat("attack", 1, spell_id)
	spell_cooldown = float(spell.cooldown)
	attack_cooldown = maxf(attack_cooldown, 0.4)
	attack_animation = 0.35
	if spell.id == "starfall":
		for offset in [-0.14, 0.0, 0.14]: shoot(float(derived.spell_power) * float(spell.scale), true, Color(spell.color), offset)
	else:
		shoot(float(derived.spell_power) * float(spell.scale), true, Color(spell.color), 0, 2 if spell.id == "chain_lightning" else 0, int(spell.get("pierces",0)))
	return true

func shoot(damage: float, magic: bool, tint: Color = Color.TRANSPARENT, offset: float = 0, chain: int = 0, pierces: int = 0) -> void:
	var screen := get_viewport().get_visible_rect().size * 0.5
	var ray_from := camera.project_ray_origin(screen)
	var direction := camera.project_ray_normal(screen)
	var query := PhysicsRayQueryParameters3D.create(ray_from, ray_from + direction * 65, 1 | 4)
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	var aim: Vector3 = hit.get("position", ray_from + direction * 65)
	var origin := global_position + Vector3.UP * 1.35 - global_basis.z * 0.45 + global_basis.x * offset
	get_parent().adventure.fire(origin, (aim - origin).normalized(), damage, false, self, magic, tint, chain, pierces)

func roll_weapon_critical() -> bool:
	return combat_rng.randf() * 100.0 < clampf(float(derived.critical), 0, 35)

func update_guard(delta: float, held: bool) -> void:
	parry_window = maxf(0, parry_window - delta)
	parry_cooldown = maxf(0, parry_cooldown - delta)
	guard_recovery = maxf(0, guard_recovery - delta)
	blocking = held and can_block() and attack_animation <= 0 and stamina > 0 and guard_recovery <= 0 and power_remaining <= 0 and finisher_remaining <= 0
	if blocking and not guard_held and parry_cooldown <= 0:
		parry_window = 0.22
		parry_cooldown = 0.8
	if not blocking: parry_window = 0
	guard_held = held

func receive_damage(amount: float, source_position: Vector3, attacker: Node = null) -> void:
	if paused or health <= 0 or invulnerable > 0:
		return
	get_parent().audio.engage()
	get_parent().audio.sfx("block" if blocking and can_block() and (-global_basis.z).dot((source_position-global_position).normalized())>0.25 else "hit")
	var impact_outcome:="HIT"
	var adjusted := amount * 100.0 / (100.0 + float(derived.armor) * 1.5)
	var source := source_position - global_position
	source.y = 0
	if blocking and can_block() and (-global_basis.z).dot(source.normalized()) > 0.25:
		if parry_window > 0 and is_instance_valid(attacker) and attacker.has_method("parried") and stamina >= 8:
			stamina -= 8
			parry_window = 0
			invulnerable = 0.15
			attacker.parried()
			record_combat("parry")
			gain_power(15)
			combat_feedback("Parry! · Attacker staggered")
			get_parent().hud.damage_direction.show_impact(source_position,"PARRY")
			return
		if stamina >= amount * 0.65:
			stamina -= amount * 0.65
			adjusted *= 0.22 if character.item_at("off_hand").get("family", "") == "shield" else 0.45
			impact_outcome="BLOCK"
			combat_feedback("Blocked · %.0f damage" % maxf(1, adjusted))
		else:
			stamina = 0
			blocking = false
			guard_recovery = 0.65
			parry_window = 0
			impact_outcome="GUARD BROKEN"
			combat_feedback("Guard broken!")
	else:
		combat_feedback("Hit · %.0f damage" % maxf(1, adjusted))
	record_combat("damage_taken", minf(health, maxf(1, adjusted)))
	health = maxf(0, health - maxf(1, adjusted))
	if health>0: get_parent().hud.damage_direction.show_impact(source_position,impact_outcome)
	else: get_parent().hud.damage_direction.clear()
	invulnerable = 0.15
	if health <= 0:
		if get_parent().combat_metrics != null: get_parent().combat_metrics.finish("death")
		cancel_power(); cancel_finisher(); power = 0
		get_parent().audio.sfx("death")
		get_parent().adventure.on_death()
		invulnerable = 2.0

func record_combat(kind: String, amount: float = 0.0, id: String = "") -> void:
	if get_parent() != null and get_parent().get("combat_metrics") != null:
		get_parent().combat_metrics.event(kind, amount, id)

func chain_lightning(first: CharacterBody3D, damage: float, jumps: int) -> void:
	var visited: Array = [first]
	var previous: CharacterBody3D = first
	for hop in range(mini(jumps, 2)):
		var target: CharacterBody3D = null
		var nearest := 5.0
		for enemy: CharacterBody3D in get_parent().combat_enemies():
			if enemy.dead or enemy in visited: continue
			var distance := previous.global_position.distance_to(enemy.global_position)
			if distance < nearest and get_parent().adventure.line_clear(previous.global_position + Vector3.UP, enemy.global_position + Vector3.UP, previous, enemy):
				target=enemy; nearest=distance
		if target==null: return
		var from := previous.global_position + Vector3.UP
		var to := target.global_position + Vector3.UP
		var flash := MeshInstance3D.new()
		var mesh := BoxMesh.new(); mesh.size=Vector3(0.07,0.07,from.distance_to(to)); flash.mesh=mesh
		var material := StandardMaterial3D.new(); material.albedo_color=Color("a4dff7"); material.emission_enabled=true; material.emission=material.albedo_color
		flash.material_override=material; get_parent().add_child(flash); flash.global_position=(from+to)*0.5
		if from.distance_to(to)>0.001: flash.look_at(to)
		get_tree().create_timer(0.18).timeout.connect(func(): if is_instance_valid(flash): flash.queue_free())
		damage*=0.65; target.receive_damage(damage,self,"","magic")
		visited.append(target); previous=target

func gain_power(amount: float) -> void:
	if amount > 0 and not paused and health > 0 and power_remaining <= 0:
		power = minf(100, power + amount)

func activate_power(move: String="whirlwind") -> bool:
	if move not in ["whirlwind","sunder"]: return false
	if paused or health <= 0 or power_remaining > 0 or finisher_remaining > 0 or attack_cooldown > 0 or blocking: return false
	if character.item_at("main_hand").get("family", "") not in ["sword", "dagger", "axe", "mace", "greatsword", "battleaxe"]:
		combat_feedback("Equip a melee weapon for a power attack")
		return false
	if power < 100:
		combat_feedback("Power attacks need a full meter · deal damage or parry")
		return false
	power_move = move
	power_hit = false
	power_damage = float(derived.damage) * (3 if move=="sunder" else 2)
	power_effect = character.item_at("main_hand").get("effect", "")
	power = 0
	power_remaining = 1.2
	power_time_scale = Engine.time_scale
	Engine.time_scale = power_time_scale * 0.35
	power_avatar_y = avatar.rotation.y
	power_hands_z = first_person_hands.rotation.z
	power_arm_rotation = right_arm.rotation
	attack_cooldown = 0.5
	combat_feedback("SUNDERING STRIKE · Forward smash!" if move=="sunder" else "WHIRLWIND · Slow-motion power attack!")
	return true

func resolve_power_hit() -> void:
	if power_hit or power_remaining<=0 or paused or health<=0: return
	power_hit=true
	get_parent().audio.sfx("power_impact")
	for enemy: CharacterBody3D in get_parent().combat_enemies():
		if enemy.dead: continue
		var offset: Vector3=enemy.global_position-global_position
		if offset.length() > (5.0 if power_move=="sunder" else 3.6): continue
		if power_move=="sunder" and (offset.length()<.001 or (-global_basis.z).dot(offset.normalized())<.7071): continue
		if not get_parent().adventure.line_clear(global_position + Vector3.UP, enemy.global_position + Vector3.UP, self, enemy): continue
		var before: float=enemy.health
		enemy.receive_damage(power_damage, self, power_effect, "melee")
		if power_move=="sunder" and not enemy.dead and enemy.health<before: enemy.stagger_time=maxf(enemy.stagger_time,1.5)

func _process(delta: float) -> void:
	update_power(delta / maxf(Engine.time_scale, 0.001))
	update_finisher(delta)

func update_power(real_delta: float) -> void:
	if power_remaining <= 0: return
	if paused or health<=0: cancel_power(); return
	var remaining:=maxf(0,power_remaining-maxf(0,real_delta))
	power_remaining=maxf(.001,remaining)
	var progress:=1.0-remaining/1.2
	if not power_hit and progress>=(.4 if power_move=="sunder" else .25): resolve_power_hit()
	if power_move=="sunder":
		avatar.rotation.y=power_avatar_y
		var lift: float=clampf(progress/.25,0,1)
		var strike: float=clampf((progress-.25)/.15,0,1)
		var recovery: float=clampf((progress-.4)/.6,0,1)
		right_arm.rotation=Vector3(lerpf(-.4,-2.4,lift) if progress<.25 else lerpf(-2.4,.15,strike) if progress<.4 else lerpf(.15,power_arm_rotation.x,recovery),0,-.25)
		first_person_hands.rotation.z=power_hands_z-sin(progress*PI)*.35
	else:
		avatar.rotation.y = power_avatar_y + TAU * progress
		right_arm.rotation = Vector3(-1.2, 0, -0.8)
		first_person_hands.rotation.z = power_hands_z - sin(progress * PI) * 0.9
	if remaining <= 0:
		# cancel_power also owns restoration, so retain the active flag until cleanup.
		power_remaining = 0.001
		cancel_power()

func cancel_power() -> void:
	if power_remaining <= 0: return
	Engine.time_scale = power_time_scale
	power_remaining = 0
	if is_instance_valid(avatar): avatar.rotation.y = power_avatar_y
	if is_instance_valid(first_person_hands): first_person_hands.rotation.z = power_hands_z
	if is_instance_valid(right_arm): right_arm.rotation = power_arm_rotation

func _exit_tree() -> void:
	cancel_power(); cancel_finisher()

func can_finish(enemy: CharacterBody3D) -> bool:
	if not is_instance_valid(enemy) or enemy.dead or enemy.health <= 0 or enemy.health > enemy.maximum_health * 0.2: return false
	if not enemy.adventure.inside: return false
	if enemy.adventure.has_method("can_damage_enemy") and not enemy.adventure.can_damage_enemy(enemy.enemy_id): return false
	var offset := enemy.global_position - global_position
	if offset.length() > 2.5 or (-global_basis.z).dot(offset.normalized()) < 0.5: return false
	return get_parent().adventure.line_clear(global_position + Vector3.UP, enemy.global_position + Vector3.UP, self, enemy)

func nearby_finisher() -> CharacterBody3D:
	if paused or health <= 0 or power_remaining > 0 or finisher_remaining > 0: return null
	if character.item_at("main_hand").get("family", "") not in ["sword", "dagger", "axe", "mace", "greatsword", "battleaxe"]: return null
	var target: CharacterBody3D = null
	for enemy: CharacterBody3D in get_parent().combat_enemies():
		if can_finish(enemy) and (target == null or global_position.distance_squared_to(enemy.global_position) < global_position.distance_squared_to(target.global_position)): target = enemy
	return target

func activate_finisher() -> bool:
	if blocking or attack_cooldown > 0: return false
	var target := nearby_finisher()
	if target == null: return false
	finisher_target = target
	finisher_move = FinisherMoves.MOVES[character.item_at("main_hand").family]
	finisher_remaining = finisher_move.duration
	finisher_impact = false
	finisher_arm = right_arm.rotation; finisher_hands = first_person_hands.rotation
	finisher_hand_position = first_person_hands.position
	target.execution_locked = true; target.windup = 0
	target.set_execution_pose(0)
	velocity = Vector3.ZERO
	combat_feedback(finisher_move.name.to_upper())
	get_parent().audio.sfx("swing")
	return true

func update_finisher(delta: float) -> void:
	if finisher_remaining <= 0: return
	if not is_instance_valid(finisher_target) or (not finisher_impact and not can_finish(finisher_target)):
		cancel_finisher(); return
	finisher_remaining = maxf(0, finisher_remaining - delta)
	var elapsed: float = finisher_move.duration - finisher_remaining
	if not finisher_impact: finisher_target.set_execution_pose(elapsed/finisher_move.impact)
	var pose: Dictionary = FinisherMoves.pose(finisher_move, elapsed)
	right_arm.rotation = finisher_arm + pose.arm
	first_person_hands.rotation = finisher_hands + pose.hands
	first_person_hands.position = finisher_hand_position + pose.offset
	if not finisher_impact and elapsed >= finisher_move.impact:
		finisher_impact = true
		finisher_target.receive_damage(finisher_target.health * 2 + 1, self, character.item_at("main_hand").get("effect", ""), "melee")
		if finisher_target.dead:
			finisher_target.finisher_burst(finisher_move.motion, -global_basis.z)
			var cue: String = {"alien":"finish_shell", "crystal":"finish_crystal", "furnace":"finish_furnace"}.get(finisher_target.finisher_surface(), "")
			if cue!="": get_parent().audio.sfx(cue)
			combat_feedback(finisher_move.name.to_upper() + " · " + finisher_target.title)
	if finisher_remaining <= 0:
		finisher_remaining = 0.001
		cancel_finisher()

func cancel_finisher() -> void:
	if finisher_remaining <= 0: return
	if is_instance_valid(finisher_target):
		finisher_target.execution_locked = false
		finisher_target.set_execution_pose(0)
	finisher_target = null; finisher_remaining = 0
	if is_instance_valid(right_arm): right_arm.rotation = finisher_arm
	if is_instance_valid(first_person_hands):
		first_person_hands.rotation = finisher_hands
		first_person_hands.position = finisher_hand_position
