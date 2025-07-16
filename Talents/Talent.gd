class_name Talent
extends Resource

@export var talent_name: String
@export var description: String
@export var level_required: int = 1
@export var talent_type: TalentType
@export var stat_modifiers: Array[StatModifier] = []
@export var special_effects: Array[SpecialEffectResource] = []
@export var trigger_conditions: Array[TriggerEffectResource] = []
@export var effect_priority: int = 0

enum TalentType {
	STAT_MODIFIER,
	SPECIAL_EFFECT,
	TRIGGER_EFFECT,
	PASSIVE_AURA,
	TRANSFORMATION
}

func apply_to_bottle(bottle: ImprovedBaseSauceBottle):
	print("Applying talent '%s' to bottle %s" % [talent_name, bottle.bottle_id])

	match talent_type:
		TalentType.STAT_MODIFIER:
			for mod in stat_modifiers:
				bottle.modify_stat(mod)
		TalentType.SPECIAL_EFFECT:
			for effect in special_effects:
				bottle.add_special_effect(effect)
		TalentType.TRIGGER_EFFECT:
			for trigger in trigger_conditions:
				bottle.add_trigger_effect(trigger)
		TalentType.PASSIVE_AURA:
			TalentManager.apply_aura_effect(bottle, self)
		TalentType.TRANSFORMATION:
			bottle.apply_transformation(self)

func remove_from_bottle(bottle: ImprovedBaseSauceBottle):
	"""Remove this talent's effects from a bottle (for respec)"""
	print("Removing talent '%s' from bottle %s" % [talent_name, bottle.bottle_id])

	match talent_type:
		TalentType.STAT_MODIFIER:
			for mod in stat_modifiers:
				bottle.remove_stat_modifier(mod)
		TalentType.SPECIAL_EFFECT:
			for effect in special_effects:
				bottle.remove_special_effect(effect)
		TalentType.TRIGGER_EFFECT:
			for trigger in trigger_conditions:
				bottle.remove_trigger_effect(trigger)
		TalentType.PASSIVE_AURA:
			TalentManager.remove_aura_effect(bottle, self)
		TalentType.TRANSFORMATION:
			bottle.remove_transformation(self)

func get_preview_text() -> String:
	"""Generate preview text for UI"""
	var preview_parts: Array[String] = []

	# Add stat modifier previews
	for mod in stat_modifiers:
		preview_parts.append(mod.get_description())

	# Add effect descriptions
	for effect in special_effects:
		preview_parts.append("Adds: " + effect.effect_name.replace("_", " ").capitalize())

	# Add trigger descriptions
	for trigger in trigger_conditions:
		preview_parts.append("Trigger: " + trigger.trigger_name.replace("_", " ").capitalize())

	return "\n".join(preview_parts)

# Static factory methods for easy talent creation
static func create_stat_talent(name: String, desc: String, level: int, modifiers: Array[StatModifier]) -> Talent:
	var talent = Talent.new()
	talent.talent_name = name
	talent.description = desc
	talent.level_required = level
	talent.talent_type = TalentType.STAT_MODIFIER
	talent.stat_modifiers = modifiers
	return talent

static func create_effect_talent(name: String, desc: String, level: int, effects: Array[SpecialEffectResource]) -> Talent:
	var talent = Talent.new()
	talent.talent_name = name
	talent.description = desc
	talent.level_required = level
	talent.talent_type = TalentType.SPECIAL_EFFECT
	talent.special_effects = effects
	return talent

static func create_trigger_talent(name: String, desc: String, level: int, triggers: Array[TriggerEffectResource]) -> Talent:
	var talent = Talent.new()
	talent.talent_name = name
	talent.description = desc
	talent.level_required = level
	talent.talent_type = TalentType.TRIGGER_EFFECT
	talent.trigger_conditions = triggers
	return talent

static func create_transformation_talent(name: String, desc: String, level: int) -> Talent:
	var talent = Talent.new()
	talent.talent_name = name
	talent.description = desc
	talent.level_required = level
	talent.talent_type = TalentType.TRANSFORMATION
	return talent
