extends Reference

const SELL_BASIS_POINTS = 2500

func buy(template: Dictionary, quantity: int) -> Dictionary:
	return _quote(template, quantity, int(template.get("buy_price", -1)))

func sell(template: Dictionary, quantity: int) -> Dictionary:
	var buy_price = int(template.get("buy_price", -1))
	if buy_price < 0:
		return {}
	return _quote(template, quantity, int(buy_price * SELL_BASIS_POINTS / 10000))

func _quote(template: Dictionary, quantity: int, unit_price: int) -> Dictionary:
	if str(template.get("id", "")).empty() or quantity < 1 or unit_price < 0:
		return {}
	return {"item_id": str(template.id), "quantity": quantity, "unit_price": unit_price, "total_price": unit_price * quantity}
