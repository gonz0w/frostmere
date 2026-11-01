extends ColorRect
## Inventory browsing anywhere; transactions re-check physical workstation access.
var world: Node3D
var state: RefCounted
var tabs: OptionButton
var listing: ItemList
var detail: Label
var actions: VBoxContainer
var banner: Label
var status: Label
var search: LineEdit
var ids: Array[String] = []
var selected := ""
var mode := "Gear"
const MODES := ["Gear", "Materials", "Forge", "Improve", "Enchant", "Salvage", "Alchemy", "Cooking", "Consumables", "Collection"]

func _ready() -> void:
	state = world.player.character
	color = Color("0d171f")
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 30)
	add_child(margin)
	var page := VBoxContainer.new()
	page.add_theme_constant_override("separation", 14)
	margin.add_child(page)
	var header := HBoxContainer.new()
	page.add_child(header)
	var title := label(header, "THE COLLECTOR'S WORKSHOP", 25)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button(header, "Return to world  [ I / Esc ]", close)
	banner = label(page, "", 15)
	tabs = OptionButton.new()
	for entry: String in MODES:
		tabs.add_item(entry)
	tabs.item_selected.connect(func(index: int): mode = MODES[index]; selected = ""; refresh())
	page.add_child(tabs)
	var columns := HBoxContainer.new()
	columns.add_theme_constant_override("separation", 30)
	columns.size_flags_vertical = Control.SIZE_EXPAND_FILL
	page.add_child(columns)
	var left := VBoxContainer.new()
	left.custom_minimum_size.x = 390
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	columns.add_child(left)
	search = LineEdit.new()
	search.placeholder_text = "Search this collection…"
	search.text_changed.connect(func(_text: String): refresh())
	left.add_child(search)
	listing = ItemList.new()
	listing.size_flags_vertical = Control.SIZE_EXPAND_FILL
	listing.add_theme_font_size_override("font_size", 16)
	listing.item_selected.connect(func(index: int): selected = ids[index]; show_detail())
	left.add_child(listing)
	var scroll := ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_stretch_ratio = 1.3
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	columns.add_child(scroll)
	var right := VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.add_theme_constant_override("separation", 15)
	scroll.add_child(right)
	detail = label(right, "", 17)
	detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	actions = VBoxContainer.new()
	actions.add_theme_constant_override("separation", 9)
	right.add_child(actions)
	status = label(page, "", 14)
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label(page, "E at nearby workstations / gathering spots · C to equip gear · M for your atlas", 13)
	state.changed.connect(refresh)
	refresh()
	visible = false

func label(parent: Node, text: String, size: int) -> Label:
	var node := Label.new()
	node.text = text
	node.add_theme_font_size_override("font_size", size)
	node.add_theme_color_override("font_color", Color("dbd3bd"))
	parent.add_child(node)
	return node

func button(parent: Node, text: String, call: Callable, enabled: bool = true) -> Button:
	var node := Button.new()
	node.text = text
	node.custom_minimum_size.y = 36
	node.disabled = not enabled
	node.pressed.connect(call)
	parent.add_child(node)
	return node

func station() -> String:
	return world.station_nearby()

func open(at_station: String = "") -> void:
	world.player.character_menu_open = false
	world.player.map_open = false
	world.player.workshop_open = true
	world.player.set_paused(true)
	mode = {"forge": "Forge", "enchant": "Enchant", "alchemy": "Alchemy", "cook": "Cooking"}.get(at_station, "Gear")
	tabs.select(MODES.find(mode))
	selected = ""
	search.text = ""
	status.text = "Collect the supply chest beside the south trail. Rare blueprints await beyond Oldwatch Crossing."
	refresh()

func close() -> void:
	world.player.workshop_open = false
	world.player.set_paused(false)

func _process(_delta: float) -> void:
	visible = world.player.workshop_open

func add_entry(id: String, title: String) -> void:
	if search.text != "" and not title.to_lower().contains(search.text.to_lower()):
		return
	ids.append(id)
	listing.add_item(title)

func refresh() -> void:
	if listing == null:
		return
	var place := station()
	banner.text = "%s  ·  %d owned pieces  ·  %d / %d designs discovered  ·  Craft XP %d" % [place.capitalize() + " workstation" if place != "" else "Travel bag — visit a workstation to craft", state.inventory.size(), state.discovered.size(), state.items.size(), state.craft_xp]
	listing.clear()
	ids.clear()
	if mode in ["Gear", "Improve", "Enchant", "Salvage"]:
		for uid: String in state.inventory:
			var record: Dictionary = state.inventory[uid]
			add_entry(uid, ("★ " if record.favorite else "") + state.describe_item(uid).name + (" [equipped]" if uid in state.equipment.values() else ""))
	elif mode in ["Forge", "Alchemy", "Cooking"]:
		var target: String = {"Forge": "forge", "Alchemy": "alchemy", "Cooking": "cook"}[mode]
		for recipe: Dictionary in state.crafting.recipes:
			if recipe.station == target or (mode == "Forge" and recipe.output_kind == "material"):
				add_entry(recipe.id, recipe.name + (" [blueprint needed]" if recipe.unlock not in state.blueprints else ""))
	elif mode == "Materials":
		for material: Dictionary in state.crafting.materials:
			add_entry(material.id, "%s ×%d" % [material.name, state.materials.get(material.id, 0)])
	elif mode == "Consumables":
		for food: Dictionary in state.crafting.consumables:
			add_entry(food.id, "%s ×%d" % [food.name, state.consumables.get(food.id, 0)])
	elif mode == "Collection":
		for item: Dictionary in state.catalog.items:
			add_entry(item.id, item.name + (" [discovered]" if item.id in state.discovered else " [not found]"))
	if selected not in ids:
		selected = ids[0] if not ids.is_empty() else ""
	if selected != "":
		listing.select(ids.find(selected))
	show_detail()

func result(message: String) -> void:
	var successful := message.begins_with("Created") or message.begins_with("Improved") or message.begins_with("Applied") or message.begins_with("Gem") or message.begins_with("Item") or message.begins_with("Used")
	var cue := "error"
	if message in ["Equipped.", "Item named."]: cue="interact"
	elif successful: cue="heal" if message.begins_with("Used") else "enchant" if station()=="enchant" else "forge" if station()=="forge" else "loot"
	world.audio.sfx(cue)
	status.text = message + (" " + state.last_error if state.last_error != "" else "")

func show_detail() -> void:
	for child in actions.get_children():
		actions.remove_child(child)
		child.queue_free()
	if selected == "":
		detail.text = "No matching items. Explore, gather, or forge your next find."
		return
	var uid := selected
	var place := station()
	if mode in ["Gear", "Improve", "Enchant", "Salvage"]:
		var item: Dictionary = state.describe_item(uid)
		var record: Dictionary = state.inventory[uid]
		var bonuses: PackedStringArray = []
		for attr: String in item.bonuses:
			bonuses.append("+%d %s" % [item.bonuses[attr], attr.capitalize()])
		detail.text = "%s\n%s\n\nArmor %d  ·  Base damage %d  ·  %.1f kg\n%s\n\nEnchantment: %s\nGem: %s\nQuality: %s" % [item.name, item.description, item.get("armor", 0), item.get("damage", 0), item.weight, ", ".join(bonuses), state.definition("enchants", record.enchant).get("name", "None"), state.definition("gems", record.gem).get("name", "Empty — unlocks at Superior"), state.crafting.quality_names[int(record.quality)]]
		if item.get("family", "") == "staff":
			detail.text += "\nStaff: +%d spell power while equipped (before perks)." % state.staff_spell_bonus(item)
		if mode == "Gear":
			var title := LineEdit.new()
			title.placeholder_text = "Give this piece a personal name"
			title.max_length = 32
			title.text = record.custom_name
			actions.add_child(title)
			button(actions, "Save item name", func(): state.personalize(uid, title.text, record.favorite); result("Item named."))
			button(actions, "Unfavorite" if record.favorite else "★ Favorite — protect from salvage", func(): state.personalize(uid, record.custom_name, not record.favorite))
			button(actions, "Equip in " + item.slot.capitalize(), func(): result("Equipped." if state.equip(uid, item.slot) else state.last_error))
			if uid in state.equipment.values():
				button(actions, "Unequip", func():
					for slot: String in state.equipment:
						if state.equipment[slot] == uid: state.unequip(slot))
		elif mode == "Improve":
			var cost: Dictionary = state.temper_cost(uid)
			detail.text += "\n\nNext: +2 base damage / armor where applicable.\nIngredients (owned / required):\n" + state.cost_text(cost)
			if item.get("family", "") == "staff" and int(record.quality) < 5:
				detail.text += "\nThis staff upgrade also adds +1 spell power before perks."
			button(actions, "Temper to " + state.crafting.quality_names[mini(5, int(record.quality) + 1)], func(): result(state.improve(uid, station())), place == "forge" and not cost.is_empty() and state.can_pay(cost) and (item.has("armor") or item.has("damage")))
			label(actions, "Legendary is the final quality. Rare upgrades use Ember Cores\nor the matching realm material; see the ingredient list.", 13)
		elif mode == "Enchant":
			label(actions, "Applying a formula replaces the current enchantment.\nEach formula lists its own material cost.", 14)
			for formula: String in state.formulas:
				var entry: Dictionary = state.definition("enchants", formula)
				button(actions, entry.name + " — " + entry.description + "\n" + state.cost_text(entry.cost).replace("\n", " · "), func(): result(state.enchant_item(uid, formula, station())), place == "enchant" and state.can_pay(entry.cost) and record.enchant != formula)
			for gem: Dictionary in state.crafting.gems:
				button(actions, "Socket " + gem.name + " (1 gem)", func(): result(state.socket_gem(uid, gem.id, station())), place == "enchant" and record.quality >= 2 and record.gem == "" and state.can_pay({gem.id: 1}))
			button(actions, "Extract gem — 1 Rune Dust; gem returned", func(): result(state.extract_gem(uid, station())), place == "enchant" and record.gem != "" and state.can_pay({"rune_dust": 1}))
			label(actions, "Study consumes this item, including its upgrades and gem.", 13)
			button(actions, "Destroy item to learn its enchantment", func(): result(state.dismantle(uid, true, station())), place == "enchant" and not state.protected_item(uid) and record.enchant != "" and record.enchant not in state.formulas)
		else:
			var yields: Dictionary = state.salvage_yield(uid)
			detail.text += "\n\nDESTROYS THIS ITEM, its upgrades, enchantment and gem.\nRecover:"
			for material: String in yields:
				detail.text += "\n%d %s" % [yields[material], state.definition("materials", material).name]
			button(actions, "Destroy item and salvage materials", func(): result(state.dismantle(uid, false, station())), place == "forge" and not state.protected_item(uid))
			label(actions, "Equipped and favorited gear is protected.", 14)
	elif mode in ["Forge", "Alchemy", "Cooking"]:
		var recipe: Dictionary = state.definition("recipes", uid)
		detail.text = "%s\n\nWorkstation: %s\nBlueprint: %s %s\n\nIngredients (owned / required):\n%s" % [recipe.name, recipe.station.capitalize(), recipe.unlock.capitalize(), "— learned" if recipe.unlock in state.blueprints else "— explore supply caches", state.cost_text(recipe.cost)]
		if recipe.output_kind == "gear":
			var item: Dictionary = state.items[recipe.output]
			detail.text += "\n\n" + item.description + "\nArmor %d · Base damage %d\nCreates a new owned piece; temper and enchant it afterwards." % [item.get("armor", 0), item.get("damage", 0)]
		elif recipe.output_kind == "consumable":
			var food: Dictionary = state.definition("consumables", recipe.output)
			detail.text += "\n\nRestores %d %s. Use from Consumables." % [food.restore, food.pool]
		button(actions, "Craft " + recipe.name, func(): result(state.craft_recipe(uid, station())), place == recipe.station and recipe.unlock in state.blueprints and state.can_pay(recipe.cost))
		if state.recipe_batchable(recipe):
			var group: String="materials" if recipe.output_kind=="material" else "consumables"
			var output_name: String=state.definition(group,recipe.output).get("name",recipe.output)
			for count in [5,10]:
				var cost: Dictionary=state.batch_cost(uid,count)
				var batch_button:=button(actions,"Craft %d batches · %d %s" % [count,int(recipe.amount)*count,output_name],func(): result(state.craft_recipe(uid,station(),count)),place==recipe.station and recipe.unlock in state.blueprints and state.can_pay(cost))
				batch_button.tooltip_text="Total ingredients (owned / required):\n"+state.cost_text(cost)
				label(actions,state.cost_text(cost).replace("\n"," · "),12)
	elif mode == "Materials":
		detail.text = "%s\n\nIn your bag: %d\n\nGather ore, herbs, mushrooms and supplies along the village paths and beyond the crossing.\n\nSmelt ore and refine hides at the forge. Grind crystals into rune dust at the Runewright's Table (Forge recipes).\n\nSupply chests contain rare gear and blueprint sets. Gathering spots replenish; chests are one-time finds." % [state.definition("materials", uid).name, state.materials.get(uid, 0)]
	elif mode == "Consumables":
		var food: Dictionary = state.definition("consumables", uid)
		var preview: Dictionary = state.consumable_preview(uid, world.player)
		detail.text = "%s\n\nOwned: %d\nRestores up to %s %s%s\nCurrent: %s / %s\n\nUse now: +%s %s\nUnused restoration: %s\n\nItems are kept if the resource is already full." % [food.name, state.consumables.get(uid, 0), String.num(preview.restore, 2), food.pool, " (includes 25% armor bonus)" if preview.boosted else "", String.num(world.player.get(food.pool), 2), String.num(world.player.derived[food.pool], 2), String.num(preview.actual, 2), food.pool, String.num(preview.unused, 2)]
		button(actions, "Use " + food.name, func(): result(state.consume(uid, world.player)), int(state.consumables.get(uid, 0)) > 0 and preview.actual > 0)
	else:
		var item: Dictionary = state.items[uid]
		detail.text = "%s\n\n%s\n\n%s\n\nCollection credit stays after salvage. Crafting or finding a design marks it discovered; duplicate pieces keep their own upgrades." % [item.name, "DISCOVERED" if uid in state.discovered else "NOT YET FOUND", item.description]
