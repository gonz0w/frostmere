extends Node3D
const Rules=preload("res://scripts/road_quest_rules.gd")
var world: Node3D
var state: RefCounted
var catalog: Dictionary
var panel: ColorRect
var title: Label
var description: Label
var options: VBoxContainer
var subject:=""
var selected:=""
var site_labels: Dictionary={}
var wheel: Node3D
var well_water: MeshInstance3D
var traveler: Node3D
var medicine_crates: Node3D
var charter_caption: Label3D
var wheel_clock:=0.0
func records() -> Dictionary: return state.hunt.get("roads",{})
func answers(id: String) -> Array: return records().get(id,{}).get("answers",[])
func complete(id: String) -> bool: return Rules.complete(records(),id)
func ending(id: String) -> String: return Rules.ending(records(),id)
func compact_blocked() -> bool: return ending("sable_concord_3")=="war"
func rank() -> String:
	return "Concord Hand" if complete("sable_concord_3") else "Broker" if complete("sable_concord_2") else "Runner" if complete("sable_concord_1") else "Unaffiliated"
func _ready() -> void:
	state=world.player.character; catalog=Rules.data(); build(); ui(); state.changed.connect(refresh); refresh()
func position_for(id: String) -> Vector3:
	if id=="traveler" and answers("side_three_roads").size()>=5: return world.shore.ORIGIN+Vector3(31,0,39)
	var site: Dictionary=catalog.sites[id]
	var p:=Vector3(site.position[0],site.position[1],site.position[2])
	return p+Vector3.UP*world.Terrain.height_at(p.x,p.z) if site.area=="home" else world.get(site.area).ORIGIN+p
func nearby() -> String:
	if not is_instance_valid(world.session_save): return ""
	var area: String=world.session_save.area()
	var best:=""; var distance:=2.25
	for id in catalog.sites:
		if catalog.sites[id].area!=area: continue
		var d: float=world.player.position.distance_to(position_for(id))
		if d<distance: best=id; distance=d
	return best
func build() -> void:
	var b: RefCounted=world.blocks
	for id in catalog.sites:
		var site: Dictionary=catalog.sites[id]; var p: Vector3=position_for(id)
		var label:=Label3D.new(); label.position=p+Vector3.UP*2.4; label.text=site.name; label.font_size=22; label.pixel_size=.0035; label.billboard=BaseMaterial3D.BILLBOARD_ENABLED; label.visibility_range_end=24; add_child(label); site_labels[id]=label
		if site.kind=="npc":
			var npc=preload("res://scripts/character_visual.gd").new(); npc.position=p; npc.rotation.y=PI; add_child(npc)
			var model=preload("res://scripts/character_state.gd").new()
			for slot in ["head","chest","hands","legs","feet"]: model.equip(model.add_item(("cloth_" if id in ["broker","refugees","informant"] else "leather_")+slot),slot)
			model.equipment.main_hand=""; model.equipment.off_hand=""; npc.build(model)
			if id=="traveler": traveler=npc
		else:
			b.piece(self,"wood",p+Vector3.UP*.5,Vector3(1.5,1,1))
			b.piece(self,"snow" if site.kind=="book" else "iron",p+Vector3.UP*1.06,Vector3(1.2,.08,.8))
	# A covered caravan table and four wheels establish the Dunewell trading stop.
	var water_material: StandardMaterial3D=b.materials.iron.duplicate(); water_material.albedo_color=Color("588c98"); b.materials.road_water=water_material
	var cart: Vector3=position_for("courier")+Vector3(3,0,6)
	b.piece(self,"wood",cart+Vector3.UP,Vector3(2.5,.3,4))
	for x in [-1.4,1.4]:
		for z in [-1.2,1.2]: b.piece(self,"timber",cart+Vector3(x,.55,z),Vector3(.2,1.1,1.1))
	for x in [-1,1]: b.piece(self,"timber",cart+Vector3(x,1.9,0),Vector3(.15,2,3.6))
	b.piece(self,"cloth",cart+Vector3.UP*2.9,Vector3(2.6,.16,4.2))
	# Mill wheel turns only after the brace and pin have been restored.
	var mill: Vector3=position_for("mill")+Vector3(-2,1.5,-2)
	wheel=Node3D.new(); wheel.position=mill; add_child(wheel)
	for i in range(8):
		var a: float=TAU*i/8
		var spoke=b.piece(wheel,"wood",Vector3(cos(a),sin(a),0),Vector3(2.2,.16,.25)); spoke.rotation.z=a
		var paddle=b.piece(wheel,"timber",Vector3(cos(a)*2,sin(a)*2,0),Vector3(.65,.3,1)); paddle.rotation.z=a
	b.piece(self,"iron",mill,Vector3(.3,.3,2))
	b.piece(self,"road_water",mill+Vector3(0,-1.6,0),Vector3(6,.1,3))
	for x in [-2.5,2.5]: b.piece(self,"stone_dark",mill+Vector3(x,-1.2,-.8),Vector3(.6,2.5,1.2))
	b.piece(self,"wood",mill+Vector3(0,-1.4,-2),Vector3(5,.2,1.5))
	var well: Vector3=position_for("well_channel")
	for x in [-1,1]: b.piece(self,"stone",well+Vector3(x*.8,.5,-2),Vector3(.3,1,2.5))
	well_water=b.piece(self,"road_water",well+Vector3(0,.3,-2),Vector3(1.3,.12,2.3))
	medicine_crates=Node3D.new(); medicine_crates.position=position_for("refugees")+Vector3(2,0,0); add_child(medicine_crates)
	for i in range(3): b.piece(medicine_crates,"wood",Vector3(i*.6,.25,0),Vector3(.5,.5,.5))
	for i in range(3):
		var refugee=preload("res://scripts/character_visual.gd").new(); refugee.position=position_for("refugees")+Vector3(-3-i*2,0,-4); refugee.rotation.y=PI; add_child(refugee)
		var model=preload("res://scripts/character_state.gd").new()
		for slot in ["head","chest","hands","legs","feet"]: model.equip(model.add_item("cloth_"+slot),slot)
		model.equipment.main_hand=""; model.equipment.off_hand=""; refugee.build(model)
		b.piece(self,"cloth",refugee.position+Vector3(0,.1,-1.5),Vector3(1,.2,1.7))
	charter_caption=Label3D.new(); charter_caption.position=position_for("route_table")+Vector3.UP*1.5; charter_caption.font_size=20; charter_caption.pixel_size=.003; charter_caption.billboard=BaseMaterial3D.BILLBOARD_ENABLED; add_child(charter_caption)
func ui() -> void:
	var layer:=CanvasLayer.new(); layer.layer=8; add_child(layer)
	panel=ColorRect.new(); panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); panel.color=Color("13232b"); layer.add_child(panel)
	var center:=CenterContainer.new(); center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); panel.add_child(center)
	var col:=VBoxContainer.new(); col.custom_minimum_size.x=760; col.add_theme_constant_override("separation",18); center.add_child(col)
	title=Label.new(); title.add_theme_font_size_override("font_size",24); col.add_child(title)
	description=Label.new(); description.custom_minimum_size=Vector2(760,210); description.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART; description.add_theme_font_size_override("font_size",18); col.add_child(description)
	options=VBoxContainer.new(); col.add_child(options)
	var back:=Button.new(); back.text="Return [ Esc ]"; back.custom_minimum_size.y=40; back.pressed.connect(close); col.add_child(back); panel.hide()
func button(label: String,callback: Callable) -> void:
	var b:=Button.new(); b.text=label; b.custom_minimum_size.y=40; b.pressed.connect(callback); options.add_child(b)
func clear_buttons() -> void:
	for child in options.get_children(): options.remove_child(child); child.queue_free()
func linked(id: String) -> Array:
	var found:=[]
	for q in catalog.quests:
		for step in catalog.quests[q].steps:
			if step.site==id or step.options.any(func(o): return o.get("site","")==id): found.append(q); break
	return found
func open() -> void:
	subject=nearby()
	if subject=="" or world.player.paused: return
	selected=""; world.player.dialog_open=true; world.player.set_paused(true); panel.show(); show_subject()
func close() -> void:
	if not panel.visible: return
	panel.hide(); world.player.dialog_open=false; world.player.set_paused(false)
func show_subject() -> void:
	clear_buttons(); title.text=catalog.sites[subject].name; description.text="Choose a matter to discuss or investigate."
	for id in linked(subject): button(catalog.quests[id].name,func(): selected=id; show_quest())
func locked(id: String) -> String:
	var q: Dictionary=catalog.quests[id]
	if complete(id): return ""
	if id=="sable_concord_3" and state.shore.get("passage_choice","")=="outlaw": return "Permanently closed by the Compact charter that outlawed the Concord."
	if q.gate!="" and q.gate not in state.story_completed: return "Complete "+q.gate.capitalize()+" before starting this quest."
	if q.requires!="" and not complete(q.requires): return "Complete "+catalog.quests[q.requires].name+" first."
	return ""
func option_site(step: Dictionary,o: Dictionary) -> String: return o.get("site",step.site)
func allowed_branch(id: String,o: Dictionary) -> bool:
	return not o.has("when") or answers(id)[o.when[0]]==o.when[1]
func outcome(id: String) -> String:
	var q: Dictionary=catalog.quests[id]
	for o in q.steps.back().options:
		if o.id==ending(id): return o.get("outcome",o.label)
	return ""
func objective(id: String) -> String:
	if complete(id): return catalog.quests[id].name+" complete · "+outcome(id)+(" · "+rank() if id.begins_with("sable_") else "")
	if locked(id)!="": return locked(id)
	var step: Dictionary=catalog.quests[id].steps[answers(id).size()]
	var target: String=step.site
	for o in step.options:
		if allowed_branch(id,o): target=option_site(step,o); break
	return "%s · %s (%s). Step %d / %d." % [catalog.quests[id].name,catalog.sites[target].name,{"home":"Frostmere","mountain":"Wyrmkeep","shore":"Saltbreak","roots":"Stag Shrine woodland"}[catalog.sites[target].area],answers(id).size()+1,catalog.quests[id].steps.size()]
func show_quest() -> void:
	clear_buttons(); title.text=catalog.quests[selected].name.to_upper(); description.text=objective(selected)
	if complete(selected) or locked(selected)!="": return
	var step: Dictionary=catalog.quests[selected].steps[answers(selected).size()]
	description.text=step.text+"\n\n"+objective(selected)
	if selected=="sable_concord_1" and answers(selected).size()==2:
		description.text=("You tell Sal you inspected the case. He accepts your honesty but insists that names are never yours to sell.\n\n" if answers(selected)[1]=="opened" else "Sal checks the intact seal and acknowledges your discretion.\n\n")+description.text
	for o: Dictionary in step.options:
		if not allowed_branch(selected,o) or option_site(step,o)!=subject: continue
		if selected=="sable_concord_3" and o.id=="war" and state.shore.get("passage_choice","")!="": continue
		button(o.label,func(): act(selected,o.id))
func act(id: String,option_id: String) -> bool:
	if not panel.visible or nearby()!=subject or not catalog.quests.has(id) or locked(id)!="" or complete(id): return false
	var step: Dictionary=catalog.quests[id].steps[answers(id).size()]
	for o: Dictionary in step.options:
		if o.id!=option_id or option_site(step,o)!=subject or not allowed_branch(id,o): continue
		if id=="sable_concord_3" and o.id=="war" and state.shore.get("passage_choice","")!="": return false
		if o.has("guard") and o.guard[1] not in state.get(o.guard[0]).defeated:
			description.text="Clear the hostile approach first. Earlier defeats count. No supplies were spent."; return false
		if not state.can_pay(o.get("cost",{})) or state.gold<int(o.get("gold_cost",0)):
			description.text="You need the listed materials or gold before proceeding. Nothing was spent.\n\n"+step.text; return false
		for mat in o.get("cost",{}): state.materials[mat]-=o.cost[mat]
		state.gold-=int(o.get("gold_cost",0))
		if not state.hunt.has("roads"): state.hunt.roads={}
		if not state.hunt.roads.has(id): state.hunt.roads[id]={"answers":[]}
		state.hunt.roads[id].answers.append(o.id)
		if o.has("reward"):
			var r: Dictionary=o.reward; state.gold+=int(r.gold)
			var uid: String=state.add_item(r.item,int(r.quality),r.enchant); state.inventory[uid].favorite=true; state.inventory[uid].custom_name=r.name
			world.adventure.grant_materials(r.materials); world.audio.sfx("quest")
		else: world.audio.sfx("interact")
		world.hud.world_map.selected_quest=id; state._commit(); selected=id; show_quest(); return true
	return false
func refresh() -> void:
	well_water.visible=answers("side_dunewell").size()>=3
	traveler.position=position_for("traveler")
	site_labels.traveler.position=traveler.position+Vector3.UP*2.4
	site_labels.traveler.text="Venn · sheltered guest" if answers("side_three_roads").size()>=5 else catalog.sites.traveler.name
	medicine_crates.visible=complete("side_reedhollow")
	charter_caption.text=rank()+" · "+ending("sable_concord_3")
func _process(delta: float) -> void:
	if is_instance_valid(world.session_save) and world.session_save.area()=="home" and not world.player.paused and answers("side_larksbridge").size()>=4:
		wheel_clock+=delta; wheel.rotation.z=wheel_clock*.6
