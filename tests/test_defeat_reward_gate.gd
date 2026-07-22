extends SceneTree

const DefeatRewardGate = preload("res://actors/DefeatRewardGate.gd")
const TestProtocol = preload("res://tests/TestProtocol.gd")

func _init():
	var test = TestProtocol.new()
	var gate = DefeatRewardGate.new()
	test.expect(gate.claim("spawn.1.enemy.2") and not gate.claim("spawn.1.enemy.2"), "claims a defeat reward exactly once")
	for _repeat in range(100):
		test.expect(not gate.claim("spawn.1.enemy.2"), "rejects repeated defeat callback")
	test.expect(not gate.claim("") and gate.release("spawn.1.enemy.2") and gate.claim("spawn.1.enemy.2"), "rejects empty IDs and supports scoped cleanup")
	test.finish(self, "defeat_reward_gate")
