extends SceneTree

const Migrator = preload("res://autoload/V1ToV2Migrator.gd")
const ContentRegistry = preload("res://autoload/ContentRegistry.gd")
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
	var registry = ContentRegistry.new()
	registry.load_content()
	test.expect(migrator.migrate_location_registered("res://Level1.tscn", registry).location.map_id == "map.level_one" and migrator.migrate_name_registered("铁剑", "items", registry).id == "item.iron_sword", "migrates legacy data through validated registry aliases")
	var migrated_skills = migrator.migrate_skills_registered({"known": ["横击剑", "饮血剑舞"], "equipped": ["饮血剑舞"]}, registry)
	test.expect(migrated_skills.ok and migrated_skills.state.equipped == ["skill.blood_sword_dance"] and not migrator.migrate_skills_registered({"known": ["unknown"], "equipped": []}, registry).ok, "migrates only validated legacy skills to canonical state")
	var legacy_state = load("res://autoload/GameState.gd").new()
	var legacy_snapshot = legacy_state.new_save_data()
	legacy_state.free()
	legacy_snapshot.map_path = "res://Level1.tscn"
	legacy_snapshot.player.money = 50
	legacy_snapshot.player.juntuan = 2
	legacy_snapshot.inventory = {"0": ["铁剑", 1]}
	legacy_snapshot.equipment.Sword = "铁剑"
	legacy_snapshot.skills = {"known": ["横击剑"], "equipped": ["横击剑"]}
	var snapshot = migrator.migrate_snapshot_registered(legacy_snapshot, registry)
	test.expect(snapshot.ok and snapshot.state.location.map_id == "map.level_one" and snapshot.state.wallet.money == 50 and snapshot.state.inventory.slots[0].template_id == "item.iron_sword" and snapshot.state.equipment.slots.Sword.modifiers.basic_damage == 4 and snapshot.state.skills.equipped == ["skill.basic_slash"], "migrates complete legacy snapshots through trusted registry data")
	test.expect(snapshot.ok and snapshot.state.legacy.v1_snapshot.hotbar.empty() and snapshot.state.legacy.v1_snapshot.player.money == 50, "retains legacy-only snapshot fields during staged V2 adoption")
	legacy_snapshot.inventory = {"0": ["unknown", 1]}
	test.expect(not migrator.migrate_snapshot_registered(legacy_snapshot, registry).ok, "rejects a full migration when any legacy inventory entry is unresolved")
	registry.free()
	test.finish(self, "v1_to_v2_migration")
