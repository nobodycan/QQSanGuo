extends SceneTree

const Migrator = preload("res://autoload/V1ToV2Migrator.gd")
const TestProtocol = preload("res://tests/TestProtocol.gd")

func _init():
	var file = File.new()
	var test = TestProtocol.new()
	test.expect(file.open("res://content/v1/legacy_aliases.json", File.READ) == OK, "opens alias table")
	var parsed = JSON.parse(file.get_as_text())
	file.close()
	var migrator = Migrator.new()
	var aliases = parsed.result if parsed.error == OK else {}
	var location = migrator.migrate_location("res://Level1.tscn", aliases)
	test.expect(location.ok and location.location.map_id == "map.level_one", "maps known v1 scene path")
	test.expect(not migrator.migrate_location("res://unknown.tscn", aliases).ok, "rejects unknown v1 scene path")
	test.expect(migrator.migrate_name("铁剑", "items", aliases).id == "item.iron_sword", "maps known legacy item")
	test.expect(not migrator.migrate_name("unknown", "items", aliases).ok, "rejects unknown legacy item")
	test.finish(self, "v1_to_v2_migration")
