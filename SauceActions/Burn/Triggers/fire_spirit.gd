# SauceActions/Burn/Triggers/fire_spirit.gd
class_name FireSpiritTrigger
extends BaseTriggerAction

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

	# Read parameters - now includes spirit_damage
	var spirit_count = data.effect_parameters.get("spirit_count", 1)
	var seek_range = data.effect_parameters.get("seek_range", 300.0)
	var spirit_speed = data.effect_parameters.get("spirit_speed", 200.0)
	var burn_stacks = data.effect_parameters.get("burn_stacks", 2)
	var spirit_damage = data.effect_parameters.get("spirit_damage", 7.0)  # NEW: Read damage parameter

	# Spawn fire spirits from the bottle
	for i in range(spirit_count):
		_spawn_fire_spirit(spawn_pos, bottle, spirit_speed, seek_range, burn_stacks, spirit_damage)

	DebugControl.debug_status("🔥 Fire Spirit: Spawned %d seeking fire spirits from bottle (%.1f damage each)" % [spirit_count, spirit_damage])

func _spawn_fire_spirit(spawn_pos: Vector2, source_bottle: ImprovedBaseSauceBottle, speed: float, seek_range: float, burn_stacks: int, spirit_damage: float):
	"""Create a seeking fire spirit projectile"""
	# Find closest enemy within range, but exclude recently targeted ones
	var target_enemy = _find_best_target(spawn_pos, seek_range)
	if not target_enemy:
		DebugControl.debug_status("🔥 Fire Spirit: No enemies in range")
		return

	# Create the fire spirit
	var fire_spirit_scene = preload("res://Effects/FireSpirit/fire_spirit.tscn")
	var fire_spirit = fire_spirit_scene.instantiate()

	# Setup the spirit
	fire_spirit.global_position = spawn_pos

	# Set high z_index so it renders on top
	fire_spirit.z_index = 100

	if is_instance_valid(target_enemy) and is_instance_valid(source_bottle):
		fire_spirit.setup_spirit(target_enemy, source_bottle, speed, burn_stacks, spirit_damage)  # Pass damage parameter
	else:
		DebugControl.debug_status("⚠️ Fire Spirit: Invalid parameters, destroying spirit")
		fire_spirit.queue_free()
		return

	# Add to scene using call_deferred to avoid physics conflicts
	var scene = Engine.get_main_loop().current_scene
	scene.call_deferred("add_child", fire_spirit)

	DebugControl.debug_status("🔥 Fire Spirit: Created spirit targeting enemy at %s (z_index: 100)" % target_enemy.global_position)

# Keep track of recently targeted enemies to spread spirits around
var recently_targeted: Array[Node2D] = []

func _find_best_target(spawn_pos: Vector2, seek_range: float) -> Node2D:
	"""Find the best enemy target within range, excluding recently targeted ones"""
	# Use a simple approach that works - get all enemy nodes directly
	var all_nodes = Engine.get_main_loop().current_scene.get_children()
	var enemies = []

	# Recursively find all enemy nodes
	_find_enemies_recursive(all_nodes, enemies)

	var best_target: Node2D = null
	var best_distance: float = seek_range + 1.0  # Start beyond max range

	for enemy in enemies:
		if not is_instance_valid(enemy):
			continue

		var distance = spawn_pos.distance_to(enemy.global_position)
		if distance <= seek_range and distance < best_distance:
			# Prefer enemies not recently targeted
			if enemy not in recently_targeted:
				best_target = enemy
				best_distance = distance

	# Clean up recently targeted list (remove invalid/dead enemies)
	recently_targeted = recently_targeted.filter(func(e): return is_instance_valid(e))

	# Add new target to recently targeted list
	if best_target:
		recently_targeted.append(best_target)
		# Keep list manageable size
		if recently_targeted.size() > 5:
			recently_targeted.pop_front()

	return best_target

func _find_enemies_recursive(nodes: Array, enemies: Array):
	"""Recursively find all enemy nodes"""
	for node in nodes:
		if node.is_in_group("enemies"):
			enemies.append(node)
		if node.get_child_count() > 0:
			_find_enemies_recursive(node.get_children(), enemies)
