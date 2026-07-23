extends SceneTree

const DungeonCheckpointService = preload("res://actors/DungeonCheckpointService.gd")
const DungeonState = preload("res://actors/DungeonState.gd")
const TestProtocol = preload("res://tests/TestProtocol.gd")
const WorldState = preload("res://actors/WorldState.gd")

func _init():
	var test = TestProtocol.new()
	var dungeon = DungeonState.new().new_state("dungeon.pilot")
	dungeon = DungeonState.new().apply(dungeon, "enter.1", "enter").state
	var world = WorldState.new().new_state()
	var service = DungeonCheckpointService.new()
	var reached = service.reach(dungeon, world, "checkpoint.1", "wave.two")
	test.expect(reached.ok and reached.dungeon.checkpoint == "wave.two" and reached.world.checkpoint == "dungeon.pilot:wave.two", "persists the active dungeon checkpoint in both state boundaries")
	var replay = service.reach(reached.dungeon, reached.world, "checkpoint.1", "different")
	test.expect(replay.ok and replay.duplicate and replay.dungeon.checkpoint == "wave.two" and replay.world.checkpoint == "dungeon.pilot:wave.two", "deduplicates checkpoint events without overwriting progress")
	var idle = DungeonState.new().new_state("dungeon.pilot")
	var blocked = service.reach(idle, world, "checkpoint.2", "wave.two")
	test.expect(not blocked.ok and blocked.dungeon.status == DungeonState.IDLE and blocked.world.checkpoint.empty(), "rejects checkpoints outside an active dungeon")
	test.finish(self, "dungeon_checkpoint_service")
