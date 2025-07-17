class_name InfectionTsunamiTrigger
extends BaseTriggerAction

func _init():
	trigger_name = "infection_tsunami"
	trigger_description = "Every 15 seconds, all infections pulse simultaneously and spread"

func execute_trigger(source_bottle: ImprovedBaseSauceBottle, trigger_data: TriggerEffectResource) -> void:
	# Get parameters
	var pulse_radius = trigger_data.effect_parameters.get("pulse_radius", 120.0)
	var spread_chance = trigger_data.effect_parameters.get("spread_chance", 0.8)
	var pulse_damage_multiplier = trigger_data.effect_parameters.get("pulse_damage", 1.5)

	# Find all infected enemies
	var infected_enemies = _find_all_infected_enemies()

	if infected_enemies.size() == 0:
		print("🌊 Infection Tsunami: No infected enemies found")
		return

	print("🌊 Infection Tsunami: Pulsing %d infected enemies!" % infected_enemies.size())

	# Create visual effects
	_create_tsunami_visuals(infected_enemies, source_bottle.sauce_data.sauce_color)

	# Process each infected enemy
	for infected_enemy in infected_enemies:
		_process_tsunami_pulse(infected_enemy, pulse_radius, spread_chance, pulse_damage_multiplier, source_bottle)

	log_trigger_executed(source_bottle, trigger_data)

func _create_tsunami_visuals(infected_enemies: Array[Node2D], sauce_color: Color):
	"""Create the visual tsunami effect"""
	# Screen flash
	_create_screen_flash(sauce_color)

	# Pulse at each infected enemy
	for enemy in infected_enemies:
		if is_instance_valid(enemy):
			_create_pulse_effect(enemy.global_position, sauce_color)

func _find_all_infected_enemies() -> Array[Node2D]:
	"""Find all enemies that currently have infection status effect"""
	var infected_enemies: Array[Node2D] = []
	var all_enemies = Engine.get_main_loop().current_scene.get_tree().get_nodes_in_group("enemies")

	for enemy in all_enemies:
		if is_instance_valid(enemy):
			# Check if enemy has infection
			var has_infection = false
			if enemy.has_method("has_status_effect"):
				has_infection = enemy.has_status_effect("infect")
			elif "active_effects" in enemy:
				has_infection = "infect" in enemy.active_effects

			if has_infection:
				infected_enemies.append(enemy)

	return infected_enemies

func _create_screen_flash(color: Color):
	"""Create brief screen flash"""
	var flash = ColorRect.new()
	flash.size = Vector2(1920, 1080)
	flash.color = Color(color.r, color.g, color.b, 0.0)
	flash.global_position = Vector2.ZERO
	flash.z_index = 100

	Engine.get_main_loop().current_scene.add_child(flash)

	var tween = flash.create_tween()
	tween.tween_property(flash, "modulate:a", 0.15, 0.1)
	tween.tween_property(flash, "modulate:a", 0.0, 0.4)
	tween.tween_callback(flash.queue_free)

func _create_pulse_effect(position: Vector2, color: Color):
	"""Create pulse ring at position"""
	var pulse = ColorRect.new()
	pulse.size = Vector2(30, 30)
	pulse.color = Color(color.r, color.g, color.b, 0.8)
	pulse.global_position = position - Vector2(15, 15)

	Engine.get_main_loop().current_scene.add_child(pulse)

	var tween = pulse.create_tween()
	tween.parallel().tween_property(pulse, "size", Vector2(120, 120), 0.6)
	tween.parallel().tween_property(pulse, "global_position", position - Vector2(60, 60), 0.6)
	tween.parallel().tween_property(pulse, "modulate:a", 0.0, 0.6)
	tween.tween_callback(pulse.queue_free)

func _process_tsunami_pulse(infected_enemy: Node2D, pulse_radius: float, spread_chance: float, pulse_damage: float, source_bottle: ImprovedBaseSauceBottle):
	"""Process tsunami effects for one infected enemy"""
	if not is_instance_valid(infected_enemy):
		return

	# Deal bonus damage to the infected enemy
	if infected_enemy.has_method("take_damage_from_source"):
		var damage = source_bottle.effective_damage * pulse_damage
		infected_enemy.take_damage_from_source(damage, source_bottle.bottle_id)

	# Try to spread infection to nearby enemies
	var nearby_enemies = get_enemies_in_radius(infected_enemy.global_position, pulse_radius)

	for nearby_enemy in nearby_enemies:
		if nearby_enemy != infected_enemy and is_instance_valid(nearby_enemy):
			# Check if already infected
			var already_infected = false
			if nearby_enemy.has_method("has_status_effect"):
				already_infected = nearby_enemy.has_status_effect("infect")
			elif "active_effects" in nearby_enemy:
				already_infected = "infect" in nearby_enemy.active_effects

			# Try to spread with chance
			if not already_infected and randf() < spread_chance:
				_spread_infection_to_enemy(nearby_enemy, source_bottle)

func _spread_infection_to_enemy(enemy: Node2D, source_bottle: ImprovedBaseSauceBottle):
	"""Spread infection to an enemy during tsunami"""
	if enemy.has_method("apply_status_effect"):
		var intensity = source_bottle.effective_effect_intensity
		var duration = source_bottle.sauce_data.effect_duration

		enemy.apply_status_effect("infect", duration, intensity, source_bottle.bottle_id)

		# Set infection color
		if "active_effects" in enemy and "infect" in enemy.active_effects:
			enemy.active_effects["infect"]["color"] = source_bottle.sauce_data.sauce_color

		print("🌊 Tsunami spread infection to enemy")
