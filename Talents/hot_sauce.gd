class_name HotSauceTalents
extends BaseTalentTree

func _init() -> void:
	sauce_name = "Hot Sauce"

func create_basic_burn() -> TriggerEffectResource:
	var trigger = TriggerEffectResource.new()
	trigger.trigger_name = "burn"
	trigger.trigger_type = TriggerEffectResource.TriggerType.ON_HIT
	trigger.trigger_condition["chance"] = 0.4

	# Base burn parameters
	trigger.effect_parameters["duration"] = 3.0
	trigger.effect_parameters["max_stacks"] = 8
	trigger.effect_parameters["stack_value"] = 1.0  # Base intensity per stack
	trigger.effect_parameters["tick_damage"] = 5.0  # Damage per stack per tick
	trigger.effect_parameters["tick_interval"] = 0.5  # Burn ticks every 0.5 seconds
	trigger.effect_parameters["burn_color"] = Color(1.2, 0.6, 0.3, 0.8)  # Orange-red fire

	return trigger
