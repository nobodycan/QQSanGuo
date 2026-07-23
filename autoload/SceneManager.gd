extends Node

const GameStateScript = preload("res://autoload/GameState.gd")
const GameStateV2 = preload("res://autoload/GameStateV2.gd")
const MapAccessPolicy = preload("res://actors/MapAccessPolicy.gd")

func restore_snapshot(snapshot):
	var state = _game_state()
	var normalized = state.normalize(snapshot)
	if normalized == null:
		return _failure("invalid_state")
	var scene_operation = change_to_map(normalized.map_path)
	var scene_result = scene_operation
	if scene_operation is GDScriptFunctionState:
		scene_result = yield(scene_operation, "completed")
	if not scene_result["ok"]:
		return scene_result
	if not state.apply_to_scene(get_tree().current_scene, normalized):
		return _failure("apply_failed")
	return {"ok": true}

func change_to_map(map_path):
	if typeof(map_path) != TYPE_STRING or not map_path.begins_with("res://") or not map_path.ends_with(".tscn"):
		return _failure("invalid_map_path")
	if not ResourceLoader.exists(map_path):
		return _failure("scene_change_failed")
	if get_tree().change_scene(map_path) != OK:
		return _failure("scene_change_failed")
	yield(get_tree(), "idle_frame")
	while get_tree().current_scene == null:
		yield(get_tree(), "idle_frame")
	return {"ok": true}

func restore_v2_legacy_snapshot(snapshot: Dictionary, loaded_revision: String, registry: Node = null):
	var compatible = GameStateV2.new().validate_content_compatibility(snapshot, loaded_revision, registry)
	if not compatible.ok:
		return _failure(compatible.reason)
	var legacy = compatible.state.get("legacy", {})
	if typeof(legacy) != TYPE_DICTIONARY or typeof(legacy.get("v1_snapshot", null)) != TYPE_DICTIONARY:
		return _failure("legacy_snapshot_unavailable")
	return restore_snapshot(legacy.v1_snapshot)

func replace_world(world_root: Node, map_path: String) -> Dictionary:
	if world_root == null or typeof(map_path) != TYPE_STRING or not map_path.begins_with("res://") or not map_path.ends_with(".tscn"):
		return _failure("invalid_world_request")
	if not ResourceLoader.exists(map_path):
		return _failure("scene_load_failed")
	var packed = load(map_path)
	if not (packed is PackedScene):
		return _failure("scene_load_failed")
	var candidate = packed.instance()
	if candidate == null:
		return _failure("scene_instance_failed")
	var previous = world_root.get_child(0) if world_root.get_child_count() > 0 else null
	world_root.add_child(candidate)
	if previous != null:
		world_root.remove_child(previous)
		previous.queue_free()
	return {"ok": true, "map_path": map_path}

func replace_world_if_allowed(world_root: Node, map_path: String, maps: Array, world_state: Dictionary, target_map_id: String, target_spawn_id: String, current_map_id: String = "") -> Dictionary:
	var access = MapAccessPolicy.new().can_enter(maps, world_state, target_map_id, target_spawn_id, current_map_id)
	if not access.ok:
		return _failure("map_" + access.reason)
	return replace_world(world_root, map_path)

func replace_registered_world_if_allowed(world_root: Node, registry: Node, world_state: Dictionary, target_map_id: String, target_spawn_id: String, current_map_id: String = "") -> Dictionary:
	var access = MapAccessPolicy.new().can_enter_registered(registry, world_state, target_map_id, target_spawn_id, current_map_id)
	if not access.ok:
		return _failure("map_" + access.reason)
	var entry = registry.get_entry(target_map_id)
	if not entry.ok or str(entry.data.get("kind", "")) != "map":
		return _failure("map_registry_entry_invalid")
	return replace_world(world_root, str(entry.data.get("scene", "")))

func _game_state():
	var singleton = get_node_or_null("/root/GameState")
	return singleton if singleton != null else GameStateScript.new()

func _failure(error_code: String) -> Dictionary:
	return {"ok": false, "error": error_code}
