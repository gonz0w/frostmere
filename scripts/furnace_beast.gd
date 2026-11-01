extends "res://scripts/enemy.gd"
var legs: Array[Node3D]=[]
var vent: Node3D
var vent_origin:=Vector3.ZERO
var vent_pending:=false
var exposed:=0.0
var shutters: Array[Node3D]=[]
var bellows: Array[Node3D]=[]
var jaw: Node3D
var impact_time:=0.0
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
	preload("res://scripts/refined_furnace_beast.gd").build(self)
	label.position.y=4.1
	vent=Node3D.new(); get_parent().add_child(vent); vent.hide()
	for i in range(24):
		var angle:=TAU*i/24
		piece(vent,Vector3(cos(angle)*2.8,0,sin(angle)*2.8),Vector3(.3,.1,.3),Color("ff793e"))
	piece(vent,Vector3.ZERO,Vector3(.8,.1,.8),Color("ff793e"))
	if dead: _show_corpse()
func update_shutters() -> void:
	for i in range(shutters.size()): shutters[i].position.x=(-1 if i==0 else 1)*(.95 if exposed>0 else .36)

func receive_damage(amount: float, source: Node=null, effect: String="", skill: String="", critical: bool=false) -> void:
	# Executions must remain lethal even when the heat shutters are closed.
	var multiplier: float=1.0 if execution_locked else 1.35 if exposed>0 else .6
	super.receive_damage(amount*multiplier,source,effect,skill,critical)

func cancel_vent() -> void:
	if vent_pending: cooldown=maxf(cooldown,2)
	vent_pending=false; windup=0
	if is_instance_valid(vent): vent.hide()
	impact_time=0; update_pose()
func begin_vent() -> void:
	exposed=0; update_shutters()
	vent_origin=adventure.world.player.global_position
	vent_origin.y=home.y+.08
	vent.global_position=vent_origin; vent.show(); vent_pending=true; windup=1.5
	update_pose()
	adventure.feedback="Furnace rupture · leave the burning circle!"; adventure.feedback_time=1.5
func resolve_vent() -> void:
	var p=adventure.world.player; var offset: Vector3=p.global_position-vent_origin
	if Vector2(offset.x,offset.z).length()<=2.8 and absf(offset.y)<2.5 and adventure.line_clear(global_position+Vector3.UP*2,p.global_position+Vector3.UP,self,p):
		p.receive_damage(46 if health<=maximum_health*.5 else 34,global_position)
	preload("res://scripts/monster_effect.gd").eruption(self,vent_origin)
	adventure.world.audio.sfx("hit"); cancel_vent(); cooldown=4 if health<=maximum_health*.5 else 6
	exposed=2.5; impact_time=.4; update_shutters(); update_pose()
	adventure.feedback="Furnace core exposed · strike now!"; adventure.feedback_time=2.5
func _physics_process(delta: float) -> void:
	var active: bool=adventure.inside and adventure.current=="crucible"
	visible=active; collision_layer=4 if active and not dead else 0
	if dead: return
	if not active or adventure.world.player.paused or execution_locked:
		exposed=0; update_shutters(); cancel_vent(); return
	exposed=maxf(0,exposed-delta); update_shutters()
	impact_time=maxf(0,impact_time-delta)
	cooldown=maxf(0,cooldown-delta); stagger_time=maxf(0,stagger_time-delta)
	velocity.x=0; velocity.z=0
	var p=adventure.world.player; var offset: Vector3=p.global_position-global_position; offset.y=0
	if stagger_time>0 or offset.length()>20: cancel_vent()
	elif vent_pending:
		windup=maxf(0,windup-delta)
		if windup<=0: resolve_vent()
	elif adventure.line_clear(global_position+Vector3.UP*2,p.global_position+Vector3.UP,self,p):
		rotation.y=atan2(-offset.x,-offset.z)
		if offset.length()>13:
			var direction=offset.normalized(); velocity.x=direction.x*1.5; velocity.z=direction.z*1.5
		elif cooldown<=0: begin_vent()
	phase+=delta*Vector2(velocity.x,velocity.z).length()*3
	update_pose()
	velocity.y-=18*delta; move_and_slide(); _update_label()
	if vent_pending: label.text="FURNACE MAW · RUPTURE!"; label.modulate=Color("ffb454")
	elif exposed>0: label.text="FURNACE MAW · CORE EXPOSED!"; label.modulate=Color("80f2a8")
	else: label.text+=" · Heat shutters closed"; label.modulate=Color("dfb3a7")
func update_pose() -> void:
	if dead or not is_instance_valid(jaw): return
	var tension: float=clampf(1-windup/1.5,0,1) if vent_pending else 0.0
	var impact: float=impact_time/.4
	jaw.rotation.x=-tension*.3-(.18 if exposed>0 else 0)
	rig.position.y=tension*.12-impact*.2
	rig.rotation.x=-tension*.06+impact*.1
	for bank in bellows:
		bank.scale.y=1+tension*.35+(.15 if exposed>0 else 0)
	for i in range(legs.size()):
		legs[i].rotation.x=sin(phase+i*PI)*.2*(1-tension)
		legs[i].rotation.z=(-1 if i<3 else 1)*(tension*.12+impact*.08)

	if execution_locked:
		rig.position.y=-.2*execution_progress; rig.rotation.x=.15*execution_progress
		jaw.rotation.x=-.5*execution_progress
		for bank in bellows: bank.scale.y=1+.2*execution_progress

func update_execution_pose() -> void:
	exposed=0; update_shutters(); cancel_vent()

func _show_corpse() -> void:
	exposed=0; update_shutters(); cancel_vent(); super._show_corpse()
	if not is_instance_valid(jaw): return
	rig.rotation=Vector3.ZERO; rig.position=Vector3(0,-.65,0)
	jaw.rotation=Vector3(-.4,0,0)
	for bank in bellows: bank.scale.y=.7
	for i in range(legs.size()): legs[i].rotation=Vector3(0,0,(-1 if i<3 else 1)*.9)
func _exit_tree() -> void:
	if is_instance_valid(vent): vent.queue_free()

func finisher_surface() -> String: return "furnace"

func defeat_duration() -> float: return 0.85
