extends SceneTree

const InventoryState = preload("res://actors/InventoryState.gd")
const ItemTemplate = preload("res://actors/ItemTemplate.gd")
const ShopSession = preload("res://actors/ShopSession.gd")
const TestProtocol = preload("res://tests/TestProtocol.gd")
const WalletState = preload("res://actors/WalletState.gd")

func _init():
	var test = TestProtocol.new()
	var wallet = WalletState.new().apply(WalletState.new().new_state(), "seed", 100, 0).state
	var inventory = InventoryState.new().normalize(InventoryState.new().new_state())
	var herb = ItemTemplate.new().normalize({"id":"item.herb","stack_limit":10})
	var shop = {"id":"shop.pilot","products":[{"item_id":"item.herb","buy_price":12},{"item_id":"item.elixir","buy_price":50,"requires_flags":["world.elixir"]}]}
	var session = ShopSession.new()
	var bought = session.purchase(wallet, inventory, "shop.herb.1", shop, [], {"item.herb":herb}, "item.herb", 2)
	test.expect(bought.ok and bought.wallet.money == 76 and bought.inventory.slots[0].quantity == 2, "purchases visible catalog products")
	test.expect(not session.purchase(wallet, inventory, "shop.elixir.1", shop, [], {"item.herb":herb}, "item.elixir", 1).ok, "rejects flag-gated products")
	test.finish(self, "shop_session")
