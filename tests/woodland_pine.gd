extends SceneTree
const Pine=preload("res://scripts/woodland_pine.gd")
const Ground=preload("res://scripts/pinehall_terrain.gd")
func _initialize() -> void:
	var checks:=0; var failures:=0; var total:=0
	for site in Ground.tree_sites():
		var seed_value:=int(roundf(site.x*193+site.z*977))
		var parts: Array=Pine.pieces(site.w,seed_value); total+=parts.size()
		checks+=1
		if parts.size()>650 or parts.size()<100: failures+=1; push_error("Pine exceeds authored geometry budget")
		checks+=1
		if parts!=Pine.pieces(site.w,seed_value): failures+=1; push_error("Pine is not reproducible")
		var bounded:=true
		for part in parts:
			if absf(part.at.x)+part.size.x/2>site.w*.34 or absf(part.at.z)+part.size.z/2>site.w*.34 or part.at.y-part.size.y/2<1 or part.at.y>site.w*1.05: bounded=false
		checks+=1
		if not bounded: failures+=1; push_error("Foliage exceeds tree footprint or walking-height clearance")
	print("WOODLAND_PINE_COMPLETE checks=%d failures=%d pieces=%d trees=%d" % [checks,failures,total,Ground.tree_sites().size()])
	quit(1 if failures else 0)
