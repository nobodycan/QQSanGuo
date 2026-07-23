extends SceneTree

const QuestTurnInService = preload("res://actors/QuestTurnInService.gd")
const TestProtocol = preload("res://tests/TestProtocol.gd")
const QuestState = preload("res://actors/QuestState.gd")
const WalletState = preload("res://actors/WalletState.gd")
const InventoryState = preload("res://actors/InventoryState.gd")
const ItemTemplate = preload("res://actors/ItemTemplate.gd")

func _init():
	var test = TestProtocol.new()
	var quests = QuestState.new()
	var quest = quests.new_state("quest.pilot")
	var wallet = WalletState.new().new_state()
	var inventory = InventoryState.new().normalize(InventoryState.new().new_state())
	var premature = QuestTurnInService.new().turn_in(quest, wallet, inventory, "turn.1", 0, 0, [])
	test.expect(premature.ok == false, "rejects a locked quest")
	quest = quests.apply(quest, "unlock", "unlock").state
	quest = quests.apply(quest, "accept", "accept").state
	quest = quests.apply(quest, "objectives", "objectives_complete").state
	var herb = ItemTemplate.new().normalize({"id":"item.herb","stack_limit":10})
	var completed = QuestTurnInService.new().turn_in(quest, wallet, inventory, "turn.1", 50, 0, [{"template":herb,"quantity":1}])
	test.expect(completed.ok and completed.quest.status == QuestState.COMPLETED and completed.wallet.money == 50 and completed.inventory.slots[0].quantity == 1, "atomically grants and completes")
	var duplicate = QuestTurnInService.new().turn_in(completed.quest, completed.wallet, completed.inventory, "turn.1", 50, 0, [{"template":herb,"quantity":1}])
	test.expect(duplicate.ok and duplicate.duplicate and duplicate.wallet.money == 50, "deduplicates repeated turn-ins")
	test.finish(self, "quest_turn_in_service")
