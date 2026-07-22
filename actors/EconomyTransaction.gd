extends Reference

const WalletState = preload("res://actors/WalletState.gd")
const InventoryState = preload("res://actors/InventoryState.gd")
const ItemInstance = preload("res://actors/ItemInstance.gd")

func buy(wallet: Dictionary, inventory: Dictionary, operation_id: String, template: Dictionary, quantity: int, money_cost: int, juntuan_cost: int = 0) -> Dictionary:
	var normalized_wallet = WalletState.new().normalize(wallet)
	var normalized_inventory = InventoryState.new().export_state(inventory)
	if normalized_wallet.empty() or normalized_inventory.empty() or operation_id.empty() or template.empty() or quantity < 1 or money_cost < 0 or juntuan_cost < 0:
		return _failure(wallet, inventory)
	if normalized_wallet.ledger.has(operation_id):
		return {"ok": true, "duplicate": true, "wallet": normalized_wallet, "inventory": normalized_inventory}
	var next_inventory = InventoryState.new().add(normalized_inventory, template, quantity, ItemInstance.new())
	if next_inventory.empty():
		return _failure(normalized_wallet, normalized_inventory)
	var wallet_result = WalletState.new().apply(normalized_wallet, operation_id, -money_cost, -juntuan_cost)
	if not wallet_result.ok:
		return _failure(normalized_wallet, normalized_inventory)
	return {"ok": true, "duplicate": false, "wallet": wallet_result.state, "inventory": next_inventory}

func _failure(wallet: Dictionary, inventory: Dictionary) -> Dictionary:
	return {"ok": false, "duplicate": false, "wallet": wallet.duplicate(true), "inventory": inventory.duplicate(true)}
