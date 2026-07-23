extends Reference

var active_npc_id = ""

func begin(npc_id: String) -> bool:
	if npc_id.empty() or not active_npc_id.empty(): return false
	active_npc_id = npc_id
	return true

func release(npc_id: String) -> bool:
	if npc_id.empty() or active_npc_id != npc_id: return false
	active_npc_id = ""
	return true

func blocked() -> bool:
	return not active_npc_id.empty()
