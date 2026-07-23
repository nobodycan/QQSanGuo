extends SceneTree

const ContentRegistry = preload("res://autoload/ContentRegistry.gd")
const TestProtocol = preload("res://tests/TestProtocol.gd")

func _init():
	var test = TestProtocol.new()
	var registry = ContentRegistry.new()
	var loaded = registry.load_content()
	test.expect(loaded.ok and loaded.data.entry_count == 4 and registry.has_entry("map.level_one"), "loads every manifest content pack into one stable registry")
	var map = registry.get_entry("map.jianglin")
	test.expect(map.ok and map.data.scene == "res://JiangLinXiJiao.tscn", "returns trusted map definitions by stable ID")
	test.expect(registry.entries_of_kind("map").size() == 2, "exposes copied definitions by declared content kind")
	test.expect(not registry.validate_id("map.bad-id").ok and not registry.get_entry("map.unknown").ok, "rejects malformed and unknown content IDs")
	registry.free()
	test.finish(self, "content_registry")
