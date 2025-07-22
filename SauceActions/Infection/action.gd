# SauceActions/Infection/action.gd
class_name InfectionAction
extends BaseSauceAction

func _init():
	action_name = "infection"
	action_description = "Applies infection that spreads and deals damage over time"

func apply_action(projectile: Area2D, enemy: Node2D, source_bottle: ImprovedBaseSauceBottle) -> void:
	"""Main entry point - matches BaseSauceAction interface"""
	return
	var intensity = source_bottle.effective_effect_intensity
	var duration = source_bottle.sauce_data.effect_duration
	var final_duration = _get_modified_duration(duration, source_bottle)


	# Apply base infection to hit enemy
	_apply_infection_to_enemy(enemy, intensity, final_duration, source_bottle.bottle_id, source_bottle.sauce_data.sauce_color)

	# Check for special infection talents
	_process_infection_talents(enemy, source_bottle, intensity, final_duration)

	#print("🦠 Infection applied to enemy with intensity %.1f for %.1fs" % [intensity, duration])

func _process_infection_talents(enemy: Node2D, source_bottle: ImprovedBaseSauceBottle, intensity: float, duration: float):
	"""Process special infection effects from talents"""
	for special_effect in source_bottle.special_effects:
		match special_effect.effect_name:
			"infection_viral_spread":
				_create_viral_spread(enemy, special_effect, intensity, duration, source_bottle)
			"infection_mutation":
				_create_mutation_strain(enemy, special_effect, intensity, duration, source_bottle)
			"infection_epidemic":
				_create_epidemic_spread(enemy, special_effect, intensity, duration, 150.0, source_bottle)
			"infection_toxic_strain":
				_create_toxic_strain(enemy, special_effect, intensity, duration, source_bottle)
			"infection_pandemic":
				_create_pandemic_spread(enemy, special_effect, intensity, duration, source_bottle)

func _apply_infection_to_enemy(enemy: Node2D, intensity: float, duration: float, source_bottle_id: String, color: Color):
	"""Apply infection status effect to an enemy"""
	if enemy.has_method("apply_status_effect"):
		enemy.apply_status_effect("infect", duration, intensity, source_bottle_id)

		# Set infection color
		if "active_effects" in enemy and "infect" in enemy.active_effects:
			enemy.active_effects["infect"]["color"] = color
				# INCREMENT GLOBAL INFECTION COUNTER FOR EXTINCTION EVENT
		#if not "total_infections_this_run" in PlayerStats:
			#PlayerStats.total_infections_this_run = 0
#
		#PlayerStats.total_infections_this_run += 1

		#print("🦠 Applied infection to enemy: intensity=%.1f, duration=%.1fs" % [intensity, duration])

func _create_viral_spread(enemy: Node2D, talent: SpecialEffectResource, intensity: float, duration: float, source_bottle: ImprovedBaseSauceBottle):
	"""Create immediate viral spread to nearby enemies"""
	var spread_radius = talent.get_parameter("spread_radius", 100.0)
	var spread_count = talent.get_parameter("spread_count", 3)

	var nearby_enemies = get_enemies_in_radius(enemy.global_position, spread_radius)
	var infected_count = 0

	for nearby_enemy in nearby_enemies:
		if nearby_enemy != enemy and infected_count < spread_count:
			if not ("infect" in nearby_enemy.active_effects):
				_apply_infection_to_enemy(nearby_enemy, intensity * 0.8, duration, source_bottle.bottle_id, source_bottle.sauce_data.sauce_color)

				# Use InfectionVisuals for spread visual
				InfectionVisuals.create_infection_spread_visual(
					enemy.global_position,
					nearby_enemy.global_position,
					source_bottle.sauce_data.sauce_color
				)
				infected_count += 1

	#print("🦠 Viral Spread: Infected %d nearby enemies" % infected_count)

func _create_mutation_strain(enemy: Node2D, talent: SpecialEffectResource, intensity: float, duration: float, source_bottle: ImprovedBaseSauceBottle):
	"""Create mutating infection that stacks damage"""
	var mutation_rate = talent.get_parameter("mutation_rate", 1.5)
	var max_stacks = talent.get_parameter("max_stacks", 5)

	# Apply base infection first
	_apply_infection_to_enemy(enemy, intensity, 8.0, source_bottle.bottle_id, Color.GREEN)

	# Now apply mutation stacking - this will automatically modify the infection!
	if enemy.has_method("apply_stacking_effect"):
		var stack_count = enemy.apply_stacking_effect(
			"mutation_infection",
			intensity * mutation_rate,
			max_stacks,
			source_bottle.bottle_id,
			10.0  # duration
		)

		# Use InfectionVisuals for mutation visual
		InfectionVisuals.create_mutation_visual(enemy.global_position, Color.MAGENTA)

		#print("🧬 Mutation: Applied mutation stacking (%d/%d stacks from bottle %s)" % [stack_count, max_stacks, source_bottle.bottle_id])
	else:
		# Fallback for enemies without stacking support
		_apply_infection_to_enemy(enemy, intensity * mutation_rate, 6.0, source_bottle.bottle_id, Color.MAGENTA)
		#print("🧬 Mutation: Applied enhanced infection (no stacking support)")

func _create_epidemic_spread(enemy: Node2D, talent: SpecialEffectResource, intensity: float, duration: float, spread_radius: float, source_bottle: ImprovedBaseSauceBottle):
	"""Create epidemic that spreads in waves - FIXED VERSION"""
	var wave_count = talent.get_parameter("wave_count", 3)
	var wave_delay = talent.get_parameter("wave_delay", 0.5)

	#print("🌊 Epidemic: Starting %d waves with %.1fs delay" % [wave_count, wave_delay])

	# Create epidemic start visual
	InfectionVisuals.create_epidemic_start_visual(enemy.global_position, source_bottle.sauce_data.sauce_color)

	# Start epidemic wave system - FIXED
	_schedule_epidemic_waves(enemy, wave_count, wave_delay, intensity, duration, spread_radius, source_bottle)

func _get_modified_duration(base_duration: float, source_bottle: ImprovedBaseSauceBottle) -> float:
	"""Calculate infection duration with talent modifications"""
	var final_duration = base_duration

	# Check bottle's special effects for duration boost
	for effect in source_bottle.special_effects:
		if effect.effect_name == "infection_duration_boost":
			var multiplier = effect.get_parameter("duration_multiplier", 1.5)
			final_duration *= multiplier
			#print("🦠 Persistent Strain: Extending infection from %.1fs to %.1fs" % [base_duration, final_duration])

	return final_duration

func _schedule_epidemic_waves(enemy: Node2D, waves: int, delay: float, intensity: float, duration: float, radius: float, source_bottle: ImprovedBaseSauceBottle):
	"""Schedule multiple infection waves - SAFE implementation storing position not object"""
	if not is_instance_valid(enemy):
		#print("⚠️ Cannot schedule epidemic waves: invalid enemy")
		return

	# Store the position instead of the enemy object to avoid freed object issues
	var epicenter_position = enemy.global_position

	for wave in range(waves):
		var timer = Timer.new()
		timer.wait_time = delay * (wave + 1)
		timer.one_shot = true

		# Store position instead of enemy object to prevent freed object errors
		timer.set_meta("epicenter_position", epicenter_position)
		timer.set_meta("intensity", intensity * (1.0 - wave * 0.15))
		timer.set_meta("duration", duration)
		timer.set_meta("radius", radius)
		timer.set_meta("source_bottle", source_bottle)
		timer.set_meta("wave_number", wave + 1)

		# Simple connection without parameters
		timer.timeout.connect(_on_epidemic_timer_timeout.bind(timer))

		# Add timer to scene
		Engine.get_main_loop().current_scene.add_child(timer)
		timer.start()

func _on_epidemic_timer_timeout(timer: Timer):
	"""Handle epidemic timer timeout safely"""
	if not is_instance_valid(timer):
		return

	# Get stored metadata - now using position instead of object
	var epicenter_position = timer.get_meta("epicenter_position", Vector2.ZERO)
	var intensity = timer.get_meta("intensity", 0.0)
	var duration = timer.get_meta("duration", 0.0)
	var radius = timer.get_meta("radius", 0.0)
	var source_bottle = timer.get_meta("source_bottle", null)
	var wave_number = timer.get_meta("wave_number", 0)

	# Execute the wave using position instead of enemy object
	_execute_epidemic_wave_at_position(epicenter_position, intensity, duration, radius, source_bottle, wave_number)

	# Clean up timer
	timer.queue_free()

func _execute_epidemic_wave_at_position(epicenter_position: Vector2, intensity: float, duration: float, radius: float, source_bottle: ImprovedBaseSauceBottle, wave_number: int):
	"""Execute epidemic wave at a specific position (safer than using enemy object)"""
	# Validate source bottle
	if not source_bottle or not is_instance_valid(source_bottle):
		#print("⚠️ Epidemic wave %d: Source bottle no longer valid" % wave_number)
		return

	var nearby_enemies = get_enemies_in_radius(epicenter_position, radius)
	var infected_count = 0

	for nearby_enemy in nearby_enemies:
		if not is_instance_valid(nearby_enemy):
			continue

		# Check if enemy already has infection - use proper method
		var already_infected = false
		if nearby_enemy.has_method("has_status_effect"):
			already_infected = nearby_enemy.has_status_effect("infect")
		elif "active_effects" in nearby_enemy:
			already_infected = "infect" in nearby_enemy.active_effects

		if not already_infected:
			_apply_infection_to_enemy(nearby_enemy, intensity, duration, source_bottle.bottle_id, source_bottle.sauce_data.sauce_color)

			# Use InfectionVisuals for wave visual
			InfectionVisuals.create_infection_wave_visual(
				epicenter_position,
				nearby_enemy.global_position,
				source_bottle.sauce_data.sauce_color,
				radius
			)
			infected_count += 1

	#print("🌊 Epidemic wave %d: Infected %d enemies at position %s" % [wave_number, infected_count, epicenter_position])



func _create_toxic_strain(enemy: Node2D, talent: SpecialEffectResource, intensity: float, duration: float, source_bottle: ImprovedBaseSauceBottle):
	"""Create toxic strain that deals more damage"""
	var toxicity_multiplier = talent.get_parameter("toxicity_multiplier", 2.0)
	var toxic_duration = talent.get_parameter("toxic_duration", 8.0)

	# Apply both infection and poison
	_apply_infection_to_enemy(enemy, intensity, duration, source_bottle.bottle_id, source_bottle.sauce_data.sauce_color)

	if enemy.has_method("apply_status_effect"):
		enemy.apply_status_effect("poison", toxic_duration, intensity * toxicity_multiplier, source_bottle.bottle_id)

	# Use InfectionVisuals for toxic visual
	InfectionVisuals.create_toxic_strain_visual(enemy.global_position)

	#print("☠️ Toxic Strain: Applied infection + poison (%.1fx multiplier)" % toxicity_multiplier)

func _create_pandemic_spread(enemy: Node2D, talent: SpecialEffectResource, intensity: float, duration: float, source_bottle: ImprovedBaseSauceBottle):
	"""Create pandemic that can spread to entire screen"""
	var pandemic_range = talent.get_parameter("pandemic_range", 800.0)
	var infection_chance = talent.get_parameter("infection_chance", 0.3)

	var all_enemies = get_enemies_in_radius(enemy.global_position, pandemic_range)
	var infected_count = 0

	for target_enemy in all_enemies:
		if target_enemy != enemy and randf() < infection_chance:
			if not ("infect" in target_enemy.active_effects):
				_apply_infection_to_enemy(target_enemy, intensity * 0.6, duration, source_bottle.bottle_id, source_bottle.sauce_data.sauce_color)

				# Use InfectionVisuals for pandemic visual
				InfectionVisuals.create_pandemic_spread_visual(
					enemy.global_position,
					target_enemy.global_position,
					source_bottle.sauce_data.sauce_color
				)
				infected_count += 1

	#print("🌍 Pandemic: Infected %d enemies across the screen" % infected_count)

func get_enemies_in_radius(center: Vector2, radius: float) -> Array[Node2D]:
	"""Get all enemies within a certain radius of a position"""
	var enemies_in_radius: Array[Node2D] = []
	var all_enemies = Engine.get_main_loop().current_scene.get_tree().get_nodes_in_group("enemies")

	for enemy in all_enemies:
		if is_instance_valid(enemy):
			var distance = center.distance_to(enemy.global_position)
			if distance <= radius:
				enemies_in_radius.append(enemy)

	return enemies_in_radius
