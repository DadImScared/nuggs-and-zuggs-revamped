# SauceActions/Cold/Triggers/snowball.gd
class_name SnowballTrigger
extends BaseTriggerAction

# Preload the snowball scene
const SNOWBALL_SCENE = preload("res://Effects/Snowball/snowball.tscn")

func _init() -> void:
	trigger_name = "snowball"
	trigger_description = "40% chance on hit to fire snowballs that explode for splash damage"

func execute_trigger(bottle: ImprovedBaseSauceBottle, data: EnhancedTriggerData):
	var hit_enemy = data.effect_parameters.get("hit_enemy")
	var hit_position = data.effect_parameters.get("hit_position", Vector2.ZERO)

	if not hit_enemy or not is_instance_valid(hit_enemy):
		return

	# Use bottle position as spawn point, not hit position
	var spawn_position = bottle.global_position if bottle else hit_enemy.global_position

	# Get parameters from trigger data
	var damage = data.effect_parameters.get("damage", 25)
	var splash_radius = data.effect_parameters.get("splash_radius", 200)
	var splash_damage_multiplier = data.effect_parameters.get("splash_damage", 0.5)
	var num_balls = data.effect_parameters.get("balls", 2)

	DebugControl.debug_status("❄️ Snowball trigger activated! Firing %d snowballs from bottle" % num_balls)

	# Find nearby enemies to target (around the hit position, not bottle)
	var target_center = hit_enemy.global_position
	var enemies = _find_nearby_enemies(target_center, 500.0)

	if enemies.is_empty():
		DebugControl.debug_status("❄️ No enemies found for snowball targeting")
		return

	# Spawn snowballs from bottle position (defer to avoid physics conflicts)
	for i in range(num_balls):
		call_deferred("_spawn_snowball", spawn_position, enemies, damage, splash_radius, splash_damage_multiplier, bottle)

func _find_nearby_enemies(center_position: Vector2, max_range: float) -> Array:
	"""Find enemies within range to target with snowballs"""
	var enemies = []
	var enemy_group = Engine.get_main_loop().get_nodes_in_group("enemies")

	for enemy in enemy_group:
		if not is_instance_valid(enemy):
			continue

		var distance = center_position.distance_to(enemy.global_position)
		if distance <= max_range:
			enemies.append(enemy)

	# Sort by distance (closest first)
	enemies.sort_custom(func(a, b): return center_position.distance_to(a.global_position) < center_position.distance_to(b.global_position))

	return enemies

func _spawn_snowball(spawn_position: Vector2, available_enemies: Array, damage: float, splash_radius: float, splash_damage_multiplier: float, source_bottle: Node):
	"""Spawn a single snowball targeting a random enemy"""

	if available_enemies.is_empty():
		return

	# Pick a random enemy from available targets
	var target_enemy = available_enemies[randi() % available_enemies.size()]

	if not is_instance_valid(target_enemy):
		return

	# Create snowball instance
	var snowball = SNOWBALL_SCENE.instantiate()

	# Add to scene (deferred to avoid physics conflicts)
	var scene_root = Engine.get_main_loop().current_scene
	scene_root.call_deferred("add_child", snowball)

	# Initialize the snowball (also deferred)
	var target_position = target_enemy.global_position
	snowball.call_deferred("initialize", spawn_position, target_position, damage, splash_radius, splash_damage_multiplier)

	# Connect explosion signal to handle splash damage (deferred)
	snowball.call_deferred("connect", "snowball_exploded", _on_snowball_exploded.bind(source_bottle))

	DebugControl.debug_status("❄️ Snowball spawned targeting enemy at %s" % target_position)

func _on_snowball_exploded(explosion_position: Vector2, splash_radius: float, splash_damage: float, source_bottle: Node):
	"""Handle snowball explosion and apply splash damage + cold to nearby enemies"""

	var enemies_in_splash = _find_nearby_enemies(explosion_position, splash_radius)

	DebugControl.debug_status("❄️ Snowball exploded! Hitting %d enemies in splash" % enemies_in_splash.size())

	for enemy in enemies_in_splash:
		if not is_instance_valid(enemy) or not enemy.has_method("take_damage_from_source"):
			continue

		# Apply splash damage
		var bottle_id = source_bottle.bottle_id if source_bottle else "snowball_trigger"
		enemy.take_damage_from_source(splash_damage, bottle_id)

		# Apply cold effect to splashed enemies
		_apply_cold_to_enemy(enemy, source_bottle)

	# Create visual feedback for splash area
	_create_splash_visual_feedback(explosion_position, splash_radius)

func _apply_cold_to_enemy(enemy: Node, source_bottle: Node):
	"""Apply cold stacks to enemy hit by snowball splash"""
	if not enemy or not is_instance_valid(enemy):
		return

	# Cold parameters for snowball splash
	var cold_stacks = 2  # Apply 2 cold stacks per snowball
	var enhanced_params = {
		"duration": 4.0,  # Slightly shorter than normal cold
		"tick_interval": 0.0,  # No ticking for cold
		"tick_damage": 0.0,    # No tick damage for cold
		"max_stacks": 6,
		"stack_value": 1.0,
		"slow_per_stack": 0.15,  # 15% slow per stack
		"freeze_threshold": 6,   # Freeze at 6 stacks
		"cold_color": Color(0.7, 0.9, 1.0, 0.8),  # Light blue
		"tick_effect": null
	}

	# Use the Effects system to apply cold
	if Effects and Effects.cold:
		Effects.cold.apply_from_talent(enemy, source_bottle, cold_stacks, enhanced_params)
		DebugControl.debug_status("❄️ Applied %d cold stacks to enemy from snowball splash" % cold_stacks)

func _create_splash_visual_feedback(position: Vector2, radius: float):
	"""Create very subtle visual feedback - no flashbang"""

	# Create gentle particle burst instead of bright rectangle
	var splash_particles = CPUParticles2D.new()
	var scene_root = Engine.get_main_loop().current_scene
	scene_root.add_child(splash_particles)

	splash_particles.global_position = position
	splash_particles.emitting = true
	splash_particles.amount = 20
	splash_particles.lifetime = 1.0
	splash_particles.one_shot = true
	splash_particles.explosiveness = 1.0

	# Gentle snow burst
	splash_particles.spread = 360.0  # All directions
	splash_particles.initial_velocity_min = 40.0
	splash_particles.initial_velocity_max = 80.0
	splash_particles.gravity = Vector2(0, 50)
	splash_particles.scale_amount_min = 0.4
	splash_particles.scale_amount_max = 1.0

	# Soft white/blue - no bright colors
	splash_particles.color = Color(0.8, 0.85, 1.0, 0.7)

	# Clean up after particles finish
	await scene_root.get_tree().create_timer(2.0).timeout
	if is_instance_valid(splash_particles):
		splash_particles.queue_free()
