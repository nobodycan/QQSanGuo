extends SceneTree

const SaveV2 = preload("res://autoload/SaveManagerV2.gd")
const ContentRegistry = preload("res://autoload/ContentRegistry.gd")
const PlayerInventory = preload("res://PlayerInventory.gd")
const TestProtocol = preload("res://tests/TestProtocol.gd")

func _init():
	var test = TestProtocol.new()
	var manager = SaveV2.new()
	manager.save_a_path = "user://test_runtime_skills_a.json"
	manager.save_b_path = "user://test_runtime_skills_b.json"
	_cleanup(manager)
	var registry = ContentRegistry.new()
	registry.load_content()
	var inventory = PlayerInventory.new()
	inventory.known_skills = ["横击剑"]
	inventory.equipped_skills = ["横击剑"]
	var snapshot = manager.state.new_envelope()
	var saved = manager.save_runtime_skills(snapshot, inventory, registry)
	test.expect(saved.ok and saved.data.skills.known == ["skill.basic_slash"], "saves canonical runtime skills")
	inventory.known_skills = []
	inventory.equipped_skills = []
	var loaded = manager.load_runtime_skills("v1-pilot-phase76", inventory, registry)
	test.expect(loaded.ok and inventory.equipped_skills == ["横击剑"], "restores runtime legacy skill arrays")
	_cleanup(manager)
	inventory.free()
	registry.free()
	test.finish(self, "runtime_skill_save")

func _cleanup(manager):
	var directory = Directory.new()
	for path in [manager.save_a_path, manager.save_b_path]:
		if directory.file_exists(path): directory.remove(path)
