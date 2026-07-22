extends SceneTree

var scene_paths = []
var failures = []
var loaded_count = 0

func _init():
	print("RESOURCE_SCENE_SMOKE_START")
	var manifest_file = File.new()
	if manifest_file.open("res://Data/scene_manifest.json", File.READ) != OK:
		failures.append({"code": "manifest_open", "path": "res://Data/scene_manifest.json"})
		call_deferred("_run_smoke")
		return
	var parsed = JSON.parse(manifest_file.get_as_text())
	manifest_file.close()
	if parsed.error != OK or typeof(parsed.result) != TYPE_DICTIONARY or parsed.result.get("schema_version", 0) != 1:
		failures.append({"code": "manifest_parse", "path": "res://Data/scene_manifest.json"})
	else:
		for path in parsed.result.get("scenes", []):
			if typeof(path) == TYPE_STRING and path.begins_with("res://") and path.ends_with(".tscn"):
				scene_paths.append(path)
			else:
				failures.append({"code": "manifest_entry", "path": str(path)})
	call_deferred("_run_smoke")

func _run_smoke():
	for path in scene_paths:
		print("RESOURCE_SCENE_SMOKE_SCENE " + path)
		var packed = ResourceLoader.load(path)
		if packed == null or not (packed is PackedScene):
			failures.append({"code": "scene_load", "path": path})
			continue
		loaded_count += 1
	var result = {
		"ok": failures.empty(),
		"scene_count": scene_paths.size(),
		"loaded_count": loaded_count,
		"failures": failures
	}
	result["test_id"] = "resource_scene_smoke"
	print("TEST_RESULT " + to_json(result))
	quit(0 if failures.empty() else 1)
