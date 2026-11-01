extends SceneTree
const Pines=preload("res://scripts/winter_pines.gd")
const Lanes=preload("res://scripts/wyrmkeep_detail.gd")
var checks:=0
var failures:=0
func check(ok: bool,label: String) -> void:
	checks+=1
	if not ok: failures+=1; push_error("FAIL "+label)
func _initialize() -> void:
	var total:=0
	for site in Pines.SITES:
		var parts: Array=Pines.pieces(site); total+=parts.size()+1
		check(parts==Pines.pieces(site),"Reproducible winter foliage")
		check(parts.size()<850 and parts.size()>100,"Bounded tree geometry")
		check(parts.filter(func(p): return p.key=="snow").size()>50,"Snow rests on branch clusters")
		var clear:=true
		for lane in Lanes.LANES:
			for i in range(lane.size()-1):
				if Geometry2D.get_closest_point_to_segment(Vector2(site.x,site.z),lane[i],lane[i+1]).distance_to(Vector2(site.x,site.z))<site.w*.34+1.65: clear=false
		check(clear,"Canopy clears paved lanes")
	print("WINTER_PINES_COMPLETE checks=%d failures=%d pieces=%d" % [checks,failures,total]); quit(1 if failures else 0)
