extends Node3D
const WATCH_SITES={"watch_cache":Vector3(0,0,20)}
var watch_patrol: Node3D
var watch_models: Array=[]
var watch_policy:=""
var watch_clock:=0.0
const WATER_SITES={"den":Vector3(-18,0,-20),"runoff":Vector3(8,0,-48),"grovekeeper":Vector3(-3,0,12),"sluice":Vector3(7,0,-55)}
var clean_sluice: Node3D
const ROAD={"village":Vector3(6,0,8),"crossing":Vector3(22,0,-20),"ridge":Vector3(27,0,-43)}
var road_glows: Dictionary={}
var lodge_subject:="board"
const POSITION = Vector3(-8,0,12)
const TARGETS = ["wild_6", "wild_7", "wild_8", "wild_11"]
var selected := "mossbound"
var heading: Label
var world: Node3D
var state: RefCounted
var panel: ColorRect
var description: Label
var actions: VBoxContainer
var tracker: Label
func _ready() -> void:
	state=world.player.character
	for id in ROAD:
		var pos: Vector3=road_position(id)
		world.blocks.piece(self,"stone_dark",pos+Vector3.UP*.55,Vector3(.65,1.1,.65))
		road_glows[id]=world.blocks.piece(self,"window",pos+Vector3.UP*1.25,Vector3(.35,.3,.35))
		world._craft_sign(pos+Vector3.UP*1.7,"Old Watch Road · "+id,Color("c5d6a0"))
	state.changed.connect(refresh_road); refresh_road()
	for id in WATER_SITES:
		var pos: Vector3=road_position(id)
		if id=="grovekeeper":
			var npc=preload("res://scripts/character_visual.gd").new(); npc.position=pos; npc.rotation.y=PI; add_child(npc)
			var model=preload("res://scripts/character_state.gd").new()
			for slot in ["head","chest","hands","legs","feet"]: model.equip(model.add_item("cloth_"+slot),slot)
			model.equipment.main_hand=""; model.equipment.off_hand=""; npc.build(model)
		else:
			world.blocks.piece(self,"wood" if id=="den" else "stone_dark",pos+Vector3.UP*.3,Vector3(1.4,.6,1))
			if id=="runoff": world.blocks.piece(self,"coal",pos+Vector3.UP*.65,Vector3(.7,.1,.6))
		world._craft_sign(pos+Vector3.UP*2,{"den":"Abandoned drinking den","runoff":"Stained runoff channel","grovekeeper":"Grove keeper Senna","sluice":"Watershed filter sluice"}[id],Color("bdd8b0"))
	clean_sluice=Node3D.new(); clean_sluice.position=road_position("sluice"); add_child(clean_sluice)
	for i in range(5): world.blocks.piece(clean_sluice,"wood",Vector3(-.6+i*.3,.7,0),Vector3(.14,.2,1.2))
	clean_sluice.visible=state.hunt.get("water_choice","")!=""
	watch_patrol=Node3D.new(); add_child(watch_patrol); watch_patrol.visible=false
	for i in range(2):
		var guard=preload("res://scripts/character_visual.gd").new(); guard.position=Vector3(i*1.5,0,0); watch_patrol.add_child(guard); watch_models.append(guard)
	world.blocks.piece(self,"wood",road_position("watch_cache")+Vector3.UP*.5,Vector3(1.4,1,.9))
	world._craft_sign(road_position("watch_cache")+Vector3.UP*1.8,"Road watch supply cache",Color("d5c099"))
	refresh_watch()
	var board:=Node3D.new(); board.position=POSITION; add_child(board)
	world.blocks.piece(board,"wood",Vector3(0,1.4,0),Vector3(1.8,1.2,.16))
	for side in [-1,1]: world.blocks.piece(board,"timber",Vector3(side*.7,.9,0),Vector3(.16,1.8,.18))
	for x in [-.45,0,.45]: world.blocks.piece(board,"snow",Vector3(x,1.4,.1),Vector3(.32,.6,.04))
	world._craft_sign(POSITION+Vector3.UP*.4,"Hunters’ Board · E",Color("c5d6a0"))
	var layer:=CanvasLayer.new(); layer.layer=6; add_child(layer)
	tracker=Label.new(); tracker.position=Vector2(30,105); tracker.add_theme_font_size_override("font_size",14); layer.add_child(tracker)
	panel=ColorRect.new(); panel.color=Color("13232b"); panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); layer.add_child(panel)
	var center:=CenterContainer.new(); center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); panel.add_child(center)
	var column:=VBoxContainer.new(); column.custom_minimum_size.x=750; column.add_theme_constant_override("separation",20); center.add_child(column)
	var tabs:=HBoxContainer.new(); column.add_child(tabs)
	for entry in [["mossbound","Mossbound Oath"],["frostmaw","The Frostmaw Hunt"],["lodge","Hearthbound Lodge"]]:
		var tab:=Button.new(); tab.text=entry[1]; var key: String=entry[0]; tab.pressed.connect(func(): selected=key; refresh()); tabs.add_child(tab)
	var title:=Label.new(); heading=title; title.text="THE MOSSBOUND OATH"; title.add_theme_font_size_override("font_size",28); column.add_child(title)
	description=Label.new(); description.custom_minimum_size=Vector2(750,180); description.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART; column.add_child(description)
	actions=VBoxContainer.new(); column.add_child(actions)
	var exit_button:=Button.new(); exit_button.text="Return to village [ Esc ]"; exit_button.pressed.connect(close); column.add_child(exit_button)
	panel.hide()
func nearby() -> bool:
	return world.wilderness.inside and world.player.global_position.distance_to(POSITION)<3
func completed_targets() -> int:
	var count:=0
	for id in TARGETS:
		if id in state.wilderness.looted: count+=1
	return count
func eligible() -> bool: return state.hunt.accepted and state.hunt.reward=="" and completed_targets()==4
func accept() -> bool:
	if not nearby() or state.hunt.accepted: return false
	state.hunt.accepted=true; state._commit(); refresh(); return true
func claim(id: String) -> bool:
	if not nearby() or not eligible() or id not in ["mossfang_blade","mossheart_amulet"]: return false
	state.hunt.reward=id
	var uid: String=state.add_item(id,1); state.inventory[uid].favorite=true
	if "mossbound" not in state.blueprints: state.blueprints.append("mossbound")
	state.gold+=120; state._commit(); refresh(); return true
func refresh() -> void:
	for child in actions.get_children(): actions.remove_child(child); child.queue_free()
	if selected=="warden": refresh_warden(); return
	if selected=="watershed": refresh_water(); return
	if selected=="lodge": refresh_lodge(); return
	heading.text="THE MOSSBOUND OATH"
	if selected=="frostmaw":
		refresh_frost(); return
	description.text="The northern pack has driven hunters from the ridge. Beyond it, a stone colossus guards the pass. Bring proof that both threats are gone.\n\nHarvest the three wolves in the northwest clearing, then the Mossbound Colossus near the north pass. Leave the amber ring before its ground slam; below half health it slams more often. Earlier harvests count.\n\nReward: 120 gold, one Fine heirloom and both crafting patterns."
	if state.hunt.reward!="":
		description.text="Oath fulfilled. You received the "+state.items[state.hunt.reward].name+" and both Mossbound patterns. Forge the other design, then temper, enchant and socket your equipment as you wish."
	elif not state.hunt.accepted: button("Accept the hunt",accept)
	else:
		description.text+="\n\nProof recovered: %d / 4" % completed_targets()
		if eligible():
			button("Choose Mossfang Blade · 21 base damage · +2 Strength / Agility",func(): claim("mossfang_blade"))
			button("Choose Mossheart Amulet · 3 base armor · +2 Endurance / +3 Willpower",func(): claim("mossheart_amulet"))
func button(text: String, callback: Callable) -> void:
	var b:=Button.new(); b.text=text; b.custom_minimum_size.y=44; b.pressed.connect(callback); actions.add_child(b)
func open() -> void:
	lodge_subject="board"
	if not nearby(): return
	world.player.dialog_open=true; world.player.set_paused(true); refresh(); panel.show()
func close() -> void:
	if not panel.visible: return
	panel.hide(); world.player.dialog_open=false; world.player.set_paused(false)
func _process(_delta: float) -> void:
	if is_instance_valid(watch_patrol):
		watch_patrol.visible=world.wilderness.inside and state.hunt.get("watch_choice","")!=""
		if watch_patrol.visible and not world.player.paused:
			watch_clock+=_delta
			var leg: float=fmod(watch_clock,16.0)
			watch_patrol.position=Vector3(1,0,10-minf(leg,16-leg)*1.5)
			watch_patrol.rotation.y=0 if leg<8 else PI
			for guard in watch_models:
				guard.left_leg.rotation.x=sin(watch_clock*6)*.35; guard.right_leg.rotation.x=-sin(watch_clock*6)*.35
	tracker.visible=world.wilderness.inside and not world.player.paused and ((state.hunt.accepted and state.hunt.reward=="") or (state.frost_hunt.accepted and not state.frost_hunt.rewarded))
	tracker.text="MOSSBOUND OATH · %d / 4 proofs\n%s" % [completed_targets(),"Return to the market board" if eligible() else "Northwest wolves → north-pass colossus · E harvest"]

	if not (state.hunt.accepted and state.hunt.reward==""): tracker.text=""
	if state.frost_hunt.accepted and not state.frost_hunt.rewarded:
		tracker.text+=("\n" if tracker.text!="" else "")+"FROSTMAW · "+("Return to the market board" if "wild_12" in state.wilderness.looted else "Eastern bank, south of bridge · E harvest")

func accept_frost() -> bool:
	if not nearby() or state.frost_hunt.accepted: return false
	state.frost_hunt.accepted=true; state._commit(); refresh(); return true
func claim_frost() -> bool:
	if not nearby() or not state.frost_hunt.accepted or state.frost_hunt.rewarded or "wild_12" not in state.wilderness.looted: return false
	state.frost_hunt.rewarded=true
	var uid: String=state.add_item("rimefang_maul",1); state.inventory[uid].favorite=true
	if "frostmaw" not in state.blueprints: state.blueprints.append("frostmaw")
	state.gold+=180; state._commit(); refresh(); return true
func refresh_frost() -> void:
	heading.text="THE FROSTMAW HUNT"
	description.text="A huge tusked beast is tearing up the eastern hunting grounds. Cross the bridge, then head south along the eastern bank to its clearing.\n\nRimefang commits to a straight charge after pawing the ground. Sidestep, then strike while it recovers. Harvest its remains with E and return here. Earlier harvests count.\n\nReward: 180 gold, a Fine Rimefang Maul, and forge patterns for the maul and Frostmaw Cuirass."
	if state.frost_hunt.rewarded: description.text="Rimefang is felled. Your Fine Rimefang Maul is protected as a favorite. Both Frostmaw patterns are available at the forge; temper, enchant and socket the equipment as usual."
	elif not state.frost_hunt.accepted: button("Accept the Frostmaw hunt",accept_frost)
	elif "wild_12" in state.wilderness.looted: button("Claim Rimefang Maul · 26 base damage · +3 Strength / +2 Endurance",claim_frost)
	else: description.text+="\n\nProof: awaiting Rimefang's harvest."

func road_position(id: String) -> Vector3:
	var pos: Vector3=ROAD[id] if id in ROAD else WATER_SITES[id] if id in WATER_SITES else WATCH_SITES[id]
	pos.y=world.Terrain.height_at(pos.x,pos.z)
	return pos
func lodge_nearby() -> String:
	if not world.wilderness.inside: return ""
	for id in ROAD.keys()+WATER_SITES.keys()+WATCH_SITES.keys():
		if world.player.position.distance_to(road_position(id))<2.3: return id
	return ""
func open_lodge() -> void:
	var id:=lodge_nearby()
	if id=="": return
	lodge_subject=id; selected="warden" if id in WATCH_SITES else "watershed" if id in WATER_SITES else "lodge"; world.player.dialog_open=true; world.player.set_paused(true); refresh(); panel.show()
func refresh_road() -> void:
	if is_instance_valid(watch_patrol): refresh_watch()
	if is_instance_valid(clean_sluice): clean_sluice.visible=state.hunt.get("water_choice","")!=""
	for id in road_glows: road_glows[id].visible=id in state.hunt.get("lodge_repairs",[])
func lodge_objective() -> String:
	var p: Dictionary=state.hunt
	if p.get("lodge_joined",false): return "Outrider · The Old Watch Road complete. You swore to shelter travelers and keep the road open."
	if not state.adventure.rewarded: return "Restore Oldwatch's forge ember, then read the Hearthbound Lodge notice at the Hunters' Board."
	if not p.get("lodge_started",false): return "Read the Hearthbound Lodge tab at Frostmere's Hunters' Board."
	if p.get("lodge_repairs",[]).size()<3: return "Repair village, eastern crossing and ridge markers · %d / 3. Each needs 2 wood and 1 iron ingot. Clear both eastern ridge boars for the last marker." % p.get("lodge_repairs",[]).size()
	return "Return to the Hunters' Board and take the Outrider oath if you wish to join."
func lodge_act(id: String) -> bool:
	if not panel.visible or selected!="lodge": return false
	if (lodge_subject=="board" and not nearby()) or (lodge_subject!="board" and lodge_nearby()!=lodge_subject): return false
	var p: Dictionary=state.hunt
	if id=="start" and lodge_subject=="board" and state.adventure.rewarded and not p.get("lodge_started",false):
		p.lodge_started=true; world.adventure.grant_materials({"wood":6,"iron_ingot":3})
	elif id=="repair" and lodge_subject in ROAD and p.get("lodge_started",false) and lodge_subject not in p.get("lodge_repairs",[]):
		if lodge_subject=="ridge" and ("wild_9" not in state.wilderness.defeated or "wild_10" not in state.wilderness.defeated): return false
		if not state.can_pay({"wood":2,"iron_ingot":1}): description.text="Each marker needs 2 wood and 1 iron ingot. No supplies were spent."; return false
		state.materials.wood-=2; state.materials.iron_ingot-=1
		if not p.has("lodge_repairs"): p.lodge_repairs=[]
		p.lodge_repairs.append(lodge_subject)
	elif id=="oath" and lodge_subject=="board" and p.get("lodge_repairs",[]).size()==3 and not p.get("lodge_joined",false):
		p.lodge_joined=true; state.gold+=120
		var uid: String=state.add_item("wardkeeper_amulet",2,"vigor"); state.inventory[uid].favorite=true; state.inventory[uid].custom_name="Outrider's Hearth"
	else: return false
	world.hud.world_map.selected_quest="hearthbound_1"; state._commit(); refresh(); return true
func refresh_lodge() -> void:
	heading.text="THE OLD WATCH ROAD"
	description.text=lodge_objective()
	var p: Dictionary=state.hunt
	if lodge_subject=="board":
		if p.get("lodge_joined",false):
			button("Investigate A Winter Without Wolves",func(): selected="watershed"; refresh())
			if p.get("water_choice","")!="": button("Decide Who Guards the Pass",func(): selected="warden"; refresh())
			return
		if not state.adventure.rewarded: return
		if not p.get("lodge_started",false):
			description.text="HEARTHBOUND LODGE NOTICE\n\nThe forge burns again. Now help people reach it. Repair the three old road markers: village edge, east bank beyond the crossing, and eastern ridge. Two bristlebacks have claimed the last stretch. They accept neither tolls nor constructive criticism.\n\nThe lodge supplies 6 wood and 3 iron ingots. Each marker costs 2 wood and 1 iron ingot."
			button("Accept the road repairs · receive supplies",func(): lodge_act("start"))
		elif p.get("lodge_repairs",[]).size()==3:
			description.text="The road markers shine again. The Hearthbound oath asks you to shelter travelers, answer distress, and keep the road open regardless of clan.\n\nJoin as Outrider for 120 gold and a Superior Vigor-enchanted Wardkeeper's Amulet. You may leave without joining; the repairs remain."
			button("Take the Outrider oath",func(): lodge_act("oath"))
	elif p.get("lodge_started",false) and lodge_subject not in p.get("lodge_repairs",[]):
		if lodge_subject=="ridge" and ("wild_9" not in state.wilderness.defeated or "wild_10" not in state.wilderness.defeated): description.text+="\n\nBoth ridge bristlebacks must be defeated. Earlier defeats count."
		else: button("Repair marker · 2 wood, 1 iron ingot",func(): lodge_act("repair"))

func water_objective() -> String:
	var p: Dictionary=state.hunt
	if p.get("water_choice","")!="": return "Waykeeper · A Winter Without Wolves complete. The filter is restored; "+("Senna's findings expose patron Orven's poison dumping." if p.water_choice=="expose" else "Orven's role is concealed from the village despite Senna's findings.")
	if not p.get("lodge_joined",false): return "Become an Outrider before investigating the empty drinking den."
	return ["Ask the Hearthbound Lodge about the missing drinking-den pack.","Inspect the abandoned drinking den northwest of Frostmere.","Trace the stained runoff on the river's west bank, north of town.","Take the residue to grove keeper Senna southwest of the village.","Repair the upstream filter sluice · 2 wood and 2 herbs. Choose whether to expose patron Orven."][int(p.get("water_stage",0))]
func water_act(id: String) -> bool:
	if not panel.visible or selected!="watershed": return false
	if (lodge_subject=="board" and not nearby()) or (lodge_subject!="board" and lodge_nearby()!=lodge_subject): return false
	var p: Dictionary=state.hunt
	var stage: int=int(p.get("water_stage",0))
	if id=="start" and lodge_subject=="board" and p.get("lodge_joined",false) and stage==0:
		p.water_stage=1
	elif id=="trace" and ((lodge_subject=="den" and stage==1) or (lodge_subject=="runoff" and stage==2) or (lodge_subject=="grovekeeper" and stage==3)):
		p.water_stage=stage+1
	elif id in ["expose","patron"] and lodge_subject=="sluice" and stage==4 and p.get("water_choice","")=="":
		if not state.can_pay({"wood":2,"herb":2}): description.text="The filter needs 2 wood and 2 herbs. No supplies were spent."; return false
		state.materials.wood-=2; state.materials.herb-=2; p.water_choice=id; state.gold+=160 if id=="expose" else 220
		var uid: String=state.add_item("leather_chest" if id=="expose" else "steel_bow",3,"vigor" if id=="expose" else "fleet")
		state.inventory[uid].favorite=true; state.inventory[uid].custom_name="Waykeeper's Renewal" if id=="expose" else "Patron's Silence"
	else: return false
	world.hud.world_map.selected_quest="hearthbound_2"; state._commit(); refresh(); return true
func refresh_water() -> void:
	heading.text="A WINTER WITHOUT WOLVES"
	description.text=water_objective()
	var p: Dictionary=state.hunt
	var stage: int=int(p.get("water_stage",0))
	if not p.get("lodge_joined",false) or p.get("water_choice","")!="": return
	if lodge_subject=="board" and stage==0:
		description.text="The pack that drank at the old den has disappeared. Other wolves still hunt the valley, but this hollow is silent. The village patron calls it a blessing. The Lodge asks you to find the reason before anyone celebrates."
		button("Investigate the silent drinking den",func(): water_act("start"))
	elif lodge_subject=="den" and stage==1:
		description.text="The den is abandoned, not bloodied. Tracks leave the drinking hollow together. No carcasses, no drag marks. A bitter stain follows the water toward the northern runoff channel."
		button("Follow the stained water upstream",func(): water_act("trace"))
	elif lodge_subject=="runoff" and stage==2:
		description.text="A split cask bears patron Orven's mark. The residue smells of tanning salts and bitterroot. Someone emptied workshop waste into the feeder channel. Grove keeper Senna can identify it."
		button("Collect residue and copy the cask mark",func(): water_act("trace"))
	elif lodge_subject=="grovekeeper" and stage==3:
		description.text="Senna: Orven calls me a meddler. Apparently water becomes private property the moment you poison it.\n\nThe salts drove the drinking pack away. Fit the upstream sluice with wood and a bitterroot filter: 2 wood, 2 herbs. That stops the local seep. Then decide whether the village hears whose cask it was."
		button("Record Senna's treatment and findings",func(): water_act("trace"))
	elif lodge_subject=="sluice" and stage==4:
		description.text="Restore the filter with 2 wood and 2 herbs. Both choices earn Waykeeper rank and stop this local seep.\n\nExpose Orven: publish Senna's findings; 160 gold and an Exquisite Vigor leather cuirass.\nProtect the patron: suppress his responsibility; 220 gold and an Exquisite Fleet steel bow. The village keeps believing the wolves simply left.\n\nThe choice is permanent."
		button("Repair and expose the patron",func(): water_act("expose"))
		button("Repair but conceal the patron's responsibility",func(): water_act("patron"))

func refresh_watch() -> void:
	var policy: String=state.hunt.get("watch_choice","")
	var appearance: String=policy+":"+str(state.mountain.clan)
	if appearance==watch_policy: return
	watch_policy=appearance
	watch_patrol.visible=policy!=""
	if policy=="": return
	for guard in watch_models:
		var model=preload("res://scripts/character_state.gd").new()
		var armor: String="fur" if policy=="neutral" else "steel" if state.mountain.clan=="stoneguard" else "cloth"
		for slot in ["head","chest","hands","legs","feet"]: model.equip(model.add_item(armor+"_"+slot),slot)
		guard.build(model)
func warden_objective() -> String:
	var p: Dictionary=state.hunt
	if p.get("watch_choice","")!="": return "Warden · Who Guards the Pass? complete. "+("A neutral Lodge watches the village road." if p.watch_choice=="neutral" else "Your sworn clan outfits the village road watch.")+(" Watch supplies collected." if p.get("watch_supplies",false) else " Collect the one-time support cache south of the village marker.")
	if p.get("water_choice","")=="": return "Become Waykeeper before deciding the road watch's command."
	if not p.get("watch_started",false): return "Accept the north-pass commission at the Hearthbound board."
	if "wild_11" not in state.wilderness.looted: return "Defeat and harvest the Mossbound Colossus guarding the north pass. Earlier harvests count."
	return "Return to the board: keep a neutral Lodge or place the watch under your sworn clan."
func warden_act(id: String) -> bool:
	if not panel.visible or selected!="warden": return false
	if (lodge_subject=="board" and not nearby()) or (lodge_subject!="board" and lodge_nearby()!=lodge_subject): return false
	var p: Dictionary=state.hunt
	if id=="start" and lodge_subject=="board" and p.get("water_choice","")!="" and not p.get("watch_started",false): p.watch_started=true
	elif id in ["neutral","clan"] and lodge_subject=="board" and p.get("watch_started",false) and "wild_11" in state.wilderness.looted and p.get("watch_choice","")=="":
		if id=="clan" and state.mountain.clan=="": return false
		p.watch_choice=id; state.gold+=220
		var uid: String=state.add_item("wardkeeper_amulet" if id=="neutral" else "steel_bow",4,"vigor" if id=="neutral" else "fleet"); state.inventory[uid].favorite=true; state.inventory[uid].custom_name="Warden's Open Hearth" if id=="neutral" else "Warden's Sworn Watch"
	elif id=="support" and lodge_subject=="watch_cache" and p.get("watch_choice","")!="" and not p.get("watch_supplies",false):
		p.watch_supplies=true
		if p.watch_choice=="neutral": state.consumables.healing_draught=int(state.consumables.get("healing_draught",0))+3; world.adventure.grant_materials({"herb":8,"water":6})
		else: world.adventure.grant_materials({"steel_ingot":8,"leather":6})
	else: return false
	world.hud.world_map.selected_quest="hearthbound_3"; state._commit(); refresh(); return true
func refresh_warden() -> void:
	heading.text="WHO GUARDS THE PASS?"; description.text=warden_objective()
	var p: Dictionary=state.hunt
	if lodge_subject=="watch_cache":
		if p.get("watch_choice","")!="" and not p.get("watch_supplies",false): button("Collect road watch support · one time",func(): warden_act("support"))
		elif p.get("watch_supplies",false): description.text="The watch's support cache has been collected. The road patrol remains on duty."
		return
	if lodge_subject!="board" or p.get("water_choice","")=="" or p.get("watch_choice","")!="": return
	if not p.get("watch_started",false):
		description.text="The markers are lit and the water runs clean. A colossus still owns the north pass. It has declined every invitation to a planning meeting. Clear it and bring a harvested proof before deciding who commands the restored watch."
		button("Accept the north-pass commission",func(): warden_act("start"))
	elif "wild_11" in state.wilderness.looted:
		description.text="Both permanent choices grant Warden rank and 220 gold.\n\nNeutral Lodge: fur-clad road watch, a Masterwork Vigor amulet, and a one-time cache of 3 healing draughts, 8 herbs and 6 water.\n\nSworn clan: watch wears your clan's armor, a Masterwork Fleet steel bow, and a one-time cache of 8 steel ingots and 6 leather. Requires an existing clan oath.\n\nThe watch patrols the village road; it does not fight or escort you. Existing faction standings remain intact."
		button("Keep the Lodge neutral · open hearth",func(): warden_act("neutral"))
		if state.mountain.clan!="": button("Place the watch under "+state.mountain.clan.capitalize(),func(): warden_act("clan"))
