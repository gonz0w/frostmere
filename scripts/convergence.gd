extends Node3D
const State=preload("res://scripts/character_state.gd")
const Visual=preload("res://scripts/character_visual.gd")
const Enemy=preload("res://scripts/enemy.gd")
const ORIGIN=Vector3(1920,0,0)
const TRAIL=Vector3(25,0,34)
const REQUIRED=["roots","tides","lens","choir"]
const NODES={"rescue_light":Vector3(-25,0,12),"rescue_winch":Vector3(-25,0,22),"rescue_cache":Vector3(-25,0,32),"names_dock":Vector3(-23,0,30),"names_roll":Vector3(7,0,7),"names_seal":Vector3(15,0,-55),"return":Vector3(0,0,40),"keeper":Vector3(-16,.25,24),"forge":Vector3(15,0,24),"enchant":Vector3(21,0,24),"supplies":Vector3(0,0,24),"roots":Vector3(-19,0,13),"tides":Vector3(-9,0,13),"lens":Vector3(9,0,13),"choir":Vector3(19,0,13),"rig":Vector3(0,0,-27),"beacon":Vector3(0,0,-63)}
const NAMES={"rescue_light":"Moving light beneath the boards","rescue_winch":"Jammed service-vault winch","rescue_cache":"Scavenger’s sealed salvage cache","names_dock":"Waterlogged passenger list","names_roll":"Erased relief register","names_seal":"Sealed evacuation testimony","return":"Marsh road · Frostmere","keeper":"Expedition leader Ilyra","forge":"Expedition forge","enchant":"Expedition rune table","supplies":"Crew's repair supplies","roots":"Woodland account","tides":"Wreck recorder","lens":"Observatory chart","choir":"Choir frequency","rig":"Transit calibration rig","beacon":"Stable return beacon"}
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
var lights: Dictionary={}
var beacon: MeshInstance3D
var rescue_npc: Node3D
var rescue_glow: MeshInstance3D
var rescue_lid: Node3D
var rescue_time:=0.0
func _ready() -> void:
	state=world.player.character; _build(); _ui(); state.changed.connect(_refresh); _refresh()
func box(p: Vector3,size: Vector3,key: String,solid: bool=false,angle: float=0) -> void:
	world.blocks.add(key,ORIGIN+p,size,angle)
	if solid: world._solid(ORIGIN+p,size)
func _build() -> void:
	var b: RefCounted=world.blocks
	for entry in [["mire_water","455e61"],["mire_reed","747f55"],["mire_glow","83d4c6"]]:
		var mat: StandardMaterial3D=b.materials["window" if entry[0]=="mire_glow" else "stone"].duplicate(); mat.albedo_color=Color(entry[1]); b.materials[entry[0]]=mat
	b.materials.mire_water=preload("res://scripts/regional_water.gd").material(true)
	rescue_glow=MeshInstance3D.new(); var glow_box:=BoxMesh.new(); glow_box.size=Vector3(.3,.3,.3); rescue_glow.mesh=glow_box
	rescue_glow.material_override=b.materials["mire_glow"].duplicate(); rescue_glow.material_override.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED; rescue_glow.position=ORIGIN+NODES.rescue_light+Vector3(0,.18,0); add_child(rescue_glow)
	world.blocks.piece(self,"wood",ORIGIN+NODES.rescue_winch+Vector3.UP*.65,Vector3(1.1,.2,.3))
	world.blocks.piece(self,"timber",ORIGIN+NODES.rescue_winch+Vector3.UP*.35,Vector3(.2,.7,.2))
	world.blocks.piece(self,"stone_dark",ORIGIN+NODES.rescue_cache+Vector3.UP*.3,Vector3(1.3,.6,1))
	rescue_lid=Node3D.new(); rescue_lid.position=ORIGIN+NODES.rescue_cache+Vector3(0,.6,-.5); add_child(rescue_lid)
	world.blocks.piece(rescue_lid,"wood",Vector3(0,0,.5),Vector3(1.3,.15,1))
	rescue_npc=Visual.new(); rescue_npc.position=ORIGIN+Vector3(-23,0,24); rescue_npc.rotation.y=PI; add_child(rescue_npc)
	var rescued_model:=State.new()
	for slot in ["head","chest","hands","legs","feet"]: rescued_model.equip(rescued_model.add_item("leather_"+slot),slot)
	rescued_model.unequip("main_hand"); rescued_model.unequip("off_hand")
	rescue_npc.build(rescued_model)
	box(Vector3(0,-2.2,-18),Vector3(130,.3,160),"mire_water")
	# Broad stilt platforms joined by a narrow boardwalk. Only the decks carry collision.
	for deck in [[0,24,56,34],[0,-12,10,60],[0,-50,46,46]]:
		var x: float=deck[0]; var z: float=deck[1]; var width: int=deck[2]; var depth: int=deck[3]
		world._solid(ORIGIN+Vector3(x,-.3,z),Vector3(width,.5,depth))
		for row in range(depth*2): box(Vector3(x,-.02,z-depth*.5+row*.5),Vector3(width,.12,.46),"wood")
		for side in [-1,1]:
			for post in range(depth/4):
				box(Vector3(x+side*(width*.5-.3),-1,z-depth*.5+post*4),Vector3(.4,3,.4),"timber")
			box(Vector3(x+side*(width*.5-.3),.8,z),Vector3(.15,.15,depth),"wood")
	world._house(ORIGIN+Vector3(-16,0,20),10,12,3.8,false,"convergence_lodge")
	for x in [11,25]:
		for z in [19,29]: box(Vector3(x,1.9,z),Vector3(.22,3.8,.22),"timber",true)
	for row in range(20): box(Vector3(18,3.9-absf(row-10)*.04,19+row*.5),Vector3(15,.16,.48),"roof")
	for side in [-1,1]:
		for i in range(28):
			var p:=Vector3(side*(31+i%5*4),-1.7,-80+i*5)
			for reed in range(7): box(p+Vector3(sin(reed*2.4)*1.1,.6+reed*.08,cos(reed*2.4)),Vector3(.12,1.7+reed*.1,.12),"mire_reed")
		for i in range(9):
			var p:=Vector3(side*(43+i%2*4),0,-72+i*14)
			box(p+Vector3.UP*2,Vector3(1.1,8,1.1),"timber")
			for tier in range(4):
				for branch in range(6): box(p+Vector3(side*(tier*.4),5+tier*.6,branch*.45-1),Vector3(4-tier*.5,.45,.4),"pine")
	for id: String in NODES:
		var p: Vector3=NODES[id]; _sign(ORIGIN+p+Vector3.UP*2,NAMES[id])
		if id=="keeper":
			var npc:=Visual.new(); npc.position=ORIGIN+p; npc.rotation.y=PI; add_child(npc)
			var model:=State.new()
			for slot in ["head","chest","hands","legs","feet"]: model.equip(model.add_item("cloth_"+slot),slot)
			npc.build(model)
		elif id!="return" and not id.begins_with("rescue_"):
			box(p+Vector3.UP*.45,Vector3(1.5,.9,1.1),"stone_dark" if id in ["rig","beacon"] else "wood",id in ["forge","enchant"])
			box(p+Vector3.UP*.95,Vector3(1.7,.12,1.2),"iron")
		if id in REQUIRED:
			box(p+Vector3.UP*1.1,Vector3(.95,.08,.65),"fur")
			lights[id]=b.piece(self,"coal",ORIGIN+p+Vector3(.6,1.2,0),Vector3(.2,.2,.2))
	# An open circular instrument cage above the return beacon, clear of the walking route.
	for ring in range(3):
		for step in range(64):
			var a: float=TAU*step/64
			box(Vector3(cos(a)*(3+ring*.4),3+ring*.8,-63+sin(a)*(3+ring*.4)),Vector3(.35,.22,.35),"iron" if ring%2 else "gold")
	for side in [-1,1]: box(Vector3(side*4,2,-63),Vector3(.4,4,.4),"iron",true)
	beacon=b.piece(self,"mire_glow",ORIGIN+NODES.beacon+Vector3.UP*2,Vector3(.9,1.3,.9))
	for p in [Vector3(0,0,32),Vector3(-4,0,-4),Vector3(4,0,-22),Vector3(-14,0,-49),Vector3(14,0,-49)]: world._lantern(ORIGIN+p,false)
	world.block_count+=b.finish(world); _sign(TRAIL+Vector3.UP*2,"Expedition road · Mirewatch")
	var positions=[Vector3(-12,0,-44),Vector3(12,0,-46),Vector3(0,0,-59)]
	for i in range(3):
		var enemy:=Enemy.new(); enemy.adventure=self; enemy.progress=state.convergence; enemy.enemy_id="convergence_"+str(i); enemy.role="boss" if i==2 else "mage" if i==1 else "guard"
		enemy.title="The Misbound Navigator" if i==2 else "Awakened Survey Sentinel"; enemy.health_override=320 if i==2 else 110; enemy.position=ORIGIN+positions[i]+Vector3.UP*.15
		add_child(enemy); enemies.append(enemy)
func ready_for_expedition() -> bool:
	for id in REQUIRED:
		if id not in state.story_completed: return false
	return true
func _sign(p: Vector3,label: String) -> void:
	var sign:=Label3D.new(); sign.position=p; sign.text=label; sign.font_size=22; sign.pixel_size=.003; sign.billboard=BaseMaterial3D.BILLBOARD_ENABLED; sign.visibility_range_begin=4.5; sign.visibility_range_end=18; add_child(sign)
func _ui() -> void:
	var layer:=CanvasLayer.new(); layer.layer=7; add_child(layer)
	preview_label=Label.new(); preview_label.position=Vector2(32,76); preview_label.text="MIREWATCH PREVIEW · progress is not saved"; layer.add_child(preview_label)
	dialog=ColorRect.new(); dialog.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); dialog.color=Color("1f292b"); layer.add_child(dialog)
	var center:=CenterContainer.new(); center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); dialog.add_child(center)
	var col:=VBoxContainer.new(); col.custom_minimum_size.x=720; col.add_theme_constant_override("separation",16); center.add_child(col)
	title=Label.new(); title.add_theme_font_size_override("font_size",25); col.add_child(title)
	description=Label.new(); description.custom_minimum_size=Vector2(720,230); description.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART; description.add_theme_font_size_override("font_size",18); col.add_child(description)
	options=VBoxContainer.new(); col.add_child(options)
	var close:=Button.new(); close.text="Return [ Esc ]"; close.custom_minimum_size.y=42; close.pressed.connect(func(): close_dialog(); world.player.set_paused(false)); col.add_child(close); dialog.hide()
func _button(label: String,id: String) -> void:
	var button:=Button.new(); button.text=label; button.custom_minimum_size.y=42; button.pressed.connect(func(): act(id)); options.add_child(button)
func enter() -> bool:
	if world.player.paused or not ready_for_expedition(): return false
	if inside: return true
	for chapter in [world.seal,world.winter,world.threshold,world.choir,world.lens,world.roots,world.shore,world.archive_chapter,world.mountain,world.realms,world.adventure]:
		if chapter.inside: chapter.leave()
	inside=true; world.player.position=ORIGIN+Vector3(0,.2,40); world.player.velocity=Vector3.ZERO; world.player.rotation=Vector3.ZERO
	for child in world.get_children():
		if child is WorldEnvironment:
			environment_backup=child.environment
			var env: Environment=environment_backup.duplicate(true); env.background_mode=Environment.BG_COLOR; env.background_color=Color("526768"); env.fog_light_color=Color("748d87"); env.fog_density=.004; env.ambient_light_color=Color("b8cebf"); preload("res://scripts/regional_sky.gd").apply(env,"convergence"); child.environment=env
	world.hud.world_map.selected_quest="convergence"; world.hud.world_map.set_view(true); world.audio.sfx("portal")
	world.hud.announce("Mirewatch","Four discoveries. One expedition. Ilyra waits at the stilt camp."); return true
func leave() -> void:
	if not inside: return
	inside=false; world.adventure.clear_projectiles(); world.player.position=TRAIL+Vector3(0,.2,2.5); world.player.velocity=Vector3.ZERO
	for child in world.get_children():
		if child is WorldEnvironment and environment_backup!=null: child.environment=environment_backup
	for enemy in enemies:
		if not enemy.dead: enemy.position=enemy.home; enemy.health=enemy.maximum_health; enemy.velocity=Vector3.ZERO; enemy.windup=0; enemy._update_label()
func nearest() -> Dictionary:
	if not inside:
		if world.player.position.distance_to(TRAIL)<2.5: return {"kind":"convergence","id":"trail","text":"[ E ] Travel to Mirewatch"}
		return {}
	for enemy in enemies:
		if enemy.dead and enemy.enemy_id not in state.convergence.looted and world.player.position.distance_to(enemy.position)<2.5: return {"kind":"convergence","id":enemy.enemy_id,"text":"[ E ] Recover survey relics"}
	for id: String in NODES:
		if world.player.position.distance_to(ORIGIN+NODES[id])<2.3: return {"kind":"convergence","id":id,"text":"[ E ] "+NAMES[id]}
	return {}
func station_nearby() -> String:
	for id in ["forge","enchant"]:
		if inside and world.player.position.distance_to(ORIGIN+NODES[id])<2.3: return id
	return ""
func interact(id: String) -> void:
	if world.player.paused or nearest().get("id","")!=id: return
	if id=="trail":
		if not enter(): world.hud.announce("The expedition road","Bring the woodland memory, wreck recorder, star chart and Choir frequency before traveling to Mirewatch.")
	elif id=="return": leave()
	elif id in ["forge","enchant"]: world.hud.workshop.open(id)
	elif id.begins_with("convergence_"): loot(id)
	else: open_dialog(id)
func _refresh() -> void:
	beacon.visible=state.convergence.calibrated
	rescue_npc.visible=state.convergence.get("rescue_stage",0)>=3
	rescue_glow.visible=state.convergence.get("rescue_stage",0)<3
	rescue_lid.rotation.x=-1.2 if state.convergence.get("rescue_stage",0)==4 else 0
	for id: String in REQUIRED: lights[id].material_override=world.blocks.materials["mire_glow" if id in state.convergence.evidence else "coal"]
func open_dialog(id: String) -> void:
	subject=id; world.player.dialog_open=true; world.player.set_paused(true); dialog.show()
	for child in options.get_children(): options.remove_child(child); child.queue_free()
	title.text=NAMES[id].to_upper()
	var p: Dictionary=state.convergence
	if id=="keeper":
		description.text="ILYRA · THE EXPEDITION\n\nThe chart gives us a destination. The wreck recorder describes the crossing. The Choir has its beacon frequency. And the woodland memory tells us what must never power the gate. Lay out all four findings, forge a transit regulator from the crew's supplies, and fit it to the calibration rig.\n\nThe test may awaken the survey sentinels. Clear them, stabilize the return beacon, and bring me the results. We will use a closed crystal reserve, leaving the land and furnace untouched. I would like one expedition where “survivors” means everyone."
		if p.rewarded: description.text="ILYRA · A ROAD WITH A WAY HOME\n\nThe return beacon holds. We have a route, an independent power reserve and a warning to keep the furnace sealed. Your expedition equipment is ready. The return beacon is the expensive part. Please come back often enough to justify it. The next crossing will begin at the Sunken Lens, through the crossing beside its recovered star chart."
		if not p.accepted: _button("Prepare the expedition","accept")
		if p.calibrated and not p.rewarded: _button("Report a stable return route · claim expedition gear","reward")
		description.text+="\n\n"+objective()
		description.text+="\n\n"+rescue_objective()
		if p.get("rescue_stage",0)==0: _button("Ask about the lights beneath the boards","rescue_accept")
	elif id.begins_with("rescue_"):
		var stage: int=p.get("rescue_stage",0)
		description.text=rescue_objective()+"\n\n"
		if id=="rescue_light":
			description.text+="The light blinks three times, pauses, then repeats. Below the boards, someone coughs. 'If you are a ghost, fetch a living person. If you are a living person, do stop rehearsing.' A jammed service-vault door has trapped a scavenger under the western deck."
			if stage==1: _button("Answer the signal · locate the jammed winch","rescue_signal")
		elif id=="rescue_winch":
			description.text+="A bent catch holds the vault door shut. The scavenger calls himself Tovin. 'I checked the lock from the inside. Very thorough. Terrible business model.' The hand crank can lift the catch without spending your supplies."
			if stage==2: _button("Release the catch and haul Tovin onto the deck","rescue_free")
			elif stage>=3: description.text+="\n\nTovin is safely beside the winch. 'Next time I rob a tomb, I am checking the return policy.'"
		else:
			description.text+="Tovin's cache holds 90 gold, six crystals, four rune dust and two healing draughts. 'Take them. I was saving for a decent funeral. You've made that awkward.'"
			if stage==3: _button("Open the salvage cache · claim your reward","rescue_reward")
			elif stage==4: description.text+="\n\nThe cache is empty. Tovin keeps his second chance."
	elif id.begins_with("names_"):
		description.text={"names_dock":"A waterlogged passenger list names families sent through a crossing that officials called empty.","names_roll":"A relief register shows food issued to those same families. Someone scraped their names from the public copy.","names_seal":"The sealed testimony confirms a deliberate evacuation. Publishing these names restores the missing to history, but also identifies surviving witnesses."}[id]
		if not state.archive.get("names_accepted",false): description.text+="\n\nSpeak to Mereth as a Lantern Witness before collecting this evidence."
		elif id=="names_seal" and not p.calibrated: description.text+="\n\nStabilize Mirewatch's return beacon before recovering the northern sealed records."
		elif id not in state.archive.get("names_records",[]): _button("Recover protected testimony","names_collect")
		else: description.text+="\n\nAlready copied. Return all three records to Mereth."
	elif id in REQUIRED:
		description.text={"roots":"WOODLAND ACCOUNT\n\nThe first crossing drained living land. Our regulator must use an isolated crystal reserve.","tides":"WRECK RECORDER\n\nThe Wayfarer lost its return bearing during transit. We need a stable beacon before departure.","lens":"OBSERVATORY CHART\n\nThe abandoned station lies beyond the First Threshold. The chart supplies its position.","choir":"CHOIR FREQUENCY\n\nThe song is a distress beacon from a stranded crew. Its warning is explicit: keep the furnace sealed."}[id]
		if id=="roots": description.text+="\n\n"+("The wild grove remains protected; gathering moved beyond its borders." if state.roots.choice=="wild" else "The tended pact preserves the shrine while the settlement replants what it gathers.")
		if id=="tides": description.text+="\n\n"+("Saltbreak kept its harbor beacon. The copied recorder still gives us the needed transit data." if state.shore.choice=="harbor" else "The restored navigation core gives us an additional bearing. Its chart confirms the recorder.")
		if not p.accepted: description.text+="\nSpeak with Ilyra before preparing the briefing."
		elif id not in p.evidence: _button("Add this finding to the expedition plan","evidence")
		else: description.text+="\n\nRecorded in the plan."
	elif id=="supplies":
		description.text="The crew has reserved 8 steel ingots, 6 crystals, 4 rune dust and 4 Ash Glass. A Transit Regulator costs 4 steel, 3 crystals and 2 rune dust. Spare materials support equipment upgrades."
		if not p.supplies: _button("Collect the crew's reserved supplies","supplies")
		else: description.text+="\n\nAlready collected."
		if state.story_recovery_available("transit_regulator"):
			description.text+="\n\nShort of ingredients? The crew kept damaged regulator parts for emergencies. Use your learned design to rebuild one dedicated unit. It cannot be sold or broken into upgrade materials."
			_button("Rebuild 1 Transit Regulator from spare parts","recover_component")
		elif int(state.materials.get("transit_regulator",0))>0 and not p.installed:
			description.text+="\n\nYour Transit Regulator is ready. Install it at the northern calibration rig."
	elif id=="rig":
		description.text="Fit one forged Transit Regulator to begin the test. This consumes the regulator and awakens the three survey sentinels on the northern platform. The crew's supply chest contains its ingredients."
		if p.installed: description.text+="\n\nThe regulator is installed. Clear the awakened sentinels and stabilize the return beacon."
		elif p.evidence.size()!=4: description.text+="\n\nAssemble all four findings to learn the regulator recipe."
		else: _button("Install 1 Transit Regulator · begin live test","install")
	elif id=="beacon":
		description.text="A return bearing makes the crossing survivable. Defeat all three awakened sentinels before locking the beacon."
		if p.calibrated: description.text+="\n\nThe return route is stable. Report to Ilyra."
		elif p.defeated.size()==3: _button("Lock the stable return bearing","calibrate")
func act(id: String) -> bool:
	if not dialog.visible or not inside or not NODES.has(subject) or world.player.position.distance_to(ORIGIN+NODES[subject])>=2.3: return false
	var p: Dictionary=state.convergence
	var success:=false
	if id=="rescue_accept" and subject=="keeper" and p.get("rescue_stage",0)==0: p.rescue_stage=1; success=true
	elif id=="rescue_signal" and subject=="rescue_light" and p.get("rescue_stage",0)==1: p.rescue_stage=2; success=true
	elif id=="rescue_free" and subject=="rescue_winch" and p.get("rescue_stage",0)==2: p.rescue_stage=3; success=true; world.audio.sfx("interact")
	elif id=="rescue_reward" and subject=="rescue_cache" and p.get("rescue_stage",0)==3:
		p.rescue_stage=4; state.gold+=90; world.adventure.grant_materials({"crystal":6,"rune_dust":4})
		state.consumables.healing_draught=int(state.consumables.get("healing_draught",0))+2; success=true; world.audio.sfx("quest")
	elif id=="accept" and subject=="keeper" and not p.accepted: p.accepted=true; success=true
	elif id=="evidence" and subject in REQUIRED and p.accepted and subject not in p.evidence:
		p.evidence.append(subject); success=true
		if p.evidence.size()==4 and "transit_regulator" not in state.blueprints: state.blueprints.append("transit_regulator")
	elif id=="supplies" and subject=="supplies" and not p.supplies:
		p.supplies=true; world.adventure.grant_materials({"steel_ingot":8,"crystal":6,"rune_dust":4,"ash_glass":4}); success=true
	elif id=="install" and subject=="rig" and p.accepted and p.evidence.size()==4 and not p.installed:
		if int(state.materials.get("transit_regulator",0))<1: description.text="Forge a Transit Regulator at the expedition forge: 4 steel ingots, 3 crystals and 2 rune dust."; world.audio.sfx("error"); return false
		state.materials.transit_regulator-=1; p.installed=true; success=true; world.audio.sfx("quest")
	elif id=="recover_component" and subject=="supplies" and state.story_recovery_available("transit_regulator"):
		state.materials.transit_regulator=1; success=true; world.audio.sfx("forge")
	elif id=="calibrate" and subject=="beacon" and p.installed and p.defeated.size()==3 and not p.calibrated: p.calibrated=true; success=true; world.audio.sfx("enchant")
	elif id=="reward" and subject=="keeper" and p.calibrated and not p.rewarded:
		p.rewarded=true; state.story_completed.append("convergence"); state.blueprints.append("expedition"); state.gold+=180
		for gear in ["wayfarer_shield","pathfinder_feet"]:
			var uid: String=state.add_item(gear,2,"vigor" if gear=="wayfarer_shield" else "fleet"); state.inventory[uid].favorite=true
		world.adventure.grant_materials({"steel_ingot":8,"crystal":6,"ash_glass":4}); success=true
	elif id=="names_collect" and subject in ["names_dock","names_roll","names_seal"] and state.archive.get("names_accepted",false) and (subject!="names_seal" or p.calibrated):
		if subject in state.archive.get("names_records",[]): return false
		if not state.archive.has("names_records"): state.archive.names_records=[]
		state.archive.names_records.append(subject); success=true
	if success:
		if id.begins_with("rescue_"): world.hud.world_map.selected_quest="side_mirewatch"
		if id=="names_collect": world.hud.world_map.selected_quest="lantern_2"
		state._commit(); open_dialog(subject)
	return success
func can_damage_enemy(_id: String) -> bool:
	return state.convergence.installed
func barrier_message() -> String:
	return "Install the transit regulator to awaken the survey sentinels"
func mark_defeated(id: String) -> void:
	if id not in state.convergence.defeated: state.convergence.defeated.append(id); state._commit()
func loot(id: String) -> bool:
	if id not in state.convergence.defeated or id in state.convergence.looted: return false
	state.convergence.looted.append(id); state.gold+=25; world.adventure.grant_materials({"steel_ingot":3,"crystal":2,"ash_glass":2}); state._commit()
	world.hud.announce("Survey relics recovered","Tempering supplies added to your collection."); return true
func rescue_objective() -> String:
	return ["Lights Beneath the Boards · Ask Ilyra about the western deck lights.","Investigate the blinking light at the northwest corner of the lodge deck.","Free the trapped scavenger using the winch halfway along the western deck.","Tovin is safe · open his salvage cache at the southwest corner of the lodge deck.","Lights Beneath the Boards complete · Tovin rescued; salvage reward collected."][int(state.convergence.get("rescue_stage",0))]

func objective() -> String:
	var p: Dictionary=state.convergence
	if p.rewarded: return "Expedition prepared · Cross from the northern Sunken Lens vault"
	if not p.accepted: return "Speak with Ilyra at the Mirewatch lodge"
	if p.evidence.size()!=4: return "Assemble the four discoveries · %d / 4" % p.evidence.size()
	if not p.installed:
		if state.story_recovery_available("transit_regulator"): return "Rebuild a regulator at the crew's supply chest, then install it"
		return "Forge a Transit Regulator, then install it at the northern rig"
	if not p.calibrated: return "Clear three survey sentinels and stabilize the return beacon"
	return "Report the successful test to Ilyra"
func close_dialog() -> void:
	dialog.hide(); world.player.dialog_open=false
func check_fall() -> void:
	var p: Vector3=world.player.position-ORIGIN
	if p.y< -1.5 or absf(p.x)>60 or p.z< -83 or p.z>44: world.player.position=ORIGIN+Vector3(0,.2,40); world.player.velocity=Vector3.ZERO
func fire(origin: Vector3,direction: Vector3,damage: float,hostile: bool,source: CollisionObject3D,magic: bool) -> void:
	world.adventure.fire(origin,direction,damage,hostile,source,magic)
func line_clear(from: Vector3,to: Vector3,source: CollisionObject3D,target_body: CollisionObject3D=null) -> bool:
	return world.adventure.line_clear(from,to,source,target_body)
func _process(delta: float) -> void:
	rescue_time+=delta if inside and not world.player.paused else 0
	rescue_glow.position=ORIGIN+NODES.rescue_light+Vector3(sin(rescue_time*2)*.7,.18,cos(rescue_time)*.35)
	var signal_phase:=fmod(rescue_time,2.4)
	rescue_glow.visible=inside and state.convergence.get("rescue_stage",0)<3 and signal_phase<1.35 and fmod(signal_phase,.45)<.26
	preview_label.visible="--convergence-preview" in OS.get_cmdline_user_args() and not world.player.paused
	if feedback_time>0: world.adventure.feedback=feedback; world.adventure.feedback_time=feedback_time; feedback_time=maxf(0,feedback_time-delta)
