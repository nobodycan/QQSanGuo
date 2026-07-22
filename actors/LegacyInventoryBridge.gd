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
	names_by_template.clear()
	for legacy_name in aliases:
		var template_id = str(aliases[legacy_name])
		var template = templates_by_name.get(str(legacy_name), {})
		if template.empty() or template.id != template_id:
			return false
		names_by_template[template_id] = str(legacy_name)
	for index in range(InventoryState.SLOT_COUNT):
		var slot = migrated.slots[index]
		if slot.empty():
			continue
		var template = templates_by_name.get(str(names_by_template.get(str(slot.template_id), "")), {})
		if template.empty() or int(slot.quantity) > int(template.stack_limit):
			return false
		if not template.stackable:
			if int(slot.quantity) != 1:
				return false
			migrated.slots[index] = instances.new_instance(template)
	state = migrated
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

func take(slot_index: int) -> Dictionary:
	var normalized = InventoryState.new().normalize(state)
	if normalized.empty() or slot_index < 0 or slot_index >= InventoryState.SLOT_COUNT or normalized.slots[slot_index].empty():
		return {}
	var taken = normalized.slots[slot_index].duplicate(true)
	normalized.slots[slot_index] = {}
	state = normalized
	return taken

func place(slot_index: int, legacy_name: String, quantity: int, stack_limit: int) -> bool:
	var template = register_template(legacy_name, stack_limit)
	var normalized = InventoryState.new().normalize(state)
	if template.empty() or normalized.empty() or slot_index < 0 or slot_index >= InventoryState.SLOT_COUNT or quantity < 1 or quantity > int(template.stack_limit) or not normalized.slots[slot_index].empty():
		return false
	normalized.slots[slot_index] = instances.new_stack(template, quantity) if template.stackable else instances.new_instance(template)
	if normalized.slots[slot_index].empty():
		return false
	state = normalized
	return true

func adjust(slot_index: int, quantity_delta: int) -> bool:
	var normalized = InventoryState.new().normalize(state)
	if normalized.empty() or slot_index < 0 or slot_index >= InventoryState.SLOT_COUNT or quantity_delta == 0:
		return false
	var slot = normalized.slots[slot_index]
	if slot.empty():
		return false
	var template_id = str(slot.get("template_id", ""))
	var legacy_name = str(names_by_template.get(template_id, ""))
	var template = templates_by_name.get(legacy_name, {})
	var next_quantity = int(slot.get("quantity", 0)) + quantity_delta
	if template.empty() or next_quantity < 0 or next_quantity > int(template.stack_limit):
		return false
	if next_quantity == 0:
		normalized.slots[slot_index] = {}
	else:
		slot.quantity = next_quantity
	state = normalized
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
