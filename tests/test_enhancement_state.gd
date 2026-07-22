extends SceneTree

const EnhancementState = preload("res://actors/EnhancementState.gd")
const TestProtocol = preload("res://tests/TestProtocol.gd")

func _init():
	var test = TestProtocol.new()
	var enhancement = EnhancementState.new()
	var expected = [10000, 10400, 10800, 11200, 11600, 12000, 12400, 12800, 13200, 13600, 14000]
	for level in range(11):
		test.expect(enhancement.multiplier_bps(level) == expected[level], "uses the explicit multiplier for level " + str(level))
		test.expect(enhancement.round_value(25, level) == int(round(25.0 * expected[level] / 10000.0)), "rounds level " + str(level) + " consistently")
	var first = {"instance_id": "sword.same.1", "enhancement_level": 0}
	var second = {"instance_id": "sword.same.2", "enhancement_level": 5}
	var upgraded = enhancement.upgrade(first)
	test.expect(upgraded.enhancement_level == 1 and second.enhancement_level == 5, "upgrades one same-name instance without changing another")
	var capped = second.duplicate(true)
	capped.enhancement_level = 10
	test.expect(enhancement.upgrade(capped).empty() and enhancement.multiplier_bps(11) == 0, "rejects enhancement beyond plus ten")
	var modifiers = enhancement.modifiers({"basic_damage": 25, "basic_defende": 5}, 5)
	test.expect(modifiers.basic_damage == 30 and modifiers.basic_defende == 6 and enhancement.power_score({"basic_damage": 25, "basic_defende": 5}, 5) == 36, "derives rounded modifiers and a deterministic power score")
	test.finish(self, "enhancement_state")
