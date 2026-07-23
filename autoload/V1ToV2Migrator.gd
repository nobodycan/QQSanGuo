extends Reference

const GameState = preload("res://autoload/GameState.gd")
const GameStateV2 = preload("res://autoload/GameStateV2.gd")
const InventoryState = preload("res://actors/InventoryState.gd")
const EquipmentState = preload("res://actors/EquipmentState.gd")

func migrate_location(map_path: String, aliases: Dictionary) -> Dictionary:
	if not aliases.has("maps") or not aliases.maps.has(map_path):
		return {"ok": false, "error": "unresolved_map", "value": map_path}
	return {"ok": true, "location": aliases.maps[map_path]}

func migrate_name(name: String, category: String, aliases: Dictionary) -> Dictionary:
	if not aliases.has(category) or not aliases[category].has(name):
		return {"ok": false, "error": "unresolved_" + category, "value": name}
	return {"ok": true, "id": aliases[category][name]}

func migrate_location_registered(map_path: String, registry: Node) -> Dictionary:
	var resolved = _resolve_registry(registry, "maps", map_path)
	if not resolved.ok or typeof(resolved.data) != TYPE_DICTIONARY:
		return {"ok": false, "error": "unresolved_map", "value": map_path}
	return {"ok": true, "location": resolved.data}

func migrate_name_registered(name: String, category: String, registry: Node) -> Dictionary:
	var resolved = _resolve_registry(registry, category, name)
	if not resolved.ok or typeof(resolved.data) != TYPE_STRING:
		return {"ok": false, "error": "unresolved_" + category, "value": name}
	return {"ok": true, "id": resolved.data}

func migrate_skills_registered(raw: Dictionary, registry: Node) -> Dictionary:
	var skill_state = load("res://actors/SkillState.gd").new()
	var migrated = skill_state.migrate_legacy_registered(raw, registry)
	if migrated.empty():
		return {"ok": false, "error": "unresolved_skills", "state": {}}
	return {"ok": true, "error": "", "state": migrated}

func migrate_snapshot_registered(raw: Dictionary, registry: Node) -> Dictionary:
	var legacy_state = GameState.new()
	var legacy = legacy_state.normalize(raw)
	legacy_state.free()
	if legacy == null or registry == null or not registry.has_method("content_revision"):
		return _snapshot_failure("invalid_legacy_snapshot")
	var location = migrate_location_registered(str(legacy.map_path), registry)
	var inventory = _migrate_inventory(legacy.inventory, registry)
	var equipment = _migrate_equipment(legacy.equipment, registry)
	var skills = migrate_skills_registered(legacy.skills, registry)
	if not location.ok:
		return _snapshot_failure(str(location.error))
	if inventory.empty():
		return _snapshot_failure("unresolved_inventory")
	if equipment.empty():
		return _snapshot_failure("unresolved_equipment")
	if not skills.ok:
		return _snapshot_failure(str(skills.error))
	var envelope = GameStateV2.new().new_envelope()
	envelope.metadata.content_revision = str(registry.content_revision())
	envelope.location = location.location.duplicate(true)
	envelope.player = _migrate_player(legacy.player)
	envelope.wallet = {"version": 1, "money": int(legacy.player.money), "juntuan": int(legacy.player.juntuan), "ledger": []}
	envelope.inventory = inventory
	envelope.equipment = equipment
	envelope.skills = skills.state
	# Fields without a V2 runtime owner remain recoverable during staged adoption.
	envelope.legacy = {"v1_snapshot": legacy.duplicate(true)}
	var normalized = GameStateV2.new().normalize(envelope)
	if normalized == null:
		return _snapshot_failure("invalid_v2_snapshot")
	return {"ok": true, "error": "", "state": normalized}

func _migrate_player(player: Dictionary) -> Dictionary:
	var raw = {"level": int(player.level), "experience": int(player.experience)}
	for key in player.attributes:
		raw[key] = int(player.attributes[key])
	return load("res://actors/PlayerStats.gd").new().migrate_v0(raw)

func _migrate_inventory(legacy_inventory: Dictionary, registry: Node) -> Dictionary:
	var aliases = {}
	for slot_index in legacy_inventory:
		var stack = legacy_inventory[slot_index]
		if typeof(stack) != TYPE_ARRAY or stack.size() != 2:
			return {}
		var resolved = migrate_name_registered(str(stack[0]), "items", registry)
		if not resolved.ok:
			return {}
		var entry = registry.get_entry(resolved.id)
		if not entry.ok or int(stack[1]) < 1 or int(stack[1]) > int(entry.data.get("stack_limit", 0)):
			return {}
		aliases[str(stack[0])] = resolved.id
	return InventoryState.new().migrate_v0(legacy_inventory, aliases)

func _migrate_equipment(legacy_equipment: Dictionary, registry: Node) -> Dictionary:
	var result = EquipmentState.new().new_state()
	for slot_name in EquipmentState.SLOTS:
		var legacy_name = str(legacy_equipment.get(slot_name, ""))
		if legacy_name.empty():
			continue
		var resolved = migrate_name_registered(legacy_name, "items", registry)
		if not resolved.ok:
			return {}
		var entry = registry.get_entry(resolved.id)
		if not entry.ok or str(entry.data.get("kind", "")) != "equipment":
			return {}
		var modifiers = _integer_modifiers(entry.data.get("modifiers", {}))
		if modifiers.empty() and not entry.data.get("modifiers", {}).empty():
			return {}
		var item = {"instance_id": "legacy." + (slot_name + "." + legacy_name).md5_text(), "slot": slot_name, "job": str(entry.data.get("job", "")), "level": int(entry.data.get("level", 1)), "modifiers": modifiers, "enhancement_level": 0}
		var equipped = EquipmentState.new().equip(result, item, str(item.job), int(item.level))
		if equipped.empty():
			return {}
		result = equipped
	return EquipmentState.new().normalize(result)

func _snapshot_failure(error_code: String) -> Dictionary:
	return {"ok": false, "error": error_code, "state": null}

func _integer_modifiers(raw) -> Dictionary:
	if typeof(raw) != TYPE_DICTIONARY:
		return {}
	var result = {}
	for key in raw:
		if typeof(key) != TYPE_STRING or (typeof(raw[key]) != TYPE_INT and typeof(raw[key]) != TYPE_REAL) or int(raw[key]) != raw[key]:
			return {}
		result[key] = int(raw[key])
	return result

func _resolve_registry(registry: Node, category: String, value: String) -> Dictionary:
	if registry == null or not registry.has_method("resolve_legacy"):
		return {"ok": false}
	return registry.resolve_legacy(category, value)
