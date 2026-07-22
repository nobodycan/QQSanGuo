extends SceneTree

const WalletState = preload("res://actors/WalletState.gd")
const TestProtocol = preload("res://tests/TestProtocol.gd")

func _init():
	var test = TestProtocol.new()
	var wallet = WalletState.new()
	var credit = wallet.apply(wallet.new_state(), "reward.snake.1", 100, 10)
	test.expect(credit.ok and not credit.duplicate and credit.state.money == 100 and credit.state.juntuan == 10, "credits a new atomic wallet operation")
	var repeated = wallet.apply(credit.state, "reward.snake.1", 100, 10)
	test.expect(repeated.ok and repeated.duplicate and repeated.state.money == 100 and repeated.state.juntuan == 10, "repeated operation IDs do not double credit")
	var failed = wallet.apply(credit.state, "shop.buy.1", -101, 0)
	test.expect(not failed.ok and failed.state.money == 100 and failed.state.juntuan == 10, "insufficient balance rejects without mutation")
	var migrated = wallet.migrate_v0({"money": 8, "juntuan": 2})
	test.expect(migrated.version == 1 and wallet.migrate_v0(migrated).money == 8, "wallet v0 migration is idempotent")
	test.finish(self, "wallet_state")
