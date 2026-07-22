extends Reference

const InventoryState = preload("res://actors/InventoryState.gd")

var state = {}
var names_by_template = {}

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
