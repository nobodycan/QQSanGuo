extends SceneTree

const LootTable = preload("res://actors/LootTable.gd")
const TestProtocol = preload("res://tests/TestProtocol.gd")

func _init():
	var test = TestProtocol.new()
	var table = {"entries": [{"item_id": "item.quest", "min_quantity": 1, "max_quantity": 1, "chance_bps": 0, "guaranteed": true}, {"item_id": "item.rare", "min_quantity": 1, "max_quantity": 3, "chance_bps": 5000, "requires": ["boss"]}]}
	var loot = LootTable.new()
	var first = loot.resolve(table, 7, {"boss": true})
	test.expect(first.size() >= 1 and first[0].item_id == "item.quest", "always emits guaranteed drops")
	test.expect(to_json(first) == to_json(loot.resolve(table, 7, {"boss": true})), "repeats exact loot for a fixed seed")
	test.expect(loot.resolve(table, 7, {}).size() == 1, "rejects conditional drops without required flags")
	test.expect(loot.resolve({"entries": [{"item_id": "bad", "min_quantity": 0, "max_quantity": 1, "chance_bps": 1}]}, 1).empty(), "rejects malformed entries")
	test.finish(self, "loot_table")
