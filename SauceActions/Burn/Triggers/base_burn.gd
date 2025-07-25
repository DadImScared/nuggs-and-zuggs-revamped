# SauceActions/Burn/Triggers/base_burn.gd
class_name BaseBurnTrigger
extends BaseTriggerAction

func _init() -> void:
	trigger_name = "burn"
	trigger_description = "Applies burning damage over time that stacks"

func execute_trigger(bottle: ImprovedBaseSauceBottle, data: EnhancedTriggerData):
	var enemy = data.effect_parameters.hit_enemy
	if not enemy or not is_instance_valid(enemy):
		DebugControl.debug_status("⚠️ Burn: No valid enemy to burn")
		return

	# Get enhancement values from Slow Burn and other talents
	var burn_stacks = data.effect_parameters.get("burn_stacks", 1)
	var duration_mult = data.effect_parameters.get("duration", 1.0)
	var tick_interval_mult = data.effect_parameters.get("tick_interval", 1.0)
	var damage_mult = data.effect_parameters.get("tick_damage", 1.0)

	# Calculate enhanced values using actual StackingEffect properties
	var enhanced_duration = Effects.burn.base_duration * duration_mult
	var enhanced_tick_interval = Effects.burn.base_tick_interval * tick_interval_mult
	var enhanced_tick_damage = Effects.burn.base_tick_damage * damage_mult

	# Apply burn directly with enhanced values (no global modification needed)
	enemy.apply_stacking_effect(
		"burn",
		Effects.burn.base_stack_value * burn_stacks,
		Effects.burn.base_max_stacks,
		bottle.bottle_id,
		enhanced_duration,
		{
			"immediate_effect": Effects.burn._create_immediate_effect(enemy, Effects.burn.base_color, {"stacks": burn_stacks}),
			"tick_effect": _create_enhanced_tick_effect(enemy, bottle, enhanced_tick_damage),
			"visual_cleanup": Effects.burn._create_visual_cleanup(enemy),
			"tick_interval": enhanced_tick_interval
		}
	)

	if duration_mult != 1.0 or tick_interval_mult != 1.0:
		DebugControl.debug_status("🔥 Applied %d enhanced burn stacks (×%.1f duration, ×%.1f interval)" % [burn_stacks, duration_mult, tick_interval_mult])
	else:
		DebugControl.debug_status("🔥 Applied %d burn stacks" % burn_stacks)

func _create_enhanced_tick_effect(enemy: Node2D, source_bottle: Node, enhanced_tick_damage: float) -> Callable:
	"""Create tick effect with pre-enhanced damage"""
	return func():
		if not is_instance_valid(enemy):
			return

		var total_stacks = enemy.get_total_stack_count("burn")
		var final_damage = enhanced_tick_damage * total_stacks  # Use pre-enhanced damage
		var bottle_id = source_bottle.bottle_id if source_bottle else "burn"
		enemy.take_damage_from_source(final_damage, bottle_id)

		# Create burn particle effect
		_create_burn_particle(enemy.global_position)

		DebugControl.debug_combat("🔥 Burn: %.1f damage (%d stacks)" % [final_damage, total_stacks])



func _create_burn_particle(position: Vector2):
	"""Create burn damage particle effect"""
	var particle = ColorRect.new()
	particle.size = Vector2(6, 6)
	particle.color = Effects.burn.base_color
	particle.position = position + Vector2(randf_range(-8, 8), randf_range(-8, 8))

	var scene = Engine.get_main_loop().current_scene
	scene.add_child(particle)

	var tween = particle.create_tween()
	tween.parallel().tween_property(particle, "position", particle.position + Vector2(randf_range(-16, 16), -24), 0.8)
	tween.parallel().tween_property(particle, "modulate:a", 0.0, 0.8)
	tween.tween_callback(particle.queue_free)
