extends Control
## Brief impact feedback; never reveals enemies before an accepted hit.
var player: CharacterBody3D
var source_position:=Vector3.ZERO
var remaining:=0.0
var outcome:="HIT"
const COLORS={"HIT":Color("ff847a"),"BLOCK":Color("f4cf76"),"PARRY":Color("8ff0cb"),"GUARD BROKEN":Color("ff847a")}
func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	hide()
func show_impact(source: Vector3, result: String) -> void:
	if player.paused or player.health<=0: return
	source_position=source; outcome=result; remaining=.9
	show(); queue_redraw()
func clear() -> void:
	remaining=0; hide(); queue_redraw()
func direction() -> Vector2:
	var offset:=source_position-player.global_position; offset.y=0
	if offset.length_squared()<.01: return Vector2.ZERO
	var local:=player.global_basis.inverse()*offset
	return Vector2(local.x,local.z).normalized()
func _process(delta: float) -> void:
	if player.paused or player.health<=0:
		clear(); return
	remaining=maxf(0,remaining-delta)
	visible=remaining>0
	if visible: queue_redraw()
func _draw() -> void:
	if remaining<=0: return
	var center:=size*.5
	var tint: Color=COLORS.get(outcome,COLORS.HIT)
	tint.a=minf(1,remaining/.25)
	var facing:=direction()
	if facing!=Vector2.ZERO:
		var side:=Vector2(-facing.y,facing.x)
		var points:=PackedVector2Array([center+facing*83,center+facing*65+side*9,center+facing*65-side*9])
		draw_colored_polygon(points,tint)
		var border:=points.duplicate(); border.append(points[0])
		draw_polyline(border,Color(0,0,0,tint.a),2,true)
	var font:=ThemeDB.fallback_font
	var width:=font.get_string_size(outcome,HORIZONTAL_ALIGNMENT_LEFT,-1,14).x
	var at:=center+Vector2(-width*.5,112)
	draw_string_outline(font,at,outcome,HORIZONTAL_ALIGNMENT_LEFT,-1,14,3,Color(0,0,0,tint.a))
	draw_string(font,at,outcome,HORIZONTAL_ALIGNMENT_LEFT,-1,14,tint)
