# SauceActions/Cold/Triggers/frozen_winds.gd
class_name FrozenWindsTrigger
extends BaseTriggerAction

func _init() -> void:
	trigger_name = "frozen_winds"
	trigger_description = "Unleash freezing winds that damage and push back enemies in a radius"

func execute_trigger(bottle: ImprovedBaseSauceBottle, data: EnhancedTriggerData):
	var enemy = data.effect_parameters.hit_enemy

	if not enemy or not is_instance_valid(enemy):
		return

	# Get parameters from trigger data
	var damage = data.effect_parameters.get("damage", 25)
	var radius = data.effect_parameters.get("radius", 100)
	var force = data.effect_parameters.get("force", 20)
	var stacks = data.effect_parameters.get("stacks", 6)

	# Get wind center position from hit enemy
	var wind_center = enemy.global_position

	# Apply damage and effects to all enemies in radius
	var enemies_in_radius = get_enemies_in_radius(wind_center, radius)

	for target_enemy in enemies_in_radius:
		if not is_instance_valid(target_enemy):
			continue

		# Apply damage
		if target_enemy.has_method("take_damage_from_source"):
			target_enemy.take_damage_from_source(damage, bottle.bottle_id)
		elif target_enemy.has_method("take_damage"):
			target_enemy.take_damage(damage)

		# Apply cold stacks using the Effects system
		if Effects.cold:
			var cold_params = {
				"duration": 5.0,
				"max_stacks": 6,
				"stack_value": 1.0,
				"slow_per_stack": 0.15,
				"freeze_threshold": 6,
				"cold_color": Color(0.7, 0.9, 1.0, 0.8)
			}
			Effects.cold.apply_from_talent(target_enemy, bottle, stacks, cold_params)

		# Apply knockback force
		#_apply_knockback_force(target_enemy, wind_center, force)

	# Create visual effect for the frozen winds
	_create_frozen_winds_visual.call_deferred(wind_center, radius)

	DebugControl.debug_status("🌬️ Frozen Winds: %d enemies affected in radius %.0f" % [enemies_in_radius.size(), radius])

func _apply_knockback_force(target_enemy: Node2D, wind_center: Vector2, force: float):
	"""Apply knockback force pushing enemies away from wind center"""
	var direction = (target_enemy.global_position - wind_center).normalized()

	# Apply force based on distance (closer = more force)
	var distance = wind_center.distance_to(target_enemy.global_position)
	var max_distance = 100.0  # Max knockback distance
	var force_multiplier = 1.0 - (distance / max_distance)
	force_multiplier = max(force_multiplier, 0.1)  # Minimum 10% force

	# Increase base force significantly and apply multiplier
	var final_force = force * 30.0 * force_multiplier  # Much stronger knockback

	# Apply the external velocity if enemy supports it
	if target_enemy.has_method("apply_external_velocity"):
		target_enemy.apply_external_velocity(direction * final_force)
		DebugControl.debug_status("💨 Knockback applied: %.1f force to enemy at distance %.1f" % [final_force, distance])
	elif "velocity" in target_enemy:
		target_enemy.velocity += direction * final_force

func _create_frozen_winds_visual(center: Vector2, radius: float):
	"""Create visual effect for frozen winds"""
	var scene = Engine.get_main_loop().current_scene

	# Create base explosion effect with ice color
	VisualEffectManager.create_explosion_visual(center, radius, Color(0.7, 0.9, 1.0, 0.6))

	# Create swirling ice particles directly
	var particle_count = 12
	for i in range(particle_count):
		var angle = (i / float(particle_count)) * TAU
		var spawn_radius = radius * 0.3
		var spawn_pos = center + Vector2.RIGHT.rotated(angle) * spawn_radius

		# Create ice crystal effect
		var ice_crystal_scene = preload("res://Effects/IceCrystal/ice_crystal.tscn")
		if ice_crystal_scene:
			var ice_crystal = ice_crystal_scene.instantiate()
			if ice_crystal:
				scene.add_child(ice_crystal)
				ice_crystal.global_position = spawn_pos
				ice_crystal.modulate = Color(0.8, 0.95, 1.0, 0.9)

				# Create spiral motion using tween
				var tween = ice_crystal.create_tween()
				var spiral_duration = 1.5
				var points_per_revolution = 8
				var revolutions = 2
				var total_points = points_per_revolution * revolutions

				# Create sequential spiral movement
				for j in range(total_points):
					var progress = j / float(total_points)
					var spiral_angle = angle + (progress * revolutions * TAU)
					var spiral_radius = spawn_radius + (progress * radius * 0.7)
					var point = center + Vector2.RIGHT.rotated(spiral_angle) * spiral_radius
					var step_duration = spiral_duration / total_points

					tween.tween_property(ice_crystal, "global_position", point, step_duration)

				tween.parallel().tween_property(ice_crystal, "modulate:a", 0.0, 0.5)
				tween.tween_callback(ice_crystal.queue_free)

	# Create wind lines
	_create_wind_lines(center, radius)

func _create_wind_particles(center: Vector2, radius: float):
	"""Create particle effects around the wind area"""
	# This is now handled in _create_frozen_winds_visual()
	pass

func _create_wind_lines(center: Vector2, radius: float):
	"""Create visual wind lines emanating from center"""
	var scene = Engine.get_main_loop().current_scene
	var line_count = 6

	for i in range(line_count):
		var angle = (i / float(line_count)) * TAU
		var start_pos = center + Vector2.RIGHT.rotated(angle) * (radius * 0.2)
		var end_pos = center + Vector2.RIGHT.rotated(angle) * radius

		# Create a simple line effect using a ColorRect
		var line = ColorRect.new()
		line.color = Color(0.8, 0.95, 1.0, 0.7)
		line.size = Vector2(2, start_pos.distance_to(end_pos))
		scene.add_child(line)

		# Position and rotate the line
		line.global_position = start_pos
		line.rotation = angle + PI/2  # Perpendicular to direction

		# Animate the line
		var tween = line.create_tween()
		tween.tween_property(line, "modulate:a", 0.0, 0.8)
		tween.tween_callback(line.queue_free)

func should_trigger_on_hit(source_bottle: ImprovedBaseSauceBottle, trigger_data: EnhancedTriggerData, hit_enemy: Node2D, projectile: Area2D = null) -> bool:
	"""Override to check specific conditions for frozen winds"""
	if trigger_data.trigger_type != TriggerEffectResource.TriggerType.ON_HIT:
		return false

	# Check chance
	var chance = trigger_data.trigger_condition.get("chance", 1.0)
	if randf() > chance:
		return false

	return true
