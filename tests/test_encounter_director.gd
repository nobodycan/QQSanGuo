extends SceneTree

const EncounterDirector = preload("res://actors/EncounterDirector.gd")
const TestProtocol = preload("res://tests/TestProtocol.gd")

func _init():
	var test = TestProtocol.new()
	var director = EncounterDirector.new()
	var run = director.new_run("dungeon", "dungeon.pilot", "run.1")
	run = director.apply(run, "start.1", "start").state
	run = director.apply(run, "attach.1", "attach", "actor.snake.1").state
	run = director.apply(run, "victory.1", "victory").state
	run = director.apply(run, "cleanup.1", "cleanup").state
	test.expect(run.status == EncounterDirector.CLEANED and run.resources.empty(), "cleans all encounter-owned resources after victory")
	var duplicate = director.apply(run, "cleanup.1", "cleanup")
	test.expect(duplicate.ok and duplicate.duplicate, "deduplicates delayed lifecycle callbacks")
	var prepared = director.new_run("boss", "boss.pilot", "run.2")
	test.expect(not director.apply(prepared, "victory.2", "victory").ok and not director.apply(prepared, "attach.2", "attach", "actor.1").ok, "rejects terminal and scoped actions before a run starts")
	test.finish(self, "encounter_director")
