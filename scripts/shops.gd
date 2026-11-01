extends Node3D
const Trade = preload("res://scripts/trade.gd")
const State = preload("res://scripts/character_state.gd")
const Visual = preload("res://scripts/character_visual.gd")
var world: Node3D
var trade: RefCounted
var shop_id := ""
var panel: ColorRect
var title: Label
var balance: Label
var mode: OptionButton
var listing: ItemList
var detail: Label
var quantity: SpinBox
var action: Button
var status: Label
var search: LineEdit
var ids: Array[String] = []
var selected := ""
var greeting_visits: Dictionary={}

func _ready() -> void:
	trade = Trade.new(world.player.character)
	for shop: Dictionary in trade.state.shop_data.shops:
		var npc := Visual.new()
		var p: Array = shop.npc_position
		npc.position = Vector3(p[0], p[1], p[2])
		npc.rotation.y = PI
		add_child(npc)
		var state := State.new()
		state.origin_id = shop.origin
		for slot: String in state.equipment: state.equipment[slot] = ""
		for slot in ["chest", "hands", "legs", "feet"]: state.equip(state.add_item(shop.armor + "_" + slot), slot)
		npc.build(state)
		world._craft_sign(npc.position + Vector3.UP * 0.6, shop.merchant + " · " + shop.role, Color("e5c795"))
	var layer := CanvasLayer.new()
	layer.layer = 5
	add_child(layer)
	panel = ColorRect.new()
	panel.color = Color("101b23")
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer.add_child(panel)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]: margin.add_theme_constant_override("margin_" + side, 32)
	panel.add_child(margin)
	var page := VBoxContainer.new()
	page.add_theme_constant_override("separation", 16)
	margin.add_child(page)
	var header := HBoxContainer.new()
	page.add_child(header)
	title = label(header, "", 27)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var leave := Button.new()
	leave.text = "Leave shop  [ Esc ]"
	leave.pressed.connect(close)
	header.add_child(leave)
	balance = label(page, "", 16)
	mode = OptionButton.new()
	for text in ["Buy", "Sell gear", "Sell materials", "Sell consumables", "Buy back gear"]: mode.add_item(text)
	mode.item_selected.connect(func(_i: int): selected = ""; quantity.value = 1; refresh())
	page.add_child(mode)
	var columns := HBoxContainer.new()
	columns.add_theme_constant_override("separation", 30)
	columns.size_flags_vertical = Control.SIZE_EXPAND_FILL
	page.add_child(columns)
	var left := VBoxContainer.new()
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	columns.add_child(left)
	search = LineEdit.new()
	search.placeholder_text = "Search this list…"
	search.text_changed.connect(func(_text: String): refresh())
	left.add_child(search)
	listing = ItemList.new()
	listing.size_flags_vertical = Control.SIZE_EXPAND_FILL
	listing.add_theme_font_size_override("font_size", 16)
	listing.item_selected.connect(func(i: int): selected = ids[i]; show_detail())
	left.add_child(listing)
	var right := VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.add_theme_constant_override("separation", 18)
	columns.add_child(right)
	detail = label(right, "", 18)
	detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail.size_flags_vertical = Control.SIZE_EXPAND_FILL
	quantity = SpinBox.new()
	quantity.min_value = 1
	quantity.max_value = 99
	quantity.value = 1
	quantity.prefix = "Quantity: "
	quantity.value_changed.connect(func(_value: float): show_detail())
	right.add_child(quantity)
	action = Button.new()
	action.custom_minimum_size.y = 46
	action.pressed.connect(transact)
	right.add_child(action)
	status = label(page, "Prices include your Presence bonus. All transactions save locally.", 15)
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label(page, "Equipped and favorited pieces are protected. Sold gear keeps its upgrades in this merchant's buyback list.", 14)
	label(page, "Stock and merchant gold persist. No automatic restocking in this first shop pass.", 13)
	trade.state.changed.connect(refresh)
	panel.visible = false

func label(parent: Node, text: String, size: int) -> Label:
	var result := Label.new()
	result.text = text
	result.add_theme_font_size_override("font_size", size)
	result.add_theme_color_override("font_color", Color("ded4ba"))
	parent.add_child(result)
	return result
func nearby() -> String:
	for shop: Dictionary in trade.state.shop_data.shops:
		var p: Array = shop.position
		if world.player.global_position.distance_to(Vector3(p[0], p[1], p[2])) < 2.3: return shop.id
	return ""
func open(id: String) -> void:
	if id == "" or nearby() != id: return
	shop_id = id
	world.player.shop_open = true
	world.player.character_menu_open = false
	world.player.map_open = false
	world.player.workshop_open = false
	world.adventure.close_dialog()
	world.player.set_paused(true)
	mode.select(0)
	quantity.value = 1
	search.text = ""
	selected = ""
	status.text = next_greeting(id)
	refresh()
func next_greeting(id: String) -> String:
	var shop: Dictionary=trade.shop(id)
	var eligible: Array[String]=[]
	# Milestone lines precede everyday greetings; visits cycle through eligible lines.
	for record: Dictionary in shop.get("greetings",[]):
		if record.get("requires","")=="" or record.requires in trade.state.story_completed: eligible.push_front(record.text)
	if eligible.is_empty(): return "Welcome. Buy supplies or sell your spare finds."
	var key:=id+":"+str(eligible.size())
	var visit: int=greeting_visits.get(key,0)
	greeting_visits[key]=visit+1
	return str(shop.merchant)+": "+eligible[visit%eligible.size()]

func close() -> void:
	world.player.shop_open = false
	world.player.set_paused(false)
func _process(_delta: float) -> void:
	panel.visible = world.player.shop_open
func add_entry(id: String, text: String) -> void:
	if search.text != "" and not text.to_lower().contains(search.text.to_lower()): return
	ids.append(id)
	listing.add_item(text)
func record_name(record: Dictionary) -> String:
	return (record.custom_name if record.custom_name != "" else trade.state.items[record.base_id].name) + " · " + trade.state.crafting.quality_names[int(record.quality)] + (" of " + trade.state.definition("enchants", record.enchant).name if record.enchant != "" else "")
func refresh() -> void:
	if shop_id == "": return
	var info: Dictionary = trade.shop(shop_id)
	var vendor: Dictionary = trade.merchant(shop_id)
	title.text = info.name.to_upper() + "  /  " + info.merchant
	balance.text = "Your gold: %d    ·    Merchant gold: %d    ·    Barter bonus: %.1f%%" % [trade.state.gold, vendor.purse, trade.state.stats().barter]
	ids.clear()
	listing.clear()
	match mode.selected:
		0:
			for sku: String in vendor.stock:
				var row: Dictionary = trade.entry(shop_id, sku)
				if not row.is_empty(): add_entry(sku, "%s ×%d  ·  %dg" % [trade.item_name(row.kind, row.item), vendor.stock[sku], trade.quote(trade.value(row.kind, row.item), true)])
		1:
			for uid: String in trade.state.inventory:
				add_entry(uid, trade.state.describe_item(uid).name + (" [protected]" if trade.state.protected_item(uid) else ""))
		2, 3:
			var bag: Dictionary = trade.state.materials if mode.selected == 2 else trade.state.consumables
			for id: String in bag:
				if bag[id] > 0: add_entry(id, "%s ×%d" % [trade.item_name("material" if mode.selected == 2 else "consumable", id), bag[id]])
		4:
			for uid: String in vendor.buyback: add_entry(uid, record_name(vendor.buyback[uid]))
	if selected not in ids: selected = ids[0] if not ids.is_empty() else ""
	if selected != "": listing.select(ids.find(selected))
	show_detail()
func show_detail() -> void:
	if selected == "":
		detail.text = "Nothing here yet. Explore, collect, and return with your finds."
		action.disabled = true
		return
	var vendor: Dictionary = trade.merchant(shop_id)
	var kind := ""
	var id := selected
	var record := {}
	var available := 1
	match mode.selected:
		0:
			var row: Dictionary = trade.entry(shop_id, selected)
			if row.is_empty():
				detail.text = "This item is no longer available here."
				action.disabled = true
				return
			kind = row.kind; id = row.item; available = int(vendor.stock[selected])
		1:
			kind = "gear"; record = trade.state.inventory[selected]; id = record.base_id
		2:
			kind = "material"; available = int(trade.state.materials[selected])
		3:
			kind = "consumable"; available = int(trade.state.consumables[selected])
		4:
			kind = "gear"; record = vendor.buyback[selected]; id = record.base_id
	var buying := mode.selected in [0, 4]
	var count := 1 if mode.selected in [1, 4] else int(quantity.value)
	quantity.editable = mode.selected not in [1, 4]
	var price: int = trade.quote(trade.value(kind, id, record), buying) * count
	detail.text = (record_name(record) if not record.is_empty() else trade.item_name(kind, id)) + "\n\n"
	if kind == "gear":
		var item: Dictionary = trade.state.items[id]
		var rank: int = int(record.get("quality", 0))
		detail.text += item.description + "\n\nDamage %d · Armor %d\n" % [int(item.get("damage", 0)) + (rank * 2 if item.has("damage") else 0), int(item.get("armor", 0)) + (rank * 2 if item.has("armor") else 0)]
		if not record.is_empty(): detail.text += "Enchantment: %s\nGem: %s\n" % [record.enchant if record.enchant != "" else "None", record.gem if record.gem != "" else "None"]
	elif kind == "consumable":
		var item: Dictionary = trade.state.definition("consumables", id)
		detail.text += "Restores %d %s. Use from your bag." % [item.restore, item.pool]
	else: detail.text += "Crafting supplies and ammunition for your next expedition."
	detail.text += "\n\nAvailable: %d\n%s %d gold for %d item(s)." % [available, "Pay" if buying else "Receive", price, count]
	action.text = ("Buy back original piece" if mode.selected == 4 else "Buy" if buying else "Sell") + " · %d gold" % price
	action.disabled = nearby() != shop_id or count > available or (trade.state.gold < price if buying else vendor.purse < price) or (mode.selected == 1 and trade.state.protected_item(selected))
func transact() -> void:
	if nearby() != shop_id or not world.player.shop_open:
		status.text = "Return to the merchant to trade."; return
	var before: int = trade.state.gold
	var message := ""
	match mode.selected:
		0: message = trade.buy(shop_id, selected, int(quantity.value))
		1: message = trade.sell(shop_id, "gear", selected, 1)
		2: message = trade.sell(shop_id, "material", selected, int(quantity.value))
		3: message = trade.sell(shop_id, "consumable", selected, int(quantity.value))
		4: message = trade.buyback(shop_id, selected)
	world.audio.sfx("loot" if before != trade.state.gold else "error")
	status.text = message + (" " + trade.state.last_error if trade.state.last_error != "" else "")
