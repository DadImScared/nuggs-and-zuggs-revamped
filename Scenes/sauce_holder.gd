extends Node2D

@export var weapon_radius: float = 12.0

func _ready():
	InventoryManager.sauce_moved.connect(_on_sauce_moved)
	InventoryManager.sauce_equipped.connect(_on_sauce_selected)
	for i in InventoryManager.equipped.size():
		var sauce_bottle = InventoryManager.equipped[i]
		if sauce_bottle:
			var item_data = ItemData.new()
			add_child(item_data.create_bottle(InventoryManager.equipped[i]))

	_position_weapons()

func _on_sauce_selected(sauce: BaseSauceResource):
	print("sauce selected")
	var item_data = ItemData.new()
	add_child(item_data.create_bottle(sauce))
	_position_weapons()

func _on_sauce_moved(from_data: SlotData, to_data: SlotData):
	if from_data.slot_type == "equipped":
		for child in get_children():
			if child.sauce_data == from_data.sauce_bottle:
				remove_child(child)
				break
		if to_data.sauce_bottle:
			var item_data = ItemData.new()
			add_child(item_data.create_bottle(to_data.sauce_bottle))
	if from_data.slot_type == "inventory":
		if to_data.sauce_bottle:
			for child in get_children():
				if child.sauce_data == to_data.sauce_bottle:
					remove_child(child)
					break
		var item_data = ItemData.new()
		add_child(item_data.create_bottle(from_data.sauce_bottle))
##	perform swap
	#if to_data.sauce_bottle:
		#var item_data = ItemData.new()
		#add_child(item_data.create_bottle(to_data.sauce_bottle))



	_position_weapons()


func _position_weapons():
	var weapons = get_children()
	for i in range(weapons.size()):
		var angle = (i * 2 * PI) / weapons.size()  # Divide circle into 6 equal parts
		var weapon_position = Vector2(
			cos(angle) * weapon_radius,
			sin(angle) * weapon_radius
		)
		weapons[i].position = weapon_position
