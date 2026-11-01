extends Node3D
const State=preload("res://scripts/character_state.gd")
const Visual=preload("res://scripts/character_visual.gd")
const Enemy=preload("res://scripts/enemy.gd")
const ORIGIN=Vector3(2480,0,0)
const TRAIL=Vector3(0,0,34)
const REQUIRED=["returning_light"]
const NODES={"return":Vector3(0,0,36),"keeper":Vector3(-12,0,23),"forge":Vector3(12,0,23),"enchant":Vector3(18,0,23),"supplies":Vector3(-7,0,28),"ward":Vector3(-12,0,3),"ballista":Vector3(12,0,3),"orders":Vector3(0,0,-43)}
const NAMES={"return":"Supply road · Frostmere","keeper":"Captain Halla","forge":"Garrison forge","enchant":"Garrison rune table","supplies":"Garrison repair stores","ward":"Broken watchstone ward","ballista":"Disabled gate ballista","orders":"Invader's command satchel"}
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
func _ready() -> void:
	state=world.player.character; _build(); _ui(); state.changed.connect(_refresh); _refresh()
func box(p: Vector3,size: Vector3,key: String,solid: bool=false,angle: float=0) -> void:
	world.blocks.add(key,ORIGIN+p,size,angle)
	if solid: world._solid(ORIGIN+p,size)
func _build() -> void:
	var b: RefCounted=world.blocks
	for entry in [["winter_snow","c8d6de"],["winter_glow","85cfe1"]]:
		var mat: StandardMaterial3D=b.materials["window" if entry[0]=="winter_glow" else "stone"].duplicate(); mat.albedo_color=Color(entry[1]); b.materials[entry[0]]=mat
	box(Vector3(0,-.4,-4),Vector3(64,.8,88),"winter_snow",true)
	for side in [-1,1]:
		box(Vector3(side*31,2,-4),Vector3(2,4,88),"stone_dark",true)
		for z in range(-46,40,3):
			box(Vector3(side*31,4.3,z),Vector3(2.3,.8,1.4),"stone")
			box(Vector3(side*31,4.8,z),Vector3(2.4,.2,1.5),"winter_snow")
		preload("res://scripts/refined_ridges.gd").build(b,ORIGIN+Vector3(side*57,0,-20),43,98,25)
		for z in [-38,-20,0,20,38]:
			for tier in range(4): box(Vector3(side*38,2+tier*1.2,z),Vector3(5-tier,1.2,5-tier),"pine")
	# A snow-covered ridgeline closes the northern view beyond the fortified road.
	for peak in [[-32,-83,32],[0,-98,46],[34,-85,37]]:
		preload("res://scripts/refined_ridges.gd").build(b,ORIGIN+Vector3(peak[0],0,peak[1]),peak[2],peak[2]*.8,peak[2]*1.2)
	for side in [-1,1]:
		box(Vector3(side*20,2,-46),Vector3(22,4,2),"stone_dark",true)
		box(Vector3(side*7,3,-46),Vector3(3,6,4),"stone_dark",true)
		box(Vector3(side*7,6.1,-46),Vector3(3.3,.3,4.3),"winter_snow")
		for z in [-8,-46]:
			for row in range(8):
				for col in range(17):
					box(Vector3(side*(13+col),.25+row*.5,z+1.55),Vector3(.92,.43,.12),"stone" if (col+row)%4 else "stone_dark")
		# Garrison pennants, supply stacks and weapon racks stay outside the combat lane.
		box(Vector3(side*11,3,-7),Vector3(.16,6,.16),"timber")
		for row in range(8): box(Vector3(side*11,5-row*.23,-6.8),Vector3(1.3-row*.07,.22,.08),"winter_glow")
		for i in range(3):
			box(Vector3(side*(23+i*1.3),.45,-23),Vector3(1.1,.9,1.2),"wood",true)
			box(Vector3(side*(23+i*1.3),.96,-23),Vector3(1.2,.12,1.3),"winter_snow")
		for x in [23,26]: box(Vector3(side*x,1.1,15),Vector3(.18,2.2,.25),"timber")
		box(Vector3(side*24.5,1.4,15),Vector3(3.2,.18,.25),"wood")
		for i in range(5): box(Vector3(side*(23.3+i*.5),1.3,14.8),Vector3(.1,1.6,.1),"iron")
	box(Vector3(0,6,-46),Vector3(12,1.5,3),"stone_dark")
	box(Vector3(0,6.85,-46),Vector3(12.3,.25,3.3),"winter_snow")
	# Two low gatehouses flank a wide, unobstructed combat lane.
	for side in [-1,1]:
		box(Vector3(side*21,2,-8),Vector3(18,4,3),"stone_dark",true)
		for x in range(13,30,2): box(Vector3(side*x,4.4,-8),Vector3(1,.8,3.2),"winter_snow")
		world._house(ORIGIN+Vector3(side*19,0,27),10,12,3.8,false,"winter_hostel" if side<0 else "winter_store")
	for z in range(-43,39):
		for x in range(-4,5): box(Vector3(x,.02,z),Vector3(.94,.08,.94),"stone")
	for id: String in NODES:
		var p: Vector3=NODES[id]; _sign(ORIGIN+p+Vector3.UP*2,NAMES[id])
		if id=="keeper":
			var npc:=Visual.new(); npc.position=ORIGIN+p; npc.rotation.y=PI; add_child(npc)
			var model:=State.new()
			for slot in ["head","chest","hands","legs","feet"]: model.equip(model.add_item("steel_"+slot),slot)
			npc.build(model)
		elif id!="return": box(p+Vector3.UP*.5,Vector3(1.7,1,1.2),"wood" if id in ["supplies","ballista"] else "stone_dark")
		if id=="forge":
			box(p+Vector3.UP*1.1,Vector3(1.1,.22,.5),"iron")
			box(p+Vector3(.65,1.1,0),Vector3(.4,.12,.28),"iron")
		if id=="enchant":
			box(p+Vector3.UP*1.06,Vector3(1.5,.12,1),"gold")
			box(p+Vector3.UP*1.2,Vector3(.7,.16,.55),"winter_glow")
		if id in ["ward","ballista"]:
			lights[id]=b.piece(self,"coal",ORIGIN+p+Vector3.UP*1.5,Vector3(.45,.8,.45))
		if id=="ballista":
			box(p+Vector3.UP*1.15,Vector3(3,.22,.3),"timber")
			box(p+Vector3(0,1.15,-.8),Vector3(.15,.15,2),"iron")
	for p in [Vector3(-5,0,32),Vector3(5,0,15),Vector3(-8,0,-9),Vector3(8,0,-9)]: world._lantern(ORIGIN+p,false)
	world.block_count+=b.finish(world); _sign(TRAIL+Vector3.UP*2,"Winter Siege · Northwatch road")
	var positions=[Vector3(-7,0,-16),Vector3(7,0,-19),Vector3(0,0,-23),Vector3(-8,0,-30),Vector3(8,0,-32),Vector3(0,0,-36)]
	for i in range(6):
		var enemy:=Enemy.new(); enemy.adventure=self; enemy.progress=state.winter; enemy.enemy_id="winter_"+str(i); enemy.role="boss" if i==5 else "archer" if i in [1,4] else "guard"
		enemy.title="The Iron Marshal" if i==5 else "Furnace Vanguard" if i>=3 else "Ashbound Scout"
		enemy.health_override=440 if i==5 else 155 if i>=3 else 120; enemy.position=ORIGIN+positions[i]+Vector3.UP*.15
		add_child(enemy); enemies.append(enemy)
func ready_for_expedition() -> bool:
	for id in REQUIRED:
		if id not in state.story_completed: return false
	return true
func _sign(p: Vector3,label: String) -> void:
	var sign:=Label3D.new(); sign.position=p; sign.text=label; sign.font_size=22; sign.pixel_size=.003; sign.billboard=BaseMaterial3D.BILLBOARD_ENABLED; sign.visibility_range_begin=4.5; sign.visibility_range_end=18; add_child(sign)
func _ui() -> void:
	var layer:=CanvasLayer.new(); layer.layer=7; add_child(layer)
	preview_label=Label.new(); preview_label.position=Vector2(32,76); preview_label.text="WINTER SIEGE PREVIEW · progress is not saved"; layer.add_child(preview_label)
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
	for chapter in [world.seal,world.threshold,world.convergence,world.choir,world.lens,world.roots,world.shore,world.archive_chapter,world.mountain,world.realms,world.adventure]:
		if chapter.inside: chapter.leave()
	inside=true; world.player.position=ORIGIN+Vector3(0,.2,36); world.player.velocity=Vector3.ZERO; world.player.rotation=Vector3.ZERO
	for child in world.get_children():
		if child is WorldEnvironment:
			environment_backup=child.environment
			var env: Environment=environment_backup.duplicate(true); env.background_mode=Environment.BG_COLOR; env.background_color=Color("697d91"); env.fog_light_color=Color("a1b8cf"); env.fog_density=.004; env.ambient_light_color=Color("cadbe9"); preload("res://scripts/regional_sky.gd").apply(env,"winter"); child.environment=env
	world.hud.world_map.selected_quest="winter_siege"; world.hud.world_map.set_view(true); world.audio.sfx("portal")
	world.hud.announce("Northwatch","The restored watchstones have drawn an invasion. Captain Halla needs you."); return true
func leave() -> void:
	if not inside: return
	inside=false; world.adventure.clear_projectiles(); world.player.position=TRAIL+Vector3(0,.2,2.5); world.player.velocity=Vector3.ZERO
	for child in world.get_children():
		if child is WorldEnvironment and environment_backup!=null: child.environment=environment_backup
	for enemy in enemies:
		if not enemy.dead: enemy.position=enemy.home; enemy.health=enemy.maximum_health; enemy.velocity=Vector3.ZERO; enemy.windup=0; enemy._update_label()
	_refresh()
func nearest() -> Dictionary:
	if not inside:
		if world.player.position.distance_to(TRAIL)<2.5: return {"kind":"winter","id":"trail","text":"[ E ] Travel to Northwatch"}
		return {}
	for enemy in enemies:
		if enemy.dead and enemy.enemy_id not in state.winter.looted and world.player.position.distance_to(enemy.position)<2.5: return {"kind":"winter","id":enemy.enemy_id,"text":"[ E ] Search the invader"}
	for id: String in NODES:
		if world.player.position.distance_to(ORIGIN+NODES[id])<2.3: return {"kind":"winter","id":id,"text":"[ E ] "+NAMES[id]}
	return {}
func station_nearby() -> String:
	for id in ["forge","enchant"]:
		if inside and world.player.position.distance_to(ORIGIN+NODES[id])<2.3: return id
	return ""
func interact(id: String) -> void:
	if world.player.paused or nearest().get("id","")!=id: return
	if id=="trail":
		if not enter(): world.hud.announce("The expedition road","Return from Aeralis before answering the northern distress call.")
	elif id=="return": leave()
	elif id in ["forge","enchant"]: world.hud.workshop.open(id)
	elif id.begins_with("winter_"): loot(id)
	else: open_dialog(id)
func first_wave_done() -> bool:
	for id in ["winter_0","winter_1","winter_2"]:
		if id not in state.winter.defeated: return false
	return true
func _refresh() -> void:
	for id: String in lights: lights[id].material_override=world.blocks.materials["winter_glow" if id in state.winter.repairs else "coal"]
	for enemy in enemies:
		if enemy.enemy_id=="winter_5" and state.winter.assault and not enemy.dead:
			enemy.health=minf(enemy.health,enemy.maximum_health-100); enemy._update_label()
		var active:=can_damage_enemy(enemy.enemy_id)
		enemy.visible=active or enemy.dead
		enemy.collision_layer=4 if active and not enemy.dead else 0
		enemy._update_label()
func open_dialog(id: String) -> void:
	subject=id; world.player.dialog_open=true; world.player.set_paused(true); dialog.show()
	for child in options.get_children(): options.remove_child(child); child.queue_free()
	title.text=NAMES[id].to_upper()
	var p: Dictionary=state.winter
	if id=="keeper":
		description.text="HALLA · NORTHWATCH\n\nYour work in Aeralis restored our watchstones. Something beneath Ember Caldera heard them. This fort guards the caldera's northern approaches; if it falls, the road to the holds lies open.\n\nRepel the scouts, then restore the ward and gate ballista using our reserved supplies. Ring the muster through me when you are ready for the main assault."
		if not p.accepted: _button("Stand with Northwatch · repel the scouts","accept")
		elif p.repairs.size()==2 and not p.assault: _button("Sound the muster · begin the main assault","assault")
		elif p.orders and not p.rewarded: _button("Deliver the orders · claim the garrison reward","reward")
		if p.rewarded: description.text="HALLA · A HOLD THAT ENDURED\n\nThese orders name a sealed industrial passage beneath the caldera. The invasion was only its surface force. Take the Northwatch patterns and prepare your equipment. Take the caldera service lift south of Frostmere. Wardwright Tovan will help you investigate The Broken Seal."
		description.text+="\n\n"+objective()
	elif id=="supplies":
		description.text="Reserved repair stock: 8 steel ingots, 6 crystals and 4 rune dust. The ward needs 2 crystals and 2 rune dust; the ballista needs 3 steel. Keep the remainder for your equipment. Separate combat reserves: 60 arrows, 120 Station Rounds and 2 Magicka Draughts."
		if p.accepted and not p.supplies: _button("Collect the reserved repair stock","supplies")
		elif p.supplies: description.text+="\n\nAlready collected."
	elif id in ["ward","ballista"]:
		description.text="The watchstone ward restores your health and magicka before the assault." if id=="ward" else "The repaired ballista weakens the Iron Marshal before the assault: 100 damage."
		if not first_wave_done(): description.text+="\n\nClear the scouting wave before attempting repairs."
		elif id not in p.repairs:
			_button("Repair · 2 crystals + 2 rune dust" if id=="ward" else "Repair · 3 steel ingots","repair")
			if spare_repair_available(id):
				description.text+="\n\nYour reserved stock is spent. Halla can release a fitted garrison spare for this defense. It installs directly and cannot be kept or sold."
				_button("Install the garrison’s fitted spare","spare_repair")
		else: description.text+="\n\nDefense restored."
	elif id=="orders":
		description.text="The marshal's sealed orders identify the source of the invasion. Clear the entire assault before recovering them."
		if p.defeated.size()==6 and not p.orders: _button("Recover the invasion orders","orders")
		elif p.orders: description.text+="\n\nOrders recovered. Report to Captain Halla."
func act(id: String) -> bool:
	if not dialog.visible or not inside or not NODES.has(subject) or world.player.position.distance_to(ORIGIN+NODES[subject])>=2.3: return false
	var p: Dictionary=state.winter
	var success:=false
	if id=="accept" and subject=="keeper" and not p.accepted: p.accepted=true; success=true
	elif id=="supplies" and subject=="supplies" and p.accepted and not p.supplies:
		p.supplies=true; world.adventure.grant_materials({"steel_ingot":8,"crystal":6,"rune_dust":4 ,"arrow":60,"station_round":120}); state.consumables.magicka_draught=int(state.consumables.get("magicka_draught",0))+2; success=true
	elif id=="spare_repair" and spare_repair_available(subject):
		p.repairs.append(subject); success=true; world.audio.sfx("forge")
	elif id=="repair" and subject in ["ward","ballista"] and first_wave_done() and subject not in p.repairs:
		var cost: Dictionary={"crystal":2,"rune_dust":2} if subject=="ward" else {"steel_ingot":3}
		for material: String in cost:
			if int(state.materials.get(material,0))<cost[material]: description.text="Insufficient repair materials. Reopen this defense’s controls to request a fitted spare." if p.supplies else "Insufficient repair materials. Collect the reserved garrison stores first."; world.audio.sfx("error"); return false
		for material: String in cost: state.materials[material]-=cost[material]
		p.repairs.append(subject); success=true; world.audio.sfx("forge")
	elif id=="assault" and subject=="keeper" and p.repairs.size()==2 and not p.assault:
		p.assault=true; success=true; state._commit()
		world.player.health=world.player.derived.health; world.player.magicka=world.player.derived.magicka
		world.audio.sfx("gun")
	elif id=="orders" and subject=="orders" and p.defeated.size()==6 and not p.orders: p.orders=true; success=true
	elif id=="reward" and subject=="keeper" and p.orders and not p.rewarded:
		p.rewarded=true
		if "winter_siege" not in state.story_completed: state.story_completed.append("winter_siege")
		if "northwatch" not in state.blueprints: state.blueprints.append("northwatch")
		state.gold+=240
		for gear in ["northwatch_head","northwatch_greatsword"]:
			var uid: String=state.add_item(gear,2,"vigor" if gear=="northwatch_head" else "fleet"); state.inventory[uid].favorite=true
		world.adventure.grant_materials({"steel_ingot":8,"crystal":6,"rune_dust":4}); success=true
	if success: state._commit(); open_dialog(subject)
	return success
func can_damage_enemy(id: String) -> bool:
	return state.winter.accepted if id in ["winter_0","winter_1","winter_2"] else state.winter.assault
func barrier_message() -> String:
	return "Answer Captain Halla's muster to begin this wave"
func mark_defeated(id: String) -> void:
	if can_damage_enemy(id) and id not in state.winter.defeated: state.winter.defeated.append(id); state._commit()
func loot(id: String) -> bool:
	if not inside or id not in state.winter.defeated or id in state.winter.looted: return false
	state.winter.looted.append(id); state.gold+=30; world.adventure.grant_materials({"steel_ingot":2,"crystal":1}); state._commit()
	world.hud.announce("Invader searched","Steel and crystal recovered for equipment upgrades."); return true
func objective() -> String:
	var p: Dictionary=state.winter
	if p.rewarded: return "Northwatch held · Take the caldera service lift to investigate The Broken Seal"
	if not p.accepted: return "Answer Captain Halla's call at Northwatch"
	if not first_wave_done(): return "Repel the scouting wave · %d / 3" % p.defeated.size()
	if p.repairs.size()!=2: return "Restore the watchstone ward and gate ballista · %d / 2" % p.repairs.size()
	if not p.assault: return "Return to Halla and sound the muster when ready"
	if p.defeated.size()!=6: return "Defeat the main assault and Iron Marshal · %d / 3" % (p.defeated.size()-3)
	if not p.orders: return "Recover the command satchel in the northern courtyard"
	return "Deliver the invasion orders to Captain Halla"
func close_dialog() -> void:
	dialog.hide(); world.player.dialog_open=false
func check_fall() -> void:
	var p: Vector3=world.player.position-ORIGIN
	if p.y< -1.5 or absf(p.x)>34 or p.z< -48 or p.z>40: world.player.position=ORIGIN+Vector3(0,.2,36); world.player.velocity=Vector3.ZERO
func fire(origin: Vector3,direction: Vector3,damage: float,hostile: bool,source: CollisionObject3D,magic: bool) -> void:
	world.adventure.fire(origin,direction,damage,hostile,source,magic)
func line_clear(from: Vector3,to: Vector3,source: CollisionObject3D,target_body: CollisionObject3D=null) -> bool:
	return world.adventure.line_clear(from,to,source,target_body)
func _process(delta: float) -> void:
	preview_label.visible="--winter-preview" in OS.get_cmdline_user_args() and not world.player.paused
	if feedback_time>0: world.adventure.feedback=feedback; world.adventure.feedback_time=feedback_time; feedback_time=maxf(0,feedback_time-delta)

func spare_repair_available(site: String) -> bool:
	if site not in ["ward","ballista"] or not state.winter.supplies or not first_wave_done() or site in state.winter.repairs: return false
	var cost: Dictionary={"crystal":2,"rune_dust":2} if site=="ward" else {"steel_ingot":3}
	return not state.can_pay(cost)
