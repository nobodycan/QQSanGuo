extends Node

var session_instance_id = 0

func _ready():
	session_instance_id = get_instance_id()

func lifecycle_snapshot() -> Dictionary:
	return {
		"game_root_id": session_instance_id,
		"world_children": $WorldRoot.get_child_count(),
		"player_children": $PlayerRoot.get_child_count(),
		"ui_children": $UIRoot.get_child_count()
	}
