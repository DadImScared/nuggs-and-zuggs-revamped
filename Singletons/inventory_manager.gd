extends Node

var max_equipped_size = 6
var max_inventory = 6
var storage: Array = [
	#preload("res://Resources/ketchup.tres")
]
var equipped: Array = [
	preload("res://Resources/ranch.tres"),
	#preload("res://Resources/bbq_sauce.tres"),
	#preload("res://Resources/ketchup.tres"),
	#preload("res://Resources/hot_sauce.tres")
]

signal sauce_moved(from_data, to_data)
signal sauce_equipped(sauce: BaseSauceResource)

func _ready() -> void:
	storage.resize(max_inventory)
	equipped.resize(max_equipped_size)

func move_sauce(from_data, to_data):
	var from = get_storage_data(from_data["slot_type"])
	var to = get_storage_data(to_data["slot_type"])
		# Get what's currently in each slot
	var from_item = from[from_data["slot_index"]]
	var to_item = to[to_data["slot_index"]]
	from[from_data["slot_index"]] = to_item
	to[to_data["slot_index"]] = from_item
	emit_signal("sauce_moved", from_data, to_data)


func get_storage_data(location):
	if location == "equipped":
		return equipped
	else:
		return storage

func is_inventory_full():
	return equipped.find(null) == -1

func can_equip_sauce():
	return equipped.size() < 6

func can_store_sauce():
	return storage.size() < 6

func select_sauce(sauce: BaseSauceResource):
	if is_inventory_full():
		print("full inventory")
		storage.append(sauce)
	else:
		var first_null_index = equipped.find(null)
		equipped[first_null_index] = sauce
		sauce_equipped.emit(sauce)
