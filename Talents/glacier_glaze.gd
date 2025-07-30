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
		),
		create_trigger_talent(
			"Frozen Winds",
			"40% chance on hit to unleash freezing winds that damage and push back enemies in a radius",
			2,
			[_create_frozen_winds()],
			TalentManager.TalentTheme.DAMAGE
		),
		create_trigger_talent(
			"Frozen Legacy",
			"Cold enemies drop frost zones on death that deal 25 damage every 0.5s for 8 seconds",
			2,
			[_create_frost_zone()],
			TalentManager.TalentTheme.DAMAGE
		),
		create_trigger_talent(
			"Ice Comet Barrage", "Drop a barrage of ice comets",
			2,
			[_create_ice_comet_barrage()],
			TalentManager.TalentTheme.DAMAGE
		),
		create_trigger_talent(
			"Ice Comet Barrage Plus", "Extra comets for extra fun",
			2,
			[_create_ice_comet_barrage_plus()],
			TalentManager.TalentTheme.DAMAGE
		),
		create_trigger_talent(
			"Frozen comets", "ice comets",
			2,
			[_create_frozen_comets_trigger()],
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
	trigger.trigger_condition["chance"] = 0.6
	trigger.effect_parameters = {
		"damage": 22,
		"splash_radius": 100,
		"splash_damage": 0.3,
		"balls": 2
	}
	return trigger

func _create_snowball_machine_trigger() -> TriggerEffectResource:
	var trigger = TriggerEffectResource.new()
	trigger.trigger_name = "snowball_machine"
	trigger.trigger_type = TriggerEffectResource.TriggerType.ON_TIMER
	trigger.trigger_condition["cooldown"] = 2.0
	trigger.effect_parameters = {
		"damage": 24,
		"splash_radius": 100,
		"splash_damage": 0.4,
		"balls": 4,
		"duration": 5
	}
	return trigger

func _create_frozen_winds() -> TriggerEffectResource:
	var trigger = TriggerEffectResource.new()
	trigger.trigger_name = "frozen_winds"
	trigger.trigger_type = TriggerEffectResource.TriggerType.ON_HIT
	trigger.trigger_condition["chance"] = 0.4
	trigger.effect_parameters = {
		"damage": 25,
		"radius": 60,
		"force": 20,
		"stacks": 6
	}
	return trigger

func _create_frost_zone() -> TriggerEffectResource:
	"""Cold enemies drop frost zones"""
	var trigger = TriggerEffectResource.new()
	trigger.trigger_name = "frozone"
	trigger.trigger_type = TriggerEffectResource.TriggerType.ON_ENEMY_DEATH
	trigger.trigger_condition["chance"] = 1
	trigger.trigger_condition["has_effects"] = ["cold"]
	trigger.effect_parameters = {
		"tick_damage": 25,
		"radius": 80,
		"duration": 8,
		"tick_interval": 0.5
	}
	return trigger

func _create_ice_comet_barrage() -> TriggerEffectResource:
	var trigger = TriggerEffectResource.new()
	trigger.trigger_name = "ice_comet_barrage"
	trigger.trigger_type = TriggerEffectResource.TriggerType.ON_HIT
	trigger.trigger_condition["chance"] = 0.6
	trigger.effect_parameters = {
		"damage": 25,
		"radius": 80,
		"duration": 3,
		"tick_interval": 0.5,
		"comet_count": 6
	}
	return trigger

func _create_ice_comet_barrage_plus() -> TriggerEffectResource:
	var trigger = TriggerEffectResource.new()
	trigger.trigger_name = "ice_comet_barrage_plus"
	trigger.trigger_type = TriggerEffectResource.TriggerType.PASSIVE
	trigger.enhances = ["ice_comet_barrage"]
	trigger.effect_parameters = {
		"damage": 15,
		"duration": 5,
		"comet_count": 12
	}

	return trigger

func _create_frozen_comets_trigger() -> TriggerEffectResource:
	"""Makes ice comets apply cold stacks"""
	var trigger = TriggerEffectResource.new()
	trigger.trigger_name = "frozen_comets"
	trigger.trigger_type = TriggerEffectResource.TriggerType.PASSIVE
	trigger.enhances = ["ice_comet_barrage"]  # Enhances ice comet barrage
	trigger.effect_parameters = {
		"applies_cold": true,
		"cold_stacks": 2,
		"cold_duration": 4.0
	}
	return trigger

func _create_ice_prism_trigger() -> TriggerEffectResource:
	var trigger = TriggerEffectResource.new()
	trigger.trigger_name = "ice_prism"
	trigger.trigger_type = TriggerEffectResource.TriggerType.ON_HIT
	trigger.trigger_condition["chance"] = 0.4
	trigger.effect_parameters = {
		"damage": 15,
		"main_target_damage": 0.1,
		"apply_cold": false,
		"beams": 3,
		"stacks": 1
	}
	return trigger

func _create_orb_rotation_trigger() -> TriggerEffectResource:
	var trigger = TriggerEffectResource.new()
	trigger.trigger_name = "orb_rotation"
	trigger.trigger_type = TriggerEffectResource.TriggerType.PASSIVE
	trigger.trigger_condition["cooldown"] = 2
	trigger.effect_parameters = {
		"damage": 15,
		"speed": 45, # degrees per second??
		"orbs": 3,
		"apply_cold": false,
		"stacks": 1,
		"size": 45,
		"knockback": true,
		"knockback_force": 30 #idk what to put this as
	}
	return trigger

func _create_more_orbs_trigger() -> TriggerEffectResource:
	var trigger = TriggerEffectResource.new()
	trigger.trigger_name = "more_orbs"
	trigger.trigger_type = TriggerEffectResource.TriggerType.PASSIVE
	trigger.enhances = ["orb_rotation"]
	trigger.effect_parameters = {
		"orbs": 3
	}
	return trigger

func _create_frozen_orb() -> TriggerEffectResource:
	var trigger = TriggerEffectResource.new()
	trigger.trigger_name = "frozen_orb"
	trigger.trigger_type = TriggerEffectResource.TriggerType.PASSIVE
	trigger.enhances = ["orb_rotation"]
	trigger.effect_parameters = {
		"apply_cold": true
	}
	return trigger

func _create_frozen_asteroid() -> TriggerEffectResource:
	var trigger = TriggerEffectResource.new()
	trigger.trigger_name = "frozen_asteroid"
	trigger.trigger_type = TriggerEffectResource.TriggerType.PASSIVE
	trigger.enhances = ["orb_rotation"]
	trigger.effect_parameters = {
		"stacks": 2,
		"size": 60,
		"apply_cold": true,
		"speed": 90
	}
	return trigger

func _create_frost_spikes() -> TriggerEffectResource:
	"""every 3rd shot sends a trail of ice spikes at the enemy"""
	var trigger = TriggerEffectResource.new()
	trigger.trigger_name = "frost_spikes"
	trigger.trigger_type = TriggerEffectResource.TriggerType.ON_SHOT_COUNT
	trigger.trigger_condition["count"] = 5
	trigger.effect_parameters = {
		"stacks": 2,
		"size": 60,
		"apply_cold": true,
		"speed": 45,
	}
	return trigger

func _create_short_spikes() -> TriggerEffectResource:
	"""every 3rd shot sends a trail of ice spikes at the enemy"""
	var trigger = TriggerEffectResource.new()
	trigger.trigger_name = "short_spikes"
	trigger.trigger_type = TriggerEffectResource.TriggerType.ON_SHOT_COUNT
	trigger.trigger_condition["count"] = 3
	trigger.effect_parameters = {
		"stacks": 2,
		"size": 60,
		"apply_cold": true,
		"speed": 45,
	}
	return trigger

func _create_frozen_opening() -> TriggerEffectResource:
	"""fire rate increased for each frozen enemy on screen"""
	var trigger = TriggerEffectResource.new()
	trigger.trigger_name = "frozen_opening"
	trigger.trigger_type = TriggerEffectResource.TriggerType.PASSIVE
	trigger.effect_parameters = {
		"fire_rate": 0.1,
		"fire_rate_cap": 1
	}
	return trigger

func _frost_shock() -> TriggerEffectResource:
	"""freezing a burning enemy shatters the freeze and does damage"""
	var trigger = TriggerEffectResource.new()
	trigger.trigger_name = "frost_shock"
	trigger.trigger_condition["has_effects"] = ["burn"]
	trigger.trigger_type = TriggerEffectResource.TriggerType.PASSIVE
	trigger.effect_parameters = {
		"apply_cold": false,
		"damage": 40,
		"stacks": 1,
		"stacks_required": 6,
		"create_puddle": false
	}
	return trigger

func _frost_nova() -> TriggerEffectResource:
	"""A random enemy triggers frost nova"""
	var trigger = TriggerEffectResource.new()
	trigger.trigger_name = "frost_nova"
	trigger.trigger_type = TriggerEffectResource.TriggerType.ON_TIMER
	trigger.trigger_condition["cooldown"] = 5
	trigger.effect_parameters = {
		"radius": 80,
		"damage": 40,
		"apply_cold": true,
		"apply_mark": true,
		"stacks": 1
	}
	return trigger

func _frost_golem() -> TriggerEffectResource:
	var trigger = TriggerEffectResource.new()
	trigger.trigger_name = "frost_golem"
	trigger.trigger_type = TriggerEffectResource.TriggerType.ON_HIT
	trigger.trigger_condition["chance"] = 0.3
	trigger.effect_parameters = {
		"duration": 8.0,
		"damage": 25,
		"swing_interval": 0.8,
		"pulse_damage": 0
	}
	return trigger
