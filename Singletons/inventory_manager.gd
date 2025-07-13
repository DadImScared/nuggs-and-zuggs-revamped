# Singletons/inventory_manager.gd
extends Node

# Direct signals for UI
signal bottle_leveled_up(bottle_id: String, sauce_name: String, level: int)

var max_equipped_size = 6
var max_inventory = 6

# Both arrays now store bottle instances only
var storage: Array = []
var equipped: Array = []

# Legacy resources for initial setup only
var old_equipped: Array = [
	preload("res://Resources/prehistoric_pesto.tres"),
	preload("res://Resources/prehistoric_pesto.tres")
]

var scene_holder_node: Node2D

signal sauce_moved(from_data, to_data)
signal sauce_equipped(bottle_instance: ImprovedBaseSauceBottle)
signal sauce_unequipped(bottle_instance: ImprovedBaseSauceBottle)

func _ready() -> void:
	storage.resize(max_inventory)
	equipped.resize(max_equipped_size)
	print("InventoryManager initialized with bottle instance storage only")

func register_scene_node(scene_node: Node2D):
	scene_holder_node = scene_node
	print("InventoryManager: Scene node registered")

# BOTTLE INSTANCE MANAGEMENT
func create_bottle_for_sauce(sauce_resource: BaseSauceResource) -> ImprovedBaseSauceBottle:
	var item_data = ItemData.new()
	var bottle = item_data.create_bottle(sauce_resource)

	if not bottle:
		print("❌ Failed to create bottle instance!")
		return null

	# Connect bottle level up signal
	if bottle.has_signal("leveled_up"):
		bottle.leveled_up.connect(_on_bottle_leveled_up)

	print("✅ Created bottle for: %s" % sauce_resource.sauce_name)
	return bottle

func add_bottle_to_scene(bottle: ImprovedBaseSauceBottle):
	"""Add bottle to scene when equipped"""
	if scene_holder_node and bottle:
		scene_holder_node.add_child(bottle)
		_position_weapons()

func remove_bottle_from_scene(bottle: ImprovedBaseSauceBottle):
	"""Remove bottle from scene when unequipped"""
	if scene_holder_node and bottle and bottle.get_parent() == scene_holder_node:
		scene_holder_node.remove_child(bottle)
		_position_weapons()

func destroy_bottle(bottle: ImprovedBaseSauceBottle):
	"""Completely destroy a bottle instance"""
	if not bottle:
		return

	# Disconnect signal
	if bottle.has_signal("leveled_up"):
		bottle.leveled_up.disconnect(_on_bottle_leveled_up)

	# Remove from scene if present
	remove_bottle_from_scene(bottle)

	# Queue for deletion
	bottle.queue_free()
	print("🗑️ Destroyed bottle: %s" % bottle.sauce_data.sauce_name)

# SIGNAL HANDLING
func _on_bottle_leveled_up(bottle_id: String, level: int, sauce_name: String):
	print("InventoryManager: %s leveled up to %d" % [sauce_name, level])
	bottle_leveled_up.emit(bottle_id, sauce_name, level)

# BOTTLE LOOKUP
func get_bottle_by_id(bottle_id: String) -> ImprovedBaseSauceBottle:
	# Search in equipped first
	for bottle in equipped:
		if bottle and bottle.bottle_id == bottle_id:
			return bottle

	# Search in storage
	for bottle in storage:
		if bottle and bottle.bottle_id == bottle_id:
			return bottle

	return null

# POSITIONING
func _position_weapons():
	if not scene_holder_node:
		return

	# Only position bottles that are actually in the scene (equipped)
	var equipped_bottles = []
	for bottle in equipped:
		if is_instance_valid(bottle) and bottle.get_parent() == scene_holder_node:
			equipped_bottles.append(bottle)

	var bottle_count = equipped_bottles.size()
	if bottle_count == 0:
		return

	var angle_step = TAU / bottle_count
	for i in range(bottle_count):
		var bottle = equipped_bottles[i]
		var angle = i * angle_step
		var offset = Vector2(cos(angle), sin(angle)) * 24.0
		bottle.position = offset

# INVENTORY MANAGEMENT - Now handles instances properly
func move_sauce(from_data, to_data):
	var from = get_storage_data(from_data["slot_type"])
	var to = get_storage_data(to_data["slot_type"])

	# Get what's currently in each slot (both are bottle instances now)
	var from_item = from[from_data["slot_index"]]
	var to_item = to[to_data["slot_index"]]

	# Handle scene management when moving between equipped and storage
	if from_data["slot_type"] == "equipped" and from_item != null:
		remove_bottle_from_scene(from_item)
		sauce_unequipped.emit(from_item)

	if to_data["slot_type"] == "equipped" and to_item != null:
		remove_bottle_from_scene(to_item)
		sauce_unequipped.emit(to_item)

	# Swap the bottle instances
	from[from_data["slot_index"]] = to_item
	to[to_data["slot_index"]] = from_item

	# Handle scene addition when moving to equipped
	if to_data["slot_type"] == "equipped" and from_item != null:
		add_bottle_to_scene(from_item)
		sauce_equipped.emit(from_item)

	if from_data["slot_type"] == "equipped" and to_item != null:
		add_bottle_to_scene(to_item)
		sauce_equipped.emit(to_item)

	emit_signal("sauce_moved", from_data, to_data)

func get_storage_data(location):
	if location == "equipped":
		return equipped
	else:
		return storage

func get_equipped_bottles() -> Array:
	var active_bottles = []
	for bottle in equipped:
		if bottle != null:
			active_bottles.append(bottle)
	return active_bottles

# XP DISTRIBUTION
func distribute_xp_by_damage(total_xp: int, damage_sources: Dictionary):
	var total_damage = 0.0
	for bottle_id in damage_sources:
		total_damage += damage_sources[bottle_id]

	if total_damage <= 0:
		return

	# Distribute XP proportionally
	for bottle_id in damage_sources:
		var damage_dealt = damage_sources[bottle_id]
		var damage_percentage = damage_dealt / total_damage
		var xp_earned = int(total_xp * damage_percentage)

		# Find the bottle and give it XP
		var bottle = get_bottle_by_id(bottle_id)
		if bottle and bottle.has_method("gain_xp"):
			bottle.gain_xp(xp_earned)

# UPGRADE APPLICATION
func apply_upgrade_choice(bottle_id: String, choice_number: int):
	print("InventoryManager: Applying upgrade choice %d to bottle %s" % [choice_number, bottle_id])

	# Find the bottle instance
	var bottle = get_bottle_by_id(bottle_id)
	if not bottle:
		print("Warning: Bottle %s not found!" % bottle_id)
		return

	# Get the upgrade name and add it to bottle's chosen_upgrades
	var upgrade_name = get_upgrade_name(bottle.sauce_data.sauce_name, choice_number)
	bottle.chosen_upgrades.append(upgrade_name)
	print("Added upgrade '%s' to bottle %s" % [upgrade_name, bottle_id])
	print("Bottle now has upgrades: ", bottle.chosen_upgrades)

	# Apply upgrade to the sauce resource (for persistence)
	apply_upgrade_to_sauce(bottle.sauce_data, choice_number)

	# Update bottle instance if needed (for immediate effects)
	var sauce_name = bottle.sauce_data.sauce_name
	match sauce_name:
		"Ketchup", "Prehistoric Pesto", _:
			match choice_number:
				2, 3: # Fire rate upgrades
					if bottle.has_method("update_fire_rate"):
						bottle.update_fire_rate()
				3: # Range upgrades
					if bottle.has_method("update_detection_range"):
						bottle.update_detection_range()

# Get the human-readable upgrade name
func get_upgrade_name(sauce_name: String, choice_number: int) -> String:
	match sauce_name:
		"Ketchup":
			match choice_number:
				1: return "Thick & Chunky"
				2: return "Double Squirt"
				3: return "Fast Food"
		"Prehistoric Pesto":
			match choice_number:
				1: return "Viral Load"
				2: return "Rapid Mutation"
				3: return "Toxic Herbs"
		_:
			match choice_number:
				1: return "More Damage"
				2: return "Faster Shooting"
				3: return "Longer Range"

	return "Unknown Upgrade"

func apply_upgrade_to_sauce(sauce_resource: BaseSauceResource, choice_number: int):
	var sauce_name = sauce_resource.sauce_name
	print("Applying upgrade choice %d to %s resource" % [choice_number, sauce_name])

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
		2: # Double Squirt
			sauce_resource.projectile_count += 1
		3: # Fast Food
			sauce_resource.fire_rate += 0.3

func _apply_pesto_upgrade(sauce_resource: BaseSauceResource, choice: int):
	match choice:
		1: # Viral Load
			sauce_resource.effect_chance += 0.3
		2: # Rapid Mutation
			sauce_resource.fire_rate += 0.5
		3: # Toxic Herbs
			sauce_resource.damage += 3.0
			sauce_resource.effect_intensity += 1.5

func _apply_generic_upgrade(sauce_resource: BaseSauceResource, choice: int):
	match choice:
		1: # More Damage
			sauce_resource.damage += 3.0
		2: # Faster Shooting
			sauce_resource.fire_rate += 0.2
		3: # Longer Range
			sauce_resource.range += 20.0

# SAUCE SELECTION
func select_sauce(sauce: BaseSauceResource):
	"""Create new bottle instance and place it"""
	var bottle = create_bottle_for_sauce(sauce)
	if not bottle:
		return

	var first_null_index = equipped.find(null)
	if first_null_index != -1:
		equipped[first_null_index] = bottle
		add_bottle_to_scene(bottle)
		sauce_equipped.emit(bottle)
	else:
		# Put in storage if equipped is full
		var storage_index = storage.find(null)
		if storage_index != -1:
			storage[storage_index] = bottle

# INVENTORY UTILITIES
func is_inventory_full():
	return equipped.find(null) == -1

func can_equip_sauce():
	return equipped.size() < 6

func can_store_sauce():
	return storage.size() < 6
