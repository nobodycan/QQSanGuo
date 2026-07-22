extends Reference

const SCHEMA_VERSION = 2
const InventoryState = preload("res://actors/InventoryState.gd")

func new_envelope() -> Dictionary:
	return {
		"schema_version": SCHEMA_VERSION,
		"section_versions": {"metadata": 1, "location": 1, "player": 1, "inventory": InventoryState.VERSION, "equipment": 0, "skills": 0, "quests": 0, "world": 0, "legacy": 0},
		"metadata": {"content_revision": "v1-pilot"},
		"location": {"map_id": "", "spawn_id": ""},
		"player": preload("res://actors/PlayerStats.gd").new().new_state(), "inventory": InventoryState.new().new_state(), "equipment": {}, "skills": {}, "quests": {}, "world": {}, "legacy": {}
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
	return result
