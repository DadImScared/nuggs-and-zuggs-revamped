extends Node2D

@export var weapon_radius: float = 12.0

# Store bottle instances for XP distribution and upgrade application
var active_bottles: Dictionary = {} # bottle_id -> bottle_instance

func _ready():
	add_to_group("sauce_holder")
	# Connect to InventoryManager signals
	InventoryManager.sauce_equipped.connect(_on_sauce_equipped)
	InventoryManager.sauce_unequipped.connect(_on_sauce_unequipped)

	# Connect to player's enemy death signal for XP distribution
	var player = get_parent()
	if player.has_signal("enemy_died_with_sources"):
		player.enemy_died_with_sources.connect(_on_enemy_died_with_sources)

	# Create bottles for initially equipped sauces
	for sauce in InventoryManager.get_equipped_sauces():
		create_bottle_instance(sauce)

func _on_sauce_equipped(sauce: BaseSauceResource):
	create_bottle_instance(sauce)

func _on_sauce_unequipped(sauce: BaseSauceResource):
	destroy_bottle_instance(sauce)

func create_bottle_instance(sauce_resource: BaseSauceResource):
	var item_data = ItemData.new()
	var bottle = item_data.create_bottle(sauce_resource)
	# Add to scene
	add_child(bottle)
	# Connect bottle level up signal to BottleUpgradeManager
	bottle.leveled_up.connect(BottleUpgradeManager._on_bottle_leveled_up)

	# Store bottle instance
	active_bottles[bottle.bottle_id] = bottle

	_position_weapons()
	print("Created bottle instance: %s" % bottle.bottle_id)

func destroy_bottle_instance(sauce_resource: BaseSauceResource):
	# Find bottle with matching sauce resource
	for bottle_id in active_bottles:
		var bottle = active_bottles[bottle_id]
		if bottle.sauce_data == sauce_resource:
			active_bottles.erase(bottle_id)
			remove_child(bottle)
			bottle.queue_free()
			_position_weapons()
			print("Destroyed bottle instance: %s" % bottle_id)
			break

func get_bottle_by_id(bottle_id: String) -> BaseSauceBottle:
	return active_bottles.get(bottle_id)

func apply_upgrade_to_bottle(bottle_id: String, choice_number: int):
	# Find the bottle instance to update its timer/range if needed
	var bottle = get_bottle_by_id(bottle_id)
	if not bottle:
		print("Warning: Bottle %s not found!" % bottle_id)
		return

	# Apply upgrade to the sauce resource (for persistence)
	InventoryManager.apply_upgrade_to_sauce(bottle.sauce_data, choice_number)

	# Update bottle instance if needed (for immediate effects)
	var sauce_name = bottle.sauce_data.sauce_name
	match sauce_name:
		"Ketchup", "Prehistoric Pesto", _:
			match choice_number:
				2, 3: # Fire rate upgrades for any sauce
					if bottle.has_method("update_fire_rate"):
						bottle.update_fire_rate()
				3: # Range upgrades
					if bottle.has_method("update_detection_range"):
						bottle.update_detection_range()

func _on_enemy_died_with_sources(total_xp: int, damage_sources: Dictionary):
	print("Enemy died! XP: %d, Sources: %s" % [total_xp, damage_sources])

	# If no damage sources tracked, distribute XP equally
	if damage_sources.is_empty():
		distribute_xp_equally(total_xp)
		return

	# Calculate total damage dealt
	var total_damage = 0.0
	for bottle_id in damage_sources:
		total_damage += damage_sources[bottle_id]

	if total_damage <= 0:
		distribute_xp_equally(total_xp)
		return
	# Distribute XP proportionally based on damage contribution
	for bottle_id in damage_sources:
		var damage_dealt = damage_sources[bottle_id]
		var damage_percentage = damage_dealt / total_damage
		var xp_earned = int(total_xp * damage_percentage)

		# Find the bottle and give it XP
		var bottle = get_bottle_by_id(bottle_id)
		if bottle and is_instance_valid(bottle):
			bottle.gain_xp(max(1, xp_earned))  # Minimum 1 XP
			print("%s earned %d XP (%.1f%% contribution)" % [bottle.sauce_data.sauce_name, xp_earned, damage_percentage * 100])

func distribute_xp_equally(total_xp: int):
	# Fallback: give equal XP to all active bottles
	if active_bottles.size() == 0:
		return

	var xp_per_bottle = max(1, total_xp / active_bottles.size())
	for bottle_id in active_bottles:
		var bottle = active_bottles[bottle_id]
		if is_instance_valid(bottle):
			bottle.gain_xp(xp_per_bottle)
			print("%s earned %d XP (equal share)" % [bottle.sauce_data.sauce_name, xp_per_bottle])

func _position_weapons():
	var weapons = get_children()
	for i in range(weapons.size()):
		var angle = (i * 2 * PI) / weapons.size()
		var weapon_position = Vector2(
			cos(angle) * weapon_radius,
			sin(angle) * weapon_radius
		)
		weapons[i].position = weapon_position
