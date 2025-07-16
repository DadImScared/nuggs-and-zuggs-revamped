class_name StatModifier
extends Resource

@export var stat_name: String
@export var add: float = 0.0
@export var multiply: float = 1.0
@export var set_value: float = 0.0
@export var mode: ModifierMode = ModifierMode.ADD

enum ModifierMode {
	ADD,      # current + add
	MULTIPLY, # current * multiply
	SET       # = set_value
}

func apply_to_value(current_value: float) -> float:
	match mode:
		ModifierMode.ADD:
			return current_value + add
		ModifierMode.MULTIPLY:
			return current_value * multiply
		ModifierMode.SET:
			return set_value
		_:
			return current_value

func get_description() -> String:
	match mode:
		ModifierMode.ADD:
			return "%s: %+.1f" % [stat_name.replace("_", " ").capitalize(), add]
		ModifierMode.MULTIPLY:
			var percent = int((multiply - 1.0) * 100)
			return "%s: %+d%%" % [stat_name.replace("_", " ").capitalize(), percent]
		ModifierMode.SET:
			return "%s: %.1f" % [stat_name.replace("_", " ").capitalize(), set_value]
		_:
			return "Unknown modifier"

# Static factory methods for common modifiers
static func create_damage_boost(amount: float) -> StatModifier:
	var mod = StatModifier.new()
	mod.stat_name = "damage"
	mod.mode = ModifierMode.ADD
	mod.add = amount
	return mod

static func create_fire_rate_multiplier(multiplier: float) -> StatModifier:
	var mod = StatModifier.new()
	mod.stat_name = "fire_rate"
	mod.mode = ModifierMode.MULTIPLY
	mod.multiply = multiplier
	return mod

static func create_range_boost(amount: float) -> StatModifier:
	var mod = StatModifier.new()
	mod.stat_name = "range"
	mod.mode = ModifierMode.ADD
	mod.add = amount
	return mod
