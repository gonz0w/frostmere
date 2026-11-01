extends Node3D
const State=preload("res://scripts/character_state.gd")
const Visual=preload("res://scripts/character_visual.gd")
const Enemy=preload("res://scripts/enemy.gd")
const ORIGIN=Vector3(-1200,0,0)
const TRAIL=Vector3(-37,0,24)
var last_light: MeshInstance3D
var last_lamp: OmniLight3D
var last_ship: Node3D
var last_caption: Label3D
var ash_cargo: Node3D
const NODES={"light_keeper":Vector3(19,0,39),"light_record":Vector3(-12,0,16),"light_control":Vector3(-12,0,-10),"ash_factor":Vector3(4,0,40),"ash_reader":Vector3(12,0,44),"ash_hull":Vector3(-12,0,6),"ash_manifest":Vector3(-10,0,0),"charter":Vector3(8,0,34),"witness":Vector3(14,0,-42),"false_orders":Vector3(31,0,-40),"compact":Vector3(28,0,32),"registry":Vector3(16,0,32),"nameplate":Vector3(4,0,-16),"silver_net":Vector3(-9,0,26),"return":Vector3(22,0,44),"harbor":Vector3(34,0.25,24),"salvager":Vector3(10,0.25,10),"forge":Vector3(25,0,10),"enchant":Vector3(31,0,10),"coast_cache":Vector3(-2,0,-6),"pump":Vector3(0,0,-29),"cave_cache":Vector3(2,0,-48),"relay":Vector3(22,0,-48),"bulkhead":Vector3(21,0,-60),"log":Vector3(16,0,-76),"core":Vector3(24,0,-99),"navigation":Vector3(17,0,-92)}
const NAMES={"light_keeper":"Mara · Hallowcliff relief pilot","light_record":"The former keeper’s log","light_control":"Ruined fjord signal · ground controls","ash_factor":"Dockworker Brann · Ashport wreck","ash_reader":"Archivist Cerys · Ashen Choir","ash_hull":"The boat that would not burn","ash_manifest":"Heat-sealed cargo manifest","charter":"Saltbreak passage charter","witness":"Pilot Tamsin · harbor witness","false_orders":"False beacon orders","compact":"Arbiter Vessa · Tidemarch Compact","registry":"Harbor departure register","nameplate":"Scraped ship nameplate","silver_net":"Silver-laden fishing net","return":"Coastal road · Frostmere","harbor":"Keeper Sella · Saltbreak","salvager":"Neris · Iron Keel salvagers","forge":"Saltbreak forge","enchant":"Saltbreak rune table","coast_cache":"Shattered salvage chest","pump":"Sea-cave pressure pump","cave_cache":"Pressure-lock cache","relay":"Wreck power relay","bulkhead":"Sealed hull entrance","log":"Flight recorder","core":"The ship's power core","navigation":"Navigation cradle"}
const RELICS={"blade":{"part":"fractured_hilt","item":"tideglass_saber","name":"Tideglass Saber","source":"coast_cache"},"armor":{"part":"pressure_shell","item":"tideguard_shell","name":"Tideguard Cuirass","source":"cave_cache"},"focus":{"part":"clouded_lens","item":"signal_focus","name":"Signal Lens","source":"shore_6"}}
var world: Node3D
var state: RefCounted
var inside:=false
var enemies: Array[CharacterBody3D]=[]
var feedback:=""
var feedback_time:=0.0
var dialog: ColorRect
var title: Label
var description: Label
var options: VBoxContainer
var subject:=""
var preview_label: Label
var bulkhead: StaticBody3D
var core_mesh: MeshInstance3D
var beacon: MeshInstance3D
var nav_light: MeshInstance3D
var beacon_light: OmniLight3D
var environment_backup: Environment
var light_backup: Dictionary={}
var charter_label: Label3D
var witness: Node3D
var witness_label: Label3D
var ship_plate: Node3D
var silver_coins: Node3D
var silver_ledger: Node3D
func _ready() -> void:
	state=world.player.character; _build(); _ui(); state.changed.connect(_refresh); _refresh()
func box(p: Vector3,size: Vector3,key: String,solid: bool=false,surface: String="stone") -> void:
	world.blocks.add(key,ORIGIN+p,size)
	if solid: world._solid(ORIGIN+p,size,surface)
func _build() -> void:
	var b: RefCounted=world.blocks
	b.materials.shore_water=preload("res://scripts/regional_water.gd").material()
	var signal_material: StandardMaterial3D=b.materials.window.duplicate(); signal_material.albedo_color=Color("83d6df"); signal_material.emission=Color("56b6d0"); b.materials.shore_signal=signal_material
	# A walkable strip of black sand follows the ocean. No invisible floor over water.
	world._solid(ORIGIN+Vector3(19,-0.6,-28),Vector3(74,1,168))
	for x in range(-17,56):
		for z in range(-111,56):
			box(Vector3(x,-0.17,z),Vector3(1.01,.14,1.01),"path" if abs(x-22)<2.5 or (z>0 and abs(z-14)<2) else "coal" if x<2 or z< -16 else "grass_dark")
	box(Vector3(-92,-1.5,-28),Vector3(148,.3,205),"shore_water")
	for h in [[34,20,10,12,"harbormaster"],[10,6,10,12,"net_loft"],[41,42,9,10,"salt_store"]]: world._house(ORIGIN+Vector3(h[0],0,h[1]),h[2],h[3],3.8,false,h[4])
	# Dock, fishing boats, drying racks, rope coils and cargo around the settlement.
	for i in range(31): box(Vector3(-5-i*.65,.05,26),Vector3(.62,.22,3.4),"wood",true,"wood")
	for x in [-7,-13,-19,-24]:
		for z in [24.7,27.3]: box(Vector3(x,-.35,z),Vector3(.26,2.5,.26),"timber")
	for z in [20,33]:
		for tier in range(4): box(Vector3(-26, -.75+tier*.22,z),Vector3(2.8-tier*.28,.2,5.4-tier*.3),"wood")
		box(Vector3(-26,1,z),Vector3(.16,3,.16),"timber")
		box(Vector3(-25.6,1.4,z),Vector3(.7,1.7,.07),"cloth")
	for x in [1,18,43]:
		for leg in [-1,1]: box(Vector3(x+leg,1,18),Vector3(.16,2,.16),"timber")
		box(Vector3(x,1.95,18),Vector3(2.4,.15,.15),"wood")
		for fish in range(5): box(Vector3(x-.8+fish*.4,1.5,18),Vector3(.12,.48,.12),"iron")
		box(Vector3(x, .4,20),Vector3(1.2,.8,.9),"wood")
	# Layered cliffs cradle the sea cave, with a clear eastward path around its exit.
	for i in range(14):
		var at=Vector3(54+(i%3)*1.4,0,-105+i*11)
		box(at+Vector3(0,.3,0),Vector3(10,.78,11.6),"stone_dark",true)
		preload("res://scripts/refined_ridges.gd").build(b,ORIGIN+at,13,16,9+(i*7%8),"stone_dark",false)
	for side in [-1,1]:
		for row in range(16):
			var x: float=-7 if side<0 else 7
			for tier in range(7): box(Vector3(x+side*tier*.14,.35+tier*.75,-22-row*2.2),Vector3(2.3,.72,2.16),"stone_dark",true)
	for z in range(-54,-20,2): box(Vector3(0,5.4,z),Vector3(17,1,1.98),"stone_dark",true)
	for z in [-25,-38,-51]:
		for side in [-1,1]: box(Vector3(side*5.7,2.4,z),Vector3(.6,4.8,.8),"timber")
		box(Vector3(0,4.8,z),Vector3(12,.4,.7),"wood")
	for z in [-22,-27,-34,-41,-48,-53]:
		for side in [-1,1]:
			for tier in range(4):
				box(Vector3(side*(5.8+tier*.12),4.7-tier*.27,z),Vector3(.95-tier*.19,.3,.9-tier*.16),"stone")
	for i in range(28):
		var x: float=-12+(i%4)*2.4
		var z: float=-106+i*5.6
		# Keep shoreline rubble clear of the pier's full visible width.
		if x>-26 and x<5 and z>23 and z<29: continue
		for tier in range(3+i%3): box(Vector3(x,tier*.32,z),Vector3(2.4-tier*.3,.3,2.7-tier*.3),"stone_dark")
	# Broken hull: tapered ribs, panel seams, wings and two connected compartments.
	for z in range(-104,-61,2):
		var width: float=14-absf(z+83)*.12
		for side in [-1,1]:
			for tier in range(10): box(Vector3(21+side*(width-tier*.08),.25+tier*.48,z),Vector3(.5,.45,1.94),"iron" if tier%3 else "stone_dark",true)
		box(Vector3(21,-.08,z),Vector3(width*2,.12,1.98),"iron")
		if z< -82: box(Vector3(21,5.1,z),Vector3(width*2,.3,1.98),"stone_dark",true)
	for z in [-62,-82]:
		for side in [-1,1]:
			box(Vector3(21+side*8,2.3,z),Vector3(9.5,4.6,.6),"iron",true)
			for row in range(9): box(Vector3(21+side*3.15,.25+row*.49,z+.35),Vector3(.3,.45,.3),"gold")
		box(Vector3(21,4.8,z),Vector3(27,.4,.9),"iron",true)
	# Segmented hull plates and a raised flight deck break up the cargo-door silhouette.
	for side in [-1,1]:
		for row in range(8):
			for col in range(8):
				box(Vector3(21+side*(4.1+col*1.02),.35+row*.53,-61.63),Vector3(.97,.48,.12),"iron" if (row+col)%4 else "stone_dark")
		for vent in range(6): box(Vector3(21+side*8,1+vent*.22,-61.5),Vector3(2.7,.1,.14),"coal")
		for rib in range(10): box(Vector3(21+side*15,1.6,-62.5-rib*.8),Vector3(2.8,2.5,.4),"stone_dark" if rib%2 else "iron")
		box(Vector3(21+side*15,1.6,-62),Vector3(1.9,1.5,.12),"shore_signal")
		for step in range(7): box(Vector3(21+side*(9+step*.4),5.3+step*.37,-91),Vector3(.5,.7,8-step*.8),"iron")
	for tier in range(6):
		box(Vector3(21,5.3+tier*.45,-72-tier*.45),Vector3(13-tier*1.4,.43,9-tier*.6),"stone_dark")
		if tier>1: box(Vector3(21,5.3+tier*.45,-67.5-tier*.75),Vector3(12-tier*1.4,.39,.08),"shore_signal")
	for x in [6,36]:
		for shard in range(6): box(Vector3(x+sin(shard)*1.3,.2+shard*.1,-55-shard*.9),Vector3(1.1,.3,1.5),"iron")
	box(Vector3(21,2.5,-104),Vector3(25,5,.7),"iron",true)
	for side in [-1,1]:
		for rib in range(8): box(Vector3(21+side*(15+rib*.7),.3+rib*.05,-77+rib*.8),Vector3(1.2,.3,12-rib),"iron")
		for z in [-70,-88,-100]:
			box(Vector3(21+side*10,1.1,z),Vector3(1.8,2.2,2),"coal",true)
			for row in range(5): box(Vector3(21+side*9.03,.5+row*.28,z),Vector3(.12,.08,1.6),"shore_signal")
	for x in [13,29]:
		for tier in range(6): box(Vector3(x,2.6,-105-tier*.22),Vector3(3-tier*.22,3-tier*.22,.2),"coal" if tier%2 else "iron")
	bulkhead=StaticBody3D.new(); bulkhead.position=ORIGIN+Vector3(21,2.3,-62); add_child(bulkhead)
	var collision:=CollisionShape3D.new(); var shape:=BoxShape3D.new(); shape.size=Vector3(5.7,4.6,.65); collision.shape=shape; bulkhead.add_child(collision)
	b.piece(bulkhead,"iron",Vector3.ZERO,shape.size)
	for x in [-1.8,-.9,0,.9,1.8]: b.piece(bulkhead,"gold",Vector3(x,0,.36),Vector3(.12,4.3,.12))
	# A dormant beacon visibly comes to life only for the harbor outcome.
	for tier in range(17): box(Vector3(44,.25+tier*.48,3),Vector3(3.8-tier*.075,.45,3.8-tier*.075),"stone")
	box(Vector3(44,8.6,3),Vector3(4,.3,4),"roof")
	beacon=b.piece(self,"window",ORIGIN+Vector3(44,8,3),Vector3(2.2,.8,2.2))
	beacon_light=OmniLight3D.new(); beacon_light.position=ORIGIN+Vector3(44,7.5,3); beacon_light.light_color=Color("ffc77e"); beacon_light.light_energy=3; beacon_light.omni_range=18; add_child(beacon_light)
	for id: String in NODES:
		var p: Vector3=NODES[id]
		if id!="witness": _sign(ORIGIN+p+Vector3.UP*2,NAMES[id])
		if id in ["harbor","salvager","compact","witness","ash_factor","ash_reader","light_keeper"]:
			var npc:=Visual.new(); npc.position=ORIGIN+p; npc.rotation.y=PI; add_child(npc)
			var model:=State.new()
			for slot in ["head","chest","hands","legs","feet"]: model.equip(model.add_item(("cloth" if id=="ash_reader" else "fur" if id=="harbor" else "leather")+"_"+slot),slot)
			if id in ["witness","ash_factor","ash_reader","light_keeper"]: model.equipment.main_hand=""; model.equipment.off_hand=""
			npc.build(model)
			if id=="witness":
				witness=npc; witness_label=Label3D.new(); witness_label.position.y=2.5; witness_label.font_size=22; witness_label.pixel_size=.003; witness_label.billboard=BaseMaterial3D.BILLBOARD_ENABLED; witness.add_child(witness_label)
		elif id not in ["return","bulkhead","ash_hull"]:
			box(p+Vector3.UP*.5,Vector3(1.5,1,1),"wood" if "cache" in id or id=="silver_net" else "stone_dark")
			box(p+Vector3.UP*1.05,Vector3(1.6,.12,1.1),"iron")
			if id in ["pump","relay","navigation"]:
				for dial in range(3): box(p+Vector3(-.5+dial*.5,1.18,0),Vector3(.2,.1,.4),"shore_signal")
	for strand in range(6):
		box(NODES.silver_net+Vector3(-.65+strand*.26,1.14,0),Vector3(.035,.035,1.1),"leather")
		box(NODES.silver_net+Vector3(0,1.14,-.5+strand*.2),Vector3(1.4,.035,.035),"leather")
	b.piece(self,"leather",ORIGIN+NODES.false_orders+Vector3.UP*1.15,Vector3(.85,.1,.6))
	b.piece(self,"snow",ORIGIN+NODES.false_orders+Vector3.UP*1.22,Vector3(.75,.035,.5))
	b.piece(self,"gold",ORIGIN+NODES.false_orders+Vector3(.25,1.25,.1),Vector3(.15,.03,.15))
	charter_label=Label3D.new(); charter_label.position=ORIGIN+NODES.charter+Vector3(0,1.35,0); charter_label.font_size=22; charter_label.pixel_size=.003; charter_label.billboard=BaseMaterial3D.BILLBOARD_ENABLED; add_child(charter_label)
	# The ruined shore signal has independent controls from the main harbor beacon.
	for tier in range(10):
		box(Vector3(-14,.25+tier*.5,-14),Vector3(3.5-tier*.09,.48,3.5-tier*.09),"stone_dark",tier==0)
	for side in [-1,1]: box(Vector3(-14+side*1.25,5.7,-14),Vector3(.2,1.8,.2),"timber")
	box(Vector3(-14,6.6,-14),Vector3(3,.18,3),"roof")
	last_light=b.piece(self,"shore_signal",ORIGIN+Vector3(-14,5.7,-14),Vector3(1.5,.7,1.5))
	last_lamp=OmniLight3D.new(); last_lamp.position=ORIGIN+Vector3(-14,5.7,-14); last_lamp.light_color=Color("83d6df"); last_lamp.light_energy=3; last_lamp.omni_range=16; add_child(last_lamp)
	last_caption=Label3D.new(); last_caption.position=ORIGIN+Vector3(-12,1.5,-10); last_caption.font_size=20; last_caption.pixel_size=.003; last_caption.billboard=BaseMaterial3D.BILLBOARD_ENABLED; add_child(last_caption)
	b.piece(self,"leather",ORIGIN+NODES.light_record+Vector3.UP*1.15,Vector3(.85,.1,.65))
	b.piece(self,"snow",ORIGIN+NODES.light_record+Vector3.UP*1.22,Vector3(.75,.04,.55))
	last_ship=Node3D.new(); add_child(last_ship)
	for tier in range(5): b.piece(last_ship,"timber",Vector3(0,tier*.3,0),Vector3(3+tier*.3,.28,8+tier*.4))
	b.piece(last_ship,"wood",Vector3(0,4,0),Vector3(.2,7,.2))
	b.piece(last_ship,"cloth",Vector3(1.25,4.8,0),Vector3(2.3,3.2,.08))
	b.piece(last_ship,"window",Vector3(0,2,4),Vector3(.3,.4,.3))
	# A beached Ashport launch, distinct from the fallen star vessel.
	for tier in range(4): box(NODES.ash_hull+Vector3(0,.1+tier*.25,-2.5),Vector3(3.6+tier*.3,.24,6+tier*.25),"wood")
	for side in [-1,1]:
		box(NODES.ash_hull+Vector3(side*2.2,1.4,-2.5),Vector3(.25,.9,6.8),"coal")
		for i in range(7): box(NODES.ash_hull+Vector3(side*2.35,.6, -5.5+i),Vector3(.22,1.7,.2),"timber")
	ash_cargo=Node3D.new(); ash_cargo.position=ORIGIN+NODES.ash_hull+Vector3(0,1.6,-2.5); add_child(ash_cargo)
	world.blocks.piece(ash_cargo,"iron",Vector3.ZERO,Vector3(1.5,1.1,1.3))
	for i in [-1,1]: world.blocks.piece(ash_cargo,"gold",Vector3(i*.5,0,.67),Vector3(.1,1.15,.05))
	b.piece(self,"snow",ORIGIN+NODES.ash_manifest+Vector3.UP*1.15,Vector3(.8,.06,.55))
	ship_plate=Node3D.new(); ship_plate.position=ORIGIN+NODES.nameplate+Vector3.UP*1.15; add_child(ship_plate)
	b.piece(ship_plate,"wood",Vector3.ZERO,Vector3(1.3,.13,.65))
	for i in range(5): b.piece(ship_plate,"iron",Vector3(-.4+i*.2,.09,0),Vector3(.07,.035,.4))
	b.piece(self,"leather",ORIGIN+NODES.registry+Vector3.UP*1.15,Vector3(.8,.12,.6))
	b.piece(self,"snow",ORIGIN+NODES.registry+Vector3.UP*1.23,Vector3(.7,.035,.5))
	silver_coins=Node3D.new(); silver_coins.position=ORIGIN+NODES.silver_net+Vector3.UP*1.18; add_child(silver_coins)
	for i in range(6): b.piece(silver_coins,"iron",Vector3((i%3-1)*.3,0,(i/3)*.25),Vector3(.18,.06,.18))
	silver_ledger=Node3D.new(); silver_ledger.position=ORIGIN+NODES.cave_cache+Vector3.UP*1.2; add_child(silver_ledger)
	b.piece(silver_ledger,"leather",Vector3.ZERO,Vector3(.7,.12,.5))
	b.piece(silver_ledger,"snow",Vector3(0,.07,0),Vector3(.6,.04,.4))
	core_mesh=b.piece(self,"shore_signal",ORIGIN+NODES.core+Vector3.UP*1.45,Vector3(.65,.65,.65))
	nav_light=b.piece(self,"shore_signal",ORIGIN+NODES.navigation+Vector3.UP*1.8,Vector3(1.7,.08,1.2))
	for star in range(7):
		b.piece(nav_light,"window",Vector3(-.65+star*.2,.12,sin(star*1.8)*.4),Vector3(.065,.065,.065))
	for p in [Vector3(22,0,30),Vector3(20,0,14),Vector3(0,0,-25),Vector3(0,0,-43),Vector3(21,0,-70),Vector3(21,0,-87)]: world._lantern(ORIGIN+p,false)
	preload("res://scripts/saltbreak_detail.gd").new().build(self)
	world.block_count+=b.finish(world)
	_sign(TRAIL+Vector3.UP*2,"Coastal road · Saltbreak")
	var positions=[Vector3(1,0,-13),Vector3(0,0,-35),Vector3(23,0,-51),Vector3(14,0,-69),Vector3(28,0,-78),Vector3(14,0,-90),Vector3(24,0,-97)]
	for i in range(7):
		var enemy=preload("res://scripts/brine_crab.gd").new() if i==6 else Enemy.new(); enemy.adventure=self; enemy.progress=state.shore; enemy.enemy_id="shore_"+str(i)
		enemy.role="boss" if i==6 else "archer" if i==2 else "mage" if i==4 else "guard"
		enemy.title="The Hull Warden" if i==6 else "Brinecutter Raider" if i<3 else "Wreckbound Sentinel"
		enemy.position=ORIGIN+positions[i]+Vector3.UP*.15; enemy.health_override=340 if i==6 else 95
		add_child(enemy); enemies.append(enemy)
func _sign(p: Vector3,label: String) -> void:
	var sign:=Label3D.new(); sign.position=p; sign.text=label; sign.font_size=22; sign.pixel_size=.003; sign.billboard=BaseMaterial3D.BILLBOARD_ENABLED; sign.visibility_range_begin=4.5; sign.visibility_range_end=19; add_child(sign)
func _ui() -> void:
	var layer:=CanvasLayer.new(); layer.layer=7; add_child(layer)
	preview_label=Label.new(); preview_label.position=Vector2(32,76); preview_label.text="BLACK SHORE PREVIEW · progress is not saved"; layer.add_child(preview_label)
	dialog=ColorRect.new(); dialog.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); dialog.color=Color("101d27"); layer.add_child(dialog)
	var center:=CenterContainer.new(); center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); dialog.add_child(center)
	var col:=VBoxContainer.new(); col.custom_minimum_size.x=720; col.add_theme_constant_override("separation",16); center.add_child(col)
	title=Label.new(); title.add_theme_font_size_override("font_size",25); col.add_child(title)
	description=Label.new(); description.custom_minimum_size=Vector2(720,210); description.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART; description.add_theme_font_size_override("font_size",18); col.add_child(description)
	options=VBoxContainer.new(); col.add_child(options)
	var close:=Button.new(); close.text="Return [ Esc ]"; close.custom_minimum_size.y=42; close.pressed.connect(func(): close_dialog(); world.player.set_paused(false)); col.add_child(close); dialog.hide()
func _button(label: String,id: String) -> void:
	var button:=Button.new(); button.text=label; button.custom_minimum_size.y=40; button.pressed.connect(func(): act(id)); options.add_child(button)
func _refresh() -> void:
	var light_stage: int=int(state.shore.get("light_stage",0))
	last_light.visible=light_stage>=3; last_lamp.visible=last_light.visible
	last_ship.visible=light_stage>=1
	last_ship.position=ORIGIN+(Vector3(-29,-1,12) if light_stage>=4 else Vector3(-48,-1,-60))
	last_caption.text="SHIP AT SAFE ANCHOR" if light_stage>=4 else "SIGNAL READY" if light_stage==3 else "LENS DARK"
	ash_cargo.visible=state.shore.get("ash_choice","")==""
	charter_label.text={"":"CHARTER AWAITING SEALS","open":"OPEN HARBOR · PUBLIC ACCOUNTS","house":"HOUSE MERROW · LICENSED PASSAGE","outlaw":"HOUSE MERROW · CONCORD BARRED"}[state.shore.get("passage_choice","")]
	witness.position=interaction_position("witness")
	witness_label.text="Tamsin · sheltered witness" if int(state.shore.get("harbor_stage",0))>=4 else "Pilot Tamsin"
	ship_plate.visible="nameplate" not in state.shore.get("compact_evidence",[])
	silver_coins.visible=state.shore.get("silver_stage",0)<2
	silver_ledger.visible=state.shore.get("silver_stage",0)<3
	var opened: bool=state.shore.relays.size()==2
	bulkhead.visible=not opened; bulkhead.collision_layer=0 if opened else 1
	core_mesh.visible=not state.shore.core
	beacon.visible=state.shore.choice=="harbor"; beacon_light.visible=beacon.visible
	nav_light.visible=state.shore.choice=="navigation"
func enter() -> bool:
	if world.player.paused or "archive" not in state.story_completed: return false
	if inside: return true
	if is_instance_valid(world.seal) and world.seal.inside: world.seal.leave()
	if is_instance_valid(world.winter) and world.winter.inside: world.winter.leave()
	if is_instance_valid(world.threshold) and world.threshold.inside: world.threshold.leave()
	if is_instance_valid(world.convergence) and world.convergence.inside: world.convergence.leave()
	if is_instance_valid(world.choir) and world.choir.inside: world.choir.leave()
	if is_instance_valid(world.roots) and world.roots.inside: world.roots.leave()
	if is_instance_valid(world.lens) and world.lens.inside: world.lens.leave()
	if world.archive_chapter.inside: world.archive_chapter.leave()
	if world.mountain.inside: world.mountain.leave()
	if world.realms.inside: world.realms.leave()
	if world.adventure.inside: world.adventure.leave()
	inside=true; world.player.position=ORIGIN+Vector3(22,.2,42); world.player.velocity=Vector3.ZERO; world.player.rotation=Vector3.ZERO
	for child in world.get_children():
		if child is WorldEnvironment:
			environment_backup=child.environment
			var env: Environment=environment_backup.duplicate(true)
			env.background_mode=Environment.BG_COLOR; env.background_color=Color("303e4a"); env.fog_light_color=Color("3d4d60"); env.fog_density=.006; env.ambient_light_color=Color("adc3d4"); env.ambient_light_energy=.55; preload("res://scripts/regional_sky.gd").apply(env,"shore"); child.environment=env
	for child in world.get_children():
		if child is DirectionalLight3D: light_backup[child]=child.light_energy; child.light_energy=.55
	world.hud.world_map.selected_quest="tides"; world.hud.world_map.set_view(true)
	world.hud.announce("Saltbreak · The Black Shore","The atlas points to a ship that fell from the stars. Keeper Sella and salvager Neris await you.")
	world.audio.sfx("portal"); return true
func leave() -> void:
	if not inside: return
	inside=false; world.adventure.clear_projectiles(); world.player.position=TRAIL+Vector3(0,.2,2.5); world.player.velocity=Vector3.ZERO
	for child in world.get_children():
		if child is WorldEnvironment and environment_backup!=null: child.environment=environment_backup
	for light in light_backup:
		if is_instance_valid(light): light.light_energy=light_backup[light]
	light_backup.clear()
	for enemy in enemies:
		if not enemy.dead: enemy.position=enemy.home; enemy.health=enemy.maximum_health; enemy.velocity=Vector3.ZERO; enemy.windup=0; enemy._update_label()
	world.audio.sfx("portal")
func nearest() -> Dictionary:
	if not inside:
		if world.player.position.distance_to(TRAIL)<2.5: return {"kind":"shore","id":"trail","text":"[ E ] Travel to Saltbreak"}
		return {}
	for enemy in enemies:
		if enemy.dead and enemy.enemy_id not in state.shore.looted and world.player.position.distance_to(enemy.position)<2.5: return {"kind":"shore","id":enemy.enemy_id,"text":"[ E ] Recover wreck salvage"}
	for id: String in NODES:
		if world.player.position.distance_to(interaction_position(id))<2.3: return {"kind":"shore","id":id,"text":"[ E ] "+NAMES[id]}
	return {}
func station_nearby() -> String:
	for id in ["forge","enchant"]:
		if inside and world.player.position.distance_to(ORIGIN+NODES[id])<2.3: return id
	return ""
func interact(id: String) -> void:
	if world.player.paused or nearest().get("id","")!=id: return
	if id=="trail":
		if not enter(): world.hud.announce("The coastal road","Complete The Missing Atlas before following its Black Shore lead.")
	elif id=="return": leave()
	elif id in ["forge","enchant"]:
		world.hud.workshop.open(id)
		world.hud.workshop.status.text="Neris identifies damaged relics. Known restoration patterns use ship salvage and ordinary forge materials."
	elif id.begins_with("shore_"): loot(id)
	else: open_dialog(id)
func can_choose() -> bool:
	return state.shore.core and state.shore.log and state.shore.heard.size()==2 and state.shore.choice==""
func open_dialog(id: String) -> void:
	subject=id; world.player.dialog_open=true; world.player.set_paused(true); dialog.show()
	for child in options.get_children(): options.remove_child(child); child.queue_free()
	title.text=NAMES[id].to_upper()
	var p: Dictionary=state.shore
	if p.get("passage_started",false) and id in ["harbor","salvager","witness"]: _button("Discuss the passage charter","passage_review")
	if id in ["light_keeper","light_record","light_control"]: light_dialog(); return
	if id in ["ash_factor","ash_reader","ash_hull","ash_manifest"]: ash_dialog(); return
	if id=="charter" or (p.get("passage_started",false) and id=="compact"): passage_dialog(); return
	if id in ["witness","false_orders"] or (id in ["compact","registry"] and int(p.get("harbor_stage",0))>0): harbor_dialog(); return
	if id in ["compact","registry","nameplate"]: compact_dialog(); return
	if id in ["harbor","salvager"]:
		description.text="SELLA · SALTBREAK KEEPER\n\nOur beacon failed in the last storm. The Brinecutters took the beach while Neris's Iron Keel crew tried to secure the wreck. A single working core could protect our fishing boats and heat the harbor through winter." if id=="harbor" else "NERIS · IRON KEEL SALVAGERS\n\nThe Brinecutters want scrap; we want to understand what fell here. Restore the sea-cave pressure pump and the beach relay to open the hull. Its own sentinels still defend it. Bring me damaged relics and I can identify their restoration patterns."
		if not p.accepted: _button("Investigate the fallen vessel","accept")
		if id not in p.heard: _button("Hear this claim on the power core","hear")
		if id=="salvager":
			if int(p.get("compact_stage",0))==1 and "salvager" not in p.get("compact_evidence",[]): _button("Ask Neris about the nameless coastal ship","compact_witness")
			for key: String in RELICS:
				if recovered(key) and key not in p.identified: _button("Identify "+RELICS[key].name,"identify_"+key)
			for key: String in p.identified:
				description.text+="\n"+RELICS[key].name+": "+{"blade":"+2 Agility; restored one-handed sword.","armor":"+2 Endurance; reinforced heavy armor.","focus":"+3 Intellect; off-hand focus."}[key]
			if "salvager" in p.get("compact_evidence",[]): description.text+="\n\nNERIS ON MERCY: I watched house porters unload relief grain. The broker paid them before the crew sailed. Nobody was hauling weapons. The missing cargo stayed here."
			if p.identified.size()>0: description.text+="\n\nIdentified relics: %d / 3. Open the forge to restore them from damaged parts, alloy and ordinary materials." % p.identified.size()
			if p.core and p.choice=="": description.text+="\n\nNavigation would reveal precise coordinates. Give the core to Sella for a healing mantle, or install it at the ship's navigation cradle for a lightning staff. Either way, the flight recorder preserves a lead to the Sunken Lens."
		if id=="harbor" and can_choose(): _button("Power Saltbreak · permanent choice · healing mantle","choose_harbor")
		if id=="harbor" and p.choice!="" and not p.rewarded: _button("Report the expedition and collect your reward","reward")
		description.text+="\n\n"+objective()
		if id=="harbor":
			description.text+="\n\n"+silver_objective()
			if p.get("silver_stage",0)==0: _button("Ask about the missing fishing crew","silver_accept")
			elif p.get("silver_stage",0)==3 and p.get("silver_choice","")=="":
				description.text="SELLA · NETS FULL OF SILVER\n\nThe ledger gives us the smugglers' drop and the crew's refuge. My runners found them alive. They were hiding from the Brinecutters, not the sea.\n\nPublish the full ledger and the crew can testify openly, but their names become public. Or publish the smuggling route with their names removed and let them return quietly. Either way, the boats can fish safely again.\n\nBoth choices grant a Fine Netmender's Band and its forge pattern."
				_button("Publish the full ledger · ring, pattern and 120 gold","silver_public")
				_button("Protect crew identities · ring, pattern, 60 gold and 6 Silver Ingots","silver_protect")
	elif id=="silver_net":
		description.text="Old silver glitters in the net. Each coin bears the same cut, used to mark a smuggler's payment. A note reads: 'Third catch. Same silver. At this rate we can afford the funeral before the fish.' The knots point to a delivery near the sea-cave cache."
		if p.get("silver_stage",0)==1: _button("Record the coin marks and follow the delivery note","silver_trace")
		elif p.get("silver_stage",0)==0: description.text+="\n\nAsk Sella about the missing crew first."
		else: description.text+="\n\nCoin marks recorded. "+silver_objective()
	elif id in ["pump","relay"]:
		description.text="SEA-CAVE PRESSURE PUMP\n\nThe scratched maintenance plate reads: 'First vent the sea pressure. Only then may the hull draw power.' The wheel offers two settings." if id=="pump" else "WRECK POWER RELAY\n\nThe panel warns: 'Flooded conduit: vent upstream before engaging the blue return line.' An amber bypass loops back into the damaged coil."
		if id in p.relays: description.text+="\n\nSystem restored."
		elif not p.accepted: description.text+="\n\nSpeak with Sella or Neris before working on the wreck."
		else:
			_button("Vent sea pressure" if id=="pump" else "Connect the blue return line","solve")
			_button("Seal the pressure chamber" if id=="pump" else "Bridge the amber bypass","wrong")
	elif id=="bulkhead": description.text="The hull opens when the sea-cave pump is vented and the beach relay reconnected.\n\n"+("The bulkhead is open. The flight recorder lies beyond the first compartment." if p.relays.size()==2 else "Restore both systems to release this physical door.")
	elif id=="log":
		description.text="FLIGHT RECORDER · VESSEL WAYFARER\n\n'We followed the signal beneath the sand. A lens on this world still remembers our departure route. Navigation is failing. Do not let the Warden reach the core.'\n\nThe recorder names the Sunken Lens. Its evidence survives either use of the core."
		if p.accepted and p.relays.size()==2 and not p.log: _button("Copy the flight record","log")
	elif id=="core":
		description.text="A single intact core hangs in its containment cradle. It can power the harbor or restore the ship's navigation. There is no second core."
		if "shore_6" not in p.defeated: description.text+="\n\nThe Hull Warden still guards it."
		elif not p.log: description.text+="\n\nCopy the flight recorder before removing the core."
		elif not p.core: _button("Recover the protected quest core","core")
		else: description.text+="\n\nCore already recovered."
	elif id=="navigation":
		description.text="The cradle can resolve the flight recorder's rough bearings into a star chart. Its core would stay here; Saltbreak would need another source of power.\n\nNavigation grants a lightning staff and pattern. Saltbreak grants a healing mantle and pattern. Either choice continues toward the Sunken Lens."
		if can_choose(): _button("Restore navigation · permanent choice · lightning staff","choose_navigation")
		else: description.text+="\n\n"+objective()
	else:
		description.text="A damaged relic is sealed among unfamiliar alloys. Recover it, ask Neris to identify its properties, then restore it at the forge."
		if id not in p.caches: _button("Recover damaged relic and components","cache")
		else: description.text+="\n\nAlready recovered."
		if id=="cave_cache":
			description.text+="\n\nA smuggler's ledger records payments planted in fishing grounds to recruit crews, followed by threats when they refused. A penciled note gives the missing crew's refuge above the tideline."
			if p.get("silver_stage",0)==2 and "shore_1" in p.defeated: _button("Recover the ledger and refuge directions","silver_ledger")
			elif p.get("silver_stage",0)==2: description.text+=" Clear the Brinecutter guarding the sea-cave approach first."
			elif p.get("silver_stage",0)>=3: description.text+=" Already secured. Return to Sella."
func recovered(key: String) -> bool:
	return RELICS[key].source in state.shore.caches or RELICS[key].source in state.shore.looted
func act(id: String) -> bool:
	if not dialog.visible or not inside or not NODES.has(subject) or world.player.position.distance_to(interaction_position(subject))>=2.3: return false
	var p: Dictionary=state.shore
	var success:=false
	if id.begins_with("passage_") and is_instance_valid(world.road_quests) and world.road_quests.compact_blocked(): return false
	if id=="passage_sign:outlaw" and is_instance_valid(world.road_quests) and world.road_quests.complete("sable_concord_3"): return false
	if id=="light_start" and subject=="light_keeper" and int(p.get("light_stage",0))==0:
		p.light_stage=1; success=true
	elif id=="light_read" and subject=="light_record" and int(p.get("light_stage",0))==1:
		p.light_stage=2; success=true
	elif id=="light_repair" and subject=="light_control" and int(p.get("light_stage",0))==2:
		if int(state.materials.get("iron_ingot",0))<2 or int(state.materials.get("crystal",0))<1:
			description.text="The frame needs 2 iron ingots and the lens needs 1 crystal. Bring both before beginning repairs."; return false
		state.materials.iron_ingot-=2; state.materials.crystal-=1; p.light_stage=3; success=true; world.audio.sfx("forge")
	elif id=="light_signal" and subject=="light_control" and int(p.get("light_stage",0))==3:
		p.light_stage=4; success=true; world.audio.sfx("quest")
	elif id in ["light_public","light_family"] and subject=="light_keeper" and int(p.get("light_stage",0))==4 and p.get("light_choice","")=="":
		p.light_choice="public" if id=="light_public" else "family"; state.gold+=120
		var uid: String=state.add_item("starsignal_staff" if p.light_choice=="public" else "tideglass_saber",2,"insight" if p.light_choice=="public" else "fleet")
		state.inventory[uid].favorite=true; state.inventory[uid].custom_name="Keeper's Witness" if p.light_choice=="public" else "The Quiet Passage"; success=true; world.audio.sfx("quest")
	if id=="ash_start" and subject=="ash_factor" and not p.get("ash_started",false): p.ash_started=true; success=true
	elif id=="ash_inspect" and subject in ["ash_hull","ash_manifest"] and p.get("ash_started",false) and subject not in p.get("ash_evidence",[]):
		if not p.has("ash_evidence"): p.ash_evidence=[]
		p.ash_evidence.append(subject); success=true
	elif id=="ash_hear" and subject in ["ash_factor","ash_reader"] and p.get("ash_evidence",[]).size()==2 and subject not in p.get("ash_claims",[]):
		if not p.has("ash_claims"): p.ash_claims=[]
		p.ash_claims.append(subject); success=true
	elif id in ["ash_workers","ash_choir"] and subject=="ash_hull" and p.get("ash_claims",[]).size()==2 and p.get("ash_choice","")=="":
		p.ash_choice="workers" if id=="ash_workers" else "choir"; state.gold+=140
		var uid: String=state.add_item("breakwater_mantle" if p.ash_choice=="workers" else "signal_focus",2,"vigor" if p.ash_choice=="workers" else "insight"); state.inventory[uid].favorite=true; state.inventory[uid].custom_name="Ashport's Shelter" if p.ash_choice=="workers" else "Fireproof Memory"
		world.adventure.grant_materials({"steel_ingot":6} if p.ash_choice=="workers" else {"resonant_ore":6,"ash_glass":4}); success=true; world.audio.sfx("quest")
	elif id=="passage_review" and subject in ["harbor","salvager","witness"] and p.get("passage_started",false):
		for child in options.get_children(): options.remove_child(child); child.queue_free()
		passage_dialog(); return true
	if id=="passage_start" and subject=="compact" and int(p.get("harbor_stage",0))==5 and not p.get("passage_started",false):
		p.passage_started=true; success=true
	elif id=="passage_hear" and subject in ["harbor","salvager","witness"] and p.get("passage_started",false) and p.get("passage_choice","")=="" and subject not in p.get("passage_heard",[]):
		if not p.has("passage_heard"): p.passage_heard=[]
		p.passage_heard.append(subject); success=true
	elif id.begins_with("passage_sign:") and subject=="charter" and p.get("passage_started",false) and p.get("passage_heard",[]).size()==3 and p.get("passage_choice","")=="":
		var choice:=id.get_slice(":",1)
		if choice not in ["open","house","outlaw"]: return false
		p.passage_choice=choice; state.gold+=200 if choice=="open" else 300
		var uid: String=state.add_item("voice_amulet",4,"vigor" if choice=="open" else "insight"); state.inventory[uid].favorite=true; state.inventory[uid].custom_name="Harbor Speaker's Seal"
		world.adventure.grant_materials({"wreck_alloy":8,"signal_circuit":6}); success=true; world.audio.sfx("quest")
	elif id=="harbor_start" and subject=="compact" and int(p.get("compact_stage",0))==4 and int(p.get("harbor_stage",0))==0:
		p.harbor_stage=1; success=true
	elif id=="harbor_register" and subject=="registry" and int(p.get("harbor_stage",0))==1:
		p.harbor_stage=2; success=true
	elif id=="harbor_orders" and subject=="false_orders" and int(p.get("harbor_stage",0))==2:
		p.harbor_stage=3; success=true
	elif id=="harbor_shelter" and subject=="witness" and int(p.get("harbor_stage",0))==3 and "shore_2" in p.defeated:
		p.harbor_stage=4; success=true
	elif id in ["harbor_public","harbor_sealed"] and subject=="compact" and int(p.get("harbor_stage",0))==4:
		p.harbor_stage=5; p.harbor_choice="public" if id=="harbor_public" else "sealed"; state.gold+=160
		var uid: String=state.add_item("tideguard_shell" if p.harbor_choice=="public" else "signal_focus",2,"vigor" if p.harbor_choice=="public" else "insight")
		state.inventory[uid].favorite=true; state.inventory[uid].custom_name="Envoy's Breakwater" if p.harbor_choice=="public" else "Envoy's Witness"
		world.adventure.grant_materials({"wreck_alloy":6,"signal_circuit":4}); success=true; world.audio.sfx("quest")
	elif id=="compact_start" and subject=="compact" and p.rewarded and int(p.get("compact_stage",0))==0:
		p.compact_stage=1; success=true
	elif id in ["compact_evidence","compact_witness"] and int(p.get("compact_stage",0))==1 and subject in ["registry","nameplate","salvager"] and subject not in p.get("compact_evidence",[]):
		if (id=="compact_witness")!=(subject=="salvager"): return false
		if subject=="nameplate" and "shore_0" not in p.defeated: return false
		if not p.has("compact_evidence"): p.compact_evidence=[]
		p.compact_evidence.append(subject); success=true
	elif id=="compact_hearing" and subject=="compact" and int(p.get("compact_stage",0))==1 and p.get("compact_evidence",[]).size()==3:
		p.compact_stage=2; success=true
	elif id in ["compact_pirates","compact_erased","compact_stars"] and subject=="compact" and int(p.get("compact_stage",0))==2:
		if id!="compact_erased":
			description.text="Vessa: That does not account for all three records. The ship carried relief grain; Neris saw it unloaded. Its name was scraped away AFTER the cargo was sold. The fallen star vessel is unrelated. Review your evidence and present the claim again. No standing or supplies are lost."
			world.audio.sfx("error"); return false
		p.compact_stage=3; success=true
	elif id=="compact_oath" and subject=="compact" and int(p.get("compact_stage",0))==3:
		p.compact_stage=4; state.gold+=140
		var uid: String=state.add_item("tideglass_saber",2,"fleet"); state.inventory[uid].favorite=true; state.inventory[uid].custom_name="Decksworn's Promise"
		if "fleet" not in state.formulas: state.formulas.append("fleet")
		success=true; world.audio.sfx("quest")
	elif id=="silver_accept" and subject=="harbor" and p.get("silver_stage",0)==0: p.silver_stage=1; success=true
	elif id=="silver_trace" and subject=="silver_net" and p.get("silver_stage",0)==1: p.silver_stage=2; success=true
	elif id=="silver_ledger" and subject=="cave_cache" and p.get("silver_stage",0)==2 and "shore_1" in p.defeated: p.silver_stage=3; success=true
	elif id in ["silver_public","silver_protect"] and subject=="harbor" and p.get("silver_stage",0)==3 and p.get("silver_choice","")=="":
		p.silver_choice="public" if id=="silver_public" else "protect"
		var uid: String=state.add_item("netmender_ring",1); state.inventory[uid].favorite=true
		if "saltbreak_silver" not in state.blueprints: state.blueprints.append("saltbreak_silver")
		state.gold+=120 if p.silver_choice=="public" else 60
		if p.silver_choice=="protect": world.adventure.grant_materials({"silver_ingot":6})
		success=true; world.audio.sfx("quest")
	elif id=="accept" and subject in ["harbor","salvager"] and not p.accepted: p.accepted=true; success=true
	elif id=="hear" and subject in ["harbor","salvager"] and subject not in p.heard: p.heard.append(subject); success=true
	elif id=="solve" and subject in ["pump","relay"] and p.accepted and subject not in p.relays:
		if subject=="relay" and "pump" not in p.relays: description.text="Vent the sea-cave pressure pump first. No materials were spent."; world.audio.sfx("error"); return false
		p.relays.append(subject); success=true; world.audio.sfx("enchant")
	elif id=="wrong" and subject in ["pump","relay"]:
		description.text="The safety lock rejects that setting. Vent the sea pressure, then connect the blue return line. No materials were spent."; world.audio.sfx("error"); return false
	elif id=="cache" and subject in ["coast_cache","cave_cache"] and subject not in p.caches:
		p.caches.append(subject); world.adventure.grant_materials({"wreck_alloy":6,"signal_circuit":3,"fractured_hilt" if subject=="coast_cache" else "pressure_shell":1}); success=true
	elif id.begins_with("identify_") and subject=="salvager":
		var key:=id.trim_prefix("identify_")
		if RELICS.has(key) and recovered(key) and key not in p.identified:
			p.identified.append(key); state.blueprints.append("shore_"+key); success=true; world.audio.sfx("enchant")
	elif id=="log" and subject=="log" and p.accepted and p.relays.size()==2 and not p.log: p.log=true; success=true
	elif id=="core" and subject=="core" and p.log and "shore_6" in p.defeated and not p.core: p.core=true; success=true; world.audio.sfx("loot")
	elif can_choose() and ((id=="choose_harbor" and subject=="harbor") or (id=="choose_navigation" and subject=="navigation")):
		p.choice=id.trim_prefix("choose_"); success=true; world.audio.sfx("quest")
	elif id=="reward" and subject=="harbor" and p.choice!="" and not p.rewarded:
		p.rewarded=true; state.story_completed.append("tides"); state.gold+=150
		var uid: String=state.add_item("breakwater_mantle" if p.choice=="harbor" else "starsignal_staff",2,"vigor" if p.choice=="harbor" else "insight")
		state.inventory[uid].favorite=true; state.blueprints.append("shore_"+p.choice)
		world.adventure.grant_materials({"wreck_alloy":6,"signal_circuit":4,"steel_ingot":6,"leather":4,"crystal":4}); success=true
	if success:
		if id.begins_with("compact_"): world.hud.world_map.selected_quest="tide_compact_1"
		if id.begins_with("silver_"): world.hud.world_map.selected_quest="side_saltbreak"
		if id.begins_with("light_"): world.hud.world_map.selected_quest="side_hallowcliff"
		if id.begins_with("ash_"): world.hud.world_map.selected_quest="side_ashport"
		if id.begins_with("passage_"): world.hud.world_map.selected_quest="tide_compact_3"
		if id.begins_with("harbor_"): world.hud.world_map.selected_quest="tide_compact_2"
		state._commit()
		if id=="light_signal": close_dialog(); world.player.set_paused(false); world.hud.announce("Safe water", "The Hallowcliff ship has reached the anchorage. Return to Mara with the keeper’s log.")
		elif id=="harbor_shelter": close_dialog(); world.player.set_paused(false); world.hud.announce("Tamsin is sheltered","The harbor watch brought her to the southern lodge. Return to Vessa to present the records.")
		else: open_dialog(subject)
	return success
func mark_defeated(id: String) -> void:
	if id not in state.shore.defeated: state.shore.defeated.append(id); state._commit()
func loot(id: String) -> bool:
	if id not in state.shore.defeated or id in state.shore.looted: return false
	state.shore.looted.append(id); state.gold+=40 if id=="shore_6" else 18
	world.adventure.grant_materials({"wreck_alloy":3,"signal_circuit":2})
	if id=="shore_6": world.adventure.grant_materials({"clouded_lens":1})
	else: state.consumables.healing_draught=int(state.consumables.get("healing_draught",0))+1
	state._commit()
	for enemy in enemies: enemy._update_label()
	world.hud.announce("Wreck salvage recovered","Take damaged relics to Neris for identification; restore them at the forge.")
	return true
func silver_objective() -> String:
	var p: Dictionary=state.shore
	if p.get("silver_choice","")=="public": return "Nets Full of Silver complete · the full ledger is public; the crew returned to testify. Sella: 'For once, the harbor gossip comes with page numbers.'"
	if p.get("silver_choice","")=="protect": return "Nets Full of Silver complete · the route is exposed and the crew's identities protected. Sella: 'The fish may keep their secrets. The smugglers have lost that privilege.'"
	return ["Nets Full of Silver · Ask Sella about the missing fishing crew.","Inspect the silver-laden net on the dock west of Saltbreak.","Find the smuggler's ledger at the sea-cave cache; defeat the Brinecutter on its approach. Earlier defeats count.","Return the ledger and refuge directions to Sella; decide how to report the evidence."][int(p.get("silver_stage",0))]

func objective() -> String:
	var p: Dictionary=state.shore
	if p.rewarded: return "Black Shore complete · "+("Saltbreak's beacon is lit" if p.choice=="harbor" else "Navigation restored")+" · Sunken Lens lead recovered"
	if not p.accepted: return "Speak with Keeper Sella or Neris in Saltbreak"
	if p.heard.size()<2: return "Hear Sella and Neris · %d / 2 claims" % p.heard.size()
	if "pump" not in p.relays: return "Vent the sea-cave pressure pump · follow the black beach north"
	if "relay" not in p.relays: return "Reconnect the beach relay beyond the cave"
	if not p.log: return "Enter the opened hull and copy the flight recorder"
	if not p.core: return "Defeat the Hull Warden, loot its lens, and recover the core"
	if p.choice=="": return "Choose: power Saltbreak or restore the ship's navigation"
	return "Return to Keeper Sella for your expedition reward"
func close_dialog() -> void:
	dialog.hide(); world.player.dialog_open=false
func check_fall() -> void:
	var p: Vector3=world.player.position-ORIGIN
	if p.y< -3 or p.x< -45 or p.x>55 or p.z< -111 or p.z>55:
		world.player.position=ORIGIN+Vector3(22,.2,42); world.player.velocity=Vector3.ZERO
		world.hud.announce("Back on the coastal road","The surf is too dangerous. Your collected salvage is safe.")
func fire(origin: Vector3,direction: Vector3,damage: float,hostile: bool,source: CollisionObject3D,magic: bool) -> void:
	world.adventure.fire(origin,direction,damage,hostile,source,magic)
func line_clear(from: Vector3,to: Vector3,source: CollisionObject3D,target_body: CollisionObject3D=null) -> bool:
	return world.adventure.line_clear(from,to,source,target_body)
func _process(delta: float) -> void:
	preview_label.visible="--shore-preview" in OS.get_cmdline_user_args() and not world.player.paused
	if feedback_time>0: world.adventure.feedback=feedback; world.adventure.feedback_time=feedback_time; feedback_time=maxf(0,feedback_time-delta)

func compact_objective() -> String:
	var stage: int=int(state.shore.get("compact_stage",0))
	if not state.shore.rewarded: return "Complete the Black Shore expedition, then meet Arbiter Vessa near Saltbreak's southern road."
	if stage==0: return "Meet Arbiter Vessa near Saltbreak's southern road to investigate a missing coastal ship."
	if stage==1: return "Compare the departure register, Neris's account, and the nameplate at the sea-cave approach · %d / 3. Clear the Brinecutter guarding the nameplate." % state.shore.get("compact_evidence",[]).size()
	if stage==2: return "Present the evidence to Vessa at the harbor hearing."
	if stage==3: return "Findings upheld · return to Vessa if you wish to swear the Decksworn oath. Membership is optional."
	return "Decksworn · A Ship Without a Name complete. Relief cargo was sold and the ship erased from the records. Speak to Vessa about the forged harbor records."
func compact_dialog() -> void:
	var p: Dictionary=state.shore
	var stage: int=int(p.get("compact_stage",0))
	description.text=compact_objective()
	if subject=="compact":
		if not p.rewarded: return
		if stage==0:
			description.text="Vessa: A coastal grain ship, Mercy, vanished from our register. Not your vessel from the stars. This one fell from an accountant's conscience. Much shorter journey.\n\nCompare the register, ask Neris what was unloaded, and recover the scraped nameplate beside the sea-cave approach. Then bring a claim the houses cannot wave away."
			_button("Investigate the missing coastal ship","compact_start")
		elif stage==1 and p.get("compact_evidence",[]).size()==3: _button("Convene the harbor hearing","compact_hearing")
		elif stage==2:
			description.text="HARBOR HEARING\n\nVessa reads the houses' objections, then places your evidence on the table.\n\nRegister: Mercy carried relief grain, not weapons.\nNeris: the grain was unloaded for a house broker before the crew departed.\nNameplate: the name was scraped away over fresh harbor paint.\n\nVessa: What claim can these facts actually support?"
			_button("The crew stole weapons for pirates","compact_pirates")
			_button("Relief cargo was sold, then the ship's identity erased","compact_erased")
			_button("The fallen star vessel destroyed the grain ship","compact_stars")
		elif stage==4: _button("Investigate the forged harbor records","harbor_start")
		elif stage==3:
			description.text="Vessa: Your finding stands. The houses must answer for a relief shipment sold under their seal. You have earned a place among us, if you want it.\n\nThe Decksworn oath: keep an honest manifest, aid a vessel in distress, and put a living crew before a profitable silence.\n\nYou may leave and decide later. Joining grants 140 gold, a Superior Fleet-enchanted Tideglass Saber, and the Fleet formula."
			_button("Swear the Decksworn oath · join the Compact","compact_oath")
	elif subject in ["registry","nameplate"]:
		description.text="MERCY · RELIEF GRAIN\n\nThe departure entry was crossed out, but the cargo tally remains beneath it. No arms aboard. A house broker's seal authorizes unloading before departure." if subject=="registry" else "Five scraped letters scar a ship's nameplate. Beneath the cuts lies fresh Saltbreak harbor paint: the name was removed after docking, not lost at sea."
		if stage==1 and subject not in p.get("compact_evidence",[]):
			if subject=="nameplate" and "shore_0" not in p.defeated: description.text+="\n\nClear the Brinecutter on the approach before recovering it."
			else: _button("Record this evidence","compact_evidence")
		else: description.text+="\n\n"+compact_objective()

func interaction_position(id: String) -> Vector3:
	if id=="witness" and int(state.shore.get("harbor_stage",0))>=4: return ORIGIN+Vector3(41,0,46)
	return ORIGIN+NODES[id]
func harbor_objective() -> String:
	var stage: int=int(state.shore.get("harbor_stage",0))
	if int(state.shore.get("compact_stage",0))<4: return "Become Decksworn before investigating The Harbor That Lied."
	if stage==5: return "Envoy · The Harbor That Lied complete. Tamsin is sheltered; " + ("her testimony is public, backed by the harbor watch." if state.shore.harbor_choice=="public" else "her identity is sealed while the forged orders are public.") + " Speak to Vessa about a new passage charter."
	return ["Ask Vessa about the forged harbor records.","Compare the amended departure register beside the southern road.","Recover the false beacon orders east of the sea-cave exit.","Find pilot Tamsin east of the sea cave. Defeat the Brinecutter at the beach relay before arranging her shelter.","Tamsin is sheltered at the southern lodge. Return to Vessa and decide how to present the evidence."][stage]
func harbor_dialog() -> void:
	var p: Dictionary=state.shore
	var stage: int=int(p.get("harbor_stage",0))
	description.text=harbor_objective()
	if subject=="compact":
		if stage==5: _button("Draft the new passage charter","passage_start")
		elif stage==1: description.text="Vessa: Mercy's broker used the same house seal on three wreck claims. All three captains supposedly ignored the beacon. Remarkably tidy paperwork for men allegedly drowning.\n\nStart with the amended register. Find the signal orders, then bring pilot Tamsin under watch protection before we present anything."
		elif stage==4:
			description.text="Vessa: The altered register blames the captains. The signed orders instructed the beacon crew to signal a safe channel over the reef. House Vale collected salvage rights on the wrecks it arranged.\n\nTamsin is safe at the lodge and willing to testify publicly with watch protection, or privately under seal. Both expose the orders and earn Envoy rank. Choose how we protect the witness. Both grant 160 gold, 6 Wreck Alloy and 4 Signal Circuits alongside the equipment."
			_button("Public testimony with watch protection · Superior heavy cuirass","harbor_public")
			_button("Seal her identity, publish the orders · Superior off-hand focus","harbor_sealed")
	elif subject=="registry":
		description.text="The original departure times were moved two hours forward. Under the blotting sand, the earlier entries match low tide: the reef was exposed when the beacon called the ships in. All amendments carry House Vale's seal."
		if stage==1: _button("Copy the original times and house seal","harbor_register")
		else: description.text+="\n\n"+harbor_objective()
	elif subject=="false_orders":
		description.text="HOUSE VALE · SIGNAL INSTRUCTION\n\nShow the white safe-channel lamp over the eastern reef. Record any loss as captain error. Transfer salvage rights to the house.\n\nThe signature matches the altered register. A margin names pilot Tamsin as the reluctant witness."
		if stage==2: _button("Secure the signed beacon orders","harbor_orders")
		else: description.text+="\n\n"+harbor_objective()
	elif subject=="witness":
		if stage<3: description.text="Tamsin: Bring proof before asking me to accuse a house. Their lawyers have longer knives than the raiders.\n\n"+harbor_objective()
		elif stage==3:
			description.text="Tamsin: I steered one ship clear. The others trusted that lamp. I kept the order, but the relay raider watches the road back. Clear him, then send Vessa's watch to bring me to the southern lodge.\n\nOnce sheltered, I will testify under protection or let Vessa seal my name. Publish the orders either way."
			if "shore_2" in p.defeated: _button("Arrange watch protection and shelter for Tamsin","harbor_shelter")
		else: description.text="Tamsin: A locked door, two watchkeepers, and soup. I had forgotten testimony could come with soup.\n\n"+harbor_objective()

func concord_capstone_blocked() -> bool:
	return state.shore.get("passage_choice","")=="outlaw"
func passage_objective() -> String:
	if is_instance_valid(world.road_quests) and world.road_quests.compact_blocked(): return "Permanently closed by your Concord declaration of war on the Compact."
	var p: Dictionary=state.shore
	if p.get("passage_choice","")!="":
		return "Harbor Speaker · The Price of Safe Passage complete. "+{"open":"An open charter publishes fees and accounts; independent routes remain welcome.","house":"House Merrow administers the port; Concord routes remain licensed.","outlaw":"House Merrow controls the port; the Sable Concord's final quest is permanently closed."}[p.passage_choice]
	if int(p.get("harbor_stage",0))<5: return "Become Envoy before drafting the passage charter."
	if not p.get("passage_started",false): return "Ask Vessa to convene the passage charter after the wreck inquiry."
	if p.get("passage_heard",[]).size()<3: return "Hear Sella, Neris and sheltered pilot Tamsin · %d / 3 proposals. Then visit the charter table west of the southern road." % p.get("passage_heard",[]).size()
	return "Sign the passage charter west of the southern road. Review its permanent terms before choosing."
func passage_dialog() -> void:
	if is_instance_valid(world.road_quests) and world.road_quests.compact_blocked(): description.text=passage_objective(); return
	var p: Dictionary=state.shore
	description.text=passage_objective()
	if not p.get("passage_started",false) or p.get("passage_choice","")!="": return
	if subject=="compact": description.text="Vessa: Vale's wreck scheme is exposed. Now we need rules that survive the next respectable thief. Hear Sella, Neris and Tamsin before signing.\n\nHouse Merrow offers to fund and administer the harbor. An open charter shares oversight instead. Neither requires banning independent traders; that is a separate, permanent clause."
	elif subject in ["harbor","salvager","witness"]:
		description.text={"harbor":"Sella: Publish the fees and accounts. Give fishing crews a seat beside the houses. A harbor belongs to everyone who risks drowning outside it, not whoever owns the finest pen.","salvager":"Neris: Merrow can pay for repairs now, in exchange for sole administration. They are not Vale. That does not make them saints. Keep independent routes licensed unless you mean to hand them the whole coast.","witness":"Tamsin: Keep my protection agreement intact. A licensed Concord route gives crews another way home. Ban it, and no Concord speaker will negotiate a final treaty with you. A rescue should not end with the exits being bricked up."}[subject]
		if subject not in p.get("passage_heard",[]): _button("Record this proposal","passage_hear")
		else: description.text+="\n\nProposal recorded. "+passage_objective()
	elif subject=="charter" and p.get("passage_heard",[]).size()==3:
		description.text="THE PRICE OF SAFE PASSAGE\n\nAll terms grant Harbor Speaker rank, a Masterwork enchanted Amulet of Presence, 8 Wreck Alloy and 6 Signal Circuits. Your witness protection agreement stays intact.\n\nOpen charter: public accounts and shared oversight; 200 gold, Vigor enchantment.\nHouse charter: Merrow controls administration; 300 gold, Insight enchantment.\n\nOnly the ban clause permanently closes the Sable Concord's final quest, The Road Without Kings. Signing is permanent."
		_button("Sign open charter · keep independent routes","passage_sign:open")
		_button("Sign Merrow charter · keep Concord licensed","passage_sign:house")
		if not is_instance_valid(world.road_quests) or not world.road_quests.complete("sable_concord_3"):
			_button("Sign Merrow charter AND ban Concord · close rival final quest","passage_sign:outlaw")

func ash_objective() -> String:
	var p: Dictionary=state.shore
	if p.get("ash_choice","")!="": return "The Boat That Would Not Burn complete · "+("Ashport's workers received the refractory plates for shelter repairs." if p.ash_choice=="workers" else "The Choir received the plates and inscriptions for controlled study.")
	if not p.get("ash_started",false): return "Speak to dockworker Brann near Saltbreak's southern road about the Ashport launch."
	if p.get("ash_evidence",[]).size()<2: return "Inspect the beached launch and heat-sealed manifest on the black shore west of town · %d / 2." % p.get("ash_evidence",[]).size()
	if p.get("ash_claims",[]).size()<2: return "Hear Brann and archivist Cerys near Saltbreak's southern road · %d / 2 claims."%p.get("ash_claims",[]).size()
	return "Return to the beached launch and award its cargo. Both claims have been heard."
func ash_dialog() -> void:
	var p: Dictionary=state.shore
	description.text=ash_objective()
	if subject=="ash_factor":
		if not p.get("ash_started",false):
			description.text="Brann: A launch from Ashport washed up here after the furnace docks burned. Black rails, untouched cargo. The insurers called it impossible. Then they called it uninsured. Inspect the hull and the sealed manifest before the Choir carts everything away."
			_button("Investigate the Ashport launch","ash_start")
		elif p.get("ash_evidence",[]).size()==2 and "ash_factor" not in p.get("ash_claims",[]):
			description.text="Brann: Those plates survived because workers lined the hold correctly, not because a god took inventory. Ashport paid for them. Send them back to line the emergency shelters. The inscriptions can be copied first."
			_button("Record the workers' claim","ash_hear")
	elif subject=="ash_reader":
		if p.get("ash_evidence",[]).size()==2 and "ash_reader" not in p.get("ash_claims",[]):
			description.text="Cerys: The plates carry old furnace-control markings. We need the originals to test their response to heat. Brann needs shelters; I cannot promise our research helps him this winter. But losing the originals could cost us knowledge we cannot reconstruct."
			_button("Record the archivist's claim","ash_hear")
	elif subject in ["ash_hull","ash_manifest"]:
		if subject=="ash_hull": description.text="The launch's rails are charred, but its lined cargo hold survived. Refractory plates shielded the chest from the fire. The boat is damaged, not blessed.\n\n"+ash_objective()
		else: description.text="ASHPORT PUBLIC WORKS\n\nPurchased: refractory shelter plates. Borrowed for a furnace trial; never returned. Beside the shipping marks, unfamiliar control inscriptions continue beneath the heat seal.\n\n"+ash_objective()
		if p.get("ash_started",false) and subject not in p.get("ash_evidence",[]): _button("Inspect and record the evidence","ash_inspect")
		if subject=="ash_hull" and p.get("ash_claims",[]).size()==2 and p.get("ash_choice","")=="":
			description.text="Both claims are recorded. The cargo cannot do both jobs at once. This decision is permanent and does not grant faction membership.\n\nBoth grant 140 gold and Superior enchanted equipment. Workers: Vigor mantle and 6 steel ingots. Choir: Insight focus, 6 Resonant Ore and 4 Ash Glass."
			_button("Return the plates to Ashport's workers","ash_workers")
			_button("Entrust the originals to Choir research","ash_choir")

func light_objective() -> String:
	var p: Dictionary=state.shore
	if p.get("light_choice","")!="": return "The Keeper’s Last Light complete · "+("The keeper's signed bargain is public; Mara petitions to protect his family from retaliation." if p.light_choice=="public" else "Mara reports the extortion route without naming the keeper; his family keeps the original log.")
	return ["Speak to relief pilot Mara near Saltbreak's southern road about the Hallowcliff ship.","Read the former keeper's log on the western shore, north of the fishing dock.","Repair the ruined signal's ground controls farther north along the beach · 2 iron ingots and 1 crystal.","Use the repaired controls to signal the safe approach.","The Hallowcliff ship is at safe anchor. Return to Mara and decide what to do with the keeper's log."][int(p.get("light_stage",0))]
func light_dialog() -> void:
	var p: Dictionary=state.shore
	var stage: int=int(p.get("light_stage",0))
	description.text=light_objective()
	if subject=="light_keeper":
		if stage==0:
			description.text="Mara: A relief ship from Hallowcliff is holding beyond the shoals. Our old fjord signal went dark before the keeper died. Read his log, repair the lens, then signal the safe approach. He left excellent instructions. Being dead has finally stopped him revising them."
			_button("Help the Hallowcliff ship","light_start")
		elif stage==4 and p.get("light_choice","")=="":
			description.text="Mara: The crew is safe. The keeper took payment to darken the signal while smugglers crossed. Later they threatened his family when he tried to stop. His last entry names their route.

Publish the signed log and seek protection for his family, or report the route without his name and return the original to them. Both grant 120 gold and Superior enchanted gear: Insight staff for publication, Fleet saber for discretion."
			_button("Publish the log; seek protection for the family","light_public")
			_button("Report the route; return the log to the family","light_family")
	elif subject=="light_record":
		description.text="KEEPER'S LOG

First entry: One dark crossing. Enough silver to fix the roof.
Last entry: They want another. They know where the children sleep. Restore the lens with iron and crystal. Signal from the ground lever; the stair is gone. The safe channel runs south of the broken mast.

"+light_objective()
		if stage==1: _button("Take the log and signal instructions","light_read")
	elif subject=="light_control":
		if stage==2: _button("Repair the frame and lens · 2 iron + 1 crystal","light_repair")
		elif stage==3: _button("Signal the safe approach to the relief ship","light_signal")
