# SauceActions/infection/infection_action.gd
class_name InfectionAction
extends BaseSauceAction

func _init():
	action_name = "infection"
	action_description = "Spreads viral infection that can jump to nearby enemies"

func apply_action(projectile: Area2D, enemy: Node2D, source_bottle: ImprovedBaseSauceBottle) -> void:
	# Get base infection parameters from bottle
	var infection_intensity = source_bottle.effective_effect_intensity
	var infection_duration = source_bottle.sauce_data.effect_duration
	var spread_radius = 120.0  # Base spread radius

	# Get talent modifications
	var talent_mods = get_talent_modifications(source_bottle)

	# Apply base infection to primary target
	_apply_infection_to_enemy(enemy, infection_intensity, infection_duration, source_bottle.bottle_id, source_bottle.sauce_data.sauce_color)

	# Apply talent modifications
	for mod in talent_mods:
		_apply_talent_modification(enemy, mod, infection_intensity, infection_duration, spread_radius, source_bottle)

	log_action_applied(enemy, talent_mods)

func _apply_infection_to_enemy(enemy: Node2D, intensity: float, duration: float, bottle_id: String, color: Color):
	"""Apply infection status effect to a single enemy"""
	if enemy.has_method("apply_status_effect"):
		enemy.apply_status_effect("infect", duration, intensity, bottle_id)

		# Set infection color for visual consistency
		if "infect" in enemy.active_effects:
			enemy.active_effects["infect"]["color"] = color

func _apply_talent_modification(enemy: Node2D, talent: SpecialEffectResource, intensity: float, duration: float, spread_radius: float, source_bottle: ImprovedBaseSauceBottle):
	"""Apply talent modifications to infection behavior"""
	match talent.effect_name:
		"infection_viral_spread":
			_create_immediate_spread(enemy, talent, intensity, duration, source_bottle)

		"infection_mutation":
			_create_mutation_effect(enemy, talent, intensity, source_bottle)

		"infection_epidemic":
			_create_epidemic_spread(enemy, talent, intensity, duration, spread_radius, source_bottle)

		"infection_toxic_strain":
			_create_toxic_strain(enemy, talent, intensity, duration, source_bottle)

		"infection_pandemic":
			_create_pandemic_spread(enemy, talent, intensity, duration, source_bottle)

func _create_immediate_spread(enemy: Node2D, talent: SpecialEffectResource, intensity: float, duration: float, source_bottle: ImprovedBaseSauceBottle):
	"""Immediately spread infection to nearby enemies on hit"""
	var spread_radius = talent.get_parameter("spread_radius", 100.0)
	var spread_count = talent.get_parameter("spread_count", 3)

	var nearby_enemies = get_enemies_in_radius(enemy.global_position, spread_radius)
	var spread_targets = 0

	for nearby_enemy in nearby_enemies:
		if nearby_enemy != enemy and spread_targets < spread_count:
			if not ("infect" in nearby_enemy.active_effects):
				_apply_infection_to_enemy(nearby_enemy, intensity * 0.8, duration, source_bottle.bottle_id, source_bottle.sauce_data.sauce_color)

				# Use InfectionVisuals instead of VisualEffectManager
				InfectionVisuals.create_infection_spread_visual(
					enemy.global_position,
					nearby_enemy.global_position,
					source_bottle.sauce_data.sauce_color
				)
				spread_targets += 1

	print("🦠 Viral Spread: Infected %d nearby enemies" % spread_targets)

func _create_mutation_effect(enemy: Node2D, talent: SpecialEffectResource, intensity: float, source_bottle: ImprovedBaseSauceBottle):
	"""Create mutating infection that gets stronger over time"""
	var mutation_rate = talent.get_parameter("mutation_rate", 1.5)
	var max_stacks = talent.get_parameter("max_stacks", 5)

	# Enhanced infection that stacks damage
	if enemy.has_method("apply_stacking_effect"):
		enemy.apply_stacking_effect("mutating_infection", intensity * mutation_rate, max_stacks, source_bottle.bottle_id)
		print("🧬 Mutation: Applied stacking infection with %.1fx multiplier" % mutation_rate)
	else:
		# Fallback: apply stronger infection
		_apply_infection_to_enemy(enemy, intensity * mutation_rate, 6.0, source_bottle.bottle_id, Color.MAGENTA)
		print("🧬 Mutation: Applied enhanced infection (fallback)")

	# Use InfectionVisuals for mutation visual
	InfectionVisuals.create_mutation_visual(enemy.global_position, Color.MAGENTA)

func _create_epidemic_spread(enemy: Node2D, talent: SpecialEffectResource, intensity: float, duration: float, spread_radius: float, source_bottle: ImprovedBaseSauceBottle):
	"""Create epidemic that spreads in waves"""
	var wave_count = talent.get_parameter("wave_count", 3)
	var wave_delay = talent.get_parameter("wave_delay", 0.5)

	print("🌊 Epidemic: Starting %d waves with %.1fs delay" % [wave_count, wave_delay])

	# Create epidemic start visual
	InfectionVisuals.create_epidemic_start_visual(enemy.global_position, source_bottle.sauce_data.sauce_color)

	# Start epidemic wave system
	_schedule_epidemic_waves(enemy, wave_count, wave_delay, intensity, duration, spread_radius, source_bottle)

func _schedule_epidemic_waves(enemy: Node2D, waves: int, delay: float, intensity: float, duration: float, radius: float, source_bottle: ImprovedBaseSauceBottle):
	"""Schedule multiple infection waves"""
	for wave in range(waves):
		var timer = Timer.new()
		timer.wait_time = delay * (wave + 1)
		timer.one_shot = true
		timer.timeout.connect(_execute_epidemic_wave.bind(enemy, intensity * (1.0 - wave * 0.15), duration, radius, source_bottle, wave + 1))

		# Add timer to scene
		Engine.get_main_loop().current_scene.add_child(timer)
		timer.start()

func _execute_epidemic_wave(epicenter: Node2D, intensity: float, duration: float, radius: float, source_bottle: ImprovedBaseSauceBottle, wave_number: int):
	"""Execute a single epidemic wave"""
	if not is_instance_valid(epicenter):
		print("⚠️ Epidemic wave %d: Epicenter no longer valid" % wave_number)
		return

	var nearby_enemies = get_enemies_in_radius(epicenter.global_position, radius)
	var infected_count = 0

	for nearby_enemy in nearby_enemies:
		if not ("infect" in nearby_enemy.active_effects):
			_apply_infection_to_enemy(nearby_enemy, intensity, duration, source_bottle.bottle_id, source_bottle.sauce_data.sauce_color)

			# Use InfectionVisuals for wave visual
			InfectionVisuals.create_infection_wave_visual(
				epicenter.global_position,
				nearby_enemy.global_position,
				source_bottle.sauce_data.sauce_color,
				radius
			)
			infected_count += 1

	print("🌊 Epidemic wave %d: Infected %d enemies" % [wave_number, infected_count])

func _create_toxic_strain(enemy: Node2D, talent: SpecialEffectResource, intensity: float, duration: float, source_bottle: ImprovedBaseSauceBottle):
	"""Create toxic strain that deals more damage"""
	var toxicity_multiplier = talent.get_parameter("toxicity_multiplier", 2.0)
	var toxic_duration = talent.get_parameter("toxic_duration", 8.0)

	# Apply both infection and poison
	_apply_infection_to_enemy(enemy, intensity * toxicity_multiplier, toxic_duration, source_bottle.bottle_id, Color.DARK_GREEN)

	# Also apply poison effect if enemy supports it
	if enemy.has_method("apply_status_effect"):
		enemy.apply_status_effect("poison", toxic_duration, intensity * 0.5, source_bottle.bottle_id)
		print("☠️ Toxic Strain: Applied infection + poison combo")
	else:
		print("☠️ Toxic Strain: Applied enhanced infection (no poison support)")

	# Use InfectionVisuals for toxic strain visual
	InfectionVisuals.create_toxic_strain_visual(enemy.global_position)

func _create_pandemic_spread(enemy: Node2D, talent: SpecialEffectResource, intensity: float, duration: float, source_bottle: ImprovedBaseSauceBottle):
	"""Create pandemic that spreads to entire screen"""
	var pandemic_range = talent.get_parameter("pandemic_range", 800.0)
	var infection_chance = talent.get_parameter("infection_chance", 0.3)

	var all_enemies = get_enemies_in_radius(enemy.global_position, pandemic_range)
	var infected_count = 0

	for potential_target in all_enemies:
		if potential_target != enemy and randf() < infection_chance:
			if not ("infect" in potential_target.active_effects):
				_apply_infection_to_enemy(potential_target, intensity * 0.6, duration, source_bottle.bottle_id, source_bottle.sauce_data.sauce_color)

				# Use InfectionVisuals for pandemic visual
				InfectionVisuals.create_pandemic_spread_visual(
					enemy.global_position,
					potential_target.global_position,
					source_bottle.sauce_data.sauce_color
				)
				infected_count += 1

	print("🔥 Pandemic: Infected %d enemies across the screen!" % infected_count)
