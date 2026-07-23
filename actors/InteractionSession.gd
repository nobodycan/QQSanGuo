extends Reference

const InteractionLock = preload("res://actors/InteractionLock.gd")

var lock = InteractionLock.new()

func open(npc_id: String) -> bool:
	return lock.begin(npc_id)

func close(npc_id: String) -> bool:
	return lock.release(npc_id)
