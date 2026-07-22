extends SceneTree

const WalletState = preload("res://actors/WalletState.gd")
const InventoryState = preload("res://actors/InventoryState.gd")
const EquipmentState = preload("res://actors/EquipmentState.gd")
const EnhancementTransaction = preload("res://actors/EnhancementTransaction.gd")
const TestProtocol = preload("res://tests/TestProtocol.gd")

func _init():
	var test = TestProtocol.new()
	var wallet = WalletState.new().apply(WalletState.new().new_state(), "seed", 100, 0).state
	var inventory = InventoryState.new().new_state()
	inventory.slots = [{"template_id": "material.enhance.low", "quantity": 2}]
	inventory = InventoryState.new().normalize(inventory)
	var equipment = EquipmentState.new().new_state()
	equipment.slots.Sword = {"instance_id": "sword.1", "slot": "Sword", "job": "js", "level": 1, "modifiers": {"basic_damage": 25}, "enhancement_level": 0}
	var result = EnhancementTransaction.new().apply(wallet, inventory, equipment, "enhance.sword.1", "Sword", {"money": 10, "material_id": "material.enhance.low", "material_quantity": 1})
	test.expect(result.ok and result.wallet.money == 90 and result.inventory.slots[0].quantity == 1 and result.equipment.slots.Sword.enhancement_level == 1, "commits money material and enhancement together")
	var duplicate = EnhancementTransaction.new().apply(result.wallet, result.inventory, result.equipment, "enhance.sword.1", "Sword", {"money": 10, "material_id": "material.enhance.low", "material_quantity": 1})
	test.expect(duplicate.ok and duplicate.duplicate and duplicate.equipment.slots.Sword.enhancement_level == 1, "duplicate operation does not charge or enhance twice")
	var insufficient = EnhancementTransaction.new().apply(wallet, InventoryState.new().normalize(InventoryState.new().new_state()), equipment, "enhance.sword.2", "Sword", {"money": 10, "material_id": "material.enhance.low", "material_quantity": 1})
	test.expect(not insufficient.ok and insufficient.wallet.money == 100 and insufficient.equipment.slots.Sword.enhancement_level == 0, "missing material leaves every state unchanged")
	test.finish(self, "enhancement_transaction")
