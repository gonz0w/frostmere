extends Node3D
const State=preload("res://scripts/character_state.gd")
const Visual=preload("res://scripts/character_visual.gd")
const Enemy=preload("res://scripts/enemy.gd")
const ORIGIN=Vector3(1200,0,0)
const TRAIL=Vector3(48,0,18)
const NODES={"return":Vector3(0,0,42),"keeper":Vector3(-16,.25,24),"forge":Vector3(12,0,20),"enchant":Vector3(18,0,20),"west_cache":Vector3(-29,0,-23),"east_cache":Vector3(29,0,-40),"dawn":Vector3(-14,0,-39),"dusk":Vector3(14,0,-39),"crown":Vector3(0,0,-27),"lens":Vector3(0,0,-45),"chart":Vector3(0,0,-65)}
const NAMES={"return":"Expedition road · Frostmere","keeper":"Astronomer Veyra","forge":"Expedition forge","enchant":"Solar rune table","west_cache":"Excavation glass cache","east_cache":"Buried survey cache","dawn":"Dawn mirror","dusk":"Dusk mirror","crown":"Crown mirror","lens":"The Sunken Lens","chart":"The recovered star chart"}
const SOLUTIONS={"dawn":1,"dusk":3,"crown":0}
const DIRECTIONS=["North","East","South","West"]
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
var gate: StaticBody3D
var mirrors: Dictionary={}
var beams: Dictionary={}
var prism: Node3D
var chart_mesh: MeshInstance3D
var debt_props: Dictionary={}
var environment_backup: Environment
func _ready() -> void:
	state=world.player.character; _build(); _ui(); state.changed.connect(_refresh); _refresh()
func box(p: Vector3,size: Vector3,key: String,solid: bool=false,angle: float=0) -> void:
	world.blocks.add(key,ORIGIN+p,size,angle)
	if solid: world._solid(ORIGIN+p,size)
func _build() -> void:
	var b: RefCounted=world.blocks
	for entry in [["lens_sand","c49c68"],["lens_stone","9d805f"],["lens_glow","ffe0a0"]]:
		var mat: StandardMaterial3D=b.materials["window" if entry[0]=="lens_glow" else "stone"].duplicate(); mat.albedo_color=Color(entry[1]); b.materials[entry[0]]=mat
	world._solid(ORIGIN+Vector3(0,-.6,-20),Vector3(104,1,148))
	for x in range(-51,52):
		for z in range(-93,54): box(Vector3(x,-.17,z),Vector3(1.01,.14,1.01),"path" if abs(x)<2 else "lens_sand")
	# Stepped dune ridges and wind-carved mesas surround the open expedition route.
	for side in [-1,1]:
		for i in range(15):
			for tier in range(4+i%6): box(Vector3(side*(44+tier*.7),tier*.55,-87+i*10),Vector3(15-tier,.53,13),"lens_sand")
		for i in range(5):
			for tier in range(10+i%4): box(Vector3(side*(58+i%2*5),tier*.7,-82+i*29),Vector3(12-tier*.6,.66,9-tier*.3),"lens_stone")
	world._house(ORIGIN+Vector3(-16,0,20),10,12,3.8,false,"lens_lodge")
	# Shade canopy, work benches and a library of field notes.
	for x in [8,23]:
		for z in [15,24]: box(Vector3(x,1.8,z),Vector3(.18,3.6,.18),"timber",true)
	for strip in range(15): box(Vector3(8.5+strip,3.8-sin(strip*.21)*.55,19.5),Vector3(.97,.12,10),"cloth" if strip%3 else "fur")
	for x in [10,20]:
		box(Vector3(x,.65,28),Vector3(3,.16,1.2),"wood")
		for book in range(8): box(Vector3(x-1+book*.28,.83,28),Vector3(.22,.17,.5),"cloth" if book%2 else "leather")
	# Circular masonry rings and broken dome ribs distinguish the observatory from a fort.
	for segment in range(72):
		var angle: float=TAU*segment/72
		var x: float=sin(angle)*22; var z: float=-45+cos(angle)*22
		if absf(x)<4 and z> -30: continue
		for row in range(13): box(Vector3(x,.24+row*.48,z),Vector3(1.9,.44,1.9),"lens_stone" if row%4 else "stone",true)
		if segment%9==0:
			for tier in range(18): box(Vector3(x*(1-tier*.025),6.5+tier*.35,-45+(z+45)*(1-tier*.025)),Vector3(.65,.4,.65),"gold")
	for x in [-18,18]:
		for row in range(11): box(Vector3(x,.25+row*.48,-54),Vector3(2,.44,2),"stone")
	for side in [-1,1]:
		box(Vector3(side*10.2,2.6,-55),Vector3(14.4,5.2,.7),"lens_stone",true)
		for row in range(10):
			for col in range(12): box(Vector3(side*(3.6+col*1.12),.25+row*.51,-54.58),Vector3(1.06,.46,.12),"stone" if (row+col)%5 else "gold")
		for step in range(4): box(Vector3(side*(3-step*.25),4.3+step*.25,-55),Vector3(.6,.3,1),"gold")
	gate=StaticBody3D.new(); gate.position=ORIGIN+Vector3(0,2.5,-55); add_child(gate)
	var collision:=CollisionShape3D.new(); var shape:=BoxShape3D.new(); shape.size=Vector3(5.8,5,.7); collision.shape=shape; gate.add_child(collision)
	b.piece(gate,"lens_glow",Vector3.ZERO,shape.size)
	for id: String in NODES:
		var p: Vector3=NODES[id]; _sign(ORIGIN+p+Vector3.UP*2,NAMES[id])
		if id=="keeper":
			var npc:=Visual.new(); npc.position=ORIGIN+p; npc.rotation.y=PI; add_child(npc)
			var model:=State.new()
			for slot in ["head","chest","hands","legs","feet"]: model.equip(model.add_item("cloth_"+slot),slot)
			npc.build(model)
		elif id!="return":
			box(p+Vector3.UP*.5,Vector3(1.4,1,1),"wood" if "cache" in id else "lens_stone")
			box(p+Vector3.UP*1.05,Vector3(1.5,.12,1.1),"gold")
		if SOLUTIONS.has(id):
			var mirror:=Node3D.new(); mirror.position=ORIGIN+p+Vector3.UP*3.2; add_child(mirror); mirrors[id]=mirror
			box(p+Vector3.UP*1.8,Vector3(.5,2.2,.5),"lens_stone")
			b.piece(mirror,"gold",Vector3.ZERO,Vector3(1.35,1.35,.18))
			b.piece(mirror,"iron",Vector3(0,0,-.12),Vector3(1.12,1.12,.08))
			var beam: MeshInstance3D=b.piece(self,"lens_glow",Vector3.ZERO,Vector3.ONE); beams[id]=beam
	prism=Node3D.new(); prism.position=ORIGIN+NODES.lens+Vector3.UP*2.6; add_child(prism)
	for tier in range(9): b.piece(prism,"lens_glow",Vector3(0,(tier-4)*.2,0),Vector3(1.8-abs(tier-4)*.3,.18,1.8-abs(tier-4)*.3))
	for arm in range(4):
		var angle: float=arm*PI/2
		for segment in range(64):
			var t: float=TAU*segment/64
			box(NODES.lens+Vector3(cos(t)*3*cos(angle),2.8+sin(t)*3,cos(t)*3*sin(angle)),Vector3(.28,.28,.28),"gold")
	for cache in ["west_cache","east_cache"]:
		var instrument:=Node3D.new(); instrument.position=ORIGIN+NODES[cache]+Vector3.UP*1.35; add_child(instrument); debt_props[cache]=instrument
		b.piece(instrument,"gold",Vector3.ZERO,Vector3(.8,.12,.6))
		b.piece(instrument,"iron",Vector3(0,.2,0),Vector3(.15,.5,.15))
		b.piece(instrument,"lens_glow",Vector3(0,.4,0),Vector3(.5,.12,.15))
	chart_mesh=b.piece(self,"lens_glow",ORIGIN+NODES.chart+Vector3.UP*1.3,Vector3(1.1,.08,.8))
	for p in [Vector3(0,0,26),Vector3(-9,0,-30),Vector3(9,0,-30),Vector3(-9,0,-61),Vector3(9,0,-61)]: world._lantern(ORIGIN+p,false)
	world.block_count+=b.finish(world); _sign(TRAIL+Vector3.UP*2,"Eastern expedition · Sunken Lens")
	var positions=[Vector3(-10,0,-34),Vector3(11,0,-43),Vector3(-13,0,-49),Vector3(13,0,-51),Vector3(0,0,-63)]
	for i in range(5):
		var enemy=preload("res://scripts/solar_scorpion.gd").new() if i==4 else Enemy.new(); enemy.adventure=self; enemy.progress=state.lens; enemy.enemy_id="lens_"+str(i); enemy.role="boss" if i==4 else "mage" if i==1 else "guard"
		enemy.title="The Meridian Keeper" if i==4 else "Gilded Sentinel"; enemy.health_override=360 if i==4 else 100; enemy.position=ORIGIN+positions[i]+Vector3.UP*.15
		add_child(enemy); enemies.append(enemy)
func _sign(p: Vector3,label: String) -> void:
	var sign:=Label3D.new(); sign.position=p; sign.text=label; sign.font_size=22; sign.pixel_size=.003; sign.billboard=BaseMaterial3D.BILLBOARD_ENABLED; sign.visibility_range_begin=4.5; sign.visibility_range_end=18; add_child(sign)
func _ui() -> void:
	var layer:=CanvasLayer.new(); layer.layer=7; add_child(layer)
	preview_label=Label.new(); preview_label.position=Vector2(32,76); preview_label.text="SUNKEN LENS PREVIEW · progress is not saved"; layer.add_child(preview_label)
	dialog=ColorRect.new(); dialog.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); dialog.color=Color("25251f"); layer.add_child(dialog)
	var center:=CenterContainer.new(); center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); dialog.add_child(center)
	var col:=VBoxContainer.new(); col.custom_minimum_size.x=720; col.add_theme_constant_override("separation",16); center.add_child(col)
	title=Label.new(); title.add_theme_font_size_override("font_size",25); col.add_child(title)
	description=Label.new(); description.custom_minimum_size=Vector2(720,230); description.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART; description.add_theme_font_size_override("font_size",18); col.add_child(description)
	options=VBoxContainer.new(); col.add_child(options)
	var close:=Button.new(); close.text="Return [ Esc ]"; close.custom_minimum_size.y=42; close.pressed.connect(func(): close_dialog(); world.player.set_paused(false)); col.add_child(close); dialog.hide()
func _button(label: String,id: String) -> void:
	var button:=Button.new(); button.text=label; button.custom_minimum_size.y=42; button.pressed.connect(func(): act(id)); options.add_child(button)
func aligned() -> bool:
	for id in SOLUTIONS:
		if state.lens.rotations[id]!=SOLUTIONS[id]: return false
	return true
func _refresh() -> void:
	for cache in debt_props: debt_props[cache].visible=cache not in state.lens.get("debt_instruments",[])
	gate.visible=not state.lens.activated; gate.collision_layer=0 if state.lens.activated else 1
	prism.visible=state.lens.activated; chart_mesh.visible=not state.lens.chart
	for id: String in SOLUTIONS:
		var setting: int=int(state.lens.rotations[id]); mirrors[id].rotation.y=-setting*PI/2
		var start: Vector3=ORIGIN+NODES[id]+Vector3.UP*3.2
		var end: Vector3=ORIGIN+NODES.lens+Vector3.UP*2.6 if setting==SOLUTIONS[id] else start+[Vector3.FORWARD,Vector3.RIGHT,Vector3.BACK,Vector3.LEFT][setting]*7
		var beam: MeshInstance3D=beams[id]; beam.position=(start+end)/2; beam.scale=Vector3(.06,.06,start.distance_to(end)); beam.look_at(end)
func enter() -> bool:
	if world.player.paused or "archive" not in state.story_completed: return false
	if inside: return true
	for chapter in [world.seal,world.winter,world.threshold,world.convergence,world.choir,world.roots,world.shore,world.archive_chapter,world.mountain,world.realms,world.adventure]:
		if chapter.inside: chapter.leave()
	inside=true; world.player.position=ORIGIN+Vector3(0,.2,40); world.player.velocity=Vector3.ZERO; world.player.rotation=Vector3.ZERO
	for child in world.get_children():
		if child is WorldEnvironment:
			environment_backup=child.environment
			var env: Environment=environment_backup.duplicate(true); env.background_mode=Environment.BG_COLOR; env.background_color=Color("aa997d"); env.fog_light_color=Color("bba584"); env.fog_density=.004; env.ambient_light_color=Color("ddc8a4"); preload("res://scripts/regional_sky.gd").apply(env,"lens"); child.environment=env
	world.hud.world_map.selected_quest="lens"; world.hud.world_map.set_view(true); world.audio.sfx("portal")
	world.hud.announce("The Sunken Lens","Veyra's expedition has uncovered an observatory that remembers the roads between worlds."); return true
func leave() -> void:
	if not inside: return
	inside=false; world.adventure.clear_projectiles(); world.player.position=TRAIL+Vector3(0,.2,2.5); world.player.velocity=Vector3.ZERO
	for child in world.get_children():
		if child is WorldEnvironment and environment_backup!=null: child.environment=environment_backup
	for enemy in enemies:
		if not enemy.dead: enemy.position=enemy.home; enemy.health=enemy.maximum_health; enemy.velocity=Vector3.ZERO; enemy.windup=0; enemy._update_label()
func nearest() -> Dictionary:
	if not inside:
		if world.player.position.distance_to(TRAIL)<2.5: return {"kind":"lens","id":"trail","text":"[ E ] Travel to the Sunken Lens"}
		return {}
	for enemy in enemies:
		if enemy.dead and enemy.enemy_id not in state.lens.looted and world.player.position.distance_to(enemy.position)<2.5: return {"kind":"lens","id":enemy.enemy_id,"text":"[ E ] Recover solar relics"}
	for id: String in NODES:
		if world.player.position.distance_to(ORIGIN+NODES[id])<2.3: return {"kind":"lens","id":id,"text":"[ E ] "+NAMES[id]}
	return {}
func station_nearby() -> String:
	for id in ["forge","enchant"]:
		if inside and world.player.position.distance_to(ORIGIN+NODES[id])<2.3: return id
	return ""
func interact(id: String) -> void:
	if world.player.paused or nearest().get("id","")!=id: return
	if id=="trail":
		if not enter(): world.hud.announce("The eastern expedition","Complete The Missing Atlas to follow the observatory lead.")
	elif id=="return": leave()
	elif id in ["forge","enchant"]: world.hud.workshop.open(id)
	elif id.begins_with("lens_"): loot(id)
	else: open_dialog(id)
func open_dialog(id: String) -> void:
	subject=id; world.player.dialog_open=true; world.player.set_paused(true); dialog.show()
	for child in options.get_children(): options.remove_child(child); child.queue_free()
	title.text=NAMES[id].to_upper()
	var p: Dictionary=state.lens
	if id=="keeper":
		description.text="VEYRA · ASTRONOMER\n\nThe atlas describes three mirrors: Dawn, Dusk and Crown. Their inscriptions name directions, not times of day. Align them, restore the lens from three Optic Glass and two crystals, then confront the Meridian Keeper. The excavation caches contain enough for the restoration."
		if state.shore.choice=="navigation": description.text+="\n\nNeris's navigation chart confirms the Crown points north. Your work at the wreck has made our bearings clearer."
		elif state.shore.choice=="harbor": description.text+="\n\nSaltbreak's beacon is burning again. The copied flight recorder still gives us everything needed to find this place."
		if not p.accepted: _button("Help restore the observatory","accept")
		if p.chart and not p.rewarded: _button("Deliver the star chart · learn Sunlance and solar patterns","reward")
		description.text+="\n\n"+objective()
		if not p.get("debt_started",false):
			description.text+="\n\nVEYRA · AN OVERDUE SKY\nMy creditor owns the instruments I lost in the excavation. He has threatened to repossess the stars. I admire his confidence."
			_button("Ask about the missing instruments","debt_accept")
		else:
			description.text+="\n\n"+debt_objective()
			if p.get("debt_instruments",[]).size()==2 and p.get("debt_choice","")=="":
				description.text+="\nThe creditor offers to cancel the debt if we sell the pair. Or I can keep them for public weather charts and repay him from my own work. Your reward comes from my expedition fund either way."
				_button("Sell to settle the debt · 250 gold + 6 Solar Alloy","debt_creditor")
				_button("Keep for public research · 80 gold + 10 Optic Glass + 8 Rune Dust","debt_public")
	elif SOLUTIONS.has(id):
		description.text={"dawn":"DAWN INSCRIPTION\n\nI face the place where the sun first rises. Turn my polished face toward that horizon.","dusk":"DUSK INSCRIPTION\n\nI keep the last light of the day. My face follows the setting sun.","crown":"CROWN INSCRIPTION\n\nMy star stands over the cold pole. Neither sunrise nor sunset moves my bearing."}[id]
		description.text+="\n\nFacing: "+DIRECTIONS[int(p.rotations[id])]+(" · beam meets the lens" if p.rotations[id]==SOLUTIONS[id] else " · beam misses the lens")
		if not p.accepted: description.text+="\nSpeak to Veyra before operating the observatory."
		elif p.activated: description.text+="\nThe active lens locks this alignment."
		else: _button("Rotate clockwise by a quarter turn","rotate")
	elif id=="lens":
		description.text="The lens gathers all three beams. It needs three Optic Glass and two crystals to replace its fractured heart. Activating it lowers the solar barrier protecting the rear vault."
		if p.activated: description.text+="\n\nThe observatory is restored. Defeat the Meridian Keeper and recover its chart."
		elif not aligned(): description.text+="\n\nAll three mirror beams must meet the lens first."
		else: _button("Restore lens · 3 Optic Glass + 2 crystals","activate")
	elif id=="chart":
		description.text="The chart names the First Threshold: an abandoned station beyond this sky. The woodland account and the Ashen Choir's signal are still needed to make the route safe. This discovery advances the shared investigation; it does not open the space gate yet."
		if "lens_4" not in p.defeated: description.text+="\n\nThe Meridian Keeper still guards the chart."
		elif not p.chart: _button("Recover the protected star chart","chart")
	else:
		description.text="Optic Glass and crystals survived beneath the sand. These supplies can restore the central lens; additional solar metal supports forging."
		if id not in p.caches: _button("Collect excavation supplies","cache")
		else: description.text+="\n\nAlready collected."
		if id in ["west_cache","east_cache"]:
			var guard: String="lens_0" if id=="west_cache" else "lens_1"
			description.text+="\n\n"+("Veyra's brass horizon gauge rests above the western excavation." if id=="west_cache" else "Veyra's weather prism survived inside the eastern survey case.")
			if not p.get("debt_started",false): description.text+=" Speak with Veyra about her debt before recovering it."
			elif id in p.get("debt_instruments",[]): description.text+=" Already recovered."
			elif guard not in p.defeated: description.text+=" The nearby observatory sentinel must be defeated before it is safe to recover."
			else: _button("Recover Veyra's instrument","debt_collect")
func act(id: String) -> bool:
	if not dialog.visible or not inside or not NODES.has(subject) or world.player.position.distance_to(ORIGIN+NODES[subject])>=2.3: return false
	var p: Dictionary=state.lens
	var success:=false
	if id=="debt_accept" and subject=="keeper" and not p.get("debt_started",false): p.debt_started=true; success=true
	elif id=="debt_collect" and subject in ["west_cache","east_cache"] and p.get("debt_started",false):
		var guard: String="lens_0" if subject=="west_cache" else "lens_1"
		if guard not in p.defeated or subject in p.get("debt_instruments",[]): return false
		if not p.has("debt_instruments"): p.debt_instruments=[]
		p.debt_instruments.append(subject); success=true
	elif id in ["debt_creditor","debt_public"] and subject=="keeper" and p.get("debt_instruments",[]).size()==2 and p.get("debt_choice","")=="":
		p.debt_choice="creditor" if id=="debt_creditor" else "public"
		state.gold+=250 if p.debt_choice=="creditor" else 80
		world.adventure.grant_materials({"solar_alloy":6} if p.debt_choice=="creditor" else {"optic_glass":10,"rune_dust":8})
		success=true; world.audio.sfx("quest")
	elif id=="accept" and subject=="keeper" and not p.accepted: p.accepted=true; success=true
	elif id=="rotate" and SOLUTIONS.has(subject) and p.accepted and not p.activated: p.rotations[subject]=(int(p.rotations[subject])+1)%4; success=true; world.audio.sfx("enchant")
	elif id=="cache" and subject in ["west_cache","east_cache"] and subject not in p.caches:
		p.caches.append(subject); world.adventure.grant_materials({"optic_glass":4,"crystal":2,"solar_alloy":4}); success=true
	elif id=="activate" and subject=="lens" and p.accepted and aligned() and not p.activated:
		if not state.can_pay({"optic_glass":3,"crystal":2}): description.text="Restore the missing materials from the excavation caches: 3 Optic Glass and 2 crystals."; world.audio.sfx("error"); return false
		state.materials.optic_glass-=3; state.materials.crystal-=2; p.activated=true; success=true; world.audio.sfx("quest")
	elif id=="chart" and subject=="chart" and p.activated and "lens_4" in p.defeated and not p.chart: p.chart=true; success=true
	elif id=="reward" and subject=="keeper" and p.chart and not p.rewarded:
		p.rewarded=true; state.story_completed.append("lens"); state.blueprints.append("sunken_lens"); state.gold+=160
		if "sunlance" not in state.known_spells: state.known_spells.append("sunlance")
		state.active_spell="sunlance"
		var uid: String=state.add_item("horizon_staff",2,"insight"); state.inventory[uid].favorite=true
		world.adventure.grant_materials({"solar_alloy":7,"optic_glass":5,"steel_ingot":5}); success=true
	if success:
		if id.begins_with("debt_"): world.hud.world_map.selected_quest="side_sunken_lens"
		state._commit(); open_dialog(subject)
	return success
func can_damage_enemy(id: String) -> bool:
	return id!="lens_4" or state.lens.activated
func mark_defeated(id: String) -> void:
	if id not in state.lens.defeated: state.lens.defeated.append(id); state._commit()
func loot(id: String) -> bool:
	if id not in state.lens.defeated or id in state.lens.looted: return false
	state.lens.looted.append(id); state.gold+=25; world.adventure.grant_materials({"optic_glass":2,"solar_alloy":3})
	if id=="lens_4":
		var uid: String=state.add_item("sunsteel_saber",2,"fleet"); state.inventory[uid].favorite=true
	else: state.consumables.healing_draught=int(state.consumables.get("healing_draught",0))+1
	state._commit(); world.hud.announce("Solar relics recovered","Solar alloy and optic glass added to your collection."); return true
func debt_objective() -> String:
	var p: Dictionary=state.lens
	if p.get("debt_choice","")=="creditor": return "The Astronomer's Debt complete · instruments sold, debt cleared. Veyra: 'At last, the only things watching my movements are celestial bodies.'"
	if p.get("debt_choice","")=="public": return "The Astronomer's Debt complete · instruments retained for public weather charts. Veyra: 'The farmers get a forecast. The creditor gets installments. Neither believes me when I promise sunshine.'"
	if not p.get("debt_started",false): return "The Astronomer's Debt · Ask Veyra about her missing instruments."
	var recovered: Array=p.get("debt_instruments",[])
	if recovered.size()==2: return "Both instruments recovered · return to Veyra and decide their future."
	return "Recover Veyra's instruments · %d / 2. Search the western excavation and eastern survey caches outside the observatory ring; clear their nearby sentinels. Earlier sentinel defeats count." % recovered.size()

func objective() -> String:
	var p: Dictionary=state.lens
	if p.rewarded: return "Star chart delivered · Sunlance learned · Follow the remaining convergence leads"
	if not p.accepted: return "Speak with Veyra at the expedition camp"
	if not aligned(): return "Align Dawn, Dusk and Crown using their inscriptions"
	if not p.activated: return "Restore the central lens · 3 Optic Glass + 2 crystals"
	if not p.chart: return "Defeat the Meridian Keeper, loot its blade, and recover the star chart"
	return "Return the star chart to Veyra"
func close_dialog() -> void:
	dialog.hide(); world.player.dialog_open=false
func check_fall() -> void:
	var p: Vector3=world.player.position-ORIGIN
	if p.y< -8 or absf(p.x)>51 or p.z< -93 or p.z>53: world.player.position=ORIGIN+Vector3(0,.2,40); world.player.velocity=Vector3.ZERO
func fire(origin: Vector3,direction: Vector3,damage: float,hostile: bool,source: CollisionObject3D,magic: bool) -> void:
	world.adventure.fire(origin,direction,damage,hostile,source,magic)
func line_clear(from: Vector3,to: Vector3,source: CollisionObject3D,target_body: CollisionObject3D=null) -> bool:
	return world.adventure.line_clear(from,to,source,target_body)
func _process(delta: float) -> void:
	preview_label.visible="--lens-preview" in OS.get_cmdline_user_args() and not world.player.paused
	if feedback_time>0: world.adventure.feedback=feedback; world.adventure.feedback_time=feedback_time; feedback_time=maxf(0,feedback_time-delta)
