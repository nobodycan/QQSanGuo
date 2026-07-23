extends SceneTree

const BossPhasePolicy = preload("res://actors/BossPhasePolicy.gd")
const TestProtocol = preload("res://tests/TestProtocol.gd")

func _init():
	var test = TestProtocol.new()
	var policy = BossPhasePolicy.new()
	var definition = policy.normalize({"boss_id":"boss.pilot","thresholds_bps":[7000,4000]})
	test.expect(not definition.empty() and policy.phase(definition, 10000) == 0 and policy.phase(definition, 7000) == 1 and policy.phase(definition, 4000) == 2, "resolves phase thresholds inclusively")
	test.expect(policy.normalize({"boss_id":"boss.bad","thresholds_bps":[4000,7000]}).empty() and policy.phase(definition, -1) == -1, "rejects unordered thresholds and invalid health")
	test.finish(self, "boss_phase_policy")
