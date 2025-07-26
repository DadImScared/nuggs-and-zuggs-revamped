# SauceActions/Burn/Triggers/cambrian_explosion.gd
class_name CambrianExplosionAction
extends BaseTriggerAction

func _init():
	trigger_name = "cambrian_explosion"
	trigger_description = "Shooting burning enemies spreads burns to nearby fresh targets"

func execute_trigger(source_bottle: ImprovedBaseSauceBottle, trigger_data: EnhancedTriggerData):
	"""Execute Cambrian Explosion - spread burns from shot burning enemy"""
	var params = trigger_data.effect_parameters
	var hit_enemy = params.get("hit_enemy")

	if not hit_enemy or not is_instance_valid(hit_enemy):
		return

	# Find the nearest non-burning enemy
	var spread_radius = params.get("spread_radius", 150.0)
	var spread_burn_stacks = params.get("spread_burn_stacks", 1)

	var nearest_enemy = _find_nearest_target(hit_enemy, spread_radius)

	if not nearest_enemy:
		return

	# Apply burn to the nearest enemy
	Effects.burn.apply_from_talent(
		nearest_enemy,
		source_bottle,
		spread_burn_stacks
	)

	# Create visual effect
	_create_cambrian_burst_visual(hit_enemy, nearest_enemy)

	DebugControl.debug_status("🦕 Cambrian Explosion: Spread burn from %s to %s" % [
		_get_enemy_name(hit_enemy),
		_get_enemy_name(nearest_enemy)
	])

func _find_nearest_target(center_enemy: Node2D, radius: float) -> Node2D:
	"""Find the nearest enemy within radius, prioritizing non-burning targets"""
	var all_enemies = Engine.get_main_loop().current_scene.get_tree().get_nodes_in_group("enemies")
	var center_pos = center_enemy.global_position
	var nearest_non_burning = null
	var nearest_burning = null
	var nearest_non_burning_dist = radius + 1.0
	var nearest_burning_dist = radius + 1.0

	for enemy in all_enemies:
		if not is_instance_valid(enemy) or enemy == center_enemy:
			continue

		var distance = center_pos.distance_to(enemy.global_position)
		if distance > radius:
			continue

		if _is_enemy_burning(enemy):
			if distance < nearest_burning_dist:
				nearest_burning_dist = distance
				nearest_burning = enemy
		else:
			if distance < nearest_non_burning_dist:
				nearest_non_burning_dist = distance
				nearest_non_burning = enemy

	# Prioritize non-burning enemies, fallback to burning ones
	return nearest_non_burning if nearest_non_burning else nearest_burning

func _is_enemy_burning(enemy: Node2D) -> bool:
	"""Check if enemy is currently burning"""
	if not is_instance_valid(enemy):
		return false

	if enemy.has_method("get_total_stack_count"):
		return enemy.get_total_stack_count("burn") > 0
	elif enemy.has_method("has_status_effect"):
		return enemy.has_status_effect("burn")
	elif "active_effects" in enemy:
		return "burn" in enemy.active_effects

	return false

func _create_cambrian_burst_visual(from_enemy: Node2D, to_enemy: Node2D):
	"""Create visual effect showing the Cambrian explosion spread"""
	var main_scene = Engine.get_main_loop().current_scene
	if not main_scene:
		return

	# Create a burst effect at the source
	var burst_particle = ColorRect.new()
	burst_particle.size = Vector2(16, 16)
	burst_particle.color = Color(1.0, 0.7, 0.2, 0.8)  # Bright orange-yellow
	burst_particle.position = from_enemy.global_position - burst_particle.size / 2

	main_scene.add_child(burst_particle)

	# Burst expansion animation
	var burst_tween = burst_particle.create_tween()
	burst_tween.parallel().tween_property(burst_particle, "scale", Vector2(3.0, 3.0), 0.3)
	burst_tween.parallel().tween_property(burst_particle, "modulate:a", 0.0, 0.3)
	burst_tween.tween_callback(burst_particle.queue_free)

	# Create spreading particle
	var spread_particle = ColorRect.new()
	spread_particle.size = Vector2(6, 6)
	spread_particle.color = Color(1.0, 0.5, 0.0, 0.9)  # Orange
	spread_particle.position = from_enemy.global_position - spread_particle.size / 2

	main_scene.add_child(spread_particle)

	# Animate particle traveling to target
	var travel_tween = spread_particle.create_tween()
	travel_tween.tween_property(spread_particle, "position", to_enemy.global_position - spread_particle.size / 2, 0.25)
	travel_tween.tween_callback(spread_particle.queue_free)

	# Fade the traveling particle
	var fade_tween = spread_particle.create_tween()
	fade_tween.parallel().tween_property(spread_particle, "modulate:a", 0.0, 0.25)

func _get_enemy_name(enemy: Node2D) -> String:
	"""Get a readable name for the enemy for debug purposes"""
	if "dummy_name" in enemy:
		return enemy.dummy_name
	elif enemy.name:
		return enemy.name
	else:
		return "Enemy"
