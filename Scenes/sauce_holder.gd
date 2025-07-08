extends Node2D

@export var weapon_radius: float = 12.0

# Store references to bottles by their IDs for XP distribution
var bottle_lookup: Dictionary = {}

func _ready():
	InventoryManager.sauce_moved.connect(_on_sauce_moved)
	InventoryManager.sauce_equipped.connect(_on_sauce_selected)

	# Connect to player's enemy death signal for XP distribution
	var player = get_parent()
	if player.has_signal("enemy_died_with_sources"):
		player.enemy_died_with_sources.connect(_on_enemy_died_with_sources)

	for i in InventoryManager.equipped.size():
		var sauce_bottle = InventoryManager.equipped[i]
		if sauce_bottle:
			var item_data = ItemData.new()
			var bottle = item_data.create_bottle(InventoryManager.equipped[i])
			add_child(bottle)
			# Register the bottle in our lookup
			bottle_lookup[bottle.bottle_id] = bottle

	_position_weapons()

func _on_sauce_selected(sauce: BaseSauceResource):
	print("sauce selected")
	var item_data = ItemData.new()
	var bottle = item_data.create_bottle(sauce)
	add_child(bottle)
	# Register the new bottle
	bottle_lookup[bottle.bottle_id] = bottle
	_position_weapons()

func _on_sauce_moved(from_data: SlotData, to_data: SlotData):
	if from_data.slot_type == "equipped":
		# Remove bottle from game world
		for child in get_children():
			if child.sauce_data == from_data.sauce_bottle:
				bottle_lookup.erase(child.bottle_id)
				remove_child(child)
				child.queue_free()
				break
		# Add new bottle if slot wasn't empty
		if to_data.sauce_bottle:
			var item_data = ItemData.new()
			var bottle = item_data.create_bottle(to_data.sauce_bottle)
			add_child(bottle)
			bottle_lookup[bottle.bottle_id] = bottle

	if from_data.slot_type == "inventory":
		# Remove old bottle if slot had something
		if to_data.sauce_bottle:
			for child in get_children():
				if child.sauce_data == to_data.sauce_bottle:
					bottle_lookup.erase(child.bottle_id)
					remove_child(child)
					child.queue_free()
					break
		# Add new bottle
		var item_data = ItemData.new()
		var bottle = item_data.create_bottle(from_data.sauce_bottle)
		add_child(bottle)
		bottle_lookup[bottle.bottle_id] = bottle

	_position_weapons()

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
		if bottle_lookup.has(bottle_id):
			var bottle = bottle_lookup[bottle_id]
			if is_instance_valid(bottle):
				bottle.gain_xp(max(1, xp_earned))  # Minimum 1 XP
				print("%s earned %d XP (%.1f%% contribution)" % [bottle.sauce_data.sauce_name, xp_earned, damage_percentage * 100])

func distribute_xp_equally(total_xp: int):
	# Fallback: give equal XP to all active bottles
	var active_bottles = get_children()
	if active_bottles.size() == 0:
		return

	var xp_per_bottle = max(1, total_xp / active_bottles.size())
	for bottle in active_bottles:
		if bottle.has_method("gain_xp"):
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
