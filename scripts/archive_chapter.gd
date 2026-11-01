extends Node3D
const State = preload("res://scripts/character_state.gd")
const Visual = preload("res://scripts/character_visual.gd")
const Enemy = preload("res://scripts/enemy.gd")
const CampDetail = preload("res://scripts/pinehall_detail.gd")
const Ground = preload("res://scripts/pinehall_terrain.gd")
const ORIGIN := Vector3(-800,0,0)
const TRAIL := Vector3(-26,0,17)
const NODES := {"apprentice_notice":Vector3(0,0,22),"apprentice":Vector3(5,0,-58),"trial":Vector3(0,0,-53),"return":Vector3(0,0,36),"lantern":Vector3(-14,0.25,8),"briar":Vector3(14,0.25,8),"atlas":Vector3(0,0,-65),"notes":Vector3(-6,0,-36),"cache_west":Vector3(-8,0,-56),"cache_east":Vector3(8,0,-39),"forge":Vector3(-7,0,16),"enchant":Vector3(7,0,16)}
const NAMES := {"apprentice_notice":"Missing apprentice · college notice","apprentice":"Iven · missing apprentice","trial":"The Uncatalogued Door","return":"Western trail · Frostmere","lantern":"Mereth · Veiled Lantern","briar":"Aelin · Briar Coven","atlas":"The Missing Atlas","notes":"Archivist's testimony","cache_west":"Sealed root cache","cache_east":"Sealed memory cache","forge":"Pinehall forge","enchant":"Root-and-rune altar"}
var apprentice: Node3D
var apprentice_label: Label3D
var world: Node3D
var state: RefCounted
var environment_backup: Environment
var inside := false
var enemies: Array[CharacterBody3D] = []
var feedback := ""
var feedback_time := 0.0
var dialog: ColorRect
var title: Label
var description: Label
var options: VBoxContainer
var subject := ""
var preview_label: Label
var relic: MeshInstance3D

func _ready() -> void:
	state=world.player.character; _build(); _ui()
	state.changed.connect(_refresh); _refresh()
func box(pos: Vector3,size: Vector3,key: String,solid: bool=false) -> void:
	world.blocks.add(key,ORIGIN+pos,size)
	if solid: world._solid(ORIGIN+pos,size)
func _build() -> void:
	var b: RefCounted=world.blocks
	var ground:=StaticBody3D.new(); ground.name="PinehallGround"; ground.position=ORIGIN; ground.set_meta("footstep","pinehall_ground")
	var collision:=CollisionShape3D.new(); var shape:=ConcavePolygonShape3D.new(); shape.set_faces(Ground.collision_vertices())
	collision.shape=shape; ground.add_child(collision); add_child(ground)
	for x in range(-43,44):
		for z in range(-82,47):
			var rise:=Ground.height_at(x,z)
			if rise>.05: box(Vector3(x,rise/2-.16,z),Vector3(.98,rise,.98),"earth")
			box(Vector3(x,rise-.12,z),Vector3(1.01,.15,1.01),"path" if CampDetail.path_at(x,z) else "grass")
	for h in [[-14,4,10,12,"lantern_house"],[14,4,10,12,"coven_house"],[-23,26,8,9,"cartographer"]]: world._house(ORIGIN+Vector3(h[0],0,h[1]),h[2],h[3],3.8,false,h[4])
	# Layered conifers surround the inhabited clearing and the ruined library.
	for site: Vector4 in Ground.tree_sites():
		var at:=Vector3(site.x,site.y,site.z)
		box(at+Vector3.UP*site.w*.44,Vector3(.5,site.w*.88,.5),"timber",true)
		preload("res://scripts/woodland_pine.gd").build(self,site)
	# A roofless entrance leads into two connected archive chambers.
	box(Vector3(0,-0.15,-50),Vector3(21,0.1,44),"stone")
	for side in [-1,1]:
		box(Vector3(side*10,2.4,-50),Vector3(0.7,4.8,44),"stone_dark",true)
		for z in [-30,-42,-54,-68]:
			for tier in range(11): box(Vector3(side*8.7,0.24+tier*0.44,z),Vector3(1.1,0.42,1.1),"stone",true)
		for z in [-36,-50,-62]:
			box(Vector3(side*9.1,1.6,z),Vector3(1.1,3.2,3.6),"wood",true)
			for shelf in range(5):
				for book in range(9): box(Vector3(side*8.48,0.3+shelf*0.55,z-1.5+book*0.36),Vector3(0.14,0.42,0.26),["cloth","leather","gold"][book%3])
	for z in [-28,-46]:
		for x in [-6.4,6.4]: box(Vector3(x,2.3,z),Vector3(7.2,4.6,0.8),"stone_dark",true)
		box(Vector3(0,4.3,z),Vector3(6,0.6,1),"stone",true)
		# Small masonry blocks, stepped portal and broken crown retain the voxel silhouette.
		for side in [-1,1]:
			for row in range(9):
				for col in range(7):
					box(Vector3(side*(3.3+col*0.95),0.25+row*0.49,z+0.44),Vector3(0.9,0.45,0.14),"stone" if (row+col)%4 else "stone_dark")
			for row in range(8): box(Vector3(side*2.95,0.26+row*0.48,z+0.6),Vector3(0.5,0.44,0.5),"stone")
			for step in range(3): box(Vector3(side*(2.6-step*0.3),3.6+step*0.26,z+0.55),Vector3(0.6,0.26,0.5),"stone")
			for col in range(6): box(Vector3(side*(3.6+col),4.8+(col%3)*0.14,z),Vector3(0.92,0.4+(col%3)*0.28,1),"stone")
			for leaf in range(18): box(Vector3(side*(8.8-sin(leaf*0.7)*0.35),0.4+leaf*0.23,z+0.59),Vector3(0.45,0.3,0.2),"pine" if leaf%2 else "pine_light")
	for side in [-1,1]:
		for z in [20, -4, -18]:
			world._lantern(ORIGIN+Vector3(side*5,0,z),false)
			box(Vector3(side*8,0.5,z),Vector3(2.4,0.2,0.8),"wood")
			for leg in [-0.85,0.85]: box(Vector3(side*8+leg,0.2,z),Vector3(0.22,0.5,0.65),"timber")
		for i in range(65):
			var x: float=side*(12+(i%8)*2.8)
			var z: float=-79+(i*17%115)
			if z>-3 and z<34 and abs(x)<23: continue
			for leaf in range(3): box(Vector3(x+(leaf-1)*0.22,Ground.height_at(x,z)+0.15+leaf*0.1,z),Vector3(0.25,0.4,0.6),"pine_light")
	box(Vector3(0,2.5,-72),Vector3(21,5,0.8),"stone_dark",true)
	box(Vector3(0,5.2,-59),Vector3(21,0.4,26),"stone_dark",true)
	for z in [-34,-51,-65]:
		for x in [-6,6]: world._lantern(ORIGIN+Vector3(x,0,z),false)
	apprentice=Visual.new(); apprentice.position=ORIGIN+NODES.apprentice; apprentice.rotation.y=PI; add_child(apprentice)
	var apprentice_model:=State.new()
	for slot in ["head","chest","hands","legs","feet"]: apprentice_model.equip(apprentice_model.add_item("cloth_"+slot),slot)
	apprentice_model.unequip("main_hand"); apprentice_model.unequip("off_hand"); apprentice.build(apprentice_model)
	apprentice_label=Label3D.new(); apprentice_label.text="Iven · apprentice"; apprentice_label.position.y=2.5; apprentice_label.billboard=BaseMaterial3D.BILLBOARD_ENABLED; apprentice_label.font_size=22; apprentice_label.pixel_size=.003; apprentice.add_child(apprentice_label)
	for id: String in NODES:
		var p: Vector3=ORIGIN+NODES[id]
		if id!="apprentice": _sign(p+Vector3.UP*2,NAMES[id])
		if id in ["lantern","briar"]:
			var npc:=Visual.new(); npc.position=p; npc.rotation.y=PI; add_child(npc)
			var model:=State.new()
			for slot in ["head","chest","hands","legs","feet"]: model.equip(model.add_item(("cloth" if id=="lantern" else "leather")+"_"+slot),slot)
			npc.build(model)
		elif id not in ["return","apprentice"]:
			box(NODES[id]+Vector3.UP*0.5,Vector3(1.4,1,0.9),"wood" if id.begins_with("cache") else "stone_dark")
			box(NODES[id]+Vector3.UP*1.05,Vector3(1.5,0.12,1),"gold" if id=="atlas" else "iron")
	for side in [-1,1]: box(NODES.trial+Vector3(side*1.2,1.7,0),Vector3(.3,3.4,.4),"stone")
	box(NODES.trial+Vector3(0,3.4,0),Vector3(2.7,.3,.4),"gold")
	relic=b.piece(self,"window",ORIGIN+NODES.atlas+Vector3.UP*1.35,Vector3(0.55,0.12,0.8))
	CampDetail.new().build(self)
	world.block_count+=b.finish(world)
	_sign(TRAIL+Vector3.UP*2,"Western trail · Pinehall")
	for i in range(4):
		var enemy:=Enemy.new(); enemy.adventure=self; enemy.progress=state.archive
		enemy.enemy_id="archive_"+str(i); enemy.role="boss" if i==3 else "mage" if i==1 else "guard"
		enemy.title="The Bound Archivist" if i==3 else "Inkbound Sentinel"
		enemy.position=ORIGIN+Vector3(-3 if i%2==0 else 3,0.15,-34-i*8)
		enemy.health_override=220 if i==3 else 70
		add_child(enemy); enemies.append(enemy)
func _sign(p: Vector3,label: String) -> void:
	var sign:=Label3D.new(); sign.position=p; sign.text=label; sign.font_size=22; sign.pixel_size=0.003
	sign.billboard=BaseMaterial3D.BILLBOARD_ENABLED; sign.visibility_range_begin=4.5; sign.visibility_range_end=20; add_child(sign)
func _ui() -> void:
	var layer:=CanvasLayer.new(); layer.layer=7; add_child(layer)
	preview_label=Label.new(); preview_label.position=Vector2(32,76); preview_label.text="PINEHALL PREVIEW · progress is not saved"; layer.add_child(preview_label)
	dialog=ColorRect.new(); dialog.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); dialog.color=Color("102019"); layer.add_child(dialog)
	var center:=CenterContainer.new(); center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); dialog.add_child(center)
	var col:=VBoxContainer.new(); col.custom_minimum_size.x=700; col.add_theme_constant_override("separation",18); center.add_child(col)
	title=Label.new(); title.add_theme_font_size_override("font_size",26); col.add_child(title)
	description=Label.new(); description.custom_minimum_size=Vector2(700,250); description.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART; description.add_theme_font_size_override("font_size",19); col.add_child(description)
	options=VBoxContainer.new(); col.add_child(options)
	var close:=Button.new(); close.text="Return [ Esc ]"; close.custom_minimum_size.y=42; close.pressed.connect(func(): close_dialog(); world.player.set_paused(false)); col.add_child(close)
	dialog.hide()
func _button(label: String,id: String) -> void:
	var button:=Button.new(); button.text=label; button.custom_minimum_size.y=44; button.pressed.connect(func(): act(id)); options.add_child(button)
func _refresh() -> void:
	apprentice.position=interaction_position("apprentice")
	apprentice_label.text=interaction_name("apprentice")
	relic.visible=not state.archive.atlas
func enter() -> bool:
	if world.player.paused or "stonewake" not in state.story_completed: return false
	if is_instance_valid(world.seal) and world.seal.inside: world.seal.leave()
	if is_instance_valid(world.winter) and world.winter.inside: world.winter.leave()
	if is_instance_valid(world.threshold) and world.threshold.inside: world.threshold.leave()
	if is_instance_valid(world.convergence) and world.convergence.inside: world.convergence.leave()
	if is_instance_valid(world.choir) and world.choir.inside: world.choir.leave()
	if is_instance_valid(world.roots) and world.roots.inside: world.roots.leave()
	if is_instance_valid(world.lens) and world.lens.inside: world.lens.leave()
	if is_instance_valid(world.shore) and world.shore.inside: world.shore.leave()
	if world.mountain.inside: world.mountain.leave()
	if world.realms.inside: world.realms.leave()
	if world.adventure.inside: world.adventure.leave()
	inside=true; world.player.position=ORIGIN+Vector3(0,0.2,32); world.player.velocity=Vector3.ZERO; world.player.rotation=Vector3.ZERO
	for child in world.get_children():
		if child is WorldEnvironment:
			environment_backup=child.environment
			var env: Environment=environment_backup.duplicate(true)
			preload("res://scripts/regional_sky.gd").apply(env,"archive_chapter")
			child.environment=env

	world.hud.world_map.selected_quest="archive"; world.hud.world_map.set_view(true)
	world.hud.announce("Pinehall","An old atlas. Two claims upon it. Hear Mereth and Aelin before entering the ruined archive.")
	return true
func leave() -> void:
	if not inside: return
	for child in world.get_children():
		if child is WorldEnvironment and environment_backup!=null: child.environment=environment_backup

	inside=false; world.adventure.clear_projectiles(); world.player.position=TRAIL+Vector3(0,0.2,2.5); world.player.velocity=Vector3.ZERO
	for enemy in enemies:
		if not enemy.dead: enemy.position=enemy.home; enemy.health=enemy.maximum_health; enemy.velocity=Vector3.ZERO; enemy._update_label()
func interaction_name(id: String) -> String:
	return "Iven · returned apprentice" if id=="apprentice" and state.archive.get("apprentice_stage",0)>=3 else NAMES[id]

func interaction_position(id: String) -> Vector3:
	return ORIGIN+Vector3(4,0,24) if id=="apprentice" and state.archive.get("apprentice_stage",0)>=3 else ORIGIN+NODES[id]

func nearest() -> Dictionary:
	if not inside:
		if world.player.position.distance_to(TRAIL)<2.5: return {"kind":"archive","id":"trail","text":"[ E ] Travel to Pinehall"}
		return {}
	for id: String in NODES:
		if world.player.position.distance_to(interaction_position(id))<2.3: return {"kind":"archive","id":id,"text":"[ E ] "+interaction_name(id)}
	for enemy in enemies:
		if enemy.dead and enemy.enemy_id not in state.archive.looted and world.player.position.distance_to(enemy.position)<2.5: return {"kind":"archive","id":enemy.enemy_id,"text":"[ E ] Recover archive relics"}
	return {}
func station_nearby() -> String:
	for id in ["forge","enchant"]:
		if inside and world.player.position.distance_to(interaction_position(id))<2.3: return id
	return ""
func interact(id: String) -> void:
	if world.player.paused or nearest().get("id","")!=id: return
	if id=="trail":
		if not enter(): world.hud.announce("The old forest road", "Complete Stonewake before investigating Pinehall.")
	elif id=="return": leave()
	elif id in ["forge","enchant"]: world.hud.workshop.open(id)
	elif id.begins_with("archive_"): loot(id)
	else: open_dialog(id)
func open_dialog(id: String) -> void:
	subject=id; world.player.dialog_open=true; world.player.set_paused(true); dialog.show()
	for child in options.get_children(): options.remove_child(child); child.queue_free()
	title.text=interaction_name(id).to_upper()
	var p: Dictionary=state.archive
	if id in ["apprentice_notice","apprentice"]:
		apprentice_dialog(id); return
	if p.get("names_choice","")!="" and (id=="lantern" or (p.get("price_started",false) and id in ["briar","trial"])):
		price_dialog(id); return
	if id in ["lantern","briar"]:
		description.text="MERETH · VEILED LANTERN\n\nThe atlas contains routes to places our world is not ready to reach. We would preserve it under controlled study. Knowledge can heal, but it can also open doors we cannot close. Our last safety manual is still screaming. We keep it in Fiction." if id=="lantern" else "AELIN · BRIAR COVEN\n\nThe atlas was grown into these roots before any order claimed it. We would return its teachings to the communities that keep the forest alive. Secrecy can protect knowledge—and keep its benefits from those who need it. Mereth charges late fees. We plant you. Different approaches to returning things."
		if p.get("names_accepted",false): description.text=description.text.replace(" Our last safety manual is still screaming. We keep it in Fiction.","")
		if not p.accepted: _button("Investigate the ruined archive", "accept")
		if id not in p.heard: _button("Hear this faction's claim", "hear")
		if p.recipient!="": description.text+="\n\n"+("You entrusted the atlas to us. Your relic pattern is learned." if p.recipient==id else "You entrusted it to our rival. We disagree, but the forest road stays open.")
		elif p.atlas and p.heard.size()==2:
			description.text+="\n\nChoose one recipient. The Lantern grants the chain-lightning staff and pattern; the Coven grants healing armor and its pattern. The unchosen pattern is not awarded. This is not a faction membership oath."
			_button("Entrust to Lantern · staff + pattern" if id=="lantern" else "Entrust to Coven · healing armor + pattern","entrust")
		else: description.text+="\n\n"+objective()
		if id=="lantern" and p.recipient!="":
			match p.get("lantern_trial",""):
				"": _button("The Uncatalogued Door · undertake the Lantern trial","trial_accept")
				"accepted": description.text+="\n\nTrial: revisit the archivist's testimony. Read what both factions contributed before opening the sealed door in the second chamber."
				"testimony": description.text+="\n\nTrial: open the Uncatalogued Door in the second archive chamber."
				"fragment":
					description.text+="\n\nYou recovered the unedited testimony. Take the Lantern oath to preserve evidence before judging it. Your atlas custody choice remains honored. Reward: 100 gold, a Fine Witness Pendant and its forge pattern."
					_button("Join the Veiled Lantern · become a Witness","trial_join")
				"member":
					description.text+="\n\nVeiled Lantern rank: "+("Recordkeeper" if p.get("names_choice","")!="" else "Witness")
					if p.get("names_choice","")!="": description.text+="\n\n"+("The missing names are public. Families can reclaim their history; the witnesses are now identifiable." if p.names_choice=="public" else "The complete testimony is preserved under seal. Witnesses remain protected; families still lack public answers.")
					elif not p.get("names_accepted",false):
						description.text+="\n\nNames Beneath the Water: recover three erased records from Mirewatch. Follow the main expedition to reach the marsh and stabilize its beacon before collecting the northern testimony."
						_button("Accept Names Beneath the Water","names_accept")
					else:
						description.text+="\n\nRecords recovered: %d / 3. Choose how to preserve the testimony once all three are here. Either resolution grants Recordkeeper rank, 140 gold and one Superior ring with its forge pattern." % p.get("names_records",[]).size()
						if p.get("names_records",[]).size()==3:
							_button("Publish the names · Memorial Ring · +3 Presence / +2 Endurance","names_resolve:public")
							_button("Preserve under seal · Sealed Memory Ring · +3 Intellect / +2 Willpower","names_resolve:sealed")
	elif id=="trial":
		description.text="An unlabelled bronze door surrounds a sealed record drawer. Its inscription asks: What must survive when rival accounts conflict?"
		if p.get("lantern_trial","") in ["", "accepted"]: description.text+="\n\nMereth requires you to study the archivist’s testimony before attempting the trial."
		elif p.lantern_trial=="testimony":
			_button("Only the victorious faction's account","trial_answer:victor")
			_button("The complete testimony, including disagreement","trial_answer:witness")
			_button("Nothing; destroy both accounts","trial_answer:erase")
		else: description.text+="\n\nThe record drawer is open. Bring its testimony to Mereth."
	elif id=="notes":
		description.text="THE ARCHIVIST'S LAST ENTRY\n\nThe Lantern warned us about unstable routes. The Coven kept our wards alive when the council forgot us. Neither speaks the whole truth. I bound myself to the atlas to keep it from raiders; now the ink will not let me go.\n\nRelease the Bound Archivist. Then choose a custodian with open eyes."
		if p.get("lantern_trial","")=="accepted": _button("Study both accounts for the Lantern trial","trial_study")
		if p.get("apprentice_stage",0)==1:
			description.text+="\n\nIven's fresh marginal notes describe using living resin to mend frost-damaged skin. A sketch marks a safe alcove in the rear archive."
			_button("Follow Iven's research trail","apprentice_trace")
	elif id=="atlas":
		description.text="The atlas sketches a wreck on an unknown shore and an observatory that watches the sky beneath the sand. These are the next leads in the watchstone network."
		if not p.accepted: description.text+="\nAsk either representative about the expedition first."
		elif "archive_3" not in p.defeated: description.text+="\nThe Bound Archivist still guards it."
		elif not p.atlas: _button("Recover the atlas · protected quest evidence","atlas")
		else: description.text+="\nAlready recovered. Hear both claims and choose its custodian."
	else:
		description.text="Rare memory fragments and living resin rest among the sealed records. Use them in the relic patterns learned from this expedition."
		if id not in p.caches: _button("Collect rare components","cache")
		else: description.text+="\nAlready collected."
func act(id: String) -> bool:
	if not dialog.visible or not inside or world.player.position.distance_to(interaction_position(subject))>=2.3: return false
	var p: Dictionary=state.archive
	var success:=false
	if id=="apprentice_accept" and subject=="apprentice_notice" and p.get("apprentice_stage",0)==0: p.apprentice_stage=1; success=true
	elif id=="apprentice_trace" and subject=="notes" and p.get("apprentice_stage",0)==1: p.apprentice_stage=2; success=true
	elif id=="apprentice_rescue" and subject=="apprentice" and p.get("apprentice_stage",0)==2 and "archive_2" in p.defeated: p.apprentice_stage=3; success=true
	elif id in ["apprentice_return","apprentice_protect"] and subject=="apprentice" and p.get("apprentice_stage",0)==3 and p.get("apprentice_choice","")=="":
		p.apprentice_choice="return" if id=="apprentice_return" else "protect"
		var formula: String="insight" if p.apprentice_choice=="return" else "vigor"
		var uid: String=state.add_item("crystal_staff" if p.apprentice_choice=="return" else "cloth_chest",2,formula)
		state.inventory[uid].favorite=true; state.inventory[uid].custom_name="Iven's Field Rod" if p.apprentice_choice=="return" else "Iven's Field Robe"
		if formula not in state.formulas: state.formulas.append(formula)
		state.gold+=100; success=true; world.audio.sfx("quest")
	elif id=="accept" and subject in ["lantern","briar"] and not p.accepted: p.accepted=true; success=true
	elif id=="hear" and subject in ["lantern","briar"] and subject not in p.heard: p.heard.append(subject); success=true
	elif id=="atlas" and subject=="atlas" and p.accepted and "archive_3" in p.defeated and not p.atlas: p.atlas=true; success=true
	elif id=="cache" and subject in ["cache_west","cache_east"] and subject not in p.caches:
		p.caches.append(subject); world.adventure.grant_materials({"memory_shard":3,"living_resin":3}); success=true
	elif id=="entrust" and subject in ["lantern","briar"] and p.atlas and p.heard.size()==2 and p.recipient=="":
		p.recipient=subject
		p.reputation[subject]+=25; p.reputation["briar" if subject=="lantern" else "lantern"]-=10
		if "archive" not in state.story_completed: state.story_completed.append("archive")
		state.blueprints.append("lantern_relic" if subject=="lantern" else "briar_relic")
		var uid: String=state.add_item("lantern_conductor" if subject=="lantern" else "briar_vestment",2,"insight" if subject=="lantern" else "vigor")
		state.inventory[uid].favorite=true; state.gold+=100; world.adventure.grant_materials({"memory_shard":3,"living_resin":3}); success=true
	elif id=="trial_accept" and subject=="lantern" and p.recipient!="" and p.get("lantern_trial","")=="": p.lantern_trial="accepted"; success=true
	elif id=="trial_study" and subject=="notes" and p.get("lantern_trial","")=="accepted": p.lantern_trial="testimony"; success=true
	elif id.begins_with("trial_answer:") and subject=="trial" and p.get("lantern_trial","")=="testimony":
		if id!="trial_answer:witness": description.text+="\n\nThe seal holds. Revisit the testimony: both factions helped, and neither held the entire truth."; return false
		p.lantern_trial="fragment"; success=true
	elif id=="trial_join" and subject=="lantern" and p.get("lantern_trial","")=="fragment":
		p.lantern_trial="member"; state.gold+=100
		var uid: String=state.add_item("witness_pendant",1); state.inventory[uid].favorite=true
		if "lantern_witness" not in state.blueprints: state.blueprints.append("lantern_witness")
		success=true
	elif id=="names_accept" and subject=="lantern" and p.get("lantern_trial","")=="member" and not p.get("names_accepted",false): p.names_accepted=true; success=true
	elif id.begins_with("names_resolve:") and subject=="lantern" and p.get("names_accepted",false) and p.get("names_records",[]).size()==3 and p.get("names_choice","")=="":
		var choice:=id.get_slice(":",1)
		if choice not in ["public","sealed"]: return false
		p.names_choice=choice; state.gold+=140
		var item: String="memorial_ring" if choice=="public" else "sealed_memory_ring"
		var uid: String=state.add_item(item,2); state.inventory[uid].favorite=true
		if "names_"+choice not in state.blueprints: state.blueprints.append("names_"+choice)
		success=true
	elif id=="price_start" and subject=="lantern" and p.get("names_choice","")!="" and not p.get("price_started",false): p.price_started=true; success=true
	elif id=="price_hear" and subject in ["lantern","briar"] and p.get("price_started",false) and p.get("price_choice","")=="":
		if subject in p.get("price_heard",[]): return false
		if not p.has("price_heard"): p.price_heard=[]
		p.price_heard.append(subject); success=true
	elif id.begins_with("price_resolve:") and subject=="trial" and p.get("price_started",false) and p.get("price_heard",[]).size()==2 and p.get("price_choice","")=="":
		var choice:=id.get_slice(":",1)
		if choice not in ["seal","share","oversight"]: return false
		p.price_choice=choice; state.gold+=200
		var uid: String=state.add_item("lantern_keystone",2); state.inventory[uid].favorite=true
		if "lantern_keeper" not in state.blueprints: state.blueprints.append("lantern_keeper")
		world.adventure.grant_materials({"memory_shard":6} if choice=="seal" else {"living_resin":6} if choice=="share" else {"memory_shard":3,"living_resin":3}); success=true
	if success:
		if id.begins_with("price_"): world.hud.world_map.selected_quest="lantern_3"
		if id.begins_with("names_"): world.hud.world_map.selected_quest="lantern_2"
		if id.begins_with("trial_"): world.hud.world_map.selected_quest="lantern_1"
		if id.begins_with("apprentice_"): world.hud.world_map.selected_quest="side_pinehall"
		state._commit()
		if id=="apprentice_rescue": close_dialog(); world.player.set_paused(false); world.hud.announce("Iven is safe","Meet him beside the college notice in Pinehall to decide the research’s future.")
		else: open_dialog(subject)
	return success
func mark_defeated(id: String) -> void:
	if id not in state.archive.defeated: state.archive.defeated.append(id); state._commit()
func loot(id: String) -> bool:
	if id not in state.archive.defeated or id in state.archive.looted: return false
	state.archive.looted.append(id); state.gold+=25
	world.adventure.grant_materials({"memory_shard":2,"living_resin":1})
	if id=="archive_3":
		var uid: String=state.add_item("echo_blade",2,"fleet"); state.inventory[uid].favorite=true
		if "archive_relic" not in state.blueprints: state.blueprints.append("archive_relic")
	state._commit()
	for enemy in enemies: enemy._update_label()
	world.hud.announce("Archive relic recovered","Echoharvest restores stamina on melee kills." if id=="archive_3" else "Rare components and gold added to your bag.")
	return true
func objective() -> String:
	var p: Dictionary=state.archive
	if p.recipient!="": return "Atlas entrusted to "+("the Lantern" if p.recipient=="lantern" else "the Coven")+" · Shore and observatory leads uncovered"
	if not p.accepted: return "Speak with Mereth or Aelin in Pinehall"
	if p.heard.size()<2: return "Hear both claims · %d / 2" % p.heard.size()
	if not p.atlas: return "Release the Bound Archivist, loot the guardian, and recover the atlas"
	return "Choose the atlas's custodian: Lantern staff or Coven healing armor"
func close_dialog() -> void:
	dialog.hide(); world.player.dialog_open=false
func check_fall() -> void:
	if world.player.position.y< -8 or absf(world.player.position.x-ORIGIN.x)>43 or world.player.position.z < -82 or world.player.position.z>46:
		world.player.position=ORIGIN+Vector3(0,0.2,32); world.player.velocity=Vector3.ZERO
func fire(origin: Vector3,direction: Vector3,damage: float,hostile: bool,source: CollisionObject3D,magic: bool) -> void:
	world.adventure.fire(origin,direction,damage,hostile,source,magic)
func line_clear(from: Vector3,to: Vector3,source: CollisionObject3D,target_body: CollisionObject3D=null) -> bool:
	return world.adventure.line_clear(from,to,source,target_body)
func _process(delta: float) -> void:
	preview_label.visible="--archive-preview" in OS.get_cmdline_user_args() and not world.player.paused
	if feedback_time>0: world.adventure.feedback=feedback; world.adventure.feedback_time=feedback_time; feedback_time=maxf(0,feedback_time-delta)

func lantern_objective() -> String:
	match state.archive.get("lantern_trial",""):
		"accepted": return "Study the archivist's testimony in Pinehall"
		"testimony": return "Solve the Uncatalogued Door in the second archive chamber"
		"fragment": return "Return the unedited testimony to Mereth for the Lantern oath"
		"member": return names_objective() if state.archive.get("names_accepted",false) else "Veiled Lantern Witness · pendant pattern learned"
	return "Complete The Missing Atlas, then ask Mereth about the Lantern trial"

func names_objective() -> String:
	var p: Dictionary=state.archive
	if p.get("price_started",false): return price_objective()
	if p.get("names_choice","")!="": return "Recordkeeper · "+("Names published" if p.names_choice=="public" else "Testimony preserved under seal")
	if not p.get("names_accepted",false): return "Become a Lantern Witness, then ask Mereth about Mirewatch's missing records"
	return "Mirewatch testimony · %d / 3 records · return to Mereth" % p.get("names_records",[]).size()

func price_dialog(id: String) -> void:
	var p: Dictionary=state.archive
	if p.get("price_choice","")!="":
		description.text="LANTERN RANK · KEEPER\n\n"+{"seal":"The archive is sealed for controlled study. Mereth accepts responsibility for access; Aelin warns that knowledge withheld can become power hoarded.","share":"The archive is opened for public copying. Aelin welcomes the decision; Mereth prepares warnings for readers who may follow dangerous routes.","oversight":"The Lantern and Coven will jointly review access. Neither faction can open a dangerous record alone. Both accept the work, and distrust each other just enough to keep records."}[p.price_choice]
		description.text+="\n\nYour Mirewatch decision remains: "+("names published." if p.names_choice=="public" else "testimony preserved under seal.")+" Your Lantern Keystone pattern is learned."
		return
	if id=="lantern":
		description.text="THE PRICE OF KNOWING\n\nMereth: You have preserved testimony. Now decide who may use the routes it reveals. Sealing them protects people from dangerous crossings, but gives us control over who learns. Hear Aelin before you choose.\n\nYour earlier Mirewatch decision remains in force."
		if not p.get("price_started",false): _button("Accept the archive's final review","price_start")
		elif "lantern" not in p.get("price_heard",[]): _button("Record Mereth's case for controlled study","price_hear")
		else: description.text+="\n\nMereth's case recorded. Hear Aelin, then decide at the Uncatalogued Door."
	elif id=="briar":
		description.text="Aelin: These routes belong to the people who kept them alive. Open copying gives them that inheritance—and the danger that comes with it. If you cannot trust either of us alone, make us answer to each other."
		if "briar" not in p.get("price_heard",[]): _button("Record Aelin's case for access and oversight","price_hear")
		else: description.text+="\n\nAelin's case recorded. Return to the Uncatalogued Door."
	else:
		description.text="THE ARCHIVE'S FUTURE\n\nThe seal waits for your mandate. All choices grant Keeper rank, 200 gold, a Superior Lantern Keystone and its forge pattern. The decision changes the archive's recorded policy and faction responses; your prior testimony choice stands."
		if p.get("price_heard",[]).size()!=2: description.text+="\n\nHear both Mereth and Aelin before making this decision."
		else:
			_button("Seal for controlled study · 6 Memory Shards","price_resolve:seal")
			_button("Open for public copying · 6 Living Resin","price_resolve:share")
			_button("Require shared oversight · 3 of each material","price_resolve:oversight")
func price_objective() -> String:
	var p: Dictionary=state.archive
	if p.get("price_choice","")!="": return "Lantern Keeper · "+{"seal":"Archive sealed","share":"Public copying","oversight":"Shared oversight"}[p.price_choice]
	if not p.get("price_started",false): return "Resolve Names Beneath the Water, then ask Mereth about the archive's future"
	return "Final review · %d / 2 perspectives · decide at the Uncatalogued Door" % p.get("price_heard",[]).size()

func apprentice_objective() -> String:
	var p: Dictionary=state.archive
	if p.get("apprentice_choice","")=="return": return "The Apprentice Who Vanished complete · Iven returned his research to supervised college study, with his authorship recorded."
	if p.get("apprentice_choice","")=="protect": return "The Apprentice Who Vanished complete · Iven kept his original research for independent healing work."
	return ["The Apprentice Who Vanished · Read the college notice near Pinehall's entrance.","Follow Iven's marginal notes at the archivist's testimony in the first archive chamber.","Find Iven in the rear archive alcove; defeat the nearby sentinel before helping him out. Earlier defeats count.","Iven is safely beside the college notice · speak with him about the research."][int(p.get("apprentice_stage",0))]

func apprentice_dialog(id: String) -> void:
	var p: Dictionary=state.archive
	description.text=apprentice_objective()+"\n\n"
	if id=="apprentice_notice":
		description.text+="MERETH'S NOTICE\nApprentice Iven entered the sealed archive with borrowed healing notes and has not returned. Recover the apprentice before the paperwork. We have spare paperwork."
		if p.get("apprentice_stage",0)==0: _button("Follow the missing apprentice's trail","apprentice_accept")
	elif p.get("apprentice_stage",0)<3:
		description.text+="IVEN\nThe college forbade field trials, so I came to check the original resin formulas. Then the sentinel woke up. I have discovered a remarkable treatment for arrogance: wait here without lunch."
		if p.get("apprentice_stage",0)<2: description.text+="\nCheck my marginal notes before handling this research."
		elif "archive_2" not in p.defeated: description.text+="\nThe sentinel near this alcove still blocks a safe departure."
		else: _button("Help Iven leave the archive for camp","apprentice_rescue")
	elif p.get("apprentice_choice","")=="":
		description.text+="IVEN\nMereth will let me continue under supervision if the research returns with my name on it. Or I can keep the original and work independently, testing carefully before treating anyone. I will accept your advice.\n\nEither choice gives 100 gold and one Superior, favorited piece of field equipment, plus its enchantment formula."
		_button("Return research · Iven's Field Rod + Insight formula","apprentice_return")
		_button("Protect authorship · Iven's Field Robe + Vigor formula","apprentice_protect")
	else: description.text+="IVEN\nNext expedition, I am packing a colleague. And two lunches."
