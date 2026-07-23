extends Reference

var definitions = {}
var known = []
var equipped = []
var cooldowns = {}

func add_definition(definition: Dictionary) -> bool:
	var skill_id = str(definition.get("id", ""))
	if skill_id.empty() or definitions.has(skill_id) or int(definition.get("unlock_level", 0)) < 1:
		return false
	definitions[skill_id] = definition.duplicate(true)
	return true

func add_registered_definition(registry: Node, skill_id: String) -> bool:
	if registry == null or not registry.has_method("get_entry"):
		return false
	var entry = registry.get_entry(skill_id)
	if not entry.get("ok", false) or str(entry.data.get("kind", "")) != "skill":
		return false
	return add_definition(entry.data)

func unlock(skill_id: String, level: int) -> bool:
	if not definitions.has(skill_id) or level < int(definitions[skill_id].unlock_level):
		return false
	if not known.has(skill_id):
		known.append(skill_id)
	return true

func cast(skill_id: String, magic: int) -> Dictionary:
	if not known.has(skill_id):
		return {"ok": false, "error": "locked", "magic": magic}
	if int(cooldowns.get(skill_id, 0)) > 0:
		return {"ok": false, "error": "cooldown", "magic": magic}
	var definition = definitions[skill_id]
	var cost = int(definition.get("magic_cost", 0))
	if magic < cost:
		return {"ok": false, "error": "insufficient_magic", "magic": magic}
	cooldowns[skill_id] = int(definition.get("cooldown_ticks", 0))
	return {"ok": true, "skill_id": skill_id, "magic": magic - cost, "damage": int(definition.get("damage", 0))}

func tick() -> void:
	for skill_id in cooldowns.keys():
		cooldowns[skill_id] = max(0, int(cooldowns[skill_id]) - 1)
