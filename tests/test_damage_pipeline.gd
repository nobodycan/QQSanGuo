extends SceneTree

const DamagePipeline = preload("res://actors/DamagePipeline.gd")
const TestProtocol = preload("res://tests/TestProtocol.gd")

func _init():
	var test = TestProtocol.new()
	var pipeline = DamagePipeline.new()
	var normal = pipeline.resolve({"base_damage": 20, "defense": 5, "multiplier": 1.0})
	test.expect(normal.ok and normal.damage == 15 and not normal.critical, "applies defense after multiplier")
	var critical = pipeline.resolve({"base_damage": 20, "defense": 5, "multiplier": 1.2, "critical": true, "critical_multiplier": 1.5})
	test.expect(critical.damage == 31 and critical.critical, "applies critical before defense")
	test.expect(pipeline.resolve({"base_damage": 1, "defense": 99}).damage == 0, "damage never becomes negative")
	test.expect(not pipeline.resolve({"base_damage": -1, "defense": 0}).ok, "rejects invalid base damage")
	test.expect(not pipeline.resolve({"base_damage": 1, "defense": 0, "multiplier": INF}).ok, "rejects non finite multiplier")
	test.finish(self, "damage_pipeline")
