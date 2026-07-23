extends Reference

const DialogueDefinition = preload("res://actors/DialogueDefinition.gd")

func present(definition: Dictionary, flags: Array) -> Dictionary:
	var nodes = DialogueDefinition.new().available_nodes(definition, flags)
	if nodes.empty(): return {"ok": false, "lines": []}
	var lines = []
	for node in nodes: lines.append({"id": str(node.id), "text": str(node.text)})
	return {"ok": true, "dialogue_id": str(definition.id), "lines": lines}
