extends RefCounted
var state: RefCounted
func _init(character: RefCounted) -> void:
	state = character
func shop(id: String) -> Dictionary:
	for entry: Dictionary in state.shop_data.shops:
		if entry.id == id: return entry
	return {}
func merchant(id: String) -> Dictionary:
	if state.merchants.has(id): return state.merchants[id]
	var info := shop(id)
	if info.is_empty(): return {}
	var stock := {}
	for entry: Dictionary in info.stock: stock[entry.id] = int(entry.count)
	return {"purse": int(info.purse), "stock": stock, "buyback": {}}
func entry(shop_id: String, sku: String) -> Dictionary:
	for row: Dictionary in shop(shop_id).get("stock", []):
		if row.id == sku: return row
	var kind := sku.get_slice(":", 0)
	var id := sku.get_slice(":", 1)
	if kind in ["material", "consumable"] and state.shop_data[kind + "_values"].has(id) and merchant(shop_id).get("stock", {}).has(sku):
		return {"id": sku, "kind": kind, "item": id}
	return {}
func gear_value(record: Dictionary) -> int:
	var item: Dictionary = state.items[record.base_id]
	return 20 + int(item.get("damage", 0)) * 6 + int(item.get("armor", 0)) * 5 + int(record.quality) * 28 + (60 if record.enchant != "" else 0) + (85 if record.gem != "" else 0)
func value(kind: String, id: String, record: Dictionary = {}) -> int:
	if kind == "gear":
		return gear_value(record if not record.is_empty() else state._record(id)) if state.items.has(id) else 0
	return int(state.shop_data.get(kind + "_values", {}).get(id, 0))
func quote(base: int, buying: bool) -> int:
	var barter := clampf(float(state.stats().barter), 0, 25) / 100
	return maxi(1, ceili(base * 1.35 * (1 - barter)) if buying else floori(base * 0.45 * (1 + barter)))
func buy(shop_id: String, sku: String, quantity: int) -> String:
	var offer := entry(shop_id, sku)
	if offer.is_empty() or quantity < 1 or quantity > 99: return "Invalid purchase."
	var vendor := merchant(shop_id)
	if int(vendor.stock.get(sku, 0)) < quantity: return "Not enough stock."
	var price := quote(value(offer.kind, offer.item), true) * quantity
	if state.gold < price: return "Not enough gold."
	state.gold -= price
	vendor.purse += price
	vendor.stock[sku] -= quantity
	if offer.kind == "gear":
		for i in range(quantity): state.add_item(offer.item)
	else:
		var bag: Dictionary = state.materials if offer.kind == "material" else state.consumables
		bag[offer.item] = int(bag.get(offer.item, 0)) + quantity
	state.merchants[shop_id] = vendor
	state._commit()
	return "Bought %d × %s for %d gold." % [quantity, item_name(offer.kind, offer.item), price]
func sell(shop_id: String, kind: String, id: String, quantity: int) -> String:
	if shop(shop_id).is_empty() or quantity < 1 or quantity > 99 or kind not in ["gear", "material", "consumable"]: return "Invalid sale."
	var record: Dictionary = state.inventory.get(id, {}) if kind == "gear" else {}
	if kind == "gear" and (quantity != 1 or state.protected_item(id)): return "Unequip and unfavorite that piece before selling."
	var bag: Dictionary = state.materials if kind == "material" else state.consumables
	if kind != "gear" and int(bag.get(id, 0)) < quantity: return "Not enough owned items."
	var base := value(kind, record.base_id if kind == "gear" else id, record)
	if base <= 0: return "This item cannot be sold."
	var price := quote(base, false) * quantity
	var vendor := merchant(shop_id)
	if vendor.purse < price: return "The merchant does not have enough gold."
	var title := item_name(kind, record.base_id if kind == "gear" else id)
	if kind == "gear":
		vendor.buyback[id] = record.duplicate(true)
		state.inventory.erase(id)
	else:
		bag[id] -= quantity
		# Sold stacks enter stock, including items outside the original assortment.
		var sku := kind + ":" + id
		vendor.stock[sku] = int(vendor.stock.get(sku, 0)) + quantity
	state.gold += price
	vendor.purse -= price
	state.merchants[shop_id] = vendor
	state._commit()
	return "Sold %d × %s for %d gold." % [quantity, title, price]
func buyback(shop_id: String, uid: String) -> String:
	var vendor := merchant(shop_id)
	if vendor.is_empty() or not vendor.buyback.has(uid) or state.inventory.has(uid): return "This piece is not available."
	var record: Dictionary = vendor.buyback[uid]
	var price := quote(gear_value(record), true)
	if state.gold < price: return "Not enough gold."
	state.gold -= price
	vendor.purse += price
	state.inventory[uid] = record.duplicate(true)
	vendor.buyback.erase(uid)
	state.merchants[shop_id] = vendor
	state._commit()
	return "Bought back your original piece for %d gold; its upgrades are intact." % price
func item_name(kind: String, id: String) -> String:
	if kind == "gear": return state.items.get(id, {}).get("name", id)
	return state.definition("materials" if kind == "material" else "consumables", id).get("name", id)
