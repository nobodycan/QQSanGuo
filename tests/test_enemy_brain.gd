extends SceneTree

const EnemyBrain = preload("res://actors/EnemyBrain.gd")
const TestProtocol = preload("res://tests/TestProtocol.gd")

func _init():
	var test = TestProtocol.new()
	var brain = EnemyBrain.new()
	test.expect(brain.next_state(brain.IDLE, true, 5, 20, 5, true) == brain.ATTACK, "close target attacks")
	test.expect(brain.next_state(brain.IDLE, true, 10, 20, 5, true) == brain.CHASE, "visible target chases")
	test.expect(brain.next_state(brain.CHASE, false, 0, 20, 5, true) == brain.RETURN, "lost target returns")
	test.expect(brain.next_state(brain.ATTACK, true, 0, 20, 5, false) == brain.DEAD, "dead enemy exits combat")
	var state = brain.IDLE
	for tick in range(10000):
		state = brain.next_state(state, tick % 7 != 0, float(tick % 30), 20.0, 5.0, tick % 997 != 0)
		test.expect([brain.IDLE, brain.CHASE, brain.ATTACK, brain.RETURN, brain.DEAD].has(state), "state remains valid at tick " + str(tick))
	test.finish(self, "enemy_brain")
