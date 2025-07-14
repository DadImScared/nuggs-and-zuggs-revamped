# Singletons/talent_manager.gd
extends Node

var talent_trees: Dictionary = {}

func _ready():
	_initialize_talent_trees()

func _initialize_talent_trees():
	_create_ketchup_talents()
	_create_pesto_talents()

func _create_ketchup_talents():
	talent_trees["Ketchup"] = {
		1: [
			# Heavy Hitter Path
			Talent.create_stat_talent(
				"Thick & Chunky",
				"+50% damage, -25% fire rate",
				1,
				[
					StatModifier.create_damage_boost(0.5),  # Fixed from 0
					StatModifier.create_fire_rate_multiplier(0.75)
				]
			),
			# Machine Gun Path
			Talent.create_stat_talent(
				"Fast Food",
				"+100% fire rate, -25% damage",
				1,
				[
					StatModifier.create_fire_rate_multiplier(2.0),
					StatModifier.create_damage_boost(-0.25)  # Relative reduction
				]
			),
			# Shotgun Path
			Talent.create_effect_talent(
				"Squeeze Bottle",
				"Fires 3 projectiles in spread",
				1,
				[SpecialEffectResource.create_triple_shot()]
			)
		],
		2: [
			# Puddle Path
			Talent.create_effect_talent(
				"Tomato Seeds",
				"25% chance to create damage puddles",
				2,
				[SpecialEffectResource.create_damage_puddles(0.25, 0.5)]
			),
			# Pierce Path
			Talent.create_stat_talent(
				"High Pressure",
				"Projectiles pierce 2 enemies",
				2,
				[_create_pierce_modifier(2)]
			),
			# Burst Path
			Talent.create_trigger_talent(
				"Ketchup Packets",
				"Every 5th shot fires burst of 5",
				2,
				[TriggerEffectResource.create_burst_fire(5, 5)]
			)
		],
		3: [
			# Control Path
			Talent.create_effect_talent(
				"Viscous Flow",
				"Projectiles slow enemies 40% for 3s",
				3,
				[SpecialEffectResource.create_slow_effect(0.4, 3.0)]
			),
			# Debuff Path
			Talent.create_effect_talent(
				"Acidic Blend",
				"Enemies take 25% more damage for 5s",
				3,
				[SpecialEffectResource.create_vulnerability_debuff(0.25, 5.0)]
			),
			# Crit Path
			Talent.create_effect_talent(
				"Concentrated Formula",
				"15% crit chance, 300% crit damage",
				3,
				[SpecialEffectResource.create_critical_hits(0.15, 3.0)]
			)
		],
		4: [
			# Enhanced Puddles
			Talent.create_effect_talent(
				"Puddle Power",
				"Puddles slow enemies and last 50% longer",
				4,
				[_create_enhanced_puddles()]
			),
			# Ramping Pierce
			Talent.create_effect_talent(
				"Chain Reaction",
				"Pierce projectiles gain +25% damage per hit",
				4,
				[SpecialEffectResource.create_pierce_ramping(0.25)]
			),
			# Chain Burst
			Talent.create_trigger_talent(
				"Burst Control",
				"Burst shots have 50% chance to trigger again",
				4,
				[TriggerEffectResource.create_chain_burst(0.5)]
			)
		],
		5: [
			# Synergy Effects
			Talent.create_effect_talent(
				"Sticky Situation",
				"Slowed enemies take 50% more damage from Ketchup",
				5,
				[_create_slow_synergy()]
			),
			# Armor Break
			Talent.create_effect_talent(
				"Armor Piercing",
				"Debuffed enemies lose 50% defense permanently",
				5,
				[_create_armor_break()]
			),
			# Crit Stacking
			Talent.create_trigger_talent(
				"Lucky Streak",
				"Each crit increases crit chance by 5% (max 50%)",
				5,
				[TriggerEffectResource.create_crit_stacking(0.05, 0.5)]
			)
		],
		6: [
			# Mega Puddles
			Talent.create_effect_talent(
				"Expanding Puddles",
				"Puddles grow over time and chain to nearby puddles",
				6,
				[_create_mega_puddles()]
			),
			# Bouncing Shots
			Talent.create_effect_talent(
				"Ricochet",
				"Piercing shots bounce between enemies (max 3 bounces)",
				6,
				[_create_bouncing_shots()]
			),
			# Crit Mode
			Talent.create_effect_talent(
				"Critical Mass",
				"At 50% crit chance, all shots become crits for 10 seconds",
				6,
				[_create_crit_mode()]
			)
		],
		7: [
			# Area Control
			Talent.create_effect_talent(
				"Flood Zone",
				"Create massive puddle covering 1/4 of screen for 15s",
				7,
				[_create_flood_zone()]
			),
			# Pierce Beams
			Talent.create_transformation_talent(
				"Piercing Storm",
				"Shots create piercing beams that last 2 seconds",
				7
			),
			# Super Crits
			Talent.create_effect_talent(
				"Mega Crit",
				"Crits deal 500% damage and reset all cooldowns",
				7,
				[_create_super_crits()]
			)
		],
		8: [
			# Tsunami
			Talent.create_trigger_talent(
				"Ketchup Tsunami",
				"Every 20 seconds, unleash wave across entire screen",
				8,
				[TriggerEffectResource.create_tsunami_wave(20.0, 2.0)]
			),
			# Buff Aura
			Talent.create_transformation_talent(
				"Condiment Synergy",
				"Other sauce bottles gain 25% of Ketchup's bonuses",
				8
			),
			# Perfect Shots
			Talent.create_trigger_talent(
				"Perfect Shots",
				"Next 10 shots are guaranteed crits with max damage",
				8,
				[TriggerEffectResource.create_perfect_shots(10)]
			)
		],
		9: [
			# Infinite Scaling
			Talent.create_transformation_talent(
				"Eternal Flood",
				"Puddles become permanent and stack damage infinitely",
				9
			),
			# Infinite Pierce
			Talent.create_effect_talent(
				"Pierce Infinity",
				"Shots pierce all enemies and gain damage each hit",
				9,
				[SpecialEffectResource.create_infinite_pierce()]
			),
			# Permanent Crits
			Talent.create_transformation_talent(
				"Crit Ascension",
				"Become crit-immune and deal only critical hits",
				9
			)
		],
		10: [
			# World Transformation
			Talent.create_transformation_talent(
				"Tomato Apocalypse",
				"Transform arena into permanent damage field",
				10
			),
			# Homing Missiles
			Talent.create_effect_talent(
				"Ballistic Ketchup",
				"Shots become homing missiles that multiply on hit",
				10,
				[SpecialEffectResource.create_homing_missiles()]
			),
			# God Mode
			Talent.create_transformation_talent(
				"The Heinz Factor",
				"Transcend normal limits - all stats infinite for 30s",
				10
			)
		]
	}

func _create_pesto_talents():
	talent_trees["Prehistoric Pesto"] = {
		1: [
			# Poison Spread
			Talent.create_effect_talent(
				"Viral Load",
				"+50% poison chance, spreads on death",
				1,
				[_create_poison_spread()]
			),
			# Poison Stacking
			Talent.create_stat_talent(
				"Rapid Mutation",
				"+100% fire rate, poison stacks up to 5 times",
				1,
				[
					StatModifier.create_fire_rate_multiplier(2.0),
					_create_poison_stacking()
				]
			),
			# Poison Clouds
			Talent.create_effect_talent(
				"Ancient Spores",
				"Projectiles create poison clouds on impact",
				1,
				[_create_poison_clouds()]
			)
		],
		2: [
			# Poison Aura
			Talent.create_effect_talent(
				"Airborne",
				"Poison spreads to nearby enemies every 2 seconds",
				2,
				[_create_poison_aura()]
			),
			# Infectious Death
			Talent.create_effect_talent(
				"Spore Burst",
				"Poisoned enemies explode on death, poisoning others",
				2,
				[_create_infectious_death()]
			),
			# Stack Boost
			Talent.create_stat_talent(
				"Concentrated Toxin",
				"Each poison stack increases damage by 20%",
				2,
				[_create_poison_damage_stacking()]
			)
		]
	}

# Helper functions for creating special effects
func _create_pierce_modifier(pierce_count: int) -> StatModifier:
	var modifier = StatModifier.new()
	modifier.stat_name = "pierce_count"
	modifier.mode = StatModifier.ModifierMode.ADD
	modifier.add = pierce_count
	return modifier

func _create_enhanced_puddles() -> SpecialEffectResource:
	var effect = SpecialEffectResource.new()
	effect.effect_name = "enhanced_puddles"
	effect.effect_type = SpecialEffectResource.EffectType.ON_HIT_EFFECT
	effect.set_parameter("puddle_slow", true)
	effect.set_parameter("duration_multiplier", 1.5)
	return effect

func _create_slow_synergy() -> SpecialEffectResource:
	var effect = SpecialEffectResource.new()
	effect.effect_name = "slow_synergy"
	effect.effect_type = SpecialEffectResource.EffectType.PASSIVE_EFFECT
	effect.set_parameter("damage_bonus", 0.5)
	return effect

func _create_armor_break() -> SpecialEffectResource:
	var effect = SpecialEffectResource.new()
	effect.effect_name = "armor_break"
	effect.effect_type = SpecialEffectResource.EffectType.ON_HIT_EFFECT
	effect.set_parameter("defense_reduction", 0.5)
	effect.set_parameter("permanent", true)
	return effect

func _create_mega_puddles() -> SpecialEffectResource:
	var effect = SpecialEffectResource.new()
	effect.effect_name = "mega_puddles"
	effect.effect_type = SpecialEffectResource.EffectType.ON_HIT_EFFECT
	effect.set_parameter("expansion_rate", 1.5)
	effect.set_parameter("chain_distance", 150.0)
	return effect

func _create_bouncing_shots() -> SpecialEffectResource:
	var effect = SpecialEffectResource.new()
	effect.effect_name = "bouncing_shots"
	effect.effect_type = SpecialEffectResource.EffectType.PROJECTILE_MODIFIER
	effect.set_parameter("max_bounces", 3)
	effect.set_parameter("bounce_range", 200.0)
	return effect

func _create_crit_mode() -> SpecialEffectResource:
	var effect = SpecialEffectResource.new()
	effect.effect_name = "crit_mode"
	effect.effect_type = SpecialEffectResource.EffectType.PASSIVE_EFFECT
	effect.set_parameter("crit_threshold", 0.5)
	effect.set_parameter("mode_duration", 10.0)
	return effect

func _create_flood_zone() -> SpecialEffectResource:
	var effect = SpecialEffectResource.new()
	effect.effect_name = "flood_zone"
	effect.effect_type = SpecialEffectResource.EffectType.ON_HIT_EFFECT
	effect.set_parameter("screen_coverage", 0.25)
	effect.set_parameter("duration", 15.0)
	return effect

func _create_super_crits() -> SpecialEffectResource:
	var effect = SpecialEffectResource.new()
	effect.effect_name = "super_crits"
	effect.effect_type = SpecialEffectResource.EffectType.PASSIVE_EFFECT
	effect.set_parameter("crit_multiplier", 5.0)
	effect.set_parameter("reset_cooldowns", true)
	return effect

func _create_poison_spread() -> SpecialEffectResource:
	var effect = SpecialEffectResource.new()
	effect.effect_name = "poison_spread"
	effect.effect_type = SpecialEffectResource.EffectType.ON_HIT_EFFECT
	effect.set_parameter("poison_chance", 0.5)
	effect.set_parameter("spread_on_death", true)
	return effect

func _create_poison_stacking() -> StatModifier:
	var modifier = StatModifier.new()
	modifier.stat_name = "poison_stacks"
	modifier.mode = StatModifier.ModifierMode.ADD
	modifier.add = 5
	return modifier

func _create_poison_clouds() -> SpecialEffectResource:
	var effect = SpecialEffectResource.new()
	effect.effect_name = "poison_clouds"
	effect.effect_type = SpecialEffectResource.EffectType.ON_HIT_EFFECT
	effect.set_parameter("cloud_radius", 80.0)
	effect.set_parameter("duration", 5.0)
	return effect

func _create_poison_aura() -> SpecialEffectResource:
	var effect = SpecialEffectResource.new()
	effect.effect_name = "poison_aura"
	effect.effect_type = SpecialEffectResource.EffectType.PASSIVE_EFFECT
	effect.set_parameter("spread_interval", 2.0)
	effect.set_parameter("aura_radius", 120.0)
	return effect

func _create_infectious_death() -> SpecialEffectResource:
	var effect = SpecialEffectResource.new()
	effect.effect_name = "infectious_death"
	effect.effect_type = SpecialEffectResource.EffectType.ON_HIT_EFFECT
	effect.set_parameter("explosion_radius", 100.0)
	effect.set_parameter("spread_poison", true)
	return effect

func _create_poison_damage_stacking() -> StatModifier:
	var modifier = StatModifier.new()
	modifier.stat_name = "damage_per_stack"
	modifier.mode = StatModifier.ModifierMode.MULTIPLY
	modifier.multiply = 1.2
	return modifier

func _create_exploding_clouds() -> SpecialEffectResource:
	var effect = SpecialEffectResource.new()
	effect.effect_name = "exploding_clouds"
	effect.effect_type = SpecialEffectResource.EffectType.ON_HIT_EFFECT
	effect.set_parameter("explosion_radius", 100.0)
	effect.set_parameter("explosion_damage", 1.5)
	return effect

# ===================================================================
# PUBLIC API FUNCTIONS - WITH ARRAY TYPE FIX
# ===================================================================

func get_talents_for_level(sauce_name: String, level: int) -> Array[Talent]:
	if talent_trees.has(sauce_name) and talent_trees[sauce_name].has(level):
		# Cast the untyped dictionary array to proper type
		var raw_array = talent_trees[sauce_name][level]
		var typed_talents: Array[Talent] = []
		typed_talents.assign(raw_array)
		return typed_talents
	return _get_default_talents(level)

func _get_default_talents(level: int) -> Array[Talent]:
	var defaults: Array[Talent] = []

	defaults.append(Talent.create_stat_talent("More Damage", "+50% damage", level,
		[StatModifier.create_damage_boost(0.5)]))
	defaults.append(Talent.create_stat_talent("Faster Shooting", "+50% fire rate", level,
		[StatModifier.create_fire_rate_multiplier(1.5)]))
	defaults.append(Talent.create_stat_talent("Longer Range", "+50% range", level,
		[StatModifier.create_range_boost(0.5)]))

	return defaults

func get_talent_by_choice(sauce_name: String, level: int, choice: int) -> Talent:
	var talents = get_talents_for_level(sauce_name, level)
	if choice >= 1 and choice <= talents.size():
		return talents[choice - 1]
	return null

# Aura effect management
func apply_aura_effect(source_bottle: ImprovedBaseSauceBottle, talent: Talent):
	match talent.talent_name:
		"Condiment Synergy":
			_apply_condiment_synergy(source_bottle)

func remove_aura_effect(source_bottle: ImprovedBaseSauceBottle, talent: Talent):
	match talent.talent_name:
		"Condiment Synergy":
			_remove_condiment_synergy(source_bottle)

func _apply_condiment_synergy(source_bottle: ImprovedBaseSauceBottle):
	var all_bottles = InventoryManager.get_equipped_bottles()
	for bottle in all_bottles:
		if bottle != source_bottle:
			# Give other bottles 25% of ketchup's bonuses
			var bonus_modifier = StatModifier.new()
			bonus_modifier.stat_name = "damage"
			bonus_modifier.mode = StatModifier.ModifierMode.MULTIPLY
			bonus_modifier.multiply = 1.25
			bottle.modify_stat(bonus_modifier)
			print("Condiment Synergy boosted %s!" % bottle.sauce_data.sauce_name)

func _remove_condiment_synergy(source_bottle: ImprovedBaseSauceBottle):
	# Would need to track and remove the specific synergy bonuses
	print("Removed Condiment Synergy from %s" % source_bottle.bottle_id)
