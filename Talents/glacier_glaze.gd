class_name GlacierGlazeTalents
extends BaseTalentTree

func _init() -> void:
	sauce_name = "Glacier Glaze"

func build_talent_pool():
	"""Build the complete talent pool for Glacier Glaze"""
	var glacier_glaze_talents = [
		create_trigger_talent(
			"Permafrost",
			"+50% cold effect duration - Ancient ice that never melts",
			1,
			[_create_permafrost_trigger()],
			TalentManager.TalentTheme.DAMAGE
		)
		#create_trigger_talent(
			#"Glacial Touch",
			#"60% chance to apply cold to enemies - slow but inevitable, like the glaciers",
			#1,
			#[create_basic_cold()],
			#TalentManager.TalentTheme.UTILITY
		#)
		# Future talents will be added here
	]

	return glacier_glaze_talents

func create_basic_cold() -> TriggerEffectResource:
	var trigger = TriggerEffectResource.new()
	trigger.trigger_name = "cold"
	trigger.trigger_type = TriggerEffectResource.TriggerType.ON_HIT
	trigger.trigger_condition["chance"] = 0.6

	# Base cold parameters with stacking
	trigger.effect_parameters["duration"] = 5.0
	trigger.effect_parameters["max_stacks"] = 6
	trigger.effect_parameters["stack_value"] = 1.0
	trigger.effect_parameters["slow_per_stack"] = 0.15  # 15% per stack
	trigger.effect_parameters["freeze_threshold"] = 6   # Freeze at 6 stacks
	trigger.effect_parameters["cold_color"] = Color(0.7, 0.9, 1.0, 0.8)  # Light blue

	return trigger

func _create_permafrost_trigger() -> TriggerEffectResource:
	"""Creates the Permafrost trigger - enhances cold effect duration"""
	var trigger = TriggerEffectResource.new()
	trigger.trigger_name = "permafrost"
	trigger.trigger_type = TriggerEffectResource.TriggerType.PASSIVE
	trigger.enhances = ["cold"]  # Enhances cold effects
	trigger.effect_parameters["duration_multiplier"] = 1.5  # +50% duration
	return trigger
