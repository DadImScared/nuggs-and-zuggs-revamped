class_name HotSauceTalents
extends BaseTalentTree

func _init() -> void:
	sauce_name = "Hot Sauce"

func build_talent_pool():
	"""Build the complete talent pool for Hot Sauce"""
	var hot_sauce_talents = [
		create_trigger_talent(
			"Fire Spirits",
			"15% chance to spawn seeking fire spirits that apply 2 burn stacks",
			2,
			[create_fire_spirit_talent()],
			TalentManager.TalentTheme.DAMAGE
		),
		create_trigger_talent(
			"Inferno Legion",
			"Fire spirits spawn in groups of 3 and apply 4 burn stacks",
			2,
			[create_inferno_legion_talent()],
			TalentManager.TalentTheme.DAMAGE
		),
		create_stat_talent("placeholder", "", 2, []),
		create_stat_talent("placeholder", "", 2, []),
		create_stat_talent("placeholder", "", 2, []),
		create_stat_talent("placeholder", "", 2, []),
	]

	return hot_sauce_talents

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

func create_fire_spirit_talent() -> TriggerEffectResource:
	"""Fire Spirit talent - player can select this as an upgrade"""
	var trigger = TriggerEffectResource.new()
	trigger.trigger_name = "fire_spirit"
	trigger.trigger_type = TriggerEffectResource.TriggerType.ON_HIT
	trigger.trigger_condition["chance"] = 0.15  # 15% chance to spawn spirit

	# Fire spirit parameters
	trigger.effect_parameters["spirit_count"] = 1
	trigger.effect_parameters["seek_range"] = 300.0
	trigger.effect_parameters["spirit_speed"] = 60.0
	trigger.effect_parameters["burn_stacks"] = 2  # Spirits apply 2 burn stacks
	trigger.effect_parameters["spirit_damage"] = 7.0

	return trigger

func create_inferno_legion_talent() -> TriggerEffectResource:
	"""Inferno Legion talent - enhanced fire spirits with more count and stacks"""
	var enhancement = TriggerEffectResource.new()
	enhancement.trigger_name = "inferno_legion"
	enhancement.trigger_type = TriggerEffectResource.TriggerType.ON_HIT
	enhancement.enhances = ["fire_spirit"]  # Enhances the base fire spirit trigger

	# Enhanced fire spirit parameters - these will be added to base values
	enhancement.effect_parameters["spirit_count"] = 2  # +2 to base 1 = 3 total
	enhancement.effect_parameters["seek_range"] = 50.0  # +50 to base 300 = 350 total
	enhancement.effect_parameters["spirit_speed"] = 20.0  # +20 to base 60 = 80 total
	enhancement.effect_parameters["burn_stacks"] = 2  # +2 to base 2 = 4 total
	enhancement.effect_parameters["spirit_damage"] = 8.0  # +8 to base 7 = 15 total impact damage

	return enhancement
