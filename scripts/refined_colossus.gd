extends RefCounted
const D=preload("res://scripts/creature_detail.gd")
const COLORS=["657169","8c9582","b1b2a0","374840","a6eb8b","506938"]
static func build(e: Node3D) -> void:
	for n in e.rig.get_children(): e.rig.remove_child(n); n.queue_free()
	e.slam_arms.clear(); e.legs.clear()
	var v=D.batch(COLORS)
	for tier in range(7):
		var width: float=[1.1,1.3,1.7,1.95,2.05,1.85,1.5][tier]
		for side in [-1.0,1.0]:
			v.add("hide" if tier%2 else "plate",Vector3(side*width*.26,1.7+tier*.24,0),Vector3(width*.49,.22,1.03+sin(tier)*.08))
			v.add("accent",Vector3(side*width*.29,1.83+tier*.24,-.42),Vector3(.32,.05,.29))
		v.add("eye",Vector3(sin(tier*1.7)*.13,1.72+tier*.24,-.535),Vector3(.07,.13,.035))
	for tier in range(4): v.add("hide",Vector3(0,3.62+tier*.23,0),Vector3(1.04-absf(tier-1)*.1,.21,.92))
	for side in [-1.0,1.0]:
		v.add("dark",Vector3(side*.24,4.03,-.49),Vector3(.36,.22,.07))
		v.add("eye",Vector3(side*.24,4.03,-.535),Vector3(.18,.065,.03))
		v.add("plate",Vector3(side*.24,4.23,-.46),Vector3(.43,.17,.21))
		for tier in range(3): v.add("accent",Vector3(side*.4,4.25+tier*.065,.05),Vector3(.26-tier*.04,.09,.6))
	v.add("dark",Vector3(0,3.69,-.49),Vector3(.52,.09,.05)); v.finish(e.rig)
	for side in [-1.0,1.0]:
		var arm=D.pivot(e.rig,Vector3(side*1.2,3.35,0)); e.slam_arms.append(arm); v=D.batch(COLORS)
		for tier in range(7):
			v.add("plate" if tier<2 else "hide",Vector3(side*.05,-tier*.27,0),Vector3(.83-absf(tier-3)*.06,.245,.8))
			v.add("accent",Vector3(side*.28,.10-tier*.27,.05),Vector3(.25,.07,.55))
		for finger in range(3): v.add("plate",Vector3((finger-1)*.23,-1.91,-.13),Vector3(.21,.38,.59))
		v.finish(arm)
		var leg=D.pivot(e.rig,Vector3(side*.5,.95,0)); e.legs.append(leg); v=D.batch(COLORS)
		for tier in range(5): v.add("hide" if tier%2 else "plate",Vector3(0,.65-tier*.3,0),Vector3(.7,.27,.73))
		v.add("plate",Vector3(0,-.79,-.16),Vector3(.8,.28,1.03)); v.finish(leg)
