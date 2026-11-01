extends "res://scripts/enemy.gd"
var wings: Array[Node3D]=[]
var shards: Array[Node3D]=[]
var aim := Vector3.FORWARD
var fractured := false
var attack_kind := "fan"
var head: Node3D
var bite_recoil:=0.0
var fan_recoil:=0.0
var jaw: Node3D
func _ready() -> void:
	super._ready()
	rig.queue_free(); rig=Node3D.new(); add_child(rig)
	var collision: CollisionShape3D=get_child(0)
	collision.shape.radius=1.15; collision.shape.height=3.4; collision.position.y=1.7
	preload("res://scripts/refined_crystal_wyrm.gd").build(self)
	label.position.y=4
	if dead: _show_corpse()
func begin_bite(offset: Vector3) -> void:
	attack_kind="bite"; aim=offset.normalized()
	rotation.y=atan2(-offset.x,-offset.z); windup=.9
	adventure.feedback="Prismwing draws back · sidestep the bite!"; adventure.feedback_time=.9

func resolve_bite() -> void:
	var p=adventure.world.player
	var offset: Vector3=p.global_position-global_position
	var flat:=Vector3(offset.x,0,offset.z)
	if flat.length()<=3.8 and absf(offset.y)<2.5 and aim.dot(flat.normalized())>.5 and adventure.line_clear(global_position+Vector3.UP*2,p.global_position+Vector3.UP,self,p):
		p.receive_damage(32,global_position,self)
	cooldown=2.4; attack_kind="fan"; bite_recoil=.25

func _physics_process(delta: float) -> void:
	var active: bool=adventure.inside and adventure.current=="aeralis"
	visible=active; collision_layer=4 if active and not dead else 0
	if dead or not active or adventure.world.player.paused or execution_locked:
		windup=0; attack_kind="fan"; bite_recoil=0; fan_recoil=0
		if not dead: update_pose()
		return
	if health>maximum_health*.5 and fractured:
		fractured=false; windup=0; attack_kind="fan"
		for shard in shards: shard.show()
	if health<=maximum_health*.5 and not fractured:
		fractured=true; windup=0; attack_kind="fan"; stagger_time=1.6; cooldown=2.5
		for i in [3,4,8,9]: shards[i].hide()
		adventure.feedback="The wyrm's crystal wings fracture · strike now!"; adventure.feedback_time=2
	bite_recoil=maxf(0,bite_recoil-delta)
	fan_recoil=maxf(0,fan_recoil-delta)
	cooldown=maxf(0,cooldown-delta); stagger_time=maxf(0,stagger_time-delta)
	var p=adventure.world.player; var offset: Vector3=p.global_position-global_position; offset.y=0
	velocity.x=0; velocity.z=0
	if stagger_time<=0 and offset.length()<20 and adventure.line_clear(global_position+Vector3.UP*2,p.global_position+Vector3.UP,self,p):
		if windup>0:
			windup=maxf(0,windup-delta)
			if windup<=0:
				if attack_kind=="bite": resolve_bite()
				else:
					for i in range(-1 if fractured else -2,2 if fractured else 3):
						adventure.fire(global_position+Vector3.UP*2,aim.rotated(Vector3.UP,i*.17),18,true,self,true)
					cooldown=3.5; fan_recoil=.3
		elif offset.length()>12:
			rotation.y=atan2(-offset.x,-offset.z); var direction=offset.normalized(); velocity.x=direction.x*1.5; velocity.z=direction.z*1.5
		elif cooldown<=0:
			if fractured and offset.length()<=4.5: begin_bite(offset)
			else:
				attack_kind="fan"
				aim=(p.global_position+Vector3.UP-global_position-Vector3.UP*2).normalized(); rotation.y=atan2(-offset.x,-offset.z); windup=1.2
	else: windup=0; attack_kind="fan"
	phase+=delta
	update_pose()
	velocity.y-=18*delta; move_and_slide()
	_update_label(); label.modulate=Color("ffc87a") if windup>0 else Color("cbd9f0")
	if windup>0: label.text="PRISMWING · BITE! Sidestep or retreat!" if attack_kind=="bite" else "PRISMWING · CRYSTAL FAN! Sidestep!"
	elif fractured: label.text+=" · Fractured wings"

func update_pose() -> void:
	var biting: bool=windup>0 and attack_kind=="bite"
	var fanning: bool=windup>0 and attack_kind=="fan"
	var tension: float=clampf(1-windup/(.9 if biting else 1.2),0,1) if windup>0 else 0.0
	head.rotation.x=(.12+tension*.15) if biting else -bite_recoil+fan_recoil*.18
	head.position.z=-1.6+(tension*.25 if biting else 0)-bite_recoil*.9
	jaw.rotation.x=-(.1+tension*.5) if biting else -.12*fan_recoil/.3
	rig.position.y=-tension*.1 if fanning else 0.0
	for i in range(wings.size()):
		var angle: float=.45+tension*.2 if biting else .18+tension*.35 if fanning else sin(phase*2)*.06-fan_recoil*.5
		wings[i].rotation.z=(-1 if i==0 else 1)*angle
	for i in range(shards.size()):
		shards[i].rotation.y=(-1 if i<5 else 1)*tension*.08*(1+i%5) if fanning else 0.0

	if execution_locked:
		rig.position.y=-.2*execution_progress
		head.rotation.x=.3*execution_progress; jaw.rotation.x=-.35*execution_progress
		for i in range(wings.size()): wings[i].rotation.z=(-1 if i==0 else 1)*.7*execution_progress

func update_execution_pose() -> void:
	windup=0; bite_recoil=0; fan_recoil=0; update_pose()

func finisher_surface() -> String: return "crystal"

func _show_corpse() -> void:
	super._show_corpse()
	if not is_instance_valid(jaw): return
	windup=0; bite_recoil=0; fan_recoil=0
	rig.rotation=Vector3.ZERO; rig.position=Vector3(0,-.5,0)
	head.position.z=-1.6; head.rotation=Vector3(-.25,0,.12); jaw.rotation=Vector3(-.15,0,0)
	for i in range(wings.size()): wings[i].rotation=Vector3(0,0,.48 if i==0 else -.58)
	for shard in shards: shard.rotation=Vector3.ZERO
	fractured=true
	for i in [3,4,8,9]: shards[i].hide()

func defeat_duration() -> float: return 0.75
