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

func sell(wallet: Dictionary, inventory: Dictionary, operation_id: String, slot_index: int, template: Dictionary, quantity: int) -> Dictionary:
	if operation_id.empty() or quantity < 1 or bool(template.get("quest", false)):
		return _failure(wallet, inventory)
	var wallet_state = load("res://actors/WalletState.gd").new()
	var normalized_wallet = wallet_state.normalize(wallet)
	var inventory_state = load("res://actors/InventoryState.gd").new()
	var normalized_inventory = inventory_state.export_state(inventory)
	if normalized_wallet.empty() or normalized_inventory.empty():
		return _failure(wallet, inventory)
	if normalized_wallet.ledger.has(operation_id):
		return {"ok": true, "duplicate": true, "wallet": normalized_wallet, "inventory": normalized_inventory}
	var quote = load("res://actors/ShopQuote.gd").new().sell(template, quantity)
	if quote.empty():
		return _failure(normalized_wallet, normalized_inventory)
	var next_inventory = inventory_state.consume(normalized_inventory, slot_index, quantity, template)
	if next_inventory.empty():
		return _failure(normalized_wallet, normalized_inventory)
	var credited = wallet_state.apply(normalized_wallet, operation_id, int(quote.total_price), 0)
	if not credited.ok:
		return _failure(normalized_wallet, normalized_inventory)
	return {"ok": true, "duplicate": false, "wallet": credited.state, "inventory": next_inventory}

func _failure(wallet: Dictionary, inventory: Dictionary) -> Dictionary:
	return {"ok": false, "duplicate": false, "wallet": wallet.duplicate(true), "inventory": inventory.duplicate(true)}
