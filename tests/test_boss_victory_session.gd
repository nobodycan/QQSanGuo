extends SceneTree

const BossEncounterState = preload("res://actors/BossEncounterState.gd")
const BossVictorySession = preload("res://actors/BossVictorySession.gd")
const EncounterDirector = preload("res://actors/EncounterDirector.gd")
const InventoryState = preload("res://actors/InventoryState.gd")
const TestProtocol = preload("res://tests/TestProtocol.gd")
const WalletState = preload("res://actors/WalletState.gd")
const WorldState = preload("res://actors/WorldState.gd")

func _init():
	var test = TestProtocol.new()
	var encounter = BossEncounterState.new().new_state("boss.pilot", 2)
	encounter = BossEncounterState.new().apply(encounter, "start.1", "start").state
	var run = EncounterDirector.new().new_run("boss", "boss.pilot", "run.1")
	run = EncounterDirector.new().apply(run, "run.start.1", "start").state
	var wallet = WalletState.new().new_state()
	var inventory = InventoryState.new().normalize(InventoryState.new().new_state())
	var session = BossVictorySession.new()
	var won = session.victory(encounter, run, WorldState.new().new_state(), wallet, inventory, "victory.1", 250, [])
	test.expect(won.ok and won.encounter.status == BossEncounterState.DEFEATED and won.run.status == EncounterDirector.VICTORY and won.wallet.money == 250 and won.world.defeated_bosses.has("boss.pilot"), "commits victory scope, reward, and world progress together")
	var replay = session.victory(won.encounter, won.run, won.world, won.wallet, won.inventory, "victory.1", 250, [])
	test.expect(replay.ok and replay.duplicate and replay.wallet.money == 250, "deduplicates delayed boss victory callbacks")
	var inactive_run = EncounterDirector.new().new_run("boss", "boss.pilot", "run.2")
	var blocked = session.victory(encounter, inactive_run, WorldState.new().new_state(), wallet, inventory, "victory.2", 250, [])
	test.expect(not blocked.ok and blocked.encounter.status == BossEncounterState.ACTIVE and blocked.run.status == EncounterDirector.PREPARED, "rejects victory when the encounter scope was not started")
	test.finish(self, "boss_victory_session")
