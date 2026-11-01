extends Node3D
const Blocks = preload("res://scripts/blocks.gd")
const State = preload("res://scripts/character_state.gd")
const Visual = preload("res://scripts/character_visual.gd")
const Enemy = preload("res://scripts/enemy.gd")
const TownDetail = preload("res://scripts/wyrmkeep_detail.gd")
const ORIGIN := Vector3(800, 0, 0)
const PASS := Vector3(-1, 0, -61)
var shelter_people: Node3D
var shelter_flame: MeshInstance3D
var shelter_label: Label3D
const NODES := {"shelter_notice":Vector3(8,0,30),"travelers":Vector3(30,0,-43),"hearth":Vector3(30,0,-57),"memorial": Vector3(-6,0,-7),"return": Vector3(0, 0, 35), "council": Vector3(0, 0.25, -26), "stoneguard": Vector3(-22, 0.25, -10), "stormweaver": Vector3(22, 0.25, -10), "ledger": Vector3(0, 0, -63), "west": Vector3(-32, 0, 17), "south": Vector3(0, 0, 25), "east": Vector3(32, 0, 17), "supply_west": Vector3(-11, 0, 16), "supply_east": Vector3(11, 0, 16), "forge": Vector3(-11, 0, 9), "enchant": Vector3(11, 0, 9)}
const NAMES := {"shelter_notice":"Rimegate travelers · overdue notice","travelers":"Marae · stranded travelers","hearth":"Abandoned watch hut hearth","memorial": "Passkeepers’ memorial record","return": "Return to Frostmere", "council": "Speaker Runa", "stoneguard": "Hadrik · Stoneguard", "stormweaver": "Sera · Stormweaver", "ledger": "Lost road ledger", "west": "West road ward", "south": "South road ward", "east": "East road ward", "supply_west": "Smithy supply post", "supply_east": "Market supply post", "forge": "Summit forge", "enchant": "Runewright altar"}
const CLANS := {"stoneguard": {"name": "Stoneguard", "value": "Protect the holds through reliable roads, shared stores and shieldwork.", "formula": "stoneguard_oath", "weapon": "stoneguard_main_hand"}, "stormweaver": {"name": "Stormweaver", "value": "Restore the old rune network through study, exploration and careful magic.", "formula": "stormweaver_sight", "weapon": "stormweaver_main_hand"}}
var memorial_caption: Label3D
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
var ward_glows: Dictionary = {}

func _ready() -> void:
	state = world.player.character
	_build()
	_ui()
	state.changed.connect(_refresh)
	_refresh()
func _build() -> void:
	var b: RefCounted = world.blocks
	world._solid(ORIGIN + Vector3(0, -0.6, -13), Vector3(110, 1, 150), "wyrmkeep_ground")
	for x in range(-53, 54):
		for z in range(-86, 60):
			var path: bool = TownDetail.path_at(x,z)
			b.add("path" if path else "snow", ORIGIN + Vector3(x, -0.12, z), Vector3(1.01, 0.15, 1.01))
	for house in [[-22,-14,12,12,4.5,"stoneguard"],[22,-14,12,12,4.5,"stormweaver"],[0,-33,16,16,5.5,"council"],[-18,14,9,10,3.8,"summit_smith"],[18,14,9,10,3.8,"high_road"]]:
		world._house(ORIGIN + Vector3(house[0], 0, house[1]), house[2], house[3], house[4], true, house[5])
	world._house(ORIGIN+Vector3(30,0,-58),9,10,3.8,true,"watch_hut")
	shelter_flame=b.piece(self,"window",ORIGIN+NODES.hearth+Vector3.UP*.6,Vector3(.6,.9,.6))
	b.add("stone_dark",ORIGIN+NODES.hearth+Vector3(0,.15,0),Vector3(1.3,.3,1.3))
	shelter_people=Node3D.new(); add_child(shelter_people)
	for i in range(3):
		var npc:=Visual.new(); npc.position=Vector3((i-1)*1.8,0,0); npc.rotation.y=PI; shelter_people.add_child(npc)
		var model:=State.new()
		for slot in ["head","chest","hands","legs","feet"]: model.equip(model.add_item("fur_"+slot),slot)
		model.equipment.main_hand=""; model.equipment.off_hand=""; npc.build(model)
	shelter_label=Label3D.new(); shelter_label.position=Vector3(0,2.6,0); shelter_label.font_size=22; shelter_label.pixel_size=.003; shelter_label.billboard=BaseMaterial3D.BILLBOARD_ENABLED; shelter_people.add_child(shelter_label)
	# Snow-capped ridges enclose the settlement and a guarded northern outpost.
	for i in range(18):
		var side := -1 if i % 2 else 1
		var x := side * (60 + (i % 4) * 5)
		var z := -80 + i * 8
		preload("res://scripts/refined_ridges.gd").build(b,ORIGIN+Vector3(x,0,z),38,33,31+(i%4)*3)
	for peak in [Vector3(-28,47,-106),Vector3(0,59,-113),Vector3(28,43,-106)]:
		preload("res://scripts/refined_ridges.gd").build(b,ORIGIN+Vector3(peak.x,0,peak.z),48,37,peak.y)
	for side in [-1,1]:
		var x: float = side*11
		for tier in range(9): b.add("wood",ORIGIN+Vector3(x,0.2+tier*0.27,-62),Vector3(3-tier*0.24,0.28,4.5))
		for row in range(4):
			for col in range(12): b.add("stone",ORIGIN+Vector3(side*7.45,0.24+row*0.48,-54-col),Vector3(0.13,0.44,0.92))
	for x in [-4,4]:
		b.add("wood",ORIGIN+Vector3(x,0.45,-66),Vector3(1.3,0.9,1.2))
		b.add("iron",ORIGIN+Vector3(x,0.6,-66),Vector3(1.35,0.12,1.25))
	for z in [-58, -66]:
		for x in [-8, 8]:
			world._solid(ORIGIN + Vector3(x, 1, z), Vector3(1, 2, 7))
			b.add("stone_dark", ORIGIN + Vector3(x, 1, z), Vector3(1, 2, 7))
	for id: String in NODES:
		var p: Vector3 = ORIGIN + NODES[id]
		if id!="travelers": _sign(p + Vector3.UP * 1.9, NAMES[id])
		if id in ["west", "south", "east"]:
			for tier in range(8): b.add("stone", p + Vector3(0, 0.15+tier*0.2, 0), Vector3(0.9-tier*0.055, 0.19, 0.65))
			world._solid(p + Vector3.UP * 0.8, Vector3(0.7, 1.6, 0.7))
			var glow: MeshInstance3D = b.piece(self, "window", p + Vector3.UP * 1.9, Vector3(0.25,0.25,0.25))
			ward_glows[id] = glow
		elif id=="memorial":
			b.add("stone",p+Vector3.UP*.2,Vector3(2,.4,1.3))
			b.add("stone_dark",p+Vector3.UP*.95,Vector3(1.6,1.2,.5))
			b.add("gold",p+Vector3(0,1,.28),Vector3(1.3,.8,.06))
			world._solid(p+Vector3.UP*.75,Vector3(1.6,1.5,.5))
			memorial_caption=Label3D.new(); memorial_caption.position=p+Vector3(0,1,.33); memorial_caption.font_size=22; memorial_caption.pixel_size=.0025; add_child(memorial_caption)
		elif id in ["supply_west", "supply_east", "ledger"]:
			b.add("wood", p + Vector3.UP * 0.45, Vector3(1.2,0.9,0.8))
			b.add("gold", p + Vector3.UP * 0.5, Vector3(0.12,1,0.85))
		elif id in ["forge", "enchant"]:
			b.add("stone_dark", p + Vector3.UP * 0.6, Vector3(1.6,1.2,1))
			b.add("iron" if id == "forge" else "window", p + Vector3.UP * 1.3, Vector3(1.8,0.25,0.7))
	for id: String in ["stoneguard", "stormweaver", "council"]:
		var npc := Visual.new()
		npc.position = ORIGIN + NODES[id]; npc.rotation.y = PI
		add_child(npc)
		var model := State.new()
		for slot in ["head","chest","hands","legs","feet"]: model.equip(model.add_item(("steel" if id == "stoneguard" else "cloth")+"_"+slot),slot)
		npc.build(model)
	# Clan banners distinguish the halls from the central council house.
	for x in [-22,22]:
		b.add("cloth", ORIGIN + Vector3(x,3,-7.7), Vector3(1,2,0.12))
		b.add("iron" if x<0 else "window", ORIGIN + Vector3(x,3,-7.6), Vector3(0.24,1.2,0.1))
	for z in [24, 2, -18]:
		for x in [-6, 6]: world._lantern(ORIGIN + Vector3(x, 0, z), false)
	for x in [-8, 8]:
		for z in [-4, 21]:
			b.add("wood",ORIGIN+Vector3(x,0.55,z),Vector3(2.4,0.18,0.65))
			for dx in [-0.8,0.8]: b.add("timber",ORIGIN+Vector3(x+dx,0.25,z),Vector3(0.2,0.5,0.5))
	# Stocked market stalls frame the square, leaving every doorway clear.
	for side in [-1,1]:
		var x: float = side * 26
		b.add("wood",ORIGIN+Vector3(x,0.8,7),Vector3(3,0.2,1.2))
		for dx in [-1.5,1.5]: b.add("timber",ORIGIN+Vector3(x+dx,1.3,7),Vector3(0.18,2.6,0.18))
		b.add("cloth",ORIGIN+Vector3(x,2.6,7),Vector3(3.5,0.15,2))
		for i in range(6): b.add("iron" if side<0 else "window",ORIGIN+Vector3(x-1+i*0.4,1.05,7),Vector3(0.25,0.3,0.5))
	TownDetail.new().build(world,ORIGIN)
	preload("res://scripts/winter_pines.gd").build(world,ORIGIN)
	preload("res://scripts/winter_ground_detail.gd").build(world,ORIGIN)
	world.block_count += b.finish(world)
	_sign(PASS + Vector3.UP * 2, "North pass · Wyrmkeep")
	for i in range(3):
		var enemy := Enemy.new(); enemy.adventure = self; enemy.progress = state.mountain
		enemy.enemy_id = "pass_" + str(i); enemy.role = "archer" if i == 1 else "guard"
		enemy.title = "Road Reaver" if i < 2 else "Reaver Captain"
		enemy.health_override = 75 if i < 2 else 110
		enemy.position = ORIGIN + Vector3((i-1)*4,0.1,-55-i*3)
		add_child(enemy); enemies.append(enemy)
func _ui() -> void:
	var layer := CanvasLayer.new(); layer.layer = 6; add_child(layer)
	preview_label = Label.new(); preview_label.position = Vector2(32,76)
	preview_label.text = "WYRMKEEP PREVIEW · after Stonewake · progress is not saved"
	preview_label.add_theme_color_override("font_color",Color("e8ba7b")); layer.add_child(preview_label)
	dialog = ColorRect.new(); dialog.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); dialog.color = Color("101923"); layer.add_child(dialog)
	var center := CenterContainer.new(); center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); dialog.add_child(center)
	var column := VBoxContainer.new(); column.custom_minimum_size.x = 700; column.add_theme_constant_override("separation",14); center.add_child(column)
	title = Label.new(); title.add_theme_font_size_override("font_size",26); column.add_child(title)
	description = Label.new(); description.custom_minimum_size = Vector2(700,220); description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; description.add_theme_font_size_override("font_size",18); column.add_child(description)
	options = VBoxContainer.new(); column.add_child(options)
	var close := Button.new(); close.text = "Return [ Esc ]"; close.custom_minimum_size.y = 40; close.pressed.connect(func(): close_dialog(); world.player.set_paused(false)); column.add_child(close)
	dialog.hide()
func _button(label: String, id: String) -> void:
	var button := Button.new(); button.text = label; button.custom_minimum_size.y = 40
	button.pressed.connect(func(): act(id)); options.add_child(button)
func _refresh() -> void:
	shelter_people.position=interaction_position("travelers")
	shelter_flame.visible=int(state.mountain.get("shelter_stage",0))==3
	shelter_label.text="Marae · travelers sheltered" if shelter_flame.visible else "Marae · stranded travelers"
	memorial_caption.text="MARA & OREN\nOne final watch" if state.mountain.get("letters_choice","")=="public" else "THE FINAL WATCH\nWe remember"
	for id: String in ward_glows: ward_glows[id].visible = id in state.mountain.wards
func enter() -> bool:
	if world.player.paused or "stonewake" not in state.story_completed: return false
	if world.realms.inside: world.realms.leave()
	if is_instance_valid(world.seal) and world.seal.inside: world.seal.leave()
	if is_instance_valid(world.winter) and world.winter.inside: world.winter.leave()
	if is_instance_valid(world.threshold) and world.threshold.inside: world.threshold.leave()
	if is_instance_valid(world.convergence) and world.convergence.inside: world.convergence.leave()
	if is_instance_valid(world.choir) and world.choir.inside: world.choir.leave()
	if is_instance_valid(world.roots) and world.roots.inside: world.roots.leave()
	if is_instance_valid(world.lens) and world.lens.inside: world.lens.leave()
	if is_instance_valid(world.shore) and world.shore.inside: world.shore.leave()
	if is_instance_valid(world.archive_chapter) and world.archive_chapter.inside: world.archive_chapter.leave()
	if world.adventure.inside: world.adventure.leave()
	inside = true; world.player.position = ORIGIN + Vector3(0,0.2,32); world.player.velocity = Vector3.ZERO; world.player.rotation = Vector3.ZERO
	for child in world.get_children():
		if child is WorldEnvironment:
			environment_backup=child.environment
			var env: Environment=environment_backup.duplicate(true)
			preload("res://scripts/regional_sky.gd").apply(env,"mountain")
			child.environment=env

	world.hud.world_map.selected_quest = "council"
	world.hud.world_map.selected_faction = "iron_pact"
	for i in range(world.atlas.data.factions.size()):
		if world.atlas.data.factions[i].id == "iron_pact": world.hud.world_map.faction_picker.select(i)
	world.hud.world_map.set_view(true)
	world.hud.announce("Wyrmkeep", "Two clans. One disputed road. Speak to Speaker Runa in the council hall.")
	return true
func leave() -> void:
	if not inside: return
	for child in world.get_children():
		if child is WorldEnvironment and environment_backup!=null: child.environment=environment_backup

	inside = false; world.adventure.clear_projectiles()
	world.player.position = PASS + Vector3(0,0.2,2.5); world.player.velocity = Vector3.ZERO
	for enemy in enemies:
		if not enemy.dead: enemy.position = enemy.home; enemy.health = enemy.maximum_health; enemy.velocity = Vector3.ZERO; enemy._update_label()
func nearest() -> Dictionary:
	if not inside:
		if world.player.position.distance_to(PASS) < 2.5: return {"kind":"mountain","id":"pass","text":"[ E ] Travel the north pass to Wyrmkeep"}
		return {}
	for id: String in NODES:
		if world.player.position.distance_to(interaction_position(id)) < 2.3: return {"kind":"mountain","id":id,"text":"[ E ] "+interaction_name(id)}
	for enemy in enemies:
		if enemy.dead and enemy.enemy_id not in state.mountain.looted and world.player.position.distance_to(enemy.position) < 2.5: return {"kind":"mountain","id":enemy.enemy_id,"text":"[ E ] Search road reaver"}
	return {}
func station_nearby() -> String:
	for id in ["forge","enchant"]:
		if inside and world.player.position.distance_to(ORIGIN+NODES[id])<2.3: return id
	return ""
func interact(id: String) -> void:
	if world.player.paused or nearest().get("id","") != id: return
	if id == "pass":
		if not enter(): world.hud.announce("The north pass is closed", "Complete Stonewake with Ilyra before seeking the mountain council.")
	elif id == "return": leave()
	elif id in ["forge","enchant"]: world.hud.workshop.open(id)
	elif id.begins_with("pass_"): loot(id)
	else: open_dialog(id)
func open_dialog(id: String) -> void:
	subject = id; world.player.dialog_open = true; world.player.set_paused(true); dialog.show()
	for child in options.get_children(): options.remove_child(child); child.queue_free()
	title.text = interaction_name(id).to_upper()
	var p: Dictionary = state.mountain
	if id in ["shelter_notice","travelers","hearth"]: shelter_dialog(); return
	if id == "council":
		description.text = "THE DIVIDED COUNCIL\n\nStoneguard blames old rune experiments for the lost road supplies. Stormweaver blames neglected patrols. Hear both sponsors, then recover the ledger from the reaver outpost north of town. Your findings can settle the dispute without taking a clan oath. We tried a committee. It formed two committees and lost another wagon."
		if not p.accepted: _button("Investigate the disputed road", "accept")
		elif p.settlement != "": description.text = "The council accepts the evidence: raiders exploited both neglected patrols and failing wards. The mountain testimony is yours; the Ashen Choir may know why the watchstones are waking.\n\nCouncil complete. Joining either clan is optional. Speak to its sponsor for an oath, initiation and promotion."
		elif p.ledger and p.heard.size()==2:
			description.text = "The ledger proves the raiders exploited a shared failure. How should the holds repair the road? Your policy affects clan reputation; it does not enroll you in either clan."
			_button("Shared patrols and rune repairs · +10 both clans", "settle:accord")
			_button("Fund Stoneguard patrols · +20 Stoneguard / −5 Stormweaver", "settle:stoneguard")
			_button("Fund Stormweaver wards · +20 Stormweaver / −5 Stoneguard", "settle:stormweaver")
		else: description.text += "\n\n" + objective()
		description.text+="\n\n"+letters_objective()
		if not p.get("letters_started",false): _button("Ask about the families' undelivered letters","letters_accept")
		elif p.get("letters_witness",false) and p.get("letters_choice","")=="":
			description.text="RUNA · LETTERS ABOVE THE SNOW\n\nBoth families blamed the other for a death they never witnessed. The final watch record shows Mara and Oren saving travelers together.\n\nWe can add the full account to the public memorial, or return copies privately and let the families choose when to speak. I can settle a road budget in one afternoon. Grief refuses to observe the agenda."
			_button("Publish their shared final watch · +10 both clans, 150 gold, 4 Steel Ingots","letters_public")
			_button("Return private family replies · +5 both clans, 120 gold, 4 Silver Ingots","letters_private")
	elif id in CLANS:
		var c: Dictionary = CLANS[id]
		description.text = c.name + ": " + c.value + "\n\nReputation: %d. " % p.reputation[id] + ("Your rank: " + rank_name() if p.clan == id else "")
		description.text += "\n\n" + ("A shield is a door you carry. Try to keep yourself on the indoor side." if id=="stoneguard" else "Hadrik calls magic unreliable. His last bridge fell down without casting a single spell.") if p.rank<2 else ""
		if id in p.heard:
			description.text += "\n\nTestimony: Our stores vanished while the road wards flickered. Without reliable patrols, even a working rune cannot protect a wagon." if id=="stoneguard" else "\n\nTestimony: The supply route lost its warning runes before the ambushes. Someone cut the conductors. Find the ledger before calling our work a failure."
		if p.accepted and id not in p.heard: _button("Hear the clan's council testimony", "hear")
		if p.settlement == "": description.text += "\nSettle the council before considering an oath."
		elif p.clan == "":
			description.text += "\n\nChoose one clan for this character. Joining closes membership in its rival, but both shops and the main story stay available. Initiation: repair three road wards with supplied iron and timber." if id == "stoneguard" else "\n\nChoose one clan for this character. Joining closes membership in its rival, but both shops and the main story stay available. Initiation: channel 15 magicka into each of three road wards."
			_button("Join " + c.name + " · decline rival membership", "join")
		elif p.clan != id: description.text += "\n\nYou swore to our rival. We will still trade and honor the council settlement."
		elif p.rank == 0:
			description.text += "\n\nRestore the west, south and east road wards. %d / 3 complete." % p.wards.size()
			if p.wards.size()==3: _button("Complete initiation · become Sworn", "initiate")
		elif p.rank == 1:
			description.text += "\n\nYour first promotion: provision the smithy and market supply posts. Each needs two steel ingots." if id == "stoneguard" else "\n\nYour first promotion: provision the smithy and market supply posts. Each needs three crystals."
			if p.services.size()==2: _button("Claim promotion · Shieldbearer and advanced patterns", "promote")
		else:
			if p.get("mandate","")!="": description.text+="\n\nAs Clan Voice, you secured "+("shared patrols under independent holds." if p.mandate=="holds" else "a central war leader for the mountain roads.")
			elif state.choir.get("fire_choice","")=="awaken": description.text+="\n\nYour Choir conquest oath permanently closes the Clan Voice commission and mandate."
			elif not p.get("expedition",false):
				description.text+="\n\nA Crown of Separate Holds: prove the roads can be defended. Harvest the north-pass colossus and Rimefang on Frostmere’s eastern bank, then return to decide who commands the patrols. Earlier harvests count."
				_button("Accept the road-defense commission","expedition")
			else:
				description.text+="\n\nRoad threats harvested: %d / 2. Return with both proofs for Clan Voice rank, 160 gold and a forgeable Clan Voice Signet." % expedition_proofs()
				if expedition_proofs()==2:
					_button("Independent holds · shared patrols · both clans gain reputation","mandate:holds")
					_button("Central war leader · favor your clan · rival reputation falls","mandate:leader")
		if p.get("letters_started",false):
			description.text+="\n\n"+("Hadrik's family letter says Mara's warning never came, so his brother Oren died waiting on the pass." if id=="stoneguard" else "Sera's family letter says Mara died carrying a warning after Oren abandoned his post. Neither family saw the final watch record.")
			if id not in p.get("letters_received",[]): _button("Carry this family's account to the memorial","letters_read")
	elif id == "memorial":
		description.text="PASSKEEPERS' RECORD\n\nThe keeper recorded two arrivals during the whiteout: Mara brought the warning; Oren left his post to find her. They escorted six travelers into shelter, then went back for the last wagon. Both names appear under the same final watch. Neither abandoned the other."
		if p.get("letters_received",[]).size()!=2: description.text+="\n\nBring both families' accounts before comparing the dates and names."
		elif not p.get("letters_witness",false): _button("Copy the final watch record","letters_verify")
		else: description.text+="\n\n"+letters_objective()
	elif id == "ledger":
		description.text = "The reavers' ledger records stolen supplies and deliberate damage to the old wards."
		if not p.accepted: description.text += "\nSpeak to the council before investigating."
		elif p.defeated.size()<3: description.text += "\nDefeat the three reavers guarding the outpost first."
		elif not p.ledger: _button("Recover the ledger · quest evidence cannot be sold", "ledger")
		else: description.text += "\nEvidence already recovered."
	elif id in ["west","south","east"]:
		description.text = "A roadside ward protects travelers from storms."
		if p.clan=="": description.text += "\nA clan oath opens this initiation."
		elif id in p.wards: description.text += "\nAlready restored."
		else: _button("Repair · 1 iron ingot + 2 timber" if p.clan=="stoneguard" else "Attune · 15 magicka", "ward")
	else:
		description.text = "A shared supply post serves the whole town. Clan service here earns your first promotion."
		if p.rank==1 and id not in p.services: _button("Deliver 2 steel ingots" if p.clan=="stoneguard" else "Deliver 3 crystals", "service")
		else: description.text += "\n" + ("Delivery complete." if id in p.services else "Complete your initiation first.")
func act(id: String) -> bool:
	if not dialog.visible or not inside or world.player.position.distance_to(interaction_position(subject))>=2.3: return false
	var p: Dictionary = state.mountain
	var success := false
	if id=="shelter_start" and subject=="shelter_notice" and int(p.get("shelter_stage",0))==0:
		p.shelter_stage=1; success=true
	elif id=="shelter_find" and subject=="travelers" and int(p.get("shelter_stage",0))==1:
		p.shelter_stage=2; success=true
	elif id=="shelter_heat" and subject=="hearth" and int(p.get("shelter_stage",0))==2:
		if not state.can_pay({"wood":4}): description.text="The hearth needs 4 wood. Bring supplies from town; no materials were spent."; return false
		state.materials.wood-=4; p.shelter_stage=3; success=true; world.audio.sfx("enchant")
	elif id in ["shelter_road","shelter_ridge"] and subject=="travelers" and int(p.get("shelter_stage",0))==3 and p.get("shelter_choice","")=="":
		if id=="shelter_road" and p.defeated.size()<3: return false
		p.shelter_choice="road" if id=="shelter_road" else "ridge"; state.gold+=120
		var uid: String=state.add_item("fur_feet",2,"fleet"); state.inventory[uid].favorite=true; state.inventory[uid].custom_name="Last Warm Mile"
		world.adventure.grant_materials({"steel_ingot":4} if p.shelter_choice=="road" else {"herb":8,"water":6}); success=true
	elif id=="letters_accept" and subject=="council" and not p.get("letters_started",false): p.letters_started=true; success=true
	elif id=="letters_read" and subject in CLANS and p.get("letters_started",false) and subject not in p.get("letters_received",[]):
		if not p.has("letters_received"): p.letters_received=[]
		p.letters_received.append(subject); success=true
	elif id=="letters_verify" and subject=="memorial" and p.get("letters_received",[]).size()==2 and not p.get("letters_witness",false): p.letters_witness=true; success=true
	elif id in ["letters_public","letters_private"] and subject=="council" and p.get("letters_witness",false) and p.get("letters_choice","")=="":
		p.letters_choice="public" if id=="letters_public" else "private"
		for clan in CLANS: p.reputation[clan]=mini(100,int(p.reputation[clan])+(10 if p.letters_choice=="public" else 5))
		state.gold+=150 if p.letters_choice=="public" else 120
		world.adventure.grant_materials({"steel_ingot":4} if p.letters_choice=="public" else {"silver_ingot":4})
		success=true; world.audio.sfx("quest")
	elif id == "accept" and subject=="council" and not p.accepted: p.accepted=true; success=true
	elif id=="hear" and subject in CLANS and p.accepted and subject not in p.heard: p.heard.append(subject); success=true
	elif id=="ledger" and subject=="ledger" and p.accepted and p.defeated.size()==3 and not p.ledger: p.ledger=true; success=true
	elif id.begins_with("settle:") and subject=="council" and p.ledger and p.heard.size()==2 and p.settlement=="":
		var policy := id.get_slice(":",1)
		if policy not in ["accord","stoneguard","stormweaver"]: return false
		p.settlement=policy
		for clan: String in CLANS: p.reputation[clan] += 10 if policy=="accord" else 20 if policy==clan else -5
		if "council" not in state.story_completed: state.story_completed.append("council")
		state.gold+=120; world.adventure.grant_materials({"steel_ingot":5,"rune_dust":6}); success=true
	elif id=="join" and subject in CLANS and p.settlement!="" and p.clan=="":
		p.clan=subject; p.reputation[subject]+=5
		if subject=="stoneguard": world.adventure.grant_materials({"iron_ingot":3,"wood":6})
		success=true
	elif id=="ward" and subject in ["west","south","east"] and p.clan!="" and p.rank==0 and subject not in p.wards:
		if p.clan=="stoneguard":
			if not spend({"iron_ingot":1,"wood":2}): return false
		else:
			if world.player.magicka<15: description.text += "\nNot enough magicka."; return false
			world.player.magicka-=15
		p.wards.append(subject); success=true
	elif id=="initiate" and subject==p.clan and p.rank==0 and p.wards.size()==3:
		p.rank=1; p.reputation[p.clan]+=25
		state.blueprints.append(p.clan); state.formulas.append(CLANS[p.clan].formula)
		var uid: String = state.add_item(CLANS[p.clan].weapon,1,CLANS[p.clan].formula); state.inventory[uid].favorite=true
		world.adventure.grant_materials({"steel_ingot":3,"crystal":3}); success=true
	elif id=="service" and subject in ["supply_west","supply_east"] and p.rank==1 and subject not in p.services:
		if not spend({"steel_ingot":2} if p.clan=="stoneguard" else {"crystal":3}): return false
		p.services.append(subject); success=true
	elif id=="promote" and subject==p.clan and p.rank==1 and p.services.size()==2:
		p.rank=2; p.reputation[p.clan]+=25; state.blueprints.append(p.clan+"_veteran"); state.gold+=80
		var uid: String = state.add_item(p.clan+"_chest",2,CLANS[p.clan].formula); state.inventory[uid].favorite=true; success=true
	elif id=="expedition" and state.choir.get("fire_choice","")!="awaken" and subject==p.clan and p.rank==2 and not p.get("expedition",false):
		p.expedition=true; success=true
	elif id.begins_with("mandate:") and state.choir.get("fire_choice","")!="awaken" and subject==p.clan and p.rank==2 and p.get("expedition",false) and expedition_proofs()==2:
		var mandate:=id.get_slice(":",1)
		if mandate not in ["holds","leader"]: return false
		p.mandate=mandate; p.rank=3
		for clan in CLANS: p.reputation[clan]=clampi(p.reputation[clan]+(15 if clan==p.clan else 10) if mandate=="holds" else p.reputation[clan]+(25 if clan==p.clan else -10),-100,100)
		state.gold+=160; var uid: String=state.add_item("clan_voice_signet",2); state.inventory[uid].favorite=true
		if "clan_voice" not in state.blueprints: state.blueprints.append("clan_voice")
		world.adventure.grant_materials({"steel_ingot":4,"silver_ingot":2} if mandate=="holds" else {"steel_ingot":6,"crystal":2}); success=true
	if success:
		if id.begins_with("shelter_"): world.hud.world_map.selected_quest="side_rimegate"
		if id.begins_with("letters_"): world.hud.world_map.selected_quest="side_wyrmkeep"
		elif id == "join": world.hud.world_map.selected_quest = "iron_pact_1"
		elif id == "initiate": world.hud.world_map.selected_quest = "iron_pact_2"
		elif id=="expedition" or id.begins_with("mandate:"): world.hud.world_map.selected_quest="iron_pact_3"
		state._commit()
		if id=="shelter_heat": close_dialog(); world.player.set_paused(false); world.hud.announce("The last warm shelter","The travelers have reached the watch hut. Speak to Marae beside the hearth.")
		else: open_dialog(subject)
	return success
func spend(cost: Dictionary) -> bool:
	for id: String in cost:
		if int(state.materials.get(id,0))<cost[id]: description.text += "\nMissing supplies. Buy them in town or bring them from Frostmere."; return false
	for id: String in cost: state.materials[id]-=cost[id]
	return true
func rank_name() -> String:
	return "Independent" if state.mountain.clan=="" else ["Recruit","Sworn","Shieldbearer","Clan Voice"][state.mountain.rank]
func letters_objective() -> String:
	var p: Dictionary=state.mountain
	if p.get("letters_choice","")=="public": return "Letters Above the Snow complete · Mara and Oren are honored together in the public record. Both clans acknowledge their shared last watch."
	if p.get("letters_choice","")=="private": return "Letters Above the Snow complete · both families received private copies. The truth is theirs to share when they are ready."
	if not p.get("letters_started",false): return "Letters Above the Snow · Ask Runa about the undelivered family letters."
	if p.get("letters_received",[]).size()!=2: return "Carry both family accounts · %d / 2. Speak to Hadrik and Sera; no clan oath is required." % p.get("letters_received",[]).size()
	if not p.get("letters_witness",false): return "Compare the accounts at the passkeepers' memorial, just west of Wyrmkeep's central road."
	return "Return the final watch record to Runa and decide how to deliver the truth."

func objective() -> String:
	var p: Dictionary = state.mountain
	if not p.accepted: return "Speak with Speaker Runa in the council hall"
	if p.heard.size()<2: return "Hear both clan sponsors · %d / 2" % p.heard.size()
	if not p.ledger: return "Defeat the road reavers and recover the northern outpost ledger"
	if p.settlement=="": return "Return the evidence to Speaker Runa"
	if p.clan=="": return "Council settled · optionally take a clan oath"
	if p.rank==0: return "%s Recruit · restore road wards (%d / 3), then report" % [CLANS[p.clan].name,p.wards.size()]
	if p.rank==1: return "%s Sworn · supply both posts (%d / 2), then report" % [CLANS[p.clan].name,p.services.size()]
	if p.rank==3: return "Clan Voice · "+("Independent holds and shared patrols" if p.mandate=="holds" else "Central war leader")
	if p.get("expedition",false): return "Road-defense commission · %d / 2 harvests · report to your sponsor" % expedition_proofs()
	return CLANS[p.clan].name + " Shieldbearer · advanced patterns unlocked"
func mark_defeated(id: String) -> void:
	if id not in state.mountain.defeated: state.mountain.defeated.append(id); state._commit()
func loot(id: String) -> bool:
	if id not in state.mountain.defeated or id in state.mountain.looted: return false
	state.mountain.looted.append(id); state.gold+=20; world.adventure.grant_materials({"steel_ingot":1,"crystal":1}); state._commit()
	for enemy in enemies: enemy._update_label()
	return true
func fire(origin: Vector3,direction: Vector3,damage: float,hostile: bool,source: CollisionObject3D,magic: bool) -> void:
	world.adventure.fire(origin,direction,damage,hostile,source,magic)
func line_clear(from: Vector3,to: Vector3,source: CollisionObject3D,target_body: CollisionObject3D=null) -> bool:
	return world.adventure.line_clear(from,to,source,target_body)
func check_fall() -> void:
	if world.player.position.y < -8 or absf(world.player.position.x-ORIGIN.x)>54 or world.player.position.z < -86 or world.player.position.z>59:
		world.player.position = ORIGIN + Vector3(0,0.2,32); world.player.velocity=Vector3.ZERO
func close_dialog() -> void:
	dialog.hide(); world.player.dialog_open=false
func _process(delta: float) -> void:
	preview_label.visible = "--mountain-preview" in OS.get_cmdline_user_args() and not world.player.paused
	if feedback_time>0:
		world.adventure.feedback=feedback; world.adventure.feedback_time=feedback_time; feedback_time=maxf(0,feedback_time-delta)

func _sign(p: Vector3, label: String) -> void:
	var sign := Label3D.new(); sign.position=p; sign.text=label; sign.font_size=22; sign.pixel_size=0.003
	sign.billboard=BaseMaterial3D.BILLBOARD_ENABLED; sign.visibility_range_begin=4.5; sign.visibility_range_end=22
	add_child(sign)

func expedition_proofs() -> int:
	var count:=0
	for id in ["wild_11","wild_12"]:
		if id in state.wilderness.looted: count+=1
	return count

func interaction_position(id: String) -> Vector3:
	if id=="travelers" and int(state.mountain.get("shelter_stage",0))==3: return ORIGIN+Vector3(30,0,-54)
	return ORIGIN+NODES[id]
func shelter_objective() -> String:
	var p: Dictionary=state.mountain
	if p.get("shelter_choice","")!="": return "The Last Warm Shelter complete · "+("The road is cleared and the travelers rest before returning home." if p.shelter_choice=="road" else "The travelers wait by the restored hearth for a ridge guide after the thaw.")
	return ["Read the Rimegate overdue notice beside Wyrmkeep's southern road.","Find the stranded group northeast of Wyrmkeep, below the watch hut.","Restore the hearth in the northeastern watch hut · 4 wood.","Speak to sheltered Marae. Clear all three northern outpost raiders for the road route, or arrange a guide after the thaw."][int(p.get("shelter_stage",0))]
func shelter_dialog() -> void:
	var p: Dictionary=state.mountain
	var stage: int=int(p.get("shelter_stage",0))
	description.text=shelter_objective()
	if subject=="shelter_notice" and stage==0:
		description.text="Three travelers from the Rimegate pass are overdue. Last seen northeast of Wyrmkeep. The old watch hut still has a roof, which puts it ahead of several official rescue plans."
		_button("Look for the stranded travelers","shelter_start")
	elif subject=="travelers":
		if stage==1:
			description.text="Marae: We turned back when the pass vanished in snow. The hut is just north, but its hearth is cold. Four lengths of dry wood would give us time to think without our teeth doing the talking."
			_button("Help the group reach a warm shelter","shelter_find")
		elif stage==3 and p.get("shelter_choice","")=="":
			description.text="Marae: Warm fingers. I had forgotten I owned those.\n\nWe can rest here, then return along the northern road if its three raiders are gone. Or wait for a ridge guide after the thaw. Either way, we stay beside this hearth until departure.\n\nBoth arrangements grant 120 gold and Superior Fleet-enchanted fur boots."
			if p.defeated.size()==3: _button("Arrange the cleared road home · 4 Steel Ingots","shelter_road")
			else: description.text+="\n\nThe road still has raiders. The guide arrangement is available now."
			_button("Arrange a ridge guide after the thaw · 8 herbs, 6 water","shelter_ridge")
	elif subject=="hearth":
		description.text="A sheltered stone hearth with a clear chimney. It needs 4 wood to restore its fire.\n\n"+shelter_objective()
		if stage==2: _button("Light the watch hut hearth · spend 4 wood","shelter_heat")

func interaction_name(id: String) -> String:
	return "Marae · sheltered travelers" if id=="travelers" and int(state.mountain.get("shelter_stage",0))==3 else NAMES[id]
