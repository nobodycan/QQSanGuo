
## 技能工厂
extends Node


## 技能属性
const SkillsProperty = preload("res://system/skill/SkillsProperty.gd")
## 技能场景文件
#const ScnSkills = preload("res://Skill.tscn")
## 技能属性列表
const SkillsPropertyList = SkillsProperty.SkillsProperty

# 存放技能图片的文件夹（这里我创建了这些路径）
const GoodsPicturePath = "res://assets/texture/skills/"


## 技能数据
var skill_data = {}
var file = File.new()

#------------------------------
#  节点带有的方法
#------------------------------
func _ready():
	# Registry is the runtime authority; the JSON file remains a cold-start fallback.
	call_deferred("_load_runtime_data")


func _load_runtime_data() -> void:
	var registry = get_node_or_null("/root/ContentRegistry")
	if registry != null and reload_from_registry(registry):
		return
	_load_legacy_json()


func reload_from_registry(registry: Node) -> bool:
	if registry == null or not registry.has_method("entries_of_kind"):
		return false
	var entries = registry.entries_of_kind("skill")
	if typeof(entries) != TYPE_ARRAY or entries.empty():
		return false
	var resolved = {}
	for entry in entries:
		if typeof(entry) != TYPE_DICTIONARY:
			return false
		var legacy_name = str(entry.get("legacy_name", ""))
		if legacy_name.empty():
			return false
		resolved[legacy_name] = {
			"skill_name": legacy_name,
			"need_level": int(entry.get("legacy_need_level", entry.get("unlock_level", 0))),
			"damage": int(entry.get("damage", 0)),
			"attack_range": int(entry.get("attack_range", 0)),
			"description": entry.get("description", ""),
			"consume": int(entry.get("legacy_consume", entry.get("magic_cost", 0))),
			"state": entry.get("legacy_state", null),
			"time": entry.get("legacy_duration", null)
		}
	skill_data = resolved
	return true


func _load_legacy_json() -> void:
	## 获取技能json数据
	file = File.new()
	if file.open("res://Data/skill.json", File.READ) != OK:
		skill_data = {}
		return
	var skill_json = JSON.parse(file.get_as_text())
	file.close()
	skill_data = skill_json.result if skill_json.error == OK and typeof(skill_json.result) == TYPE_DICTIONARY else {}



#------------------------------
#  自定义方法
#------------------------------
## 返回一个物品
## @goods_name 物品名称
## @return 返回一个物品的节点
#func get_skills(skill_name: String):
#	if skill_data.has(skill_name):
#		var data = get_skills_data(skill_name)	# 物品数据
#		var res_property = create_skill_property(data)
#
#		## 设置物品属性资源的属性数据
#		res_property.set_property(data)
#
#		## 返回物品节点
#		var goods = ScnSkills.instance()
#		goods.set_goods_property(res_property)	# 设置物品属性
#		return goods
#	else:
#		print_debug("没有【%s】这个技能" % skill_name)
#		return null



## 返回物品数据
## --------------
## 做这个方法的原因是因为，数据的属性可能与文件的属性数据不一致的问题
## 我们在这里将数据转为 符合物品属性数据格式 的数据
func get_skills_data(skill_name: String):
	if not skill_data.has(skill_name):
		return {}
	var data = skill_data[skill_name]	# 物品数据
	var temp = {}
	
	# 设置资源的格式：变量[属性名] = 属性值
	temp[SkillsPropertyList.Name] = data.get('skill_name', skill_name)
	temp[SkillsPropertyList.Damage] = int(data['damage'])
	temp[SkillsPropertyList.NeedLevel] = int(data['need_level'])
	temp[SkillsPropertyList.AttackRange] = int(data['attack_range'])
	temp[SkillsPropertyList.Description] = data['description']
	temp[SkillsPropertyList.Consume] = int(data['consume'])
	temp[SkillsPropertyList.State] = data['state']
	temp[SkillsPropertyList.Time] = int(data['time'])
	#temp[SkillsPropertyList.Texture] = get_goods_texture(data['Picture'])
	return temp


## 获取物品图片
## @picture_name 物品图片名称
## @return 返回物品的图片

func get_goods_texture(picture_name: String) -> Texture:
	var path = GoodsPicturePath + picture_name + ".png"	# 物品图片路径
	
	# 如果存在图片，则返回图片
	if file.file_exists(path):
		return load(path) as Texture
	# 如果不存在，则返回默认的 icon 图片
	else:
		return load("res://69896-1.png") as Texture

