# Talents/prehistoric_pesto_talents.gd
class_name PrehistoricPestoTalents
extends BaseTalentTree

func _init():
	sauce_name = "Prehistoric Pesto"

func build_talent_pool():
	var pesto_talents = [
			#create_trigger_talent(
			#"Mutation Catalyst",
			#"Each infection tick has 0.01% chance to permanently increase damage by 0.1% for the rest of the run",
			#2,
			#[_create_mutation_catalyst_trigger()],
			#TalentManager.TalentTheme.INFECTION
		#),
		#create_special_talent(
			#"Viral Spread", "Infection immediately spreads to 3 nearby enemies", 2,
			#[_create_viral_spread_effect()],
			#TalentManager.TalentTheme.INFECTION
		#),
		create_trigger_talent(
			"Plague Bearer",
			"Infection Aura",
			2,
			[_create_plague_bearer_resource()],
			TalentManager.TalentTheme.INFECTION
		),
		Talent.create_trigger_talent(
			"Virulent Aura",
			"Plague Bearer radius increased by 50%",
			3,
			[create_virulent_aura_enhancement()],
			TalentManager.TalentTheme.INFECTION
		),
		#create_trigger_talent(
			#"Infectious Momentum",
			#"Each enemy killed while infected increases movement speed by 3% for 12 seconds (stacks up to 30%)", 2,
			#[_create_infectious_momentum_trigger()],
			#TalentManager.TalentTheme.INFECTION
		#),
		#create_trigger_talent(
			#"Extinction Event",
			#"After 100 total infections this run, every 5th shot creates a massive 200-pixel infection explosion", 3,
			#[_create_extinction_event_trigger()],
			#TalentManager.TalentTheme.EXPLOSIVE
		#)
		#create_stat_talent(
			#"Evolution", "+0.3 Fire Rate", 2,
			#[create_fire_rate_boost(0.3)]
		#),
		#create_trigger_talent(
			#"Pathogen Dividend",
			#"Each time an infected enemy dies, there's a 10% chance to grant +5 XP", 2,
			#[_create_pathogen_dividend()], TalentManager.TalentTheme.INFECTION
		#)
		#create_stat_talent(
			#"Enhanced Transmission",
			#"Infection spread radius increased by 50%",
			#2,  # Foundation tier
			#[_create_enhanced_transmission()]
		#)
		Talent.create_trigger_talent(
			"Triple Dose", "Adds 2 more enemies to spread count", 3,
			[create_triple_dose_resource()],
			TalentManager.TalentTheme.INFECTION
		),
		#Talent.create_effect_talent(
			#"Persistent Strain",
			#"Infections last 50% longer",
			#2,
			#[_create_persistent_strain_effect()],
			#TalentManager.TalentTheme.INFECTION
		#),
		#create_trigger_talent(
			#"Primordial Pulse",
			#"Each tick of infection damage has 20% chance to spread to nearby enemy",
			#2,
			#[_create_primordial_pulse_trigger()],
			#TalentManager.TalentTheme.INFECTION
		#)
		#create_special_talent(
			#"Mutation Strain", "Infections stack and mutate for increased damage", 2,
			#[_create_mutation_effect()],
			#TalentManager.TalentTheme.INFECTION
		#),
		#create_trigger_talent(
			#"Infection Tsunami", "Every 15 seconds, all infections pulse and spread", 2,
			#[_create_infection_tsunami_trigger()],
			#TalentManager.TalentTheme.INFECTION
		#),
		create_trigger_talent(
			"Double Dose",
			"20% chance: hitting infected enemy spreads to 2 nearby",
			2,
			[_create_double_dose_trigger()],
			TalentManager.TalentTheme.INFECTION
		),
		#create_trigger_talent(
			#"Viral Relay",
			#"Every 3 seconds, infections jump to closest uninfected targets", 2,
			#[_create_viral_relay_trigger()], TalentManager.TalentTheme.INFECTION
		#)
		#create_trigger_talent(
			#"Viral Frenzy",
			 #"25% chance per infection tick: +100% fire rate for 8 seconds", 2,
			#[_create_viral_frenzy_trigger()], TalentManager.TalentTheme.INFECTION
		#)
	]

	return pesto_talents

func build_talent_tree() -> Dictionary:
	var pesto_talents = {}

	# Level 1 talents - Foundation choices
	pesto_talents[1] = [
		create_stat_talent("Viral Load", "+30% Effect Chance - spreads like gossip", 1,
			[create_effect_chance_boost(0.3)]),
		create_stat_talent("Rapid Mutation", "+0.5 Fire Rate - evolution doesn't wait", 1,
			[create_fire_rate_boost(0.5)]),
		create_stat_talent("Toxic Herbs", "+3 Damage from herbs that survived the meteor", 1,
			[create_damage_boost(3.0)])
	]

	# Level 2 talents - First special effects appear
	pesto_talents[2] = [
		create_special_talent("Viral Spread", "Infection immediately spreads to 3 nearby enemies", 2,
			[_create_viral_spread_effect()], TalentManager.TalentTheme.INFECTION),
		create_stat_talent("Evolution", "+0.8 Fire Rate", 2,
			[create_fire_rate_boost(0.8)]),
		create_special_talent("Mutation Strain", "Infections stack and mutate for increased damage", 2,
			[_create_mutation_effect()], TalentManager.TalentTheme.INFECTION)
	]

	# Level 3 talents - More powerful effects
	pesto_talents[3] = [
		create_special_talent("Epidemic Outbreak", "Creates spreading waves of infection", 3,
			[_create_epidemic_effect()], TalentManager.TalentTheme.INFECTION),
		create_stat_talent("Ancient Power", "+6 Damage", 3,
			[create_damage_boost(6.0)]),
		create_special_talent("Toxic Strain", "Infection also applies poison damage", 3,
			[_create_toxic_strain_effect()], TalentManager.TalentTheme.INFECTION)
	]

	# Level 4 talents - Deeper specialization
	pesto_talents[4] = [
		create_stat_talent("Viral Saturation", "+50% Effect Chance", 4,
			[create_effect_chance_boost(0.5)]),
		create_stat_talent("Hyper Evolution", "+1.0 Fire Rate", 4,
			[create_fire_rate_boost(1.0)]),
		create_stat_talent("Primordial Power", "+8 Damage", 4,
			[create_damage_boost(8.0)])
	]

	# Level 5 talents - Game changing effects
	pesto_talents[5] = [
		create_special_talent("Pandemic", "Low chance to infect ALL enemies on screen", 5,
			[_create_pandemic_effect()], TalentManager.TalentTheme.INFECTION),
		create_stat_talent("Meteor Impact", "+12 Damage", 5,
			[create_damage_boost(12.0)]),
		create_special_talent("Super Mutation", "Enhanced mutation with double stacking", 5,
			[_create_enhanced_mutation_effect()], TalentManager.TalentTheme.INFECTION)
	]

	return pesto_talents

# === INFECTION SPECIAL EFFECT HELPERS ===
func create_basic_infection() -> TriggerEffectResource:
	var trigger = TriggerEffectResource.new()
	trigger.trigger_name = "infect"
	trigger.trigger_type = TriggerEffectResource.TriggerType.ON_HIT
	trigger.trigger_condition["chance"] = 0.2
	trigger.trigger_condition["radius"] = 150
	trigger.trigger_condition["duration"] = 5
	return trigger

func _create_plague_bearer_resource() -> TriggerEffectResource:
	var trigger = TriggerEffectResource.new()
	trigger.trigger_name = "plague_bearer"
	trigger.trigger_type = TriggerEffectResource.TriggerType.ON_TIMER
	trigger.trigger_condition["cooldown"] = 3.0  # Every 3 seconds
	trigger.trigger_condition["chance"] = 0.2
	trigger.trigger_condition["radius"] = 50
	return trigger

func create_virulent_aura_enhancement() -> TriggerEffectResource:
	var enhancement = TriggerEffectResource.new()
	enhancement.trigger_name = "virulent_aura"
	enhancement.trigger_type = TriggerEffectResource.TriggerType.ON_TIMER
	enhancement.trigger_condition["cooldown"] = 999.0  # Never triggers on its own
	enhancement.enhances = ["plague_bearer"]  # Only affects plague bearer
	enhancement.effect_parameters = {
		"radius_multiplier": 1.5  # 50% bigger radius
	}
	return enhancement

func create_triple_dose_resource() -> TriggerEffectResource:
	var enhancement = TriggerEffectResource.new()
	enhancement.trigger_name = "triple_dose"
	enhancement.trigger_type
	enhancement.trigger_condition["cooldown"] = 999.0  # Never triggers on its own
	enhancement.enhances = ["double_dose"]
	enhancement.effect_parameters = {
		"spread_count_multiplier": 1.5
	}
	return enhancement

func _create_infectious_momentum_trigger() -> TriggerEffectResource:
	"""Creates infectious momentum trigger - speed buff on infected enemy kills"""
	var trigger = TriggerEffectResource.new()
	trigger.trigger_name = "infectious_momentum"
	trigger.trigger_type = TriggerEffectResource.TriggerType.ON_ENEMY_DEATH
	trigger.effect_name = "speed_buff_on_infected_kill"

	# Effect parameters
	trigger.effect_parameters["speed_boost_per_stack"] = 0.03  # 3% per stack
	trigger.effect_parameters["duration"] = 12.0  # 12 seconds
	trigger.effect_parameters["max_stacks"] = 10  # Max 30% (10 x 3%)

	return trigger

func _create_extinction_event_trigger() -> TriggerEffectResource:
	"""Creates extinction event trigger - massive explosion every 5th shot after 100 infections"""
	var trigger = TriggerEffectResource.new()
	trigger.trigger_name = "extinction_event"
	trigger.trigger_type = TriggerEffectResource.TriggerType.ON_SHOT_COUNT
	trigger.effect_name = "massive_infection_explosion"

	# Trigger conditions - shot interval + infection threshold
	trigger.trigger_condition["interval"] = 5  # Every 5th shot
	trigger.trigger_condition["infection_threshold"] = 100  # Need 100 total infections first

	# Effect parameters
	trigger.effect_parameters["explosion_radius"] = 200.0
	trigger.effect_parameters["damage_multiplier"] = 2.0
	trigger.effect_parameters["infection_chance"] = 0.8
	trigger.effect_parameters["infection_duration"] = 4.0
	trigger.effect_parameters["infection_damage_ratio"] = 0.5

	return trigger

func _create_mutation_catalyst_trigger() -> TriggerEffectResource:
	"""Creates mutation catalyst trigger that permanently boosts damage on infection ticks"""
	var trigger = TriggerEffectResource.new()
	trigger.trigger_name = "mutation_catalyst"
	trigger.trigger_type = TriggerEffectResource.TriggerType.ON_DOT_TICK
	trigger.trigger_condition["chance"] = 0.001  # 0.1% chance per DOT tick
	trigger.trigger_condition["dot_types"] = ["infect"]  # Only infection DOT ticks
	trigger.effect_parameters["damage_boost_percent"] = 0.001  # 0.1% = 0.001
	return trigger

func _create_enhanced_transmission() -> StatModifier:
	"""Enhanced Transmission - Infection spread radius increased by 50%"""
	var modifier = StatModifier.new()
	modifier.stat_name = "base_radius"
	modifier.mode = StatModifier.ModifierMode.MULTIPLY
	modifier.multiply = 1.5  # 50% increase
	return modifier

func _create_pathogen_dividend() -> TriggerEffectResource:
	var trigger = TriggerEffectResource.new()
	trigger.trigger_name = "pathogen_dividend"
	trigger.trigger_type = TriggerEffectResource.TriggerType.ON_ENEMY_DEATH
	trigger.trigger_condition["chance"] = 0.10
	trigger.effect_parameters["xp_reward"] = 5
	return trigger

func _create_primordial_pulse_trigger() -> TriggerEffectResource:
	"""Creates primordial pulse trigger that spreads on DOT ticks"""
	var trigger = TriggerEffectResource.new()
	trigger.trigger_name = "primordial_pulse"
	trigger.trigger_type = TriggerEffectResource.TriggerType.ON_DOT_TICK
	trigger.trigger_condition["chance"] = 0.20  # 20% chance per DOT tick
	trigger.trigger_condition["dot_types"] = ["infect"]  # Only infection DOT ticks
	trigger.effect_parameters["spread_radius"] = 100.0  # Within 100 pixels
	trigger.effect_parameters["infection_strength"] = 1.0  # Full strength infection
	trigger.effect_parameters["max_spreads_per_tick"] = 1  # Only spread to 1 enemy per tick
	return trigger

func _create_viral_relay_trigger() -> TriggerEffectResource:
	"""Creates viral relay trigger that jumps infections every 3 seconds"""
	var trigger = TriggerEffectResource.new()
	trigger.trigger_name = "viral_relay"
	trigger.trigger_type = TriggerEffectResource.TriggerType.ON_TIMER
	trigger.trigger_condition["cooldown"] = 3.0  # Every 3 seconds
	trigger.effect_parameters["jump_range"] = 150.0  # Jump range
	trigger.effect_parameters["infection_strength"] = 0.8  # 80% strength
	return trigger

func _create_viral_frenzy_trigger() -> TriggerEffectResource:
	"""Creates viral frenzy trigger that gives fire rate boost on infection ticks"""
	var trigger = TriggerEffectResource.new()
	trigger.trigger_name = "viral_frenzy"
	trigger.trigger_type = TriggerEffectResource.TriggerType.ON_DOT_TICK
	trigger.trigger_condition["chance"] = 0.01  #1% chance per DOT tick
	trigger.trigger_condition["dot_types"] = ["infect"]  # Only infection ticks
	trigger.effect_parameters["fire_rate_boost"] = 1.0  # 100% boost
	trigger.effect_parameters["duration"] = 8.0  # 8 seconds
	return trigger

func _create_double_dose_trigger() -> TriggerEffectResource:
	"""Creates double dose trigger that spreads infection on hitting infected enemies"""
	var trigger = TriggerEffectResource.new()
	trigger.trigger_name = "double_dose"
	trigger.trigger_type = TriggerEffectResource.TriggerType.ON_HIT
	trigger.trigger_condition["chance"] = 0.20  # 20% chance per shot
	trigger.effect_parameters["spread_count"] = 2  # Spread to 2 enemies
	trigger.effect_parameters["spread_radius"] = 100.0  # Within 100 pixels
	trigger.effect_parameters["target_infected_only"] = true  # Only when hitting infected
	return trigger

func _create_infection_tsunami_trigger() -> TriggerEffectResource:
	"""Creates infection tsunami trigger that pulses all infections every 15 seconds"""
	var trigger = TriggerEffectResource.new()
	trigger.trigger_name = "infection_tsunami"
	trigger.trigger_type = TriggerEffectResource.TriggerType.ON_TIMER
	trigger.trigger_condition["cooldown"] = 15.0  # Every 15 seconds
	trigger.effect_parameters["pulse_radius"] = 120.0  # Spread radius
	trigger.effect_parameters["spread_chance"] = 0.8   # 80% chance to spread
	trigger.effect_parameters["pulse_damage"] = 1.5    # 150% damage pulse
	return trigger

func _create_viral_spread_effect() -> SpecialEffectResource:
	"""Creates immediate spread infection on hit"""
	var effect = SpecialEffectResource.new()
	effect.effect_name = "infection_viral_spread"
	effect.effect_type = SpecialEffectResource.EffectType.ON_HIT_EFFECT
	effect.set_parameter("spread_radius", 100.0)
	effect.set_parameter("spread_count", 3)
	return effect

func _create_mutation_effect() -> SpecialEffectResource:
	"""Creates mutating infection that stacks damage"""
	var effect = SpecialEffectResource.new()
	effect.effect_name = "infection_mutation"
	effect.effect_type = SpecialEffectResource.EffectType.ON_HIT_EFFECT
	effect.set_parameter("mutation_rate", 1.5)
	effect.set_parameter("max_stacks", 5)
	return effect

func _create_persistent_strain_effect() -> SpecialEffectResource:
	"""Create the Persistent Strain effect"""
	var effect = SpecialEffectResource.new()
	effect.effect_name = "infection_duration_boost"
	effect.effect_type = SpecialEffectResource.EffectType.PASSIVE_EFFECT
	effect.set_parameter("duration_multiplier", 1.5)  # 50% longer
	return effect

func _create_epidemic_effect() -> SpecialEffectResource:
	"""Creates epidemic that spreads in waves"""
	var effect = SpecialEffectResource.new()
	effect.effect_name = "infection_epidemic"
	effect.effect_type = SpecialEffectResource.EffectType.ON_HIT_EFFECT
	effect.set_parameter("wave_count", 3)
	effect.set_parameter("wave_delay", 0.5)
	return effect

func _create_toxic_strain_effect() -> SpecialEffectResource:
	"""Creates toxic strain that also applies poison"""
	var effect = SpecialEffectResource.new()
	effect.effect_name = "infection_toxic_strain"
	effect.effect_type = SpecialEffectResource.EffectType.ON_HIT_EFFECT
	effect.set_parameter("toxicity_multiplier", 2.0)
	effect.set_parameter("toxic_duration", 8.0)
	return effect

func _create_pandemic_effect() -> SpecialEffectResource:
	"""Creates pandemic that can spread to entire screen"""
	var effect = SpecialEffectResource.new()
	effect.effect_name = "infection_pandemic"
	effect.effect_type = SpecialEffectResource.EffectType.ON_HIT_EFFECT
	effect.set_parameter("pandemic_range", 800.0)
	effect.set_parameter("infection_chance", 0.3)
	return effect

func _create_enhanced_mutation_effect() -> SpecialEffectResource:
	"""Enhanced mutation with higher rates and more stacks"""
	var effect = SpecialEffectResource.new()
	effect.effect_name = "infection_mutation"
	effect.effect_type = SpecialEffectResource.EffectType.ON_HIT_EFFECT
	effect.set_parameter("mutation_rate", 2.5)  # Higher mutation rate
	effect.set_parameter("max_stacks", 10)      # More stacks
	return effect
