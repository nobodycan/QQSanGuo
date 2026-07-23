extends SceneTree

const DungeonState = preload("res://actors/DungeonState.gd")
const TestProtocol = preload("res://tests/TestProtocol.gd")

func _init():
	var test = TestProtocol.new()
	var dungeon = DungeonState.new()
	var state = dungeon.new_state("dungeon.pilot")
	state = dungeon.apply(state, "enter.1", "enter").state
	state = dungeon.apply(state, "checkpoint.1", "checkpoint", "checkpoint.wave_two").state
	state = dungeon.apply(state, "fail.1", "fail").state
	state = dungeon.apply(state, "retry.1", "retry").state
	state = dungeon.apply(state, "complete.1", "complete").state
	test.expect(state.status == DungeonState.COMPLETED and state.checkpoint == "checkpoint.wave_two", "moves through enter checkpoint fail retry and complete")
	var duplicate = dungeon.apply(state, "complete.1", "complete")
	test.expect(duplicate.ok and duplicate.duplicate and not dungeon.apply(state, "retry.2", "retry").ok, "deduplicates events and rejects invalid transitions")
	test.finish(self, "dungeon_state")
