extends RefCounted
## Small shared, deterministic textures: no external assets or per-frame updates.
static var textures: Dictionary = {}
static func apply(material: StandardMaterial3D, item: Dictionary) -> void:
	var family: String=item.get("family", "")
	var stock: String=item.get("material",family)
	var kind: String="weave" if family in ["cloth","fur"] else "leather" if family=="leather" else "metal"
	if not textures.has(kind):
		var img=Image.create(32,32,false,Image.FORMAT_RGB8)
		var rng=RandomNumberGenerator.new(); rng.seed=8319
		var patches: Array[float]=[]
		for i in range(64): patches.append(rng.randf_range(.82,1.0))
		for y in range(32):
			for x in range(32):
				var shade: float=patches[(y/4)*8+x/4]
				if kind=="weave": shade=.90 if (x+y)%2==0 else 1.0
				elif kind=="leather": shade=shade*.93 if (x*7+y*11)%23==0 else shade
				elif (x*13+y*3)%61==0: shade=1.0
				img.set_pixel(x,y,Color(shade,shade,shade))
		img.generate_mipmaps(); textures[kind]=ImageTexture.create_from_image(img)
	material.albedo_texture=textures[kind]
	material.texture_filter=BaseMaterial3D.TEXTURE_FILTER_NEAREST_WITH_MIPMAPS
	material.uv1_triplanar=false
	material.metallic=.25 if kind=="metal" and stock not in ["crystal","aether","wood"] else 0.0
