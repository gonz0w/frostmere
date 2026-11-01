extends Control
signal selected(kind: String, id: String)
const MAP_SIZE := Vector2(1100, 1000)
const INK := Color("e1dac0")
const GOLD := Color("d8bf80")
var atlas: RefCounted
var player: CharacterBody3D
var local_view := false
var show_factions := false
var show_quests := true
var show_roads := true
var selected_id := "frostmere"
var zoom := 1.0
var pan := Vector2.ZERO
var dragging := false
var drag_start := Vector2.ZERO
var drag_distance := 0.0
var textures: Dictionary = {}
var decoration: Array[Dictionary] = []
var region_polygons: Dictionary = {}
var cached_player := Vector3.INF
var font: Font

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	clip_contents = true
	font = ThemeDB.fallback_font
	custom_minimum_size = Vector2(320, 360)
	resized.connect(func(): _clamp_pan(); queue_redraw())
	_bake()
	atlas.changed.connect(queue_redraw)

func _bake() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 9068
	for region: Dictionary in atlas.data.regions:
		var points := PackedVector2Array()
		for point: Array in region.polygon:
			points.append(Vector2(point[0], point[1]))
		region_polygons[region.id] = points
	var world_image := Image.create(1100, 1000, false, Image.FORMAT_RGB8)
	world_image.fill(Color("183440"))
	var local_image := Image.create(1100, 1000, false, Image.FORMAT_RGB8)
	local_image.fill(Color("465e4b"))
	for y in range(0, 1000, 8):
		for x in range(0, 1100, 8):
			var p := Vector2(x + 4, y + 4)
			var shade := rng.randf_range(0.93, 1.04)
			for region: Dictionary in atlas.data.regions:
				if Geometry2D.is_point_in_polygon(p, region_polygons[region.id]):
					var color := Color(region.color) * shade
					world_image.fill_rect(Rect2i(x, y, 8, 8), color)
					if rng.randf() < 0.035:
						decoration.append({"point": p, "region": region.id})
					break
			var local_color := Color("537258") * shade
			if x >= 605 and x < 693:
				local_color = Color("416f83") * shade
			if y < 255 + sin(x * 0.015) * 35:
				local_color = Color("8b9c9d") * shade
			if (abs(x - 495) < 28 and y > 418 and y < 880) or (abs(y - 600) < 18 and x > 495 and x < 836) or (abs(x - 836) < 18 and y > 480 and y < 600):
				local_color = Color("b1a184") * shade
			local_image.fill_rect(Rect2i(x, y, 8, 8), local_color)
	textures.world = ImageTexture.create_from_image(world_image)
	textures.local = ImageTexture.create_from_image(local_image)

func base_scale() -> float:
	return minf(size.x / MAP_SIZE.x, size.y / MAP_SIZE.y) * 0.95

func map_to_screen(point: Vector2) -> Vector2:
	return size / 2 + pan + (point - MAP_SIZE / 2) * base_scale() * zoom

func screen_to_map(point: Vector2) -> Vector2:
	return MAP_SIZE / 2 + (point - size / 2 - pan) / (base_scale() * zoom)

static func local_point(position: Vector3) -> Vector2:
	return Vector2((position.x + 45) * 11, (position.z + 100) / 140.0 * 1000)

func set_local(value: bool) -> void:
	local_view = value
	selected_id = "trail" if value else "frostmere"
	reset_view()

func reset_view() -> void:
	zoom = 1.0
	pan = Vector2.ZERO
	queue_redraw()

func zoom_at(factor: float, screen_point: Vector2) -> void:
	var anchor := screen_to_map(screen_point)
	zoom = clampf(zoom * factor, 1.0, 4.0)
	pan = screen_point - size / 2 - (anchor - MAP_SIZE / 2) * base_scale() * zoom
	_clamp_pan()
	queue_redraw()

func _clamp_pan() -> void:
	var extent := (MAP_SIZE * base_scale() * zoom - size) / 2 + size * 0.15
	pan.x = clampf(pan.x, -maxf(0, extent.x), maxf(0, extent.x))
	pan.y = clampf(pan.y, -maxf(0, extent.y), maxf(0, extent.y))

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.pressed and event.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN]:
			zoom_at(1.15 if event.button_index == MOUSE_BUTTON_WHEEL_UP else 1.0 / 1.15, event.position)
			accept_event()
		elif event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				dragging = true
				drag_start = event.position
				drag_distance = 0.0
			else:
				dragging = false
				if drag_distance < 5:
					_pick(event.position)
			accept_event()
	elif event is InputEventMouseMotion and dragging:
		pan += event.relative
		drag_distance += event.relative.length()
		_clamp_pan()
		queue_redraw()
		accept_event()
	elif event is InputEventPanGesture:
		pan -= event.delta * 18
		_clamp_pan()
		queue_redraw()
		accept_event()
	elif event is InputEventMagnifyGesture:
		zoom_at(event.factor, event.position)
		accept_event()

func _pick(point: Vector2) -> void:
	if local_view and in_seal(): return
	if local_view and in_winter(): return
	if local_view and in_threshold(): return
	if local_view and in_convergence(): return
	if local_view and in_choir(): return
	if local_view and in_roots(): return
	if local_view and in_lens(): return
	if local_view and in_shore(): return
	if local_view and in_archive(): return
	if local_view and in_mountain(): return
	if local_view and in_realm(): return
	if local_view and player.position.y < -20:
		return
	if local_view:
		for site: Dictionary in atlas.data.local_sites:
			var p: Array = site.position
			if point.distance_to(map_to_screen(local_point(Vector3(p[0], p[1], p[2])))) < 16:
				selected_id = site.id
				selected.emit("site", site.id)
				queue_redraw()
				return
	else:
		for location: Dictionary in atlas.data.locations:
			if point.distance_to(map_to_screen(Vector2(location.point[0], location.point[1]))) < 16:
				selected_id = location.id
				selected.emit("location", location.id)
				queue_redraw()
				return
		var p := screen_to_map(point)
		for region: Dictionary in atlas.data.regions:
			if Geometry2D.is_point_in_polygon(p, region_polygons[region.id]):
				selected.emit("region", region.id)
				return

func _polyline(points: Array, color: Color, width: float) -> void:
	var transformed := PackedVector2Array()
	for p: Array in points:
		transformed.append(map_to_screen(Vector2(p[0], p[1])))
	draw_polyline(transformed, color, width, true)

func _label(point: Vector2, text: String, color: Color, font_size: int = 13, center: bool = false) -> void:
	var p := point
	if center:
		p.x -= font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x / 2
	draw_string_outline(font, p, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, 3, Color(0.04, 0.07, 0.08, 0.8))
	draw_string(font, p, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)

func _marker(point: Vector2, kind: String, tint: Color, chosen: bool) -> void:
	if chosen:
		draw_arc(point, 12, 0, TAU, 24, GOLD, 2, true)
	draw_circle(point, 8, Color("16282e"))
	if kind in ["town", "city", "hall", "forge"]:
		draw_rect(Rect2(point - Vector2(4, 1), Vector2(8, 6)), tint)
		draw_colored_polygon(PackedVector2Array([point + Vector2(-6, -1), point + Vector2(0, -6), point + Vector2(6, -1)]), tint)
	elif kind == "fort":
		draw_rect(Rect2(point - Vector2(5, 4), Vector2(10, 10)), tint)
		for x in [-4, 0, 4]:
			draw_rect(Rect2(point + Vector2(x - 1, -7), Vector2(2, 4)), tint)
	else:
		draw_colored_polygon(PackedVector2Array([point + Vector2(0, -6), point + Vector2(5, 0), point + Vector2(0, 6), point + Vector2(-5, 0)]), tint)

func _draw() -> void:
	if textures.is_empty():
		return
	draw_rect(Rect2(Vector2.ZERO, size), Color("10232c"))
	if local_view and in_seal():
		_draw_seal()
		return
	if local_view and in_winter():
		_draw_winter()
		return
	if local_view and in_threshold():
		_draw_threshold()
		return
	if local_view and in_convergence():
		_draw_convergence()
		return
	if local_view and in_choir():
		_draw_choir()
		return
	if local_view and in_roots():
		_draw_roots()
		return
	if local_view and in_lens():
		_draw_lens()
		return
	if local_view and in_shore():
		_draw_shore()
		return
	if local_view and in_archive():
		_draw_archive()
		return
	if local_view and in_mountain():
		_draw_mountain()
		return
	if local_view and in_realm():
		_draw_realm()
		return
	if local_view and player.position.y < -20:
		_draw_barrow()
		return
	var start := map_to_screen(Vector2.ZERO)
	var scaled := MAP_SIZE * base_scale() * zoom
	draw_texture_rect(textures.local if local_view else textures.world, Rect2(start, scaled), false)
	# A subtle navigational grid keeps the atlas readable at every zoom level.
	for x in range(0, 1101, 100):
		draw_line(map_to_screen(Vector2(x, 0)), map_to_screen(Vector2(x, 1000)), Color(1, 1, 1, 0.045))
	for y in range(0, 1001, 100):
		draw_line(map_to_screen(Vector2(0, y)), map_to_screen(Vector2(1100, y)), Color(1, 1, 1, 0.045))
	if local_view:
		_draw_local()
	else:
		_draw_world()
	_label(Vector2(size.x - 30, 26), "N", GOLD, 17, true)
	draw_line(Vector2(size.x - 30, 36), Vector2(size.x - 30, 65), GOLD, 2)
	draw_colored_polygon(PackedVector2Array([Vector2(size.x - 30, 32), Vector2(size.x - 35, 42), Vector2(size.x - 25, 42)]), GOLD)
	_label(Vector2(18, size.y - 18), "LOCAL SURVEY · meters" if local_view else "REGIONAL ATLAS · schematic distances", INK, 11)

func _draw_world() -> void:
	for region: Dictionary in atlas.data.regions:
		var outline := PackedVector2Array()
		for p: Vector2 in region_polygons[region.id]:
			outline.append(map_to_screen(p))
		outline.append(outline[0])
		draw_polyline(outline, Color(0.08, 0.13, 0.15, 0.4), 1, true)
	for feature: Dictionary in decoration:
		var p := map_to_screen(feature.point)
		var s := maxf(2, 5 * base_scale() * zoom)
		if feature.region in ["pineward", "amberweald", "westmere"]:
			draw_colored_polygon(PackedVector2Array([p + Vector2(0, -s), p + Vector2(-s * 0.6, s), p + Vector2(s * 0.6, s)]), Color(0.07, 0.18, 0.13, 0.3))
		elif feature.region in ["glassfen", "sunscar"]:
			draw_line(p, p + Vector2(s * 1.5, -s * 0.25), Color(0.15, 0.23, 0.20, 0.25), 1)
	for river: Array in atlas.data.rivers:
		_polyline(river, Color("294c62"), 4 * base_scale() * zoom + 1)
		_polyline(river, Color("75a5b1"), 1.5 * base_scale() * zoom)
	for spine: Array in atlas.data.mountain_spines:
		for i in range(spine.size() - 1):
			var a := Vector2(spine[i][0], spine[i][1])
			var b := Vector2(spine[i + 1][0], spine[i + 1][1])
			for j in range(5):
				var point := a.lerp(b, j / 5.0) + Vector2((j % 2) * 16, 0)
				var p := map_to_screen(point)
				var s := 13 * base_scale() * zoom
				draw_colored_polygon(PackedVector2Array([p + Vector2(-s, s * 0.65), p + Vector2(0, -s), p + Vector2(s, s * 0.65)]), Color("657b85"))
				draw_colored_polygon(PackedVector2Array([p + Vector2(-s * 0.38, -s * 0.38), p + Vector2(0, -s), p + Vector2(s * 0.38, -s * 0.38)]), Color("d3ded9"))
	if show_roads:
		for road: Dictionary in atlas.data.routes:
			var a: Array = atlas.locations[road.start].point
			var b: Array = atlas.locations[road.end].point
			draw_dashed_line(map_to_screen(Vector2(a[0], a[1])), map_to_screen(Vector2(b[0], b[1])), Color(0.90, 0.79, 0.54, 0.65), 1.5, 4, true)
	for region: Dictionary in atlas.data.regions:
		_label(map_to_screen(Vector2(region.label[0], region.label[1])), region.name.to_upper(), Color("e1e5d0"), 13, true)
	if show_factions:
		for faction: Dictionary in atlas.data.factions:
			var home: Dictionary = atlas.locations[faction.home]
			var p := map_to_screen(Vector2(home.point[0], home.point[1]))
			draw_circle(p, 45 * base_scale() * zoom, Color(Color(faction.color), 0.15))
			draw_arc(p, 45 * base_scale() * zoom, 0, TAU, 36, Color(faction.color), 1, true)
	for location: Dictionary in atlas.data.locations:
		var p := map_to_screen(Vector2(location.point[0], location.point[1]))
		var tint := GOLD if location.status == "playable" else Color("d4dad2")
		_marker(p, location.kind, tint, selected_id == location.id)
		var label: String = location.name
		if show_factions:
			var faction: Dictionary = atlas.factions[location.faction]
			if faction.home == location.id:
				label = faction.name
		_label(p + Vector2(11, 5), label, tint, 14)
		if show_quests:
			var count: int = atlas.quests_at(location.id).size()
			if count > 0:
				_label(p + Vector2(-8, -12), str(count), GOLD, 10, true)
	var home: Array = atlas.locations.frostmere.point
	var current := map_to_screen(Vector2(home[0] - 18, home[1] + 15))
	draw_circle(current, 4, Color("8ee3d0"))

func _draw_local() -> void:
	for tree: Dictionary in player.get_parent().tree_sites:
		var p := map_to_screen(local_point(tree.position))
		var radius: float = tree.height * 0.65 * base_scale() * zoom
		for tier in range(3):
			var r := radius * (1.0 - tier * 0.20)
			var tip := p + Vector2(0, -tier * radius * 0.35)
			draw_colored_polygon(PackedVector2Array([tip + Vector2(0, -r), tip + Vector2(-r * 0.65, r * 0.3), tip + Vector2(r * 0.65, r * 0.3)]), Color("2b483b") if tier < 2 else Color("73917c"))
	var fortress := map_to_screen(local_point(Vector3(1, 0, -88)))
	_marker(fortress, "fort", Color("8a9c9f"), false)
	_label(fortress + Vector2(0, -14), "Distant fortress · scenery", INK, 11, true)
	# Buildings use the same centers and footprints as the playable scene.
	for house in [[-10, -8, 8, 9], [-11, -28, 7, 9], [1, -45, 11, 13], [6, 6, 5, 6]]:
		var a := map_to_screen(local_point(Vector3(house[0] - house[2] / 2.0, 0, house[1] - house[3] / 2.0)))
		var b := map_to_screen(local_point(Vector3(house[0] + house[2] / 2.0, 0, house[1] + house[3] / 2.0)))
		draw_rect(Rect2(a, b - a), Color("403e35"))
		draw_rect(Rect2(a, b - a), Color("b7a07d"), false, 2)
	if atlas.waypoint != "":
		var target := map_to_screen(local_point(atlas.target_position()))
		draw_dashed_line(map_to_screen(local_point(player.position)), target, GOLD, 2, 6, true)
		_label(target + Vector2(0, -22), "WAYPOINT", GOLD, 10, true)
	for site: Dictionary in atlas.data.local_sites:
		var a: Array = site.position
		var p := map_to_screen(local_point(Vector3(a[0], a[1], a[2])))
		_marker(p, site.kind, GOLD if atlas.visits.has(site.id) else INK, selected_id == site.id)
		_label(p + Vector2(13, 5), site.name, INK, 13)
	for shop: Dictionary in player.character.shop_data.shops:
		if shop.position[0] > 100: continue
		var pos: Array = shop.position
		var marker := map_to_screen(local_point(Vector3(pos[0], pos[1], pos[2])))
		draw_circle(marker, 4, Color("e8bb68"))
		_label(marker + Vector2(10, -6), shop.name, Color("e8bb68"), 11)
	if "stonewake" in player.character.story_completed:
		var pass_marker := map_to_screen(local_point(player.get_parent().mountain.PASS))
		draw_circle(pass_marker, 5, GOLD)
		_label(pass_marker + Vector2(12, 4), "North pass · Wyrmkeep", GOLD, 12)
		var trail_marker := map_to_screen(local_point(player.get_parent().archive_chapter.TRAIL))
		draw_circle(trail_marker, 5, GOLD)
		_label(trail_marker + Vector2(-70, 18), "Pinehall trail", GOLD, 12)
	if "stonewake" in player.character.story_completed:
		var roots_marker:=map_to_screen(local_point(player.get_parent().roots.TRAIL)); draw_circle(roots_marker,5,GOLD)
		_label(roots_marker+Vector2(8,20),"Amberweald trail",GOLD,12)
	if "winter_siege" in player.character.story_completed:
		var seal_marker:=map_to_screen(local_point(player.get_parent().seal.TRAIL)); draw_circle(seal_marker,5,GOLD)
		_label(seal_marker+Vector2(5,-15),"Caldera service lift",GOLD,12)
	if "returning_light" in player.character.story_completed:
		var siege_marker:=map_to_screen(local_point(player.get_parent().winter.TRAIL)); draw_circle(siege_marker,5,GOLD)
		_label(siege_marker+Vector2(-100,15),"Northwatch siege",GOLD,12)
	if is_instance_valid(player.get_parent().convergence) and player.get_parent().convergence.ready_for_expedition():
		var expedition_marker:=map_to_screen(local_point(player.get_parent().convergence.TRAIL)); draw_circle(expedition_marker,5,GOLD)
		_label(expedition_marker+Vector2(-100,35),"Mirewatch expedition",GOLD,12)
	if "council" in player.character.story_completed:
		var choir_marker:=map_to_screen(local_point(player.get_parent().choir.TRAIL)); draw_circle(choir_marker,5,GOLD)
		_label(choir_marker+Vector2(-80,22),"Ash pilgrimage",GOLD,12)
	if "archive" in player.character.story_completed:
		var coast_marker := map_to_screen(local_point(player.get_parent().shore.TRAIL))
		draw_circle(coast_marker,5,GOLD)
		_label(coast_marker+Vector2(-40,18),"Coastal road · Saltbreak",GOLD,12)
		var lens_marker:=map_to_screen(local_point(player.get_parent().lens.TRAIL))
		draw_circle(lens_marker,5,GOLD)
		_label(lens_marker+Vector2(-65,20),"Sunken Lens expedition",GOLD,12)
	var story: Node3D = player.get_parent().stonewake
	if is_instance_valid(story) and player.character.adventure.rewarded:
		var keeper := map_to_screen(local_point(story.KEEPER))
		draw_circle(keeper, 5, Color("8ad7e6"))
		_label(keeper + Vector2(10, -8), "Ilyra", Color("8ad7e6"), 12)
		if player.character.stonewake.accepted and not player.character.stonewake.rewarded:
			for ward: Dictionary in story.WARDS:
				var marker := map_to_screen(local_point(ward.position))
				draw_circle(marker, 5, Color("8ad7e6") if ward.id in player.character.stonewake.wards else GOLD)
				_label(marker + Vector2(-90, -10), ward.name, INK, 11)
			var target := map_to_screen(local_point(story.target()))
			draw_dashed_line(map_to_screen(local_point(player.position)), target, Color("8ad7e6"), 2, 6, true)
	var point := map_to_screen(local_point(player.position))
	var direction := Vector2(-sin(player.rotation.y), -cos(player.rotation.y))
	var perpendicular := Vector2(-direction.y, direction.x)
	draw_colored_polygon(PackedVector2Array([point + direction * 9, point - direction * 5 + perpendicular * 5, point - direction * 5 - perpendicular * 5]), Color("93ebd5"))
	_label(point + Vector2(0, 21), "YOU", Color("93ebd5"), 10, true)

func _process(_delta: float) -> void:
	if is_visible_in_tree() and player.position != cached_player:
		cached_player = player.position
		queue_redraw()

func _barrow_point(x: float, z: float) -> Vector2:
	return map_to_screen(Vector2(250 + (x + 10) * 30, 100 + (z + 52) * 12))

func _draw_barrow() -> void:
	var top := _barrow_point(-10, -52)
	var end := _barrow_point(10, 12)
	draw_rect(Rect2(top, end - top), Color("283139"))
	draw_rect(Rect2(top, end - top), GOLD, false, 3)
	for z in [-10, -30]:
		draw_line(_barrow_point(-10, z), _barrow_point(-2.5, z), GOLD, 5)
		draw_line(_barrow_point(2.5, z), _barrow_point(10, z), GOLD, 5)
	for z in [1, -20, -42]:
		for x in [-6, 6]:
			draw_circle(_barrow_point(x, z), 8 * base_scale() * zoom, Color("aa9d7c"))
	_label(_barrow_point(0, -48), "THE CAPTAIN'S VAULT", GOLD, 15, true)
	_label(_barrow_point(0, -25), "EMBER GALLERY", INK, 13, true)
	_label(_barrow_point(0, -5), "SENTRY HALL", INK, 13, true)
	_label(_barrow_point(0, 11), "EXIT TO FROSTMERE", GOLD, 13, true)
	var p := _barrow_point(player.position.x, player.position.z)
	var direction := Vector2(-sin(player.rotation.y), -cos(player.rotation.y))
	var perpendicular := Vector2(-direction.y, direction.x)
	draw_colored_polygon(PackedVector2Array([p + direction * 9, p - direction * 5 + perpendicular * 5, p - direction * 5 - perpendicular * 5]), Color("93ebd5"))
	_label(p + Vector2(0, 20), "YOU", Color("93ebd5"), 11, true)
	_label(Vector2(18, 27), "OLDWATCH BARROW · underground", INK, 16)
	_label(Vector2(18, size.y - 18), "Doorways connect the three chambers. Return south to leave.", INK, 12)

func in_realm() -> bool:
	return is_instance_valid(player.get_parent().realms) and player.get_parent().realms.inside

func _realm_point(x: float, z: float) -> Vector2:
	return map_to_screen(Vector2(550 + x * 20, 100 + (z + 42) * 12))

func _draw_realm() -> void:
	var realm: Node3D = player.get_parent().realms
	for z in [13, -9, -32]:
		var a := _realm_point(-10, z - 8.5)
		var b := _realm_point(10, z + 8.5)
		draw_rect(Rect2(a, b-a), Color("59697d") if realm.current == "aeralis" else Color("754738"))
	for z in [2, -20]:
		var a := _realm_point(-2, z - 3.5)
		draw_rect(Rect2(a, _realm_point(2, z + 3.5)-a), GOLD)
	_label(_realm_point(0, -33), "GUARDIAN / RELIC", INK, 13, true)
	if realm.current=="crucible": _label(_realm_point(6,-38),"SHUTDOWN",GOLD,11,true)
	_label(_realm_point(0, -9), "SENTRIES", INK, 13, true)
	_label(_realm_point(0, 19), "RETURN GATE", GOLD, 13, true)
	_label(_realm_point(-6, 15), "ATTUNE", INK, 11, true)
	_label(_realm_point(7, 10), "CRAFT", INK, 11, true)
	var pos: Vector3 = player.position - realm.vector(realm.definitions[realm.current].origin)
	draw_circle(_realm_point(pos.x, pos.z), 6, Color("80e4df"))
	_label(Vector2(18, 27), realm.definitions[realm.current].name, INK, 16)

func in_mountain() -> bool:
	return is_instance_valid(player.get_parent().mountain) and player.get_parent().mountain.inside
func _mountain_point(p: Vector3) -> Vector2:
	return map_to_screen(Vector2(550 + p.x * 8, 130 + (p.z + 70) * 7))
func _draw_mountain() -> void:
	var town: Node3D = player.get_parent().mountain
	for house in [[-22,-14,12,12],[22,-14,12,12],[0,-33,16,16],[-18,14,9,10],[18,14,9,10]]:
		var a := _mountain_point(Vector3(house[0]-house[2]/2.0,0,house[1]-house[3]/2.0))
		var b := _mountain_point(Vector3(house[0]+house[2]/2.0,0,house[1]+house[3]/2.0))
		draw_rect(Rect2(a,b-a),Color("756d62"))
	for id: String in town.NODES:
		var p := _mountain_point(town.NODES[id])
		draw_circle(p,4,GOLD)
		_label(p+Vector2(7,-6),town.NAMES[id],INK,10)
	for shop: Dictionary in player.character.shop_data.shops:
		if shop.position[0]<100: continue
		var p := _mountain_point(Vector3(shop.position[0],shop.position[1],shop.position[2])-town.ORIGIN)
		draw_circle(p,4,Color("e8bb68"))
		_label(p+Vector2(-85,16),shop.name,GOLD,10)
	draw_circle(_mountain_point(player.position-town.ORIGIN),6,Color("8ee3d0"))
	_label(Vector2(18,27),"WYRMKEEP · mountain settlement",INK,16)

func in_archive() -> bool:
	return is_instance_valid(player.get_parent().archive_chapter) and player.get_parent().archive_chapter.inside
func _archive_point(p: Vector3) -> Vector2:
	return map_to_screen(Vector2(550+p.x*10,120+(p.z+75)*7))
func _draw_archive() -> void:
	var chapter: Node3D = player.get_parent().archive_chapter
	for h in [[-14,4,10,12],[14,4,10,12],[-23,26,8,9],[0,-50,21,44]]:
		var a := _archive_point(Vector3(h[0]-h[2]/2.0,0,h[1]-h[3]/2.0))
		var b := _archive_point(Vector3(h[0]+h[2]/2.0,0,h[1]+h[3]/2.0))
		draw_rect(Rect2(a,b-a),Color("465947"))
	for x in [-6,6]:
		draw_line(_archive_point(Vector3(x-3.5,0,-46)),_archive_point(Vector3(x+3.5,0,-46)),GOLD,3)
	for id: String in chapter.NODES:
		var p := _archive_point(chapter.NODES[id]); draw_circle(p,4,GOLD)
		_label(p+Vector2(8,-8),chapter.NAMES[id],INK,10)
	draw_circle(_archive_point(player.position-chapter.ORIGIN),6,Color("8ee3d0"))
	_label(Vector2(18,27),"PINEHALL · forest and ruined archive",INK,16)

func in_shore() -> bool:
	return is_instance_valid(player.get_parent().shore) and player.get_parent().shore.inside
func _shore_point(p: Vector3) -> Vector2:
	return map_to_screen(Vector2(360+p.x*8,70+(p.z+112)*5))
func _draw_shore() -> void:
	var chapter: Node3D=player.get_parent().shore
	var ocean_start:=_shore_point(Vector3(-45,0,-111))
	draw_rect(Rect2(ocean_start,_shore_point(Vector3(-18,0,55))-ocean_start),Color("28495b"))
	for h in [[34,20,10,12],[10,6,10,12],[41,42,9,10],[0,-38,14,36],[21,-83,28,42]]:
		var a:=_shore_point(Vector3(h[0]-h[2]/2.0,0,h[1]-h[3]/2.0))
		var b:=_shore_point(Vector3(h[0]+h[2]/2.0,0,h[1]+h[3]/2.0))
		draw_rect(Rect2(a,b-a),Color("4d636c"))
	for id: String in chapter.NODES:
		var p:=_shore_point(chapter.NODES[id]); draw_circle(p,4,GOLD)
		var offset:=Vector2(7,-5)
		if id=="forge": offset=Vector2(-65,18)
		elif id=="enchant": offset=Vector2(10,30)
		elif id=="salvager": offset=Vector2(-130,-10)
		_label(p+offset,chapter.NAMES[id],INK,9)
	draw_circle(_shore_point(player.position-chapter.ORIGIN),6,Color("8ee3d0"))
	_label(Vector2(18,27),"SALTBREAK · sea cave and fallen vessel",INK,16)

func in_lens() -> bool:
	return is_instance_valid(player.get_parent().lens) and player.get_parent().lens.inside
func _lens_point(p: Vector3) -> Vector2:
	return map_to_screen(Vector2(550+p.x*9,130+(p.z+78)*6))
func _draw_lens() -> void:
	var chapter: Node3D=player.get_parent().lens
	var center:=_lens_point(Vector3(0,0,-45))
	var outline:=PackedVector2Array()
	for segment in range(72):
		var angle: float=TAU*segment/72
		outline.append(_lens_point(Vector3(sin(angle)*22,0,-45+cos(angle)*22)))
	draw_colored_polygon(outline,Color("75664d"))
	for id: String in chapter.NODES:
		var p:=_lens_point(chapter.NODES[id]); draw_circle(p,4,GOLD)
		var offset:=Vector2(8,-8)
		if id=="forge": offset=Vector2(-65,20)
		if id=="enchant": offset=Vector2(8,32)
		_label(p+offset,chapter.NAMES[id],INK,10)
		if chapter.SOLUTIONS.has(id) and int(player.character.lens.rotations[id])==chapter.SOLUTIONS[id]: draw_line(p,center,Color("ead297"),2)
	draw_circle(_lens_point(player.position-chapter.ORIGIN),6,Color("8ee3d0"))
	if "convergence" in player.character.story_completed:
		var gate:=_lens_point(Vector3(-7,0,-62)); draw_circle(gate,5,GOLD); _label(gate+Vector2(8,-12),"First Threshold crossing",GOLD,10)
	_label(Vector2(18,27),"SUNKEN LENS · mirrors and guardian vault",INK,16)

func in_roots() -> bool:
	return is_instance_valid(player.get_parent().roots) and player.get_parent().roots.inside
func _roots_point(p: Vector3) -> Vector2:
	return map_to_screen(Vector2(550+p.x*10,100+(p.z+78)*6))
func _draw_roots() -> void:
	var chapter: Node3D=player.get_parent().roots
	for side in [-1,1]:
		for i in range(10): draw_circle(_roots_point(Vector3(side*34,0,28-i*10)),14,Color("73815c"))
	draw_line(_roots_point(Vector3(0,0,40)),_roots_point(Vector3(0,0,-69)),Color("ac9a71"),6)
	for id: String in chapter.NODES:
		var p:=_roots_point(chapter.NODES[id]); draw_circle(p,4,Color("8ee3a0") if id in player.character.roots.cleansed else GOLD)
		var offset:=Vector2(8,-8)
		if id=="keeper": offset=Vector2(-130,-8)
		if id=="enchant": offset=Vector2(-110,-8)
		if id=="alchemy": offset=Vector2(-120,20)
		if id=="forge": offset=Vector2(8,-12)
		if id=="steward": offset=Vector2(8,16)
		if id=="camp_cache": offset=Vector2(-65,22)
		_label(p+offset,chapter.NAMES[id],INK,10)
	draw_circle(_roots_point(player.position-chapter.ORIGIN),6,Color("8ee3d0"))
	_label(Vector2(18,27),"STAG SHRINE · blighted roots and woodland pact",INK,16)

func in_choir() -> bool:
	return is_instance_valid(player.get_parent().choir) and player.get_parent().choir.inside
func _choir_point(p: Vector3) -> Vector2:
	return map_to_screen(Vector2(550+p.x*10,100+(p.z+78)*6))
func _draw_choir() -> void:
	var chapter: Node3D=player.get_parent().choir
	for side in [-1,1]:
		var a:=_choir_point(Vector3(side*35-5,0,-76)); var b:=_choir_point(Vector3(side*35+5,0,22))
		draw_rect(Rect2(a,b-a),Color("a05740"))
	draw_line(_choir_point(Vector3(-16,0,-57)),_choir_point(Vector3(16,0,-57)),Color("78cbd5") if not player.character.choir.activated else Color("62736f"),3)
	for id: String in chapter.NODES:
		var p:=_choir_point(chapter.NODES[id]); draw_circle(p,4,Color("8ee3d0") if id in player.character.choir.song else GOLD)
		var offset:=Vector2(8,-8)
		if id=="keeper": offset=Vector2(-100,-8)
		if id=="forge": offset=Vector2(-70,20)
		if id=="enchant": offset=Vector2(8,20)
		_label(p+offset,chapter.NAMES[id],INK,10)
	draw_circle(_choir_point(player.position-chapter.ORIGIN),6,Color("8ee3d0"))
	_label(Vector2(18,27),"EMBER CALDERA · resonators and signal vault",INK,16)

func in_convergence() -> bool:
	return is_instance_valid(player.get_parent().convergence) and player.get_parent().convergence.inside
func _convergence_point(p: Vector3) -> Vector2:
	return map_to_screen(Vector2(550+p.x*10,100+(p.z+78)*6))
func _draw_convergence() -> void:
	var chapter: Node3D=player.get_parent().convergence
	for deck in [[0,24,56,34],[0,-12,10,60],[0,-50,46,46]]:
		var a:=_convergence_point(Vector3(deck[0]-deck[2]/2.0,0,deck[1]-deck[3]/2.0)); var b:=_convergence_point(Vector3(deck[0]+deck[2]/2.0,0,deck[1]+deck[3]/2.0))
		draw_rect(Rect2(a,b-a),Color("465951"))
	for id: String in chapter.NODES:
		var p:=_convergence_point(chapter.NODES[id]); draw_circle(p,4,Color("8ee3d0") if id in player.character.convergence.evidence else GOLD)
		var offset:=Vector2(8,-8)
		if id in ["roots","lens"]: offset=Vector2(-45,-18)
		if id in ["tides","choir"]: offset=Vector2(-35,20)
		if id=="keeper": offset=Vector2(-115,-5)
		if id=="forge": offset=Vector2(-70,20)
		if id=="enchant": offset=Vector2(8,20)
		if id=="supplies": offset=Vector2(-65,30)
		_label(p+offset,chapter.NAMES[id],INK,10)
	draw_circle(_convergence_point(player.position-chapter.ORIGIN),6,Color("8ee3d0"))
	_label(Vector2(18,27),"MIREWATCH · expedition briefing and calibration",INK,16)

func in_threshold() -> bool:
	return is_instance_valid(player.get_parent().threshold) and player.get_parent().threshold.inside
func _threshold_point(p: Vector3) -> Vector2:
	return map_to_screen(Vector2(550+p.x*14,100+(p.z+78)*6))
func _draw_threshold() -> void:
	var chapter: Node3D=player.get_parent().threshold
	var a:=_threshold_point(Vector3(-20,0,-83)); var b:=_threshold_point(Vector3(20,0,43)); draw_rect(Rect2(a,b-a),Color("3e5365"))
	for z in [8,-43]: draw_line(_threshold_point(Vector3(-20,0,z)),_threshold_point(Vector3(20,0,z)),Color("92c9d4"),2)
	for id: String in chapter.NODES:
		var p:=_threshold_point(chapter.NODES[id]); draw_circle(p,4,GOLD)
		var offset:=Vector2(8,-8)
		if id=="keeper": offset=Vector2(-105,-8)
		if id=="forge": offset=Vector2(-50,20)
		if id=="enchant": offset=Vector2(8,32)
		if id=="locker": offset=Vector2(-110,20)
		_label(p+offset,chapter.NAMES[id],INK,10)
	draw_circle(_threshold_point(player.position-chapter.ORIGIN),6,Color("8ee3d0"))
	_label(Vector2(18,27),"FIRST THRESHOLD · systems and command deck",INK,16)

func in_winter() -> bool:
	return is_instance_valid(player.get_parent().winter) and player.get_parent().winter.inside
func _winter_point(p: Vector3) -> Vector2:
	return map_to_screen(Vector2(550+p.x*10,100+(p.z+48)*7))
func _draw_winter() -> void:
	var chapter: Node3D=player.get_parent().winter
	var a:=_winter_point(Vector3(-31,0,-47)); var b:=_winter_point(Vector3(31,0,39)); draw_rect(Rect2(a,b-a),Color("63788a"))
	for side in [-1,1]: draw_line(_winter_point(Vector3(side*12,0,-8)),_winter_point(Vector3(side*30,0,-8)),GOLD,4)
	for id: String in chapter.NODES:
		var p:=_winter_point(chapter.NODES[id]); draw_circle(p,4,GOLD)
		var offset:=Vector2(8,-8)
		if id in ["keeper","ward"]: offset=Vector2(-135,-8)
		if id in ["forge","supplies"]: offset=Vector2(-70,20)
		_label(p+offset,chapter.NAMES[id],INK,10)
	draw_circle(_winter_point(player.position-chapter.ORIGIN),6,Color("8ee3d0"))
	_label(Vector2(18,27),"NORTHWATCH · defend the northern road",INK,16)

func in_seal() -> bool:
	return is_instance_valid(player.get_parent().seal) and player.get_parent().seal.inside
func _seal_point(p: Vector3) -> Vector2:
	return map_to_screen(Vector2(550+p.x*13,70+(p.z+70)*6))
func _draw_seal() -> void:
	var chapter: Node3D=player.get_parent().seal
	var a:=_seal_point(Vector3(-22,0,-69)); var b:=_seal_point(Vector3(22,0,39)); draw_rect(Rect2(a,b-a),Color("645346"))
	for z in [10,-27,-48]:
		for side in [-1,1]: draw_line(_seal_point(Vector3(side*6,0,z)),_seal_point(Vector3(side*22,0,z)),GOLD,3)
	for id: String in chapter.NODES:
		var p:=_seal_point(chapter.NODES[id]); draw_circle(p,4,GOLD)
		var offset:=Vector2(8,-8)
		if id in ["keeper","intake"]: offset=Vector2(-145,-8)
		if id in ["forge","supplies"]: offset=Vector2(-80,20)
		_label(p+offset,chapter.NAMES[id],INK,10)
	draw_circle(_seal_point(player.position-chapter.ORIGIN),6,Color("8ee3d0"))
	_label(Vector2(18,27),"CALDERA UNDERWORKS · contain the furnace",INK,16)
