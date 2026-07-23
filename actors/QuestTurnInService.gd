extends Reference

func turn_in(quest: Dictionary, wallet: Dictionary, inventory: Dictionary, event_id: String, money_reward: int, juntuan_reward: int, drops: Array) -> Dictionary:
	if event_id.empty():
		return _failure(quest, wallet, inventory)
	if str(quest.get("status", "")) == "completed" and typeof(quest.get("events", null)) == TYPE_ARRAY and quest.events.has(event_id):
		return {"ok": true, "duplicate": true, "quest": quest.duplicate(true), "wallet": wallet.duplicate(true), "inventory": inventory.duplicate(true)}
	if str(quest.get("status", "")) != "ready_to_turn_in":
		return _failure(quest, wallet, inventory)
	var reward_service = load("res://actors/RewardService.gd").new()
	var operation_id = "quest." + str(quest.get("quest_id", "")) + "." + event_id
	var reward = reward_service.grant_many(wallet, inventory, operation_id, money_reward, juntuan_reward, drops)
	if not reward.ok:
		return _failure(quest, reward.wallet, reward.inventory)
	var quest_state = load("res://actors/QuestState.gd").new()
	var transition = quest_state.apply(quest, event_id, "turn_in")
	if not transition.ok:
		return _failure(quest, reward.wallet, reward.inventory)
	return {"ok": true, "duplicate": reward.duplicate or transition.duplicate, "quest": transition.state, "wallet": reward.wallet, "inventory": reward.inventory}

func _failure(quest: Dictionary, wallet: Dictionary, inventory: Dictionary) -> Dictionary:
	return {"ok": false, "duplicate": false, "quest": quest.duplicate(true), "wallet": wallet.duplicate(true), "inventory": inventory.duplicate(true)}
