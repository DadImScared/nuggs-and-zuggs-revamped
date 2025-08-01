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
		#create_trigger_talent(
			#"Inferno Legion",
			#"Fire spirits spawn in groups of 3 and apply 4 burn stacks",
			#2,
			#[create_inferno_legion_talent()],
			#TalentManager.TalentTheme.DAMAGE
		#),
		create_trigger_talent(
			"Chain Ignition",
			"Burning enemies have 25% chance to instantly ignite nearby enemies",
			2,
			[create_chain_ignition_talent()],
			TalentManager.TalentTheme.EXPLOSIVE
		),
		create_trigger_talent(
			"Fossil Fuel",
			"Fossilized enemies take 2x burn damage",
			3,
			[create_fossil_fuel_talent()],
			TalentManager.TalentTheme.DAMAGE
		),
		#create_trigger_talent(
			#"Blazing Trails",
			#"Fire spirits leave burning trails that damage enemies for 5 seconds",
			#3,
			#[create_blazing_trails_talent()],
			#TalentManager.TalentTheme.EXPLOSIVE
		#),
		create_trigger_talent(
			"Blazing Trails",
			"Fire spirits leave burning trails that damage enemies for 5 seconds",
			3,
			[create_blazing_trails_talent()],
			TalentManager.TalentTheme.EXPLOSIVE
		),
		create_trigger_talent(
			"Slow Burn",
			"Burns last 50% longer but tick 30% slower",
			2,
			[create_slow_burn_talent()],
			TalentManager.TalentTheme.DAMAGE
		),
		create_trigger_talent(
			"Cambrian Explosion",
			"Shooting a burning enemy instantly spreads 1 burn to the nearest enemy",
			2,
			[create_cambrian_explosion_talent()],
			TalentManager.TalentTheme.EXPLOSIVE
		),
		create_trigger_talent(
			"Ember Cascade",
			"Each burn tick has 15% chance to apply another burn stack to the same enemy",
			2,
			[create_ember_cascade_talent()],
			TalentManager.TalentTheme.DAMAGE
		),
		create_trigger_talent(
			"Thermal Shock",
			"When burns are first applied, deal 50% of their total damage instantly - ancient heat that can't wait",
			2,  # Level 2 talent
			[create_thermal_shock_talent()],
			TalentManager.TalentTheme.BURN
		)
		#create_stat_talent("placeholder", "", 2, []),
		#create_stat_talent("placeholder", "", 2, []),
		#create_stat_talent("placeholder", "", 2, []),
		#create_stat_talent("placeholder", "", 2, []),
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

func create_blazing_trails_talent() -> TriggerEffectResource:
	"""Blazing Trails talent - fire spirits leave burning trails behind them"""
	var enhancement = TriggerEffectResource.new()
	enhancement.trigger_name = "blazing_trails"
	enhancement.trigger_type = TriggerEffectResource.TriggerType.PASSIVE

	enhancement.enhances = ["fire_spirit"]  # Enhances fire spirit behavior

	# Trail parameters - ALL in effect_parameters for consistency
	enhancement.effect_parameters["leaves_trail"] = true
	enhancement.effect_parameters["trail_width"] = 60.0
	enhancement.effect_parameters["trail_duration"] = 5.0
	enhancement.effect_parameters["trail_tick_damage"] = 8.0
	enhancement.effect_parameters["trail_tick_interval"] = 0.3
	enhancement.effect_parameters["trail_color"] = Color(1.0, 0.3, 0.0, 0.6)

	return enhancement

func create_slow_burn_talent() -> TriggerEffectResource:
	"""Slow Burn talent - burns last 50% longer but tick slower"""
	var enhancement = TriggerEffectResource.new()
	enhancement.trigger_name = "slow_burn"
	enhancement.trigger_type = TriggerEffectResource.TriggerType.ON_HIT
	enhancement.enhances = ["burn"]

	# Slow burn parameters - affect all burn effects
	enhancement.effect_parameters["duration_multiplier"] = 1.5  # 50% longer duration
	enhancement.effect_parameters["tick_interval_multiplier"] = 1.3  # 30% slower ticks

	return enhancement

func create_chain_ignition_talent():
	"""Chain Ignition: Burning enemies have 25% chance to instantly ignite nearby enemies"""
	var trigger = TriggerEffectResource.new()
	trigger.trigger_name = "chain_ignition"
	trigger.trigger_type = TriggerEffectResource.TriggerType.ON_DOT_TICK
	trigger.trigger_condition["dot_types"] = ["burn"]
	trigger.trigger_condition["chance"] = 0.05
	trigger.effect_parameters["spread_radius"] = 100.0
	trigger.effect_parameters["spread_burn_stacks"] = 1
	trigger.effect_parameters["max_targets"] = 3
	return trigger

func create_fossil_fuel_talent() -> TriggerEffectResource:
	"""Fossil Fuel: Fossilized enemies take 2x burn damage"""
	var enhancement = TriggerEffectResource.new()
	enhancement.trigger_name = "fossil_fuel"
	enhancement.trigger_type = TriggerEffectResource.TriggerType.PASSIVE
	enhancement.enhances = ["burn"]
	enhancement.effect_parameters["tick_damage_multiplier"] = 2.0
	enhancement.trigger_condition["has_effects"] = ["fossilize"]
	return enhancement

func create_cambrian_explosion_talent() -> TriggerEffectResource:
	"""Cambrian Explosion: Shooting a burning enemy instantly spreads 1 burn to nearest enemy"""
	var trigger = TriggerEffectResource.new()
	trigger.trigger_name = "cambrian_explosion"
	trigger.trigger_type = TriggerEffectResource.TriggerType.ON_HIT
	trigger.trigger_condition["has_effects"] = ["burn"]  # Only triggers on enemies with burn effect
	trigger.trigger_condition["chance"] = 1.0  # Always triggers when conditions are met

	# Cambrian explosion parameters
	trigger.effect_parameters["spread_radius"] = 150.0  # Search radius for nearest enemy
	trigger.effect_parameters["spread_burn_stacks"] = 1  # Always spreads 1 burn stack

	return trigger

func create_ember_cascade_talent() -> TriggerEffectResource:
	"""Ember Cascade: Each burn tick has 15% chance to apply another burn stack"""
	var enhancement = TriggerEffectResource.new()
	enhancement.trigger_name = "ember_cascade"
	enhancement.trigger_type = TriggerEffectResource.TriggerType.ON_DOT_TICK
	enhancement.enhances = ["burn"]  # Enhances existing burn effects
	enhancement.trigger_condition["dot_types"] = ["burn"]
	enhancement.trigger_condition["chance"] = 0.15  # 15% chance per tick

	# Ember cascade parameters - using standard names for enhancement compatibility
	enhancement.effect_parameters["burn_stacks"] = 1  # Add 1 more burn stack

	return enhancement

func create_thermal_shock_talent():
	"""Thermal Shock: Deal instant damage when burns are first applied"""
	var trigger = TriggerEffectResource.new()
	trigger.trigger_name = "thermal_shock"
	trigger.trigger_type = TriggerEffectResource.TriggerType.ON_HIT
	trigger.trigger_condition["chance"] = 1.0  # Always check on hit

	# Thermal shock parameters
	trigger.effect_parameters["thermal_shock_multiplier"] = 0.5  # 50% of total burn DoT

	return trigger
