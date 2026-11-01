extends "res://scripts/enemy.gd"
var legs: Array[Node3D]=[]
var plates: Array[Node3D]=[]
var exposed := 0.0
var core: MeshInstance3D
var mandibles: Array[Node3D]=[]
var charge: MeshInstance3D
var spit_recoil := 0.0
func piece(parent: Node3D, at: Vector3, size: Vector3, color: Color) -> MeshInstance3D:
	var node:=MeshInstance3D.new(); var mesh:=BoxMesh.new(); mesh.size=size
	var material:=StandardMaterial3D.new(); material.albedo_color=color
	mesh.material=material; node.mesh=mesh; node.position=at; parent.add_child(node); return node
func _ready() -> void:
	super._ready()
	rig.queue_free(); rig=Node3D.new(); add_child(rig)
	var shape: CollisionShape3D=get_child(0)
	shape.shape.radius=1.3; shape.shape.height=3.6; shape.position.y=1.8
	preload("res://scripts/refined_shell_creatures.gd").build(self,"hull")
	label.position.y=3.9
	if dead: _show_corpse()
func receive_damage(amount: float, source: Node=null, effect: String="", skill: String="", critical: bool=false) -> void:
	super.receive_damage(amount*(1.5 if exposed>0 else .65),source,effect,skill,critical)
func _physics_process(delta: float) -> void:
	visible=adventure.inside; collision_layer=4 if adventure.inside and not dead else 0
	if dead or not adventure.inside or adventure.world.player.paused or execution_locked or not adventure.can_damage_enemy(enemy_id):
		windup=0; exposed=0; spit_recoil=0; update_shell(); return
	var p=adventure.world.player
	exposed=maxf(0,exposed-delta); cooldown=maxf(0,cooldown-delta); stagger_time=maxf(0,stagger_time-delta)
	spit_recoil=maxf(0,spit_recoil-delta)
	velocity.x=0; velocity.z=0
	var offset: Vector3=p.global_position-global_position; offset.y=0
	var clear: bool=adventure.line_clear(global_position+Vector3.UP*2,p.global_position+Vector3.UP,self,p)
	if stagger_time<=0 and offset.length()<21 and clear:
		rotation.y=atan2(-offset.x,-offset.z)
		if windup>0:
			windup=maxf(0,windup-delta)
			if windup<=0:
				adventure.fire(global_position+Vector3.UP*2,(p.global_position+Vector3.UP-global_position-Vector3.UP*2).normalized(),26,true,self,true)
				exposed=3; cooldown=4.5; spit_recoil=.35
		elif exposed<=0:
			if offset.length()>11:
				var direction=offset.normalized(); velocity.x=direction.x*1.8; velocity.z=direction.z*1.8
			elif cooldown<=0: windup=1.1
	else: windup=0
	phase+=delta*Vector2(velocity.x,velocity.z).length()*3
	velocity.y-=18*delta; move_and_slide(); update_shell()
func update_shell() -> void:
	if dead:
		charge.hide(); return
	for i in range(plates.size()): plates[i].position.x=(-1 if i==0 else 1)*(.95 if exposed>0 else .4)
	update_pose()
	_update_label()
	if exposed>0: label.text="HULLCARVER · CORE EXPOSED!"; label.modulate=Color("80f2a8")
	elif windup>0: label.text="HULLCARVER · PLASMA SPIT!"; label.modulate=Color("ffb454")
	else: label.text+=" · Armored"; label.modulate=Color("c6d7df")

func update_pose() -> void:
	var preparing: bool=windup>0
	var tension: float=clampf(1-windup/1.1,0,1) if preparing else 0.0
	var recoil: float=spit_recoil/.35
	charge.visible=preparing
	charge.scale=Vector3.ONE*(.3+tension*.9)
	charge.rotation=Vector3(tension*1.4,tension*2.1,0)
	for i in range(mandibles.size()):
		mandibles[i].rotation.y=(-1 if i==0 else 1)*(.08+tension*.42+recoil*.18)
	rig.position.y=-tension*.14
	rig.rotation.x=-tension*.06+recoil*.12
	for i in range(legs.size()):
		var side: float=-1 if i<4 else 1
		legs[i].rotation.z=side*tension*.15+sin(phase+i*PI)*.12*(1-tension)

	if execution_locked:
		rig.position.y=-.3*execution_progress; rig.rotation.x=.12*execution_progress
		for i in range(mandibles.size()): mandibles[i].rotation.y=(-1 if i==0 else 1)*.65*execution_progress

func update_execution_pose() -> void:
	windup=0; exposed=0; spit_recoil=0; update_shell()

func _show_corpse() -> void:
	super._show_corpse()
	if not is_instance_valid(charge): return # Base ready runs before the creature rig exists.
	windup=0; exposed=0; spit_recoil=0; charge.hide()
	charge.scale=Vector3.ONE; charge.rotation=Vector3.ZERO
	rig.rotation=Vector3.ZERO; rig.position=Vector3(0,-.85,0)
	for i in range(legs.size()): legs[i].rotation=Vector3(0,0,(-1 if i<4 else 1)*.9)
	for i in range(mandibles.size()): mandibles[i].rotation=Vector3(0,(-1 if i==0 else 1)*.55,0)
	for i in range(plates.size()): plates[i].position.x=(-1 if i==0 else 1)*.4

func finisher_surface() -> String: return "alien"

func defeat_duration() -> float: return 0.6
