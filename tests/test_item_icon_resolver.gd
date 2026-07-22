extends SceneTree

const ItemIconResolver = preload("res://ItemIconResolver.gd")
const TestProtocol = preload("res://tests/TestProtocol.gd")

func _init():
	var file = File.new()
	var test = TestProtocol.new()
	test.expect(file.open("res://Data/itemData.json", File.READ) == OK, "opens item data")
	var parsed = JSON.parse(file.get_as_text())
	file.close()
	test.expect(parsed.error == OK, "parses item data")
	test.expect(parsed.error == OK and parsed.result.has("龙泉剑"), "has fallback item")
	test.expect(parsed.error == OK and parsed.result.has("铁剑"), "has fallback icon owner")
	test.expect(ResourceLoader.exists("res://UI/item_icons/铁剑.png"), "fallback icon exists")
	test.expect(!ResourceLoader.exists("res://UI/item_icons/龙泉剑.png"), "missing source icon stays absent")
	test.expect(ItemIconResolver.resolve_path("龙泉剑") == "res://UI/item_icons/铁剑.png", "resolves fallback icon")
	test.expect(ItemIconResolver.resolve_path("铁剑") == "res://UI/item_icons/铁剑.png", "resolves existing icon")
	test.finish(self, "item_icon_resolver")
