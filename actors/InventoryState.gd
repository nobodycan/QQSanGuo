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
