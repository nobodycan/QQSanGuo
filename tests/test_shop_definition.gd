extends SceneTree

const ShopDefinition = preload("res://actors/ShopDefinition.gd")
const TestProtocol = preload("res://tests/TestProtocol.gd")

func _init():
	var test = TestProtocol.new()
	var shops = ShopDefinition.new()
	var raw = {"id":"shop.pilot","products":[{"item_id":"item.herb","buy_price":12},{"item_id":"item.elixir","buy_price":99,"requires_flags":["world.elixir"]}]}
	var definition = shops.normalize(raw)
	test.expect(not definition.empty() and definition.products.size() == 2, "normalizes stable shop products")
	test.expect(shops.available(definition, []).size() == 1 and shops.available(definition, ["world.elixir"]).size() == 2, "filters products by world flags")
	test.expect(shops.normalize({"id":"shop.bad","products":[{"item_id":"item.herb","buy_price":1},{"item_id":"item.herb","buy_price":2}]}).empty(), "rejects duplicate product IDs")
	test.finish(self, "shop_definition")
