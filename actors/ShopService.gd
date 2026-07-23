extends Reference

func buy(wallet: Dictionary, inventory: Dictionary, operation_id: String, product: Dictionary, templates_by_id: Dictionary, quantity: int) -> Dictionary:
	if operation_id.empty() or quantity < 1 or str(product.get("item_id", "")).empty():
		return _failure(wallet, inventory)
	var item_id = str(product.item_id)
	if not templates_by_id.has(item_id):
		return _failure(wallet, inventory)
	var quote = load("res://actors/ShopQuote.gd").new().buy({"id": item_id, "buy_price": int(product.get("buy_price", -1))}, quantity)
	if quote.empty():
		return _failure(wallet, inventory)
	return load("res://actors/EconomyTransaction.gd").new().buy(wallet, inventory, operation_id, templates_by_id[item_id], quantity, int(quote.total_price))

func _failure(wallet: Dictionary, inventory: Dictionary) -> Dictionary:
	return {"ok": false, "duplicate": false, "wallet": wallet.duplicate(true), "inventory": inventory.duplicate(true)}
