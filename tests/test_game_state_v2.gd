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
	var legacy_player = state.new_envelope()
	legacy_player.player = {"level": 2, "exprience": 3, "max_health": 1100}
	var migrated_player = state.normalize(legacy_player)
	var remigrated_player = state.normalize(migrated_player)
	test.expect(migrated_player.player.version == 1 and migrated_player.player.level == 2 and migrated_player.player.experience == 3, "upgrades player v0 within v2 envelope")
	test.expect(remigrated_player.player.base.max_health == migrated_player.player.base.max_health and remigrated_player.player.derived.max_health == migrated_player.player.derived.max_health, "player migration remains idempotent in v2 envelope")
	envelope.erase("location")
	test.expect(state.normalize(envelope) == null, "rejects missing location")
	envelope = state.new_envelope()
	envelope.schema_version = 3
	test.expect(state.normalize(envelope) == null, "rejects unsupported schema")
	test.finish(self, "game_state_v2")
