extends Reference

func purchase(wallet: Dictionary, inventory: Dictionary, operation_id: String, definition: Dictionary, flags: Array, templates_by_id: Dictionary, item_id: String, quantity: int) -> Dictionary:
	if item_id.empty() or quantity < 1:
		return _failure(wallet, inventory)
	var products = load("res://actors/ShopDefinition.gd").new().available(definition, flags)
	for product in products:
		if str(product.get("item_id", "")) == item_id:
			return load("res://actors/ShopService.gd").new().buy(wallet, inventory, operation_id, product, templates_by_id, quantity)
	return _failure(wallet, inventory)

func purchase_registered(wallet: Dictionary, inventory: Dictionary, operation_id: String, definition: Dictionary, flags: Array, registry: Node, item_id: String, quantity: int) -> Dictionary:
	if registry == null or not registry.has_method("get_entry") or item_id.empty():
		return _failure(wallet, inventory)
	var entry = registry.get_entry(item_id)
	if not entry.get("ok", false):
		return _failure(wallet, inventory)
	var template = load("res://actors/ItemTemplate.gd").new().normalize(entry.data)
	if template.empty():
		return _failure(wallet, inventory)
	return purchase(wallet, inventory, operation_id, definition, flags, {item_id: template}, item_id, quantity)

func _failure(wallet: Dictionary, inventory: Dictionary) -> Dictionary:
	return {"ok": false, "duplicate": false, "wallet": wallet.duplicate(true), "inventory": inventory.duplicate(true)}
