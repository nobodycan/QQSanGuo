extends Reference

const LootTable = preload("res://actors/LootTable.gd")
const RewardService = preload("res://actors/RewardService.gd")

func grant(wallet: Dictionary, inventory: Dictionary, operation_id: String, table: Dictionary, rng_seed: int, templates_by_id: Dictionary, flags: Dictionary = {}, money_reward: int = 0, juntuan_reward: int = 0) -> Dictionary:
	var resolved = LootTable.new().resolve(table, rng_seed, flags)
	if typeof(table) != TYPE_DICTIONARY or not table.has("entries") or money_reward < 0 or juntuan_reward < 0:
		return _failure(wallet, inventory)
	var drops = []
	for entry in resolved:
		var template = templates_by_id.get(str(entry.item_id), {})
		if typeof(template) != TYPE_DICTIONARY or template.empty():
			return _failure(wallet, inventory)
		drops.append({"template": template, "quantity": int(entry.quantity)})
	return RewardService.new().grant_many(wallet, inventory, operation_id, money_reward, juntuan_reward, drops)

func _failure(wallet: Dictionary, inventory: Dictionary) -> Dictionary:
	return {"ok": false, "duplicate": false, "wallet": wallet.duplicate(true), "inventory": inventory.duplicate(true)}
