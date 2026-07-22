extends Reference

func normalize(raw) -> Dictionary:
	if typeof(raw) != TYPE_DICTIONARY:
		return {}
	var item_id = str(raw.get("id", ""))
	if item_id.empty() or not _valid_id(item_id):
		return {}
	var stack_limit = int(raw.get("stack_limit", 1))
	if stack_limit < 1:
		return {}
	return {"id": item_id, "stack_limit": stack_limit, "stackable": stack_limit > 1, "kind": str(raw.get("kind", "material")), "quest": bool(raw.get("quest", false))}

func _valid_id(item_id: String) -> bool:
	for index in range(item_id.length()):
		if "abcdefghijklmnopqrstuvwxyz0123456789._".find(item_id.substr(index, 1)) < 0:
			return false
	return true
