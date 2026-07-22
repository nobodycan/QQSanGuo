extends SceneTree

const EconomyTransaction = preload("res://actors/EconomyTransaction.gd")
const WalletState = preload("res://actors/WalletState.gd")
const InventoryState = preload("res://actors/InventoryState.gd")
const ItemTemplate = preload("res://actors/ItemTemplate.gd")
const ItemInstance = preload("res://actors/ItemInstance.gd")
const TestProtocol = preload("res://tests/TestProtocol.gd")

func _init():
	var test = TestProtocol.new()
	var transaction = EconomyTransaction.new()
	var wallet = WalletState.new().apply(WalletState.new().new_state(), "seed", 100, 0).state
	var inventory = InventoryState.new().normalize(InventoryState.new().new_state())
	var herb = ItemTemplate.new().normalize({"id": "item.herb", "stack_limit": 10})
	var bought = transaction.buy(wallet, inventory, "shop.herb.1", herb, 3, 25)
	test.expect(bought.ok and bought.wallet.money == 75 and bought.inventory.slots[0].quantity == 3, "commits wallet debit and inventory credit together")
	var duplicate = transaction.buy(bought.wallet, bought.inventory, "shop.herb.1", herb, 3, 25)
	test.expect(duplicate.ok and duplicate.duplicate and duplicate.wallet.money == 75 and duplicate.inventory.slots[0].quantity == 3, "duplicate transaction does not charge or grant twice")
	var insufficient = transaction.buy(wallet, inventory, "shop.herb.2", herb, 3, 101)
	test.expect(not insufficient.ok and insufficient.wallet.money == wallet.money and insufficient.inventory.slots[0].empty(), "insufficient balance leaves both states unchanged")
	var full = InventoryState.new().new_state()
	for index in range(InventoryState.SLOT_COUNT):
		full.slots.append(ItemInstance.new().new_stack(herb, 10))
	full = InventoryState.new().normalize(full)
	var full_result = transaction.buy(wallet, full, "shop.herb.3", herb, 1, 1)
	test.expect(not full_result.ok and full_result.wallet.money == wallet.money and full_result.inventory.slots[0].quantity == 10, "full inventory leaves both states unchanged")
	test.finish(self, "economy_transaction")
