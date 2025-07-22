# SauceActions/Fossilization/Triggers/crystalline_bloom.gd
class_name CrystallineBloomTrigger
extends BaseAmberTrigger

# Crystalline Bloom parameters
var detection_radius: float = 400.0
var cooldown_duration: float = 2.0
var min_fossilized_enemies: int = 3
var max_spawn_distance: float = 250.0  # Maximum distance from player to spawn crystal

# Cooldown tracking
var last_crystal_spawn_time: int = 0
var crystal_scene: PackedScene

func _init():
	trigger_name = "crystalline_bloom"
	trigger_description = "Spawn amber crystals when 3+ enemies are fossilized nearby"

	# Load the crystal scene
	crystal_scene = preload("res://Scenes/amber_crystal.tscn")

func should_trigger(source_bottle: ImprovedBaseSauceBottle, trigger_data: EnhancedTriggerData) -> bool:
	# Check cooldown first
	var current_time = Time.get_ticks_msec()

	if current_time - last_crystal_spawn_time < cooldown_duration * 1000:  # Convert seconds to milliseconds
		return false

	# Check if we have enough fossilized enemies nearby
	var player_position = _get_player_position()
	if player_position == Vector2.ZERO:
		return false

	var fossilized_count = _count_fossilized_enemies_near_player(player_position)

	if fossilized_count >= min_fossilized_enemies:
		#print("💎 Crystalline Bloom: %d fossilized enemies detected - spawning crystal!" % fossilized_count)
		return true

	return false

func execute_trigger(source_bottle: ImprovedBaseSauceBottle, trigger_data: EnhancedTriggerData) -> void:
	var player_position = _get_player_position()

	if player_position == Vector2.ZERO:
		#print("💎 Crystalline Bloom: Could not find player position")
		return

	# FIXED: Find a good spawn position that stays near the player
	var spawn_position = _get_crystal_spawn_position(player_position)

	_spawn_crystal_at_position(spawn_position, source_bottle, trigger_data)
	_update_cooldown()

func _get_player_position() -> Vector2:
	"""Get the current player position"""
	# Try multiple ways to find the player
	var player = null

	# Method 1: Look for player in scene tree
	var scene_tree = Engine.get_main_loop().current_scene.get_tree()
	var players = scene_tree.get_nodes_in_group("player")
	if players.size() > 0:
		player = players[0]

	# Method 2: Look for player node by name
	if not player:
		player = Engine.get_main_loop().current_scene.get_node_or_null("Player")

	# Method 3: Look for DinoNugget (if that's the player class)
	if not player:
		player = Engine.get_main_loop().current_scene.get_node_or_null("DinoNugget")

	if player and is_instance_valid(player):
		return player.global_position

	#print("💎 Warning: Could not find player node")
	return Vector2.ZERO

func _get_crystal_spawn_position(player_position: Vector2) -> Vector2:
	"""FIXED: Find a good position to spawn the crystal - keep it reasonably close to player"""
	var nearby_enemies = get_nearby_enemies(player_position, detection_radius)
	var fossilized_enemies = []

	# Collect all fossilized enemies within reasonable distance
	for enemy in nearby_enemies:
		if is_instance_valid(enemy) and is_enemy_fossilized(enemy):
			var distance_to_player = enemy.global_position.distance_to(player_position)

			# Only consider enemies within reasonable range
			if distance_to_player <= max_spawn_distance:
				fossilized_enemies.append(enemy)

	if fossilized_enemies.is_empty():
		#print("💎 No nearby fossilized enemies - spawning near player")
		# Spawn in a random direction around the player, but close by
		var random_angle = randf() * TAU  # Random angle in radians
		var spawn_distance = randf_range(80.0, 150.0)  # 80-150 pixels from player
		var offset = Vector2(cos(random_angle), sin(random_angle)) * spawn_distance
		return player_position + offset

	# Find the center point of nearby fossilized enemies
	var center_position = Vector2.ZERO
	for enemy in fossilized_enemies:
		center_position += enemy.global_position
	center_position /= fossilized_enemies.size()

	# FIXED: Clamp the spawn position to stay within reasonable distance of player
	var distance_to_player = center_position.distance_to(player_position)
	if distance_to_player > max_spawn_distance:
		# Move the spawn position closer to the player
		var direction_to_center = (center_position - player_position).normalized()
		center_position = player_position + (direction_to_center * max_spawn_distance)
		#print("💎 Clamped crystal spawn position to stay within %.0fpx of player" % max_spawn_distance)

	#print("💎 Spawning crystal at center of %d nearby fossilized enemies (%.0fpx from player)" % [fossilized_enemies.size(), center_position.distance_to(player_position)])
	return center_position

func _count_fossilized_enemies_near_player(player_position: Vector2) -> int:
	"""Count fossilized enemies within detection radius of player"""
	var fossilized_count = 0
	var nearby_enemies = get_nearby_enemies(player_position, detection_radius)

	for enemy in nearby_enemies:
		if is_instance_valid(enemy) and is_enemy_fossilized(enemy):
			fossilized_count += 1

	#print("💎 Found %d fossilized enemies within %.0fpx of player" % [fossilized_count, detection_radius])
	return fossilized_count

func _spawn_crystal_at_position(position: Vector2, source_bottle: ImprovedBaseSauceBottle, trigger_data: EnhancedTriggerData):
	"""Instantiate and configure the amber crystal"""
	if not crystal_scene:
		#print("💎 Error: Crystal scene not loaded!")
		return

	var crystal = crystal_scene.instantiate()

	if not crystal:
		#print("💎 Error: Failed to instantiate crystal!")
		return

	# Position the crystal at chosen location
	crystal.global_position = position

	# Pass the source bottle for damage credit
	crystal.source_bottle = source_bottle

	# Apply any enhancements from trigger data
	_apply_crystal_enhancements(crystal, trigger_data)

	# Add to scene
	Engine.get_main_loop().current_scene.add_child(crystal)

	#print("💎 Amber Crystal spawned at position %s by %s (%.0fpx from player)" % [str(position), source_bottle.sauce_data.sauce_name, position.distance_to(_get_player_position())])

	# Optional: Create spawn visual effect
	create_fossilization_particles(position, DEFAULT_AMBER_COLOR)

func _apply_crystal_enhancements(crystal: AmberCrystal, trigger_data: EnhancedTriggerData):
	"""Apply any talent enhancements to the crystal"""

	# Check for fossilization chance enhancements
	var chance_bonus = trigger_data.effect_parameters.get("spread_fossilize_chance_bonus", 0.0)
	if chance_bonus > 0.0:
		crystal.enhance_fossilization_chance(chance_bonus)

	# Check for damage multiplier enhancements
	var damage_multiplier = trigger_data.effect_parameters.get("damage_multiplier", 1.0)
	if damage_multiplier != 1.0:
		crystal.enhance_damage_multiplier(damage_multiplier)

	# Check for radius enhancements
	var radius_bonus = trigger_data.effect_parameters.get("pulse_radius_bonus", 0.0)
	if radius_bonus > 0.0:
		crystal.pulse_radius += radius_bonus

	# Check for duration enhancements
	var duration_bonus = trigger_data.effect_parameters.get("duration_bonus", 0.0)
	if duration_bonus > 0.0:
		crystal.total_duration += duration_bonus

func _update_cooldown():
	"""Update the cooldown timestamp"""
	last_crystal_spawn_time = Time.get_ticks_msec()

	#print("💎 Crystalline Bloom cooldown started - next crystal available in %.1fs" % cooldown_duration)

# Public interface for debugging/testing
func get_fossilized_count_near_player() -> int:
	"""Public method to check current fossilized enemy count"""
	var player_position = _get_player_position()
	if player_position != Vector2.ZERO:
		return _count_fossilized_enemies_near_player(player_position)
	return 0

func is_on_cooldown() -> bool:
	"""Check if the trigger is currently on cooldown"""
	var current_time = Time.get_ticks_msec()
	return current_time - last_crystal_spawn_time < cooldown_duration * 1000
