extends Node3D
const State=preload("res://scripts/character_state.gd")
const Visual=preload("res://scripts/character_visual.gd")
const Enemy=preload("res://scripts/enemy.gd")
const ORIGIN=Vector3(1440,0,0)
const TRAIL=Vector3(-40,0,18)
const STAG_STOPS=[Vector3(0,0,32),Vector3(0,0,8),Vector3(0,0,-18),Vector3(0,0,-48)]
var amber_trees: Array[Node3D]=[]
var amber_crowns: Array[MeshInstance3D]=[]
var amber_stumps: Node3D
var stag: Node3D
const NODES={"amber_healer":Vector3(-5,0,27),"amber_plot":Vector3(18,0,-8),"amber_bench":Vector3(8,0,32),"hunter":Vector3(-5,0,34),"stag_echo":Vector3.ZERO,"foundation":Vector3(18,0,30),"bed_west":Vector3(-8,0,14),"bed_east":Vector3(8,0,14),"bed_south":Vector3(4,0,32),"return":Vector3(0,0,40),"keeper":Vector3(-12,.25,24),"steward":Vector3(12,.25,24),"forge":Vector3(21,0,16),"enchant":Vector3(-21,0,16),"alchemy":Vector3(-21,0,23),"camp_cache":Vector3(0,0,20),"grove_cache":Vector3(25,0,-29),"spring":Vector3(-17,0,-17),"stone":Vector3(17,0,-26),"seed":Vector3(-13,0,-42),"heart":Vector3(0,0,-57),"record":Vector3(0,0,-69)}
const NAMES={"amber_healer":"Herbalist Edda · Alderrest growers","amber_plot":"Alderrest amber trial plot","amber_bench":"Amber treatment bench","hunter":"Hunter Fenn · a broken promise","stag_echo":"The stag without a shadow","foundation":"Lodge foundation · buried roots","bed_west":"Blighted west seedbed","bed_east":"Blighted east seedbed","bed_south":"Blighted south seedbed","return":"Woodland road · Frostmere","keeper":"Coven healer Maelin","steward":"Woodland steward Oren","forge":"Grove forge","enchant":"Living rune table","alchemy":"Herbalist's bench","camp_cache":"Healer's supply chest","grove_cache":"Abandoned gatherer's pack","spring":"Spring root","stone":"Stone root","seed":"Seed root","heart":"Heart of the Stag","record":"The woodland memory"}
const ROOT_GUARDS={"spring":"roots_0","stone":"roots_1","seed":"roots_2"}
var seedlings: Dictionary={}
var debt_repairs: Dictionary={}
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
var environment_backup: Environment
var root_lights: Dictionary={}
var ward: MeshInstance3D
var record_mesh: MeshInstance3D
var wild_growth: Node3D
var tended_growth: Node3D
func _ready() -> void:
	state=world.player.character; _build(); _ui(); state.changed.connect(_refresh); _refresh()
func box(p: Vector3,size: Vector3,key: String,solid: bool=false,angle: float=0) -> void:
	world.blocks.add(key,ORIGIN+p,size,angle)
	if solid: world._solid(ORIGIN+p,size)
func _build() -> void:
	var b: RefCounted=world.blocks
	for entry in [["roots_leaf","b1753e"],["roots_moss","788650"],["roots_blight","764661"],["roots_glow","b9de8b"]]:
		var mat: StandardMaterial3D=b.materials["window" if entry[0]=="roots_glow" else "stone"].duplicate(); mat.albedo_color=Color(entry[1]); b.materials[entry[0]]=mat
	world._solid(ORIGIN+Vector3(0,-.6,-19),Vector3(88,1,128))
	for x in range(-43,44):
		for z in range(-82,44): box(Vector3(x,-.17,z),Vector3(1.01,.14,1.01),"path" if abs(x)<2 else "grass_dark" if sin(x*.16)+cos(z*.2)<.8 else "roots_moss")
	world._house(ORIGIN+Vector3(-12,0,20),9,12,3.8,false,"grove_keeper")
	world._house(ORIGIN+Vector3(12,0,20),9,12,3.8,false,"grove_hunter")
	# Broad copper crowns, fine bark ribs, exposed buttress roots and a clear central path.
	for side in [-1,1]:
		for i in range(12):
			var p:=Vector3(side*(30+i%3*4),0,35-i*10)
			box(p+Vector3.UP*5,Vector3(1.7,10,1.7),"timber",true)
			for rib in range(5): box(p+Vector3(-.9+rib*.44,5,.88),Vector3(.18,10,.18),"wood")
			preload("res://scripts/refined_canopy.gd").build(b,ORIGIN+p,10,4.4,"roots_leaf","roots_moss")
			for step in range(5): box(p+Vector3(-side*(1+step*.5),.7-step*.13,0),Vector3(.6,1.3-step*.23,1.2),"wood")
	# Inner trunks break up the grove while keeping every quest station and the main path clear.
	for p in [Vector3(-9,0,3),Vector3(11,0,-4),Vector3(-25,0,-6),Vector3(25,0,4),Vector3(-25,0,-32),Vector3(24,0,-43),Vector3(-22,0,-60),Vector3(22,0,-68),Vector3(-12,0,-78),Vector3(12,0,-78)]:
		box(p+Vector3.UP*4,Vector3(1.1,8,1.1),"timber",true)
		for rib in range(4): box(p+Vector3(-.5+rib*.33,4,.6),Vector3(.14,8,.15),"wood")
		preload("res://scripts/refined_canopy.gd").build(b,ORIGIN+p,8,3.8,"roots_leaf","roots_moss")
		for sprig in range(12):
			var angle: float=TAU*sprig/12
			var q: Vector3=p+Vector3(cos(angle)*2.2,.18,sin(angle)*2.2)
			for leaf in range(3): box(q+Vector3(leaf*.12,leaf*.15,0),Vector3(.4,.12,.3),"roots_moss")
	# An open shrine under an immense hollow trunk. Roots frame the route without blocking it.
	for side in [-1,1]:
		for tier in range(18): box(Vector3(side*(8-tier*.08),.4+tier*.65,-62),Vector3(4,.62,7),"timber",true)
		for step in range(10): box(Vector3(side*(7+step*.9),1.4-step*.1,-57+step*.5),Vector3(1.2,2.7-step*.2,1.5),"wood",true)
		for tier in range(9): box(Vector3(side*(7-tier*.8),11+tier*.55,-62),Vector3(2,.52,6),"wood")
		for antler in range(11):
			box(Vector3(side*(1+antler*.36),4+antler*.3,-62),Vector3(.4,.38,.4),"fur")
			if antler%3==0:
				for twig in range(4): box(Vector3(side*(1+antler*.36),4+antler*.3+twig*.3,-62-twig*.22),Vector3(.26,.3,.26),"fur")
	# Branches and a broad crown make the shrine read as a living tree, not a freestanding arch.
	for side in [-1,1]:
		for rib in range(9): box(Vector3(side*7-1.5+rib*.37,6,-58.42),Vector3(.2,11.5,.22),"wood")
		for branch in range(12): box(Vector3(side*(7+branch*.55),11+branch*.35,-62),Vector3(.65,.5,.65),"timber")
	for tier in range(6):
		for x in range(-17+tier,18-tier):
			for z in range(-8+tier/2,9-tier/2):
				if x*x/4+z*z>95-tier*5: continue
				box(Vector3(x*.85,14+tier*.6,-62+z*.85),Vector3(.9,.58,.9),"roots_leaf" if (x+z+tier)%4 else "roots_moss")
	box(Vector3(0,3.3,-62),Vector3(1.2,1.3,1.7),"fur")
	for id: String in NODES:
		if id=="stag_echo": continue
		var p: Vector3=NODES[id]; _sign(ORIGIN+p+Vector3.UP*2,NAMES[id])
		if id in ["keeper","steward","hunter","amber_healer"]:
			var npc:=Visual.new(); npc.position=ORIGIN+p; npc.rotation.y=PI; add_child(npc)
			var model:=State.new()
			for slot in ["head","chest","hands","legs","feet"]: model.equip(model.add_item(("cloth_" if id=="keeper" else "leather_")+slot),slot)
			if id=="amber_healer": model.equipment.main_hand=""; model.equipment.off_hand=""
			npc.build(model)
		elif id.begins_with("bed_"):
			box(p+Vector3.UP*.2,Vector3(1.8,.35,1.4),"wood")
			box(p+Vector3.UP*.4,Vector3(1.5,.12,1.1),"stone_dark")
		elif id!="return":
			box(p+Vector3.UP*.45,Vector3(1.4,.9,1),"wood" if "cache" in id else "stone_dark")
			box(p+Vector3.UP*.95,Vector3(1.6,.12,1.2),"roots_moss")
		if ROOT_GUARDS.has(id):
			root_lights[id]=b.piece(self,"roots_blight",ORIGIN+p+Vector3.UP*1.4,Vector3(.6,.65,.6))
			for spoke in range(8):
				var angle: float=TAU*spoke/8
				for step in range(6): box(p+Vector3(cos(angle)*(1+step*.35),.35-step*.04,sin(angle)*(1+step*.35)),Vector3(.38,.5-step*.05,.38),"wood")
	amber_stumps=Node3D.new(); amber_stumps.position=ORIGIN; add_child(amber_stumps)
	for i in range(3):
		var base:=Vector3(19,0,-12-i*4)
		var tree:=Node3D.new(); tree.position=ORIGIN+base; add_child(tree); amber_trees.append(tree)
		b.piece(tree,"timber",Vector3(0,1.6,0),Vector3(.65,3.2,.65))
		var crown: MeshInstance3D=b.piece(tree,"roots_blight",Vector3(0,3.4,0),Vector3(2.2,1.4,2.2)); amber_crowns.append(crown)
		for side in [-1,1]: b.piece(tree,"gold",Vector3(side*.36,1.8,.15),Vector3(.18,.35,.22))
		if i>0: b.piece(amber_stumps,"wood",base+Vector3.UP*.2,Vector3(.8,.4,.8))
	ward=b.piece(self,"roots_blight",ORIGIN+Vector3(0,3,-64),Vector3(5,.2,5))
	record_mesh=b.piece(self,"roots_glow",ORIGIN+NODES.record+Vector3.UP*1.3,Vector3(1,.3,.7))
	wild_growth=Node3D.new(); add_child(wild_growth); tended_growth=Node3D.new(); add_child(tended_growth)
	for side in [-1,1]:
		for i in range(12):
			var p:=ORIGIN+Vector3(side*(4+i%3*2),0,-30-i*2)
			for leaf in range(7):
				var q:=p+Vector3(sin(leaf*2.4)*.65,.25+leaf*.12,cos(leaf*2.4)*.65)
				b.piece(wild_growth,"roots_moss",q,Vector3(.6,.35,.55))
				if leaf%3==0: b.piece(wild_growth,"roots_glow",q+Vector3.UP*.22,Vector3(.16,.12,.16))
		for row in range(4):
			var p:=ORIGIN+Vector3(side*8,0,-34-row*5)
			b.piece(tended_growth,"wood",p,Vector3(5,.2,2.5))
			for plant in range(6): b.piece(tended_growth,"roots_moss",p+Vector3(-2+plant*.8,.35,0),Vector3(.45,.6,.5))
	for p in [Vector3(0,0,29),Vector3(-5,0,-10),Vector3(5,0,-30),Vector3(0,0,-53)]: world._lantern(ORIGIN+p,false)
	for id in ["bed_west","bed_east","bed_south"]:
		var plant:=Node3D.new(); plant.position=ORIGIN+NODES[id]+Vector3.UP*.48; add_child(plant); seedlings[id]=plant
		for i in range(5): b.piece(plant,"roots_moss",Vector3((i%3-1)*.32,.2+(i%2)*.2,0),Vector3(.25,.5,.25))
	for repair in ["bridge","cistern"]:
		var dressing:=Node3D.new(); add_child(dressing); debt_repairs[repair]=dressing
		var base: Vector3=ORIGIN+NODES.foundation
		if repair=="bridge":
			for i in range(7): b.piece(dressing,"wood",base+Vector3(-1.5+i*.5,.65,2),Vector3(.45,.2,2))
			for side in [-1,1]: b.piece(dressing,"timber",base+Vector3(side*1.5,.3,2),Vector3(.25,.6,2))
		else:
			for side in [-1,1]:
				b.piece(dressing,"stone_dark",base+Vector3(side*1.1,.5,2),Vector3(.3,1,2.5))
				b.piece(dressing,"stone_dark",base+Vector3(0,.5,2+side*1.1),Vector3(2.2,1,.3))
			b.piece(dressing,"roots_glow",base+Vector3(0,.55,2),Vector3(1.8,.1,1.8))
	_build_stag()
	world.block_count+=b.finish(world); _sign(TRAIL+Vector3.UP*2,"Amberweald trail · Stag Shrine")
	var positions=[Vector3(-17,0,-20),Vector3(17,0,-29),Vector3(-13,0,-45),Vector3(0,0,-65)]
	for i in range(4):
		var enemy=preload("res://scripts/hollow_warden.gd").new() if i==3 else Enemy.new(); enemy.adventure=self; enemy.progress=state.roots; enemy.enemy_id="roots_"+str(i); enemy.role="boss" if i==3 else "mage" if i==1 else "archer" if i==2 else "guard"
		enemy.title="The Hollow Warden" if i==3 else "Blightbound Keeper"; enemy.health_override=300 if i==3 else 90; enemy.position=ORIGIN+positions[i]+Vector3.UP*.15
		enemy.armor_override="leather"; add_child(enemy); enemies.append(enemy)
func _sign(p: Vector3,label: String) -> void:
	var sign:=Label3D.new(); sign.position=p; sign.text=label; sign.font_size=22; sign.pixel_size=.003; sign.billboard=BaseMaterial3D.BILLBOARD_ENABLED; sign.visibility_range_begin=4.5; sign.visibility_range_end=18; add_child(sign)
func _ui() -> void:
	var layer:=CanvasLayer.new(); layer.layer=7; add_child(layer)
	preview_label=Label.new(); preview_label.position=Vector2(32,76); preview_label.text="STAG SHRINE PREVIEW · progress is not saved"; layer.add_child(preview_label)
	dialog=ColorRect.new(); dialog.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); dialog.color=Color("20271f"); layer.add_child(dialog)
	var center:=CenterContainer.new(); center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); dialog.add_child(center)
	var col:=VBoxContainer.new(); col.custom_minimum_size.x=720; col.add_theme_constant_override("separation",16); center.add_child(col)
	title=Label.new(); title.add_theme_font_size_override("font_size",25); col.add_child(title)
	description=Label.new(); description.custom_minimum_size=Vector2(720,230); description.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART; description.add_theme_font_size_override("font_size",18); col.add_child(description)
	options=VBoxContainer.new(); col.add_child(options)
	var close:=Button.new(); close.text="Return [ Esc ]"; close.custom_minimum_size.y=42; close.pressed.connect(func(): close_dialog(); world.player.set_paused(false)); col.add_child(close); dialog.hide()
func _button(label: String,id: String) -> void:
	var button:=Button.new(); button.text=label; button.custom_minimum_size.y=42; button.pressed.connect(func(): act(id)); options.add_child(button)
func enter() -> bool:
	if world.player.paused or "stonewake" not in state.story_completed: return false
	if inside: return true
	for chapter in [world.seal,world.winter,world.threshold,world.convergence,world.choir,world.lens,world.shore,world.archive_chapter,world.mountain,world.realms,world.adventure]:
		if chapter.inside: chapter.leave()
	stag.position=ORIGIN+STAG_STOPS[clampi(int(state.roots.get("stag_step",0))-1,0,3)]
	inside=true; world.player.position=ORIGIN+Vector3(0,.2,40); world.player.velocity=Vector3.ZERO; world.player.rotation=Vector3.ZERO
	for child in world.get_children():
		if child is WorldEnvironment:
			environment_backup=child.environment
			var env: Environment=environment_backup.duplicate(true); env.fog_light_color=Color("7a886d"); env.fog_density=.002; env.ambient_light_color=Color("bfc79c"); preload("res://scripts/regional_sky.gd").apply(env,"roots"); child.environment=env
	world.hud.world_map.selected_quest="roots"; world.hud.world_map.set_view(true); world.audio.sfx("portal")
	world.hud.announce("The Stag Shrine","Blight has silenced the grove. Two keepers disagree about the promise that can restore it."); return true
func leave() -> void:
	if not inside: return
	inside=false; world.adventure.clear_projectiles(); world.player.position=TRAIL+Vector3(0,.2,2.5); world.player.velocity=Vector3.ZERO
	for child in world.get_children():
		if child is WorldEnvironment and environment_backup!=null: child.environment=environment_backup
	for enemy in enemies:
		if not enemy.dead: enemy.position=enemy.home; enemy.health=enemy.maximum_health; enemy.velocity=Vector3.ZERO; enemy.windup=0; enemy._update_label()
func nearest() -> Dictionary:
	if not inside:
		if world.player.position.distance_to(TRAIL)<2.5: return {"kind":"roots","id":"trail","text":"[ E ] Travel to the Stag Shrine"}
		return {}
	for enemy in enemies:
		if enemy.dead and enemy.enemy_id not in state.roots.looted and world.player.position.distance_to(enemy.position)<2.5: return {"kind":"roots","id":enemy.enemy_id,"text":"[ E ] Recover woodland relics"}
	for id: String in NODES:
		if id=="stag_echo" and (not stag.visible or not stag_arrived()): continue
		if world.player.position.distance_to(interaction_position(id))<2.3: return {"kind":"roots","id":id,"text":"[ E ] "+NAMES[id]}
	return {}
func station_nearby() -> String:
	for id in ["forge","enchant","alchemy"]:
		if inside and world.player.position.distance_to(ORIGIN+NODES[id])<2.3: return id
	return ""
func interact(id: String) -> void:
	if world.player.paused or nearest().get("id","")!=id: return
	if id=="trail":
		if not enter(): world.hud.announce("The woodland trail","Complete Stonewake to follow the woodland lead.")
	elif id=="return": leave()
	elif id in ["forge","enchant","alchemy"]: world.hud.workshop.open(id)
	elif id.begins_with("roots_"): loot(id)
	else: open_dialog(id)
func _refresh() -> void:
	var amber_stage: int=int(state.roots.get("amber_stage",0))
	var logging: bool=state.roots.get("amber_choice","")=="logging"
	amber_stumps.visible=logging
	for i in range(amber_trees.size()):
		amber_trees[i].visible=not logging or i==0
		amber_crowns[i].material_override=world.blocks.materials["roots_leaf" if amber_stage>=4 and (i==0 or state.roots.get("amber_choice","")=="protect") else "roots_blight"]
	stag.visible=int(state.roots.get("stag_step",0)) in [1,2,3]
	for id in debt_repairs: debt_repairs[id].visible=state.roots.get("debt_choice","")==id
	for id in seedlings: seedlings[id].visible=id in state.roots.get("coven_beds",[])
	for id: String in ROOT_GUARDS: root_lights[id].material_override=world.blocks.materials["roots_glow" if id in state.roots.cleansed else "roots_blight"]
	ward.visible=state.roots.cleansed.size()!=3
	record_mesh.visible=not state.roots.record
	wild_growth.visible=state.roots.choice=="wild"; tended_growth.visible=state.roots.choice=="tended"
func open_dialog(id: String) -> void:
	subject=id; world.player.dialog_open=true; world.player.set_paused(true); dialog.show()
	for child in options.get_children(): options.remove_child(child); child.queue_free()
	title.text=NAMES[id].to_upper()
	var p: Dictionary=state.roots
	if id in ["amber_healer","amber_plot","amber_bench"]: amber_dialog(); return
	if id in ["hunter","stag_echo"]: stag_dialog(); return
	if (id=="keeper" and p.get("debt_choice","")!="") or (id in ["steward","record","heart"] and p.get("promise_started",false)):
		promise_dialog(); return
	if (id=="keeper" and p.get("coven_oath","")!="") or (id in ["steward","foundation","spring"] and p.get("debt_started",false)):
		debt_dialog(); return
	if id=="foundation":
		description.text="Old roots press against the lodge footing. Maelin may know what promise was forgotten here."; return
	if id=="keeper" and p.rewarded:
		coven_dialog(); return
	if id.begins_with("bed_"):
		description.text="The seeds have survived, but the soil remains blighted. Each bed needs two herbs, two water and one Amber Resin."
		if not p.get("coven_started",false): description.text+="\n\nSpeak with Maelin after recovering the woodland memory."
		elif id in p.get("coven_beds",[]): description.text+="\n\nNew shoots are growing here."
		else: _button("Revive seedbed · 2 herbs / 2 water / 1 Amber Resin","coven_tend")
	elif id in ["keeper","steward"]:
		description.text="MAELIN · BRIAR COVEN\n\nThe roots remember the first crossing between worlds. Blight is feeding on that memory. Free the three roots and confront the Hollow Warden. I would let the grove grow wild again, and move our gathering beyond its bounds. Our healers will tend the people, not the sacred trees.\n\nWild pact reward: Groveheart Vest, improving healing draughts by 25%, and its forging pattern." if id=="keeper" else "OREN · WOODLAND STEWARD\n\nOur settlement needs wood and medicine. Let us plant as much as we take, mark protected trees, and grow herbs in beds outside the shrine. A living pact should have room for people.\n\nTended pact reward: Pactkeeper Axe, restoring 18 stamina on melee kills, and its forging pattern."
		if id=="keeper" and state.archive.recipient=="lantern": description.text+="\n\nYou gave Pinehall's atlas to the Lantern. I still need your help here; that choice does not close this grove."
		if not p.accepted: _button("Help recover the woodland memory","accept")
		if id not in p.heard: _button("Hear this proposal","hear")
		if p.record and not p.rewarded: _button("Report the recovered memory · claim pact equipment","reward")
		description.text+="\n\n"+objective()+"\nCoven membership requires a separate oath."
	elif ROOT_GUARDS.has(id):
		description.text="A blightbound keeper feeds this root. Defeat its keeper, then use two herbs and two water to cleanse the root. The two supply caches hold enough to restore all three."
		if id in p.cleansed: description.text+="\n\nThe root is alive again."
		elif not p.accepted: description.text+="\n\nSpeak with Maelin or Oren first."
		elif ROOT_GUARDS[id] not in p.defeated: description.text+="\n\nIts blightbound keeper still lives."
		else: _button("Cleanse root · 2 herbs + 2 water","cleanse")
	elif id=="heart":
		description.text="The renewed roots loosen the Warden's hold on the shrine. After defeating it, choose a permanent pact. Both preserve the woodland memory and the road to the First Threshold."
		if p.choice!="": description.text+="\n\nPact kept: "+("Wild grove · gathering moves outside the sacred ground." if p.choice=="wild" else "Tended grove · herb beds and careful harvesting.")
		elif p.heard.size()!=2: description.text+="\n\nHear both Maelin and Oren before deciding."
		elif "roots_3" not in p.defeated: description.text+="\n\nCleanse the three roots and defeat the Hollow Warden first."
		else:
			_button("Keep the grove wild · permanent · healing armor pattern","wild")
			_button("Renew the tended pact · permanent · stamina axe pattern","tended")
	elif id=="record":
		description.text="WOODLAND MEMORY\n\n'When the first road opened above the sky, its travelers drew strength from the land below. We closed the root gates to stop the hunger. Let no crossing be powered by a living world again.'\n\nThis warning adds a vital constraint to the space expedition. The shore, observatory and Choir evidence are still required."
		if p.choice=="": description.text="The memory is silent. Defeat the Warden and renew a pact at the Heart of the Stag."
		elif not p.record: _button("Copy the woodland memory into the expedition record","record")
		else: description.text+="\n\nSafely recorded; report to either keeper."
	else:
		description.text="Healer's supplies: herbs, water, Heartwood and Amber Resin. Enough cleansing supplies survive across these two caches to restore the grove."
		if id not in p.caches: _button("Collect the supplies","cache")
		else: description.text+="\n\nAlready collected."
func act(id: String) -> bool:
	if not dialog.visible or not inside or not NODES.has(subject) or world.player.position.distance_to(interaction_position(subject))>=2.3: return false
	var p: Dictionary=state.roots
	var success:=false
	if id=="amber_start" and subject=="amber_healer" and int(p.get("amber_stage",0))==0:
		p.amber_stage=1; success=true
	elif id=="amber_sample" and subject=="amber_plot" and int(p.get("amber_stage",0))==1:
		p.amber_stage=2; success=true
	elif id=="amber_mix" and subject=="amber_bench" and int(p.get("amber_stage",0))==2:
		if not state.can_pay({"herb":3,"water":2}): description.text="Bring 3 herbs and 2 water for Edda's measured treatment. Nothing has been spent."; return false
		state.materials.herb-=3; state.materials.water-=2; p.amber_stage=3; success=true; world.audio.sfx("enchant")
	elif id=="amber_test" and subject=="amber_plot" and int(p.get("amber_stage",0))==3:
		p.amber_stage=4; success=true
	elif id in ["amber_protect","amber_logging"] and subject=="amber_healer" and int(p.get("amber_stage",0))==4 and p.get("amber_choice","")=="":
		p.amber_choice="protect" if id=="amber_protect" else "logging"; state.gold+=100 if p.amber_choice=="protect" else 160
		var uid: String=state.add_item("groveheart_chest" if p.amber_choice=="protect" else "pactkeeper_axe",2,"vigor" if p.amber_choice=="protect" else "fleet")
		state.inventory[uid].favorite=true; state.inventory[uid].custom_name="Amber's Tomorrow" if p.amber_choice=="protect" else "The Lean Season"
		world.adventure.grant_materials({"amber_resin":6} if p.amber_choice=="protect" else {"heartwood":10}); success=true; world.audio.sfx("quest")
	if id=="stag_start" and subject=="hunter" and p.rewarded and int(p.get("stag_step",0))==0:
		p.stag_step=1; stag.position=ORIGIN+STAG_STOPS[0]; success=true
	elif id=="stag_follow" and subject=="stag_echo" and int(p.get("stag_step",0)) in [1,2,3] and stag_arrived():
		p.stag_step+=1; success=true
	elif id=="stag_forgive" and subject=="hunter" and int(p.get("stag_step",0))==4:
		p.stag_step=5; state.gold+=100; world.adventure.grant_materials({"heartwood":6,"amber_resin":4}); success=true
	elif id=="accept" and subject in ["keeper","steward"] and not p.accepted: p.accepted=true; success=true
	elif id=="hear" and subject in ["keeper","steward"] and subject not in p.heard: p.heard.append(subject); success=true
	elif id=="cache" and subject in ["camp_cache","grove_cache"] and subject not in p.caches:
		p.caches.append(subject); world.adventure.grant_materials({"herb":4,"water":4,"heartwood":4,"amber_resin":2}); success=true
	elif id=="cleanse" and ROOT_GUARDS.has(subject) and p.accepted and ROOT_GUARDS[subject] in p.defeated and subject not in p.cleansed:
		if not state.can_pay({"herb":2,"water":2}): description.text="The root needs 2 herbs and 2 water. Check the healer's chest or gatherer's pack."; world.audio.sfx("error"); return false
		state.materials.herb-=2; state.materials.water-=2; p.cleansed.append(subject); success=true; world.audio.sfx("enchant")
	elif id in ["wild","tended"] and subject=="heart" and p.accepted and p.heard.size()==2 and p.cleansed.size()==3 and "roots_3" in p.defeated and p.choice=="": p.choice=id; success=true; world.audio.sfx("quest")
	elif id=="record" and subject=="record" and p.choice!="" and not p.record: p.record=true; success=true
	elif id=="reward" and subject in ["keeper","steward"] and p.record and not p.rewarded:
		p.rewarded=true; state.story_completed.append("roots"); state.blueprints.append("woodland"); state.blueprints.append("roots_"+p.choice); state.gold+=140
		var uid: String=state.add_item("groveheart_chest" if p.choice=="wild" else "pactkeeper_axe",2,"vigor" if p.choice=="wild" else "fleet"); state.inventory[uid].favorite=true
		world.adventure.grant_materials({"heartwood":8,"amber_resin":5,"leather":5}); success=true
	elif id=="coven_start" and subject=="keeper" and p.rewarded and not p.get("coven_started",false):
		p.coven_started=true; world.adventure.grant_materials({"herb":6,"water":6,"amber_resin":3}); success=true
	elif id=="coven_tend" and subject in ["bed_west","bed_east","bed_south"] and p.get("coven_started",false) and subject not in p.get("coven_beds",[]):
		if not state.can_pay({"herb":2,"water":2,"amber_resin":1}): description.text="Each bed needs two herbs, two water and one Amber Resin. Bring more supplies or return to the grove's caches."; return false
		state.materials.herb-=2; state.materials.water-=2; state.materials.amber_resin-=1
		if not p.has("coven_beds"): p.coven_beds=[]
		p.coven_beds.append(subject); success=true
	elif id.begins_with("coven_oath:") and subject=="keeper" and p.get("coven_beds",[]).size()==3 and p.get("coven_oath","")=="":
		var oath:=id.get_slice(":",1)
		if oath not in ["shelter","medicine"]: return false
		p.coven_oath=oath; state.gold+=100
		var uid: String=state.add_item("seedkeeper_charm",1); state.inventory[uid].favorite=true
		if "coven_seedkeeper" not in state.blueprints: state.blueprints.append("coven_seedkeeper")
		world.adventure.grant_materials({"heartwood":4} if oath=="shelter" else {"herb":8}); success=true
	elif id=="debt_start" and subject=="keeper" and p.get("coven_oath","")!="" and not p.get("debt_started",false):
		p.debt_started=true; success=true
	elif id=="debt_inspect" and subject in ["foundation","spring","steward"] and p.get("debt_started",false) and subject not in p.get("debt_evidence",[]):
		if not p.has("debt_evidence"): p.debt_evidence=[]
		p.debt_evidence.append(subject); success=true
	elif id.begins_with("debt_choose:") and subject=="keeper" and p.get("debt_evidence",[]).size()==3 and p.get("debt_choice","")=="":
		var choice:=id.get_slice(":",1)
		if choice not in ["bridge","cistern"]: return false
		if not state.can_pay({"heartwood":4,"amber_resin":2}): description.text="Both repairs need 4 Heartwood and 2 Amber Resin. Gather supplies, then return; your evidence is safe."; return false
		state.materials.heartwood-=4; state.materials.amber_resin-=2
		p.debt_choice=choice; state.gold+=140
		var uid: String=state.add_item("pactmender_ring",2); state.inventory[uid].favorite=true
		if "coven_pactmender" not in state.blueprints: state.blueprints.append("coven_pactmender")
		success=true
	elif id=="promise_start" and subject=="keeper" and p.get("debt_choice","")!="" and not p.get("promise_started",false):
		p.promise_started=true; success=true
	elif id=="promise_hear" and subject in ["keeper","steward","record"] and p.get("promise_started",false) and subject not in p.get("promise_heard",[]):
		if not p.has("promise_heard"): p.promise_heard=[]
		p.promise_heard.append(subject); success=true
	elif id.begins_with("promise_choose:") and subject=="heart" and p.get("promise_started",false) and p.get("promise_heard",[]).size()==3 and p.get("promise_choice","")=="":
		var choice:=id.get_slice(":",1)
		if choice not in ["renew","shared"]: return false
		p.promise_choice=choice; state.gold+=200
		var uid: String=state.add_item("oldpromise_talisman",2); state.inventory[uid].favorite=true
		if "coven_elder" not in state.blueprints: state.blueprints.append("coven_elder")
		world.adventure.grant_materials({"heartwood":6} if choice=="renew" else {"heartwood":3,"amber_resin":3}); success=true
	if success:
		if id.begins_with("promise_"): world.hud.world_map.selected_quest="briar_coven_3"
		if id.begins_with("debt_"): world.hud.world_map.selected_quest="briar_coven_2"
		if id.begins_with("coven_"): world.hud.world_map.selected_quest="briar_coven_1"
		if id.begins_with("amber_"): world.hud.world_map.selected_quest="side_alderrest"
		if id.begins_with("stag_"): world.hud.world_map.selected_quest="side_stag_shrine"
		state._commit()
		if id in ["stag_start","stag_follow"]:
			close_dialog(); world.player.set_paused(false); world.hud.announce("The Stag Without a Shadow",stag_objective())
		else: open_dialog(subject)
	return success
func can_damage_enemy(id: String) -> bool:
	return id!="roots_3" or state.roots.cleansed.size()==3
func barrier_message() -> String:
	return "Three blighted roots protect the Hollow Warden"
func mark_defeated(id: String) -> void:
	if id not in state.roots.defeated: state.roots.defeated.append(id); state._commit()
func loot(id: String) -> bool:
	if id not in state.roots.defeated or id in state.roots.looted: return false
	state.roots.looted.append(id); state.gold+=20; world.adventure.grant_materials({"heartwood":3,"amber_resin":2})
	if id=="roots_3":
		var uid: String=state.add_item("amberbough_bow",2,"fleet"); state.inventory[uid].favorite=true
	else: state.consumables.healing_draught=int(state.consumables.get("healing_draught",0))+1
	state._commit(); world.hud.announce("Woodland relics recovered","Heartwood and Amber Resin added to your collection."); return true
func objective() -> String:
	var p: Dictionary=state.roots
	if p.get("promise_started",false): return promise_objective()
	if p.get("debt_started",false): return debt_objective()
	if p.get("coven_started",false): return coven_objective()
	if p.rewarded: return "Woodland memory delivered · "+("Wild grove" if p.choice=="wild" else "Tended grove")+" pact kept"
	if not p.accepted: return "Speak with Maelin or Oren at the woodland lodge"
	if p.cleansed.size()!=3: return "Defeat the blightbound keepers and cleanse three roots · %d / 3" % p.cleansed.size()
	if "roots_3" not in p.defeated: return "The Warden is vulnerable · defeat it beneath the hollow tree"
	if p.heard.size()!=2: return "Hear both Maelin's and Oren's proposals"
	if p.choice=="": return "Choose a permanent pact at the Heart of the Stag"
	if not p.record: return "Copy the woodland memory behind the shrine"
	return "Report to Maelin or Oren for your pact equipment and patterns"
func close_dialog() -> void:
	dialog.hide(); world.player.dialog_open=false
func check_fall() -> void:
	var p: Vector3=world.player.position-ORIGIN
	if p.y< -8 or absf(p.x)>43 or p.z< -82 or p.z>43: world.player.position=ORIGIN+Vector3(0,.2,40); world.player.velocity=Vector3.ZERO
func fire(origin: Vector3,direction: Vector3,damage: float,hostile: bool,source: CollisionObject3D,magic: bool) -> void:
	world.adventure.fire(origin,direction,damage,hostile,source,magic)
func line_clear(from: Vector3,to: Vector3,source: CollisionObject3D,target_body: CollisionObject3D=null) -> bool:
	return world.adventure.line_clear(from,to,source,target_body)
func _process(delta: float) -> void:
	if inside and not world.player.paused and stag.visible and world.player.position.distance_to(stag.position)<16:
		var target: Vector3=ORIGIN+STAG_STOPS[int(state.roots.stag_step)]
		stag.position=stag.position.move_toward(target,delta*2.2)
	preview_label.visible="--roots-preview" in OS.get_cmdline_user_args() and not world.player.paused
	if feedback_time>0: world.adventure.feedback=feedback; world.adventure.feedback_time=feedback_time; feedback_time=maxf(0,feedback_time-delta)

func coven_dialog() -> void:
	var p: Dictionary=state.roots
	description.text="THE GROVE THAT REFUSED SPRING\n\nMaelin: The great roots live, but these seedbeds still refuse spring. They have learned stubbornness from the council. Let us try water before forming a committee.\n\nYour "+p.choice+" pact remains intact; these beds stand outside the sacred grove."
	if p.get("coven_oath","")!="":
		description.text="BRIAR COVEN · SEEDKEEPER\n\n"+("You promised to shelter renewal and keep the sacred grove's boundaries." if p.coven_oath=="shelter" else "You promised to share medicine grown beyond the sacred grove.")+" Your earlier woodland pact is unchanged. Your Seedkeeper Charm pattern is learned."
	elif not p.get("coven_started",false): _button("Begin the Coven trial · receive seedbed supplies","coven_start")
	elif p.get("coven_beds",[]).size()<3: description.text+="\n\nSeedbeds restored: %d / 3. Tend the west, east and south beds near the settlement, then return." % p.get("coven_beds",[]).size()
	else:
		description.text+="\n\nTake an oath to become a Seedkeeper. Either promise grants 100 gold, a Fine Seedkeeper Charm and its forge pattern."
		_button("Shelter the renewal · 4 Heartwood","coven_oath:shelter")
		_button("Share the medicine · 8 herbs","coven_oath:medicine")
func coven_objective() -> String:
	var p: Dictionary=state.roots
	if p.get("coven_oath","")!="": return "Coven Seedkeeper · "+("Shelter renewal" if p.coven_oath=="shelter" else "Share medicine")
	if not p.get("coven_started",false): return "Restore the woodland memory, then speak with Maelin about the seedbeds"
	return "Revive the settlement seedbeds · %d / 3 · return to Maelin" % p.get("coven_beds",[]).size()

func debt_dialog() -> void:
	var p: Dictionary=state.roots
	if subject=="keeper":
		description.text="A DEBT OF SAP AND STONE\n\nMaelin: The lodge was built over an old grove. The roots are collecting a debt the dead neglected to mention. Very considerate of them.\n\nYour "+p.coven_oath+" oath stands. Inspect the lodge foundation and Spring root, then hear Oren before proposing a repair."
		if p.get("debt_choice","")!="":
			description.text="BRIAR COVEN · PACTMENDER\n\n"+("A raised timber crossing leaves the buried roots room to grow. Oren agrees to keep the footing clear and Maelin will inspect it each spring." if p.debt_choice=="bridge" else "A lined cistern catches runoff before it erodes the old roots. Oren agrees to maintain it and Maelin will watch the grove's water.")+"\n\nThe settlement stays. Your woodland pact and Seedkeeper oath remain intact. The Pactmender Ring pattern is learned."
		elif not p.get("debt_started",false): _button("Investigate the settlement's old debt","debt_start")
		elif p.get("debt_evidence",[]).size()==3:
			description.text="A DEBT OF SAP AND STONE\n\nThe footing pinches living roots; runoff strips their soil. Oren needs a safe lodge, not more land. Maelin accepts either repair with yearly care. Nobody needs to lose their home.\n\nEither repair costs 4 Heartwood and 2 Amber Resin and grants Pactmender rank, 140 gold, a Superior Pactmender Ring and its forge pattern."
			_button("Raise a timber crossing · protect root space","debt_choose:bridge")
			_button("Line a catchment cistern · protect root water","debt_choose:cistern")
		else: description.text+="\n\n"+debt_objective()
	else:
		description.text={"foundation":"Buried roots are wedged against the lodge footing. A raised crossing could spread the load without cutting them.","spring":"Rainwater carries soil away from the old roots. A lined catchment could slow the runoff without draining the sacred spring.","steward":"Oren: We need a safe lodge and water for the beds. We can maintain a crossing or a cistern. Evicting everyone would simplify the census, but I prefer my neighbors alive and indoors."}[subject]
		if subject not in p.get("debt_evidence",[]): _button("Record the finding" if subject!="steward" else "Record Oren's agreement","debt_inspect")
		else: description.text+="\n\nRecorded. Return to Maelin when all three findings are gathered."
func debt_objective() -> String:
	var p: Dictionary=state.roots
	if p.get("debt_choice","")!="": return "Coven Pactmender · "+("Root crossing agreed" if p.debt_choice=="bridge" else "Catchment cistern agreed")
	if not p.get("debt_started",false): return "Become a Seedkeeper, then ask Maelin about the lodge"
	return "Inspect foundation and Spring root; hear Oren · %d / 3 · return to Maelin" % p.get("debt_evidence",[]).size()

func promise_dialog() -> void:
	var p: Dictionary=state.roots
	if p.get("promise_choice","")!="":
		description.text="BRIAR COVEN · ROOTWARDEN\n\n"+("The oldest protections are renewed. The Coven keeps the sacred boundaries, with the settlement's repair and yearly obligations written into the pact." if p.promise_choice=="renew" else "A shared charter now names the town and Coven as joint caretakers. The sacred boundaries remain; both must agree to changes and record their yearly care.")+"\n\nYour "+p.choice+" woodland pact, "+p.coven_oath+" oath and "+("timber crossing" if p.debt_choice=="bridge" else "catchment cistern")+" stand. The woodland memory and Lantern records remain preserved. Your Old Promise Talisman pattern is learned."
	elif subject=="keeper":
		description.text="THE LAST OLD PROMISE\n\nMaelin: The lodge stands and the roots breathe. Now we must decide who keeps the promise when we are gone. I would renew the old protections, with your repair written into them.\n\nThe last steward promised to serve forever. We have since clarified that this is not an instruction to rise from the grave."
		if not p.get("promise_started",false): _button("Begin the final pact review","promise_start")
		elif "keeper" not in p.get("promise_heard",[]): _button("Record Maelin's case for renewal","promise_hear")
		else: description.text+="\n\n"+promise_objective()
	elif subject=="steward":
		description.text="OREN · A PROMISE PEOPLE CAN KEEP\n\nA pact should name the work, the people responsible and when we check it. Let the town and Coven share that duty. Your repair is the first obligation; the sacred boundaries stay."
		if "steward" not in p.get("promise_heard",[]): _button("Record Oren's shared charter","promise_hear")
		else: description.text+="\n\nRecorded. Hear the woodland memory, then decide at the Stag Heart."
	elif subject=="record":
		description.text="THE OLDEST WARNING\n\nThe memory describes a crossing fed by a living world. The pact closed the root gates to stop that hunger. Whoever keeps the promise must forbid another crossing from consuming the grove.\n\nPreserve this testimony. Neither proposal requires destroying it."
		if "record" not in p.get("promise_heard",[]): _button("Record the memory's condition","promise_hear")
		else: description.text+="\n\nCondition recorded. Return to the Stag Heart."
	else:
		description.text="THE LAST OLD PROMISE\n\nHear Maelin, Oren and the woodland memory before deciding. Both paths preserve your earlier promises and forbid feeding another crossing with the grove."
		if p.get("promise_heard",[]).size()==3:
			description.text+="\n\nEither decision grants Rootwarden rank, 200 gold, a Superior Old Promise Talisman and its forge pattern. This decision is permanent."
			_button("Renew the old protections · 6 Heartwood","promise_choose:renew")
			_button("Adopt a shared charter · 3 Heartwood / 3 Amber Resin","promise_choose:shared")
		else: description.text+="\n\n"+promise_objective()
func promise_objective() -> String:
	var p: Dictionary=state.roots
	if p.get("promise_choice","")!="": return "Coven Rootwarden · "+("Old protections renewed" if p.promise_choice=="renew" else "Shared charter adopted")
	if not p.get("promise_started",false): return "Resolve the lodge's debt, then ask Maelin about the oldest pact"
	return "Hear Maelin, Oren and the woodland memory · %d / 3 · decide at the Stag Heart" % p.get("promise_heard",[]).size()

func interaction_position(id: String) -> Vector3:
	return stag.position if id=="stag_echo" else ORIGIN+NODES[id]
func stag_arrived() -> bool:
	var step: int=int(state.roots.get("stag_step",0))
	return step in [1,2,3] and stag.position.distance_to(ORIGIN+STAG_STOPS[step])<.05
func _build_stag() -> void:
	stag=Node3D.new(); add_child(stag); stag.position=ORIGIN+STAG_STOPS[0]
	preload("res://scripts/refined_woodland.gd").stag(stag)
func stag_objective() -> String:
	var step: int=int(state.roots.get("stag_step",0))
	if not state.roots.rewarded: return "Restore the woodland memory, then find hunter Fenn beside the southern road."
	if step==0: return "Speak to hunter Fenn beside the southern road in Stag Shrine."
	if step<4: return "Follow the pale stag north along the central path · listen at stop %d / 3. It waits if you fall behind." % step
	if step==4: return "Return the stag's forgiveness to Fenn beside the southern road."
	return "Quest complete · Fenn will tend the grove instead of hunting its guardian."
func stag_dialog() -> void:
	var step: int=int(state.roots.get("stag_step",0))
	description.text=stag_objective()
	if subject=="hunter":
		if not state.roots.rewarded: return
		if step==0:
			description.text="Fenn: I swore never to hunt the white stag. Then winter came, and promises proved poor soup. I wounded it. Now it waits for me every dusk.\n\nI asked a priest if it was a curse. He charged extra for uncertainty.\n\nPlease follow it. I cannot make my legs do it."
			_button("Follow the pale stag","stag_start")
		elif step==4:
			description.text="Fenn: It wanted the arrow returned to the earth? Not my blood?\n\nYou tell him what the grove showed you: a hungry winter, a frightened hunter, and a guardian still leaving room for both.\n\nFenn: Then I will plant where I once set traps. Something should grow from this besides guilt."
			_button("Offer forgiveness · 100 gold, 6 Heartwood, 4 Amber Resin","stag_forgive")
	elif step in [1,2,3] and stag_arrived():
		description.text=["", "The stag bows beside the road. In its pale ribs you see a winter camp: an empty pot, a child asleep, a hunter breaking his oath.", "The stag lowers its antlers. An old arrow crumbles into roots. The grove remembers the wound without asking for another.", "At the living shrine, the stag turns toward Fenn's camp. A vision: traps replaced by seedlings. Carry that invitation back to the hunter."][step]
		_button("Listen, then follow" if step<3 else "Carry the invitation back to Fenn","stag_follow")

func amber_objective() -> String:
	var p: Dictionary=state.roots
	if p.get("amber_choice","")!="": return "A Harvest of Amber complete · "+("Edda treats the remaining trees and suspends tapping while the grove recovers." if p.amber_choice=="protect" else "Two failing trees are cut for emergency supplies; the treated tree is preserved for future seed.")
	return ["Speak to herbalist Edda near the woodland camp about Alderrest's amber growers.","Collect a bark sample at the amber trial plot east of the central woodland path.","Prepare Edda's treatment at the camp's amber bench · 3 herbs and 2 water.","Test the treatment on the first tree at the amber plot.","The test tree responds. Return to Edda to decide the rest of the plot's future."][int(p.get("amber_stage",0))]
func amber_dialog() -> void:
	var p: Dictionary=state.roots
	var stage: int=int(p.get("amber_stage",0))
	description.text=amber_objective()
	if subject=="amber_healer":
		if stage==0:
			description.text="Edda: Alderrest's growers keep a trial plot here. Blight entered the tapping wounds. Our last expert prescribed optimism. The trees remain unconvinced. Bring a bark sample; I have a treatment worth testing."
			_button("Investigate the amber blight","amber_start")
		elif stage==4 and p.get("amber_choice","")=="":
			description.text="Edda: The test tree is responding, but this season's resin is lost. Treating the others means a lean winter. Cutting the two failing trees pays for immediate supplies while we preserve the treated tree for seed.

Protect: 100 gold, Superior Vigor grove armor, 6 Amber Resin from my reserve. Limited logging: 160 gold, Superior Fleet axe, 10 Heartwood. This decision is permanent."
			_button("Treat the grove and suspend this season's tapping","amber_protect")
			_button("Authorize two trees for emergency supplies","amber_logging")
	elif subject=="amber_plot":
		if stage==1:
			description.text="Grey blight follows deep tapping cuts. Fresh growth above an untouched branch is still healthy. Edda's treatment may stop the spread if the wounds are allowed to close."
			_button("Collect bark and resin samples","amber_sample")
		elif stage==3: _button("Apply the prepared treatment to the first tree","amber_test")
	elif subject=="amber_bench" and stage==2:
		description.text="Edda's notes call for a diluted herb wash and a full season without tapping. Prepare a measured trial dose: 3 herbs and 2 water."
		_button("Prepare the trial treatment · 3 herbs + 2 water","amber_mix")
