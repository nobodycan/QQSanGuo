extends SceneTree

const ContentRegistry = preload("res://autoload/ContentRegistry.gd")
const TestProtocol = preload("res://tests/TestProtocol.gd")

func _init():
	var test = TestProtocol.new()
	var registry = ContentRegistry.new()
	var loaded = registry.load_content()
	test.expect(loaded.ok and loaded.data.entry_count == 4 and registry.content_revision() == "v1-pilot" and registry.has_entry("map.level_one"), "loads every manifest content pack into one stable registry revision")
	var map = registry.get_entry("map.jianglin")
	test.expect(map.ok and map.data.scene == "res://JiangLinXiJiao.tscn", "returns trusted map definitions by stable ID")
	map.data.scene = "res://mutated.tscn"
	test.expect(registry.get_entry("map.jianglin").data.scene == "res://JiangLinXiJiao.tscn", "does not expose mutable references to registered content")
	var maps = registry.entries_of_kind("map")
	test.expect(maps.size() == 2 and maps[0].id == "map.jianglin" and maps[1].id == "map.level_one", "exposes copied content definitions in stable ID order")
	var legacy_item = registry.resolve_legacy("items", "铁剑")
	var legacy_map = registry.resolve_legacy("maps", "res://Level1.tscn")
	test.expect(legacy_item.ok and legacy_item.data == "item.iron_sword" and legacy_map.ok and legacy_map.data.map_id == "map.level_one", "resolves validated legacy names and map paths through the registry")
	test.expect(not registry.load_content("res://tests/fixtures/content_invalid_manifest.json").ok and registry.has_entry("skill.basic_slash"), "rejects incomplete typed entries without replacing loaded content")
	test.expect(not registry.validate_id("map.bad-id").ok and not registry.get_entry("map.unknown").ok and not registry.resolve_legacy("items", "unknown").ok, "rejects malformed, unknown, and unaliased content")
	registry.free()
	test.finish(self, "content_registry")
