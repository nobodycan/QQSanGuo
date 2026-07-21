extends Reference

const ICON_ROOT = "res://UI/item_icons/"
const FALLBACK_ICON_PATH = ICON_ROOT + "铁剑.png"

static func resolve_path(item_name):
	var candidate_path = ICON_ROOT + str(item_name) + ".png"
	if ResourceLoader.exists(candidate_path):
		return candidate_path
	return FALLBACK_ICON_PATH
