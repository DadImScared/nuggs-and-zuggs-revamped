# Talents/prehistoric_pesto_talents.gd
class_name PrehistoricPestoTalents
extends BaseTalentTree

func _init():
	sauce_name = "Prehistoric Pesto"

func build_talent_pool():
	var pesto_talents = [
		create_special_talent("Viral Spread", "Infection immediately spreads to 3 nearby enemies", 2,
			[_create_viral_spread_effect()], TalentManager.TalentTheme.INFECTION),
		create_stat_talent("Evolution", "+0.3 Fire Rate", 2,
			[create_fire_rate_boost(0.3)]),
		create_special_talent("Mutation Strain", "Infections stack and mutate for increased damage", 2,
			[_create_mutation_effect()], TalentManager.TalentTheme.INFECTION)
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
