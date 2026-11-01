extends Node3D
## Cached realm backdrop; inactive cavern geometry never leaks into nearby chapters.
const Blocks = preload("res://scripts/blocks.gd")
var sky: Sky
var embers: CPUParticles3D
func configure(id: String) -> void:
	name = "RealmAtmosphere"
	visible = false
	if id == "aeralis":
		sky = Sky.new()
		var material := ShaderMaterial.new()
		material.shader = preload("res://shaders/aeralis_sky.gdshader")
		sky.sky_material = material
		sky.radiance_size = Sky.RADIANCE_SIZE_256
		sky.process_mode = Sky.PROCESS_MODE_REALTIME
	else:
		_build_cavern()
func deactivate() -> void:
	hide()
	if embers != null: embers.emitting = false
func apply(env: Environment, id: String) -> void:
	visible = true
	if embers != null: embers.emitting = true
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	if id == "aeralis":
		env.background_mode = Environment.BG_SKY
		env.sky = sky
		env.fog_light_color = Color("7186ae")
		env.fog_density = .0025
	else:
		env.background_mode = Environment.BG_COLOR
		env.background_color = Color("211015")
		env.fog_light_color = Color("54251f")
		env.fog_density = .007
func _build_cavern() -> void:
	var b := Blocks.new()
	var rng := RandomNumberGenerator.new()
	rng.seed = 638421
	for pair in [["basalt","30272b"],["scoria","493034"],["hot","ff5419"]]:
		var mat: StandardMaterial3D = b.materials.stone.duplicate()
		mat.albedo_color = Color(pair[1])
		if pair[0] == "hot":
			mat.emission_enabled = true
			mat.emission = Color("ff4812")
			mat.emission_energy_multiplier = 2.0
		b.materials[pair[0]] = mat
	# Continuous dark shell behind staggered plates and recessed molten seams.
	b.add("basalt",Vector3(0,39,-20),Vector3(150,8,180))
	for x in range(-7,8):
		for z in range(-10,9):
			var p := Vector3(x*10,32+rng.randf_range(-2,2),z*10-20)
			b.add("hot",p+Vector3(0,1.8,0),Vector3(10.1,.35,10.1))
			b.add("scoria" if rng.randf()<.32 else "basalt",p,Vector3(rng.randf_range(9.1,9.7),3.5,rng.randf_range(9.0,9.7)))
			for ledge in range(3):
				b.add("scoria",p+Vector3(rng.randf_range(-3,3),-2.0-ledge*.3,rng.randf_range(-3,3)),Vector3(rng.randf_range(2,5),.65,rng.randf_range(2,5)))
			if rng.randf()<.4:
				var length := rng.randf_range(3,8)
				for step in range(5):
					var width := 3.5-float(step)*.61
					b.add("basalt",p+Vector3(1,-1.5-step*length/5,1),Vector3(width,length/5+.2,width))
	# Broken cliffs close the far horizon, well outside all traversable terraces.
	for side in [-1,1]:
		for z in range(-9,7):
			b.add("scoria",Vector3(side*rng.randf_range(57,64),12,z*10),Vector3(15,43,11))
	for x in range(-6,7):
		b.add("basalt",Vector3(x*10,12,-99),Vector3(11,46,14))
	b.finish(self)

	embers = CPUParticles3D.new()
	embers.name = "RisingEmbers"
	embers.amount = 80
	embers.lifetime = 16.0
	embers.preprocess = 12.0
	embers.position = Vector3(0,5,-20)
	embers.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	embers.emission_box_extents = Vector3(23,6,40)
	embers.direction = Vector3.UP
	embers.spread = 18.0
	embers.gravity = Vector3(0,.03,0)
	embers.initial_velocity_min = .4
	embers.initial_velocity_max = .8
	var mote := BoxMesh.new()
	mote.size = Vector3(.055,.10,.055)
	mote.material = b.materials.hot
	embers.mesh = mote
	embers.emitting = false
	add_child(embers)
