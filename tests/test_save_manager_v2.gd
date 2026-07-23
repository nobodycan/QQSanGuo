extends SceneTree

const SaveV2 = preload("res://autoload/SaveManagerV2.gd")
const TestProtocol = preload("res://tests/TestProtocol.gd")

func _init():
	var manager = SaveV2.new()
	manager.save_a_path = "user://test_v2_a.json"
	manager.save_b_path = "user://test_v2_b.json"
	_cleanup(manager)
	var test = TestProtocol.new()
	var first = manager.state.new_envelope()
	first.location = {"map_id":"map.level_one","spawn_id":"spawn.start"}
	var saved_first = manager.save_data(first)
	test.expect(saved_first.ok and saved_first.generation == 0, "writes initial generation")
	var stale = manager.state.new_envelope()
	stale.metadata.content_revision = "v2-next"
	var rejected = manager.save_data_compatible(stale, "v1-pilot")
	test.expect(not rejected.ok and rejected.error == "content_revision_mismatch" and manager.load_latest().generation == 0, "rejects incompatible writes before changing save generations")
	var second = manager.state.new_envelope()
	second.location = {"map_id":"map.jianglin","spawn_id":"spawn.entry"}
	var saved_second = manager.save_data(second)
	test.expect(saved_second.ok and saved_second.generation == 1 and saved_second.path != saved_first.path, "alternates generation path")
	var incompatible = File.new()
	incompatible.open(saved_second.path, File.READ)
	var incompatible_data = JSON.parse(incompatible.get_as_text()).result
	incompatible.close()
	incompatible_data.metadata.content_revision = "v2-next"
	incompatible.open(saved_second.path, File.WRITE)
	incompatible.store_string(to_json(incompatible_data))
	incompatible.close()
	var compatible = manager.load_latest_compatible("v1-pilot")
	test.expect(compatible.ok and compatible.generation == 0, "falls back to the newest content-compatible generation")
	var corrupt = File.new()
	corrupt.open(saved_second.path, File.WRITE)
	corrupt.store_string("{\"schema_version\":999}")
	corrupt.close()
	var recovered = manager.load_latest()
	test.expect(recovered.ok and recovered.generation == 0, "falls back to valid generation")
	_cleanup(manager)
	test.finish(self, "save_manager_v2")

func _cleanup(manager):
	var directory = Directory.new()
	for path in [manager.save_a_path, manager.save_b_path]:
		if directory.file_exists(path): directory.remove(path)
