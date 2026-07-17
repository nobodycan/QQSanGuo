extends Node

const VERSION = 1
const EQUIPMENT_SLOTS = ["Head", "Up_Body", "Necklace", "Hand", "Sword", "Boot", "Down_Body", "Wing", "Mask", "Ring"]

func new_save_data() -> Dictionary:
	return {
		"version": VERSION,
		"map_path": "",
		"player": {
			"position": {"x": 0.0, "y": 0.0},
			"level": 1,
			"experience": 0,
			"health": 1000,
			"magic": 1000,
			"money": 0,
			"juntuan": 0,
			"attributes": {
				"max_health": 1000, "max_magic": 1000, "basic_damage": 20,
				"basic_defende": 10, "basic_shugong": 0, "basic_shufang": 0,
				"force": 0, "agility": 0, "strong": 0, "wisdom": 0, "aim": 0
			}
		},
		"inventory": {},
		"hotbar": {},
		"equipment": _empty_equipment(),
		"skills": {"known": [], "equipped": []}
	}

func normalize(raw):
	if typeof(raw) != TYPE_DICTIONARY or not _is_integer(raw.get("version", null)) or int(raw.version) != VERSION:
		return null
	if typeof(raw.get("map_path", null)) != TYPE_STRING or raw.map_path.empty() or not raw.map_path.begins_with("res://") or not raw.map_path.ends_with(".tscn"):
		return null
	if typeof(raw.get("player", null)) != TYPE_DICTIONARY or typeof(raw.get("inventory", null)) != TYPE_DICTIONARY or typeof(raw.get("hotbar", null)) != TYPE_DICTIONARY or typeof(raw.get("equipment", null)) != TYPE_DICTIONARY or typeof(raw.get("skills", null)) != TYPE_DICTIONARY:
		return null
	var player = _normalize_player(raw.player)
	if player == null:
		return null
	var result = new_save_data()
	result.map_path = raw.map_path
	result.player = player
	result.inventory = _normalize_items(raw.inventory)
	result.hotbar = _normalize_items(raw.hotbar)
	result.equipment = _normalize_equipment(raw.equipment)
	result.skills = _normalize_skills(raw.skills)
	return result

func capture_from_scene(scene_root) -> Dictionary:
	if scene_root == null:
		return {}
	var steve = scene_root.get_node_or_null("Steve")
	if steve == null:
		return {}
	var inventory_state = _player_inventory()
	if inventory_state == null:
		return {}
	var result = new_save_data()
	result.map_path = scene_root.filename
	result.player.position = {"x": steve.position.x, "y": steve.position.y}
	result.player.level = inventory_state.level
	result.player.experience = steve.experience_pool
	result.player.health = steve.health
	result.player.magic = steve.magic
	result.player.money = inventory_state.money
	result.player.juntuan = inventory_state.juntuan
	for key in result.player.attributes:
		result.player.attributes[key] = inventory_state.get(key)
	result.inventory = _string_keyed_copy(inventory_state.inventory)
	result.hotbar = _string_keyed_copy(inventory_state.hotbar)
	result.equipment = _normalize_equipment(inventory_state.equipment)
	result.skills = {"known": inventory_state.known_skills.duplicate(), "equipped": inventory_state.equipped_skills.duplicate()}
	return normalize(result)

func apply_to_scene(scene_root, snapshot) -> bool:
	var data = normalize(snapshot)
	if data == null or scene_root == null:
		return false
	var steve = scene_root.get_node_or_null("Steve")
	if steve == null:
		return false
	var inventory_state = _player_inventory()
	if inventory_state == null:
		return false
	inventory_state.level = data.player.level
	inventory_state.money = data.player.money
	inventory_state.juntuan = data.player.juntuan
	for key in data.player.attributes:
		inventory_state.set(key, data.player.attributes[key])
	inventory_state.inventory = _integer_keyed_copy(data.inventory)
	inventory_state.hotbar = _integer_keyed_copy(data.hotbar)
	inventory_state.equipment = data.equipment.duplicate(true)
	inventory_state.known_skills = data.skills.known.duplicate()
	inventory_state.equipped_skills = data.skills.equipped.duplicate()
	steve.position = Vector2(data.player.position.x, data.player.position.y)
	steve.experience_pool = data.player.experience
	steve.health = data.player.health
	steve.magic = data.player.magic
	return true

func _empty_equipment() -> Dictionary:
	var equipment = {}
	for slot in EQUIPMENT_SLOTS:
		equipment[slot] = ""
	return equipment

func _normalize_player(raw):
	if typeof(raw.get("position", null)) != TYPE_DICTIONARY or typeof(raw.get("attributes", null)) != TYPE_DICTIONARY:
		return null
	var required = ["level", "experience", "health", "magic", "money", "juntuan"]
	for key in required:
		if not raw.has(key) or not _is_integer(raw[key]):
			return null
	var x_type = typeof(raw.position.get("x", null))
	var y_type = typeof(raw.position.get("y", null))
	if not raw.position.has("x") or not raw.position.has("y") or (x_type != TYPE_INT and x_type != TYPE_REAL) or (y_type != TYPE_INT and y_type != TYPE_REAL):
		return null
	var result = new_save_data().player
	for key in required:
		result[key] = int(raw[key])
	result.position = {"x": raw.position.x, "y": raw.position.y}
	for key in result.attributes:
		if not raw.attributes.has(key) or not _is_integer(raw.attributes[key]):
			return null
		result.attributes[key] = int(raw.attributes[key])
	return result

func _normalize_items(raw: Dictionary) -> Dictionary:
	var result = {}
	for key in raw:
		var item = raw[key]
		if typeof(item) == TYPE_ARRAY and item.size() == 2 and typeof(item[0]) == TYPE_STRING and not item[0].empty() and _is_integer(item[1]) and int(item[1]) > 0:
			result[str(key)] = [item[0], int(item[1])]
	return result

func _normalize_equipment(raw: Dictionary) -> Dictionary:
	var result = _empty_equipment()
	for slot in EQUIPMENT_SLOTS:
		if raw.has(slot) and typeof(raw[slot]) == TYPE_STRING:
			result[slot] = raw[slot]
	return result

func _normalize_skills(raw: Dictionary) -> Dictionary:
	var result = {"known": [], "equipped": []}
	for key in result:
		if typeof(raw.get(key, [])) == TYPE_ARRAY:
			for skill_id in raw[key]:
				if typeof(skill_id) == TYPE_STRING and not skill_id.empty() and not result[key].has(skill_id):
					result[key].append(skill_id)
	return result

func _string_keyed_copy(raw: Dictionary) -> Dictionary:
	var result = {}
	for key in raw:
		result[str(key)] = raw[key].duplicate() if typeof(raw[key]) == TYPE_ARRAY else raw[key]
	return result

func _integer_keyed_copy(raw: Dictionary) -> Dictionary:
	var result = {}
	for key in raw:
		result[int(key)] = raw[key].duplicate() if typeof(raw[key]) == TYPE_ARRAY else raw[key]
	return result

func _player_inventory():
	return get_node_or_null("/root/PlayerInventory")

func _is_integer(value) -> bool:
	var value_type = typeof(value)
	return (value_type == TYPE_INT or value_type == TYPE_REAL) and int(value) == value
