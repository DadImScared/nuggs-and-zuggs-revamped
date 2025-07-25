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

func _create_amber_amplifier_trigger() -> TriggerEffectResource:
	var trigger = TriggerEffectResource.new()
	trigger.trigger_name = "amber_amplifier"
	trigger.trigger_type = TriggerEffectResource.TriggerType.PASSIVE
	trigger.effect_parameters["radius"] = 400.0
	trigger.effect_parameters["damage_per_enemy"] = 0.20
	trigger.effect_parameters["max_enemies"] = 10
	return trigger

func _create_temporal_debt_trigger() -> TriggerEffectResource:
	var trigger = TriggerEffectResource.new()
	trigger.trigger_name = "temporal_debt_collection"
	trigger.trigger_type = TriggerEffectResource.TriggerType.ON_HIT
	trigger.trigger_condition["chance"] = 1.0  # Always check hits
	trigger.effect_parameters["bonus_per_second"] = 0.05  # 5% per second
	return trigger

func _create_amber_preservation_trigger() -> TriggerEffectResource:
	var trigger = TriggerEffectResource.new()
	trigger.trigger_name = "amber_preservation_protocol"
	trigger.trigger_type = TriggerEffectResource.TriggerType.ON_ENEMY_DEATH
	trigger.effect_parameters["seeker_count"] = [3, 5]  # 3-5 seekers
	trigger.effect_parameters["seeker_range"] = 200.0  # Seeker flight range
	trigger.effect_parameters["seeker_fossilize_chance"] = 1  # 60% fossilize chance per seeker
	return trigger

func _create_fossilization_overflow_trigger() -> TriggerEffectResource:
	"""When hitting already-fossilized enemies, create amber explosion that spreads fossilization"""
	var trigger = TriggerEffectResource.new()
	trigger.trigger_name = "fossilization_overflow"
	trigger.trigger_type = TriggerEffectResource.TriggerType.ON_HIT
	trigger.trigger_condition["chance"] = 1.0  # Always check hits

	# Explosion parameters
	trigger.effect_parameters["explosion_radius"] = 120.0
	trigger.effect_parameters["explosion_damage_multiplier"] = 1.3  # 200% damage
	trigger.effect_parameters["spread_fossilize_chance"] = 0.5  # 80% chance to fossilize hit enemies
	trigger.effect_parameters["amber_color"] = Color(1.0, 0.8, 0.3, 0.8)

	# Fossilization parameters for spread effect
	trigger.effect_parameters["fossilize_duration"] = 2.5
	trigger.effect_parameters["fossilize_tick_damage"] = 6.0
	trigger.effect_parameters["max_fossilize_stacks"] = 3  # Lower than normal for balance

	return trigger

func _create_crystalline_bloom_trigger() -> TriggerEffectResource:
	"""When 3+ enemies are fossilized nearby, spawn amber crystal that pulses damage + fossilization"""
	var trigger = TriggerEffectResource.new()
	trigger.trigger_name = "crystalline_bloom"
	trigger.trigger_type = TriggerEffectResource.TriggerType.ON_TIMER
	trigger.trigger_condition["chance"] = 1.0  # Always check hits to detect fossilizations
	trigger.trigger_condition["cooldown"] = 3.0

	# Base crystal parameters (can be enhanced by future talents)
	trigger.effect_parameters["detection_radius"] = 400.0  # Range to check for fossilized enemies
	trigger.effect_parameters["min_fossilized_enemies"] = 3  # Minimum to trigger
	trigger.effect_parameters["cooldown_duration"] = 2.0  # Seconds between crystals
	trigger.effect_parameters["pulse_radius"] = 150.0  # Crystal pulse range
	trigger.effect_parameters["spread_fossilize_chance"] = 0.5  # 50% chance per pulse
	trigger.effect_parameters["crystal_duration"] = 5.0  # Crystal lifetime
	trigger.effect_parameters["pulse_interval"] = 1.0  # Seconds between pulses

	return trigger

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
		create_trigger_talent(
			"Fossilization Overflow",
			"Hitting already-fossilized enemies creates amber explosions that deal 200% damage and spread fossilization to nearby enemies (80% chance).",
			2,  # Tier 2 talent
			[_create_fossilization_overflow_trigger()],
			TalentManager.TalentTheme.EXPLOSIVE
		),
		create_trigger_talent(
			"Crystalline Bloom",
			"When 3+ enemies are fossilized nearby, spawn amber crystal that pulses damage + 50% fossilization chance",
			2,  # Tier 3 talent
			[_create_crystalline_bloom_trigger()],
			TalentManager.TalentTheme.EXPLOSIVE
		),
		#create_trigger_talent(
			#"Amber Amplifier",
			#"+20% damage per fossilized enemy alive (max +200%)",
			#2,
			#[_create_amber_amplifier_trigger()],
			#TalentManager.TalentTheme.DAMAGE
		#),
		SharedTalents.fossil_fuel_talent(),
		create_trigger_talent(
			"Temporal Debt Collection",
			"Every second without fossilizing, gain +5% fossilization chance. Resets on success.",
			2,
			[_create_temporal_debt_trigger()],
			TalentManager.TalentTheme.DEFENSIVE
		),
		create_trigger_talent(
			"Amber Preservation Protocol",
			"Fossilized enemies shatter into 3-5 amber seekers that fly out and fossilize on hit (60% chance)",
			2,
			[_create_amber_preservation_trigger()],
			TalentManager.TalentTheme.DAMAGE
		)
	]
	return apple_butter_talents
