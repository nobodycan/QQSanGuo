extends SceneTree

const PlayerStats = preload("res://actors/PlayerStats.gd")
const TestProtocol = preload("res://tests/TestProtocol.gd")

func _init():
	var test = TestProtocol.new()
	var stats = PlayerStats.new()
	var state = stats.new_state()
	for level in range(1, PlayerStats.MAX_LEVEL):
		var required = stats.required_experience(level)
		var before = stats.grant_experience(state, required - 1)
		test.expect(before.level == level and before.experience == required - 1, "xp N-1 stays at level " + str(level))
		var exact = stats.grant_experience(state, required)
		test.expect(exact.level == level + 1 and exact.experience == 0, "xp N levels at level " + str(level))
		var after = stats.grant_experience(state, required + 1)
		if level == PlayerStats.MAX_LEVEL - 1:
			test.expect(after.level == PlayerStats.MAX_LEVEL and after.experience == 0 and after.overflow_experience == 1, "xp N+1 overflows at level cap")
		else:
			test.expect(after.level == level + 1 and after.experience == 1, "xp N+1 carries at level " + str(level))
		state = exact
	var capped = stats.grant_experience(state, 99999)
	test.expect(capped.level == PlayerStats.MAX_LEVEL and capped.experience == 0 and capped.overflow_experience > 0, "level cap never creates level 31")
	var normalized = stats.normalize(capped)
	test.expect(normalized.level == capped.level and normalized.experience == capped.experience and normalized.overflow_experience == capped.overflow_experience, "normalized player v1 state round trips")
	test.finish(self, "player_stats")
