# Talents/Talent.gd
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

# NEW: Multiple theme support
@export var talent_themes: Array[TalentManager.TalentTheme] = []
# LEGACY: Keep for backward compatibility
@export var talent_theme: TalentManager.TalentTheme = TalentManager.TalentTheme.DAMAGE

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

func set_theme(theme: TalentManager.TalentTheme) -> Talent:
	talent_theme = theme
	var typed_themes: Array[TalentManager.TalentTheme] = [theme]
	talent_themes = typed_themes
	return self

# NEW: Multiple theme helper methods
func has_theme(theme: TalentManager.TalentTheme) -> bool:
	"""Check if talent has a specific theme"""
	return theme in talent_themes or theme == talent_theme

func get_primary_theme() -> TalentManager.TalentTheme:
	"""Get the primary theme for display/filtering"""
	if talent_themes.size() > 0:
		return talent_themes[0]
	return talent_theme

func get_all_themes() -> Array[TalentManager.TalentTheme]:
	"""Get all themes this talent belongs to"""
	if talent_themes.size() > 0:
		return talent_themes
	return [talent_theme]

func get_theme_display_string() -> String:
	"""Get a display string showing all themes"""
	var themes = get_all_themes()
	if themes.size() == 1:
		return TalentManager.get_theme_name(themes[0])
	else:
		var theme_names = []
		for theme in themes:
			theme_names.append(TalentManager.get_theme_name(theme))
		return " + ".join(theme_names)

# Updated factory functions with theme setting
static func create_stat_talent_with_theme(name: String, desc: String, level: int, modifiers: Array[StatModifier], theme: TalentManager.TalentTheme) -> Talent:
	var talent = create_stat_talent(name, desc, level, modifiers)
	talent.talent_theme = theme
	var typed_themes: Array[TalentManager.TalentTheme] = [theme]
	talent.talent_themes = typed_themes
	return talent

static func create_effect_talent_with_theme(name: String, desc: String, level: int, effects: Array[SpecialEffectResource], theme: TalentManager.TalentTheme) -> Talent:
	var talent = create_effect_talent(name, desc, level, effects)
	talent.talent_theme = theme
	var typed_themes: Array[TalentManager.TalentTheme] = [theme]
	talent.talent_themes = typed_themes
	return talent

# Static factory methods for easy talent creation
static func create_stat_talent(
	name: String,
	desc: String,
	level: int,
	modifiers: Array[StatModifier],
	theme = TalentManager.TalentTheme.DAMAGE
) -> Talent:
	var talent = Talent.new()
	talent.talent_name = name
	talent.description = desc
	talent.level_required = level
	talent.talent_type = TalentType.STAT_MODIFIER
	talent.stat_modifiers = modifiers

	# Handle both single theme and multiple themes
	if theme is Array:
		var typed_themes: Array[TalentManager.TalentTheme] = []
		for t in theme:
			typed_themes.append(t)
		talent.talent_themes = typed_themes
		talent.talent_theme = theme[0] if theme.size() > 0 else TalentManager.TalentTheme.DAMAGE
	else:
		talent.talent_theme = theme
		var typed_themes: Array[TalentManager.TalentTheme] = [theme]
		talent.talent_themes = typed_themes

	return talent

static func create_effect_talent(
	name: String,
	desc: String,
	level: int,
	effects: Array[SpecialEffectResource],
	theme = TalentManager.TalentTheme.DAMAGE
) -> Talent:
	var talent = Talent.new()
	talent.talent_name = name
	talent.description = desc
	talent.level_required = level
	talent.talent_type = TalentType.SPECIAL_EFFECT
	talent.special_effects = effects

	# Handle both single theme and multiple themes
	if theme is Array:
		var typed_themes: Array[TalentManager.TalentTheme] = []
		for t in theme:
			typed_themes.append(t)
		talent.talent_themes = typed_themes
		talent.talent_theme = theme[0] if theme.size() > 0 else TalentManager.TalentTheme.DAMAGE
	else:
		talent.talent_theme = theme
		var typed_themes: Array[TalentManager.TalentTheme] = [theme]
		talent.talent_themes = typed_themes

	return talent

static func create_trigger_talent(
	name: String,
	desc: String,
	level: int,
	triggers: Array[TriggerEffectResource],
	theme = TalentManager.TalentTheme.DAMAGE
) -> Talent:
	var talent = Talent.new()
	talent.talent_name = name
	talent.description = desc
	talent.level_required = level
	talent.talent_type = TalentType.TRIGGER_EFFECT
	talent.trigger_conditions = triggers

	# Handle both single theme and multiple themes
	if theme is Array:
		var typed_themes: Array[TalentManager.TalentTheme] = []
		for t in theme:
			typed_themes.append(t)
		talent.talent_themes = typed_themes
		talent.talent_theme = theme[0] if theme.size() > 0 else TalentManager.TalentTheme.DAMAGE
	else:
		talent.talent_theme = theme
		var typed_themes: Array[TalentManager.TalentTheme] = [theme]
		talent.talent_themes = typed_themes

	return talent

static func create_transformation_talent(name: String, desc: String, level: int) -> Talent:
	var talent = Talent.new()
	talent.talent_name = name
	talent.description = desc
	talent.level_required = level
	talent.talent_type = TalentType.TRANSFORMATION
	talent.talent_theme = TalentManager.TalentTheme.UTILITY
	var typed_themes: Array[TalentManager.TalentTheme] = [TalentManager.TalentTheme.UTILITY]
	talent.talent_themes = typed_themes
	return talent
