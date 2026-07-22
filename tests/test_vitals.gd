extends SceneTree

const Vitals = preload("res://actors/Vitals.gd")
const TestProtocol = preload("res://tests/TestProtocol.gd")

func _init():
	var test = TestProtocol.new()
	var vitals = Vitals.new()
	var state = vitals.new_state(100, 50)
	state = vitals.damage(state, 120)
	test.expect(state.health == 0 and not state.alive and state.death_count == 1, "damage clamps and records one death")
	state = vitals.damage(state, 1)
	test.expect(state.death_count == 1, "repeated damage cannot duplicate death")
	state = vitals.recover(state, 50, 50)
	test.expect(state.health == 0 and state.magic == 50, "dead actors do not recover")
	state = vitals.revive(state, 999, 999)
	test.expect(state.alive and state.health == 100 and state.magic == 50, "revive clamps vitals")
	state = vitals.recover(state, -1, -1)
	test.expect(state.health == 100 and state.magic == 50, "negative recovery is ignored")
	test.finish(self, "vitals")
