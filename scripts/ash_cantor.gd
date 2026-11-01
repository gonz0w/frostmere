extends "res://scripts/enemy.gd"
var legs: Array[Node3D]=[]
var wings: Array[Node3D]=[]
var dots: Array[Node3D]=[]
var wave: Node3D
var wave_origin:=Vector3.ZERO
var radius:=0.0
var ringing:=false
var hit:=false
func piece(parent: Node3D, at: Vector3, size: Vector3, color: Color) -> void:
	var n:=MeshInstance3D.new(); var mesh:=BoxMesh.new(); mesh.size=size
	var mat:=StandardMaterial3D.new(); mat.albedo_color=color
	if color==Color("ff793e"): mat.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
	mesh.material=mat; n.mesh=mesh; n.position=at; parent.add_child(n)
func _ready() -> void:
	super._ready()
	rig.queue_free(); rig=Node3D.new(); add_child(rig)
	var collision: CollisionShape3D=get_child(0)
	collision.shape.radius=1.3; collision.shape.height=3.8; collision.position.y=1.9
	preload("res://scripts/refined_cantor.gd").build(self)
	label.position.y=4.5
	wave=Node3D.new(); get_parent().add_child(wave); wave.hide()
	for i in range(40):
		var dot:=Node3D.new(); wave.add_child(dot); dots.append(dot)
		piece(dot,Vector3.ZERO,Vector3(.35,.15,.35),Color("ff793e"))
	if dead: _show_corpse()

func cancel_song() -> void:
	if windup>0 or ringing: cooldown=maxf(cooldown,2)
	windup=0; ringing=false; radius=0
	if is_instance_valid(wave): wave.hide()
func update_wave(value: float) -> void:
	for i in range(dots.size()):
		var angle:=TAU*i/dots.size()
		dots[i].position=Vector3(cos(angle)*value,.15,sin(angle)*value)
func begin_song() -> void:
	adventure.world.audio.warning_at("ash_warning",self)
	wave_origin=global_position; wave_origin.y=home.y
	wave.global_position=wave_origin; wave.show(); update_wave(8)
	windup=1.5; hit=false
	adventure.feedback="The Cantor inhales · retreat beyond the ring or jump the coming shockwave!"; adventure.feedback_time=1.5
func advance_wave(delta: float) -> void:
	var previous:=radius; radius=minf(8,radius+7*delta); update_wave(radius)
	var p=adventure.world.player; var offset: Vector3=p.global_position-wave_origin
	var distance:=Vector2(offset.x,offset.z).length()
	if not hit and distance<=8 and distance>=previous-.65 and distance<=radius+.65 and absf(offset.y)<.85 and adventure.line_clear(global_position+Vector3.UP,p.global_position+Vector3.UP,self,p):
		hit=true; p.receive_damage(40 if health<=maximum_health*.5 else 30,global_position)
	if radius>=8: ringing=false; wave.hide(); cooldown=4 if health<=maximum_health*.5 else 6
func _physics_process(delta: float) -> void:
	preload("res://scripts/creature_presentation.gd").live(self,"cantor")
	visible=adventure.inside; collision_layer=4 if adventure.inside and not dead else 0
	if dead or not adventure.inside or adventure.world.player.paused or execution_locked or not adventure.can_damage_enemy(enemy_id):
		cancel_song(); return
	cooldown=maxf(0,cooldown-delta); stagger_time=maxf(0,stagger_time-delta)
	velocity.x=0; velocity.z=0
	var p=adventure.world.player; var offset: Vector3=p.global_position-global_position; offset.y=0
	if stagger_time>0 or offset.length()>21: cancel_song()
	elif ringing: advance_wave(delta)
	elif windup>0:
		windup=maxf(0,windup-delta)
		if windup<=0:
			ringing=true; radius=0; update_wave(0); adventure.world.audio.sfx("enchant")
	elif adventure.line_clear(global_position+Vector3.UP*2,p.global_position+Vector3.UP,self,p):
		rotation.y=atan2(-offset.x,-offset.z)
		if offset.length()>7:
			var direction=offset.normalized(); velocity.x=direction.x*1.5; velocity.z=direction.z*1.5
		elif cooldown<=0: begin_song()
	phase+=delta*Vector2(velocity.x,velocity.z).length()*3
	for i in range(legs.size()): legs[i].rotation.x=sin(phase+i*PI)*.2
	for i in range(wings.size()): wings[i].rotation.z=(-1 if i==0 else 1)*(.3 if windup>0 else .1 if ringing else 0)
	velocity.y-=18*delta; move_and_slide(); _update_label()
	if windup>0: label.text="DISSONANT CANTOR · INHALE!"
	elif ringing: label.text="DISSONANT CANTOR · JUMP THE RING!"
	label.modulate=Color("ffb454") if windup>0 or ringing else Color("dfb3a7")
func _show_corpse() -> void:
	cancel_song(); super._show_corpse()
	preload("res://scripts/creature_presentation.gd").corpse(self,"cantor")
func _exit_tree() -> void:
	if is_instance_valid(wave): wave.queue_free()
func finisher_surface() -> String: return "furnace"

func update_execution_pose() -> void:
	cancel_song()
	preload("res://scripts/creature_presentation.gd").execution(self,"cantor")

func defeat_duration() -> float: return .7
