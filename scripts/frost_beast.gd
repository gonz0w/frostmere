extends "res://scripts/wild_creature.gd"
var charge_remaining := 0.0
var charge_warning := 0.0
var charge_cooldown := 4.0
var charge_direction := Vector3.ZERO
var charge_hit := false
var charge_head: Node3D
var charge_phase := 0.0
var frost_jaw: Node3D
func _ready() -> void:
	species="frostbeast"; role="boss"
	super._ready()
	maximum_health=540; health=0 if dead else maximum_health
	rig.scale=Vector3.ONE*2.4
	var shape: CollisionShape3D=get_child(0)
	shape.shape.radius=1.1; shape.shape.height=3.3; shape.position.y=1.65
	frost_jaw=preload("res://scripts/refined_frost_beast.gd").build(self)
	label.position.y=4.5; _update_label()
	if dead: _show_corpse()
func cancel_charge() -> void:
	if charge_warning>0 or charge_remaining>0: charge_cooldown=maxf(charge_cooldown,2)
	charge_warning=0; charge_remaining=0; velocity.x=0; velocity.z=0
	for leg in legs: leg.rotation.x=0
	update_charge_pose()
func _physics_process(delta: float) -> void:
	if dead or not adventure.inside or adventure.world.player.paused or execution_locked:
		cancel_charge(); super._physics_process(delta); return
	charge_cooldown=maxf(0,charge_cooldown-delta)
	if not threatens_player() or stagger_time>0: cancel_charge()
	if charge_warning>0:
		charge_warning=maxf(0,charge_warning-delta)
		charge_phase+=delta*12
		update_charge_pose()
		label.text="RIMEFANG · CHARGE! Sidestep!"; label.modulate=Color("ffb454")
		velocity=Vector3.ZERO
		if charge_warning<=0: charge_remaining=1.1
		return
	if charge_remaining>0:
		charge_remaining=maxf(0,charge_remaining-delta)
		charge_phase+=delta*18; update_charge_pose()
		velocity=charge_direction*10; velocity.y=-2; move_and_slide()
		var p=adventure.world.player
		if not charge_hit and global_position.distance_to(p.global_position)<3 and adventure.line_clear(global_position+Vector3.UP,p.global_position+Vector3.UP,self,p):
			charge_hit=true; p.receive_damage(44,global_position)
		if charge_remaining<=0 or is_on_wall():
			cancel_charge(); charge_cooldown=6; cooldown=2; stagger_time=1.2
		return
	var p=adventure.world.player
	if charge_cooldown<=0 and windup<=0 and stagger_time<=0 and threatens_player() and global_position.distance_to(p.global_position)>3.5 and adventure.line_clear(global_position+Vector3.UP,p.global_position+Vector3.UP,self,p):
		charge_direction=p.global_position-global_position; charge_direction.y=0; charge_direction=charge_direction.normalized()
		rotation.y=atan2(-charge_direction.x,-charge_direction.z)
		charge_warning=1.3; charge_hit=false; windup=0; charge_phase=0; update_charge_pose()
		adventure.feedback="Rimefang paws the ground · sidestep its charge!"; adventure.feedback_time=1.3
		return
	super._physics_process(delta); _update_label()
func _show_corpse() -> void:
	if is_instance_valid(frost_jaw): frost_jaw.rotation=Vector3.ZERO
	cancel_charge(); super._show_corpse()
	preload("res://scripts/creature_presentation.gd").corpse(self,"frost")

func update_charge_pose() -> void:
	if dead or not is_instance_valid(charge_head): return
	if execution_locked:
		preload("res://scripts/creature_presentation.gd").execution(self,"frost")
		charge_head.rotation.x=.25*execution_progress; return
	var tension: float=clampf(1-charge_warning/1.3,0,1) if charge_warning>0 else 0
	if is_instance_valid(frost_jaw):
		frost_jaw.rotation.x=-.22*tension if charge_warning>0 else -.15 if charge_remaining>0 else -.3*clampf(1-windup/.65,0,1) if windup>0 else 0.0
	charge_head.rotation.x=-.28*tension if charge_warning>0 else -.22 if charge_remaining>0 else 0.0
	rig.position.y=-.1*tension if charge_warning>0 else sin(charge_phase*2)*.025 if charge_remaining>0 else 0.0
	for i in range(legs.size()):
		if charge_remaining>0: legs[i].rotation.x=sin(charge_phase+(i%2)*PI)*.65
		elif charge_warning>0: legs[i].rotation.x=sin(charge_phase)*.22 if i==0 else -.1*tension

func update_execution_pose() -> void:
	cancel_charge()
	preload("res://scripts/creature_presentation.gd").execution(self,"frost")
	if is_instance_valid(charge_head): charge_head.rotation.x=.25*execution_progress
func defeat_duration() -> float: return .75
