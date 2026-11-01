extends "res://scripts/enemy.gd"
var species := "wolf"
var bite_head: Node3D
var bite_jaw: Node3D
var bite_recoil:=0.0
var legs: Array[Node3D] = []
func piece(parent: Node3D, at: Vector3, size: Vector3, color: Color) -> void:
	var node := MeshInstance3D.new(); var mesh := BoxMesh.new(); mesh.size = size
	var material := StandardMaterial3D.new(); material.albedo_color = color; mesh.material = material
	node.mesh = mesh; node.position = at; parent.add_child(node)
func _ready() -> void:
	if species == "golem": role = "boss"
	health_override = 420 if species == "golem" else 85 if species == "boar" else 55
	super._ready()
	rig.queue_free(); rig = Node3D.new(); add_child(rig)
	var collision: CollisionShape3D = get_child(0)
	var capsule := CapsuleShape3D.new(); capsule.radius = 0.9 if species == "golem" else 0.4; capsule.height = 4.5 if species == "golem" else 1.3
	collision.shape = capsule; collision.position.y = capsule.height / 2
	var color := Color("788474") if species == "golem" else Color("685345") if species == "boar" else Color("9aafb7")
	if species == "golem":
		piece(rig,Vector3(0,2.65,0),Vector3(1.8,1.8,1),color)
		piece(rig,Vector3(0,3.95,0),Vector3(1,1,0.9),color)
		for side in [-1,1]:
			piece(rig,Vector3(side*1.2,2.5,0),Vector3(.65,2,.7),color.darkened(.15))
			piece(rig,Vector3(side*.5,.9,0),Vector3(.65,1.8,.75),color)
			piece(rig,Vector3(side*.23,4,-.47),Vector3(.18,.15,.08),Color("a6eb8b"))
		for i in range(9): piece(rig,Vector3((i%3-1)*.5,2.1+(i/3)*.45,-.54),Vector3(.25,.2,.12),Color("4b663d"))
	else:
		preload("res://scripts/refined_wildlife.gd").build(self)
	label.position.y = 4.8 if species == "golem" else 1.7
	if dead: _show_corpse()
func _physics_process(delta: float) -> void:
	visible = adventure.inside
	collision_layer = 4 if adventure.inside and not dead else 0
	if execution_locked and not dead and species in ["wolf","boar"]:
		preload("res://scripts/creature_presentation.gd").execution(self,species); return
	if dead or not adventure.inside or adventure.world.player.paused or execution_locked:
		if species in ["wolf","boar"]:
			windup=0; bite_recoil=0; update_bite_pose()
		return
	bite_recoil=maxf(0,bite_recoil-delta)
	var p = adventure.world.player
	cooldown -= delta; stagger_time = maxf(0, stagger_time-delta)
	if stagger_time > 0:
		velocity.x = 0; velocity.z = 0; velocity.y -= 18*delta; move_and_slide(); update_bite_pose(); return
	var offset: Vector3 = p.global_position-global_position; offset.y=0
	var hunting: bool = threatens_player()
	velocity.x=0; velocity.z=0
	if hunting and stagger_time<=0 and adventure.line_clear(global_position+Vector3.UP,p.global_position+Vector3.UP,self,p):
		rotation.y=atan2(-offset.x,-offset.z)
		var reach: float = 3.5 if species=="frostbeast" else 3.2 if species=="golem" else 1.9
		if windup>0:
			windup-=delta; label.modulate=Color("ffad63")
			if windup<=0:
				bite_recoil=.22
				if offset.length()<reach+.3: p.receive_damage(28 if species=="frostbeast" else 38 if species=="golem" else 20 if species=="boar" else 13,global_position,self)
				cooldown=2 if species=="golem" else 1.3
		elif offset.length()>reach:
			var direction=offset.normalized(); velocity.x=direction.x*(1.6 if species=="golem" else 3.1); velocity.z=direction.z*(1.6 if species=="golem" else 3.1)
		elif cooldown<=0: windup=1.2 if species=="golem" else .65
	else:
		windup=0
		if global_position.distance_to(home)>1:
			var direction=(home-global_position).normalized(); velocity.x=direction.x*2; velocity.z=direction.z*2
	if windup<=0: label.modulate=Color("d8b59a")
	phase+=delta*Vector2(velocity.x,velocity.z).length()*3
	for i in range(legs.size()): legs[i].rotation.x=sin(phase+(i%2)*PI)*.5
	velocity.y-=18*delta; move_and_slide(); update_bite_pose()

func threatens_player() -> bool:
	var p = adventure.world.player
	return adventure.inside and not dead and p.global_position.distance_to(home)<18 and not adventure.town_safe(p.position) and global_position.distance_to(p.global_position)<14

func finisher_surface() -> String: return "stone" if species == "golem" else "flesh"

func update_bite_pose() -> void:
	if dead or not is_instance_valid(bite_head): return
	var tension: float=clampf(1-windup/.65,0,1) if windup>0 else 0
	bite_head.position.z=-.82+tension*.1-bite_recoil*.5
	bite_head.rotation.x=.16*tension-bite_recoil*.3
	bite_jaw.rotation.x=-.55*tension if windup>0 else -.12*bite_recoil/.22

func _show_corpse() -> void:
	bite_recoil=0
	if is_instance_valid(bite_head):
		bite_head.position.z=-.82; bite_head.rotation=Vector3.ZERO; bite_jaw.rotation=Vector3.ZERO
	super._show_corpse()
	if species in ["wolf","boar"]: preload("res://scripts/creature_presentation.gd").corpse(self,species)

func update_execution_pose() -> void:
	if species in ["wolf","boar"]:
		windup=0; bite_recoil=0; update_bite_pose()
		preload("res://scripts/creature_presentation.gd").execution(self,species)
func defeat_duration() -> float: return .5 if species in ["wolf","boar"] else 0.0
