extends Node

signal runtime_event(event_id, payload)

func publish(event_id: String, payload = null) -> Dictionary:
	if event_id.empty():
		return _failure("invalid_event_id")
	emit_signal("runtime_event", event_id, payload)
	return {"ok": true, "error_code": "", "operation_id": "event.publish", "data": null}

func subscribe(target: Object, method: String) -> Dictionary:
	if target == null or method.empty():
		return _failure("invalid_subscriber")
	if not is_connected("runtime_event", target, method):
		connect("runtime_event", target, method)
	return {"ok": true, "error_code": "", "operation_id": "event.subscribe", "data": null}

func _failure(error_code: String) -> Dictionary:
	return {"ok": false, "error_code": error_code, "operation_id": "event", "data": null}
