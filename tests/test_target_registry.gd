extends SceneTree

const TargetRegistry = preload("res://actors/TargetRegistry.gd")
const TestProtocol = preload("res://tests/TestProtocol.gd")

func _init():
	var test = TestProtocol.new()
	var registry = TargetRegistry.new()
	test.expect(registry.register_target("enemy.b", TargetRegistry.FACTION_ENEMY, Vector2(10, 0)), "registers target")
	test.expect(registry.register_target("enemy.a", TargetRegistry.FACTION_ENEMY, Vector2(10, 0)), "registers tie target")
	test.expect(registry.register_target("ally", TargetRegistry.FACTION_PLAYER, Vector2(1, 0)), "registers friendly target")
	var selected = registry.select_nearest("player", TargetRegistry.FACTION_PLAYER, Vector2.ZERO)
	test.expect(selected.id == "enemy.a", "selection is stable and ignores friends")
	registry.unregister_target("enemy.a")
	selected = registry.select_nearest("player", TargetRegistry.FACTION_PLAYER, Vector2.ZERO)
	test.expect(selected.id == "enemy.b", "released target clears within next selection")
	registry.unregister_target("enemy.b")
	test.expect(registry.select_nearest("player", TargetRegistry.FACTION_PLAYER, Vector2.ZERO).empty(), "empty registry has no target")
	test.finish(self, "target_registry")
