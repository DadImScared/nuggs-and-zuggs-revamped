# SauceActions/Burn/Triggers/thermal_shock.gd
class_name ThermalShockTrigger
extends BaseTriggerAction

func _init() -> void:
	trigger_name = "thermal_shock"
	trigger_description = "Deal instant damage when burns are first applied"

func execute_trigger(bottle: ImprovedBaseSauceBottle, data: EnhancedTriggerData):
	var enemy = data.effect_parameters.hit_enemy
	var projectile = data.effect_parameters.get("hit_projectile")

	if not enemy or not is_instance_valid(enemy):
		return

	# Only trigger if burns were applied this specific hit
	if not projectile or not "effects_applied_this_hit" in projectile:
		return

	if not "burn" in projectile.effects_applied_this_hit:
		return

	# Calculate thermal shock damage using enhanced burn data
	var thermal_multiplier = data.effect_parameters.get("thermal_shock_multiplier", 0.5)
	var burn_stacks = data.effect_parameters.get("burn_stacks", 1)
	var tick_damage = data.effect_parameters.get("tick_damage", 5.0)
	var duration = data.effect_parameters.get("duration", 5.0)
	var tick_interval = data.effect_parameters.get("tick_interval", 0.5)

	var total_ticks = duration / tick_interval
	var total_burn_damage = tick_damage * burn_stacks * total_ticks
	var thermal_damage = total_burn_damage * thermal_multiplier

	# Deal thermal shock damage
	var bottle_id = bottle.bottle_id if bottle else "thermal_shock"
	if enemy.has_method("take_damage_from_source"):
		enemy.take_damage_from_source(thermal_damage, bottle_id)
	elif enemy.has_method("take_damage"):
		enemy.take_damage(thermal_damage)

	# Create visual effect
	_create_thermal_shock_visual(enemy, thermal_damage)

	DebugControl.debug_status("⚡ Thermal Shock: %.1f instant damage!" % thermal_damage)

func _create_thermal_shock_visual(enemy: Node2D, damage: float):
	"""Create thermal shock visual effect"""
	if not enemy or not is_instance_valid(enemy):
		return

	var main_scene = Engine.get_main_loop().current_scene
	if not main_scene:
		return

	# Create bright flash
	var flash = ColorRect.new()
	flash.size = Vector2(40, 40)
	flash.position = enemy.global_position - flash.size/2
	flash.color = Color.WHITE
	flash.modulate = Color(2.5, 1.8, 0.8, 1.0)
	main_scene.add_child(flash)

	var flash_tween = flash.create_tween()
	flash_tween.parallel().tween_property(flash, "scale", Vector2(1.8, 1.8), 0.12)
	flash_tween.parallel().tween_property(flash, "modulate:a", 0.0, 0.12)
	flash_tween.tween_callback(flash.queue_free)

	# Create crackling particles
	for i in range(6):
		var particle = ColorRect.new()
		particle.size = Vector2(4, 4)
		particle.color = Color(1.4, 0.9, 0.4, 1.0)
		particle.position = enemy.global_position + Vector2(
			randf_range(-20, 20),
			randf_range(-20, 20)
		)
		main_scene.add_child(particle)

		var particle_tween = particle.create_tween()
		particle_tween.parallel().tween_property(particle, "position",
			enemy.global_position + Vector2(randf_range(-5, 5), randf_range(-5, 5)), 0.2)
		particle_tween.parallel().tween_property(particle, "modulate:a", 0.0, 0.2)
		particle_tween.tween_callback(particle.queue_free)
