extends "res://scripts/enemy.gd"
var legs: Array[Node3D]=[]
var plates: Array[Node3D]=[]
var exposed := 0.0
var claws: Array[Node3D]=[]
var aim:=Vector3.FORWARD
var core: MeshInstance3D
func piece(parent: Node3D, at: Vector3, size: Vector3, color: Color) -> MeshInstance3D:
	var node:=MeshInstance3D.new(); var mesh:=BoxMesh.new(); mesh.size=size
	var material:=StandardMaterial3D.new(); material.albedo_color=color
	mesh.material=material; node.mesh=mesh; node.position=at; parent.add_child(node); return node
func _ready() -> void:
	super._ready()
	rig.queue_free(); rig=Node3D.new(); add_child(rig)
	var shape: CollisionShape3D=get_child(0)
	shape.shape.radius=1.25; shape.shape.height=2.8; shape.position.y=1.4
	preload("res://scripts/refined_shell_creatures.gd").build(self,"crab")
	label.position.y=3.2
	if dead: _show_corpse()
func receive_damage(amount: float, source: Node=null, effect: String="", skill: String="", critical: bool=false) -> void:
	super.receive_damage(amount*(1.4 if exposed>0 else .8),source,effect,skill,critical)
func _physics_process(delta: float) -> void:
	preload("res://scripts/creature_presentation.gd").live(self,"crab")
	visible=adventure.inside; collision_layer=4 if adventure.inside and not dead else 0
	if dead or not adventure.inside or adventure.world.player.paused or execution_locked :
		windup=0; exposed=0; update_shell(); return
	var p=adventure.world.player
	exposed=maxf(0,exposed-delta); cooldown=maxf(0,cooldown-delta); stagger_time=maxf(0,stagger_time-delta)
	velocity.x=0; velocity.z=0
	var offset: Vector3=p.global_position-global_position; offset.y=0
	var clear: bool=adventure.line_clear(global_position+Vector3.UP*2,p.global_position+Vector3.UP,self,p)
	if stagger_time<=0 and offset.length()<21 and clear:
		rotation.y=atan2(-offset.x,-offset.z)
		if windup>0:
			windup=maxf(0,windup-delta)
			if windup<=0:
				for i in range(-1,2): adventure.world.adventure.fire(global_position+Vector3.UP*1.6,aim.rotated(Vector3.UP,i*.22),20,true,self,true,Color("8fd4cf"))
				exposed=2.5; cooldown=5
		elif exposed<=0:
			if offset.length()>11:
				var direction=offset.normalized(); velocity.x=direction.x*1.8; velocity.z=direction.z*1.8
			elif cooldown<=0:
				adventure.world.audio.warning_at("brine_warning",self)
				windup=1.4; aim=(p.global_position+Vector3.UP-global_position-Vector3.UP*1.6).normalized()
				adventure.feedback="Hull Warden draws brine · sidestep the volley, then strike its open shell!"; adventure.feedback_time=1.4
	else: windup=0
	phase+=delta*Vector2(velocity.x,velocity.z).length()*3
	for i in range(legs.size()): legs[i].rotation.z=sin(phase+i*PI)*.12
	velocity.y-=18*delta; move_and_slide(); update_shell()
func update_shell() -> void:
	if dead: return
	for i in range(claws.size()): claws[i].rotation.y=(-1 if i==0 else 1)*(.45 if windup>0 else -.3 if exposed>0 else 0)
	for i in range(plates.size()): plates[i].position.x=(-1 if i==0 else 1)*(.95 if exposed>0 else .4)
	if dead: return
	_update_label()
	if exposed>0: label.text="HULL WARDEN · SHELL OPEN!"; label.modulate=Color("80f2a8")
	elif windup>0: label.text="HULL WARDEN · BRINE VOLLEY!"; label.modulate=Color("ffb454")
	else: label.text+=" · Armored"; label.modulate=Color("c6d7df")

func finisher_surface() -> String: return "shell"

func update_execution_pose() -> void:
	windup=0; exposed=0; update_shell()
	preload("res://scripts/creature_presentation.gd").execution(self,"crab")
func _show_corpse() -> void:
	windup=0; exposed=0; update_shell(); super._show_corpse()
	preload("res://scripts/creature_presentation.gd").corpse(self,"crab")
func defeat_duration() -> float: return .65
