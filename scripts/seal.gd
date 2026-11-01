extends Node3D
const State=preload("res://scripts/character_state.gd")
const Visual=preload("res://scripts/character_visual.gd")
const Enemy=preload("res://scripts/enemy.gd")
const ORIGIN=Vector3(2720,0,0)
const TRAIL=Vector3(12,0,34)
const REQUIRED=["winter_siege"]
const NODES={"return":Vector3(0,0,36),"keeper":Vector3(-10,0,27),"forge":Vector3(10,0,26),"enchant":Vector3(16,0,26),"supplies":Vector3(-5,0,29),"intake":Vector3(-12,0,-8),"exhaust":Vector3(12,0,-20),"plans":Vector3(0,0,-40),"seal":Vector3(0,0,-57),"crossing":Vector3(0,0,-65)}
const NAMES={"return":"Service lift · Frostmere","keeper":"Wardwright Tovan","forge":"Wardwright's forge","enchant":"Inscription bench","supplies":"Wardwright's supplies","intake":"Intake isolation valve","exhaust":"Exhaust isolation valve","plans":"Furnace shipping ledger","seal":"Fractured containment seal","crossing":"Descent to the Crucible"}
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
	for entry in [["seal_ember","db793d"],["seal_ward","87d3cc"]]:
		var mat: StandardMaterial3D=b.materials["window"].duplicate(); mat.albedo_color=Color(entry[1]); mat.emission=Color(entry[1]); mat.emission_energy_multiplier=.8; b.materials[entry[0]]=mat
	box(Vector3(0,-.4,-15),Vector3(44,.8,112),"stone_dark",true)
	box(Vector3(0,9,-15),Vector3(44,1,112),"stone_dark",true)
	for side in [-1,1]:
		box(Vector3(side*22,4,-15),Vector3(2,9,112),"stone_dark",true)
		for z in range(-67,40,4):
			box(Vector3(side*20.8,3,z),Vector3(.6,6,.8),"iron")
			box(Vector3(side*20.3,5.5,z),Vector3(.2,.5,1),"seal_ember")
		box(Vector3(side*18,6,-15),Vector3(1,1,104),"iron")
		for z in [-48,-32,-16,0,16,32]:
			for row in range(8): box(Vector3(side*21,.5+row*.6,z),Vector3(.2,.5,3.8),"stone")
		for z in [-35,-3,17]:
			box(Vector3(side*17,1.4,z),Vector3(3,2.8,3),"iron",true)
			for row in range(5): box(Vector3(side*17,.5+row*.4,z+1.55),Vector3(2.5,.12,.12),"seal_ember")
	for z in range(-67,39):
		for x in range(-5,6): box(Vector3(x,.03,z),Vector3(.94,.08,.94),"iron" if z<0 else "stone")
	# Riveted deck seams and masonry frame the clear central walking route.
	for z in range(-67,38,2):
		box(Vector3(0,.09,z),Vector3(11,.025,.12),"stone_dark")
		for x in [-4.7,4.7]: box(Vector3(x,.11,z+.4),Vector3(.12,.06,.12),"gold")
	for z in [10,-27,-48]:
		for side in [-1,1]:
			for row in range(10):
				for col in range(12): box(Vector3(side*(6.5+col*1.25),.3+row*.6,z+.76),Vector3(1.16,.51,.12),"stone")
		for side in [-1,1]: box(Vector3(side*14,3,z),Vector3(16,6,1.4),"stone_dark",true)
		box(Vector3(0,6.3,z),Vector3(44,.6,1.8),"iron")
	for z in [-69,40]: box(Vector3(0,4,z),Vector3(44,8,1),"stone_dark",true)
	for id: String in NODES:
		var p: Vector3=NODES[id]; _sign(ORIGIN+p+Vector3.UP*2,NAMES[id])
		if id=="keeper":
			var npc:=Visual.new(); npc.position=ORIGIN+p; npc.rotation.y=PI; add_child(npc)
			var model:=State.new()
			for slot in ["head","chest","hands","legs","feet"]: model.equip(model.add_item("cloth_"+slot),slot)
			npc.build(model)
		elif id not in ["return","crossing"]: box(p+Vector3.UP*.5,Vector3(1.7,1,1.2),"wood" if id=="supplies" else "stone_dark")
		if id in ["intake","exhaust"]:
			box(p+Vector3.UP*1.4,Vector3(1.1,.2,.2),"iron")
			box(p+Vector3.UP*1.4,Vector3(.2,1.1,.2),"iron")
			lights[id]=b.piece(self,"seal_ember",ORIGIN+p+Vector3(0,2,0),Vector3(.3,.3,.3))
		if id=="forge": box(p+Vector3.UP*1.1,Vector3(1.2,.3,.5),"iron")
		if id in ["plans","enchant"]: box(p+Vector3.UP*1.1,Vector3(1,.12,.8),"fur")
	for side in [-1,1]:
		box(Vector3(side*3,2.5,-65),Vector3(1,5,1),"iron",true)
		for step in range(9): box(Vector3(side*(3-step*.33),5+sin(step*.18),-65),Vector3(.4,.4,1),"seal_ember")
	lights["seal"]=b.piece(self,"seal_ember",ORIGIN+NODES.seal+Vector3.UP*1.7,Vector3(.9,1,.9))
	lights["crossing"]=b.piece(self,"seal_ward",ORIGIN+NODES.crossing+Vector3.UP*2.3,Vector3(4,4,.12))
	for p in [Vector3(-5,0,33),Vector3(5,0,14),Vector3(-6,0,-25),Vector3(6,0,-46)]: world._lantern(ORIGIN+p,false)
	world.block_count+=b.finish(world); _sign(TRAIL+Vector3.UP*2,"The Broken Seal · Caldera service lift")
	var positions=[Vector3(-6,0,-2),Vector3(6,0,-14),Vector3(-7,0,-33),Vector3(7,0,-36),Vector3(0,0,-51)]
	for i in range(5):
		var enemy:=Enemy.new(); enemy.adventure=self; enemy.progress=state.seal; enemy.enemy_id="seal_"+str(i); enemy.role="boss" if i==4 else "archer" if i%2 else "guard"
		enemy.title="The Sealbreaker" if i==4 else "Furnace Enforcer"; enemy.health_override=420 if i==4 else 150; enemy.position=ORIGIN+positions[i]+Vector3.UP*.15
		add_child(enemy); enemies.append(enemy)
func ready_for_expedition() -> bool:
	for id in REQUIRED:
		if id not in state.story_completed: return false
	return true
func _sign(p: Vector3,label: String) -> void:
	var sign:=Label3D.new(); sign.position=p; sign.text=label; sign.font_size=22; sign.pixel_size=.003; sign.billboard=BaseMaterial3D.BILLBOARD_ENABLED; sign.visibility_range_begin=4.5; sign.visibility_range_end=18; add_child(sign)
func _ui() -> void:
	var layer:=CanvasLayer.new(); layer.layer=7; add_child(layer)
	preview_label=Label.new(); preview_label.position=Vector2(32,76); preview_label.text="BROKEN SEAL PREVIEW · progress is not saved"; layer.add_child(preview_label)
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
	for chapter in [world.winter,world.threshold,world.convergence,world.choir,world.lens,world.roots,world.shore,world.archive_chapter,world.mountain,world.realms,world.adventure]:
		if chapter.inside: chapter.leave()
	inside=true; world.player.position=ORIGIN+Vector3(0,.2,36); world.player.velocity=Vector3.ZERO; world.player.rotation=Vector3.ZERO
	for child in world.get_children():
		if child is WorldEnvironment:
			environment_backup=child.environment
			var env: Environment=environment_backup.duplicate(true); env.background_mode=Environment.BG_COLOR; env.background_color=Color("302824"); env.fog_light_color=Color("90664b"); env.fog_density=.004; env.ambient_light_color=Color("c8b7a2"); child.environment=env
	world.hud.world_map.selected_quest="broken_seal"; world.hud.world_map.set_view(true); world.audio.sfx("portal")
	world.hud.announce("The Broken Seal","Follow the furnace supply line. Tovan waits beside the service lift."); return true
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
		if world.player.position.distance_to(TRAIL)<2.5: return {"kind":"seal","id":"trail","text":"[ E ] Travel beneath Ember Caldera"}
		return {}
	for enemy in enemies:
		if enemy.dead and enemy.enemy_id not in state.seal.looted and world.player.position.distance_to(enemy.position)<2.5: return {"kind":"seal","id":enemy.enemy_id,"text":"[ E ] Search the invader"}
	for id: String in NODES:
		if world.player.position.distance_to(ORIGIN+NODES[id])<2.3: return {"kind":"seal","id":id,"text":"[ E ] "+NAMES[id]}
	return {}
func station_nearby() -> String:
	for id in ["forge","enchant"]:
		if inside and world.player.position.distance_to(ORIGIN+NODES[id])<2.3: return id
	return ""
func interact(id: String) -> void:
	if world.player.paused or nearest().get("id","")!=id: return
	if id=="trail":
		if not enter(): world.hud.announce("The expedition road","Defend Northwatch and recover the invasion orders before taking this lift.")
	elif id=="return": leave()
	elif id in ["forge","enchant"]: world.hud.workshop.open(id)
	elif id=="crossing":
		if not state.seal.rewarded: world.hud.announce("Containment active","Bind the ward and report to Tovan before descending.")
		else: world.realms.enter("crucible",false)
	elif id.begins_with("seal_"): loot(id)
	else: open_dialog(id)
func _refresh() -> void:
	for id in ["intake","exhaust"]: lights[id].material_override=world.blocks.materials["seal_ward" if id in state.seal.valves else "seal_ember"]
	lights.seal.material_override=world.blocks.materials["seal_ward" if state.seal.bound else "seal_ember"]
	lights.crossing.visible=state.seal.rewarded
	for enemy in enemies:
		var active:=can_damage_enemy(enemy.enemy_id)
		enemy.visible=active or enemy.dead; enemy.collision_layer=4 if active and not enemy.dead else 0; enemy._update_label()
func open_dialog(id: String) -> void:
	subject=id; world.player.dialog_open=true; world.player.set_paused(true); dialog.show()
	for child in options.get_children(): options.remove_child(child); child.queue_free()
	title.text=NAMES[id].to_upper()
	var p: Dictionary=state.seal
	if id=="keeper":
		description.text="TOVAN · THE WARDWRIGHT\n\nThe marshal's orders trace the invasion to this furnace supply line. Its engines have been weakening the old containment seal. Isolate both pressure valves, clear the enforcers and recover their ledger.\n\nThe ledger contains a containment design. Forge a Cinder Ward, defeat the Sealbreaker and bind the ward into the fractured seal. Then we can descend without opening a road for the invasion to follow us home."
		if not p.accepted: _button("Investigate the furnace supply line","accept")
		if p.bound and not p.rewarded: _button("Report containment restored · prepare the descent","reward")
		if p.rewarded: description.text="TOVAN · THE ROAD BELOW\n\nThe ward is bound into the threshold. You can carry weapons and relics back through it while the invasion remains contained. The northern crossing now leads to the Crucible. Attune at its arrival forge, defeat its warden and bring the final furnace to a halt."
		description.text+="\n\n"+objective()
	elif id=="supplies":
		description.text="Reserved stock: 8 steel, 8 crystals, 4 rune dust and 4 Ash Glass. Enough to forge two Cinder Wards. The ward's design is in the shipping ledger beyond the pressure controls. Separate combat reserves: 60 arrows, 120 Station Rounds and 3 Magicka Draughts."
		if p.accepted and not p.supplies: _button("Collect the wardwright's supplies","supplies")
		elif p.supplies: description.text+="\n\nAlready collected."
		if state.story_recovery_available("cinder_ward"):
			description.text+="\n\nThe wardwright kept a damaged containment assembly. With the recovered design, you can rebuild one Cinder Ward even if you spent the shared ingredients. Its dedicated parts cannot be sold or salvaged for upgrades."
			_button("Rebuild 1 Cinder Ward from spare parts","recover_component")
		elif int(state.materials.get("cinder_ward",0))>0 and not p.bound:
			description.text+="\n\nYour Cinder Ward is ready. Defeat the Sealbreaker, then bind it into the fractured seal."
	elif id in ["intake","exhaust"]:
		description.text="Isolate this pressure line after defeating its assigned enforcer. Both lines must be closed before the inner guards can be confronted."
		var guard: String="seal_0" if id=="intake" else "seal_1"
		if guard in p.defeated and id not in p.valves: _button("Isolate the pressure line","valve")
		elif id in p.valves: description.text+="\n\nPressure line isolated."
	elif id=="plans":
		description.text="The ledger reveals the invasion's supply route and a containment pattern. Defeat both inner enforcers before taking it."
		if "seal_2" in p.defeated and "seal_3" in p.defeated and not p.plans: _button("Recover the ledger · learn Cinder Ward recipe","plans")
		elif p.plans: description.text+="\n\nForge a Cinder Ward: 4 steel, 4 crystals, 2 rune dust and 2 Ash Glass."
	elif id=="seal":
		description.text="The ward must be bound here after defeating the Sealbreaker. Binding consumes one forged Cinder Ward and creates a permanent protected crossing. Your equipment slots remain free."
		if p.bound: description.text+="\n\nContainment restored. Report to Tovan."
		elif p.plans and "seal_4" in p.defeated: _button("Bind 1 Cinder Ward into the threshold","bind")
func act(id: String) -> bool:
	if not dialog.visible or not inside or not NODES.has(subject) or world.player.position.distance_to(ORIGIN+NODES[subject])>=2.3: return false
	var p: Dictionary=state.seal
	var success:=false
	if id=="accept" and subject=="keeper" and not p.accepted: p.accepted=true; success=true
	elif id=="supplies" and subject=="supplies" and p.accepted and not p.supplies:
		p.supplies=true; world.adventure.grant_materials({"steel_ingot":8,"crystal":8,"rune_dust":4,"ash_glass":4 ,"arrow":60,"station_round":120}); state.consumables.magicka_draught=int(state.consumables.get("magicka_draught",0))+3; success=true
	elif id=="valve" and subject in ["intake","exhaust"] and subject not in p.valves:
		var guard: String="seal_0" if subject=="intake" else "seal_1"
		if guard not in p.defeated: return false
		p.valves.append(subject); success=true
	elif id=="plans" and subject=="plans" and "seal_2" in p.defeated and "seal_3" in p.defeated and not p.plans:
		p.plans=true
		if "cinder_ward" not in state.blueprints: state.blueprints.append("cinder_ward")
		success=true
	elif id=="bind" and subject=="seal" and p.plans and "seal_4" in p.defeated and not p.bound:
		if int(state.materials.get("cinder_ward",0))<1: description.text="Forge a Cinder Ward first: 4 steel, 4 crystals, 2 rune dust and 2 Ash Glass."; world.audio.sfx("error"); return false
		state.materials.cinder_ward-=1; p.bound=true; success=true; world.audio.sfx("enchant")
	elif id=="recover_component" and subject=="supplies" and state.story_recovery_available("cinder_ward"):
		state.materials.cinder_ward=1; success=true; world.audio.sfx("forge")
	elif id=="reward" and subject=="keeper" and p.bound and not p.rewarded:
		p.rewarded=true
		if "broken_seal" not in state.story_completed: state.story_completed.append("broken_seal")
		if "wardkeeper" not in state.blueprints: state.blueprints.append("wardkeeper")
		state.gold+=220
		var uid: String=state.add_item("wardkeeper_amulet",2,"vigor"); state.inventory[uid].favorite=true
		world.adventure.grant_materials({"steel_ingot":6,"crystal":6,"rune_dust":4,"ash_glass":4}); success=true
	if success: state._commit(); open_dialog(subject)
	return success
func can_damage_enemy(id: String) -> bool:
	if id in ["seal_0","seal_1"]: return state.seal.accepted
	if id in ["seal_2","seal_3"]: return state.seal.valves.size()==2
	return id=="seal_4" and state.seal.plans
func barrier_message() -> String:
	return "Isolate the pressure lines and recover the ledger to reach the inner defenders"
func mark_defeated(id: String) -> void:
	if can_damage_enemy(id) and id not in state.seal.defeated: state.seal.defeated.append(id); state._commit()
func loot(id: String) -> bool:
	if not inside or id not in state.seal.defeated or id in state.seal.looted: return false
	state.seal.looted.append(id); state.gold+=30; world.adventure.grant_materials({"steel_ingot":2,"ash_glass":1}); state._commit()
	world.hud.announce("Furnace salvage","Tempering supplies recovered."); return true
func objective() -> String:
	var p: Dictionary=state.seal
	if p.rewarded: return "Containment restored · Use the northern crossing to enter the Crucible"
	if not p.accepted: return "Meet Wardwright Tovan beside the service lift"
	if p.valves.size()!=2: return "Defeat the outer enforcers and isolate both pressure lines · %d / 2" % p.valves.size()
	if not p.plans: return "Clear the inner enforcers and recover the shipping ledger"
	if not p.bound:
		if state.story_recovery_available("cinder_ward"): return "Rebuild a Cinder Ward at the supply chest, then confront the Sealbreaker"
		return "Forge a Cinder Ward, defeat the Sealbreaker and bind the fractured seal"
	return "Report the restored containment to Tovan"
func close_dialog() -> void:
	dialog.hide(); world.player.dialog_open=false
func check_fall() -> void:
	var p: Vector3=world.player.position-ORIGIN
	if p.y< -1.5 or absf(p.x)>24 or p.z< -70 or p.z>40: world.player.position=ORIGIN+Vector3(0,.2,36); world.player.velocity=Vector3.ZERO
func fire(origin: Vector3,direction: Vector3,damage: float,hostile: bool,source: CollisionObject3D,magic: bool) -> void:
	world.adventure.fire(origin,direction,damage,hostile,source,magic)
func line_clear(from: Vector3,to: Vector3,source: CollisionObject3D,target_body: CollisionObject3D=null) -> bool:
	return world.adventure.line_clear(from,to,source,target_body)
func _process(delta: float) -> void:
	preview_label.visible="--seal-preview" in OS.get_cmdline_user_args() and not world.player.paused
	if feedback_time>0: world.adventure.feedback=feedback; world.adventure.feedback_time=feedback_time; feedback_time=maxf(0,feedback_time-delta)
