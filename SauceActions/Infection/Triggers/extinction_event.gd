class_name ExtinctionEventTrigger
extends BaseTriggerAction

func _init():
	trigger_name = "extinction_event"
	trigger_description = "Massive infection explosion every 5th shot after 100 total infections"

func execute_trigger(source_bottle: ImprovedBaseSauceBottle, trigger_data: EnhancedTriggerData) -> void:
	var explosion_radius = trigger_data.effect_parameters.get("explosion_radius", 200.0)
	var damage_multiplier = trigger_data.effect_parameters.get("damage_multiplier", 2.0)
	var infection_chance = trigger_data.effect_parameters.get("infection_chance", 0.8)
	var infection_duration = trigger_data.effect_parameters.get("infection_duration", 4.0)
	var infection_damage_ratio = trigger_data.effect_parameters.get("infection_damage_ratio", 0.5)

	var explosion_position = source_bottle.current_target.global_position if source_bottle.current_target else source_bottle.global_position
	var explosion_damage = source_bottle.effective_damage * damage_multiplier

	# Create dramatic visual effect
	_create_extinction_explosion_visual(explosion_position, explosion_radius)

	# Find all enemies in explosion radius
	var enemies = source_bottle.get_tree().get_nodes_in_group("enemies")
	var enemies_hit = 0

	for enemy in enemies:
		if not is_instance_valid(enemy):
			continue

		var distance = explosion_position.distance_to(enemy.global_position)
		if distance <= explosion_radius:
			enemies_hit += 1

			# Deal explosion damage with bottle attribution
			if enemy.has_method("take_damage_from_source"):
				enemy.take_damage_from_source(explosion_damage, source_bottle.bottle_id)
			elif enemy.has_method("take_damage"):
				enemy.take_damage(explosion_damage)

			# Apply infection chance directly to enemy
			if randf() < infection_chance:
				var infection_intensity = source_bottle.effective_damage * infection_damage_ratio
				if enemy.has_method("apply_status_effect"):
					enemy.apply_status_effect("infect", infection_duration, infection_intensity, source_bottle.bottle_id)

					# Set infection color
					if "active_effects" in enemy and "infect" in enemy.active_effects:
						enemy.active_effects["infect"]["color"] = source_bottle.sauce_data.sauce_color

	#print("💥 EXTINCTION EVENT! Hit %d enemies with %.1f damage at %s" % [enemies_hit, explosion_damage, explosion_position])
	log_trigger_executed(source_bottle, trigger_data)

func should_trigger(source_bottle: ImprovedBaseSauceBottle, trigger_data: EnhancedTriggerData) -> bool:
	# Check infection threshold first
	var infection_threshold = trigger_data.trigger_condition.get("infection_threshold", 100)

	# Add the counter to PlayerStats if it doesn't exist
	if not "total_infections_this_run" in PlayerStats:
		PlayerStats.total_infections_this_run = 0

	var total_infections = PlayerStats.total_infections_this_run

	if total_infections < infection_threshold:
		return false  # Not enough infections yet

	# Then check shot count interval
	var shot_interval = trigger_data.trigger_condition.get("interval", 5)
	return source_bottle.shot_counter % shot_interval == 0

func _create_extinction_explosion_visual(position: Vector2, radius: float):
	"""Create dramatic extinction explosion visual effect"""
	var explosion_effect = Node2D.new()
	explosion_effect.global_position = position
	explosion_effect.z_index = 10

	# Add to scene
	var scene = Engine.get_main_loop().current_scene
	scene.add_child(explosion_effect)

	# Create multiple expanding rings for dramatic effect
	for i in range(3):
		var ring = _create_explosion_ring(radius * (1.0 - i * 0.3), Color.RED.lerp(Color.YELLOW, i * 0.5))
		explosion_effect.add_child(ring)

		# Animate each ring with slight delay
		var tween = explosion_effect.create_tween()
		ring.scale = Vector2.ZERO
		ring.modulate.a = 0.8

		tween.parallel().tween_property(ring, "scale", Vector2.ONE, 0.4 + i * 0.1)
		tween.parallel().tween_property(ring, "modulate:a", 0.0, 0.4 + i * 0.1)

	# Screen shake effect
	_create_screen_shake(0.3, 8.0)

	# Clean up after animation
	var cleanup_timer = Timer.new()
	cleanup_timer.wait_time = 1.0
	cleanup_timer.one_shot = true
	cleanup_timer.timeout.connect(func(): explosion_effect.queue_free())
	explosion_effect.add_child(cleanup_timer)
	cleanup_timer.start()

func _create_explosion_ring(radius: float, color: Color) -> ColorRect:
	"""Create a single explosion ring"""
	var ring = ColorRect.new()
	ring.size = Vector2(radius * 2, radius * 2)
	ring.position = Vector2(-radius, -radius)
	ring.color = color
	return ring

func _create_screen_shake(duration: float, intensity: float):
	"""Create screen shake effect"""
	var camera = Engine.get_main_loop().current_scene.get_viewport().get_camera_2d()
	if not camera:
		return

	var original_position = camera.global_position
	var shake_tween = camera.create_tween()

	for i in range(int(duration * 20)):  # 20 FPS shake
		var shake_offset = Vector2(
			randf_range(-intensity, intensity),
			randf_range(-intensity, intensity)
		)
		shake_tween.parallel().tween_property(camera, "global_position", original_position + shake_offset, 1.0/20.0)

	# Return to original position
	shake_tween.tween_property(camera, "global_position", original_position, 0.1)
