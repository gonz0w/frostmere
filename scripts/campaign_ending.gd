extends Node
const HOME=Vector3(41,0,-35)
const CONTROL=Vector3(6,0,-36)
const REWARDS={"blade":"dawnforged_sword","bow":"dawnforged_bow","staff":"dawnforged_staff"}
var world: Node3D
var state: RefCounted
var dialog: ColorRect
var story: RichTextLabel
var reward_note: Label
var options: VBoxContainer
var core: MeshInstance3D
var warning_lights: Array[MeshInstance3D]=[]
func _ready() -> void:
	state=world.player.character
	_build_engine(); _ui(); state.changed.connect(refresh); refresh()
func _build_engine() -> void:
	var realm: Node3D=world.realms.roots.crucible
	var b=preload("res://scripts/blocks.gd").new()
	var glow: StandardMaterial3D=b.materials.window.duplicate(); glow.albedo_color=Color("f27b37"); glow.emission=glow.albedo_color; b.materials.engine_glow=glow
	for side in [-1,1]:
		b.add("iron",Vector3(side*3,3,-38),Vector3(.7,6,.8))
		for y in range(7): b.add("coal",Vector3(side*3,y*.7+.2,-37.5),Vector3(.9,.2,.2))
	for y in [1,5]: b.add("iron",Vector3(0,y,-38),Vector3(6,.5,1))
	core=b.piece(realm,"engine_glow",Vector3(0,3,-38),Vector3(3,3,.7))
	for side in [-1,1]:
		for y in range(4): warning_lights.append(b.piece(realm,"engine_glow",Vector3(side*2,1.5+y*.8,-37.4),Vector3(.3,.3,.2)))
	b.add("iron",CONTROL+Vector3.UP*.6,Vector3(1.5,1.2,1))
	b.add("gold",CONTROL+Vector3.UP*1.3,Vector3(.8,.15,.2))
	b.finish(realm)
	var label:=Label3D.new(); label.text="Invasion engine · emergency shutdown"; label.position=CONTROL+Vector3.UP*2.2; label.font_size=20; label.pixel_size=.003; label.billboard=BaseMaterial3D.BILLBOARD_ENABLED; label.visibility_range_end=20; realm.add_child(label)
	world.blocks.add("stone",HOME+Vector3.UP*.4,Vector3(1.3,.8,.8))
	world.blocks.add("fur",HOME+Vector3.UP*.85,Vector3(.9,.12,.6))
	world.block_count+=world.blocks.finish(world)
	var book_label:=Label3D.new(); book_label.text="Chronicle of the Returning Light"; book_label.position=HOME+Vector3.UP*1.8; book_label.font_size=20; book_label.pixel_size=.003; book_label.billboard=BaseMaterial3D.BILLBOARD_ENABLED; book_label.visibility_range_begin=3.5; book_label.visibility_range_end=18; world.add_child(book_label)
func _ui() -> void:
	var layer:=CanvasLayer.new(); layer.layer=8; add_child(layer)
	dialog=ColorRect.new(); dialog.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); dialog.color=Color("17282a"); layer.add_child(dialog)
	var center:=CenterContainer.new(); center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); dialog.add_child(center)
	var col:=VBoxContainer.new(); col.custom_minimum_size.x=760; col.add_theme_constant_override("separation",14); center.add_child(col)
	var heading:=Label.new(); heading.text="THE LAST FURNACE · A LIGHT BROUGHT HOME"; heading.add_theme_font_size_override("font_size",25); col.add_child(heading)
	story=RichTextLabel.new(); story.bbcode_enabled=true; story.custom_minimum_size=Vector2(760,340); story.add_theme_font_size_override("normal_font_size",18); col.add_child(story)
	reward_note=Label.new(); reward_note.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART; reward_note.custom_minimum_size.x=760; reward_note.add_theme_font_size_override("font_size",16); col.add_child(reward_note)
	options=VBoxContainer.new(); col.add_child(options)
	var close:=Button.new(); close.text="Continue adventuring [ Esc ]"; close.custom_minimum_size.y=42; close.pressed.connect(func(): close_dialog(); world.player.set_paused(false)); col.add_child(close)
	dialog.hide()
func refresh() -> void:
	if not is_instance_valid(core): return
	core.visible=not state.finale.shutdown
	for lamp in warning_lights: lamp.visible=not state.finale.shutdown
func can_shutdown() -> bool:
	if not world.realms.inside or world.realms.current!="crucible" or world.player.paused or state.finale.shutdown: return false
	if world.player.position.distance_to(world.realms.vector(world.realms.definitions.crucible.origin)+CONTROL)>=2.4: return false
	for id in ["crucible_guard","crucible_gunner","crucible_warden"]:
		if id not in state.realm_progress.defeated: return false
	return "crucible_warden" in state.realm_progress.looted
func shutdown() -> bool:
	if not can_shutdown():
		world.hud.announce("Engine still active","Defeat all three defenders, recover the Warden's relic and use the shutdown console."); return false
	state.finale.shutdown=true; state._commit(); world.audio.sfx("quest")
	world.hud.announce("The last furnace falls silent","The invasion engine is stopped. Return through the arrival gate to bring the news home."); return true
func open_chronicle() -> bool:
	if world.realms.inside or "last_furnace" not in state.story_completed or world.player.position.distance_to(HOME)>6: return false
	world.player.dialog_open=true; world.player.set_paused(true); dialog.show()
	story.text=chronicle_text()
	reward_note.text="Choose one Exquisite heirloom · all three recipes, 350 gold and upgrade supplies included" if state.finale.reward=="" else "Heirloom claimed · all three Dawnforged recipes are available at the forge"
	for child in options.get_children(): options.remove_child(child); child.queue_free()
	if state.finale.reward=="":
		for choice: String in REWARDS:
			var item: Dictionary=state.items[REWARDS[choice]]
			var attribute: String={"blade":"strength","bow":"agility","staff":"intellect"}[choice]
			var button:=Button.new()
			button.text="%s · %d base damage / +%d %s" % [item.name,item.damage,item.bonuses.get(attribute,0),attribute.capitalize()]
			button.custom_minimum_size.y=40; button.pressed.connect(func(): claim(choice)); options.add_child(button)
	return true
func claim(choice: String) -> bool:
	if not dialog.visible or not REWARDS.has(choice) or state.finale.reward!="" or not state.finale.shutdown or "last_furnace" not in state.story_completed or world.realms.inside or world.player.position.distance_to(HOME)>6: return false
	state.finale.reward=choice
	if "dawnforged" not in state.blueprints: state.blueprints.append("dawnforged")
	var uid: String=state.add_item(REWARDS[choice],3,"vigor"); state.inventory[uid].favorite=true
	state.gold+=350
	world.adventure.grant_materials({"steel_ingot":12,"crystal":8,"cinder_alloy":8,"soul_ember":6})
	state._commit(); world.audio.sfx("quest"); open_chronicle(); return true
func chronicle_text() -> String:
	var text:="[b]The invasion engine is silent.[/b]\n\nYou brought the light back from Aeralis, held Northwatch, and carried a protected crossing into the Crucible. The road home remains open. Your weapons, magic and recovered relics remain yours.\n\n"
	if state.roots.choice!="": text+=("The Stag Shrine remains a wild grove." if state.roots.choice=="wild" else "The Stag Shrine endures through the tended woodland pact.")+"\n"
	if state.shore.choice!="": text+=("Saltbreak's harbor beacon still guides its sailors." if state.shore.choice=="harbor" else "The restored navigation core preserves the wreck's discoveries.")+"\n"
	if state.mountain.clan!="": text+="Your place among the "+state.mountain.clan.capitalize()+" remains yours.\n"
	text+="\n[b]Continue your adventure[/b]\nRevisit the holds, collect missing designs, improve your equipment and pursue the available side quests. Read this chronicle again beside the home-world gates.\n\n"
	text+=("Choose one Exquisite Dawnforged heirloom. All three patterns, 350 gold and upgrade supplies are included." if state.finale.reward=="" else "Your Dawnforged heirloom and all three patterns have been claimed. Forge the other designs and temper your collection at any forge.")
	return text
func close_dialog() -> void:
	dialog.hide(); world.player.dialog_open=false
