extends SceneTree

const LegacyWalletBridge = preload("res://actors/LegacyWalletBridge.gd")
const TestProtocol = preload("res://tests/TestProtocol.gd")

func _init():
	var test = TestProtocol.new()
	var bridge = LegacyWalletBridge.new()
	test.expect(bridge.import_legacy(50, 2), "imports legacy balances into wallet state")
	test.expect(bridge.apply("reward.snake.1", 100, 10).ok and bridge.project_legacy().money == 150 and bridge.project_legacy().juntuan == 12, "projects wallet rewards back to legacy balances")
	test.expect(bridge.apply("reward.snake.1", 100, 10).duplicate and bridge.project_legacy().money == 150, "legacy bridge preserves idempotent operation ledger")
	test.expect(not bridge.apply("shop.buy.1", -151, 0).ok and bridge.project_legacy().money == 150, "legacy bridge rejects overdrafts without mutation")
	test.finish(self, "legacy_wallet_bridge")
