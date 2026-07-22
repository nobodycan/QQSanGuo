extends SceneTree

const HitResolver = preload("res://actors/HitResolver.gd")
const TestProtocol = preload("res://tests/TestProtocol.gd")

func _init():
	var test = TestProtocol.new()
	var resolver = HitResolver.new()
	var player = {"id": "player", "faction": "player"}
	var enemy = {"id": "enemy", "faction": "enemy"}
	test.expect(resolver.resolve("hit.1", player, enemy).ok, "hostile target resolves")
	test.expect(not resolver.resolve("hit.1", player, enemy).ok, "duplicate hit resolves once")
	test.expect(resolver.resolve("hit.2", player, player).error == "invalid_target", "self target is rejected")
	test.expect(resolver.resolve("hit.3", player, {"id": "ally", "faction": "player"}).error == "friendly_target", "friendly target is rejected")
	test.finish(self, "hit_resolver")
