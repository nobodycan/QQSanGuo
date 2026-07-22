extends Reference

const LootRewardService = preload("res://actors/LootRewardService.gd")

func collect(wallet: Dictionary, inventory: Dictionary, pickup_id: String, table: Dictionary, rng_seed: int, templates_by_id: Dictionary, flags: Dictionary = {}, money_reward: int = 0, juntuan_reward: int = 0) -> Dictionary:
	if pickup_id.empty():
		return {"ok": false, "remove_pickup": false, "wallet": wallet.duplicate(true), "inventory": inventory.duplicate(true)}
	var result = LootRewardService.new().grant(wallet, inventory, "pickup." + pickup_id, table, rng_seed, templates_by_id, flags, money_reward, juntuan_reward)
	result.remove_pickup = bool(result.ok)
	return result
