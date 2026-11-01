extends Node3D
const State=preload("res://scripts/character_state.gd")
const Visual=preload("res://scripts/character_visual.gd")
const Enemy=preload("res://scripts/enemy.gd")
const ORIGIN=Vector3(1680,0,0)
const TRAIL=Vector3(44,0,30)
const PILGRIM_SHRINES=["vigil_south","vigil_middle","vigil_north"]
var vigil_time:=0.0
var vigil_lights: Dictionary={}
var vigil_labels: Dictionary={}
var memory_door: Node3D
var memory_caption: Label3D
const FIRE_SEALS={"fire_west":"choir_2","fire_east":"choir_3"}
var fire_core: MeshInstance3D
var fire_caption: Label3D
var pilgrim: Node3D
var pilgrim_label: Label3D
const NODES={"pilgrim_notice":Vector3(0,0,33),"empty_shoes":Vector3(-22,0,-8),"escape_note":Vector3(24,0,-32),"pilgrim":Vector3(23,0,-8),"fire_west":Vector3(-7,0,-48),"fire_east":Vector3(7,0,-48),"fire_cradle":Vector3(9,0,-69),"memory_lock":Vector3(-6,0,-77),"memory_archive":Vector3(-13,0,-77),"vigil_south":Vector3(7,0,5),"vigil_middle":Vector3(-7,0,-12),"vigil_north":Vector3(7,0,-39),"roll":Vector3(-8,0,-69),"return":Vector3(0,0,40),"keeper":Vector3(-13,.25,24),"forge":Vector3(13,0,22),"enchant":Vector3(20,0,22),"camp_cache":Vector3(-23,0,12),"vault_cache":Vector3(23,0,-39),"ember":Vector3(-12,0,-33),"ash":Vector3(12,0,-33),"stone":Vector3(0,0,-43),"receiver":Vector3(0,0,-53),"record":Vector3(0,0,-69)}
const NAMES={"pilgrim_notice":"Missing pilgrim · camp notice","empty_shoes":"A pilgrim’s empty shoes","escape_note":"Hidden pilgrim letter","pilgrim":"Leth · missing pilgrim","fire_west":"Western ember governor","fire_east":"Eastern ember governor","fire_cradle":"The bound ember cradle","memory_lock":"Sanctuary archive pressure lock","memory_archive":"Sealed awakening records","vigil_south":"First vigil · breath","vigil_middle":"Second vigil · silence","vigil_north":"Third vigil · memory","roll":"The omitted names","return":"Pilgrim road · Frostmere","keeper":"Cantor Sereth","forge":"Pilgrim forge","enchant":"Resonance table","camp_cache":"Pilgrim supply chest","vault_cache":"Mason's supply chest","ember":"Ember resonator","ash":"Ash resonator","stone":"Stone resonator","receiver":"The buried receiver","record":"The first distress signal"}
const SONG=["ember","ash","stone"]
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
var lights: Dictionary={}
var record_mesh: MeshInstance3D
var environment_backup: Environment
var bell: AudioStreamPlayer
func _ready() -> void:
	state=world.player.character; _build(); _ui(); state.changed.connect(_refresh); _refresh()
func box(p: Vector3,size: Vector3,key: String,solid: bool=false,angle: float=0) -> void:
	world.blocks.add(key,ORIGIN+p,size,angle)
	if solid: world._solid(ORIGIN+p,size)
func _build() -> void:
	var b: RefCounted=world.blocks
	for entry in [["choir_basalt","504b51"],["choir_ash","827777"],["choir_lava","d86532"],["choir_signal","84c9d4"]]:
		var mat: StandardMaterial3D=b.materials["window" if entry[0] in ["choir_lava","choir_signal"] else "stone"].duplicate(); mat.albedo_color=Color(entry[1])
		if mat.emission_enabled: mat.emission=Color(entry[1]); mat.emission_energy_multiplier=.7
		b.materials[entry[0]]=mat
	# Safe basalt causeway between deep, inaccessible lava channels.
	world._solid(ORIGIN+Vector3(0,-.6,-20),Vector3(86,1,128))
	for x in range(-42,43):
		for z in range(-83,44): box(Vector3(x,-.17,z),Vector3(1.01,.14,1.01),"path" if abs(x)<3 else "choir_ash")
	for side in [-1,1]:
		box(Vector3(side*35,.1,-27),Vector3(12,.3,98),"choir_lava")
		box(Vector3(side*28,1,-27),Vector3(1,2,99),"choir_basalt",true)
		for end in [-76.5,22.5]: box(Vector3(side*35,1,end),Vector3(14,2,1),"choir_basalt",true)
		for i in range(24):
			box(Vector3(side*28,2.1,-74+i*4),Vector3(1.3,.4,1.3),"iron")
		for i in range(20):
			for tier in range(9+i%7): box(Vector3(side*(44+tier*.35),tier*.75,-82+i*7),Vector3(8-tier*.22,.72,8),"choir_basalt")
	world._house(ORIGIN+Vector3(-13,0,20),10,12,3.8,false,"choir_lodge")
	for x in [9,25]:
		for z in [17,27]: box(Vector3(x,2,z),Vector3(.3,4,.3),"iron",true)
	box(Vector3(17,4.2,22),Vector3(17,.25,12),"roof")
	# Tall basalt organ-pipes frame a roofless sanctuary with a central processional aisle.
	for side in [-1,1]:
		for i in range(12):
			var x: float=side*(17+i%2*3); var z: float=-20-i*5
			box(Vector3(x,3.5,z),Vector3(1.4,7,1.4),"choir_basalt",true)
			for rib in range(4): box(Vector3(x-.55+rib*.37,4.5,z+.8),Vector3(.22,9+(i%3),.25),"iron")
			box(Vector3(x,8+i%3*.5,z),Vector3(1.9,.4,1.9),"gold")
		for row in range(12):
			for col in range(10): box(Vector3(side*(3.5+col*1.15),.24+row*.48,-57),Vector3(1.1,.44,.8),"choir_basalt",true)
		for step in range(8): box(Vector3(side*(3.3-step*.4),5.8+step*.28,-57),Vector3(.6,.4,1),"iron")
	gate=StaticBody3D.new(); gate.position=ORIGIN+Vector3(0,2.8,-57); add_child(gate)
	var collision:=CollisionShape3D.new(); var shape:=BoxShape3D.new(); shape.size=Vector3(5.8,5.6,.6); collision.shape=shape; gate.add_child(collision); b.piece(gate,"choir_signal",Vector3.ZERO,shape.size)
	for id: String in NODES:
		var p: Vector3=NODES[id]
		if id!="pilgrim": _sign(ORIGIN+p+Vector3.UP*2,NAMES[id])
		if id in ["keeper","pilgrim"]:
			var npc:=Visual.new(); npc.position=ORIGIN+p; npc.rotation.y=PI; add_child(npc)
			var model:=State.new()
			for slot in ["head","chest","hands","legs","feet"]: model.equip(model.add_item("cloth_"+slot),slot)
			if id=="pilgrim": model.equipment.main_hand=""; model.equipment.off_hand=""
			npc.build(model)
			if id=="pilgrim":
				pilgrim=npc; pilgrim_label=Label3D.new(); pilgrim_label.position.y=2.5; pilgrim_label.font_size=22; pilgrim_label.pixel_size=.003; pilgrim_label.billboard=BaseMaterial3D.BILLBOARD_ENABLED; pilgrim.add_child(pilgrim_label)
		elif id!="return":
			box(p+Vector3.UP*.45,Vector3(1.4,.9,1),"wood" if "cache" in id else "choir_basalt")
			box(p+Vector3.UP*.95,Vector3(1.6,.12,1.2),"gold")
		if id in SONG:
			for side in [-1,1]: box(p+Vector3(side*.8,2.4,0),Vector3(.24,3,.24),"iron")
			box(p+Vector3.UP*3.8,Vector3(2,.2,.4),"gold")
			for tier in range(5): box(p+Vector3(0,2.4+tier*.22,0),Vector3(1.15-tier*.13,.2,1.15-tier*.13),"gold")
			lights[id]=b.piece(self,"coal",ORIGIN+p+Vector3(0,1.4,.65),Vector3(.4,.4,.16))
			_sign(ORIGIN+p+Vector3.UP*4.4,str(SONG.find(id)+1)+" · "+id.to_upper())
	for id in PILGRIM_SHRINES:
		vigil_lights[id]=b.piece(self,"choir_lava",ORIGIN+NODES[id]+Vector3.UP*1.4,Vector3(.6,.7,.6))
		var label:=Label3D.new(); label.position=ORIGIN+NODES[id]+Vector3.UP*2.5; label.font_size=22; label.pixel_size=.003; label.billboard=BaseMaterial3D.BILLBOARD_ENABLED; add_child(label); vigil_labels[id]=label
	b.piece(self,"snow",ORIGIN+NODES.roll+Vector3.UP*1.06,Vector3(1,.08,.65))
	memory_door=Node3D.new(); memory_door.position=ORIGIN+NODES.memory_archive+Vector3(-.9,1.6,.6); add_child(memory_door)
	b.piece(memory_door,"iron",Vector3(.9,0,0),Vector3(1.8,1.4,.15))
	for side in [-1,1]: box(NODES.memory_archive+Vector3(side,1.6,0),Vector3(.15,1.6,1.3),"choir_basalt")
	box(NODES.memory_archive+Vector3(0,1.6,-.65),Vector3(2.1,1.6,.15),"choir_basalt")
	box(NODES.memory_archive+Vector3(0,2.4,0),Vector3(2.1,.15,1.3),"choir_basalt")
	b.piece(self,"snow",ORIGIN+NODES.memory_archive+Vector3(0,1.2,.1),Vector3(1,.1,.7))
	memory_caption=Label3D.new(); memory_caption.position=ORIGIN+NODES.memory_archive+Vector3.UP*2.7; memory_caption.font_size=20; memory_caption.pixel_size=.003; memory_caption.billboard=BaseMaterial3D.BILLBOARD_ENABLED; add_child(memory_caption)
	fire_core=b.piece(self,"choir_signal",ORIGIN+NODES.fire_cradle+Vector3.UP*1.5,Vector3(.9,.9,.9))
	fire_caption=Label3D.new(); fire_caption.position=ORIGIN+NODES.fire_cradle+Vector3.UP*2.5; fire_caption.font_size=20; fire_caption.pixel_size=.003; fire_caption.billboard=BaseMaterial3D.BILLBOARD_ENABLED; add_child(fire_caption)
	for side in [-1,1]: b.piece(self,"leather",ORIGIN+NODES.empty_shoes+Vector3(side*.28,1.12,0),Vector3(.3,.28,.65))
	b.piece(self,"snow",ORIGIN+NODES.escape_note+Vector3.UP*1.04,Vector3(.8,.06,.55))
	record_mesh=b.piece(self,"choir_signal",ORIGIN+NODES.record+Vector3.UP*1.3,Vector3(1.1,.6,.7))
	for i in range(15):
		box(Vector3(-7+i,1.5,-74),Vector3(.5,3+sin(i*.9)*1.3,.7),"iron")
		box(Vector3(-7+i,3.5,-74),Vector3(.3,.15,.9),"choir_signal")
	for p in [Vector3(0,0,28),Vector3(-6,0,-19),Vector3(6,0,-45),Vector3(0,0,-64)]: world._lantern(ORIGIN+p,false)
	world.block_count+=b.finish(world); _sign(TRAIL+Vector3.UP*2,"Ash pilgrimage · Ember Caldera")
	var positions=[Vector3(-10,0,-21),Vector3(11,0,-25),Vector3(-11,0,-46),Vector3(10,0,-50),Vector3(0,0,-66)]
	for i in range(5):
		var enemy=preload("res://scripts/ash_cantor.gd").new() if i==4 else Enemy.new(); enemy.adventure=self; enemy.progress=state.choir; enemy.enemy_id="choir_"+str(i); enemy.role="boss" if i==4 else "mage" if i%2 else "guard"
		enemy.title="The Dissonant Cantor" if i==4 else "Ashbound Sentinel"; enemy.health_override=340 if i==4 else 100; enemy.position=ORIGIN+positions[i]+Vector3.UP*.15
		add_child(enemy); enemies.append(enemy)
	bell=AudioStreamPlayer.new(); bell.bus="Effects"; bell.stream=world.audio.streams.get("enchant"); add_child(bell)
func _sign(p: Vector3,label: String) -> void:
	var sign:=Label3D.new(); sign.position=p; sign.text=label; sign.font_size=22; sign.pixel_size=.003; sign.billboard=BaseMaterial3D.BILLBOARD_ENABLED; sign.visibility_range_begin=4.5; sign.visibility_range_end=18; add_child(sign)
func _ui() -> void:
	var layer:=CanvasLayer.new(); layer.layer=7; add_child(layer)
	preview_label=Label.new(); preview_label.position=Vector2(32,76); preview_label.text="EMBER CALDERA PREVIEW · progress is not saved"; layer.add_child(preview_label)
	dialog=ColorRect.new(); dialog.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); dialog.color=Color("282329"); layer.add_child(dialog)
	var center:=CenterContainer.new(); center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); dialog.add_child(center)
	var col:=VBoxContainer.new(); col.custom_minimum_size.x=720; col.add_theme_constant_override("separation",16); center.add_child(col)
	title=Label.new(); title.add_theme_font_size_override("font_size",25); col.add_child(title)
	description=Label.new(); description.custom_minimum_size=Vector2(720,230); description.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART; description.add_theme_font_size_override("font_size",18); col.add_child(description)
	options=VBoxContainer.new(); col.add_child(options)
	var close:=Button.new(); close.text="Return [ Esc ]"; close.custom_minimum_size.y=42; close.pressed.connect(func(): close_dialog(); world.player.set_paused(false)); col.add_child(close); dialog.hide()
func _button(label: String,id: String) -> void:
	var button:=Button.new(); button.text=label; button.custom_minimum_size.y=42; button.pressed.connect(func(): act(id)); options.add_child(button)
func enter() -> bool:
	if world.player.paused or "council" not in state.story_completed: return false
	if inside: return true
	for chapter in [world.seal,world.winter,world.threshold,world.convergence,world.lens,world.roots,world.shore,world.archive_chapter,world.mountain,world.realms,world.adventure]:
		if chapter.inside: chapter.leave()
	inside=true; world.player.position=ORIGIN+Vector3(0,.2,40); world.player.velocity=Vector3.ZERO; world.player.rotation=Vector3.ZERO
	for child in world.get_children():
		if child is WorldEnvironment:
			environment_backup=child.environment
			var env: Environment=environment_backup.duplicate(true); env.background_mode=Environment.BG_COLOR; env.background_color=Color("514750"); env.fog_light_color=Color("76616a"); env.fog_density=.004; env.ambient_light_color=Color("b9a9b6"); preload("res://scripts/regional_sky.gd").apply(env,"choir"); child.environment=env
	world.hud.world_map.selected_quest="choir"; world.hud.world_map.set_view(true); world.audio.sfx("portal")
	world.hud.announce("Ember Caldera","The Choir hears a voice in the stone. Sereth needs someone willing to listen without swearing an oath."); return true
func leave() -> void:
	if not inside: return
	inside=false; world.adventure.clear_projectiles(); world.player.position=TRAIL+Vector3(0,.2,2.5); world.player.velocity=Vector3.ZERO
	for child in world.get_children():
		if child is WorldEnvironment and environment_backup!=null: child.environment=environment_backup
	for enemy in enemies:
		if not enemy.dead: enemy.position=enemy.home; enemy.health=enemy.maximum_health; enemy.velocity=Vector3.ZERO; enemy.windup=0; enemy._update_label()
func nearest() -> Dictionary:
	if not inside:
		if world.player.position.distance_to(TRAIL)<2.5: return {"kind":"choir","id":"trail","text":"[ E ] Travel to Ember Caldera"}
		return {}
	for enemy in enemies:
		if enemy.dead and enemy.enemy_id not in state.choir.looted and world.player.position.distance_to(enemy.position)<2.5: return {"kind":"choir","id":enemy.enemy_id,"text":"[ E ] Recover resonant relics"}
	for id: String in NODES:
		if world.player.position.distance_to(interaction_position(id))<2.3: return {"kind":"choir","id":id,"text":"[ E ] "+interaction_name(id)}
	return {}
func station_nearby() -> String:
	for id in ["forge","enchant"]:
		if inside and world.player.position.distance_to(ORIGIN+NODES[id])<2.3: return id
	return ""
func interact(id: String) -> void:
	if world.player.paused or nearest().get("id","")!=id: return
	if id=="trail":
		if not enter(): world.hud.announce("The ash pilgrimage","Resolve The Divided Council to follow the ash pilgrimage.")
	elif id=="return": leave()
	elif id in ["forge","enchant"]: world.hud.workshop.open(id)
	elif id.begins_with("choir_"): loot(id)
	else: open_dialog(id)
func _refresh() -> void:
	pilgrim.position=interaction_position("pilgrim")
	pilgrim_label.text="Leth · safe at camp" if state.choir.get("pilgrim_choice","")!="" else "Leth · missing pilgrim"
	var fire: String=state.choir.get("fire_choice","")
	fire_core.material_override=world.blocks.materials["choir_lava" if fire=="awaken" else "coal" if fire=="silence" else "choir_signal"]
	fire_caption.text={"":"BOUND EMBER","awaken":"EMBER OF CONQUEST","contain":"EMBER UNDER GUARD","silence":"EMBER SILENCED"}[fire]
	memory_door.rotation.y=-1.8 if int(state.choir.get("memory_lock",0))==3 else 0.0
	memory_caption.text={"":"SEALED HISTORY","publish":"TESTIMONY MADE PUBLIC","conceal":"RESTRICTED CHOIR RECORD"}[state.choir.get("memory_choice","")]
	gate.visible=not state.choir.activated; gate.collision_layer=0 if state.choir.activated else 1
	record_mesh.visible=not state.choir.record
	for id: String in SONG: lights[id].material_override=world.blocks.materials["choir_signal" if id in state.choir.song else "coal"]
func open_dialog(id: String) -> void:
	subject=id; world.player.dialog_open=true; world.player.set_paused(true); dialog.show()
	for child in options.get_children(): options.remove_child(child); child.queue_free()
	title.text=interaction_name(id).to_upper()
	var p: Dictionary=state.choir
	if id in ["pilgrim_notice","empty_shoes","escape_note","pilgrim"]: pilgrim_dialog(); return
	if id in FIRE_SEALS or id=="fire_cradle": fire_dialog(); return
	if id in ["memory_lock","memory_archive"]: memory_dialog(); return
	if id in PILGRIM_SHRINES or id=="roll": listener_dialog(); return
	if id=="keeper":
		if p.get("memory_choice","")!="": _button("Discuss the bound ember","fire_discuss")
		if p.get("listener_joined",false): _button("Discuss the sealed awakening records","memory_discuss")
		if p.rewarded: _button("Discuss the ash pilgrimage","listener_discuss")
		description.text="SERETH · CANTOR OF THE ASHEN CHOIR\n\nThe council heard a threat in our song. I hear someone calling for help. Our sentinels turned on us when the buried receiver woke. Ring the resonators in the order carved into their plaques, then mend the receiver with three Resonant Ore and two crystals. The supply chests hold enough.\n\nYou need swear no oath to learn what happened here."
		if p.rewarded: description.text="SERETH · THE SIGNAL ANSWERED\n\nA stranded crew, and we called their fear a promise. Take this frequency to the expedition. I will tell our pilgrims what the receiver truly said: the furnace must stay sealed.\n\nYou have my staff, the resonance patterns, and our surviving repair supplies. The council, woodland memory, wreck recorder and star chart can now be brought together."
		if state.mountain.clan!="": description.text+="\n\nYour clan and the Choir have their quarrels. I will still hear what you find."
		if not p.accepted: _button("Investigate the voice in the stone","accept")
		if p.record and not p.rewarded: _button("Deliver the distress signal · claim resonance equipment and patterns","reward")
		description.text+="\n\n"+objective()
	elif id in SONG:
		description.text={"ember":"I · EMBER\n\nFirst came the spark. Ring Ember before any other voice.","ash":"II · ASH\n\nAfter the flame, ash settled. Ring Ash after Ember.","stone":"III · STONE\n\nLast, the mountain held the memory. Ring Stone after Ember and Ash."}[id]
		description.text+="\n\nSequence: "+(" → ".join(p.song) if not p.song.is_empty() else "not started")+"\nWrong notes reset the sequence without spending materials. The numbered plaques can be followed with sound muted."
		if not p.accepted: description.text+="\nSpeak with Sereth before ringing the resonators."
		elif p.activated: description.text+="\nThe repaired receiver holds this song."
		else: _button("Ring "+id.capitalize(),"ring")
	elif id=="receiver":
		description.text="Three voices stabilize the receiver. Repair its cracked resonator with 3 Resonant Ore and 2 crystals to lower the northern barrier and awaken the Dissonant Cantor."
		if p.activated: description.text+="\n\nThe receiver is repaired. Its guardian protects the signal archive."
		elif p.song!=SONG: description.text+="\n\nRing Ember, then Ash, then Stone."
		else: _button("Repair receiver · 3 Resonant Ore + 2 crystals","activate")
	elif id=="record":
		description.text="FIRST DISTRESS SIGNAL\n\n'Threshold station to surface. Our transit regulator failed. The return signal is an emergency beacon, not a command to awaken the furnace. Repeat: keep the furnace sealed. Use the beacon frequency to reach us.'\n\nThe Choir has been hearing a stranded crew. Copy this frequency for the expedition and bring the truth to Sereth."
		if "choir_4" not in p.defeated: description.text="The Dissonant Cantor still guards the signal archive."
		elif not p.record: _button("Copy the protected beacon frequency","record")
		else: description.text+="\n\nSafely copied."
	else:
		description.text="A pilgrim's repair supplies: 4 Resonant Ore, 3 Ash Glass and 2 crystals. Spare ore and glass can be forged into equipment."
		if id not in p.caches: _button("Collect the repair supplies","cache")
		else: description.text+="\n\nAlready collected."
func act(id: String) -> bool:
	if not dialog.visible or not inside or not NODES.has(subject) or world.player.position.distance_to(interaction_position(subject))>=2.3: return false
	var p: Dictionary=state.choir
	var success:=false
	if id=="pilgrim_start" and subject=="pilgrim_notice" and int(p.get("pilgrim_stage",0))==0:
		p.pilgrim_stage=1; success=true
	elif id=="pilgrim_shoes" and subject=="empty_shoes" and int(p.get("pilgrim_stage",0))==1:
		p.pilgrim_stage=2; success=true
	elif id=="pilgrim_letter" and subject=="escape_note" and int(p.get("pilgrim_stage",0))==2 and "choir_1" in p.defeated:
		p.pilgrim_stage=3; success=true
	elif id in ["pilgrim_shelter","pilgrim_depart"] and subject=="pilgrim" and int(p.get("pilgrim_stage",0))==3 and p.get("pilgrim_choice","")=="":
		p.pilgrim_choice="shelter" if id=="pilgrim_shelter" else "depart"; state.gold+=100
		var uid: String=state.add_item("swift_ring",2,"fleet"); state.inventory[uid].favorite=true; state.inventory[uid].custom_name="Unbound Pilgrim's Ring"
		world.adventure.grant_materials({"herb":8,"water":6} if p.pilgrim_choice=="shelter" else {"resonant_ore":6,"ash_glass":4}); success=true
	elif id=="fire_discuss" and subject=="keeper" and p.get("memory_choice","")!="":
		for child in options.get_children(): options.remove_child(child); child.queue_free()
		fire_dialog(); return true
	if id=="fire_start" and subject=="keeper" and p.get("memory_choice","")!="" and not p.get("fire_started",false):
		p.fire_started=true; success=true
	elif id=="fire_secure" and subject in FIRE_SEALS and p.get("fire_started",false) and subject not in p.get("fire_seals",[]) and FIRE_SEALS[subject] in p.defeated:
		if not p.has("fire_seals"): p.fire_seals=[]
		p.fire_seals.append(subject); success=true
	elif id.begins_with("fire_choose:") and subject=="fire_cradle" and p.get("fire_started",false) and p.get("fire_seals",[]).size()==2 and p.get("fire_choice","")=="":
		var choice:=id.get_slice(":",1)
		if choice not in ["awaken","contain","silence"]: return false
		if choice=="awaken" and int(state.mountain.rank)==3: description.text="Your Clan Voice mandate rules out a conquest oath against the holds. Containment and silence remain available."; return false
		p.fire_choice=choice; state.gold+=250
		var uid: String=state.add_item({"awaken":"resonance_blade","contain":"cantors_staff","silence":"resolve_amulet"}[choice],4,"fleet" if choice=="awaken" else "insight" if choice=="contain" else "vigor")
		state.inventory[uid].favorite=true; state.inventory[uid].custom_name={"awaken":"Ember Voice's Command","contain":"Ember Voice's Vigil","silence":"Ember Voice's Quiet"}[choice]
		world.adventure.grant_materials({"resonant_ore":10,"ash_glass":8}); success=true; world.audio.sfx("quest")
	elif id=="memory_discuss" and subject=="keeper" and p.get("listener_joined",false):
		for child in options.get_children(): options.remove_child(child); child.queue_free()
		memory_dialog(); return true
	if id=="memory_start" and subject=="keeper" and p.get("listener_joined",false) and not p.get("memory_started",false):
		p.memory_started=true; success=true
	elif id.begins_with("memory_lock:") and subject=="memory_lock" and p.get("memory_started",false) and int(p.get("memory_lock",0))<3:
		var setting:=id.get_slice(":",1)
		if setting not in ["mute","vent","release"]: return false
		if setting==["mute","vent","release"][int(p.get("memory_lock",0))]: p.memory_lock=int(p.get("memory_lock",0))+1
		else: p.memory_lock=0
		success=true
	elif id=="memory_read" and subject=="memory_archive" and int(p.get("memory_lock",0))==3 and not p.get("memory_record",false):
		p.memory_record=true; success=true
	elif id in ["memory_publish","memory_conceal"] and subject=="keeper" and p.get("memory_record",false) and p.get("memory_choice","")=="":
		p.memory_choice="publish" if id=="memory_publish" else "conceal"; state.gold+=180
		var uid: String=state.add_item("cantors_staff" if p.memory_choice=="publish" else "resonance_blade",3,"insight" if p.memory_choice=="publish" else "fleet")
		state.inventory[uid].favorite=true; state.inventory[uid].custom_name="Unburied Voice" if p.memory_choice=="publish" else "Keeper of Ash"
		world.adventure.grant_materials({"resonant_ore":8,"ash_glass":6}); success=true; world.audio.sfx("quest")
	elif id=="listener_discuss" and subject=="keeper" and p.rewarded:
		for child in options.get_children(): options.remove_child(child); child.queue_free()
		listener_dialog(); return true
	if id=="listener_start" and subject=="keeper" and p.rewarded and not p.get("listener_started",false):
		p.listener_started=true; success=true
	elif id=="listener_wait" and subject in PILGRIM_SHRINES and p.get("listener_started",false) and subject not in p.get("listener_vigils",[]):
		if not vigil_cool(subject): description.text="The vent is still roaring. Return to the path and wait for the blue light and COOL inscription. Menus pause the vent cycle."; return false
		if not p.has("listener_vigils"): p.listener_vigils=[]
		p.listener_vigils.append(subject); success=true
	elif id=="listener_roll" and subject=="roll" and p.get("listener_vigils",[]).size()==3 and not p.get("listener_record",false):
		p.listener_record=true; success=true
	elif id=="listener_oath" and subject=="keeper" and p.get("listener_record",false) and not p.get("listener_joined",false):
		p.listener_joined=true; state.gold+=140
		var uid: String=state.add_item("cloth_chest",2,"vigor"); state.inventory[uid].favorite=true; state.inventory[uid].custom_name="Listener's Ashweave"
		if "vigor" not in state.formulas: state.formulas.append("vigor")
		world.adventure.grant_materials({"resonant_ore":6,"ash_glass":4}); success=true; world.audio.sfx("quest")
	elif id=="accept" and subject=="keeper" and not p.accepted: p.accepted=true; success=true
	elif id=="ring" and subject in SONG and p.accepted and not p.activated:
		if p.song.size()<3 and subject==SONG[p.song.size()]: p.song.append(subject)
		else: p.song.clear()
		bell.pitch_scale=[.75,1.0,1.25][SONG.find(subject)]
		if world.audio.enabled: bell.play()
		success=true
	elif id=="cache" and subject in ["camp_cache","vault_cache"] and subject not in p.caches:
		p.caches.append(subject); world.adventure.grant_materials({"resonant_ore":4,"ash_glass":3,"crystal":2}); success=true
	elif id=="activate" and subject=="receiver" and p.accepted and p.song==SONG and not p.activated:
		if not state.can_pay({"resonant_ore":3,"crystal":2}): description.text="Repair needs 3 Resonant Ore and 2 crystals. Check the pilgrim or mason supply chest."; world.audio.sfx("error"); return false
		state.materials.resonant_ore-=3; state.materials.crystal-=2; p.activated=true; success=true; world.audio.sfx("quest")
	elif id=="record" and subject=="record" and p.activated and "choir_4" in p.defeated and not p.record: p.record=true; success=true
	elif id=="reward" and subject=="keeper" and p.record and not p.rewarded:
		p.rewarded=true; state.story_completed.append("choir"); state.blueprints.append("resonance"); state.gold+=160
		var uid: String=state.add_item("cantors_staff",2,"insight"); state.inventory[uid].favorite=true
		world.adventure.grant_materials({"resonant_ore":8,"ash_glass":6,"steel_ingot":5}); success=true
	if success:
		if id.begins_with("pilgrim_"): world.hud.world_map.selected_quest="side_ember_caldera"
		if id.begins_with("fire_"): world.hud.world_map.selected_quest="ashen_choir_3"
		if id.begins_with("memory_"): world.hud.world_map.selected_quest="ashen_choir_2"
		if id.begins_with("listener_"): world.hud.world_map.selected_quest="ashen_choir_1"
		state._commit()
		if id in ["pilgrim_shelter","pilgrim_depart"]:
			close_dialog(); world.player.set_paused(false); world.hud.announce("Leth is safe",pilgrim_objective())
		else: open_dialog(subject)
		if id.begins_with("listener_") and subject=="keeper":
			for child in options.get_children(): options.remove_child(child); child.queue_free()
			listener_dialog()
		if id.begins_with("memory_") and subject=="keeper":
			for child in options.get_children(): options.remove_child(child); child.queue_free()
			memory_dialog()
		if id.begins_with("fire_") and subject=="keeper":
			for child in options.get_children(): options.remove_child(child); child.queue_free()
			fire_dialog()
	return success
func can_damage_enemy(id: String) -> bool:
	return id!="choir_4" or state.choir.activated
func barrier_message() -> String:
	return "The unrepaired receiver shields the Dissonant Cantor"
func mark_defeated(id: String) -> void:
	if id not in state.choir.defeated: state.choir.defeated.append(id); state._commit()
func loot(id: String) -> bool:
	if id not in state.choir.defeated or id in state.choir.looted: return false
	state.choir.looted.append(id); state.gold+=25; world.adventure.grant_materials({"resonant_ore":3,"ash_glass":2})
	if id=="choir_4":
		var uid: String=state.add_item("resonance_blade",2,"fleet"); state.inventory[uid].favorite=true
	else: state.consumables.healing_draught=int(state.consumables.get("healing_draught",0))+1
	state._commit(); world.hud.announce("Resonant relics recovered","Resonant Ore and Ash Glass added to your collection."); return true
func objective() -> String:
	var p: Dictionary=state.choir
	if p.rewarded: return "Beacon frequency delivered · Follow the remaining convergence leads"
	if not p.accepted: return "Speak with Cantor Sereth at the pilgrim lodge"
	if p.song!=SONG: return "Ring the three resonators in inscription order · %d / 3" % p.song.size()
	if not p.activated: return "Repair the receiver · 3 Resonant Ore + 2 crystals"
	if not p.record: return "Defeat the Dissonant Cantor and copy the distress signal"
	return "Return the beacon frequency to Sereth"
func close_dialog() -> void:
	dialog.hide(); world.player.dialog_open=false
func check_fall() -> void:
	var p: Vector3=world.player.position-ORIGIN
	if p.y< -8 or absf(p.x)>42 or p.z< -83 or p.z>43: world.player.position=ORIGIN+Vector3(0,.2,40); world.player.velocity=Vector3.ZERO
func fire(origin: Vector3,direction: Vector3,damage: float,hostile: bool,source: CollisionObject3D,magic: bool) -> void:
	world.adventure.fire(origin,direction,damage,hostile,source,magic)
func line_clear(from: Vector3,to: Vector3,source: CollisionObject3D,target_body: CollisionObject3D=null) -> bool:
	return world.adventure.line_clear(from,to,source,target_body)
func _process(delta: float) -> void:
	if inside and not world.player.paused: vigil_time+=delta
	for id in PILGRIM_SHRINES:
		var done: bool=id in state.choir.get("listener_vigils",[])
		vigil_lights[id].material_override=world.blocks.materials["choir_signal" if done or vigil_cool(id) else "choir_lava"]
		vigil_labels[id].text="REMEMBERED" if done else "COOL · listen" if vigil_cool(id) else "VENTING · wait"
	preview_label.visible="--choir-preview" in OS.get_cmdline_user_args() and not world.player.paused
	if feedback_time>0: world.adventure.feedback=feedback; world.adventure.feedback_time=feedback_time; feedback_time=maxf(0,feedback_time-delta)

func vigil_cool(id: String) -> bool:
	return fmod(vigil_time+PILGRIM_SHRINES.find(id)*2.0,6.0)>=2.0
func listener_objective() -> String:
	var p: Dictionary=state.choir
	if p.get("listener_joined",false): return "Listener · Voices in the Furnace complete. The omitted pilgrims are remembered; your oath preserves their testimony."
	if not p.rewarded: return "Complete A Song Through the Stone, then ask Sereth about the ash pilgrimage."
	if not p.get("listener_started",false): return "Ask Sereth about the three vent vigils."
	if p.get("listener_vigils",[]).size()<3: return "Visit the three vigil shrines along the caldera path. Listen when each reads COOL · %d / 3." % p.get("listener_vigils",[]).size()
	if not p.get("listener_record",false): return "Read the omitted names beside the northern signal archive."
	return "Return to Sereth with the omitted names. Take the Listener oath if you wish to join."
func listener_dialog() -> void:
	var p: Dictionary=state.choir
	description.text=listener_objective()
	if subject=="keeper":
		if not p.rewarded or p.get("listener_joined",false): return
		if not p.get("listener_started",false):
			description.text="Sereth: Our pilgrimage teaches people to hear the mountain. Lately we have been very good at hearing only ourselves.\n\nVisit the three vent shrines. Wait for each roar to subside, then listen. Read the names behind the northern sanctuary afterward. Stay on the causeway; faith does not make good footwear."
			_button("Begin the three vigils","listener_start")
		elif p.get("listener_record",false):
			description.text="Sereth: Those pilgrims died sealing a failed awakening. Our old hymn called them volunteers. The roll says they begged us to stop.\n\nA Listener's oath must preserve testimony, even when it shames the Choir. You may leave without joining. Swear it, and receive 140 gold, Superior Vigor-enchanted robes, the Vigor formula, 6 Resonant Ore and 4 Ash Glass. Your Iron Pact standing is unchanged."
			_button("Swear to preserve the testimony · become Listener","listener_oath")
	elif subject in PILGRIM_SHRINES:
		if not p.get("listener_started",false): return
		description.text={"vigil_south":"Between the vent's breaths, a voice counts those entering the furnace. It counts people, not offerings.","vigil_middle":"In the silence you hear the order to seal the doors. Someone inside asks for more time.","vigil_north":"The last voice asks that their names survive. The official hymn ends before that verse."}[subject]+"\n\n"+("Vigil recorded." if subject in p.get("listener_vigils",[]) else "Wait for COOL before listening. The cycle pauses while this dialogue is open.")
		if subject not in p.get("listener_vigils",[]): _button("Listen during the cool interval","listener_wait")
	elif subject=="roll":
		description.text="THE OMITTED NAMES\n\nEris, furnace mason. Hal, bell keeper. Nema, water carrier. Eleven more names follow. Beside them: 'Sealed inside against their wishes. Do not call this consent.'\n\nThe vigils explain what the public hymn left out."
		if p.get("listener_vigils",[]).size()==3 and not p.get("listener_record",false): _button("Copy every name and the final testimony","listener_roll")
		else: description.text+="\n\n"+listener_objective()

func memory_objective() -> String:
	var p: Dictionary=state.choir
	if p.get("memory_choice","")!="": return "Cantor · Ash Remembers Everything complete. "+("The signed sealing order is public; the Choir must answer to the pilgrims' families." if p.memory_choice=="publish" else "The signed order is preserved privately; the public hymn still conceals the elders' responsibility.")
	if not p.get("listener_joined",false): return "Become a Listener before investigating the sealed awakening records."
	if not p.get("memory_started",false): return "Ask Sereth about the sealed awakening records."
	if int(p.get("memory_lock",0))<3: return "Open the sanctuary archive lock beyond the northern gate: mute, vent, release · %d / 3." % int(p.get("memory_lock",0))
	if not p.get("memory_record",false): return "Read the opened archive cabinet west of its pressure lock."
	return "Return the signed order to Sereth. Decide whether to publish or conceal the elders' responsibility."
func memory_dialog() -> void:
	var p: Dictionary=state.choir
	description.text=memory_objective()
	if subject=="keeper":
		if not p.get("listener_joined",false) or p.get("memory_choice","")!="": return
		if not p.get("memory_started",false):
			description.text="Sereth: The names tell us who died. The old archive may tell us who ordered it. Its pressure lock stands beyond the northern sanctuary gate.\n\nMute the signal, vent the pressure, then release the latch. The masons wrote it down. An unusual act of mercy for this institution."
			_button("Investigate the sealed sanctuary archive","memory_start")
		elif p.get("memory_record",false):
			description.text="Sereth: The elder council knew the doors would trap the pilgrims. Their signed order survives.\n\nPublish it and the families can challenge us. Keep it restricted and we preserve the evidence while letting the public hymn continue to lie. That would betray the spirit of your Listener oath.\n\nEither path grants Cantor rank, 180 gold, 8 Resonant Ore and 6 Ash Glass. Neither changes your Iron Pact standing. The decision is permanent."
			_button("Publish the order · Exquisite Insight staff","memory_publish")
			_button("Conceal the elders' responsibility · Exquisite Fleet blade","memory_conceal")
	elif subject=="memory_lock":
		if not p.get("memory_started",false): return
		description.text="ARCHIVE SAFETY PLATE\n\n1. Mute the signal.\n2. Vent the pressure.\n3. Release the latch.\n\nAn incorrect setting resets the lock without consuming supplies.\n\n"+memory_objective()
		if int(p.get("memory_lock",0))<3:
			_button("Mute the signal","memory_lock:mute")
			_button("Vent the pressure","memory_lock:vent")
			_button("Release the latch","memory_lock:release")
	elif subject=="memory_archive":
		if int(p.get("memory_lock",0))<3: return
		description.text="ELDER COUNCIL · SEALED ORDER\n\n'Close the furnace doors. Accept the loss of those within. Enter their names as willing offerings.'\n\nFour signatures follow. The pressure log records the pilgrims' appeals AFTER the order was received. The deaths were ordered, and the account was changed afterward."
		if not p.get("memory_record",false): _button("Copy the signed order and pressure log","memory_read")
		else: description.text+="\n\n"+memory_objective()

func fire_objective() -> String:
	var p: Dictionary=state.choir
	if p.get("fire_choice","")!="": return "Ember Voice · The Fire We Invite complete. "+{"awaken":"The bound ember serves a conquest oath. The Iron Pact's Clan Voice commission is permanently closed.","contain":"The ember remains under guard for study; the holds remain allies in containment.","silence":"The ember is extinguished. Its power will claim no more pilgrims."}[p.fire_choice]
	if p.get("memory_choice","")=="": return "Become Cantor before deciding the bound ember's future."
	if not p.get("fire_started",false): return "Ask Sereth about the bound ember beneath the sanctuary."
	if p.get("fire_seals",[]).size()<2: return "Defeat the sentinels guarding the west and east ember governors, then secure both controls · %d / 2." % p.get("fire_seals",[]).size()
	return "Decide the bound ember's future at its cradle beside the northern archive."
func fire_dialog() -> void:
	var p: Dictionary=state.choir
	description.text=fire_objective()
	if subject=="keeper" and p.get("memory_choice","")!="" and not p.get("fire_started",false):
		description.text="Sereth: A captive ember remains in the sanctuary. The elders hoped to make it a weapon. Secure both governors before deciding its fate. The sentinels still bound to those controls must fall first.\n\nThis is a remnant in a local cradle, not the great furnace. The expedition's seals must hold. We have enough historic mistakes without commissioning a larger edition."
		_button("Secure the ember governors","fire_start")
	elif subject in FIRE_SEALS:
		if not p.get("fire_started",false): return
		description.text="The governor can isolate the captive ember from the sanctuary's old commands.\n\n"+fire_objective()
		if FIRE_SEALS[subject] not in p.defeated: description.text+="\n\nThe nearby Ashbound Sentinel still controls this governor. Earlier defeats count."
		elif subject not in p.get("fire_seals",[]): _button("Isolate and secure this governor","fire_secure")
	elif subject=="fire_cradle" and p.get("fire_seals",[]).size()==2 and p.get("fire_choice","")=="":
		description.text="THE FIRE WE INVITE\n\nAwaken the captive ember for conquest, contain it under guard, or silence it permanently. Each grants Ember Voice rank, 250 gold, 10 Resonant Ore and 8 Ash Glass, plus Masterwork enchanted equipment.\n\nConquest permanently closes the Iron Pact's Clan Voice commission and mandate. If you already became Clan Voice, that oath rules out conquest. Your earlier ranks and equipment are retained.\n\nThe great furnace and the expedition's main story are unchanged. This choice is permanent."
		if int(state.mountain.rank)<3: _button("Awaken for conquest · Fleet blade · close Iron Pact finale","fire_choose:awaken")
		_button("Contain under guard · Insight staff","fire_choose:contain")
		_button("Silence the ember · Vigor amulet","fire_choose:silence")

func interaction_position(id: String) -> Vector3:
	if id=="pilgrim" and state.choir.get("pilgrim_choice","")!="": return ORIGIN+Vector3(-7,0,29)
	return ORIGIN+NODES[id]
func pilgrim_objective() -> String:
	var p: Dictionary=state.choir
	if p.get("pilgrim_choice","")!="": return "A Pilgrim's Empty Shoes complete · "+("Leth has temporary shelter without taking an oath." if p.pilgrim_choice=="shelter" else "Leth has supplies for a free departure and waits safely at camp.")
	return ["Read the missing-pilgrim notice beside the caldera entrance.","Inspect the abandoned shoes west of the central ash path.","Recover the hidden letter beside the eastern sanctuary wall. Defeat the nearby Ashbound Sentinel first.","Find Leth east of the central path, opposite the abandoned shoes. Help without forcing an oath."][int(p.get("pilgrim_stage",0))]
func pilgrim_dialog() -> void:
	var p: Dictionary=state.choir
	var stage: int=int(p.get("pilgrim_stage",0))
	description.text=pilgrim_objective()
	if subject=="pilgrim_notice" and stage==0:
		description.text="MISSING: LETH, PILGRIM\n\nLast seen carrying a change of clothes toward the ash paths. Shoes found near the vents. Some fear a sacrifice. Someone has already requested a memorial donation. Please find the pilgrim before the collection plate."
		_button("Investigate the missing pilgrim","pilgrim_start")
	elif subject=="empty_shoes":
		description.text="The shoes are set neatly outside the hot ground. Their soles are intact. Beside them, fresh bootprints cross toward the eastern wall. Whoever left these changed footwear before disappearing."
		if stage==1: _button("Follow the bootprints toward the eastern wall","pilgrim_shoes")
		else: description.text+="\n\n"+pilgrim_objective()
	elif subject=="escape_note":
		description.text="'I will not swear. If they think the mountain took me, perhaps they will stop asking. I left the shoes, bought boots and hid near the east path. I want to live somewhere a quiet morning is not evidence of insufficient devotion. — Leth'"
		if stage==2 and "choir_1" in p.defeated: _button("Recover Leth's letter and hiding place","pilgrim_letter")
		elif stage==2: description.text+="\n\nThe Ashbound Sentinel on the eastern approach still guards the letter."
		else: description.text+="\n\n"+pilgrim_objective()
	elif subject=="pilgrim":
		if p.get("pilgrim_choice","")!="": description.text="Leth: Thank you for asking where I wanted to go. Everyone else began with where I belonged.\n\n"+pilgrim_objective()
		elif stage<3: description.text="Leth: I am not ready to explain. Read what I left by the eastern wall first.\n\n"+pilgrim_objective()
		else:
			description.text="Leth: No sacrifice. I staged the shoes so nobody would drag me back to an oath I never wanted. A poor plan, but the boots were excellent.\n\nI will accept temporary shelter if it comes without vows, or supplies to leave freely. I can wait safely at camp either way.\n\nBoth choices grant 100 gold and a Superior Fleet-enchanted Ring of Swiftness."
			_button("Arrange shelter without an oath · 8 herbs, 6 water","pilgrim_shelter")
			_button("Supply a free departure · 6 Resonant Ore, 4 Ash Glass","pilgrim_depart")

func interaction_name(id: String) -> String:
	return "Leth · safe at camp" if id=="pilgrim" and state.choir.get("pilgrim_choice","")!="" else NAMES[id]
