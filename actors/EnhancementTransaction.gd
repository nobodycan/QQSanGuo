extends Reference

const WalletState = preload("res://actors/WalletState.gd")
const InventoryState = preload("res://actors/InventoryState.gd")
const EquipmentState = preload("res://actors/EquipmentState.gd")
const EnhancementState = preload("res://actors/EnhancementState.gd")

func apply(wallet: Dictionary, inventory: Dictionary, equipment: Dictionary, operation_id: String, slot_name: String, cost: Dictionary) -> Dictionary:
	var current_wallet = WalletState.new().normalize(wallet)
	var current_inventory = InventoryState.new().export_state(inventory)
	var current_equipment = EquipmentState.new().normalize(equipment)
	if current_wallet.empty() or current_inventory.empty() or current_equipment.empty() or operation_id.empty() or not current_equipment.slots.has(slot_name) or current_equipment.slots[slot_name].empty() or int(cost.get("money", -1)) < 0 or str(cost.get("material_id", "")).empty() or int(cost.get("material_quantity", 0)) < 1:
		return _failure(wallet, inventory, equipment)
	if current_wallet.ledger.has(operation_id):
		return {"ok": true, "duplicate": true, "wallet": current_wallet, "inventory": current_inventory, "equipment": current_equipment}
	var next_inventory = InventoryState.new().consume_template(current_inventory, str(cost.material_id), int(cost.material_quantity))
	var next_item = EnhancementState.new().upgrade(current_equipment.slots[slot_name])
	if next_inventory.empty() or next_item.empty():
		return _failure(current_wallet, current_inventory, current_equipment)
	var wallet_result = WalletState.new().apply(current_wallet, operation_id, -int(cost.money), 0)
	if not wallet_result.ok:
		return _failure(current_wallet, current_inventory, current_equipment)
	current_equipment.slots[slot_name] = next_item
	return {"ok": true, "duplicate": false, "wallet": wallet_result.state, "inventory": next_inventory, "equipment": current_equipment}

func _failure(wallet: Dictionary, inventory: Dictionary, equipment: Dictionary) -> Dictionary:
	return {"ok": false, "duplicate": false, "wallet": wallet.duplicate(true), "inventory": inventory.duplicate(true), "equipment": equipment.duplicate(true)}
