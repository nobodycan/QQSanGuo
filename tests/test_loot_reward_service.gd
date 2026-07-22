extends SceneTree

const LootRewardService = preload("res://actors/LootRewardService.gd")
const WalletState = preload("res://actors/WalletState.gd")
const InventoryState = preload("res://actors/InventoryState.gd")
const ItemTemplate = preload("res://actors/ItemTemplate.gd")
const TestProtocol = preload("res://tests/TestProtocol.gd")

func _init():
	var test = TestProtocol.new()
	var herb = ItemTemplate.new().normalize({"id": "item.herb", "stack_limit": 10})
	var table = {"entries": [{"item_id": "item.herb", "min_quantity": 2, "max_quantity": 2, "chance_bps": 0, "guaranteed": true}]}
	var wallet = WalletState.new().new_state()
	var inventory = InventoryState.new().normalize(InventoryState.new().new_state())
	var rewards = LootRewardService.new()
	var result = rewards.grant(wallet, inventory, "enemy.1", table, 7, {"item.herb": herb}, {}, 25)
	test.expect(result.ok and result.wallet.money == 25 and result.inventory.slots[0].quantity == 2, "resolves and commits loot through one reward operation")
	var duplicate = rewards.grant(result.wallet, result.inventory, "enemy.1", table, 7, {"item.herb": herb}, {}, 25)
	test.expect(duplicate.ok and duplicate.duplicate and duplicate.inventory.slots[0].quantity == 2, "duplicate defeat reward does not grant loot twice")
	test.expect(not rewards.grant(wallet, inventory, "enemy.2", table, 7, {}).ok, "rejects unresolved loot templates without partial rewards")
	test.finish(self, "loot_reward_service")
