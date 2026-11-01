extends "res://scripts/enemy.gd"
var legs: Array[Node3D]=[]
var warning: Node3D
var thorns: Node3D
var target:=Vector3.ZERO
var pending:=false
var eruption_time:=0.0
func piece(parent: Node3D,at: Vector3,size: Vector3,color: Color) -> void:
	var mesh:=BoxMesh.new(); mesh.size=size
	var material:=StandardMaterial3D.new(); material.albedo_color=color; mesh.material=material
	var n:=MeshInstance3D.new(); n.mesh=mesh; n.position=at; parent.add_child(n)
func _ready() -> void:
	super._ready()
	rig.queue_free(); rig=Node3D.new(); add_child(rig)
	var shape: CollisionShape3D=get_child(0)
	shape.shape.radius=1.1; shape.shape.height=3.6; shape.position.y=1.8
	preload("res://scripts/refined_woodland.gd").build(self)
	label.position.y=5.5
	warning=Node3D.new(); get_parent().add_child(warning); warning.hide()
	thorns=Node3D.new(); get_parent().add_child(thorns); thorns.hide()
	for i in range(24):
		var angle:=TAU*i/24
		piece(warning,Vector3(cos(angle)*2.6,.06,sin(angle)*2.6),Vector3(.28,.12,.28),Color("ccda71"))
	for i in range(9):
		piece(thorns,Vector3((i%3-1)*1.1,.65,(i/3-1)*1.1),Vector3(.3,1.3,.3),Color("79644a"))
	if dead: _show_corpse()
func cancel_roots() -> void:
	if pending: cooldown=maxf(cooldown,2)
	pending=false; windup=0; eruption_time=0
	if is_instance_valid(warning): warning.hide()
	if is_instance_valid(thorns): thorns.hide()
func begin_roots() -> void:
	adventure.world.audio.warning_at("root_warning",self)
	target=adventure.world.player.global_position; target.y=home.y+.03
	warning.global_position=target; warning.show(); pending=true; windup=1.5
	adventure.feedback="The Hollow Warden wakes the roots · leave the pale circle!"; adventure.feedback_time=1.5
func resolve_roots() -> void:
	var p=adventure.world.player; var offset: Vector3=p.global_position-target
	if Vector2(offset.x,offset.z).length()<=2.6 and absf(offset.y)<2.5 and adventure.line_clear(global_position+Vector3.UP*2,p.global_position+Vector3.UP,self,p):
		p.receive_damage(38 if health<=maximum_health*.5 else 28,global_position)
	pending=false; windup=0; warning.hide(); thorns.global_position=target; thorns.show(); eruption_time=.5
	cooldown=4 if health<=maximum_health*.5 else 6; adventure.world.audio.sfx("hit")
func _physics_process(delta: float) -> void:
	preload("res://scripts/creature_presentation.gd").live(self,"warden")
	var active: bool=adventure.inside
	visible=active; collision_layer=4 if active and not dead else 0
	if dead or not active or adventure.world.player.paused or execution_locked:
		cancel_roots(); return
	cooldown=maxf(0,cooldown-delta); stagger_time=maxf(0,stagger_time-delta)
	eruption_time=maxf(0,eruption_time-delta)
	if eruption_time<=0: thorns.hide()
	velocity.x=0; velocity.z=0
	var p=adventure.world.player; var offset: Vector3=p.global_position-global_position; offset.y=0
	if stagger_time>0 or offset.length()>20 or not adventure.can_damage_enemy(enemy_id): cancel_roots()
	elif pending:
		windup=maxf(0,windup-delta)
		if windup<=0: resolve_roots()
	elif adventure.line_clear(global_position+Vector3.UP*2,p.global_position+Vector3.UP,self,p):
		rotation.y=atan2(-offset.x,-offset.z)
		if offset.length()>12:
			var direction=offset.normalized(); velocity.x=direction.x*1.4; velocity.z=direction.z*1.4
		elif cooldown<=0: begin_roots()
	phase+=delta*Vector2(velocity.x,velocity.z).length()*3
	for i in range(legs.size()): legs[i].rotation.x=sin(phase+i*PI)*.2
	velocity.y-=18*delta; move_and_slide(); _update_label()
	if pending: label.text="HOLLOW WARDEN · ROOT ERUPTION!"
	label.modulate=Color("ccda71") if pending else Color("d8b59a")
func _show_corpse() -> void:
	cancel_roots(); super._show_corpse()
	preload("res://scripts/creature_presentation.gd").corpse(self,"warden")
func _exit_tree() -> void:
	if is_instance_valid(warning): warning.queue_free()
	if is_instance_valid(thorns): thorns.queue_free()
func finisher_surface() -> String: return "bark"

func update_execution_pose() -> void:
	cancel_roots()
	preload("res://scripts/creature_presentation.gd").execution(self,"warden")

func defeat_duration() -> float: return .7
