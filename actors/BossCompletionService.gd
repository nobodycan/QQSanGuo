extends Reference

func defeat(encounter: Dictionary, world: Dictionary, wallet: Dictionary, inventory: Dictionary, event_id: String, money_reward: int, drops: Array) -> Dictionary:
	if event_id.empty():
		return _failure(encounter, world, wallet, inventory)
	if str(encounter.get("status", "")) == "defeated" and typeof(encounter.get("events", null)) == TYPE_ARRAY and encounter.events.has(event_id):
		return {"ok": true, "duplicate": true, "encounter": encounter.duplicate(true), "world": world.duplicate(true), "wallet": wallet.duplicate(true), "inventory": inventory.duplicate(true)}
	if str(encounter.get("status", "")) != "active":
		return _failure(encounter, world, wallet, inventory)
	var boss_id = str(encounter.get("boss_id", ""))
	var reward = load("res://actors/RewardService.gd").new().grant_many(wallet, inventory, "boss." + boss_id + "." + event_id, money_reward, 0, drops)
	if not reward.ok:
		return _failure(encounter, world, wallet, inventory)
	var defeated = load("res://actors/BossEncounterState.gd").new().apply(encounter, event_id, "defeat")
	if not defeated.ok:
		return _failure(encounter, world, wallet, inventory)
	var next_world = load("res://actors/WorldState.gd").new().apply(world, "boss.world." + boss_id + "." + event_id, "defeat_boss", boss_id)
	if not next_world.ok:
		return _failure(encounter, world, wallet, inventory)
	return {"ok": true, "duplicate": false, "encounter": defeated.state, "world": next_world.state, "wallet": reward.wallet, "inventory": reward.inventory}

func _failure(encounter: Dictionary, world: Dictionary, wallet: Dictionary, inventory: Dictionary) -> Dictionary:
	return {"ok": false, "duplicate": false, "encounter": encounter.duplicate(true), "world": world.duplicate(true), "wallet": wallet.duplicate(true), "inventory": inventory.duplicate(true)}
