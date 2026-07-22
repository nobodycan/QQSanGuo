extends SceneTree

const EnemyBrain = preload("res://actors/EnemyBrain.gd")
const SpawnerScope = preload("res://actors/SpawnerScope.gd")
const TargetRegistry = preload("res://actors/TargetRegistry.gd")
const TestProtocol = preload("res://tests/TestProtocol.gd")

func _init():
	var test = TestProtocol.new()
	var first = _trace(17)
	var second = _trace(17)
	var different_role = _trace(17, "bruiser")
	test.expect(first == second, "same seed produces identical encounter trace")
	test.expect(first != different_role, "enemy role changes the primary encounter trace")
	test.finish(self, "combat_trace")

func _trace(seed_value, role = "skirmisher"):
	seed(seed_value)
	var brain = EnemyBrain.new()
	var scope = SpawnerScope.new()
	var actor_id = "enemy.trace"
	scope.spawn(actor_id)
	var state = brain.IDLE
	var trace = []
	for tick in range(12):
		var distance = 4.0 if tick == 0 else float(randi() % 30)
		var aggro = 12.0 if role == "skirmisher" else 20.0
		var attack = 3.0 if role == "skirmisher" else 6.0
		var registry = TargetRegistry.new()
		registry.register_target(actor_id, TargetRegistry.FACTION_ENEMY, Vector2(distance, 0))
		var target = registry.select_nearest("player.trace", TargetRegistry.FACTION_PLAYER, Vector2.ZERO)
		var has_target = not target.empty()
		state = brain.next_state(state, has_target, distance, aggro, attack, has_target)
		trace.append(state + ":" + target.id + ":" + str(int(distance)))
	return trace
