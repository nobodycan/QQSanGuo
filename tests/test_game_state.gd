extends SceneTree

func _init():
	var state = preload("res://autoload/GameState.gd").new()
	var data = state.new_save_data()
	assert(data["equipment"].has("Sword"))
	assert(data["equipment"]["Sword"] == "")
	assert(data["skills"]["known"] == [])
	assert(data["skills"]["equipped"] == [])
	data["map_path"] = "res://Level1.tscn"
	data["inventory"] = {"0": ["Iron Sword", 1], "bad": ["", 0]}
	var normalized = state.normalize(data)
	assert(normalized != null)
	assert(normalized["inventory"].has("0"))
	assert(!normalized["inventory"].has("bad"))
	var parsed = JSON.parse(to_json(normalized))
	assert(parsed.error == OK)
	assert(state.normalize(parsed.result) != null)
	data.erase("player")
	assert(state.normalize(data) == null)
	print("TEST_GAME_STATE_PASS")
	quit()
