extends SceneTree

const EffectState = preload("res://actors/EffectState.gd")
const TestProtocol = preload("res://tests/TestProtocol.gd")

func _init():
	var test = TestProtocol.new()
	var state = EffectState.new()
	var effects = state.apply([], {"id": "burn", "remaining_ticks": 2, "power": 3, "max_stacks": 2})
	effects = state.apply(effects, {"id": "burn", "remaining_ticks": 1, "power": 3, "max_stacks": 2})
	test.expect(effects.size() == 1 and effects[0].stacks == 2 and effects[0].remaining_ticks == 2, "same effect stacks and refreshes")
	var first = state.tick(effects)
	test.expect(first.total_power == 6 and first.effects.size() == 1, "tick applies stacked power")
	var second = state.tick(first.effects)
	test.expect(second.effects.empty(), "expired effect is removed")
	test.finish(self, "effect_state")
