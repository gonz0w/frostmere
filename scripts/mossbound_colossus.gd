extends "res://scripts/wild_creature.gd"
# Slam timers are transient; saved health determines the current phase.
const SLAM_RADIUS := 5.0
const SLAM_WARNING := 1.5
var slam_remaining := 0.0
var slam_cooldown := 5.0
var slam_origin := Vector3.ZERO
var slam_arms: Array[Node3D]=[]
var slam_recoil:=0.0
var warning: Node3D
var warning_material: StandardMaterial3D
var awakened: bool:
	get: return health <= maximum_health * 0.5

func _ready() -> void:
	species = "golem"
	super._ready()
	preload("res://scripts/refined_colossus.gd").build(self)
	if dead: _show_corpse()
	warning = Node3D.new(); adventure.add_child(warning); warning.hide()
	warning_material = StandardMaterial3D.new()
	warning_material.albedo_color = Color("ffb454")
	warning_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	for i in range(48):
		var marker := MeshInstance3D.new(); var mesh := BoxMesh.new()
		mesh.size = Vector3(.35,.09,.35); mesh.material = warning_material; marker.mesh = mesh
		var angle := TAU * i / 48.0
		marker.position = Vector3(cos(angle)*SLAM_RADIUS,0,sin(angle)*SLAM_RADIUS)
		warning.add_child(marker)

func start_slam() -> void:
	slam_origin = global_position
	slam_remaining = SLAM_WARNING; windup = 0; slam_recoil=0
	update_slam_pose()
	velocity = Vector3.ZERO
	warning.global_position = Vector3(slam_origin.x,0,slam_origin.z)
	for marker in warning.get_children():
		marker.position.y = adventure.world.Terrain.height_at(marker.global_position.x,marker.global_position.z) + .08
	warning.show()
	adventure.feedback = "Colossus ground slam · leave the amber ring!"; adventure.feedback_time = SLAM_WARNING

func cancel_slam() -> void:
	if slam_remaining > 0: slam_cooldown = maxf(slam_cooldown,2.0)
	slam_remaining = 0
	if is_instance_valid(warning): warning.hide()
	slam_recoil=0; update_slam_pose()

func resolve_slam() -> void:
	var p = adventure.world.player
	var offset: Vector3 = p.global_position - slam_origin
	if threatens_player() and Vector2(offset.x,offset.z).length() <= SLAM_RADIUS and absf(offset.y) < 2.5 and adventure.line_clear(slam_origin+Vector3.UP,p.global_position+Vector3.UP,self,p):
		# Area impact can be blocked but has no melee attacker to parry.
		p.receive_damage(48 if awakened else 36,slam_origin)
	preload("res://scripts/ground_slam_effect.gd").spawn(self,slam_origin)
	adventure.world.audio.sfx("hit")
	slam_cooldown = 4.0 if awakened else 7.0
	cooldown = 1.4
	cancel_slam()
	slam_recoil=.4; update_slam_pose()

func _physics_process(delta: float) -> void:
	if dead or not adventure.inside or adventure.world.player.paused or execution_locked:
		cancel_slam(); super._physics_process(delta); return
	slam_recoil=maxf(0,slam_recoil-delta)
	if slam_remaining > 0:
		if not threatens_player() or stagger_time > 0:
			cancel_slam()
		else:
			slam_remaining = maxf(0,slam_remaining-delta)
			update_slam_pose()
			label.text = "Mossbound Colossus · GROUND SLAM!"; label.modulate = Color("ffb454")
			warning_material.albedo_color = Color("ffb454").lerp(Color("ff563f"),1.0-slam_remaining/SLAM_WARNING)
			velocity.x = 0; velocity.z = 0; velocity.y -= 18*delta; move_and_slide()
			if slam_remaining <= 0: resolve_slam()
			return
	slam_cooldown = maxf(0,slam_cooldown-delta)
	var p = adventure.world.player
	if slam_cooldown <= 0 and windup <= 0 and stagger_time <= 0 and threatens_player() and global_position.distance_to(p.global_position) < 7 and adventure.line_clear(global_position+Vector3.UP,p.global_position+Vector3.UP,self,p):
		start_slam(); return
	super._physics_process(delta)
	update_slam_pose()
	_update_label()
	if awakened and not dead: label.text = "Awakened · " + label.text

func parried() -> void:
	super.parried()
	cancel_slam()

func _show_corpse() -> void:
	cancel_slam()
	super._show_corpse()
	preload("res://scripts/creature_presentation.gd").corpse(self,"colossus")

func _exit_tree() -> void:
	if is_instance_valid(warning): warning.queue_free()

func update_slam_pose() -> void:
	if dead: return
	if execution_locked:
		preload("res://scripts/creature_presentation.gd").execution(self,"colossus"); return
	var tension: float=clampf(1-slam_remaining/SLAM_WARNING,0,1) if slam_remaining>0 else 0
	var impact: float=slam_recoil/.4
	rig.rotation.x=-.22*tension-.12*impact
	rig.position.y=-.2*impact
	for arm in slam_arms:
		arm.rotation.x=2.2*tension+.35*impact
		arm.position.y=3.35-.65*impact

func update_execution_pose() -> void:
	cancel_slam()
	preload("res://scripts/creature_presentation.gd").execution(self,"colossus")
func defeat_duration() -> float: return .9
