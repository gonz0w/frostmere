extends "res://scripts/enemy.gd"
var tail: Node3D
var legs: Array[Node3D]=[]
var warning: Node3D
var beam: Node3D
var target:=Vector3.ZERO
var aim:=Vector3.FORWARD
var pending:=false
var beam_time:=0.0
func piece(parent: Node3D,at: Vector3,size: Vector3,color: Color) -> void:
	var mesh:=BoxMesh.new(); mesh.size=size
	var material:=StandardMaterial3D.new(); material.albedo_color=color; mesh.material=material
	var n:=MeshInstance3D.new(); n.mesh=mesh; n.position=at; parent.add_child(n)
func _ready() -> void:
	super._ready()
	rig.queue_free(); rig=Node3D.new(); add_child(rig)
	var shape: CollisionShape3D=get_child(0)
	shape.shape.radius=1.2; shape.shape.height=3.4; shape.position.y=1.7
	preload("res://scripts/refined_shell_creatures.gd").build(self,"solar")
	label.position.y=4.7
	warning=Node3D.new(); get_parent().add_child(warning); warning.hide()
	beam=Node3D.new(); get_parent().add_child(beam); beam.hide()
	for side in [-1,1]:
		for i in range(24): piece(warning,Vector3(side*.8,.1,-i*.5),Vector3(.16,.1,.35),Color("f9db83"))
	for i in range(24): piece(beam,Vector3(0,.8,-i*.5),Vector3(.5,1.5,.45),Color("f9db83"))
	if dead: _show_corpse()
func cancel_beam() -> void:
	if pending: cooldown=maxf(cooldown,2)
	pending=false; windup=0; beam_time=0
	if is_instance_valid(warning): warning.hide()
	if is_instance_valid(beam): beam.hide()
func begin_beam() -> void:
	adventure.world.audio.warning_at("solar_warning",self)
	target=global_position; target.y=home.y
	aim=adventure.world.player.global_position-global_position; aim.y=0; aim=aim.normalized()
	warning.global_position=target; warning.rotation.y=atan2(-aim.x,-aim.z)
	warning.show(); pending=true; windup=1.4
	adventure.feedback="The Meridian Keeper aligns its tail · step sideways out of the beam path!"; adventure.feedback_time=1.4
func resolve_beam() -> void:
	var p=adventure.world.player; var offset: Vector3=p.global_position-target
	var along:=offset.dot(aim); var lateral:=absf(offset.x*aim.z-offset.z*aim.x)
	if along>=0 and along<=12 and lateral<=.8 and absf(offset.y)<2.3 and adventure.line_clear(global_position+Vector3.UP*2,p.global_position+Vector3.UP,self,p):
		p.receive_damage(44 if health<=maximum_health*.5 else 32,global_position)
	pending=false; windup=0; warning.hide(); beam.global_position=target; beam.rotation.y=warning.rotation.y; beam.show(); beam_time=.4
	cooldown=4 if health<=maximum_health*.5 else 6; adventure.world.audio.sfx("spell")
func _physics_process(delta: float) -> void:
	preload("res://scripts/creature_presentation.gd").live(self,"solar")
	var active: bool=adventure.inside
	visible=active; collision_layer=4 if active and not dead else 0
	if dead or not active or adventure.world.player.paused or execution_locked:
		cancel_beam(); return
	cooldown=maxf(0,cooldown-delta); stagger_time=maxf(0,stagger_time-delta)
	beam_time=maxf(0,beam_time-delta)
	if beam_time<=0: beam.hide()
	velocity.x=0; velocity.z=0
	var p=adventure.world.player; var offset: Vector3=p.global_position-global_position; offset.y=0
	if stagger_time>0 or offset.length()>20 or not adventure.can_damage_enemy(enemy_id): cancel_beam()
	elif pending:
		windup=maxf(0,windup-delta)
		if windup<=0: resolve_beam()
	elif adventure.line_clear(global_position+Vector3.UP*2,p.global_position+Vector3.UP,self,p):
		rotation.y=atan2(-offset.x,-offset.z)
		if offset.length()>12:
			var direction=offset.normalized(); velocity.x=direction.x*1.4; velocity.z=direction.z*1.4
		elif cooldown<=0: begin_beam()
	phase+=delta*Vector2(velocity.x,velocity.z).length()*3
	for i in range(legs.size()): legs[i].rotation.x=sin(phase+i*PI)*.2
	velocity.y-=18*delta; move_and_slide(); _update_label()
	if pending: label.text="MERIDIAN KEEPER · SOLAR LANCE!"
	label.modulate=Color("ccda71") if pending else Color("d8b59a")
func _show_corpse() -> void:
	cancel_beam(); super._show_corpse()
	preload("res://scripts/creature_presentation.gd").corpse(self,"solar")
func _exit_tree() -> void:
	if is_instance_valid(warning): warning.queue_free()
	if is_instance_valid(beam): beam.queue_free()
func finisher_surface() -> String: return "stone"

func update_execution_pose() -> void:
	cancel_beam()
	preload("res://scripts/creature_presentation.gd").execution(self,"solar")

func defeat_duration() -> float: return .7
