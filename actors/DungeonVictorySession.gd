extends Reference

func victory(dungeon: Dictionary, run: Dictionary, world: Dictionary, wallet: Dictionary, inventory: Dictionary, event_id: String, money_reward: int, drops: Array) -> Dictionary:
	if event_id.empty() or str(run.get("kind", "")) != "dungeon" or str(run.get("encounter_id", "")) != str(dungeon.get("dungeon_id", "")):
		return _failure(dungeon, run, world, wallet, inventory)
	var completion = load("res://actors/DungeonCompletionService.gd").new().complete(dungeon, world, wallet, inventory, event_id, money_reward, drops)
	if completion.get("ok", false) and completion.get("duplicate", false):
		return {"ok": true, "duplicate": true, "dungeon": completion.dungeon, "run": run.duplicate(true), "world": completion.world, "wallet": completion.wallet, "inventory": completion.inventory}
	if not completion.get("ok", false):
		return _failure(dungeon, run, world, wallet, inventory)
	var won_run = load("res://actors/EncounterDirector.gd").new().apply(run, event_id, "victory")
	if not won_run.get("ok", false):
		return _failure(dungeon, run, world, wallet, inventory)
	return {"ok": true, "duplicate": false, "dungeon": completion.dungeon, "run": won_run.state, "world": completion.world, "wallet": completion.wallet, "inventory": completion.inventory}

func _failure(dungeon: Dictionary, run: Dictionary, world: Dictionary, wallet: Dictionary, inventory: Dictionary) -> Dictionary:
	return {"ok": false, "duplicate": false, "dungeon": dungeon.duplicate(true), "run": run.duplicate(true), "world": world.duplicate(true), "wallet": wallet.duplicate(true), "inventory": inventory.duplicate(true)}
