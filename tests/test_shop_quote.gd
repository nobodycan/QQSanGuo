extends SceneTree

const ShopQuote = preload("res://actors/ShopQuote.gd")
const TestProtocol = preload("res://tests/TestProtocol.gd")

func _init():
	var test = TestProtocol.new()
	var quote = ShopQuote.new()
	var potion = {"id":"item.potion","buy_price":99}
	var purchase = quote.buy(potion, 3)
	test.expect(purchase.unit_price == 99 and purchase.total_price == 297, "quotes deterministic purchase totals")
	var sale = quote.sell(potion, 3)
	test.expect(sale.unit_price == 24 and sale.total_price == 72, "uses floor-rounded 25 percent resale value")
	test.expect(quote.buy({}, 1).empty() and quote.sell(potion, 0).empty(), "rejects invalid templates and quantities")
	test.finish(self, "shop_quote")
