extends Reference

const MATERIALS = ["material.enhance.low", "material.enhance.mid", "material.enhance.high"]
const BASE_MONEY = [10, 50, 250]

func quote(item_level: int, enhancement_level: int) -> Dictionary:
	if item_level < 1 or enhancement_level < 0 or enhancement_level >= 10:
		return {}
	var tier = 0 if item_level <= 20 else (1 if item_level <= 50 else 2)
	return {"money": BASE_MONEY[tier] * (enhancement_level + 1), "material_id": MATERIALS[tier], "material_quantity": 1, "tier": tier}
