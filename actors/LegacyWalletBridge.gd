extends Reference

const WalletState = preload("res://actors/WalletState.gd")

var state = WalletState.new().new_state()

func import_legacy(money: int, juntuan: int) -> bool:
	state = WalletState.new().migrate_v0({"money": money, "juntuan": juntuan})
	return not state.empty()

func apply(operation_id: String, money_delta: int, juntuan_delta: int) -> Dictionary:
	var result = WalletState.new().apply(state, operation_id, money_delta, juntuan_delta)
	if result.ok:
		state = result.state
	return result

func project_legacy() -> Dictionary:
	return {"money": state.money, "juntuan": state.juntuan}
