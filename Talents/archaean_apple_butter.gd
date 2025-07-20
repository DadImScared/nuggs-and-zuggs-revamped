class_name ArchaeanAppleButterTalents
extends BaseTalentTree

func _init():
	sauce_name = "Archaean Apple Butter"

func create_basic_fossilization() -> TriggerEffectResource:
	"""Every Archaean Apple Butter bottle gets temporal fossilization"""
	var trigger = TriggerEffectResource.new()
	trigger.trigger_name = "fossilize"
	trigger.trigger_type = TriggerEffectResource.TriggerType.ON_HIT
	trigger.trigger_condition["chance"] = 0.15  # 15% chance
	trigger.effect_parameters["duration"] = 2.5  # 2.5 seconds frozen
	trigger.effect_parameters["amber_color"] = Color(1.0, 0.8, 0.3, 0.6)  # Translucent amber
	trigger.effect_parameters["max_stacks"] = 1  # Default: no stacking
	trigger.effect_parameters["stack_value"] = 0.15  # 15% additional slow per stack
	return trigger

func _create_sedimentary_layers_enhancement() -> TriggerEffectResource:
	var enhancement = TriggerEffectResource.new()
	enhancement.trigger_name = "sedimentary_layers"
	enhancement.trigger_type = TriggerEffectResource.TriggerType.PASSIVE
	enhancement.enhances = ["fossilize"]  # Enhances existing fossilization triggers

	# Enhanced parameters
	enhancement.effect_parameters["max_stacks"] = 5
	#enhancement.effect_parameters["tick_damage"] = 8.0
	#enhancement.effect_parameters["tick_interval"] = 0.8

	return enhancement

func build_talent_pool():
	var apple_butter_talents = [
		# Future talents will go here
		create_trigger_talent(
			"Sedimentary Layers",
			"Fossilization can now stack up to 5 times, each adding 15% slow",
			2,
			[_create_sedimentary_layers_enhancement()],
			TalentManager.TalentTheme.DAMAGE
		),
		create_stat_talent("shot", "ww", 2, []),
		create_stat_talent("shot", "ww", 2, [])
	]
	return apple_butter_talents
