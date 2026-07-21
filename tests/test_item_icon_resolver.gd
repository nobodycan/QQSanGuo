extends SceneTree

const ItemIconResolver = preload("res://ItemIconResolver.gd")

func _init():
	var file = File.new()
	assert(file.open("res://Data/itemData.json", File.READ) == OK)
	var parsed = JSON.parse(file.get_as_text())
	file.close()
	assert(parsed.error == OK)
	assert(parsed.result.has("龙泉剑"))
	assert(parsed.result.has("铁剑"))

	assert(ResourceLoader.exists("res://UI/item_icons/铁剑.png"))
	assert(!ResourceLoader.exists("res://UI/item_icons/龙泉剑.png"))
	assert(ItemIconResolver.resolve_path("龙泉剑") == "res://UI/item_icons/铁剑.png")
	assert(ItemIconResolver.resolve_path("铁剑") == "res://UI/item_icons/铁剑.png")
	print("TEST_ITEM_ICON_RESOLVER_PASS")
	quit()
