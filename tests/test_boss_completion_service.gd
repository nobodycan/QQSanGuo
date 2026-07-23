extends SceneTree

const BossCompletionService = preload("res://actors/BossCompletionService.gd")
const BossEncounterState = preload("res://actors/BossEncounterState.gd")
const InventoryState = preload("res://actors/InventoryState.gd")
const TestProtocol = preload("res://tests/TestProtocol.gd")
const WalletState = preload("res://actors/WalletState.gd")
const WorldState = preload("res://actors/WorldState.gd")

func _init():
	var test = TestProtocol.new()
	var encounter = BossEncounterState.new().new_state("boss.pilot", 2)
	encounter = BossEncounterState.new().apply(encounter, "start", "start").state
	var service = BossCompletionService.new()
	var completed = service.defeat(encounter, WorldState.new().new_state(), WalletState.new().new_state(), InventoryState.new().normalize(InventoryState.new().new_state()), "defeat.1", 250, [])
	test.expect(completed.ok and completed.encounter.status == BossEncounterState.DEFEATED and completed.wallet.money == 250 and completed.world.defeated_bosses.has("boss.pilot"), "defeat grants reward and records world boss progress")
	var duplicate = service.defeat(completed.encounter, completed.world, completed.wallet, completed.inventory, "defeat.1", 250, [])
	test.expect(duplicate.ok and duplicate.duplicate and duplicate.wallet.money == 250, "deduplicates repeated boss defeat")
	test.finish(self, "boss_completion_service")
