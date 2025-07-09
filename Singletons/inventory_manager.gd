extends Node

var max_equipped_size = 6
var max_inventory = 6
var storage: Array = [
	#preload("res://Resources/ketchup.tres")
]
var equipped: Array = [
	preload("res://Resources/prehistoric_pesto.tres")
	#preload("res://Resources/mesozoic_miracle_whip.tres")
	#preload("res://Resources/quantom_queso.tres")
	#preload("res://Resources/balsamic_vinegar.tres")
	#preload("res://Resources/worcestershire.tres")
	#preload("res://Resources/sriracha.tres")
	#preload("res://Resources/mustard.tres")
	#preload("res://Resources/ranch.tres"),
	#preload("res://Resources/bbq_sauce.tres"),
	#preload("res://Resources/ketchup.tres"),
	#preload("res://Resources/hot_sauce.tres")
]

signal sauce_moved(from_data, to_data)
signal sauce_equipped(sauce: BaseSauceResource)
signal sauce_unequipped(sauce: BaseSauceResource)

func _ready() -> void:
	storage.resize(max_inventory)
	equipped.resize(max_equipped_size)

func move_sauce(from_data, to_data):
	var from = get_storage_data(from_data["slot_type"])
	var to = get_storage_data(to_data["slot_type"])

	# Get what's currently in each slot
	var from_item = from[from_data["slot_index"]]
	var to_item = to[to_data["slot_index"]]

	# Emit unequipped signals for bottles leaving equipped slots
	if from_data["slot_type"] == "equipped" and from_item != null:
		sauce_unequipped.emit(from_item)
	if to_data["slot_type"] == "equipped" and to_item != null:
		sauce_unequipped.emit(to_item)

	# Move the sauce resources
	from[from_data["slot_index"]] = to_item
	to[to_data["slot_index"]] = from_item

	# Emit equipped signals for bottles moving to equipped slots
	if to_data["slot_type"] == "equipped" and from_item != null:
		sauce_equipped.emit(from_item)
	if from_data["slot_type"] == "equipped" and to_item != null:
		sauce_equipped.emit(to_item)

	emit_signal("sauce_moved", from_data, to_data)

func get_storage_data(location):
	if location == "equipped":
		return equipped
	else:
		return storage

func get_equipped_sauces() -> Array:
	var active_sauces = []
	for sauce in equipped:
		if sauce != null:
			active_sauces.append(sauce)
	return active_sauces

func apply_upgrade_to_sauce(sauce_resource: BaseSauceResource, choice_number: int):
	var sauce_name = sauce_resource.sauce_name
	print("Applying upgrade choice %d to %s resource" % [choice_number, sauce_name])

	# Apply the upgrade directly to the sauce resource
	match sauce_name:
		"Ketchup":
			_apply_ketchup_upgrade(sauce_resource, choice_number)
		"Prehistoric Pesto":
			_apply_pesto_upgrade(sauce_resource, choice_number)
		_:
			_apply_generic_upgrade(sauce_resource, choice_number)

func _apply_ketchup_upgrade(sauce_resource: BaseSauceResource, choice: int):
	match choice:
		1: # Thick & Chunky
			sauce_resource.damage += 5.0
			print("Applied Thick & Chunky: +5 damage to resource")
		2: # Double Squirt
			sauce_resource.projectile_count += 1
			print("Applied Double Squirt: +1 projectile to resource")
		3: # Fast Food
			sauce_resource.fire_rate += 0.3
			print("Applied Fast Food: +0.3 fire rate to resource")

func _apply_pesto_upgrade(sauce_resource: BaseSauceResource, choice: int):
	match choice:
		1: # Viral Load
			sauce_resource.effect_chance += 0.3
			print("Applied Viral Load: +30% effect chance to resource")
		2: # Rapid Mutation
			sauce_resource.fire_rate += 0.5
			print("Applied Rapid Mutation: +0.5 fire rate to resource")
		3: # Toxic Herbs
			sauce_resource.damage += 3.0
			sauce_resource.effect_intensity += 1.5
			print("Applied Toxic Herbs: +3 damage, +1.5 effect intensity to resource")

func _apply_generic_upgrade(sauce_resource: BaseSauceResource, choice: int):
	match choice:
		1: # More Damage
			sauce_resource.damage += 3.0
			print("Applied More Damage: +3 damage to resource")
		2: # Faster Shooting
			sauce_resource.fire_rate += 0.2
			print("Applied Faster Shooting: +0.2 fire rate to resource")
		3: # Longer Range
			sauce_resource.range += 20.0
			print("Applied Longer Range: +20 range to resource")

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
