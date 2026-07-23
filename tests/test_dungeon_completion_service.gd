extends SceneTree

const DungeonCompletionService = preload("res://actors/DungeonCompletionService.gd")
const DungeonState = preload("res://actors/DungeonState.gd")
const InventoryState = preload("res://actors/InventoryState.gd")
const TestProtocol = preload("res://tests/TestProtocol.gd")
const WalletState = preload("res://actors/WalletState.gd")
const WorldState = preload("res://actors/WorldState.gd")

func _init():
	var test = TestProtocol.new()
	var dungeon = DungeonState.new().new_state("dungeon.pilot")
	dungeon = DungeonState.new().apply(dungeon, "enter", "enter").state
	var world = WorldState.new().new_state()
	var wallet = WalletState.new().new_state()
	var inventory = InventoryState.new().normalize(InventoryState.new().new_state())
	var service = DungeonCompletionService.new()
	var completed = service.complete(dungeon, world, wallet, inventory, "complete.1", 100, [])
	test.expect(completed.ok and completed.dungeon.status == DungeonState.COMPLETED and completed.wallet.money == 100 and completed.world.flags.has("dungeon.completed.dungeon.pilot"), "completes a dungeon with reward and world flag")
	var duplicate = service.complete(completed.dungeon, completed.world, completed.wallet, completed.inventory, "complete.1", 100, [])
	test.expect(duplicate.ok and duplicate.duplicate and duplicate.wallet.money == 100, "deduplicates repeated dungeon completion")
	test.finish(self, "dungeon_completion_service")
