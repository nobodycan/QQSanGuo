extends Reference

const SCHEMA_VERSION = 2
const InventoryState = preload("res://actors/InventoryState.gd")
const EquipmentState = preload("res://actors/EquipmentState.gd")
const WalletState = preload("res://actors/WalletState.gd")
const WorldState = preload("res://actors/WorldState.gd")
const SkillState = preload("res://actors/SkillState.gd")

func new_envelope() -> Dictionary:
	return {
		"schema_version": SCHEMA_VERSION,
		"section_versions": {"metadata": 1, "location": 1, "player": 1, "wallet": WalletState.VERSION, "inventory": InventoryState.VERSION, "equipment": EquipmentState.VERSION, "skills": SkillState.VERSION, "quests": 0, "world": WorldState.VERSION, "legacy": 0},
		"metadata": {"content_revision": "v1-pilot-phase76"},
		"location": {"map_id": "", "spawn_id": ""},
		"player": preload("res://actors/PlayerStats.gd").new().new_state(), "wallet": WalletState.new().new_state(), "inventory": InventoryState.new().new_state(), "equipment": EquipmentState.new().new_state(), "skills": SkillState.new().new_state(), "quests": {}, "world": WorldState.new().new_state(), "legacy": {}
	}

func normalize(raw):
	if typeof(raw) != TYPE_DICTIONARY or int(raw.get("schema_version", -1)) != SCHEMA_VERSION:
		return null
	if typeof(raw.get("section_versions", null)) != TYPE_DICTIONARY or typeof(raw.get("location", null)) != TYPE_DICTIONARY:
		return null
	if typeof(raw.location.get("map_id", null)) != TYPE_STRING or typeof(raw.location.get("spawn_id", null)) != TYPE_STRING:
		return null
	var result = new_envelope()
	for key in result:
		if raw.has(key): result[key] = raw[key]
	var player_stats = preload("res://actors/PlayerStats.gd").new()
	result.player = player_stats.migrate_v0(result.player)
	result.section_versions.player = player_stats.SECTION_VERSION
	var wallet_version = int(raw.section_versions.get("wallet", 0))
	if wallet_version > WalletState.VERSION:
		return null
	var wallet_state = WalletState.new()
	if wallet_version == 0:
		if raw.has("wallet") and (typeof(result.wallet) != TYPE_DICTIONARY or not result.wallet.empty()):
			return null
		result.wallet = wallet_state.new_state()
	else:
		result.wallet = wallet_state.normalize(result.wallet)
		if result.wallet.empty():
			return null
	result.section_versions.wallet = WalletState.VERSION
	var inventory_version = int(raw.section_versions.get("inventory", -1))
	if inventory_version > InventoryState.VERSION:
		return null
	var inventory_state = InventoryState.new()
	if inventory_version == 0:
		if typeof(result.inventory) != TYPE_DICTIONARY or not result.inventory.empty():
			return null
		result.inventory = inventory_state.normalize(inventory_state.new_state())
	else:
		result.inventory = inventory_state.normalize(result.inventory)
		if result.inventory.empty():
			return null
	result.section_versions.inventory = InventoryState.VERSION
	var equipment_version = int(raw.section_versions.get("equipment", -1))
	if equipment_version > EquipmentState.VERSION:
		return null
	var equipment_state = EquipmentState.new()
	if equipment_version == 0:
		if typeof(result.equipment) != TYPE_DICTIONARY or not result.equipment.empty():
			return null
		result.equipment = equipment_state.new_state()
	elif equipment_version == 1:
		result.equipment = equipment_state.migrate_v1(result.equipment)
	else:
		result.equipment = equipment_state.normalize(result.equipment)
		if result.equipment.empty():
			return null
	result.section_versions.equipment = EquipmentState.VERSION
	var skills_version = int(raw.section_versions.get("skills", 0))
	if skills_version > SkillState.VERSION:
		return null
	var skill_state = SkillState.new()
	if skills_version == 0:
		result.skills = skill_state.migrate_v0(result.skills)
	else:
		result.skills = skill_state.normalize(result.skills)
	if result.skills.empty():
		return null
	result.section_versions.skills = SkillState.VERSION
	var world_version = int(raw.section_versions.get("world", 0))
	if world_version > WorldState.VERSION: return null
	var world_state = WorldState.new()
	if world_version == 0:
		result.world = world_state.migrate_v0(result.world)
	else:
		result.world = world_state.normalize(result.world)
	if result.world.empty(): return null
	result.section_versions.world = WorldState.VERSION
	return result

func validate_content_compatibility(raw: Dictionary, loaded_revision: String, registry: Node = null) -> Dictionary:
	if loaded_revision.empty():
		return {"ok": false, "reason": "invalid_loaded_revision", "state": null}
	var normalized = normalize(raw)
	if normalized == null or typeof(normalized.get("metadata", null)) != TYPE_DICTIONARY or typeof(normalized.metadata.get("content_revision", null)) != TYPE_STRING:
		return {"ok": false, "reason": "invalid_save", "state": null}
	if normalized.metadata.content_revision != loaded_revision:
		return {"ok": false, "reason": "content_revision_mismatch", "state": null}
	if registry != null:
		var skills = SkillState.new().validate_registered(normalized.skills, registry)
		if not skills.ok:
			return {"ok": false, "reason": skills.error, "state": null}
		normalized.skills = skills.state
	return {"ok": true, "reason": "", "state": normalized}
