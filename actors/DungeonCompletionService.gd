extends Reference

func complete(dungeon: Dictionary, world: Dictionary, wallet: Dictionary, inventory: Dictionary, event_id: String, money_reward: int, drops: Array) -> Dictionary:
	if event_id.empty():
		return _failure(dungeon, world, wallet, inventory)
	if str(dungeon.get("status", "")) == "completed" and typeof(dungeon.get("events", null)) == TYPE_ARRAY and dungeon.events.has(event_id):
		return {"ok": true, "duplicate": true, "dungeon": dungeon.duplicate(true), "world": world.duplicate(true), "wallet": wallet.duplicate(true), "inventory": inventory.duplicate(true)}
	if str(dungeon.get("status", "")) != "active":
		return _failure(dungeon, world, wallet, inventory)
	var dungeon_id = str(dungeon.get("dungeon_id", ""))
	var reward = load("res://actors/RewardService.gd").new().grant_many(wallet, inventory, "dungeon." + dungeon_id + "." + event_id, money_reward, 0, drops)
	if not reward.ok:
		return _failure(dungeon, world, wallet, inventory)
	var completed = load("res://actors/DungeonState.gd").new().apply(dungeon, event_id, "complete")
	if not completed.ok:
		return _failure(dungeon, world, wallet, inventory)
	var next_world = load("res://actors/WorldState.gd").new().apply(world, "dungeon.world." + dungeon_id + "." + event_id, "flag", "dungeon.completed." + dungeon_id)
	if not next_world.ok:
		return _failure(dungeon, world, wallet, inventory)
	return {"ok": true, "duplicate": false, "dungeon": completed.state, "world": next_world.state, "wallet": reward.wallet, "inventory": reward.inventory}

func _failure(dungeon: Dictionary, world: Dictionary, wallet: Dictionary, inventory: Dictionary) -> Dictionary:
	return {"ok": false, "duplicate": false, "dungeon": dungeon.duplicate(true), "world": world.duplicate(true), "wallet": wallet.duplicate(true), "inventory": inventory.duplicate(true)}
