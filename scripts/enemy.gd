extends CharacterBody3D
const State = preload("res://scripts/character_state.gd")
const Visual = preload("res://scripts/character_visual.gd")
var adventure: Node3D
var enemy_id := ""
var role := "guard"
var title := "Barrow Guard"
var health := 60.0
var maximum_health := 60.0
var cooldown := 0.8
var windup := 0.0
var hurt_time := 0.0
var stagger_time := 0.0
var dead := false
var execution_locked := false
var execution_progress := 0.0
var rig: Node3D
var label: Label3D
var phase := 0.0
var home := Vector3.ZERO
var progress: Dictionary = {}
var armor_override := ""
var weapon_override := ""
var origin_override := ""
var health_override := 0.0

func _ready() -> void:
	collision_layer = 4
	collision_mask = 1 | 2 | 4
	floor_snap_length = 0.4
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.38
	capsule.height = 1.8
	var collision := CollisionShape3D.new()
	collision.shape = capsule
	collision.position.y = 0.9
	add_child(collision)
	var state := State.new()
	state.origin_id = origin_override if origin_override != "" else "dusk_elf"
	if progress.is_empty(): progress = adventure.state.adventure
	for slot: String in state.equipment:
		state.equipment[slot] = ""
	var armor := "cloth" if role == "mage" else "leather" if role == "archer" else "obsidian" if role == "boss" else "chain"
	if armor_override != "": armor = armor_override
	for slot in ["head", "chest", "hands", "legs", "feet"]:
		state.equip(state.add_item(armor + "_" + slot), slot)
	state.equip(state.add_item(weapon_override if weapon_override != "" else "iron_staff" if role == "mage" else "iron_bow" if role == "archer" else "oldwatch_oath" if role == "boss" else "iron_axe"), "main_hand")
	rig = Visual.new()
	add_child(rig)
	rig.build(state)
	if role == "boss":
		rig.scale *= 1.22
	maximum_health = 190 if role == "boss" else 46 if role in ["mage", "archer"] else 65
	if health_override > 0: maximum_health = health_override
	health = maximum_health
	home = global_position
	label = Label3D.new()
	label.position.y = 2.5 if role == "boss" else 2.15
	label.font_size = 24
	label.pixel_size = 0.008
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.modulate = Color("d8b59a")
	add_child(label)
	if enemy_id in progress.defeated:
		dead = true
		_show_corpse()
	_update_label()

func _update_label() -> void:
	label.text = title + (" — remains" if dead else "  %d / %d" % [ceili(health), maximum_health])
	label.visible = not dead or enemy_id not in progress.looted

func _show_corpse() -> void:
	collision_layer = 0
	collision_mask = 0
	rig.rotation.z = PI / 2
	rig.position.y = 0.22
	label.position.y = 0.8

func set_execution_pose(amount: float) -> void:
	execution_progress=clampf(amount,0,1)
	if not dead: update_execution_pose()

func update_execution_pose() -> void: pass

func defeat_duration() -> float: return 0.0

func receive_damage(amount: float, source: Node = null, effect: String = "", skill: String = "", critical: bool = false) -> void:
	if dead or not adventure.inside or adventure.world.player.paused:
		return
	if adventure.has_method("can_damage_enemy") and not adventure.can_damage_enemy(enemy_id):
		adventure.feedback=adventure.barrier_message() if adventure.has_method("barrier_message") else "The solar barrier protects the Meridian Keeper"; adventure.feedback_time=1.5; return
	adventure.world.audio.engage()
	adventure.world.audio.sfx("hit")
	critical = critical and source == adventure.world.player and skill in ["melee", "marksman"]
	if critical: amount *= 1.5
	var before_health:=health
	health = maxf(0, health - maxf(1, amount * (0.8 if role == "boss" else 1.0)))
	if source == adventure.world.player:
		source.record_combat("damage_dealt", before_health - health, enemy_id)
		if health <= 0: source.record_combat("kill")
	if source == adventure.world.player and skill in ["melee", "marksman", "magic"]:
		source.gain_power((before_health - health) * 0.25)
	var advanced:=false
	if source==adventure.world.player and skill!="": advanced=source.character.train(skill,maxi(1,floori(minf(before_health,before_health-health)/5.0)),false)
	hurt_time = 0.16
	adventure.feedback = ("Critical! %s · %d damage" if critical else "Hit %s · %d damage") % [title, ceili(amount * (0.8 if role == "boss" else 1.0))]
	adventure.feedback_time = 1.3
	if health <= 0:
		var initial: Dictionary = preload("res://scripts/defeat_motion.gd").capture(rig) if defeat_duration()>0 else {}
		dead = true
		if source == adventure.world.player and effect == "stamina_on_kill":
			source.stamina = minf(source.derived.stamina, source.stamina + 18)
			source.combat_feedback("Melee kill · 18 stamina restored")
		adventure.mark_defeated(enemy_id)
		_show_corpse()
		if not initial.is_empty(): preload("res://scripts/defeat_motion.gd").start(self, initial, defeat_duration())
	_update_label()
	if advanced: source.character._commit()

func parried() -> void:
	if dead: return
	windup = 0
	stagger_time = 0.35 if role == "boss" else 0.7
	cooldown = maxf(cooldown, stagger_time + 0.4)

func _physics_process(delta: float) -> void:
	if dead or not adventure.inside or adventure.world.player.paused:
		return
	if adventure.has_method("can_damage_enemy") and not adventure.can_damage_enemy(enemy_id): return
	if execution_locked:
		velocity = Vector3.ZERO
		return
	var player: CharacterBody3D = adventure.world.player
	cooldown -= delta
	hurt_time = maxf(0, hurt_time - delta)
	rig.scale.y = (1.22 if role == "boss" else 1.0) * (0.94 if hurt_time > 0 else 1.0)
	if stagger_time > 0:
		stagger_time = maxf(0, stagger_time - delta)
		windup = 0
		velocity.x = 0
		velocity.z = 0
		velocity.y -= 18 * delta
		rig.right_arm.rotation.x = 0.5
		label.modulate = Color("8de4f0")
		move_and_slide()
		return
	var offset := player.global_position - global_position
	offset.y = 0
	var distance := offset.length()
	var visible_target: bool = adventure.line_clear(global_position + Vector3.UP * 1.2, player.global_position + Vector3.UP * 1.0, self, player)
	velocity.x = 0
	velocity.z = 0
	if distance < 21 and visible_target:
		rotation.y = atan2(-offset.x, -offset.z)
		var ranged := role in ["mage", "archer"]
		var reach := 13.0 if ranged else 2.25 if role == "boss" else 1.8
		if windup > 0:
			windup -= delta
			rig.right_arm.rotation.x = -1.7
			label.modulate = Color("ffb36b")
			if windup <= 0:
				if ranged:
					var origin := global_position + Vector3.UP * 1.35
					adventure.fire(origin, (player.global_position + Vector3.UP - origin).normalized(), 17 if role == "mage" else 13, true, self, role == "mage")
				elif distance < reach + 0.45:
					player.receive_damage(27 if role == "boss" else 16, global_position, self)
				cooldown = 1.7 if ranged else 1.2 if role == "boss" else 1.35
		elif distance > reach:
			var direction := offset.normalized()
			velocity.x = direction.x * (2.1 if role == "boss" else 2.5)
			velocity.z = direction.z * (2.1 if role == "boss" else 2.5)
		elif cooldown <= 0:
			windup = 0.85 if role == "boss" else 0.65
	else:
		windup = 0
	if windup <= 0:
		label.modulate = Color("d8b59a")
		phase += delta * Vector2(velocity.x, velocity.z).length() * 2.5
		rig.left_leg.rotation.x = sin(phase) * 0.45
		rig.right_leg.rotation.x = -sin(phase) * 0.45
		rig.right_arm.rotation.x = 0
	velocity.y -= 18 * delta
	move_and_slide()

func finisher_surface() -> String: return "flesh"

func finisher_burst(motion: String = "crush", direction: Vector3 = Vector3.FORWARD) -> void:
	preload("res://scripts/finisher_effect.gd").spawn(self, motion, direction)
