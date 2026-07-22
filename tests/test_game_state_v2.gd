extends SceneTree

const StateV2 = preload("res://autoload/GameStateV2.gd")
const TestProtocol = preload("res://tests/TestProtocol.gd")

func _init():
	var state = StateV2.new()
	var test = TestProtocol.new()
	var envelope = state.new_envelope()
	envelope.location = {"map_id": "map.level_one", "spawn_id": "spawn.start"}
	var normalized = state.normalize(envelope)
	test.expect(normalized != null, "normalizes valid v2 envelope")
	var parsed = JSON.parse(to_json(normalized))
	test.expect(parsed.error == OK and state.normalize(parsed.result) != null, "v2 envelope round trips through JSON")
	envelope.erase("location")
	test.expect(state.normalize(envelope) == null, "rejects missing location")
	envelope = state.new_envelope()
	envelope.schema_version = 3
	test.expect(state.normalize(envelope) == null, "rejects unsupported schema")
	test.finish(self, "game_state_v2")
