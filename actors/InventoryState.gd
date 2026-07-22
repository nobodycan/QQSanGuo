extends Reference

const VERSION = 1
const SLOT_COUNT = 50

func new_state() -> Dictionary:
	return {"version": VERSION, "slots": []}

func normalize(raw) -> Dictionary:
	if typeof(raw) != TYPE_DICTIONARY or int(raw.get("version", -1)) != VERSION or typeof(raw.get("slots", null)) != TYPE_ARRAY or raw.slots.size() > SLOT_COUNT:
		return {}
	var result = new_state()
	for slot in raw.slots:
		result.slots.append(slot.duplicate(true) if typeof(slot) == TYPE_DICTIONARY else {})
	while result.slots.size() < SLOT_COUNT:
		result.slots.append({})
	return result

func add(state: Dictionary, template: Dictionary, quantity: int, instances) -> Dictionary:
	var result = normalize(state)
	if result.empty() or template.empty() or quantity < 1:
		return {}
	var remaining = quantity
	if template.stackable:
		for index in range(SLOT_COUNT):
			var slot = result.slots[index]
			if slot.get("template_id", "") == template.id and not slot.has("instance_id"):
				var added = min(remaining, int(template.stack_limit) - int(slot.quantity))
				slot.quantity += added
				remaining -= added
				if remaining == 0:
					return result
	for index in range(SLOT_COUNT):
		if not result.slots[index].empty():
			continue
		var amount = min(remaining, int(template.stack_limit)) if template.stackable else 1
		result.slots[index] = instances.new_stack(template, amount) if template.stackable else instances.new_instance(template)
		remaining -= amount
		if remaining == 0:
			return result
	return {}

func move(state: Dictionary, from_slot: int, to_slot: int) -> Dictionary:
	var result = normalize(state)
	if result.empty() or from_slot < 0 or from_slot >= SLOT_COUNT or to_slot < 0 or to_slot >= SLOT_COUNT or from_slot == to_slot or result.slots[from_slot].empty():
		return {}
	var moving = result.slots[from_slot]
	result.slots[from_slot] = result.slots[to_slot]
	result.slots[to_slot] = moving
	return result

func split(state: Dictionary, from_slot: int, to_slot: int, quantity: int) -> Dictionary:
	var result = normalize(state)
	if result.empty() or from_slot < 0 or from_slot >= SLOT_COUNT or to_slot < 0 or to_slot >= SLOT_COUNT or from_slot == to_slot or quantity < 1 or not result.slots[to_slot].empty():
		return {}
	var source = result.slots[from_slot]
	if source.empty() or source.has("instance_id") or int(source.get("quantity", 0)) <= quantity:
		return {}
	source.quantity -= quantity
	result.slots[to_slot] = {"template_id": source.template_id, "quantity": quantity}
	return result

func consume(state: Dictionary, slot_index: int, quantity: int, template: Dictionary) -> Dictionary:
	var result = normalize(state)
	if result.empty() or slot_index < 0 or slot_index >= SLOT_COUNT or quantity < 1 or bool(template.get("quest", false)):
		return {}
	var slot = result.slots[slot_index]
	if slot.empty() or slot.get("template_id", "") != template.get("id", "") or int(slot.get("quantity", 0)) < quantity:
		return {}
	slot.quantity -= quantity
	if slot.quantity == 0:
		result.slots[slot_index] = {}
	return result
