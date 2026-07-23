extends SceneTree

const InventoryState = preload("res://actors/InventoryState.gd")
const ItemTemplate = preload("res://actors/ItemTemplate.gd")
const ShopService = preload("res://actors/ShopService.gd")
const TestProtocol = preload("res://tests/TestProtocol.gd")
const WalletState = preload("res://actors/WalletState.gd")

func _init():
	var test = TestProtocol.new()
	var wallet = WalletState.new().apply(WalletState.new().new_state(), "seed", 100, 0).state
	var inventory = InventoryState.new().normalize(InventoryState.new().new_state())
	var herb = ItemTemplate.new().normalize({"id":"item.herb","stack_limit":10})
	var service = ShopService.new()
	var product = {"item_id":"item.herb","buy_price":12}
	var bought = service.buy(wallet, inventory, "shop.herb.1", product, {"item.herb":herb}, 3)
	test.expect(bought.ok and bought.wallet.money == 64 and bought.inventory.slots[0].quantity == 3, "purchases at the catalog quote atomically")
	var duplicate = service.buy(bought.wallet, bought.inventory, "shop.herb.1", product, {"item.herb":herb}, 3)
	test.expect(duplicate.ok and duplicate.duplicate and duplicate.wallet.money == 64, "deduplicates repeat purchase IDs")
	test.expect(not service.buy(wallet, inventory, "shop.missing", {"item_id":"item.none","buy_price":1}, {"item.herb":herb}, 1).ok, "rejects products missing a template")
	var sold = service.sell(bought.wallet, bought.inventory, "shop.herb.sell.1", 0, {"id":"item.herb","buy_price":12}, 2)
	test.expect(sold.ok and sold.wallet.money == 70 and sold.inventory.slots[0].quantity == 1, "sells inventory atomically at the resale quote")
	var sell_duplicate = service.sell(sold.wallet, sold.inventory, "shop.herb.sell.1", 0, {"id":"item.herb","buy_price":12}, 2)
	test.expect(sell_duplicate.ok and sell_duplicate.duplicate and sell_duplicate.wallet.money == 70, "deduplicates repeat sale IDs")
	test.finish(self, "shop_service")
