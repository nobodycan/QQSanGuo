extends Node

var _entries = {}

func has_entry(content_id: String) -> bool:
	return _entries.has(content_id)

func get_entry(content_id: String) -> Dictionary:
	if not has_entry(content_id):
		return _failure("content_not_found")
	return {"ok": true, "error_code": "", "operation_id": "content.get", "data": _entries[content_id]}

func validate_id(content_id: String) -> Dictionary:
	if content_id.empty() or not content_id.is_valid_identifier():
		return _failure("invalid_content_id")
	return {"ok": true, "error_code": "", "operation_id": "content.validate", "data": content_id}

func _failure(error_code: String) -> Dictionary:
	return {"ok": false, "error_code": error_code, "operation_id": "content", "data": null}
