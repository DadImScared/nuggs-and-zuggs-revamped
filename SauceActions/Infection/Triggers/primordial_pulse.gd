# SauceActions/Infection/Triggers/primordial_pulse.gd
class_name PrimordialPulseTrigger
extends BaseTriggerAction

func _init():
	trigger_name = "primordial_pulse"
	trigger_description = "Each tick of infection damage has 20% chance to spread to nearby enemy"

func execute_trigger(source_bottle: ImprovedBaseSauceBottle, trigger_data: TriggerEffectResource) -> void:
	# Get parameters from trigger data
	#var spread_radius = trigger_data.effect_parameters.get("spread_radius", 100.0)
	var spread_radius = source_bottle.effective_radius
	var infection_strength = trigger_data.effect_parameters.get("infection_strength", 1.0)
	var max_spreads = trigger_data.effect_parameters.get("max_spreads_per_tick", 1)

	# The triggering enemy is passed via effect_parameters by TriggerActionManager
	var triggering_enemy = trigger_data.effect_parameters.get("dot_enemy")
	if not triggering_enemy or not is_instance_valid(triggering_enemy):
		print("⚠️ Primordial Pulse: No valid triggering enemy")
		return

	print("🌋 Primordial Pulse: Triggered from infection tick on enemy")

	# Find nearby uninfected enemies
	var nearby_enemies = _get_enemies_in_radius(triggering_enemy.global_position, spread_radius)
	var uninfected_nearby = []

	for enemy in nearby_enemies:
		if enemy != triggering_enemy and not _is_infected(enemy):
			uninfected_nearby.append(enemy)

	if uninfected_nearby.size() == 0:
		print("🌋 Primordial Pulse: No uninfected enemies nearby")
		return

	# Spread to up to max_spreads nearby enemies
	var spread_count = 0
	uninfected_nearby.shuffle()  # Randomize which enemies get infected

	for enemy in uninfected_nearby:
		if spread_count >= max_spreads:
			break

		# Apply infection to this enemy
		_apply_infection_spread(enemy, source_bottle, infection_strength)
		spread_count += 1

	print("🌋 Primordial Pulse: Spread infection to %d nearby enemies" % spread_count)

	# Create visual effect
	_create_spread_visual(triggering_enemy.global_position, uninfected_nearby, spread_count)

	log_trigger_executed(source_bottle, trigger_data)

func _apply_infection_spread(target_enemy: Node2D, source_bottle: ImprovedBaseSauceBottle, strength_multiplier: float):
	"""Apply infection to a target enemy with modified strength"""
	if not target_enemy.has_method("apply_status_effect"):
		return

	# Calculate infection parameters
	var infection_intensity = source_bottle.effective_effect_intensity * strength_multiplier
	var infection_duration = source_bottle.sauce_data.effect_duration
	var bottle_id = source_bottle.bottle_id
	var infection_color = source_bottle.sauce_data.sauce_color

	# Apply the infection
	target_enemy.apply_status_effect("infect", infection_duration, infection_intensity, bottle_id)

	# Set infection color for visual consistency
	if "active_effects" in target_enemy and "infect" in target_enemy.active_effects:
		target_enemy.active_effects["infect"]["color"] = infection_color

	print("🌋 Primordial Pulse: Applied infection (%.1f intensity, %.1f duration)" % [infection_intensity, infection_duration])

func _is_infected(enemy: Node2D) -> bool:
	"""Check if an enemy is already infected"""
	if not enemy.has_method("has_status_effect"):
		# Fallback: check active_effects directly
		if "active_effects" in enemy:
			return "infect" in enemy.active_effects
		return false
	return enemy.has_status_effect("infect")

func _get_enemies_in_radius(center_position: Vector2, radius: float) -> Array:
	"""Get all enemies within a radius of the center position"""
	var enemies = []

	# Get all enemies from the scene using Engine instead of get_tree()
	var all_enemies = Engine.get_main_loop().current_scene.get_tree().get_nodes_in_group("enemies")

	for enemy in all_enemies:
		if not is_instance_valid(enemy):
			continue

		var distance = center_position.distance_to(enemy.global_position)
		if distance <= radius:
			enemies.append(enemy)

	return enemies

func _create_spread_visual(source_position: Vector2, nearby_enemies: Array, spread_count: int):
	"""Create visual effect showing infection spreading"""
	if spread_count == 0:
		return

	# Create small infection particles that spread outward
	for i in range(min(spread_count, 3)):  # Limit visual particles to 3
		if i < nearby_enemies.size():
			var target_position = nearby_enemies[i].global_position
			_create_infection_particle(source_position, target_position)

func _create_infection_particle(from_pos: Vector2, to_pos: Vector2):
	"""Create a small particle effect traveling from source to target"""
	# Get the main scene using Engine instead of get_tree()
	var main_scene = Engine.get_main_loop().current_scene
	if not main_scene:
		return

	# Create a simple particle that moves from source to target
	var particle = ColorRect.new()
	particle.size = Vector2(4, 4)
	particle.color = Color.GREEN
	particle.position = from_pos - particle.size / 2

	main_scene.add_child(particle)

	# Animate the particle movement
	var tween = particle.create_tween()
	tween.tween_property(particle, "position", to_pos - particle.size / 2, 0.3)
	tween.tween_callback(particle.queue_free)

	# Fade out as it travels
	var fade_tween = particle.create_tween()
	fade_tween.parallel().tween_property(particle, "modulate:a", 0.0, 0.3)
