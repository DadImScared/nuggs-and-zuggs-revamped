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
		print("🔥 Fire Spirit: Spawning from bottle at %s" % spawn_pos)
	else:
		print("⚠️ Fire Spirit: No valid bottle position")
		return

	# Read parameters
	var spirit_count = data.effect_parameters.get("spirit_count", 1)
	var seek_range = data.effect_parameters.get("seek_range", 300.0)
	var spirit_speed = data.effect_parameters.get("spirit_speed", 200.0)
	var burn_stacks = data.effect_parameters.get("burn_stacks", 2)

	# Spawn fire spirits from the bottle
	for i in range(spirit_count):
		_spawn_fire_spirit(spawn_pos, bottle, spirit_speed, seek_range, burn_stacks)

	print("🔥 Fire Spirit: Spawned %d seeking fire spirits from bottle" % spirit_count)

func _spawn_fire_spirit(spawn_pos: Vector2, source_bottle: ImprovedBaseSauceBottle, speed: float, seek_range: float, burn_stacks: int):
	"""Create a seeking fire spirit projectile"""
	# Find closest enemy within range, but exclude recently targeted ones
	var target_enemy = _find_best_target(spawn_pos, seek_range)
	if not target_enemy:
		print("🔥 Fire Spirit: No enemies in range")
		return

	# Create the fire spirit
	var fire_spirit_scene = preload("res://Effects/FireSpirit/fire_spirit.tscn")
	var fire_spirit = fire_spirit_scene.instantiate()

	# Setup the spirit
	fire_spirit.global_position = spawn_pos

	# Set high z_index so it renders on top
	fire_spirit.z_index = 100

	if is_instance_valid(target_enemy) and is_instance_valid(source_bottle):
		fire_spirit.setup_spirit(target_enemy, source_bottle, speed, burn_stacks)
	else:
		print("⚠️ Fire Spirit: Invalid parameters, destroying spirit")
		fire_spirit.queue_free()
		return

	# Add to scene using call_deferred to avoid physics conflicts
	var scene = Engine.get_main_loop().current_scene
	scene.call_deferred("add_child", fire_spirit)

	print("🔥 Fire Spirit: Created spirit targeting enemy at %s (z_index: 100)" % target_enemy.global_position)

# Keep track of recently targeted enemies to spread spirits around
var recently_targeted: Array[Node2D] = []

func _find_best_target(position: Vector2, max_range: float) -> Node2D:
	"""Find the best enemy target, avoiding recently targeted ones"""
	var enemies = get_enemies_in_radius(position, max_range)
	if enemies.is_empty():
		return null

	# Clean up invalid recently targeted enemies
	recently_targeted = recently_targeted.filter(func(enemy): return is_instance_valid(enemy))

	# First try to find enemies not recently targeted
	var untargeted_enemies = []
	for enemy in enemies:
		if not enemy in recently_targeted:
			untargeted_enemies.append(enemy)

	var target_pool = untargeted_enemies if untargeted_enemies.size() > 0 else enemies

	# Find closest enemy from the target pool
	var closest_enemy = null
	var closest_distance = max_range + 1

	for enemy in target_pool:
		if not is_instance_valid(enemy):
			continue

		var distance = position.distance_to(enemy.global_position)
		if distance < closest_distance:
			closest_distance = distance
			closest_enemy = enemy

	# Mark this enemy as recently targeted
	if closest_enemy:
		recently_targeted.append(closest_enemy)
		# Keep only the last 5 targets to eventually allow retargeting
		if recently_targeted.size() > 5:
			recently_targeted.pop_front()

		print("🔥 Fire Spirit: Targeting enemy (recently targeted: %d)" % recently_targeted.size())

	return closest_enemy
