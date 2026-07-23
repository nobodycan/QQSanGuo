extends Reference

const VERSION = 1

func new_state() -> Dictionary:
	return {"version": VERSION, "known": [], "equipped": [], "cooldowns": {}}

func normalize(raw) -> Dictionary:
	if typeof(raw) != TYPE_DICTIONARY or int(raw.get("version", -1)) != VERSION:
		return {}
	if not _has_only_valid_skill_ids(raw.get("known", null)) or not _has_only_valid_skill_ids(raw.get("equipped", null)):
		return {}
	var known = _normalize_skill_ids(raw.get("known", null))
	var equipped = _normalize_skill_ids(raw.get("equipped", null))
	for skill_id in equipped:
		if not known.has(skill_id):
			return {}
	if typeof(raw.get("cooldowns", null)) != TYPE_DICTIONARY:
		return {}
	var cooldowns = {}
	for skill_id in raw.cooldowns:
		if not known.has(skill_id) or not _is_integer(raw.cooldowns[skill_id]) or int(raw.cooldowns[skill_id]) < 0:
			return {}
		cooldowns[skill_id] = int(raw.cooldowns[skill_id])
	return {"version": VERSION, "known": known, "equipped": equipped, "cooldowns": cooldowns}

func migrate_v0(raw) -> Dictionary:
	if typeof(raw) != TYPE_DICTIONARY or not raw.empty():
		return {}
	return new_state()

func migrate_legacy_registered(raw, registry: Node) -> Dictionary:
	if typeof(raw) != TYPE_DICTIONARY or registry == null or not registry.has_method("resolve_legacy"):
		return {}
	var result = new_state()
	for field in ["known", "equipped"]:
		if typeof(raw.get(field, null)) != TYPE_ARRAY:
			return {}
		for legacy_name in raw[field]:
			if typeof(legacy_name) != TYPE_STRING or legacy_name.empty():
				return {}
			var resolved = registry.resolve_legacy("skills", legacy_name)
			if not resolved.get("ok", false) or typeof(resolved.get("data", null)) != TYPE_STRING:
				return {}
			if not result[field].has(resolved.data):
				result[field].append(resolved.data)
	for skill_id in result.equipped:
		if not result.known.has(skill_id):
			return {}
	result.known.sort()
	result.equipped.sort()
	return result

func _normalize_skill_ids(raw) -> Array:
	if typeof(raw) != TYPE_ARRAY:
		return []
	var result = []
	for skill_id in raw:
		if typeof(skill_id) != TYPE_STRING or not _is_stable_skill_id(skill_id):
			return []
		if not result.has(skill_id):
			result.append(skill_id)
	result.sort()
	return result

func _has_only_valid_skill_ids(raw) -> bool:
	if typeof(raw) != TYPE_ARRAY:
		return false
	for skill_id in raw:
		if typeof(skill_id) != TYPE_STRING or not _is_stable_skill_id(skill_id):
			return false
	return true

func _is_stable_skill_id(skill_id: String) -> bool:
	if not skill_id.begins_with("skill.") or skill_id.length() <= 6:
		return false
	for index in range(skill_id.length()):
		var code = skill_id.ord_at(index)
		if not (code >= 97 and code <= 122) and not (code >= 48 and code <= 57) and code != 46 and code != 95:
			return false
	return true

func _is_integer(value) -> bool:
	return (typeof(value) == TYPE_INT or typeof(value) == TYPE_REAL) and int(value) == value
