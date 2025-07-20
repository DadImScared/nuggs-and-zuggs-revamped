# SauceActions/Fossilization/Triggers/fossilization_overflow.gd
class_name FossilizationOverflowTrigger
extends BaseAmberTrigger

func _init():
	trigger_name = "fossilization_overflow"
	trigger_description = "Hitting already-fossilized enemies creates amber explosions"

func should_trigger(source_bottle: ImprovedBaseSauceBottle, trigger_data: EnhancedTriggerData) -> bool:
	# Only trigger on hits against fossilized enemies
	var hit_enemy = trigger_data.effect_parameters.get("hit_enemy")
	if hit_enemy and is_instance_valid(hit_enemy):
		return is_enemy_fossilized(hit_enemy)  # Use base class method
	return false

func execute_trigger(source_bottle: ImprovedBaseSauceBottle, trigger_data: EnhancedTriggerData) -> void:
	var hit_enemy = trigger_data.effect_parameters.get("hit_enemy")
	var projectile = trigger_data.effect_parameters.get("projectile")

	if not hit_enemy or not is_instance_valid(hit_enemy):
		return

	print("💥 Fossilization Overflow! Amber explosion triggered!")

	# Get explosion parameters
	var explosion_radius = trigger_data.effect_parameters.get("explosion_radius", 120.0)
	var damage_multiplier = trigger_data.effect_parameters.get("explosion_damage_multiplier", 2.0)
	var spread_chance = trigger_data.effect_parameters.get("spread_fossilize_chance", 0.8)
	var amber_color = trigger_data.effect_parameters.get("amber_color", DEFAULT_AMBER_COLOR)

	# Create amber explosion
	_create_amber_explosion(hit_enemy.global_position, explosion_radius, damage_multiplier,
		spread_chance, source_bottle, amber_color)

func _create_amber_explosion(position: Vector2, radius: float, damage_multiplier: float,
	spread_chance: float, source_bottle: ImprovedBaseSauceBottle, amber_color: Color):
	"""Create amber explosion using existing visual and damage systems"""

	# Use existing explosion visual with amber color
	VisualEffectManager.create_explosion_visual(position, radius, amber_color)

	# Create amber particles using base class method
	create_fossilization_particles(position, amber_color)

	# Calculate explosion damage
	var explosion_damage = source_bottle.effective_damage * damage_multiplier

	# Get nearby enemies using base class method
	var nearby_enemies = get_nearby_enemies(position, radius)

	print("🔶 Amber explosion hit %d enemies in %.1f radius" % [nearby_enemies.size(), radius])

	for enemy in nearby_enemies:
		if not is_instance_valid(enemy):
			continue

		# Calculate distance-based damage falloff
		var distance = position.distance_to(enemy.global_position)
		var falloff_multiplier = 1.0 - (distance / radius)
		var final_damage = explosion_damage * falloff_multiplier

		# Deal damage
		if enemy.has_method("take_damage_from_source"):
			enemy.take_damage_from_source(final_damage, source_bottle.bottle_id)
		elif enemy.has_method("take_damage"):
			enemy.take_damage(final_damage)

		print("💥 Dealt %.1f damage to enemy at distance %.1f" % [final_damage, distance])

		# Apply fossilization to hit enemies using base class method
		if randf() < spread_chance:
			# Create a temporary TriggerEffectResource for the fossilization application
			var fossilize_trigger_resource = TriggerEffectResource.new()
			fossilize_trigger_resource.trigger_name = "fossilization_spread"
			fossilize_trigger_resource.trigger_type = TriggerEffectResource.TriggerType.ON_HIT
			fossilize_trigger_resource.effect_parameters["trigger_source"] = "overflow_explosion"
			fossilize_trigger_resource.effect_parameters["duration"] = DEFAULT_FOSSILIZE_DURATION
			fossilize_trigger_resource.effect_parameters["tick_damage"] = DEFAULT_TICK_DAMAGE
			fossilize_trigger_resource.effect_parameters["amber_color"] = amber_color
			fossilize_trigger_resource.effect_parameters["max_stacks"] = 3  # Overflow has lower limit
			fossilize_trigger_resource.effect_parameters["distance_factor"] = falloff_multiplier

			# Create EnhancedTriggerData from the resource
			var fossilize_trigger_data = EnhancedTriggerData.new(fossilize_trigger_resource)

			apply_fossilization_to_enemy(enemy, source_bottle, fossilize_trigger_data, 1)
			print("🔶 Spread fossilization to enemy at distance %.1f" % distance)
