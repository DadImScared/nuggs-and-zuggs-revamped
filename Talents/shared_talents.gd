# Talents/shared_talents.gd
class_name SharedTalents
extends RefCounted

## Cross-sauce synergy talents that can appear in multiple sauce trees

static func create_fossil_fuel_talent():
	"""Fossil Fuel: Fossilized enemies take 2x burn damage"""
	var trigger = TriggerEffectResource.new()
	trigger.trigger_name = "fossil_fuel"
	trigger.trigger_type = TriggerEffectResource.TriggerType.PASSIVE
	trigger.enhances = ["burn"]  # Enhances existing burn effects
	trigger.effect_parameters["fossilized_damage_multiplier"] = 2.0
	return trigger

static func fossil_fuel_talent():
	"""Returns complete Fossil Fuel trigger talent"""
	return Talent.create_trigger_talent(
		"Fossil Fuel",
		"Fossilized enemies take 2x burn damage - ancient organic matter burns twice as hot",
		3,
		[create_fossil_fuel_talent()],
		[TalentManager.TalentTheme.BURN, TalentManager.TalentTheme.FOSSILIZE]
	)

# Future shared talents:
# static func extinction_event_talent() - themes: [EXPLOSIVE, CHAOS]
# static func primordial_soup_talent() - themes: [UTILITY, DEFENSIVE]
# static func cambrian_explosion_talent() - themes: [CHAOS, EXPLOSIVE]
