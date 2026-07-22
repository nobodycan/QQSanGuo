extends SceneTree

const SpawnerScope = preload("res://actors/SpawnerScope.gd")
const TestProtocol = preload("res://tests/TestProtocol.gd")

func _init():
	var test = TestProtocol.new()
	var scope = SpawnerScope.new()
	test.expect(scope.spawn("enemy.1") and not scope.spawn("enemy.1"), "actor spawns once per scope")
	test.expect(scope.defeat("enemy.1", "defeat.1").reward, "first defeat grants reward")
	test.expect(not scope.defeat("enemy.1", "defeat.1").ok, "duplicate defeat cannot reward")
	scope.spawn("enemy.2")
	test.expect(scope.cleanup() == 1 and scope.spawned.empty(), "cleanup removes remaining spawned actors")
	test.finish(self, "spawner_scope")
