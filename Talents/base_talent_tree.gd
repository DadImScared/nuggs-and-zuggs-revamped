class_name BaseTalentTree
extends RefCounted

# Override this in each sauce's talent tree
var sauce_name: String = ""

# Override this to build the talent tree
func build_talent_tree() -> Dictionary:
	push_error("build_talent_tree() must be implemented by child class")
	return {}

# Helper functions available to all talent trees
func create_stat_talent(name: String, desc: String, level: int, modifiers: Array[StatModifier]) -> Talent:
	return Talent.create_stat_talent(name, desc, level, modifiers)

func create_special_talent(name: String, desc: String, level: int, effects: Array[SpecialEffectResource], theme) -> Talent:
	return Talent.create_effect_talent(name, desc, level, effects, theme)

func create_trigger_talent(name: String, desc: String, level: int, triggers: Array[TriggerEffectResource], theme) -> Talent:
	return Talent.create_trigger_talent(name, desc, level, triggers, theme)

# Common stat modifier helpers
func create_damage_boost(amount: float) -> StatModifier:
	return StatModifier.create_damage_boost(amount)

func create_fire_rate_boost(amount: float) -> StatModifier:
	var mod = StatModifier.new()
	mod.stat_name = "fire_rate"
	mod.mode = StatModifier.ModifierMode.ADD
	mod.add = amount
	return mod

func create_range_boost(amount: float) -> StatModifier:
	return StatModifier.create_range_boost(amount)

func create_effect_chance_boost(amount: float) -> StatModifier:
	var mod = StatModifier.new()
	mod.stat_name = "effect_chance"
	mod.mode = StatModifier.ModifierMode.ADD
	mod.add = amount
	return mod

func create_projectile_boost(amount: int) -> StatModifier:
	var mod = StatModifier.new()
	mod.stat_name = "projectile_count"
	mod.mode = StatModifier.ModifierMode.ADD
	mod.add = float(amount)
	return mod

# Debug helper
func print_talent_tree():
	var tree = build_talent_tree()
	#print("=== %s Talent Tree ===" % sauce_name)
	for level in tree.keys():
		#print("Level %d:" % level)
		for i in range(tree[level].size()):
			var talent = tree[level][i]
			#print("  %d. %s - %s" % [i + 1, talent.talent_name, talent.description])
	#print("=========================")
