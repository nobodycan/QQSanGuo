extends SceneTree

const SaveV2 = preload("res://autoload/SaveManagerV2.gd")
const ContentRegistry = preload("res://autoload/ContentRegistry.gd")
const TestProtocol = preload("res://tests/TestProtocol.gd")

func _init():
	var manager = SaveV2.new()
	var registry = ContentRegistry.new()
	registry.load_content()
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
	var rejected = manager.save_data_compatible(stale, "v1-pilot-phase76", registry)
	test.expect(not rejected.ok and rejected.error == "content_revision_mismatch" and manager.load_latest().generation == 0, "rejects incompatible writes before changing save generations")
	var second = manager.state.new_envelope()
	second.location = {"map_id":"map.jianglin","spawn_id":"spawn.entry"}
	second.skills.known = ["skill.basic_slash"]
	var saved_second = manager.save_data_compatible(second, "v1-pilot-phase76", registry)
	test.expect(saved_second.ok and saved_second.generation == 1 and saved_second.path != saved_first.path, "alternates generation path")
	var incompatible = File.new()
	incompatible.open(saved_second.path, File.READ)
	var incompatible_data = JSON.parse(incompatible.get_as_text()).result
	incompatible.close()
	incompatible_data.skills.known = ["skill.forged"]
	incompatible.open(saved_second.path, File.WRITE)
	incompatible.store_string(to_json(incompatible_data))
	incompatible.close()
	var compatible = manager.load_latest_compatible("v1-pilot-phase76", registry)
	test.expect(compatible.ok and compatible.generation == 0, "falls back when the newer generation references an unknown skill")
	var corrupt = File.new()
	corrupt.open(saved_second.path, File.WRITE)
	corrupt.store_string("{\"schema_version\":999}")
	corrupt.close()
	var recovered = manager.load_latest()
	test.expect(recovered.ok and recovered.generation == 0, "falls back to valid generation")
	var legacy_state = load("res://autoload/GameState.gd").new()
	var legacy_snapshot = legacy_state.new_save_data()
	legacy_state.free()
	legacy_snapshot.map_path = "res://Level1.tscn"
	legacy_snapshot.player.money = 25
	legacy_snapshot.inventory = {"0": ["铁剑", 1]}
	legacy_snapshot.skills = {"known": ["横击剑"], "equipped": ["横击剑"]}
	var imported = manager.import_legacy_snapshot(legacy_snapshot, registry)
	test.expect(imported.ok and imported.generation == 1 and imported.data.wallet.money == 25 and imported.data.inventory.slots[0].template_id == "item.iron_sword" and imported.data.skills.equipped == ["skill.basic_slash"], "imports a registry-validated legacy snapshot into alternating V2 storage")
	legacy_snapshot.inventory = {"0": ["unknown", 1]}
	var rejected_import = manager.import_legacy_snapshot(legacy_snapshot, registry)
	test.expect(not rejected_import.ok and manager.load_latest().generation == 1, "rejects unsafe legacy imports without advancing the V2 generation")
	_cleanup(manager)
	registry.free()
	test.finish(self, "save_manager_v2")

func _cleanup(manager):
	var directory = Directory.new()
	for path in [manager.save_a_path, manager.save_b_path]:
		if directory.file_exists(path): directory.remove(path)
