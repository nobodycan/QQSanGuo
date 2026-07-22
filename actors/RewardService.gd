extends Reference

const WalletState = preload("res://actors/WalletState.gd")
const InventoryState = preload("res://actors/InventoryState.gd")
const ItemInstance = preload("res://actors/ItemInstance.gd")

func grant(wallet: Dictionary, inventory: Dictionary, operation_id: String, money_reward: int, juntuan_reward: int, template: Dictionary = {}, quantity: int = 0) -> Dictionary:
	var normalized_wallet = WalletState.new().normalize(wallet)
	var normalized_inventory = InventoryState.new().export_state(inventory)
	if normalized_wallet.empty() or normalized_inventory.empty() or operation_id.empty() or money_reward < 0 or juntuan_reward < 0 or quantity < 0:
		return _failure(wallet, inventory)
	if normalized_wallet.ledger.has(operation_id):
		return {"ok": true, "duplicate": true, "wallet": normalized_wallet, "inventory": normalized_inventory}
	var next_inventory = normalized_inventory
	if quantity > 0:
		next_inventory = InventoryState.new().add(normalized_inventory, template, quantity, ItemInstance.new())
		if next_inventory.empty():
			return _failure(normalized_wallet, normalized_inventory)
	elif not template.empty():
		return _failure(normalized_wallet, normalized_inventory)
	var wallet_result = WalletState.new().apply(normalized_wallet, operation_id, money_reward, juntuan_reward)
	if not wallet_result.ok:
		return _failure(normalized_wallet, normalized_inventory)
	return {"ok": true, "duplicate": false, "wallet": wallet_result.state, "inventory": next_inventory}

func _failure(wallet: Dictionary, inventory: Dictionary) -> Dictionary:
	return {"ok": false, "duplicate": false, "wallet": wallet.duplicate(true), "inventory": inventory.duplicate(true)}
