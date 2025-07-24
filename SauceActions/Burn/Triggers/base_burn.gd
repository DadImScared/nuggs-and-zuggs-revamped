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
	var duration_mult = data.effect_parameters.get("duration_multiplier", 1.0)
	var tick_interval_mult = data.effect_parameters.get("tick_interval_multiplier", 1.0)
	var damage_mult = data.effect_parameters.get("tick_damage_multiplier", 1.0)

	# Calculate enhanced values
	var enhanced_duration = Effects.burn.get_duration() * duration_mult
	var enhanced_tick_interval = Effects.burn.get_tick_interval() * tick_interval_mult
	var enhanced_tick_damage = Effects.burn.get_tick_damage() * damage_mult

	# Apply burn directly with enhanced values (no global modification needed)
	enemy.apply_stacking_effect(
		"burn",
		Effects.burn.get_stack_value() * burn_stacks,
		Effects.burn.get_max_stacks(),
		bottle.bottle_id,
		enhanced_duration,
		{
			"immediate_effect": Effects.burn._create_immediate_effect(enemy),
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
	"""Create tick effect with enhanced damage"""
	return func():
		if not is_instance_valid(enemy):
			return

		var total_stacks = enemy.get_total_stack_count("burn")
		var damage = enhanced_tick_damage * total_stacks
		var bottle_id = source_bottle.bottle_id if source_bottle else "burn"

		enemy.take_damage_from_source(damage, bottle_id)
		Effects.burn._create_particle(enemy.global_position)
		DebugControl.debug_combat("🔥 Burn: %.1f damage (%d stacks)" % [damage, total_stacks])
