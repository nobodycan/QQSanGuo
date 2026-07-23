extends Reference

const SkillState = preload("res://actors/SkillState.gd")

var state = SkillState.new().new_state()

func import_legacy(known: Array, equipped: Array, registry: Node) -> bool:
	var migrated = SkillState.new().migrate_legacy_registered({"known": known, "equipped": equipped}, registry)
	if migrated.empty():
		return false
	state = migrated
	return true

func apply_canonical(raw: Dictionary, registry: Node) -> bool:
	var validated = SkillState.new().validate_registered(raw, registry)
	if not validated.ok:
		return false
	state = validated.state
	return true

func export_canonical() -> Dictionary:
	return state.duplicate(true)

func project_legacy(registry: Node) -> Dictionary:
	if registry == null or not registry.has_method("get_entry"):
		return {}
	var result = {"known": [], "equipped": []}
	for field in ["known", "equipped"]:
		for skill_id in state[field]:
			var entry = registry.get_entry(skill_id)
			if not entry.get("ok", false) or str(entry.data.get("kind", "")) != "skill":
				return {}
			var legacy_name = str(entry.data.get("legacy_name", ""))
			if legacy_name.empty():
				return {}
			result[field].append(legacy_name)
	return result
