extends KinematicBody2D

const CombatAction = preload("res://actors/CombatAction.gd")
const Vitals = preload("res://actors/Vitals.gd")

export var damage = 20
export var hp = 100
export var speed = 20
var now_hp = hp

var state_machine
var player
var velocity
var be_attack = false

var combat = false

var itemDrop = preload("res://ItemDrop.tscn")
var state = ""
var boss_behavior
var vitals_model = Vitals.new()
var vitals_state = {}
var combat_action = CombatAction.new()
var combat_hit_sequence = 0


func _ready():
	state_machine = $AnimationTree.get("parameters/playback")
	init()
	
func init():
	print("进入初始状态")
	$HealthBar/HealthBar.value = hp
	vitals_state = vitals_model.new_state(hp, 0)
	vitals_state.health = clamp(now_hp, 0, vitals_state.max_health)
	now_hp = vitals_state.health
	state_machine.travel("idle")
	be_attack = false
	combat = false
	
func _process(delta):
	velocity = Vector2(0, 0)
	if player and be_attack:
		if player.position.x > position.x:
			$AnimatedSprite.flip_h = false
		else:
			$AnimatedSprite.flip_h = true
		move_to_player(delta)
		if velocity == Vector2(0, 0):
			if be_attack == true:
				if combat == false:
					combat = true
					$combat_timer.start()
					state_machine.travel("idle_attack")
			else:
				state_machine.travel("idle")
		
func choose(array):
	array.shuffle()
	return array.front()

#func _on_Timer_timeout():
#	$Timer.wait_time = choose([1]) #0.5 1 1.5
#	if state == "combat":
#		state = choose([attack(), ])
		


func Drop():
	##死后有概率掉落物品
	#if randi()%2:
		
	var item = itemDrop.instance()
	item.position = position
	get_parent().add_child(item)

func move_to_player(delta):
	
	var dist = player.position.x - position.x
	if abs(dist) <= 100:
		velocity = Vector2(0, 0)
#	print(dist)
	else:
		velocity.x = player.position.x - position.x
		velocity.y = 0
	if velocity != Vector2(0, 0):
		state_machine.travel("move")
		velocity = move_and_slide(velocity)
	else:
		print("这段时间我也不知道干嘛")
		if $combat_timer.time_left > 1.3:
			state_machine.travel("idle_attack")
		elif now_hp > 0 and state != "die":
			state_machine.travel("attack1")


func injury(num, crit=false):
	be_attack = true
	combat_hit_sequence += 1
	var action = {"id": "legacy.player_to_boss." + str(combat_hit_sequence), "attacker": {"id": "player", "faction": "player"}, "defender": {"id": "boss.dengmao", "faction": "boss"}, "damage": {"base_damage": abs(int(num)), "defense": 0, "critical": crit, "critical_multiplier": 1.5}}
	var result = combat_action.resolve(action, vitals_state)
	if not result.ok:
		return result
	vitals_state = result.vitals
	now_hp = vitals_state.health
	if num < 0:
		$HealthBar/HealthBar.value = int((now_hp*1.0/hp)*100)
		$FCTmgr.show_value(num, crit)
		state_machine.travel("injury")
		state = "combat"
	if not vitals_state.alive:
		die()
	return result

func die():
	var num = int(rand_range(2, 7))
	if player:
		player.temp_enemy = null
	for i in num:
		Drop()
	state_machine.travel("die")
	state = "die"
	set_process(false)
	get_parent().get_node("Steve").gain_money(10000, 1000)
	get_parent().get_node("Steve").gain_experience(10000)

func attack():
	if player and velocity == Vector2(0, 0):
#		print("攻击")
		state_machine.travel("attack1")

func dengmao_hit():
	player.dengmao_hit()
		
func attack_damage():
	if player:
		var num = int(rand_range(1, 4))
		for i in num:
				var crit = rand_range(0, 1)
				var temp_damage = damage
				if crit < 0.5:
					temp_damage *= rand_range(1.2, 2)
					player.injury(-int(temp_damage), true)
					var offset = Vector2()
					offset.x = rand_range(-15, 15)
					offset.y = rand_range(-15, 15)
					var newpos = get_parent().get_node("Steve/Camera2D").get_position()
					var oldpos = newpos
					newpos += offset
					get_parent().get_node("Steve/Camera2D").set_position(newpos)
					yield(get_tree().create_timer(0.18),"timeout")
					get_parent().get_node("Steve/Camera2D").set_position(oldpos)
					yield(get_tree().create_timer(0.18),"timeout")
				else:
					player.injury(-int(temp_damage))

func _on_player_detect_body_entered(body):
	print("玩家进入")
	if body.name == "Steve":
		player = body


func _on_player_detect_body_exited(body):
	print("玩家退出")
	player = null
#	$normal_timer.start(5)


func _on_combat_timer_timeout():
	pass



func _on_normal_timer_timeout():
	init()
