extends Reference

var claimed_ids = {}

func claim(defeat_id: String) -> bool:
	if defeat_id.empty() or claimed_ids.has(defeat_id):
		return false
	claimed_ids[defeat_id] = true
	return true

func release(defeat_id: String) -> bool:
	if not claimed_ids.has(defeat_id):
		return false
	claimed_ids.erase(defeat_id)
	return true
