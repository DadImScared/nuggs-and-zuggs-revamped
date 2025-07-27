class_name GlacierGlazeTalents
extends BaseTalentTree

func _init() -> void:
	sauce_name = "Glacier Glaze"

func build_talent_pool():
	"""Build the complete talent pool for Glacier Glaze"""
	var glacier_glaze_talents = [
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
