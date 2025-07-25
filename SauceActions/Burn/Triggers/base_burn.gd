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
		var base_damage = enhanced_tick_damage * total_stacks

		# Apply any conditional damage multipliers from talents
		var final_damage = _apply_conditional_damage_multipliers(enemy, source_bottle, base_damage)

		var bottle_id = source_bottle.bottle_id if source_bottle else "burn"
		enemy.take_damage_from_source(final_damage, bottle_id)
		Effects.burn._create_particle(enemy.global_position)
		DebugControl.debug_combat("🔥 Burn: %.1f damage (%d stacks)" % [final_damage, total_stacks])

func _apply_conditional_damage_multipliers(enemy: Node2D, source_bottle: Node, base_damage: float) -> float:
	"""Apply conditional damage multipliers based on enemy state and bottle talents"""
	if not source_bottle:
		return base_damage

	# DEBUG: Let's see what triggers are on the bottle
	for i in range(source_bottle.trigger_effects.size()):
		var trigger = source_bottle.trigger_effects[i]

	var final_damage = base_damage
	for trigger in source_bottle.trigger_effects:
		if not trigger.enhances.has("burn"):
			continue

		# FOSSIL FUEL: Fossilized enemies take extra damage
		if trigger.trigger_name == "fossil_fuel":
			var is_fossilized = enemy.has_method("get_total_stack_count") and enemy.get_total_stack_count("fossilize") > 0
			if is_fossilized:
				var multiplier = trigger.effect_parameters.get("fossilized_damage_multiplier", 1.0)
				if multiplier > 1.0:
					final_damage *= multiplier
					DebugControl.debug_status("🌋 Fossil Fuel: %.1f → %.1f damage (×%.1f fossilized bonus)" % [base_damage, final_damage, multiplier])

		# FUTURE: Add more conditional multipliers here
		# if trigger.trigger_name == "some_other_talent":
		#     if some_condition:
		#         final_damage *= trigger.effect_parameters.get("some_multiplier", 1.0)

	return final_damage
