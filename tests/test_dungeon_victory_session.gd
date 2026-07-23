extends SceneTree

const DungeonState = preload("res://actors/DungeonState.gd")
const DungeonVictorySession = preload("res://actors/DungeonVictorySession.gd")
const EncounterDirector = preload("res://actors/EncounterDirector.gd")
const InventoryState = preload("res://actors/InventoryState.gd")
const TestProtocol = preload("res://tests/TestProtocol.gd")
const WalletState = preload("res://actors/WalletState.gd")
const WorldState = preload("res://actors/WorldState.gd")

func _init():
	var test = TestProtocol.new()
	var dungeon = DungeonState.new().new_state("dungeon.pilot")
	dungeon = DungeonState.new().apply(dungeon, "enter.1", "enter").state
	var run = EncounterDirector.new().new_run("dungeon", "dungeon.pilot", "run.1")
	run = EncounterDirector.new().apply(run, "run.start.1", "start").state
	var wallet = WalletState.new().new_state()
	var inventory = InventoryState.new().normalize(InventoryState.new().new_state())
	var session = DungeonVictorySession.new()
	var won = session.victory(dungeon, run, WorldState.new().new_state(), wallet, inventory, "victory.1", 100, [])
	test.expect(won.ok and won.dungeon.status == DungeonState.COMPLETED and won.run.status == EncounterDirector.VICTORY and won.wallet.money == 100, "commits dungeon completion and encounter victory together")
	var replay = session.victory(won.dungeon, won.run, won.world, won.wallet, won.inventory, "victory.1", 100, [])
	test.expect(replay.ok and replay.duplicate and replay.wallet.money == 100, "deduplicates delayed dungeon victory callbacks")
	var inactive_run = EncounterDirector.new().new_run("dungeon", "dungeon.pilot", "run.2")
	var blocked = session.victory(dungeon, inactive_run, WorldState.new().new_state(), wallet, inventory, "victory.2", 100, [])
	test.expect(not blocked.ok and blocked.dungeon.status == DungeonState.ACTIVE and blocked.run.status == EncounterDirector.PREPARED, "rejects victory when the dungeon scope was not started")
	test.finish(self, "dungeon_victory_session")
