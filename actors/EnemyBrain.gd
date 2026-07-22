extends Reference

const IDLE = "idle"
const CHASE = "chase"
const ATTACK = "attack"
const RETURN = "return"
const DEAD = "dead"

func next_state(current: String, has_target: bool, distance: float, aggro_range: float, attack_range: float, alive: bool) -> String:
	if not alive:
		return DEAD
	if not has_target:
		return RETURN if current == CHASE or current == ATTACK else IDLE
	if distance <= attack_range:
		return ATTACK
	if distance <= aggro_range:
		return CHASE
	return RETURN
