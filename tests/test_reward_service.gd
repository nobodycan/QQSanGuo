extends SceneTree

const RewardService = preload("res://actors/RewardService.gd")
const WalletState = preload("res://actors/WalletState.gd")
const InventoryState = preload("res://actors/InventoryState.gd")
const ItemTemplate = preload("res://actors/ItemTemplate.gd")
const ItemInstance = preload("res://actors/ItemInstance.gd")
const TestProtocol = preload("res://tests/TestProtocol.gd")

func _init():
	var test = TestProtocol.new()
	var rewards = RewardService.new()
	var wallet = WalletState.new().new_state()
	var inventory = InventoryState.new().normalize(InventoryState.new().new_state())
	var herb = ItemTemplate.new().normalize({"id": "item.herb", "stack_limit": 10})
	var granted = rewards.grant(wallet, inventory, "snake.1", 100, 10, herb, 2)
	test.expect(granted.ok and granted.wallet.money == 100 and granted.wallet.juntuan == 10 and granted.inventory.slots[0].quantity == 2, "grants wallet and inventory rewards atomically")
	var duplicate = rewards.grant(granted.wallet, granted.inventory, "snake.1", 100, 10, herb, 2)
	test.expect(duplicate.ok and duplicate.duplicate and duplicate.wallet.money == 100 and duplicate.inventory.slots[0].quantity == 2, "duplicate reward ID grants exactly once")
	var full = InventoryState.new().new_state()
	for index in range(InventoryState.SLOT_COUNT):
		full.slots.append(ItemInstance.new().new_stack(herb, 10))
	full = InventoryState.new().normalize(full)
	var full_reward = rewards.grant(wallet, full, "snake.2", 100, 10, herb, 1)
	test.expect(not full_reward.ok and full_reward.wallet.money == 0 and full_reward.inventory.slots[0].quantity == 10, "full inventory prevents every reward component from committing")
	var currency_only = rewards.grant(wallet, inventory, "boss.1", 1000, 100)
	test.expect(currency_only.ok and currency_only.wallet.money == 1000 and currency_only.inventory.slots[0].empty(), "supports atomic currency-only rewards")
	test.finish(self, "reward_service")
