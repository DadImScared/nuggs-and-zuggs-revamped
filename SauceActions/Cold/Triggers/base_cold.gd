# SauceActions/Cold/Triggers/base_cold.gd
class_name ColdTrigger
extends BaseTriggerAction

func _init() -> void:
	trigger_name = "cold"
	trigger_description = "Apply stacking cold effect that progressively chills enemies until frozen solid"

func execute_trigger(bottle: ImprovedBaseSauceBottle, data: EnhancedTriggerData):
	var enemy = data.effect_parameters.hit_enemy

	if not enemy or not is_instance_valid(enemy):
		return

	# Get cold parameters from trigger data (like Hot Sauce does)
	var stack_count = data.effect_parameters.get("stack_value", 1)
	var enhanced_params = {
		"duration": data.effect_parameters.get("duration", 5.0),
		"tick_interval": 0.0,  # No ticking for cold
		"tick_damage": 0.0,    # No tick damage for cold
		"max_stacks": data.effect_parameters.get("max_stacks", 6),
		"stack_value": data.effect_parameters.get("stack_value", 1.0),
		"slow_per_stack": data.effect_parameters.get("slow_per_stack", 0.15),
		"freeze_threshold": data.effect_parameters.get("freeze_threshold", 6),
		"cold_color": data.effect_parameters.get("cold_color", Color(0.7, 0.9, 1.0, 0.8)),
		"tick_effect": null
	}

	# Use the Effects system like Hot Sauce does
	Effects.cold.apply_from_talent(enemy, bottle, stack_count, enhanced_params)

	DebugControl.debug_status("🧊 Cold applied via Effects system! Stacks: %d" % stack_count)
