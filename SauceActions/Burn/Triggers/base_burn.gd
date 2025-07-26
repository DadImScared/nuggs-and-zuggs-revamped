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

	var burn_stacks = data.effect_parameters.get("burn_stacks", 1)

	# Extract enhanced parameters - trigger system already processed all multipliers!
	var enhanced_params = {
		"duration": data.effect_parameters.get("duration", Effects.burn.base_duration),
		"tick_interval": data.effect_parameters.get("tick_interval", Effects.burn.base_tick_interval),
		"damage": data.effect_parameters.get("tick_damage", Effects.burn.base_tick_damage),
		"max_stacks": data.effect_parameters.get("max_stacks", Effects.burn.base_max_stacks),
		"stack_value": data.effect_parameters.get("stack_value", Effects.burn.base_stack_value),
		"stacks": burn_stacks
	}

	# Use StackingEffect with trigger-enhanced parameters
	Effects.burn._apply_with_enhanced_params(enemy, bottle, enhanced_params)

	DebugControl.debug_status("🔥 Applied burn: %.1f damage, %.1fs duration" % [enhanced_params["damage"], enhanced_params["duration"]])
