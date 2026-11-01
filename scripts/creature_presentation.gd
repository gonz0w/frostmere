extends RefCounted
## Visual-only reactions: collision, warning areas, damage and loot stay on the actor.
static func execution(e: Node3D, kind: String) -> void:
	if e.dead: return
	var t: float=e.execution_progress
	e.rig.position.y=-t*(.16 if kind in ["wolf","boar"] else .28)
	e.rig.rotation.x=t*(.14 if kind!="colossus" else -.18)
	for i in range(e.legs.size()): e.legs[i].rotation.z=(-1 if i<e.legs.size()/2 else 1)*t*.35
	if kind in ["wolf","boar"] and is_instance_valid(e.bite_jaw): e.bite_jaw.rotation.x=-.35*t
	if kind=="colossus":
		for arm in e.slam_arms: arm.rotation.x=-t*.28
	if kind=="solar" and is_instance_valid(e.tail): e.tail.rotation.x=.25*t
	if kind=="cantor":
		for i in range(e.wings.size()): e.wings[i].rotation.z=(-1 if i==0 else 1)*t*.6
static func corpse(e: Node3D, kind: String) -> void:
	e.rig.rotation=Vector3.ZERO
	e.rig.position.y=-.32 if kind in ["wolf","boar"] else -.7 if kind!="colossus" else -1.3
	e.rig.rotation.z=.55 if kind in ["wolf","boar"] else 0.0
	for i in range(e.legs.size()): e.legs[i].rotation=Vector3(0,0,(-1 if i<e.legs.size()/2 else 1)*.75)
	if kind=="colossus":
		e.rig.rotation.x=.22
		for arm in e.slam_arms: arm.rotation=Vector3(-.35,0,0); arm.position.y=2.8
	if kind=="cantor":
		for i in range(e.wings.size()): e.wings[i].rotation=Vector3(0,0,.65 if i==0 else -.65)
	if kind=="solar" and is_instance_valid(e.tail): e.tail.rotation=Vector3(.5,0,.3)
	if kind=="crab":
		for i in range(e.plates.size()): e.plates[i].position.x=(-1 if i==0 else 1)*.4
		for i in range(e.claws.size()): e.claws[i].rotation=Vector3(0,(-1 if i==0 else 1)*.5,0)
static func live(e: Node3D, kind: String) -> void:
	if e.dead: return
	if e.execution_locked: execution(e,kind); return
	var t: float=clampf(1-e.windup/1.5,0,1) if e.windup>0 else 0.0
	e.rig.position.y=-t*.10; e.rig.rotation.x=-t*.055
	if kind=="solar" and is_instance_valid(e.tail): e.tail.rotation.x=-t*.14
	if kind=="cantor":
		var throat=e.rig.get_node_or_null("Throat")
		if throat!=null: throat.scale=Vector3(1+t*.15,1+t*.20,1)
