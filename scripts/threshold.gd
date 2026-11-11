extends Node3D
const State=preload("res://scripts/character_state.gd")
const Visual=preload("res://scripts/character_visual.gd")
const Enemy=preload("res://scripts/enemy.gd")
const ORIGIN=Vector3(2240,0,0)
const TRAIL=Vector3(1193,0,-62)
const HOME=Vector3(48,.2,20)
const NODES={"return":Vector3(0,0,40),"keeper":Vector3(-10,0,25),"forge":Vector3(10,0,26),"enchant":Vector3(16,0,26),"locker":Vector3(-16,0,32),"cargo":Vector3(15,0,-31),"power":Vector3(-12,0,-13),"air":Vector3(12,0,-25),"record":Vector3(0,0,-72)}
const NAMES={"return":"Return beacon · Frostmere","keeper":"Station engineer Rook","forge":"Fabrication bench","enchant":"Signal inscription table","locker":"Emergency equipment locker","cargo":"Cargo salvage crate","power":"Reactor isolation control","air":"Life-support restart","record":"Command archive"}
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
func _ready() -> void:
	state=world.player.character; _build(); _ui(); state.changed.connect(_refresh); _refresh()
func box(p: Vector3,size: Vector3,key: String,solid: bool=false,angle: float=0) -> void:
	world.blocks.add(key,ORIGIN+p,size,angle)
	if solid: world._solid(ORIGIN+p,size)
func _build() -> void:
	var b: RefCounted=world.blocks
	for entry in [["station_plate","566776"],["station_floor","354552"],["station_light","91dbe4"],["station_red","d97c5e"],["planet","678daa"]]:
		var mat: StandardMaterial3D=b.materials["window" if entry[0] in ["station_light","station_red"] else "iron"].duplicate(); mat.albedo_color=Color(entry[1])
		if mat.emission_enabled: mat.emission=Color(entry[1]); mat.emission_energy_multiplier=.6
		b.materials[entry[0]]=mat
	world._solid(ORIGIN+Vector3(0,-.5,-20),Vector3(40,1,128),"metal")
	for x in range(-20,20):
		for z in range(-84,44): box(Vector3(x+.5,.03,z+.5),Vector3(.96,.06,.96),"station_floor" if abs(x)>2 else "iron")
	for side in [-1,1]:
		box(Vector3(side*20,4,-20),Vector3(.5,8,128),"station_plate",true)
		for rib in range(26):
			box(Vector3(side*19.6,4,-82+rib*5),Vector3(.4,8,.35),"iron")
			box(Vector3(side*18.8,6.8,-82+rib*5),Vector3(.3,.2,2.5),"station_light")
		for z in [8,-43]:
			box(Vector3(side*12,3.5,z),Vector3(16,7,.6),"station_plate",true)
			for row in range(12): box(Vector3(side*12,.3+row*.55,z+.35),Vector3(15.6,.08,.12),"iron")
		box(Vector3(side*15,4,-83),Vector3(10,8,.5),"station_plate",true)
	box(Vector3(0,4,43),Vector3(40,8,.5),"station_plate",true)
	box(Vector3(0,8,-20),Vector3(40,.4,128),"station_floor",true)
	# Observation window: physical pane and a voxel planet beyond the hull.
	world._solid(ORIGIN+Vector3(0,4,-83),Vector3(20,8,.3))
	for x in [-10,0,10]: box(Vector3(x,4,-82.8),Vector3(.3,8,.3),"iron")
	for y in [0,8]: box(Vector3(0,y,-82.8),Vector3(20,.3,.3),"iron")
	for x in range(-12,13):
		for y in range(-12,13):
			if x*x+y*y<=144: box(Vector3(x,9+y,-112+sqrt(maxf(0,144-x*x-y*y))*.4),Vector3(.98,.98,.98),"planet" if (x+y)%5 else "fur")
	for i in range(150): box(Vector3(sin(i*23.1)*80,cos(i*17.3)*45,-130),Vector3(.13,.13,.13),"station_light")
	gate=StaticBody3D.new(); gate.position=ORIGIN+Vector3(0,3.5,-43); add_child(gate)
	var collision:=CollisionShape3D.new(); var shape:=BoxShape3D.new(); shape.size=Vector3(8,7,.6); collision.shape=shape; gate.add_child(collision); b.piece(gate,"station_red",Vector3.ZERO,shape.size)
	for id: String in NODES:
		var p: Vector3=NODES[id]; _sign(ORIGIN+p+Vector3.UP*2,NAMES[id])
		if id=="keeper":
			var npc:=Visual.new(); npc.position=ORIGIN+p; npc.rotation.y=PI; add_child(npc)
			var model:=State.new()
			for slot in ["head","chest","hands","legs","feet"]: model.equip(model.add_item("steel_"+slot),slot)
			npc.build(model)
		elif id!="return":
			box(p+Vector3.UP*.5,Vector3(1.5,1,1),"station_plate",true)
			box(p+Vector3.UP*1.05,Vector3(1.6,.12,1.1),"iron")
		if id in ["power","air"]: lights[id]=b.piece(self,"station_red",ORIGIN+p+Vector3(0,1.3,0),Vector3(.8,.3,.5))
	for i in range(8):
		var p:=Vector3(-15+(i%2)*30,0,-5-i*8)
		box(p+Vector3.UP*.9,Vector3(2.5,1.8,2),"station_plate",true)
		for strip in range(4): box(p+Vector3(-.9+strip*.6,1.85,0),Vector3(.15,.15,2),"iron")
	record_mesh=b.piece(self,"station_light",ORIGIN+NODES.record+Vector3.UP*1.6,Vector3(2,1,.1))
	# Recessed equipment racks, status strips and cable runs break up the hull panels.
	for side in [-1,1]:
		for z in [30,19,-7,-20,-34,-53,-67]:
			box(Vector3(side*19.5,2.6,z),Vector3(.3,2.4,3.6),"coal")
			for strip in range(7): box(Vector3(side*19.25,1.8+strip*.25,z),Vector3(.12,.08,2.8 if strip%3 else 1.6),"station_light" if strip%3 else "station_red")
		for tube in range(3): box(Vector3(side*(18.8-tube*.25),7.7,-20),Vector3(.15,.15,126),"iron")
	for x in [-7,7]:
		box(Vector3(x,1,-75),Vector3(3,2,1.5),"station_plate")
		box(Vector3(x,2.1,-75),Vector3(2.5,.12,1.2),"station_light")
	for z in [32,16,-4,-24,-50,-70]:
		var lamp:=OmniLight3D.new(); lamp.position=ORIGIN+Vector3(0,6,z); lamp.light_color=Color("b3d2ed"); lamp.light_energy=.8; lamp.omni_range=24; add_child(lamp)
	for side in [-1,1]: b.add("station_plate",TRAIL+Vector3(side*1.4,1.6,0),Vector3(.4,3.2,.6))
	b.add("station_plate",TRAIL+Vector3.UP*3.2,Vector3(3.2,.4,.6))
	b.add("station_light",TRAIL+Vector3.UP*1.5,Vector3(2.4,2.8,.08))
	preload("res://scripts/landmark_architecture.gd").station(self)
	world.block_count+=b.finish(world); _sign(TRAIL+Vector3.UP*2,"First Threshold · station crossing")
	var positions=[Vector3(-8,0,-4),Vector3(9,0,-17),Vector3(-9,0,-31),Vector3(-9,0,-52),Vector3(10,0,-60),Vector3(0,0,-69)]
	for i in range(6):
		var enemy=preload("res://scripts/hullcarver.gd").new() if i==5 else Enemy.new(); enemy.adventure=self; enemy.progress=state.threshold; enemy.enemy_id="threshold_"+str(i); enemy.role="boss" if i==5 else "archer"
		enemy.title="Hullcarver Broodmother" if i==5 else "Rogue Station Trooper"; enemy.health_override=380 if i==5 else 100; enemy.position=ORIGIN+positions[i]+Vector3.UP*.15
		enemy.armor_override="steel"; enemy.weapon_override="station_rifle"; add_child(enemy); enemies.append(enemy)
func _sign(p: Vector3,label: String) -> void:
	var sign:=Label3D.new(); sign.position=p; sign.text=label; sign.font_size=22; sign.pixel_size=.003; sign.billboard=BaseMaterial3D.BILLBOARD_ENABLED; sign.visibility_range_begin=4.5; sign.visibility_range_end=18; add_child(sign)
func _ui() -> void:
	var layer:=CanvasLayer.new(); layer.layer=7; add_child(layer)
	preview_label=Label.new(); preview_label.position=Vector2(32,76); preview_label.text="FIRST THRESHOLD PREVIEW · progress is not saved"; layer.add_child(preview_label)
	dialog=ColorRect.new(); dialog.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); dialog.color=Color("1f2732"); layer.add_child(dialog)
	var center:=CenterContainer.new(); center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); dialog.add_child(center)
	var col:=VBoxContainer.new(); col.custom_minimum_size.x=720; col.add_theme_constant_override("separation",16); center.add_child(col)
	title=Label.new(); title.add_theme_font_size_override("font_size",25); col.add_child(title)
	description=Label.new(); description.custom_minimum_size=Vector2(720,230); description.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART; description.add_theme_font_size_override("font_size",18); col.add_child(description)
	options=VBoxContainer.new(); col.add_child(options)
	var close:=Button.new(); close.text="Return [ Esc ]"; close.custom_minimum_size.y=42; close.pressed.connect(func(): close_dialog(); world.player.set_paused(false)); col.add_child(close); dialog.hide()
func _button(label: String,id: String) -> void:
	var button:=Button.new(); button.text=label; button.custom_minimum_size.y=42; button.pressed.connect(func(): act(id)); options.add_child(button)
func enter() -> bool:
	if world.player.paused or "convergence" not in state.story_completed: return false
	if inside: return true
	for chapter in [world.seal,world.winter,world.convergence,world.choir,world.lens,world.roots,world.shore,world.archive_chapter,world.mountain,world.realms,world.adventure]:
		if chapter.inside: chapter.leave()
	inside=true; world.player.position=ORIGIN+Vector3(0,.2,40); world.player.velocity=Vector3.ZERO; world.player.rotation=Vector3.ZERO
	for child in world.get_children():
		if child is WorldEnvironment:
			environment_backup=child.environment
			var env: Environment=environment_backup.duplicate(true); env.background_mode=Environment.BG_COLOR; env.background_color=Color("070c15"); env.fog_light_color=Color("344859"); env.fog_density=.001; env.ambient_light_color=Color("c0d4ea"); child.environment=env
	world.hud.world_map.selected_quest="threshold"; world.hud.world_map.set_view(true); world.audio.sfx("portal")
	world.hud.announce("Beyond the First Threshold","Your return beacon holds. Rook waits in the station airlock."); return true
func leave() -> void:
	if not inside: return
	inside=false; world.adventure.clear_projectiles(); world.player.position=HOME; world.player.velocity=Vector3.ZERO
	for child in world.get_children():
		if child is WorldEnvironment and environment_backup!=null: child.environment=environment_backup
	for enemy in enemies:
		if not enemy.dead: enemy.position=enemy.home; enemy.health=enemy.maximum_health; enemy.velocity=Vector3.ZERO; enemy.windup=0; enemy._update_label()
func nearest() -> Dictionary:
	if not inside:
		if world.lens.inside and world.player.position.distance_to(TRAIL)<2.5: return {"kind":"threshold","id":"trail","text":"[ E ] Travel to the orbital station"}
		return {}
	for enemy in enemies:
		if enemy.dead and enemy.enemy_id not in state.threshold.looted and world.player.position.distance_to(enemy.position)<2.5: return {"kind":"threshold","id":enemy.enemy_id,"text":"[ E ] Recover station salvage"}
	for id: String in NODES:
		if world.player.position.distance_to(ORIGIN+NODES[id])<2.3: return {"kind":"threshold","id":id,"text":"[ E ] "+NAMES[id]}
	return {}
func station_nearby() -> String:
	for id in ["forge","enchant"]:
		if inside and world.player.position.distance_to(ORIGIN+NODES[id])<2.3: return id
	return ""
func interact(id: String) -> void:
	if world.player.paused or nearest().get("id","")!=id: return
	if id=="trail":
		if not enter(): world.hud.announce("The First Threshold","Complete The Roads Converge at Mirewatch to use this crossing.")
	elif id=="return":
		if state.threshold.record and not state.threshold.rewarded: reward()
		leave()
	elif id in ["forge","enchant"]: world.hud.workshop.open(id)
	elif id.begins_with("threshold_"): loot(id)
	else: open_dialog(id)
func _refresh() -> void:
	gate.visible=not state.threshold.air; gate.collision_layer=0 if state.threshold.air else 1
	record_mesh.visible=not state.threshold.record
	for id: String in ["power","air"]: lights[id].material_override=world.blocks.materials["station_light" if state.threshold[id] else "station_red"]
func open_dialog(id: String) -> void:
	subject=id; world.player.dialog_open=true; world.player.set_paused(true); dialog.show()
	for child in options.get_children(): options.remove_child(child); child.queue_free()
	title.text=NAMES[id].to_upper()
	var p: Dictionary=state.threshold
	if id=="keeper":
		description.text="ROOK · STATION ENGINEER\n\nYou answered the beacon. A hull-boring broodmother nested in command and severed the security link. The troopers turned on us. Security has never been this efficient at removing staff. The airlock is safe, but the command deck is sealed. Isolate the reactor first, then restart life support. The automated shutters will open.\n\nAn emergency rifle, ammunition, arrows and magicka draughts are in the locker. Keep your own fighting style if you prefer; the fabrication bench can make more. Ammunition, that is. We’re down to one engineer. Defeat the Hullcarver Broodmother — dodge its plasma spit, then strike the exposed green core — and recover the command archive, then carry it home through your return beacon."
		if not p.accepted: _button("Help restore the station","accept")
		description.text+="\n\n"+objective()
	elif id=="locker":
		description.text="An emergency Station Rifle, 120 Station Rounds, 6 Station Alloy and 3 Navigation Cells. The traveler reserve also holds 36 arrows and 2 Magicka Draughts. Collecting the kit also teaches station equipment and ammunition recipes. Equip the rifle from your inventory; it uses Station Rounds, not infernal ammunition."
		if not p.locker: _button("Take the emergency kit and fabrication patterns","locker")
		else: description.text+="\n\nAlready collected."
	elif id=="cargo":
		description.text="Cargo salvage: 80 Station Rounds, 8 Station Alloy, 4 Navigation Cells, 24 arrows and 1 Magicka Draught."
		if not p.cargo: _button("Collect cargo salvage","cargo")
		else: description.text+="\n\nAlready collected."
	elif id=="power":
		description.text="The reactor is feeding the broken transit regulator. Isolate that circuit to restore local station power. The repair does not require fuel from the furnace or living land."
		if not p.accepted: description.text+="\nSpeak with Rook first."
		elif not p.power: _button("Isolate damaged transit circuit","power")
		else: description.text+="\n\nLocal power is stable."
	elif id=="air":
		description.text="Restart life support after restoring power. This releases the command shutters and reactivates security on the command deck."
		if not p.power: description.text+="\n\nThe reactor isolation control must be used first."
		elif not p.air: _button("Restart life support · open command deck","air")
		else: description.text+="\n\nCommand deck is open."
	elif id=="record":
		description.text="COMMAND ARCHIVE\n\nThe watchstones on your world are losing their light. The station's return regulator cannot replenish them. A Dawn Prism in Aeralis can stabilize the network; its crystal-winged guardian has fractured into a dangerous wyrm.\n\nThe archive contains the coordinates needed to unseal the crystal crossing in Frostmere. The furnace seal must remain intact."
		if "threshold_5" not in p.defeated: description.text="The Hullcarver Broodmother still guards the command archive."
		elif not p.record: _button("Copy the archive and Aeralis coordinates","record")
		else: description.text+="\n\nCarry the findings through the return beacon to complete the expedition."
func act(id: String) -> bool:
	if not dialog.visible or not inside or not NODES.has(subject) or world.player.position.distance_to(ORIGIN+NODES[subject])>=2.3: return false
	var p: Dictionary=state.threshold
	var success:=false
	if id=="accept" and subject=="keeper" and not p.accepted: p.accepted=true; success=true
	elif id=="locker" and subject=="locker" and not p.locker:
		p.locker=true; state.add_item("station_rifle",1); state.blueprints.append("station"); world.adventure.grant_materials({"station_round":120,"station_alloy":6,"navigation_cell":3,"arrow":36}); state.consumables.magicka_draught=int(state.consumables.get("magicka_draught",0))+2; success=true
	elif id=="cargo" and subject=="cargo" and not p.cargo:
		p.cargo=true; world.adventure.grant_materials({"station_round":80,"station_alloy":8,"navigation_cell":4,"arrow":24}); state.consumables.magicka_draught=int(state.consumables.get("magicka_draught",0))+1; success=true
	elif id=="power" and subject=="power" and p.accepted and not p.power: p.power=true; success=true; world.audio.sfx("forge")
	elif id=="air" and subject=="air" and p.power and not p.air: p.air=true; success=true; world.audio.sfx("portal")
	elif id=="record" and subject=="record" and p.air and "threshold_5" in p.defeated and not p.record: p.record=true; success=true
	if success: state._commit(); open_dialog(subject)
	return success
func reward() -> bool:
	if not inside or world.player.position.distance_to(ORIGIN+NODES["return"])>=2.3 or not state.threshold.record or state.threshold.rewarded: return false
	state.threshold.rewarded=true; state.story_completed.append("threshold"); state.gold+=200
	var uid: String=state.add_item("station_chest",2,"vigor"); state.inventory[uid].favorite=true
	if "station" not in state.blueprints: state.blueprints.append("station")
	world.adventure.grant_materials({"station_alloy":8,"navigation_cell":6,"station_round":100}); state._commit()
	world.hud.announce("The expedition returns","Aeralis is now reachable through Frostmere's crystal crossing. Recover its Dawn Prism."); return true
func can_damage_enemy(id: String) -> bool:
	return id in ["threshold_0","threshold_1","threshold_2"] or state.threshold.air
func barrier_message() -> String:
	return "Restore station systems before confronting command-deck security"
func mark_defeated(id: String) -> void:
	if id not in state.threshold.defeated: state.threshold.defeated.append(id); state._commit()
func loot(id: String) -> bool:
	if id not in state.threshold.defeated or id in state.threshold.looted: return false
	state.threshold.looted.append(id); state.gold+=25; world.adventure.grant_materials({"station_alloy":3,"navigation_cell":2,"station_round":30})
	if id=="threshold_5":
		var uid: String=state.add_item("void_cutter",2,"fleet"); state.inventory[uid].favorite=true
	else: state.consumables.healing_draught=int(state.consumables.get("healing_draught",0))+1
	state._commit(); world.hud.announce("Station salvage recovered","Fabrication materials and ammunition added to your bag."); return true
func objective() -> String:
	var p: Dictionary=state.threshold
	if p.rewarded: return "Expedition complete · Aeralis crystal crossing unlocked in Frostmere"
	if not p.accepted: return "Speak with engineer Rook in the airlock"
	if not p.power: return "Isolate the reactor circuit · emergency rifle in the airlock locker"
	if not p.air: return "Restart life support to open the command deck"
	if not p.record: return "Defeat the Hullcarver Broodmother and recover the command archive"
	return "Return through the airlock beacon with the Aeralis coordinates"
func close_dialog() -> void:
	dialog.hide(); world.player.dialog_open=false
func check_fall() -> void:
	var p: Vector3=world.player.position-ORIGIN
	if p.y< -8 or absf(p.x)>21 or p.z< -84 or p.z>44: world.player.position=ORIGIN+Vector3(0,.2,40); world.player.velocity=Vector3.ZERO
func fire(origin: Vector3,direction: Vector3,damage: float,hostile: bool,source: CollisionObject3D,magic: bool) -> void:
	world.adventure.fire(origin,direction,damage,hostile,source,magic)
func line_clear(from: Vector3,to: Vector3,source: CollisionObject3D,target_body: CollisionObject3D=null) -> bool:
	return world.adventure.line_clear(from,to,source,target_body)
func _process(delta: float) -> void:
	preview_label.visible="--threshold-preview" in OS.get_cmdline_user_args() and not world.player.paused
	if feedback_time>0: world.adventure.feedback=feedback; world.adventure.feedback_time=feedback_time; feedback_time=maxf(0,feedback_time-delta)
