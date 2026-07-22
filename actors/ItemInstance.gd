extends Reference

var sequence = 0

func new_stack(template: Dictionary, quantity: int) -> Dictionary:
	if template.empty() or not bool(template.get("stackable", false)) or quantity < 1 or quantity > int(template.get("stack_limit", 0)):
		return {}
	return {"template_id": template.id, "quantity": quantity}

func new_instance(template: Dictionary) -> Dictionary:
	if template.empty() or bool(template.get("stackable", false)):
		return {}
	sequence += 1
	return {"template_id": template.id, "instance_id": template.id + "." + str(sequence), "quantity": 1}
