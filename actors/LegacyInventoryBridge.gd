extends Reference

const InventoryState = preload("res://actors/InventoryState.gd")
const ItemTemplate = preload("res://actors/ItemTemplate.gd")
const ItemInstance = preload("res://actors/ItemInstance.gd")

var state = {}
var names_by_template = {}
var templates_by_name = {}
var instances = ItemInstance.new()

func register_template(legacy_name: String, stack_limit: int) -> Dictionary:
	if legacy_name.empty() or stack_limit < 1:
		return {}
	if templates_by_name.has(legacy_name):
		return templates_by_name[legacy_name]
	var template = ItemTemplate.new().normalize({"id": "legacy." + legacy_name.md5_text(), "stack_limit": stack_limit})
	if template.empty():
		return {}
	templates_by_name[legacy_name] = template
	names_by_template[template.id] = legacy_name
	return template

func import_legacy(legacy: Dictionary, aliases: Dictionary) -> bool:
	var inventory = InventoryState.new()
	var migrated = inventory.migrate_v0(legacy, aliases)
	if migrated.empty():
		return false
	state = migrated
	names_by_template.clear()
	for legacy_name in aliases:
		names_by_template[str(aliases[legacy_name])] = str(legacy_name)
	return true

func add_legacy(legacy_name: String, quantity: int, stack_limit: int) -> bool:
	var template = register_template(legacy_name, stack_limit)
	if template.empty() or quantity < 1:
		return false
	if state.empty():
		state = InventoryState.new().normalize(InventoryState.new().new_state())
	var next = InventoryState.new().add(state, template, quantity, instances)
	if next.empty():
		return false
	state = next
	return true

func move(from_slot: int, to_slot: int) -> bool:
	var next = InventoryState.new().move(state, from_slot, to_slot)
	if next.empty():
		return false
	state = next
	return true

func split(from_slot: int, to_slot: int, quantity: int) -> bool:
	var next = InventoryState.new().split(state, from_slot, to_slot, quantity)
	if next.empty():
		return false
	state = next
	return true

func export_state() -> Dictionary:
	return InventoryState.new().export_state(state)

func project_legacy() -> Dictionary:
	var result = {}
	var normalized = InventoryState.new().normalize(state)
	if normalized.empty():
		return result
	for index in range(InventoryState.SLOT_COUNT):
		var slot = normalized.slots[index]
		if slot.empty():
			continue
		var template_id = str(slot.get("template_id", ""))
		var name = str(names_by_template.get(template_id, ""))
		if name.empty():
			return {}
		result[index] = [name, int(slot.get("quantity", 0))]
	return result
