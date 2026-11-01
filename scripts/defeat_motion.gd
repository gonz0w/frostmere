extends Node
# Only visual transforms interpolate. Defeat, collision removal and loot are immediate.
var actor: Node3D
var initial: Dictionary
var settled: Dictionary
var age:=0.0
var duration:=.7
var realm:=""
static func capture(node: Node3D) -> Dictionary:
	var poses: Dictionary={node:node.transform}
	for child in node.get_children():
		if child is Node3D: poses.merge(capture(child))
	return poses
static func start(target: Node3D, before: Dictionary, seconds: float) -> Node:
	var motion=load("res://scripts/defeat_motion.gd").new()
	motion.actor=target; motion.initial=before; motion.settled=capture(target.rig); motion.duration=seconds
	if target.adventure==target.adventure.world.realms: motion.realm=target.adventure.current
	motion.name="DefeatMotion"; target.add_child(motion); motion.apply(0)
	return motion
func apply(weight: float) -> void:
	for node in settled:
		if is_instance_valid(node): node.transform=settled[node] if weight>=1 else initial[node] if weight<=0 else initial[node].interpolate_with(settled[node],weight)
func _process(delta: float) -> void:
	if not is_instance_valid(actor): queue_free(); return
	if not actor.adventure.inside or (realm!="" and actor.adventure.current!=realm):
		apply(1); queue_free(); return
	if actor.adventure.world.player.paused: return
	age=minf(duration,age+delta)
	var t:=age/duration
	# Smooth acceleration into the fall, then ease into the resting silhouette.
	apply(t*t*(3-2*t))
	if age>=duration: queue_free()
