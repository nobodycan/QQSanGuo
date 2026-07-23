extends Reference

func purchase(wallet: Dictionary, inventory: Dictionary, operation_id: String, definition: Dictionary, flags: Array, templates_by_id: Dictionary, item_id: String, quantity: int) -> Dictionary:
	if item_id.empty() or quantity < 1:
		return _failure(wallet, inventory)
	var products = load("res://actors/ShopDefinition.gd").new().available(definition, flags)
	for product in products:
		if str(product.get("item_id", "")) == item_id:
			return load("res://actors/ShopService.gd").new().buy(wallet, inventory, operation_id, product, templates_by_id, quantity)
	return _failure(wallet, inventory)

func _failure(wallet: Dictionary, inventory: Dictionary) -> Dictionary:
	return {"ok": false, "duplicate": false, "wallet": wallet.duplicate(true), "inventory": inventory.duplicate(true)}
