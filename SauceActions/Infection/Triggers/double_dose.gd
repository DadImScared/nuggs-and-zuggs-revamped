class_name DoubleDoseTrigger
extends BaseTriggerAction

func _init():
	trigger_name = "double_dose"
	trigger_description = "20% chance when hitting infected enemy: spread to 2 nearby enemies"

func execute_trigger(source_bottle: ImprovedBaseSauceBottle, trigger_data: TriggerEffectResource) -> void:
	# Get the enemy that was hit from the trigger data
	var hit_enemy = trigger_data.effect_parameters.get("hit_enemy")
	if not hit_enemy or not is_instance_valid(hit_enemy):
		print("💉 Double Dose: No valid hit enemy")
		return

	# Get parameters
	var spread_count = trigger_data.effect_parameters.get("spread_count", 2)
	#var spread_radius = trigger_data.effect_parameters.get("spread_radius", 100.0)
	var spread_radius = source_bottle.effective_radius

	print("💉 Double Dose: Triggered on infected enemy hit!")

	# Find nearby enemies to spread to
	var nearby_enemies = get_enemies_in_radius(hit_enemy.global_position, spread_radius)
	var spread_targets = []

	# Filter for uninfected enemies
	for enemy in nearby_enemies:
		if enemy != hit_enemy and is_instance_valid(enemy):
			if not _is_enemy_infected(enemy):
				spread_targets.append(enemy)

	# Randomly select spread targets
	if spread_targets.size() == 0:
		print("💉 Double Dose: No valid spread targets found")
		return

	spread_targets.shuffle()
	var actual_spread_count = min(spread_count, spread_targets.size())

	# Spread infection to selected targets
	for i in range(actual_spread_count):
		var spread_target = spread_targets[i]
		_spread_infection_to_enemy(spread_target, source_bottle)
		# Use existing InfectionVisuals system
		InfectionVisuals.create_infection_spread_visual(
			hit_enemy.global_position,
			spread_target.global_position,
			source_bottle.sauce_data.sauce_color
		)

	print("💉 Double Dose: Spread infection to %d enemies from infected target" % actual_spread_count)
	log_trigger_executed(source_bottle, trigger_data)

func _is_enemy_infected(enemy: Node2D) -> bool:
	"""Check if an enemy is currently infected"""
	if not is_instance_valid(enemy):
		return false

	if enemy.has_method("has_status_effect"):
		return enemy.has_status_effect("infect")
	elif "active_effects" in enemy:
		return "infect" in enemy.active_effects

	return false

func _spread_infection_to_enemy(enemy: Node2D, source_bottle: ImprovedBaseSauceBottle):
	"""Spread infection to an enemy during double dose"""
	if enemy.has_method("apply_status_effect"):
		var intensity = source_bottle.effective_effect_intensity
		var duration = source_bottle.sauce_data.effect_duration

		enemy.apply_status_effect("infect", duration, intensity, source_bottle.bottle_id)

		# Set infection color
		if "active_effects" in enemy and "infect" in enemy.active_effects:
			enemy.active_effects["infect"]["color"] = source_bottle.sauce_data.sauce_color
