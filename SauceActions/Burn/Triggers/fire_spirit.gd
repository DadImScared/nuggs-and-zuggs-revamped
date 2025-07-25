# SauceActions/Burn/Triggers/fire_spirit.gd
class_name FireSpiritTrigger
extends BaseTriggerAction

# Track recently targeted enemies to encourage spread
var recently_targeted: Array[Node2D] = []

func _init() -> void:
	trigger_name = "fire_spirit"
	trigger_description = "15% chance to spawn a seeking fire spirit that travels to nearest enemy"

func execute_trigger(bottle: ImprovedBaseSauceBottle, data: EnhancedTriggerData):
	var hit_enemy = data.effect_parameters.get("hit_enemy")
	var projectile = data.effect_parameters.get("hit_projectile")

	# Always spawn from bottle position for cooler effect
	var spawn_pos: Vector2
	if bottle and is_instance_valid(bottle):
		spawn_pos = bottle.global_position
		DebugControl.debug_status("🔥 Fire Spirit: Spawning from bottle at %s" % spawn_pos)
	else:
		DebugControl.debug_status("⚠️ Fire Spirit: No valid bottle position")
		return

	# Read ALL parameters from effect_parameters (consistent location)
	var spirit_count = data.effect_parameters.get("spirit_count", 1)
	var seek_range = data.effect_parameters.get("seek_range", 300.0)
	var spirit_speed = data.effect_parameters.get("spirit_speed", 200.0)
	var burn_stacks = data.effect_parameters.get("burn_stacks", 2)
	var spirit_damage = data.effect_parameters.get("spirit_damage", 7.0)

	# NEW: Trail parameters from Blazing Trails talent
	var leaves_trail = data.effect_parameters.get("leaves_trail", false)
	var trail_width = data.effect_parameters.get("trail_width", 60.0)
	var trail_duration = data.effect_parameters.get("trail_duration", 5.0)
	var trail_tick_damage = data.effect_parameters.get("trail_tick_damage", 8.0)
	var trail_tick_interval = data.effect_parameters.get("trail_tick_interval", 0.3)
	var trail_color = data.effect_parameters.get("trail_color", Color(1.0, 0.3, 0.0, 0.6))

	# Spawn fire spirits from the bottle
	for i in range(spirit_count):
		_spawn_fire_spirit(spawn_pos, seek_range, spirit_speed, burn_stacks,
			spirit_damage, bottle, leaves_trail, trail_width, trail_duration,
			trail_tick_damage, trail_tick_interval, trail_color)

func _spawn_fire_spirit(spawn_pos: Vector2, seek_range: float, spirit_speed: float,
	burn_stacks: int, spirit_damage: float, source_bottle: ImprovedBaseSauceBottle,
	leaves_trail: bool = false, trail_width: float = 60.0, trail_duration: float = 5.0,
	trail_tick_damage: float = 8.0, trail_tick_interval: float = 0.3,
	trail_color: Color = Color(1.0, 0.3, 0.0, 0.6)):
	"""Spawn a single fire spirit with smart targeting"""

	# Find smart target
	var target_enemy = _find_smart_target(spawn_pos, seek_range)
	if not target_enemy:
		# Try clearing recently targeted and search again
		_clear_recently_targeted_if_needed()
		target_enemy = _find_smart_target(spawn_pos, seek_range)

	if not target_enemy:
		DebugControl.debug_status("🔥 Fire Spirit: No valid targets found")
		return

	# Add to recently targeted list
	_manage_recently_targeted_list(target_enemy)

	# Load fire spirit scene
	var fire_spirit_scene = preload("res://Effects/FireSpirit/fire_spirit.tscn")
	var fire_spirit = fire_spirit_scene.instantiate()

	# Set position
	fire_spirit.global_position = spawn_pos

	# Setup fire spirit with correct method and parameters
	fire_spirit.setup_spirit(target_enemy, source_bottle, spirit_speed, burn_stacks, spirit_damage)

	# Enable trail behavior if Blazing Trails talent is active
	if leaves_trail:
		fire_spirit.setup_trail_behavior(trail_width, trail_duration, trail_tick_damage, trail_tick_interval, trail_color)

	# Add to scene (deferred to avoid physics collision issues)
	var main_scene = Engine.get_main_loop().current_scene
	main_scene.call_deferred("add_child", fire_spirit)

	DebugControl.debug_status("🔥 Fire Spirit spawned with speed: %.0f, targeting: %s" % [spirit_speed, target_enemy.name if target_enemy else "none"])

func _find_smart_target(spawn_pos: Vector2, seek_range: float) -> Node2D:
	"""Smart targeting: non-burning > not recently targeted > random"""

	var all_enemies = Engine.get_main_loop().current_scene.get_tree().get_nodes_in_group("enemies")
	var valid_enemies = []
	var non_burning_enemies = []
	var fresh_enemies = []  # Not recently targeted

	# Categorize all valid enemies
	for enemy in all_enemies:
		if not is_instance_valid(enemy):
			continue

		var distance = spawn_pos.distance_to(enemy.global_position)
		if distance > seek_range:
			continue

		valid_enemies.append(enemy)

		# Check if enemy is burning
		var is_burning = false
		if enemy.has_method("get_total_stack_count"):
			is_burning = enemy.get_total_stack_count("burn") > 0
		elif enemy.has_method("has_status_effect"):
			is_burning = enemy.has_status_effect("burn")

		if not is_burning:
			non_burning_enemies.append(enemy)

		# Check if recently targeted
		if enemy not in recently_targeted:
			fresh_enemies.append(enemy)

	# Priority 1: Non-burning enemies that aren't recently targeted
	var priority_targets = []
	for enemy in non_burning_enemies:
		if enemy in fresh_enemies:
			priority_targets.append(enemy)

	if priority_targets.size() > 0:
		DebugControl.debug_status("🔥 Fire Spirit: Targeting non-burning fresh enemy")
		return _get_closest_enemy(spawn_pos, priority_targets)

	# Priority 2: Any non-burning enemies (even if recently targeted)
	if non_burning_enemies.size() > 0:
		DebugControl.debug_status("🔥 Fire Spirit: Targeting non-burning enemy (recently targeted)")
		return _get_closest_enemy(spawn_pos, non_burning_enemies)

	# Priority 3: Fresh enemies (not recently targeted, even if burning)
	if fresh_enemies.size() > 0:
		DebugControl.debug_status("🔥 Fire Spirit: Targeting fresh burning enemy")
		return _get_closest_enemy(spawn_pos, fresh_enemies)

	# Priority 4: Any valid enemy (random fallback)
	if valid_enemies.size() > 0:
		DebugControl.debug_status("🔥 Fire Spirit: Random target fallback")
		return valid_enemies[randi() % valid_enemies.size()]

	# No targets available
	DebugControl.debug_status("🔥 Fire Spirit: No valid targets in range")
	return null

func _get_closest_enemy(spawn_pos: Vector2, enemies: Array) -> Node2D:
	"""Get the closest enemy from a list"""
	if enemies.is_empty():
		return null

	var closest_enemy = enemies[0]
	var closest_distance = spawn_pos.distance_to(closest_enemy.global_position)

	for enemy in enemies:
		var distance = spawn_pos.distance_to(enemy.global_position)
		if distance < closest_distance:
			closest_distance = distance
			closest_enemy = enemy

	return closest_enemy

func _manage_recently_targeted_list(new_target: Node2D):
	"""Add target to recently targeted and manage list size"""
	if new_target:
		recently_targeted.append(new_target)

		# Keep list reasonable size (prevent infinite growth)
		var max_recently_targeted = 5
		while recently_targeted.size() > max_recently_targeted:
			recently_targeted.pop_front()

		# Clean up invalid references
		recently_targeted = recently_targeted.filter(func(enemy): return is_instance_valid(enemy))

func _clear_recently_targeted_if_needed():
	"""Clear recently targeted if no valid targets available"""
	var all_enemies = Engine.get_main_loop().current_scene.get_tree().get_nodes_in_group("enemies")
	var available_targets = 0

	for enemy in all_enemies:
		if is_instance_valid(enemy) and enemy not in recently_targeted:
			available_targets += 1

	# If no fresh targets available, clear the list to allow retargeting
	if available_targets == 0 and recently_targeted.size() > 0:
		DebugControl.debug_status("🔥 Fire Spirit: Clearing recently targeted list (no fresh targets)")
		recently_targeted.clear()
