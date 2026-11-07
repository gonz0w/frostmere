extends Node3D
## A short playable prelude. Built only when needed, outside campaign geometry.
const ORIGIN := Vector3(0,0,600)
const LANTERN := Vector3(0,1,-4)
const EXIT := Vector3(0,0,-14)
const Blocks=preload("res://scripts/blocks.gd")
var static_batches: Dictionary={}
var material_cache: Dictionary={}
var world: Node3D
var active := false
var stage := 0
var reveal_time := 0.0
var scene: Node3D
var creature: Node3D
var head: Node3D
var jaw: Node3D
const REVEAL_DURATION := 8.0
var ward: MeshInstance3D
var light: OmniLight3D
var ash: Array[MeshInstance3D] = []
var overlay: CanvasLayer
var raw_subtitle:=""
var subtitle: Label
var heading: Label
var previous_environment: Environment
var sun: DirectionalLight3D
var sun_energy := 1.0
var previous_controls := true
var arrival: CanvasLayer
var arrival_cover: ColorRect
var arrival_time := 0.0

func cube(parent: Node3D, at: Vector3, size: Vector3, color: Color, glow: float=0) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	var shape := BoxMesh.new(); shape.size=size; mesh.mesh=shape
	var material := surface(color,glow)
	mesh.material_override=material; mesh.position=at; parent.add_child(mesh)
	return mesh

func surface(color: Color,glow: float) -> StandardMaterial3D:
	var key: String=color.to_html()+"_"+str(glow)
	if material_cache.has(key): return material_cache[key]
	var material=StandardMaterial3D.new(); material.albedo_color=color; material.roughness=1
	if glow==0:
		material.albedo_texture=world.blocks.materials.stone.albedo_texture
		material.texture_filter=BaseMaterial3D.TEXTURE_FILTER_NEAREST
		material.uv1_triplanar=true; material.uv1_world_triplanar=true
	else:
		material.emission_enabled=true; material.emission=color; material.emission_energy_multiplier=glow
	material_cache[key]=material
	return material
func static_cube(parent: Node3D,at: Vector3,size: Vector3,color: Color,glow: float=0) -> void:
	if not static_batches.has(parent):
		var batch=Blocks.new(); batch.spatial_batching=false; static_batches[parent]=batch
	var batch: RefCounted=static_batches[parent]
	var key: String=color.to_html()+"_"+str(glow)
	batch.materials[key]=surface(color,glow); batch.add(key,at,size)
func flush_static() -> void:
	for parent in static_batches: static_batches[parent].finish(parent)
	static_batches.clear()

func solid(at: Vector3, size: Vector3, surface: String="stone") -> void:
	var body := StaticBody3D.new(); body.position=at; body.set_meta("footstep",surface)
	var collider := CollisionShape3D.new(); var shape := BoxShape3D.new(); shape.size=size
	collider.shape=shape; body.add_child(collider); scene.add_child(body)

func build() -> void:
	world.controls.changed.connect(func():
		if is_instance_valid(subtitle): subtitle.text=world.controls.format_prompt(raw_subtitle))
	scene=Node3D.new(); scene.position=ORIGIN; add_child(scene)
	static_cube(scene,Vector3(0,-.35,-8),Vector3(24,.7,52),Color("667b88"))
	solid(Vector3(0,-.35,-4),Vector3(14,.7,36),"snow")
	for side in [-1,1]:
		solid(Vector3(side*7,4,-4),Vector3(2,8,36))
		for row in range(9):
			var z: float=12-row*4
			for tier in range(3):
				var height: float=2.5+fmod(row*.7+tier*.4,1.2)
				var at:=Vector3(side*(7.5+tier*.65),tier*2.6+height/2,z+sin(row*2.1)*.35)
				static_cube(scene,at,Vector3(3.1,height,4.25),Color("24323d") if tier%2==0 else Color("35424d"))
				static_cube(scene,at+Vector3(0,height/2+.06,0),Vector3(3.25,.16,4.3),Color("a8b9c3"))
			static_cube(scene,Vector3(side*5.7,.1,z),Vector3(1.3,.2,2.1+fmod(row*.6,1.3)),Color("9aabb2"))
			if row%2==0: pine(Vector3(side*(5.5+fmod(row*.3,.7)),0,z),3.4+fmod(row*.7,1.8))
	# Fractured cliff faces and short hanging ice lips, batched with the static scenery.
	for side in [-1,1]:
		for row in range(22):
			for tier in range(10):
				var at=Vector3(side*(6.05+sin(row*.9+tier)*.13),.4+tier*.65,11-row*1.3)
				static_cube(scene,at,Vector3(.26,.59,1.15),Color("344552") if (row+tier)%4 else Color("425360"))
			if row%3==0:
				for ice in range(3): static_cube(scene,Vector3(side*5.95,6.1-ice*.2,11-row*1.3+ice*.15),Vector3(.15,.7-ice*.12,.14),Color("91aebc"))
	# Shallow windblown streaks and broken masonry preserve the center route.
	for i in range(22):
		var side: float=-1 if i%2 else 1
		static_cube(scene,Vector3(side*(2.8+fmod(i*.71,1.4)),.025,10-i*1.1),Vector3(.5+fmod(i*.3,.8),.05,.8),Color("9baebc"))
	for i in range(7):
		var rubble := cube(scene,Vector3(-4.8+sin(i)*.6,.18,-9-i*.65),Vector3(.65,.36,.8),Color("4b525d"))
		rubble.rotation.y=i*.4

	solid(Vector3(0,4,14),Vector3(14,8,1))
	solid(Vector3(0,4,-18),Vector3(14,8,1))
	for side in [-1,1]:
		for row in range(12):
			static_cube(scene,Vector3(side*3.4,.3+row*.55,-15),Vector3(1.1,.52,1.5),Color("41454d"))
			if row%2==0: static_cube(scene,Vector3(side*3.4,.3+row*.55,-14.22),Vector3(.25,.3,.07),Color("de6948"),1.2)
	static_cube(scene,Vector3(0,6.9,-15),Vector3(8.2,.8,1.7),Color("41454d"))
	ward=cube(scene,Vector3(0,3.5,-17.8),Vector3(6.4,7,.08),Color("632b30"),.3)
	ward.material_override=ward.material_override.duplicate()
	ward.material_override.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
	ward.material_override.albedo_color=Color(.39,.17,.19,.2)
	for i in range(9): static_cube(scene,Vector3(-3+i*.75,3.5,-17.7),Vector3(.035,7,.04),Color("cf7460"),1)
	static_cube(scene,LANTERN-Vector3(0,.4,0),Vector3(.8,1.2,.8),Color("333844"))
	solid(LANTERN-Vector3(0,.4,0),Vector3(.8,1.2,.8))
	static_cube(scene,LANTERN+Vector3(0,.5,0),Vector3(.28,.4,.28),Color("e6ac67"),.6)
	for side in [-1,1]:
		for z in [-.2,.2]: static_cube(scene,LANTERN+Vector3(side*.2,.5,z),Vector3(.055,.65,.055),Color("252c35"))
	static_cube(scene,LANTERN+Vector3(0,.86,0),Vector3(.58,.13,.58),Color("303946"))
	static_cube(scene,LANTERN+Vector3(0,.96,0),Vector3(.65,.07,.64),Color("b8c6ce"))
	static_cube(scene,Vector3(-2.6,1,-12),Vector3(.16,2,.16),Color("4b3b32"))
	static_cube(scene,Vector3(-2.6,1.8,-12),Vector3(1.8,.6,.12),Color("544839"))
	var sign := Label3D.new(); sign.position=Vector3(-2.6,1.8,-11.9); sign.text="FROSTMERE\nKeep your name."; sign.font_size=24; sign.pixel_size=.007; sign.modulate=Color("e0c694"); scene.add_child(sign)
	light=OmniLight3D.new(); light.position=LANTERN+Vector3.UP; light.omni_range=17
	light.light_color=Color("e8a568"); light.light_energy=3; scene.add_child(light)
	creature=Node3D.new(); creature.position=Vector3(0,0,-29); scene.add_child(creature)
	creature.scale=Vector3.ONE*1.6
	preload("res://scripts/intro_sentinel.gd").build(self)
	creature.visible=false
	for i in range(56):
		ash.append(cube(scene,Vector3(sin(i*2.4)*6,1+fmod(i*.73,7),10-fmod(i*1.7,27)),Vector3(.06,.06,.06),Color("c0a8a0"),.25))
	flush_static()
	overlay=CanvasLayer.new(); overlay.layer=2; add_child(overlay)
	var layout := Control.new(); layout.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); layout.mouse_filter=Control.MOUSE_FILTER_IGNORE; overlay.add_child(layout)
	heading=Label.new(); heading.text="ASH THROUGH THE SNOW"; heading.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	heading.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE); heading.offset_top=95; heading.add_theme_font_size_override("font_size",27); layout.add_child(heading)
	subtitle=Label.new(); subtitle.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER; subtitle.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	subtitle.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE); subtitle.anchor_left=.12; subtitle.anchor_right=.88; subtitle.offset_left=0; subtitle.offset_right=0; subtitle.offset_top=-150; subtitle.offset_bottom=-35
	subtitle.add_theme_font_size_override("font_size",18); subtitle.add_theme_color_override("font_color",Color("ffe1b3")); layout.add_child(subtitle)

func start() -> bool:
	if active or world.player.character.intro_completed: return false
	if is_instance_valid(arrival): arrival.queue_free(); arrival=null
	active=true; stage=0; reveal_time=0
	build()
	var p: CharacterBody3D=world.player
	p.cancel_power(); p.cancel_finisher(); p.position=ORIGIN+Vector3(0,.1,8); p.velocity=Vector3.ZERO; p.rotation=Vector3.ZERO; p.pivot.rotation.x=-.08
	previous_environment=p.camera.environment
	var env := Environment.new(); env.background_mode=Environment.BG_COLOR; env.background_color=Color("101821")
	env.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR; env.ambient_light_color=Color("8cacc4"); env.ambient_light_energy=.65
	env.fog_enabled=true; env.fog_light_color=Color("1c2534"); env.fog_density=.012
	p.camera.environment=env
	for child in world.get_children():
		if child is DirectionalLight3D: sun=child; sun_energy=sun.light_energy; sun.light_energy=.08; break
	previous_controls=world.hud.controls.visible; world.hud.controls.hide()
	world.hud.notice_time=0
	_set_subtitle("The last road to Frostmere. Ash is falling through the snow.\nWASD · walk to the lantern. Mouse · look. E · inspect.\nTAB · skip opening")
	return true

func prompt() -> String:
	if stage==0 and world.player.position.distance_to(ORIGIN+LANTERN)<2.8: return "[ E ] Warm your hands at the ward lantern"
	if stage==2 and world.player.position.distance_to(ORIGIN+EXIT)<3: return "[ E ] Take the road to Frostmere"
	return ""

func interact() -> bool:
	if not active or world.player.paused or prompt().is_empty(): return false
	if stage==0:
		stage=1; reveal_time=0; heading.hide(); creature.show(); pose_reveal(); world.audio.sfx("ward_approach")
		_set_subtitle("Something moves beyond the ward. Too large for the road.\nThe stone is warm. The snow is not melting.\nTAB · skip opening")
	else: finish()
	return true

func advance(delta: float) -> void:
	if active: world.audio.sync_intro_cues(world.player.paused)
	if is_instance_valid(arrival): arrival.visible=not world.player.paused
	if is_instance_valid(arrival) and not world.player.paused:
		arrival_time=maxf(0,arrival_time-delta)
		arrival_cover.color.a=arrival_time/.75
		if arrival_time==0: arrival.queue_free(); arrival=null
	if active: overlay.visible=not world.player.paused
	if not active or world.player.paused: return
	for mote in ash:
		mote.position.y-=delta*.65
		if mote.position.y<.2: mote.position.y=8
	if stage==1:
		reveal_time+=delta
		pose_reveal()
		if reveal_time>=REVEAL_DURATION:
			stage=2; creature.hide(); light.light_energy=3; ward.scale.x=1
			world.audio.sfx("ward_holds")
			_set_subtitle("The shape withdraws. The ward holds—for now.\nA weathered sign: ‘Frostmere. If the road whispers, do not give it your name.’\nWalk to the arch. E · continue. TAB · skip opening")
	# The prelude has no combat or fall penalty; recover safely if displaced.
	if world.player.position.y < -2 or world.player.position.distance_to(ORIGIN)>60: world.player.respawn()

func pine(at: Vector3, height: float) -> void:
	static_cube(scene,at+Vector3.UP*height*.45,Vector3(.28,height*.9,.28),Color("382f31"))
	for tier in range(4):
		var width: float=2.2-tier*.44
		var center: Vector3=at+Vector3.UP*(height*.34+tier*.55)
		static_cube(scene,center,Vector3(width,.45,width*.8),Color("243e43"))
		static_cube(scene,center+Vector3.UP*.25,Vector3(width*.85,.13,width*.7),Color("9cabb7"))

func pose_reveal() -> void:
	var approach:=smoothstep(0.0,2.5,reveal_time)
	var retreat:=smoothstep(5.0,REVEAL_DURATION,reveal_time)
	creature.position=Vector3(sin(reveal_time*.8)*.2, -retreat*7, -40+approach*11-retreat*19)
	head.rotation=Vector3(-sin(approach*PI)*.1+retreat*.2,sin(reveal_time*.7)*.12,0)
	jaw.rotation.x=sin(clampf((reveal_time-2.5)/2.5,0,1)*PI)*.23
	light.light_energy=2.6+sin(reveal_time*5)*.4
	ward.scale.x=1+sin(reveal_time*4)*.018

func _process(delta: float) -> void: advance(delta)

func _unhandled_input(event: InputEvent) -> void:
	if active and not world.player.paused and event is InputEventKey and event.pressed and not event.echo and event.physical_keycode==KEY_TAB:
		finish(); get_viewport().set_input_as_handled()

func finish() -> void:
	if not active: return
	world.audio.sync_intro_cues(false, true)
	active=false
	world.player.camera.environment=previous_environment
	if is_instance_valid(sun): sun.light_energy=sun_energy
	world.hud.controls.visible=previous_controls
	scene.queue_free(); overlay.queue_free(); ash.clear(); material_cache.clear()
	world.player.position=world.player.spawn_point; world.player.velocity=Vector3.ZERO
	world.player.rotation=Vector3.ZERO; world.player.pivot.rotation.x=-.1
	world.player.character.intro_completed=true
	world.player.character._commit()
	world.hud.announce("Frostmere","Find Edda at the village forge. Tell her about the warm stone.")
	arrival=CanvasLayer.new(); arrival.layer=3; add_child(arrival)
	arrival_cover=ColorRect.new(); arrival_cover.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	arrival_cover.mouse_filter=Control.MOUSE_FILTER_IGNORE; arrival_cover.color=Color("101821")
	arrival.add_child(arrival_cover); arrival_time=.75

func _set_subtitle(text: String) -> void:
	raw_subtitle=text
	subtitle.text=world.controls.format_prompt(text)
