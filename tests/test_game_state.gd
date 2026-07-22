extends SceneTree

const TestProtocol = preload("res://tests/TestProtocol.gd")

func _init():
	var state = preload("res://autoload/GameState.gd").new()
	var data = state.new_save_data()
	var test = TestProtocol.new()
	test.expect(data["equipment"].has("Sword"), "default equipment includes Sword")
	test.expect(data["equipment"]["Sword"] == "", "default Sword slot is empty")
	test.expect(data["skills"]["known"] == [], "known skills default to empty")
	test.expect(data["skills"]["equipped"] == [], "equipped skills default to empty")
	data["map_path"] = "res://Level1.tscn"
	data["inventory"] = {"0": ["Iron Sword", 1], "bad": ["", 0]}
	var normalized = state.normalize(data)
	test.expect(normalized != null, "normalizes valid state")
	test.expect(normalized != null and normalized["inventory"].has("0"), "keeps valid inventory entry")
	test.expect(normalized != null and !normalized["inventory"].has("bad"), "drops invalid inventory entry")
	var parsed = JSON.parse(to_json(normalized))
	test.expect(parsed.error == OK, "normalized state serializes as JSON")
	test.expect(parsed.error == OK and state.normalize(parsed.result) != null, "serialized state normalizes again")
	data.erase("player")
	test.expect(state.normalize(data) == null, "rejects missing player section")
	state.free()
	test.finish(self, "game_state")
