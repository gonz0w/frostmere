extends RefCounted
## Shared construction operations; authored proportions live in each family builder.
const Blocks=preload("res://scripts/blocks.gd")
static var palettes: Dictionary={}
static func batch(colors: Array) -> RefCounted:
	var id=str(colors)
	if not palettes.has(id):
		var mats={}; var keys=["hide","plate","trim","dark","eye","accent"]
		for i in range(keys.size()):
			var m=StandardMaterial3D.new(); m.albedo_color=Color(colors[i]); m.roughness=.87
			if keys[i]=="eye": m.emission_enabled=true; m.emission=m.albedo_color; m.emission_energy_multiplier=.4
			mats[keys[i]]=m
		palettes[id]=mats
	var v=Blocks.new(); v.materials=palettes[id]; v.spatial_batching=false
	return v
static func pivot(parent: Node3D, at: Vector3) -> Node3D:
	var n=Node3D.new(); n.position=at; parent.add_child(n); return n
static func taper(v: RefCounted, key: String, a: Vector3, b: Vector3, width: float, tip: float, steps: int=8) -> void:
	var step=(b-a)/steps
	for i in range(steps):
		var w=lerpf(width,tip,float(i)/maxi(1,steps-1))
		v.add(key,a+step*(i+.5),Vector3(absf(step.x)+w,absf(step.y)+w,absf(step.z)+w))
static func body(v: RefCounted, at: Vector3, length: float, widths: Array, heights: Array) -> void:
	for row in range(widths.size()):
		for tier in range(5):
			v.add("hide",at+Vector3(0,(tier-2)*float(heights[row])/5,row*length/(widths.size()-1)),Vector3(float(widths[row])*(1-absf(tier-2)*.13),float(heights[row])/5+.02,length/(widths.size()-1)+.02))
static func antler(v: RefCounted, at: Vector3, side: float, scale: float=1.0) -> void:
	var end=at+Vector3(side*.9,1.1,.2)*scale
	taper(v,"trim",at,end,.18*scale,.05*scale,12)
	for i in range(3):
		var base=at.lerp(end,.3+i*.25)
		taper(v,"trim",base,base+Vector3(side*.13,.45,-.32)*scale,.11*scale,.025*scale,6)
