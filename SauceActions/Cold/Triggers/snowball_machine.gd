# SauceActions/Cold/Triggers/snowball_machine.gd
class_name SnowballMachineTrigger
extends BaseTriggerAction

# Preload the snowball scene
const SNOWBALL_SCENE = preload("res://Effects/Snowball/snowball.tscn")

func _init() -> void:
	trigger_name = "snowball_machine"
	trigger_description = "Fires snowballs in different directions every second"

func execute_trigger(bottle: ImprovedBaseSauceBottle, data: EnhancedTriggerData):
	"""Find marked enemies and fire snowballs from their positions"""

	# Get parameters from trigger data
	var damage = data.effect_parameters.get("damage", 15)
	var duration = data.effect_parameters.get("duration", 5)
	var splash_radius = data.effect_parameters.get("splash_radius", 100)
	var splash_damage_multiplier = data.effect_parameters.get("splash_damage", 0.5)
	var num_balls = data.effect_parameters.get("balls", 4)

	# Find all marked enemies in range
	var marked_enemies = _find_marked_enemies_in_range(bottle, 800.0)  # Large range

	if marked_enemies.is_empty():
		DebugControl.debug_status("⚙️❄️ No marked enemies found for Snowball Machine")
		return

	DebugControl.debug_status("⚙️❄️ Snowball Machine activated! %d marked enemies firing snowballs" % marked_enemies.size())

	# Fire snowballs from each marked enemy position
	for enemy in marked_enemies:
		if not is_instance_valid(enemy):
			continue

		var machine_position = enemy.global_position

		# Create visual effect at marked enemy position
		_create_machine_pulse_visual(machine_position)

		# Calculate spread directions (evenly spaced around circle)
		var angle_step = TAU / num_balls  # 2π / count = even spread

		for i in range(num_balls):
			var direction_angle = angle_step * i
			var direction = Vector2.RIGHT.rotated(direction_angle)
			var target_position = machine_position + (direction * 300.0)  # Fixed range

			# Spawn machine snowball from marked enemy position
			call_deferred("_spawn_machine_snowball", machine_position, target_position, damage,
						  splash_radius, splash_damage_multiplier, bottle, duration)

	# Log the execution
	log_trigger_executed(bottle, data)

func _find_marked_enemies_in_range(bottle: ImprovedBaseSauceBottle, range: float) -> Array:
	"""Find all enemies in range that have mark from this bottle"""
	var marked_enemies = []
	var all_enemies = Engine.get_main_loop().current_scene.get_tree().get_nodes_in_group("enemies")
	var bottle_position = bottle.global_position
	var mark_key = "mark_of_winter"


	for enemy in all_enemies:
		if not is_instance_valid(enemy):
			continue
		# Check if enemy is in range
		var distance = bottle_position.distance_to(enemy.global_position)
		if distance > range:
			continue

		# Check if enemy has mark from this bottle
		if "stacking_effects" in enemy and enemy.stacking_effects.has(mark_key):
			marked_enemies.append(enemy)

	return marked_enemies

func _spawn_machine_snowball(spawn_pos: Vector2, target_pos: Vector2, damage: float,
							  splash_radius: float, splash_damage_mult: float, source_bottle: Node, duration: float = 5.0):
	"""Spawn a machine snowball that flies in a fixed direction"""

	var snowball = SNOWBALL_SCENE.instantiate()
	var scene_root = Engine.get_main_loop().current_scene
	scene_root.call_deferred("add_child", snowball)

	# Initialize the snowball
	snowball.call_deferred("initialize", spawn_pos, target_pos, damage, splash_radius, splash_damage_mult)

	# Mark as machine snowball for visual distinction
	snowball.set_meta("machine_snowball", true)
	snowball.set_meta("source_bottle", source_bottle)

	# Connect explosion signal
	snowball.call_deferred("connect", "snowball_exploded", _on_machine_snowball_exploded.bind(source_bottle, duration))

	DebugControl.debug_status("⚙️❄️ Machine snowball fired")

func _on_machine_snowball_exploded(explosion_position: Vector2, splash_radius: float, splash_damage: float, source_bottle: Node, duration: float):
	"""Handle machine snowball explosion"""

	# Find enemies in splash radius
	var enemies_in_splash = _find_nearby_enemies(explosion_position, splash_radius)
	DebugControl.debug_status("⚙️❄️ Machine snowball exploded! Hitting %d enemies" % enemies_in_splash.size())

	# Apply effects to all enemies in splash
	for enemy in enemies_in_splash:
		if not is_instance_valid(enemy) or not enemy.has_method("take_damage_from_source"):
			continue

		# Apply splash damage
		var bottle_id = source_bottle.bottle_id if source_bottle else "machine_snowball"
		enemy.take_damage_from_source(splash_damage, bottle_id)

		# Apply cold effects (1 stack for machine snowballs)
		_apply_cold_to_enemy(enemy, source_bottle, 1)

		# Apply mark of winter for potential death triggers
		if Effects and Effects.cold:
			Effects.cold.apply_mark(enemy, "mark_of_winter", source_bottle, duration)

	# Create visual feedback
	_create_splash_visual_feedback(explosion_position, splash_radius)

func _apply_cold_to_enemy(enemy: Node, source_bottle: Node, cold_stacks: int):
	"""Apply cold stacks to enemy hit by machine snowball"""
	if not enemy or not is_instance_valid(enemy):
		return

	# Cold parameters for machine snowballs
	var enhanced_params = {
		"duration": 3.0,  # Shorter than normal
		"tick_interval": 0.0,
		"tick_damage": 0.0,
		"max_stacks": 6,
		"stack_value": 1.0,
		"slow_per_stack": 0.15,
		"freeze_threshold": 6,
		"cold_color": Color(0.7, 0.9, 1.0, 0.8),
		"tick_effect": null
	}

	# Use the Effects system to apply cold
	if Effects and Effects.cold:
		Effects.cold.apply_from_talent(enemy, source_bottle, cold_stacks, enhanced_params)
		DebugControl.debug_status("❄️ Applied %d cold stacks to enemy from machine snowball" % cold_stacks)

func _create_machine_pulse_visual(position: Vector2):
	"""Create visual effect for snowball machine pulse"""
	var pulse_particles = CPUParticles2D.new()
	var scene_root = Engine.get_main_loop().current_scene
	scene_root.add_child(pulse_particles)

	pulse_particles.global_position = position
	pulse_particles.emitting = true
	pulse_particles.amount = 20
	pulse_particles.lifetime = 0.8
	pulse_particles.one_shot = true
	pulse_particles.explosiveness = 1.0

	# Pulsing ring effect
	pulse_particles.spread = 360.0
	pulse_particles.initial_velocity_min = 40.0
	pulse_particles.initial_velocity_max = 80.0
	pulse_particles.color = Color(0.8, 0.9, 1.0, 0.9)
	pulse_particles.scale_amount_min = 0.4
	pulse_particles.scale_amount_max = 0.8

	# Clean up
	await scene_root.get_tree().create_timer(1.5).timeout
	if is_instance_valid(pulse_particles):
		pulse_particles.queue_free()

func _create_splash_visual_feedback(position: Vector2, radius: float):
	"""Create visual feedback for machine snowball explosion"""

	var splash_particles = CPUParticles2D.new()
	var scene_root = Engine.get_main_loop().current_scene
	scene_root.add_child(splash_particles)

	splash_particles.global_position = position
	splash_particles.emitting = true
	splash_particles.amount = 15
	splash_particles.lifetime = 0.8
	splash_particles.one_shot = true
	splash_particles.explosiveness = 1.0

	# Smaller burst for machine snowballs
	splash_particles.spread = 360.0
	splash_particles.initial_velocity_min = 30.0
	splash_particles.initial_velocity_max = 60.0
	splash_particles.gravity = Vector2(0, 40)
	splash_particles.scale_amount_min = 0.3
	splash_particles.scale_amount_max = 0.6
	splash_particles.color = Color(0.8, 0.85, 1.0, 0.7)

	# Clean up
	await scene_root.get_tree().create_timer(1.5).timeout
	if is_instance_valid(splash_particles):
		splash_particles.queue_free()

func _find_nearby_enemies(center: Vector2, radius: float) -> Array:
	"""Find enemies within range"""
	var enemies = []
	var enemy_group = Engine.get_main_loop().get_nodes_in_group("enemies")

	for enemy in enemy_group:
		if not is_instance_valid(enemy):
			continue

		var distance = center.distance_to(enemy.global_position)
		if distance <= radius:
			enemies.append(enemy)

	return enemies
