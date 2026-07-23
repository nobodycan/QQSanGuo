extends Reference

func normalize(raw: Dictionary) -> Dictionary:
	var shop_id = str(raw.get("id", ""))
	var products = raw.get("products", null)
	if shop_id.empty() or typeof(products) != TYPE_ARRAY:
		return {}
	var normalized = []
	var seen = {}
	for product in products:
		if typeof(product) != TYPE_DICTIONARY:
			return {}
		var item_id = str(product.get("item_id", ""))
		var buy_price = int(product.get("buy_price", -1))
		var requires_flags = product.get("requires_flags", [])
		if item_id.empty() or buy_price < 0 or seen.has(item_id) or typeof(requires_flags) != TYPE_ARRAY:
			return {}
		seen[item_id] = true
		normalized.append({"item_id": item_id, "buy_price": buy_price, "requires_flags": requires_flags.duplicate()})
	return {"id": shop_id, "products": normalized}

func available(definition: Dictionary, flags: Array) -> Array:
	var normalized = normalize(definition)
	if normalized.empty():
		return []
	var result = []
	for product in normalized.products:
		var visible = true
		for required_flag in product.requires_flags:
			if typeof(required_flag) != TYPE_STRING or not flags.has(required_flag):
				visible = false
				break
		if visible:
			result.append(product.duplicate(true))
	return result
