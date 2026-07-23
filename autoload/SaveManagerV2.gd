extends Reference

const StateV2 = preload("res://autoload/GameStateV2.gd")
const V1ToV2Migrator = preload("res://autoload/V1ToV2Migrator.gd")

var save_a_path = "user://save_a.json"
var save_b_path = "user://save_b.json"
var state = StateV2.new()

func load_latest() -> Dictionary:
	var candidates = []
	for path in [save_a_path, save_b_path]:
		var loaded = _read_generation(path)
		if loaded.ok: candidates.append(loaded)
	if candidates.empty(): return {"ok": false, "error": "missing_save"}
	candidates.sort_custom(self, "_newer_generation")
	return candidates[0]

func load_latest_compatible(loaded_revision: String, registry: Node = null) -> Dictionary:
	var candidates = []
	var saw_mismatch = false
	for path in [save_a_path, save_b_path]:
		var loaded = _read_generation(path)
		if not loaded.ok:
			continue
		var compatibility = state.validate_content_compatibility(loaded.data, loaded_revision, registry)
		if compatibility.ok:
			loaded.data = compatibility.state
			candidates.append(loaded)
		elif compatibility.reason == "content_revision_mismatch":
			saw_mismatch = true
	if candidates.empty():
		return {"ok": false, "error": "content_revision_mismatch" if saw_mismatch else "missing_save"}
	candidates.sort_custom(self, "_newer_generation")
	return candidates[0]

func save_data(snapshot: Dictionary) -> Dictionary:
	var normalized = state.normalize(snapshot)
	if normalized == null: return {"ok": false, "error": "invalid_state"}
	var current = load_latest()
	var generation = int(current.get("generation", -1)) + 1
	normalized["generation"] = generation
	var target = save_a_path if current.get("path", save_b_path) == save_b_path else save_b_path
	var file = File.new()
	if file.open(target, File.WRITE) != OK: return {"ok": false, "error": "write_failed"}
	file.store_string(to_json(normalized))
	file.close()
	var verified = _read_generation(target)
	if not verified.ok or verified.generation != generation: return {"ok": false, "error": "verify_failed"}
	verified["path"] = target
	return verified

func save_data_compatible(snapshot: Dictionary, loaded_revision: String, registry: Node = null) -> Dictionary:
	var compatibility = state.validate_content_compatibility(snapshot, loaded_revision, registry)
	if not compatibility.ok:
		return {"ok": false, "error": compatibility.reason}
	return save_data(compatibility.state)

func import_legacy_snapshot(legacy_snapshot: Dictionary, registry: Node) -> Dictionary:
	var migrated = V1ToV2Migrator.new().migrate_snapshot_registered(legacy_snapshot, registry)
	if not migrated.ok:
		return {"ok": false, "error": migrated.error}
	return save_data_compatible(migrated.state, str(registry.content_revision()), registry)

func save_runtime_skills(snapshot: Dictionary, inventory: Node, registry: Node) -> Dictionary:
	var captured = state.capture_runtime_skills(snapshot, inventory, registry)
	if not captured.ok:
		return {"ok": false, "error": captured.reason}
	return save_data_compatible(captured.state, str(captured.state.metadata.content_revision), registry)

func load_runtime_skills(loaded_revision: String, inventory: Node, registry: Node) -> Dictionary:
	var loaded = load_latest_compatible(loaded_revision, registry)
	if not loaded.ok:
		return loaded
	var applied = state.apply_runtime_skills(loaded.data, inventory, registry)
	if not applied.ok:
		return {"ok": false, "error": applied.reason}
	loaded.data = applied.state
	return loaded

func _read_generation(path: String) -> Dictionary:
	var file = File.new()
	if not file.file_exists(path) or file.open(path, File.READ) != OK: return {"ok": false}
	var parsed = JSON.parse(file.get_as_text())
	file.close()
	if parsed.error != OK or state.normalize(parsed.result) == null: return {"ok": false}
	return {"ok": true, "path": path, "generation": int(parsed.result.get("generation", -1)), "data": parsed.result}

func _newer_generation(a, b) -> bool:
	return a.generation > b.generation
