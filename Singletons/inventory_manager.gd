# Singletons/inventory_manager.gd
extends Node

# Direct signals for UI
signal bottle_leveled_up(bottle_id: String, sauce_name: String, level: int)

var max_equipped_size = 6
var max_inventory = 6

# Sauce resources (for UI display)
var storage: Array = []
var old_equipped: Array = [
	preload("res://Resources/prehistoric_pesto.tres"),
	preload("res://Resources/prehistoric_pesto.tres")
]

var equipped = [

]

# Bottle instances (for gameplay) - NO DUPLICATION!
var equipped_bottles: Dictionary = {} # sauce_resource -> bottle_instance
var scene_holder_node: Node2D # Reference to actual scene node

signal sauce_moved(from_data, to_data)
signal sauce_equipped(sauce: BaseSauceResource)
signal sauce_unequipped(sauce: BaseSauceResource)

func _ready() -> void:
	storage.resize(max_inventory)
	equipped.resize(max_equipped_size)
	print("InventoryManager initialized with bottle management")

# Called by the scene's SauceHolder node to register itself
func register_scene_node(scene_node: Node2D):
	scene_holder_node = scene_node
	print("InventoryManager: Scene node registered")

# BOTTLE MANAGEMENT - Merged from SauceHolder
func create_bottle_for_sauce(sauce_resource: BaseSauceResource):
	#if equipped_bottles.has(sauce_resource):
		#print("Bottle already exists for %s" % sauce_resource.sauce_name)
		#return

	var item_data = ItemData.new()
	var bottle = item_data.create_bottle(sauce_resource)

	if not bottle:
		print("❌ Failed to create bottle instance!")
		return

	# Add to scene
	if scene_holder_node:
		scene_holder_node.add_child(bottle)

	# Connect bottle level up signal DIRECTLY
	if bottle.has_signal("leveled_up"):
		bottle.leveled_up.connect(_on_bottle_leveled_up)

	# Store bottle instance
	equipped_bottles[sauce_resource] = bottle
	equip_new_sauce(bottle)
	_position_weapons()
	print("✅ Created bottle for: %s" % sauce_resource.sauce_name)

func destroy_bottle_for_sauce(sauce_resource: BaseSauceResource):
	if not equipped_bottles.has(sauce_resource):
		return

	var bottle = equipped_bottles[sauce_resource]

	# Disconnect signal
	if bottle.has_signal("leveled_up"):
		bottle.leveled_up.disconnect(_on_bottle_leveled_up)

	# Remove from scene and cleanup
	if scene_holder_node and bottle.get_parent() == scene_holder_node:
		scene_holder_node.remove_child(bottle)
	bottle.queue_free()

	equipped_bottles.erase(sauce_resource)
	_position_weapons()
	print("🗑️ Destroyed bottle for: %s" % sauce_resource.sauce_name)

# DIRECT SIGNAL HANDLING - No forwarding needed!
func _on_bottle_leveled_up(bottle_id: String, level: int, sauce_name: String):
	print("InventoryManager: %s leveled up to %d" % [sauce_name, level])
	bottle_leveled_up.emit(bottle_id, sauce_name, level)

# DIRECT UPGRADE APPLICATION
func apply_upgrade_choice(bottle_id: String, choice_number: int):
	print("InventoryManager: Applying upgrade choice %d to bottle %s" % [choice_number, bottle_id])

	# Find the bottle instance
	var bottle = get_bottle_by_id(bottle_id)
	if not bottle:
		print("Warning: Bottle %s not found!" % bottle_id)
		return

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

func get_bottle_by_id(bottle_id: String):
	for bottle in equipped:
		if bottle and bottle.bottle_id == bottle_id:
			return bottle
	return null

func _position_weapons():
	if not scene_holder_node:
		return

	var bottle_count = equipped.size()
	if bottle_count == 0:
		return

	var angle_step = TAU / bottle_count
	var i = 0
	for bottle in equipped:
		if is_instance_valid(bottle):
			var angle = i * angle_step
			var offset = Vector2(cos(angle), sin(angle)) * 24.0 # weapon_radius
			bottle.position = offset
			i += 1

# EXISTING SAUCE MANAGEMENT
func move_sauce(from_data, to_data):
	var from = get_storage_data(from_data["slot_type"])
	var to = get_storage_data(to_data["slot_type"])

	# Get what's currently in each slot
	var from_item = from[from_data["slot_index"]]
	var to_item = to[to_data["slot_index"]]

	# Handle bottle destruction/creation
	if from_data["slot_type"] == "equipped" and from_item != null:
		destroy_bottle_for_sauce(from_item)
		sauce_unequipped.emit(from_item)
	if to_data["slot_type"] == "equipped" and to_item != null:
		destroy_bottle_for_sauce(to_item)
		sauce_unequipped.emit(to_item)

	# Move the sauce resources
	from[from_data["slot_index"]] = to_item
	to[to_data["slot_index"]] = from_item

	# Handle bottle creation
	if to_data["slot_type"] == "equipped" and from_item != null:
		create_bottle_for_sauce(from_item)
		sauce_equipped.emit(from_item)
	if from_data["slot_type"] == "equipped" and to_item != null:
		create_bottle_for_sauce(to_item)
		sauce_equipped.emit(to_item)

	emit_signal("sauce_moved", from_data, to_data)

func get_storage_data(location):
	if location == "equipped":
		return equipped
	else:
		return storage

func get_equipped_sauces() -> Array:
	return equipped
	var active_sauces = []
	for sauce in equipped:
		if sauce != null:
			active_sauces.append(sauce)
	return active_sauces

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

# UPGRADE LOGIC
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

func is_inventory_full():
	return equipped.find(null) == -1

func can_equip_sauce():
	return equipped.size() < 6

func can_store_sauce():
	return storage.size() < 6

func select_sauce(sauce: BaseSauceResource):
	var first_null_index = equipped.find(null)
	if first_null_index != -1:
		create_bottle_for_sauce(sauce)
		sauce_equipped.emit(sauce)
	else:
		storage.append(sauce)

func equip_new_sauce(sauce_bottle):
	var first_null_index = equipped.find(null)
	if first_null_index != -1:
		equipped[first_null_index] = sauce_bottle
