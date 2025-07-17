class_name TriggerEffectResource
extends Resource

@export var trigger_name: String
@export var trigger_type: TriggerType
@export var effect_name: String
@export var trigger_condition: Dictionary = {}
@export var effect_parameters: Dictionary = {}

enum TriggerType {
	ON_SHOT_COUNT,    # Every N shots
	ON_CRITICAL_HIT,  # When landing a crit
	ON_ENEMY_DEATH,   # When killing an enemy
	ON_LOW_HEALTH,    # When player health is low
	ON_TIMER,         # Every N seconds
	ON_RANDOM_CHANCE,  # Random probability per shot
	ON_HIT,
	ON_DOT_TICK
}

# Factory methods for common triggers
static func create_burst_fire(interval: int = 5, burst_size: int = 5) -> TriggerEffectResource:
	var trigger = TriggerEffectResource.new()
	trigger.trigger_name = "burst_fire"
	trigger.trigger_type = TriggerType.ON_SHOT_COUNT
	trigger.effect_name = "fire_burst"
	trigger.trigger_condition["interval"] = interval
	trigger.effect_parameters["burst_size"] = burst_size
	trigger.effect_parameters["spread_angle"] = 8.0
	return trigger

static func create_tsunami_wave(cooldown: float = 20.0, damage_multiplier: float = 2.0) -> TriggerEffectResource:
	var trigger = TriggerEffectResource.new()
	trigger.trigger_name = "tsunami_wave"
	trigger.trigger_type = TriggerType.ON_TIMER
	trigger.effect_name = "create_tsunami"
	trigger.trigger_condition["cooldown"] = cooldown
	trigger.effect_parameters["damage_multiplier"] = damage_multiplier
	return trigger

static func create_crit_stacking(bonus_per_crit: float = 0.05, max_bonus: float = 0.5) -> TriggerEffectResource:
	var trigger = TriggerEffectResource.new()
	trigger.trigger_name = "crit_stacking"
	trigger.trigger_type = TriggerType.ON_CRITICAL_HIT
	trigger.effect_name = "increase_crit_chance"
	trigger.effect_parameters["bonus_per_crit"] = bonus_per_crit
	trigger.effect_parameters["max_bonus"] = max_bonus
	return trigger

static func create_death_explosion(damage_multiplier: float = 1.5, radius: float = 100.0) -> TriggerEffectResource:
	var trigger = TriggerEffectResource.new()
	trigger.trigger_name = "death_explosion"
	trigger.trigger_type = TriggerType.ON_ENEMY_DEATH
	trigger.effect_name = "create_explosion"
	trigger.effect_parameters["damage_multiplier"] = damage_multiplier
	trigger.effect_parameters["radius"] = radius
	return trigger

static func create_chain_burst(chance: float = 0.5) -> TriggerEffectResource:
	var trigger = TriggerEffectResource.new()
	trigger.trigger_name = "chain_burst"
	trigger.trigger_type = TriggerType.ON_RANDOM_CHANCE
	trigger.effect_name = "fire_burst"
	trigger.trigger_condition["chance"] = chance
	trigger.effect_parameters["burst_size"] = 5
	trigger.effect_parameters["spread_angle"] = 8.0
	return trigger

static func create_perfect_shots(shot_count: int = 10) -> TriggerEffectResource:
	var trigger = TriggerEffectResource.new()
	trigger.trigger_name = "perfect_shots"
	trigger.trigger_type = TriggerType.ON_RANDOM_CHANCE  # Could be timer-based instead
	trigger.effect_name = "activate_perfect_mode"
	trigger.trigger_condition["chance"] = 0.1  # 10% chance per shot
	trigger.effect_parameters["shot_count"] = shot_count
	return trigger
