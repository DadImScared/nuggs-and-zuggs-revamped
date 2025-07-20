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

func build_talent_pool():
	var apple_butter_talents = [
		# Future talents will go here
	]
	return apple_butter_talents
