extends ColorRect
const CampaignGuide=preload("res://scripts/campaign_guide.gd")
const Canvas = preload("res://scripts/atlas_canvas.gd")
const INK := Color("e3ded0")
const GOLD := Color("cdb782")
var world: Node3D
var atlas: RefCounted
var canvas: Control
var view_label: Label
var tabs: TabContainer
var place_text: RichTextLabel
var place_action: Button
var survey_action: Button
var faction_picker: OptionButton
var faction_text: RichTextLabel
var quest_filter: OptionButton
var quest_list: ItemList
var quest_text: RichTextLabel
var quest_action: Button
var status: Label
var layer_toggles: Array[CheckBox] = []
var selected_kind := "location"
var selected_id := "frostmere"
var quest_ids: Array[String] = []
var selected_quest := "oldwatch_survey"
var selected_faction := "hearthbound"

func _ready() -> void:
	atlas = world.atlas
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	color = Color("0c171e")
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 22)
	add_child(margin)
	var page := VBoxContainer.new()
	page.add_theme_constant_override("separation", 12)
	margin.add_child(page)
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 10)
	page.add_child(header)
	var title := _label(header, "THE NORTHERN REACH", 23, INK)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_button(header, "World", func(): set_view(false))
	_button(header, "Local area", func(): set_view(true))
	_button(header, "Return   [ M / Esc ]", close)
	var tools := HBoxContainer.new()
	tools.add_theme_constant_override("separation", 10)
	page.add_child(tools)
	view_label = _label(tools, "", 13, GOLD)
	view_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for layer in ["Routes", "Quest counts", "Faction seats"]:
		var toggle := CheckBox.new()
		toggle.text = layer
		toggle.button_pressed = layer != "Faction seats"
		toggle.add_theme_font_size_override("font_size", 12)
		tools.add_child(toggle)
		layer_toggles.append(toggle)
		toggle.tooltip_text = "Regional atlas overlay"
		toggle.toggled.connect(func(value: bool):
			match layer:
				"Routes": canvas.show_roads = value
				"Quest counts": canvas.show_quests = value
				"Faction seats": canvas.show_factions = value
			canvas.queue_redraw())
	_button(tools, "−", func(): canvas.zoom_at(1.0 / 1.2, canvas.size / 2))
	_button(tools, "+", func(): canvas.zoom_at(1.2, canvas.size / 2))
	_button(tools, "Fit", func(): canvas.reset_view())
	var body := HBoxContainer.new()
	body.add_theme_constant_override("separation", 16)
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	page.add_child(body)
	canvas = Canvas.new()
	canvas.atlas = atlas
	canvas.player = world.player
	canvas.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	canvas.selected.connect(_selected)
	body.add_child(canvas)
	tabs = TabContainer.new()
	tabs.custom_minimum_size.x = 355
	tabs.add_theme_font_size_override("font_size", 14)
	body.add_child(tabs)
	var place := _tab("Place")
	place_text = _rich(place)
	place_action = _button(place, "Explore Frostmere map", _place_action)
	survey_action = _button(place, "Begin Oldwatch Survey", _start_survey)
	_button(place, "Clear waypoint", func(): atlas.set_waypoint(""))
	var factions := _tab("Factions")
	faction_picker = OptionButton.new()
	for faction: Dictionary in atlas.data.factions:
		faction_picker.add_item(faction.name)
	faction_picker.item_selected.connect(func(index: int):
		selected_faction = atlas.data.factions[index].id
		_show_faction())
	factions.add_child(faction_picker)
	faction_text = _rich(factions)
	_button(factions, "Show faction home", func():
		set_view(false)
		_selected("location", atlas.factions[selected_faction].home))
	var quests := _tab("Quests")
	quest_filter = OptionButton.new()
	for label in ["All quest lines", "Primary timeline", "Faction chapters", "Local side quests"]:
		quest_filter.add_item(label)
	quest_filter.item_selected.connect(func(_index: int): _filter_quests())
	quests.add_child(quest_filter)
	quest_list = ItemList.new()
	quest_list.custom_minimum_size.y = 210
	quest_list.add_theme_font_size_override("font_size", 13)
	quest_list.item_selected.connect(func(index: int):
		selected_quest = quest_ids[index]
		_show_quest())
	quests.add_child(quest_list)
	quest_text = _rich(quests)
	quest_action = _button(quests, "Begin survey", func():
		if selected_quest == "side_frostmere":
			atlas.set_waypoint("forge" if not world.player.character.adventure.accepted or "captain" in world.player.character.adventure.looted else "stones")
		else:
			_start_survey())
	_button(quests, "Show quest location", func():
		set_view(false)
		_selected("location", atlas.quests[selected_quest].location))
	status = _label(page, "", 12, GOLD)
	status.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	_label(page, "Drag to pan · Scroll / pinch to zoom · Click a marker or landscape · Gold: playable / visited · Pale: planned · Mint: you", 12, INK)
	atlas.changed.connect(_refresh)
	world.player.character.changed.connect(_refresh)
	_refresh()
	visible = false

func _label(parent: Node, text: String, font_size: int, tint: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", tint)
	parent.add_child(label)
	return label

func _button(parent: Node, text: String, callback: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size.y = 32
	button.add_theme_font_size_override("font_size", 13)
	button.pressed.connect(callback)
	parent.add_child(button)
	return button

func _tab(title: String) -> VBoxContainer:
	var column := VBoxContainer.new()
	column.name = title
	column.add_theme_constant_override("separation", 10)
	tabs.add_child(column)
	return column

func _rich(parent: Node) -> RichTextLabel:
	var text := RichTextLabel.new()
	text.bbcode_enabled = true
	text.size_flags_vertical = Control.SIZE_EXPAND_FILL
	text.add_theme_font_size_override("normal_font_size", 14)
	text.add_theme_font_size_override("bold_font_size", 14)
	text.add_theme_color_override("default_color", INK)
	parent.add_child(text)
	return text

func set_view(local: bool) -> void:
	canvas.set_local(local)
	selected_kind = "site" if local else "location"
	selected_id = "trail" if local else "frostmere"
	_refresh()

func _selected(kind: String, id: String) -> void:
	selected_kind = kind
	selected_id = id
	canvas.selected_id = id
	canvas.queue_redraw()
	_show_place()

func _refresh() -> void:
	for toggle: CheckBox in layer_toggles:
		toggle.disabled = canvas.local_view
	view_label.text = ("OLDWATCH BARROW  /  underground" if world.player.position.y < -20 else "LOCAL SURVEY  /  Frostmere is playable") if canvas.local_view else "WORLD OUTLINE  /  8 regions · 16 locations"
	if canvas.local_view and canvas.in_realm(): view_label.text = world.realms.definitions[world.realms.current].name
	if canvas.local_view and canvas.in_mountain(): view_label.text = "WYRMKEEP / mountain settlement"
	if canvas.local_view and canvas.in_seal(): view_label.text="CALDERA UNDERWORKS / The Broken Seal"
	if canvas.local_view and canvas.in_winter(): view_label.text="NORTHWATCH / Winter Siege"
	if canvas.local_view and canvas.in_threshold(): view_label.text="FIRST THRESHOLD / orbital station"
	if canvas.local_view and canvas.in_convergence(): view_label.text="MIREWATCH / expedition camp"
	if canvas.local_view and canvas.in_choir(): view_label.text="EMBER CALDERA / Ashen Choir"
	if canvas.local_view and canvas.in_roots(): view_label.text="STAG SHRINE / Amberweald"
	if canvas.local_view and canvas.in_lens(): view_label.text="SUNKEN LENS / buried observatory"
	if canvas.local_view and canvas.in_shore(): view_label.text = "SALTBREAK / the Black Shore"
	if canvas.local_view and canvas.in_archive(): view_label.text = "PINEHALL / forest and ruined archive"
	_show_place()
	_show_faction()
	_filter_quests()
	status.text = "Progress could not be saved." if atlas.save_error else "The Oldwatch Survey is complete." if atlas.survey_complete() else "Walking to: " + atlas.waypoint_text() if atlas.waypoint != "" else "Explore the roads, speak with local guides and follow your journal. Travel to new areas through their world entrances."
	if world.player.position.y < -20 and not atlas.save_error:
		status.text = "Oldwatch Barrow · " + world.adventure.objective()
	if is_instance_valid(world.stonewake) and world.stonewake.available() and world.player.character.stonewake.accepted and not world.player.character.stonewake.rewarded:
		status.text = "Stonewake · " + world.stonewake.objective()
	if canvas.in_mountain(): status.text = world.mountain.objective()
	if canvas.in_seal(): status.text=world.seal.objective()
	if canvas.in_winter(): status.text=world.winter.objective()
	if canvas.in_threshold(): status.text=world.threshold.objective()
	if canvas.in_convergence(): status.text=world.convergence.objective()
	if canvas.in_choir(): status.text=world.choir.objective()
	if canvas.in_roots(): status.text=world.roots.objective()
	if canvas.in_lens(): status.text=world.lens.objective()
	if canvas.in_shore(): status.text = world.shore.objective()
	if canvas.in_archive(): status.text = world.archive_chapter.objective()
	if is_instance_valid(world.session_save) and world.session_save.area()=="home" and not atlas.save_error and atlas.waypoint=="":
		var open_paths: PackedStringArray=[]
		for route in CampaignGuide.routes(world): open_paths.append(route.place)
		if not open_paths.is_empty(): status.text="Open main paths · choose any: "+" / ".join(open_paths)
	canvas.queue_redraw()

func _show_place() -> void:
	place_action.disabled = false
	survey_action.visible = canvas.local_view or selected_id == "frostmere"
	survey_action.disabled = atlas.survey_complete()
	survey_action.text = "Survey completed" if atlas.survey_complete() else "Track Oldwatch Survey" if atlas.survey_started else "Begin Oldwatch Survey"
	if canvas.local_view and canvas.in_seal():
		place_text.text="[font_size=23][b]Caldera Underworks[/b][/font_size]\n\n"+world.seal.objective()+"\n\nTovan and the workshops are beside the southern service lift. Isolate the two pressure lines, recover the ledger, forge a Cinder Ward and bind it into the northern seal. Report before descending."
		place_action.text="Investigate the underworks"; place_action.disabled=true; survey_action.visible=false
		return
	if canvas.local_view and canvas.in_winter():
		place_text.text="[font_size=23][b]Northwatch[/b][/font_size]\n\n"+world.winter.objective()+"\n\nThe caldera frontier fort guards the northern holds. Halla and the workshops occupy the southern courtyard. Repair the defenses after the scouts fall, then ask Halla to begin the assault. Recover the orders in the northern courtyard."
		place_action.text="Defend Northwatch"; place_action.disabled=true; survey_action.visible=false
		return
	if canvas.local_view and canvas.in_threshold():
		place_text.text="[font_size=23][b]First Threshold Station[/b][/font_size]\n\n"+world.threshold.objective()+"\n\nRook, emergency supplies and fabrication benches are in the southern airlock. Isolate the reactor, restart life support, defeat command security and recover the archive. Return through the airlock beacon to bring the findings home."
		place_action.text="Use the southern return beacon"; place_action.disabled=true; survey_action.visible=false
		return
	if (canvas.local_view and canvas.in_convergence()) or (not canvas.local_view and selected_kind=="location" and selected_id=="mirewatch"):
		place_text.text="[font_size=23][b]Mirewatch[/b][/font_size]\n\n"+world.convergence.objective()+"\n\nBring all four branch discoveries to the southeastern expedition road. Ilyra and the evidence desks are on the southern platform. Forge a Transit Regulator from crew supplies, install it at the northern rig, and clear the awakened sentinels to stabilize the return beacon."
		place_action.text="Use the expedition road"; place_action.disabled=true; survey_action.visible=false
		return
	if (canvas.local_view and canvas.in_choir()) or (selected_kind=="location" and selected_id=="ember_caldera"):
		place_text.text="[font_size=23][b]Ember Caldera[/b][/font_size]\n\n"+world.choir.objective()+"\n\nAfter resolving The Divided Council, take the southeastern ash pilgrimage from Frostmere. Speak with Sereth in the southern lodge. Read the resonator inscriptions, ring their sequence, then repair the receiver to enter the signal vault."
		place_action.text="Use the southeastern pilgrim road"; place_action.disabled=true; survey_action.visible=false
		return
	if (canvas.local_view and canvas.in_roots()) or (selected_kind=="location" and selected_id=="stag_shrine"):
		place_text.text="[font_size=23][b]The Stag Shrine[/b][/font_size]\n\n"+world.roots.objective()+"\n\nAfter Stonewake, take the western Amberweald trail from Frostmere. Maelin and Oren wait in the southern lodges. Defeat each blightbound keeper and cleanse its root with herbs and water. The hollow-tree shrine stands in the north. Both restoration pacts preserve the ancient memory."
		place_action.text="Use the western woodland road"; place_action.disabled=true; survey_action.visible=false
		return
	if canvas.local_view and canvas.in_lens():
		place_text.text="[font_size=23][b]The Sunken Lens[/b][/font_size]\n\n"+world.lens.objective()+"\n\nVeyra's camp is south. Excavation caches lie outside the observatory walls. Dawn, Dusk and Crown are the three mirrors inside. Align their beams, then restore the central lens to open the northern vault."
		place_action.text="Return through the southern expedition road"; place_action.disabled=true; survey_action.visible=false
		return
	if selected_kind=="location" and selected_id=="sunken_lens":
		place_text.text="[font_size=23][b]The Sunken Lens[/b][/font_size]\n\nA playable observatory chapter after The Missing Atlas. Take the eastern expedition road from Frostmere. Both Black Shore choices retain this route."
		place_action.text="Use the eastern expedition road"; place_action.disabled=true; survey_action.visible=false
		return
	if canvas.local_view and canvas.in_shore():
		place_text.text="[font_size=23][b]Saltbreak · Black Shore[/b][/font_size]\n\n"+world.shore.objective()+"\n\nSella is in the east harbor house; Neris is in the west salvager house. The beach leads north through the sea cave. Restore the pump, then the beach relay to enter the hull. Identify damaged relics with Neris and restore them at the forge."
		place_action.text="Return through the southern coastal road"; place_action.disabled=true; survey_action.visible=false
		return
	if selected_kind=="location" and selected_id=="saltbreak":
		place_text.text="[font_size=23][b]Saltbreak[/b][/font_size]\n\nThe Black Shore chapter is playable after The Missing Atlas. Take the coastal road southwest of Frostmere. Both power-core choices preserve the lead to the Sunken Lens."
		place_action.text="Use the coastal road in Frostmere"; place_action.disabled=true; survey_action.visible=false
		return
	if canvas.local_view and canvas.in_archive():
		place_text.text = "[font_size=23][b]Pinehall[/b][/font_size]\n\n" + world.archive_chapter.objective() + "\n\nMereth represents the Lantern in the west house; Aelin represents the Coven in the east house. The ruined archive is north. Read its notes, explore the side caches, and confront the Bound Archivist."
		place_action.text = "Use the southern trail to return home"; place_action.disabled = true; survey_action.visible = false
		return
	if selected_kind == "location" and selected_id == "pinehall":
		place_text.text = "[font_size=23][b]Pinehall[/b][/font_size]\n\nA playable forest settlement and archive. After Stonewake, use the western trail near the southern woods in Frostmere. Either recipient of the recovered atlas advances the main story."
		place_action.text = "Travel through the western trail"; place_action.disabled = true; survey_action.visible = false
		return
	if canvas.local_view and canvas.in_mountain():
		place_text.text = "[font_size=23][b]Wyrmkeep[/b][/font_size]\n\n" + world.mountain.objective() + "\n\nSpeaker Runa occupies the central hall. Stoneguard is west; Stormweaver is east. Shops and crafting stations surround the southern square. The reaver outpost lies north, beyond the council hall."
		place_action.text = "Use the southern pass to return home"; place_action.disabled = true; survey_action.visible = false
		return
	if selected_kind == "location" and selected_id == "wyrmkeep":
		place_text.text = "[font_size=23][b]Wyrmkeep[/b][/font_size]\n\nA playable mountain settlement. Complete Stonewake, then use the north pass beyond Ember Hall in Frostmere. Settle the council independently or join one of two rival clans."
		place_action.text = "Travel through the north pass in the world"; place_action.disabled = true; survey_action.visible = false
		return
	if canvas.local_view and canvas.in_realm():
		var realm: Dictionary = world.realms.definitions[world.realms.current]
		place_text.text = "[font_size=23][b]" + realm.name + "[/b][/font_size]\n[color=#d3bb7e]" + realm.act + "[/color]\n\n" + realm.story + "\n\n[b]Current objective[/b]\n" + world.realms.objective() + "\n\nThe mint marker is your position. Attunement, forge and enchantment altar are on the arrival terrace."
		place_action.text = "Use the return gate in the world"
		place_action.disabled = true
		survey_action.visible = false
		return
	if selected_kind == "site":
		var site: Dictionary = atlas.sites[selected_id]
		place_text.text = "[font_size=23][b]%s[/b][/font_size]\n[color=#d3bb7e]PLAYABLE · %s[/color]\n\n%s\n\n%s\n\nSet a waypoint to get a distance and direction guide while walking. This does not teleport you." % [site.name, site.kind.capitalize(), site.description, "Visited" if atlas.visits.has(site.id) else "Not yet visited"]
		place_action.text = "Set walking waypoint"
	elif selected_kind == "region":
		var region: Dictionary = atlas.regions[selected_id]
		place_text.text = "[font_size=23][b]%s[/b][/font_size]\n[color=#d3bb7e]%s[/color]\n\n%s\n\n[b]Places[/b]\n" % [region.name, region.biome, region.description]
		for location: Dictionary in atlas.data.locations:
			if location.region == selected_id:
				place_text.text += "• %s — %s\n" % [location.name, location.status]
		place_text.text += "\nRegion borders and travel distances are a design outline. Frostmere is the current playable slice."
		place_action.text = "Inspect a place marker"
		place_action.disabled = true
	else:
		var location: Dictionary = atlas.locations[selected_id]
		var faction: Dictionary = atlas.factions[location.faction]
		place_text.text = "[font_size=23][b]%s[/b][/font_size]\n[color=#d3bb7e]%s · %s[/color]\n\n%s\n\n[b]Landscape[/b]\n%s\n\n[b]Faction connection[/b]\n%s\n\n[b]Quest connections[/b]\n" % [location.name, location.status.to_upper(), location.kind.capitalize(), location.description, atlas.regions[location.region].biome, faction.name]
		for quest: Dictionary in atlas.quests_at(selected_id):
			place_text.text += "• %s (%s)\n" % [quest.name, quest.kind]
		place_action.text = "Explore Frostmere map" if location.status == "playable" else "Destination not built yet"
		place_action.disabled = location.status != "playable"

func _show_faction() -> void:
	var faction: Dictionary = atlas.factions[selected_faction]
	var allies: Array[String] = []
	var rivals: Array[String] = []
	for id: String in faction.allies:
		allies.append(atlas.factions[id].name)
	for id: String in faction.rivals:
		rivals.append(atlas.factions[id].name)
	faction_text.text = "[font_size=21][b]%s[/b][/font_size]\n[color=#d3bb7e]%s · planned joinable faction[/color]\n\n[b]Home[/b]\n%s\n\n[b]Purpose[/b]\n%s\n\n[b]Initiation[/b]\n%s\n\n[b]Ranks[/b]\n%s\n\n[b]Allies[/b]\n%s\n\n[b]Rivals[/b]\n%s\n\nMembership will require an in-world initiation. Meeting another faction will not automatically make it hostile; a major allegiance choice may close a rival capstone." % [faction.name, faction.kind, atlas.locations[faction.home].name, faction.goal, faction.initiation, " → ".join(faction.ranks), ", ".join(allies) if not allies.is_empty() else "No fixed alliance", ", ".join(rivals) if not rivals.is_empty() else "No fixed rivalry"]
	if selected_faction=="sable_concord" and is_instance_valid(world.road_quests):
		faction_text.text=faction_text.text.replace("planned joinable faction","joinable faction · full arc playable")
		faction_text.text+="\n\n[b]Concord membership[/b]\n"+world.road_quests.rank()
		for quest_id in ["sable_concord_1","sable_concord_2","sable_concord_3"]: faction_text.text+="\n"+world.road_quests.objective(quest_id)
	if selected_faction=="tide_compact" and is_instance_valid(world.shore):
		faction_text.text=faction_text.text.replace("planned joinable faction","joinable faction · initiation playable")
		faction_text.text+="\n\n[b]Compact membership[/b]\n"+world.shore.compact_objective()+"\n"+world.shore.harbor_objective()+"\n"+world.shore.passage_objective()

	if selected_faction=="ashen_choir" and is_instance_valid(world.choir):
		faction_text.text=faction_text.text.replace("planned joinable faction","joinable faction · initiation playable")
		faction_text.text+="\n\n[b]Choir membership[/b]\n"+world.choir.listener_objective()+"\n"+world.choir.memory_objective()+"\n"+world.choir.fire_objective()

	if selected_faction=="hearthbound" and is_instance_valid(world.hunts):
		faction_text.text=faction_text.text.replace("planned joinable faction","joinable faction · initiation playable")
		faction_text.text+="\n\n[b]Lodge membership[/b]\n"+world.hunts.lodge_objective()+"\n"+world.hunts.water_objective()+"\n"+world.hunts.warden_objective()

	if selected_faction == "iron_pact" and is_instance_valid(world.mountain):
		var p: Dictionary = world.player.character.mountain
		faction_text.text = "[font_size=21][b]Iron Pact · Wyrmkeep[/b][/font_size]\n\nTwo rival clans share this council. Stoneguard protects the holds through patrols and stores; Stormweaver restores rune knowledge. Join one after settling the council, or remain independent.\n\n[b]Membership[/b]\n" + (world.mountain.CLANS[p.clan].name if p.clan != "" else "Independent") + " · " + world.mountain.rank_name() + "\n\n[b]Reputation[/b]\nStoneguard: %d\nStormweaver: %d\n\nInitiation restores three road wards. The first promotion supplies two town posts. Weapon patterns and a clan formula unlock at Sworn; chest and off-hand patterns unlock at Shieldbearer. Clan Voice follows the colossus and Rimefang commission and a mandate choice." % [p.reputation.stoneguard,p.reputation.stormweaver]

	if selected_faction in ["lantern", "briar_coven"] and is_instance_valid(world.archive_chapter):
		var id := "lantern" if selected_faction == "lantern" else "briar"
		faction_text.text += "\n\n[b]The Missing Atlas[/b]\nStanding: %d. " % world.player.character.archive.reputation[id] + ("Atlas entrusted to this faction." if world.player.character.archive.recipient == id else "Atlas entrusted to its rival." if world.player.character.archive.recipient != "" else "Custodian not yet chosen.") + " This custody decision does not grant membership."

	if selected_faction=="lantern" and is_instance_valid(world.archive_chapter):
		faction_text.text=faction_text.text.replace("planned joinable faction","joinable faction · first initiation playable")
		faction_text.text+="\n\n[b]Lantern membership[/b]\n"+world.archive_chapter.lantern_objective()

	if selected_faction=="briar_coven" and is_instance_valid(world.roots):
		faction_text.text=faction_text.text.replace("planned joinable faction","joinable faction · first initiation playable")
		faction_text.text+="\n\n[b]Coven membership[/b]\n"+world.roots.coven_objective()+"\n"+world.roots.debt_objective()+"\n"+world.roots.promise_objective()

func _filter_quests() -> void:
	quest_list.clear()
	quest_ids.clear()
	var kind: String = ["", "main", "faction", "side"][quest_filter.selected]
	for quest: Dictionary in atlas.data.quests:
		if kind != "" and quest.kind != kind:
			continue
		quest_ids.append(quest.id)
		var prefix := "◆ " if quest.status == "playable" else "◇ "
		quest_list.add_item(prefix + quest.name)
	if selected_quest not in quest_ids:
		selected_quest = quest_ids[0]
	quest_list.select(quest_ids.find(selected_quest))
	_show_quest()

func _show_quest() -> void:
	var quest: Dictionary = atlas.quests[selected_quest]
	var prerequisites: Array[String] = []
	for id: String in quest.requires:
		prerequisites.append(atlas.quests[id].name)
	quest_text.text = "[font_size=20][b]%s[/b][/font_size]\n[color=#d3bb7e]%s · %s[/color]\n\n%s\n\n[b]Location[/b]\n%s\n\n[b]Prerequisites[/b]\n%s" % [quest.name, quest.kind.capitalize(), quest.status.to_upper(), quest.summary, atlas.locations[quest.location].name, ", ".join(prerequisites) if not prerequisites.is_empty() else "An independent entry point"]
	quest_action.disabled = quest.status != "playable" or atlas.survey_complete()
	quest_action.text = "Quest not built yet" if quest.status != "playable" else "Survey completed" if atlas.survey_complete() else "Track survey" if atlas.survey_started else "Begin survey"
	if selected_quest == "side_frostmere":
		quest_action.disabled = false
		quest_action.text = "Show smith / barrow waypoint"
		quest_text.text += "\n\n[b]Progress[/b]\n" + world.adventure.objective() + "\nSpeak to Edda beside the forge to accept or return the quest."
	elif selected_quest=="sable_concord_3" and is_instance_valid(world.shore) and world.shore.concord_capstone_blocked():
		quest_text.text+="\n\n[b]Permanently closed[/b]\nYour passage charter outlawed the Sable Concord."
		quest_action.disabled=true; quest_action.text="Closed by your passage charter"
	elif is_instance_valid(world.road_quests) and world.road_quests.catalog.quests.has(selected_quest):
		quest_text.text+="\n\n"+world.road_quests.objective(selected_quest)
		quest_action.disabled=true; quest_action.text="Follow the quest directions"
	elif selected_quest=="iron_pact_3" and world.player.character.choir.get("fire_choice","")=="awaken":
		quest_text.text+="\n\n[b]Permanently closed[/b]\nYour Choir conquest oath closes the Clan Voice commission and mandate."
		quest_action.disabled=true; quest_action.text="Closed by conquest oath"
	elif selected_quest=="side_ember_caldera" and is_instance_valid(world.choir):
		quest_text.text+="\n\n[b]Progress[/b]\n"+world.choir.pilgrim_objective()
		quest_action.disabled=true; quest_action.text="Read the caldera entrance notice"
	elif selected_quest=="hearthbound_3" and is_instance_valid(world.hunts):
		quest_text.text+="\n\n[b]Progress[/b]\n"+world.hunts.warden_objective()
		quest_action.disabled=true; quest_action.text="Return to the Hearthbound board"
	elif selected_quest=="hearthbound_2" and is_instance_valid(world.hunts):
		quest_text.text+="\n\n[b]Progress[/b]\n"+world.hunts.water_objective()
		quest_action.disabled=true; quest_action.text="Investigate the drinking den and runoff"
	elif selected_quest=="hearthbound_1" and is_instance_valid(world.hunts):
		quest_text.text+="\n\n[b]Progress[/b]\n"+world.hunts.lodge_objective()
		quest_action.disabled=true; quest_action.text="Read the Hearthbound tab at the Hunters’ Board"
	elif selected_quest=="ashen_choir_3" and is_instance_valid(world.choir):
		quest_text.text+="\n\n[b]Progress[/b]\n"+world.choir.fire_objective()
		quest_action.disabled=true; quest_action.text="Secure the ember governors in the caldera"
	elif selected_quest=="ashen_choir_2" and is_instance_valid(world.choir):
		quest_text.text+="\n\n[b]Progress[/b]\n"+world.choir.memory_objective()
		quest_action.disabled=true; quest_action.text="Discuss the old archive with Sereth"
	elif selected_quest=="ashen_choir_1" and is_instance_valid(world.choir):
		quest_text.text+="\n\n[b]Progress[/b]\n"+world.choir.listener_objective()
		quest_action.disabled=true; quest_action.text="Speak to Sereth at Ember Caldera"
	elif selected_quest=="tide_compact_3" and is_instance_valid(world.shore):
		quest_text.text+="\n\n[b]Progress[/b]\n"+world.shore.passage_objective()
		quest_action.disabled=true; quest_action.text="Consult the harbor and sign the charter"
	elif selected_quest=="tide_compact_2" and is_instance_valid(world.shore):
		quest_text.text+="\n\n[b]Progress[/b]\n"+world.shore.harbor_objective()
		quest_action.disabled=true; quest_action.text="Meet Vessa and protect Tamsin in Saltbreak"
	elif selected_quest=="tide_compact_1" and is_instance_valid(world.shore):
		quest_text.text+="\n\n[b]Progress[/b]\n"+world.shore.compact_objective()
		quest_action.disabled=true; quest_action.text="Meet Arbiter Vessa in Saltbreak"
	elif selected_quest=="side_alderrest" and is_instance_valid(world.roots):
		quest_text.text+="\n\n"+world.roots.amber_objective()
		quest_action.disabled=true; quest_action.text="Find Edda in the woodland camp"
	elif selected_quest=="side_stag_shrine" and is_instance_valid(world.roots):
		quest_text.text+="\n\n[b]Progress[/b]\n"+world.roots.stag_objective()
		quest_action.disabled=true; quest_action.text="Find Fenn beside the Stag Shrine southern road"
	elif selected_quest=="side_pinehall" and is_instance_valid(world.archive_chapter):
		quest_text.text+="\n\n[b]Progress[/b]\n"+world.archive_chapter.apprentice_objective()
		quest_action.disabled=true; quest_action.text="Read the college notice at Pinehall"
	elif selected_quest=="side_rimegate" and is_instance_valid(world.mountain):
		quest_text.text+="\n\n[b]Progress[/b]\n"+world.mountain.shelter_objective()
		quest_action.disabled=true; quest_action.text="Read the overdue notice in Wyrmkeep"
	elif selected_quest=="side_wyrmkeep" and is_instance_valid(world.mountain):
		quest_text.text+="\n\n[b]Progress[/b]\n"+world.mountain.letters_objective()
		quest_action.disabled=true; quest_action.text="Speak to Runa, Hadrik and Sera in Wyrmkeep"
	elif selected_quest=="side_hallowcliff" and is_instance_valid(world.shore):
		quest_text.text+="\n\n"+world.shore.light_objective()
		quest_action.text="Find relief pilot Mara in Saltbreak"; quest_action.disabled=true
	elif selected_quest=="side_ashport" and is_instance_valid(world.shore):
		quest_text.text+="\n\n[b]Progress[/b]\n"+world.shore.ash_objective()
		quest_action.disabled=true; quest_action.text="Find the Ashport claimants in Saltbreak"
	elif selected_quest=="side_saltbreak" and is_instance_valid(world.shore):
		quest_text.text+="\n\n[b]Progress[/b]\n"+world.shore.silver_objective()
		quest_action.disabled=true; quest_action.text="Speak to Sella at Saltbreak"
	elif selected_quest=="side_sunken_lens" and is_instance_valid(world.lens):
		quest_text.text+="\n\n[b]Progress[/b]\n"+world.lens.debt_objective()
		quest_action.disabled=true; quest_action.text="Speak to Veyra at the Sunken Lens"
	elif selected_quest=="side_mirewatch" and is_instance_valid(world.convergence):
		quest_text.text+="\n\n[b]Progress[/b]\n"+world.convergence.rescue_objective()
		quest_action.disabled=true; quest_action.text="Speak to Ilyra at Mirewatch; follow the western lodge deck"
	elif selected_quest=="broken_seal" and is_instance_valid(world.seal):
		quest_text.text+="\n\n[b]Progress[/b]\n"+world.seal.objective()+"\n\nUse the caldera service lift south of Frostmere after defending Northwatch."
		quest_action.disabled=true; quest_action.text="Investigate the furnace supply line"
	elif selected_quest=="winter_siege" and is_instance_valid(world.winter):
		quest_text.text+="\n\n[b]Progress[/b]\n"+world.winter.objective()+"\n\nTake the Northwatch supply road south of Frostmere after returning from Aeralis."
		quest_action.disabled=true; quest_action.text="Answer the Northwatch distress call"
	elif selected_quest=="threshold" and is_instance_valid(world.threshold):
		quest_text.text+="\n\n[b]Progress[/b]\n"+world.threshold.objective()+"\n\nDeparture is beside the star chart in the Sunken Lens. Completing the return unlocks the Aeralis crossing in Frostmere."
		quest_action.disabled=true; quest_action.text="Use the crossing in the Sunken Lens vault"
	elif selected_quest=="convergence" and is_instance_valid(world.convergence):
		quest_text.text+="\n\n[b]Progress[/b]\n"+world.convergence.objective()+"\n\nBoth woodland pacts and both harbor outcomes support the expedition. Report the test to earn a Wayfarer Shield and Pathfinder Sabatons."
		quest_action.disabled=true; quest_action.text="Prepare the expedition at Mirewatch"
	elif selected_quest=="choir" and is_instance_valid(world.choir):
		quest_text.text+="\n\n[b]Progress[/b]\n"+world.choir.objective()+"\n\nReturn the distress signal for resonance patterns and a Cantor’s Staff. No cult membership is required."
		quest_action.disabled=true; quest_action.text="Follow the ash pilgrimage after The Divided Council"
	elif selected_quest=="roots" and is_instance_valid(world.roots):
		quest_text.text+="\n\n[b]Progress[/b]\n"+world.roots.objective()+"\n\nWild pact: healing armor. Tended pact: stamina axe. Both grant woodland bow patterns. Return to Maelin after the pact to begin the Coven initiation."
		quest_action.disabled=true; quest_action.text="Follow the Amberweald trail after Stonewake"
	elif selected_quest=="lens" and is_instance_valid(world.lens):
		quest_text.text+="\n\n[b]Progress[/b]\n"+world.lens.objective()+"\n\nReturn the star chart to Veyra for Sunlance, solar-forging patterns and a Horizon Staff. The expedition follows the atlas; earlier space prerequisites remain intact."
		quest_action.disabled=true; quest_action.text="Speak with Veyra at the Sunken Lens"
	elif selected_quest == "tides" and is_instance_valid(world.shore):
		quest_text.text+="\n\n[b]Progress[/b]\n"+world.shore.objective()+"\n\nIdentify recovered relics with Neris. The core can power Saltbreak or restore navigation; claim your final reward from Sella."
		quest_action.disabled=true; quest_action.text="Follow the coastal road after The Missing Atlas"
	elif selected_quest=="briar_coven_3" and is_instance_valid(world.roots):
		quest_text.text+="\n\n[b]Progress[/b]\n"+world.roots.promise_objective()
		quest_action.disabled=true; quest_action.text="Hear the keepers and memory; decide at the Stag Heart"
	elif selected_quest=="briar_coven_2" and is_instance_valid(world.roots):
		quest_text.text+="\n\n[b]Progress[/b]\n"+world.roots.debt_objective()
		quest_action.disabled=true; quest_action.text="Investigate the lodge and return to Maelin"
	elif selected_quest=="briar_coven_1" and is_instance_valid(world.roots):
		quest_text.text+="\n\n[b]Progress[/b]\n"+world.roots.coven_objective()
		quest_action.disabled=true; quest_action.text="Speak with Maelin at the Stag Shrine"
	elif selected_quest=="lantern_3" and is_instance_valid(world.archive_chapter):
		quest_text.text+="\n\n[b]Progress[/b]\n"+world.archive_chapter.price_objective()
		quest_action.disabled=true; quest_action.text="Hear both factions and decide at the archive seal"
	elif selected_quest=="lantern_2" and is_instance_valid(world.archive_chapter):
		quest_text.text+="\n\n[b]Progress[/b]\n"+world.archive_chapter.names_objective()
		quest_action.disabled=true; quest_action.text="Recover Mirewatch records, then return to Mereth"
	elif selected_quest=="lantern_1" and is_instance_valid(world.archive_chapter):
		quest_text.text+="\n\n[b]Progress[/b]\n"+world.archive_chapter.lantern_objective()
		quest_action.disabled=true; quest_action.text="Speak with Mereth in Pinehall"
	elif selected_quest == "archive" and is_instance_valid(world.archive_chapter):
		quest_text.text += "\n\n[b]Progress[/b]\n" + world.archive_chapter.objective() + "\n\nThe Lantern rewards a chain-lightning staff pattern; the Coven rewards healing armor. Only the chosen recipient's pattern is granted."
		quest_action.disabled = true; quest_action.text = "Speak with Mereth or Aelin in Pinehall"
	elif selected_quest in ["council", "iron_pact_1", "iron_pact_2", "iron_pact_3"] and is_instance_valid(world.mountain):
		quest_text.text += "\n\n[b]Progress[/b]\n" + world.mountain.objective() + "\n\nCouncil membership is optional. Take clan oaths and claim ranks in person with a sponsor."
		quest_action.disabled = true
		quest_action.text = "Speak to the council or clan sponsor"
	elif selected_quest == "stonewake" and is_instance_valid(world.stonewake):
		quest_text.text += "\n\n[b]Progress[/b]\n" + world.stonewake.objective() + "\n\nSpeak with Ilyra beside the northern village house. Blue ward markers appear on the Frostmere-area map after accepting."
		quest_action.disabled = true
		quest_action.text = "Chapter completed" if world.player.character.stonewake.rewarded else "Speak with Ilyra in the village"
	elif selected_quest in ["returning_light", "last_furnace"] and is_instance_valid(world.realms):
		var id := "aeralis" if selected_quest == "returning_light" else "crucible"
		var realm: Dictionary = world.realms.definitions[id]
		var completed: bool = id in world.player.character.realm_progress.completed
		quest_text.text += "\n\n[b]Realm chapter[/b]\n" + realm.name + "\n" + realm.story
		quest_text.text += "\n\n" + ("Guardian relic recovered and returned home." if completed else "The arrival route, sentries, guardian, loot and return gate are built. Campaign access requires the earlier chapters; isolated previews are available through the realm launchers.")
		if id=="crucible":
			quest_text.text+="\n\n"+("Read the Returning Light chronicle beside the home-world gates for your heirloom and all three Dawnforged patterns." if completed else "Defeat every defender, recover the Warden relic, use the shutdown console on the final terrace, then return home.")
		quest_action.text = "Realm chapter completed" if completed else "Enter through the watchstone gate"
		quest_action.disabled = true
	elif quest.status == "playable":
		quest_text.text += "\n\n[b]Progress[/b]\n%d / 3 objectives\n%s" % [atlas.survey_stage, atlas.objective_text() if atlas.survey_started else "Ready to begin"]

	for route in CampaignGuide.routes(world):
		if route.id==selected_quest:
			quest_text.text+="\n\n[b]Route from Frostmere[/b]\n"+route.directions+".\nThis path is open."
			if CampaignGuide.routes(world).size()>1: quest_text.text+=" Other available branches can be played in either order."

func _place_action() -> void:
	if selected_kind == "site":
		atlas.set_waypoint(selected_id)
	elif selected_kind == "location" and selected_id == "frostmere":
		set_view(true)

func _start_survey() -> void:
	if atlas.start_quest("oldwatch_survey"):
		set_view(true)
		_selected("site", atlas.waypoint)

func close() -> void:
	world.player.map_open = false
	world.player.set_paused(false)

func _process(_delta: float) -> void:
	visible = world.player.map_open
