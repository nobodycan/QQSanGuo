extends SceneTree

const BossEncounterState = preload("res://actors/BossEncounterState.gd")
const TestProtocol = preload("res://tests/TestProtocol.gd")

func _init():
	var test = TestProtocol.new()
	var encounter = BossEncounterState.new()
	var state = encounter.new_state("boss.pilot", 3)
	state = encounter.apply(state, "start.1", "start").state
	state = encounter.apply(state, "phase.1", "next_phase").state
	state = encounter.apply(state, "phase.2", "next_phase").state
	state = encounter.apply(state, "defeat.1", "defeat").state
	test.expect(state.status == BossEncounterState.DEFEATED and state.phase == 2, "tracks ordered boss phases through defeat")
	var duplicate = encounter.apply(state, "defeat.1", "defeat")
	var reset = encounter.apply(state, "reset.1", "reset")
	test.expect(duplicate.ok and duplicate.duplicate and reset.ok and reset.state.status == BossEncounterState.IDLE and reset.state.phase == 0, "deduplicates defeat and resets completed encounters")
	test.finish(self, "boss_encounter_state")
