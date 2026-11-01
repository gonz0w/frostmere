extends RefCounted
## Batches static cuboids by material into MultiMeshes. Blocks are visual geometry,
## not individual nodes. Collision is authored separately at structure scale.

var batches: Dictionary = {}
var materials: Dictionary = {}
var rng := RandomNumberGenerator.new()
var spatial_batching := true

func _init() -> void:
	rng.seed = 81632
	var palette := {
		"grass": Color("657553"), "grass_dark": Color("485d40"),
		"earth": Color("625647"), "stone": Color("7a8182"),
		"stone_dark": Color("515d65"), "path": Color("89877b"),
		"wood": Color("6c4c33"), "timber": Color("3f3027"),
		"roof": Color("525b57"), "snow": Color("d7e1dc"),
		"pine": Color("304d40"), "pine_light": Color("45604a"),
		"iron": Color("747d80"), "leather": Color("70503a"),
		"fur": Color("b2aa90"), "skin": Color("c69c79"),
		"cloth": Color("374c58"), "gold": Color("b79a5b"),
		"window": Color("f3b75e"), "coal": Color("252c2e")
	}
	for key: String in palette:
		var material := StandardMaterial3D.new()
		material.albedo_color = palette[key]
		material.roughness = 0.92
		material.vertex_color_use_as_albedo = true
		material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST_WITH_MIPMAPS
		if key not in ["window", "skin", "iron", "gold"]:
			material.albedo_texture = _texture(key)
			material.uv1_triplanar = true
			material.uv1_world_triplanar = true
			material.uv1_scale = Vector3(0.5, 0.5, 0.5)
			material.uv1_triplanar_sharpness = 16.0
		if key == "window":
			material.emission_enabled = true
			material.emission = Color("ffae49")
			material.emission_energy_multiplier = 1.0
		materials[key] = material

func _texture(key: String) -> ImageTexture:
	var img := Image.create(32, 32, false, Image.FORMAT_RGB8)
	for y in range(32):
		for x in range(32):
			var shade := rng.randf_range(0.82, 1.0)
			if key in ["wood", "timber"] and x % 4 == 0:
				shade *= 0.90
			img.set_pixel(x, y, Color(shade, shade, shade))
	img.generate_mipmaps()
	return ImageTexture.create_from_image(img)

func add(key: String, position: Vector3, size: Vector3, rotation_y: float = 0.0) -> void:
	# Small animated parts are culled as a unit. Splitting them at local x/z=0
	# creates extra draw batches without useful world-scale visibility savings.
	var batch_key := "%s@%d,%d" % [key, floori(position.x / 24.0) if spatial_batching else 0, floori(position.z / 24.0) if spatial_batching else 0]
	if not batches.has(batch_key):
		batches[batch_key] = []
	var basis := Basis(Vector3.UP, rotation_y).scaled(size)
	var tint := rng.randf_range(0.94, 1.04)
	batches[batch_key].append([Transform3D(basis, position), Color(tint, tint, tint)])

func finish(parent: Node3D) -> int:
	var count := 0
	for key: String in batches:
		var mesh := BoxMesh.new()
		mesh.size = Vector3.ONE
		mesh.material = materials[key.get_slice("@", 0)]
		var multi := MultiMesh.new()
		multi.transform_format = MultiMesh.TRANSFORM_3D
		multi.use_colors = true
		multi.mesh = mesh
		multi.instance_count = batches[key].size()
		for i in range(multi.instance_count):
			multi.set_instance_transform(i, batches[key][i][0])
			multi.set_instance_color(i, batches[key][i][1])
		var instance := MultiMeshInstance3D.new()
		instance.name = "Blocks_" + key
		instance.multimesh = multi
		parent.add_child(instance)
		count += multi.instance_count
	batches.clear()
	return count

func piece(parent: Node3D, key: String, position: Vector3, size: Vector3) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh.material = materials[key]
	node.mesh = mesh
	node.position = position
	parent.add_child(node)
	return node
