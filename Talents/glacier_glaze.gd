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
		),
		create_trigger_talent(
			"Ice Crystals",
			"20% chance on hit to create ice spikes - Frozen moisture crystallizes into deadly projectiles",
			2,
			[_create_ice_crystals_trigger()],
			TalentManager.TalentTheme.DAMAGE
		),
		create_trigger_talent(
			"Snowcone",
			"always cold",
			2,
			[_create_snowcone_trigger()],
			TalentManager.TalentTheme.DAMAGE
		),
		create_trigger_talent(
			"Snowball Fight",
			"40% chance on hit to launch 2 snowballs at nearby enemies that explode for splash damage",
			2,
			[_create_snowball_trigger()],
			TalentManager.TalentTheme.EXPLOSIVE
		),
		create_trigger_talent(
			"Snowball Machine",
			"snowballs mark enemies and turn them into machines that shoot snowballs",
			2,
			[_create_snowball_machine_trigger()],
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
	trigger.trigger_condition["chance"] = 0.2

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

func _create_ice_crystals_trigger() -> TriggerEffectResource:
	"""Creates the Ice Crystals trigger - 20% chance to spawn ice spikes on hit application"""
	var trigger = TriggerEffectResource.new()
	trigger.trigger_name = "ice_crystals"
	trigger.trigger_type = TriggerEffectResource.TriggerType.ON_HIT
	trigger.trigger_condition["chance"] = 0.7  # 20% chance
	trigger.effect_parameters["spike_count"] = 3  # Number of ice spikes
	trigger.effect_parameters["damage_multiplier"] = 0.6  # 60% of bottle damage
	trigger.effect_parameters["spike_range"] = 40.0  # Range around hit point
	return trigger

func _create_snowcone_trigger() -> TriggerEffectResource:
	var trigger = TriggerEffectResource.new()
	trigger.trigger_name = "snowcone"
	trigger.enhances = ["cold"]
	trigger.trigger_type = TriggerEffectResource.TriggerType.ON_HIT
	trigger.trigger_condition["chance"] = 0.9
	return trigger

func _create_snowball_trigger() -> TriggerEffectResource:
	var trigger = TriggerEffectResource.new()
	trigger.trigger_name = "snowball"
	trigger.trigger_type = TriggerEffectResource.TriggerType.ON_HIT
	trigger.trigger_condition["chance"] = 0.4
	trigger.effect_parameters = {
		"damage": 25,
		"splash_radius": 200,
		"splash_damage": 0.5,
		"balls": 2
	}
	return trigger

func _create_snowball_machine_trigger() -> TriggerEffectResource:
	var trigger = TriggerEffectResource.new()
	trigger.trigger_name = "snowball_machine"
	trigger.trigger_type = TriggerEffectResource.TriggerType.ON_TIMER
	trigger.trigger_condition["cooldown"] = 1.0
	trigger.effect_parameters = {
		"damage": 15,
		"splash_radius": 100,
		"splash_damage": 0.5,
		"balls": 4,
		"duration": 5
	}
	return trigger
