extends Reference

func victory(encounter: Dictionary, run: Dictionary, world: Dictionary, wallet: Dictionary, inventory: Dictionary, event_id: String, money_reward: int, drops: Array) -> Dictionary:
	if event_id.empty() or str(run.get("kind", "")) != "boss" or str(run.get("encounter_id", "")) != str(encounter.get("boss_id", "")):
		return _failure(encounter, run, world, wallet, inventory)
	var completion = load("res://actors/BossCompletionService.gd").new().defeat(encounter, world, wallet, inventory, event_id, money_reward, drops)
	if completion.get("ok", false) and completion.get("duplicate", false):
		return {"ok": true, "duplicate": true, "encounter": completion.encounter, "run": run.duplicate(true), "world": completion.world, "wallet": completion.wallet, "inventory": completion.inventory}
	if not completion.get("ok", false):
		return _failure(encounter, run, world, wallet, inventory)
	var won_run = load("res://actors/EncounterDirector.gd").new().apply(run, event_id, "victory")
	if not won_run.get("ok", false):
		return _failure(encounter, run, world, wallet, inventory)
	return {"ok": true, "duplicate": false, "encounter": completion.encounter, "run": won_run.state, "world": completion.world, "wallet": completion.wallet, "inventory": completion.inventory}

func _failure(encounter: Dictionary, run: Dictionary, world: Dictionary, wallet: Dictionary, inventory: Dictionary) -> Dictionary:
	return {"ok": false, "duplicate": false, "encounter": encounter.duplicate(true), "run": run.duplicate(true), "world": world.duplicate(true), "wallet": wallet.duplicate(true), "inventory": inventory.duplicate(true)}
