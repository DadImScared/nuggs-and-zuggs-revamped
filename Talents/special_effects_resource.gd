class_name SpecialEffectResource
extends Resource

@export var effect_name: String
@export var effect_type: EffectType
@export var parameters: Dictionary = {}

enum EffectType {
	PROJECTILE_MODIFIER,  # Changes how projectiles behave
	ON_HIT_EFFECT,       # Triggers when projectiles hit
	PASSIVE_EFFECT,      # Continuous effects
	VISUAL_EFFECT        # Cosmetic changes
}

# Parameter management
func get_parameter(key: String, default_value = null):
	return parameters.get(key, default_value)

func set_parameter(key: String, value):
	parameters[key] = value

# Factory methods for common effects
static func create_triple_shot() -> SpecialEffectResource:
	var effect = SpecialEffectResource.new()
	effect.effect_name = "triple_shot"
	effect.effect_type = EffectType.PROJECTILE_MODIFIER
	effect.set_parameter("projectile_count", 3)
	effect.set_parameter("spread_angle", 15.0)
	return effect

static func create_damage_puddles(chance: float = 0.25, damage_multiplier: float = 0.5) -> SpecialEffectResource:
	var effect = SpecialEffectResource.new()
	effect.effect_name = "create_puddles"
	effect.effect_type = EffectType.ON_HIT_EFFECT
	effect.set_parameter("chance", chance)
	effect.set_parameter("damage_multiplier", damage_multiplier)
	effect.set_parameter("duration", 5.0)
	return effect

static func create_slow_effect(strength: float = 0.4, duration: float = 3.0) -> SpecialEffectResource:
	var effect = SpecialEffectResource.new()
	effect.effect_name = "apply_slow"
	effect.effect_type = EffectType.ON_HIT_EFFECT
	effect.set_parameter("slow_strength", strength)
	effect.set_parameter("duration", duration)
	return effect

static func create_pierce_ramping(damage_bonus: float = 0.25) -> SpecialEffectResource:
	var effect = SpecialEffectResource.new()
	effect.effect_name = "ramping_pierce"
	effect.effect_type = EffectType.PROJECTILE_MODIFIER
	effect.set_parameter("damage_bonus_per_hit", damage_bonus)
	return effect

static func create_critical_hits(chance: float = 0.15, multiplier: float = 3.0) -> SpecialEffectResource:
	var effect = SpecialEffectResource.new()
	effect.effect_name = "critical_hits"
	effect.effect_type = EffectType.PASSIVE_EFFECT
	effect.set_parameter("crit_chance", chance)
	effect.set_parameter("crit_multiplier", multiplier)
	return effect

static func create_homing_missiles() -> SpecialEffectResource:
	var effect = SpecialEffectResource.new()
	effect.effect_name = "homing_missiles"
	effect.effect_type = EffectType.PROJECTILE_MODIFIER
	effect.set_parameter("turn_speed", 0.05)
	return effect

static func create_vulnerability_debuff(bonus: float = 0.25, duration: float = 5.0) -> SpecialEffectResource:
	var effect = SpecialEffectResource.new()
	effect.effect_name = "vulnerability_debuff"
	effect.effect_type = EffectType.ON_HIT_EFFECT
	effect.set_parameter("damage_bonus", bonus)
	effect.set_parameter("duration", duration)
	return effect

static func create_infinite_pierce() -> SpecialEffectResource:
	var effect = SpecialEffectResource.new()
	effect.effect_name = "infinite_pierce"
	effect.effect_type = EffectType.PROJECTILE_MODIFIER
	effect.set_parameter("pierce_count", 999)
	effect.set_parameter("damage_scaling", true)
	return effect
