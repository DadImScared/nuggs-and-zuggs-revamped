# Singletons/talent_manager.gd
extends Node

# Talent trees organized by sauce name and level
var talent_trees: Dictionary = {}
var talent_pools = {}

const COHERENCE_CHANCE = 0.4  # 40% chance to prefer synergistic talents
const MIN_VARIETY = 1         # Always guarantee at least 1 different theme
const MAX_SAME_THEME = 2      # Never show more than 2 of same theme

# Add to TalentManager - Smart selection metadata
enum TalentTier {
	FOUNDATION = 1,    # Levels 1-3: Basic mechanics, stats
	SPECIALIZATION = 2, # Levels 4-6: Build direction, synergies
	LEGENDARY = 3       # Levels 7-10: Game-changing effects
}

enum TalentTheme {
	INFECTION,     # Infection-related talents
	DAMAGE,        # Pure damage/stats
	UTILITY,       # Fire rate, range, etc.
	DEFENSIVE,     # Healing, shields, survival
	EXPLOSIVE,     # AoE, explosions, volcanic rings
	EXPERIMENTAL   # Wild, unique mechanics
}

func _ready():
	print("TalentManager initialized")
	_build_talent_trees()

func _build_talent_trees():
	# Keep existing fixed trees for backwards compatibility
	var pesto_tree = PrehistoricPestoTalents.new()
	talent_trees["Prehistoric Pesto"] = pesto_tree.build_talent_tree()
	talent_trees["Ketchup"] = _build_ketchup_talents()
	talent_trees["Mustard"] = _build_mustard_talents()
	talent_trees["Jurassic Jalapeno"] = _build_jurassic_jalapeno_talents()

	# Build new pool system using existing talent tree classes
	_build_talent_pools()

	print("✅ Talent trees built for %d sauces" % talent_trees.keys().size())
	print("✅ Talent pools built for %d sauces" % talent_pools.keys().size())

func _build_talent_pools():
	# Use existing talent tree classes to build pools
	var pesto_tree = PrehistoricPestoTalents.new()
	if pesto_tree.has_method("build_talent_pool"):
		talent_pools["Prehistoric Pesto"] = pesto_tree.build_talent_pool()
		print("✅ Built talent pool for Prehistoric Pesto with %d talents" % talent_pools["Prehistoric Pesto"].size())
	else:
		print("⚠️ PrehistoricPestoTalents doesn't have build_talent_pool() method yet")

func _build_jurassic_jalapeno_talents():
	var jalapeno_talents = {}

	jalapeno_talents[2] = [
		Talent.create_trigger_talent(
			"Spicy Burst",
			 "Every 3rd shot creates a mini-volcano",
			2,
			[_create_mini_volcano_trigger()]
		),
		Talent.create_effect_talent(
			"Collapsing Rings",
			"Rings collapse inward, hitting enemies twice",
			2,
			[_create_volcanic_collapsing_rings()]
		),
		Talent.create_effect_talent(
			"Molten Pools",
			"Rings leave burning ground for 4 seconds",
			2,
			[_create_molten_pools_effect()]
		)
	]

	return jalapeno_talents


func _build_ketchup_talents() -> Dictionary:
	var ketchup_talents = {}

	# Level 1 talents
	ketchup_talents[1] = [
		Talent.create_stat_talent("Thick & Chunky", "+5 Damage from grandpa's heavy hand", 1,
			[StatModifier.create_damage_boost(5.0)]),
		Talent.create_stat_talent("Double Squirt", "+1 Projectile because two pumps better than one", 1,
			[_create_projectile_boost(1)]),
		Talent.create_stat_talent("Fast Food", "+0.3 Fire Rate - waiting is for restaurants", 1,
			[_create_fire_rate_boost(0.3)])
	]

	# Level 2 talents
	ketchup_talents[2] = [
		Talent.create_stat_talent("Extra Thick", "+8 Damage", 2,
			[StatModifier.create_damage_boost(8.0)]),
		Talent.create_stat_talent("Triple Squirt", "+2 Projectiles", 2,
			[_create_projectile_boost(2)]),
		Talent.create_stat_talent("Speed Demon", "+0.5 Fire Rate", 2,
			[_create_fire_rate_boost(0.5)])
	]

	# Level 3 talents
	ketchup_talents[3] = [
		Talent.create_stat_talent("Mega Chunky", "+12 Damage", 3,
			[StatModifier.create_damage_boost(12.0)]),
		Talent.create_stat_talent("Burst Fire", "+3 Projectiles", 3,
			[_create_projectile_boost(3)]),
		Talent.create_stat_talent("Machine Gun", "+0.8 Fire Rate", 3,
			[_create_fire_rate_boost(0.8)])
	]

	return ketchup_talents

func _build_prehistoric_pesto_talents() -> Dictionary:
	var pesto_talents = {}

	# Level 1 talents
	pesto_talents[1] = [
		Talent.create_stat_talent("Viral Load", "+30% Effect Chance - spreads like gossip", 1,
			[_create_effect_chance_boost(0.3)]),
		Talent.create_stat_talent("Rapid Mutation", "+0.5 Fire Rate - evolution doesn't wait", 1,
			[_create_fire_rate_boost(0.5)]),
		Talent.create_stat_talent("Toxic Herbs", "+3 Damage from herbs that survived the meteor", 1,
			[StatModifier.create_damage_boost(3.0)])
	]

	# Level 2 talents
	pesto_talents[2] = [
		Talent.create_stat_talent("Epidemic", "+50% Effect Chance", 2,
			[_create_effect_chance_boost(0.5)]),
		Talent.create_stat_talent("Evolution", "+0.8 Fire Rate", 2,
			[_create_fire_rate_boost(0.8)]),
		Talent.create_stat_talent("Ancient Power", "+6 Damage", 2,
			[StatModifier.create_damage_boost(6.0)])
	]

	# Level 3 talents
	pesto_talents[3] = [
		Talent.create_stat_talent("Pandemic", "+70% Effect Chance", 3,
			[_create_effect_chance_boost(0.7)]),
		Talent.create_stat_talent("Hyper Evolution", "+1.2 Fire Rate", 3,
			[_create_fire_rate_boost(1.2)]),
		Talent.create_stat_talent("Meteor Impact", "+10 Damage", 3,
			[StatModifier.create_damage_boost(10.0)])
	]

	return pesto_talents

func _build_mustard_talents() -> Dictionary:
	var mustard_talents = {}

	# Level 1 talents
	mustard_talents[1] = [
		Talent.create_stat_talent("Sharp Bite", "+4 Damage", 1,
			[StatModifier.create_damage_boost(4.0)]),
		Talent.create_stat_talent("Steady Stream", "+0.4 Fire Rate", 1,
			[_create_fire_rate_boost(0.4)]),
		Talent.create_stat_talent("Long Reach", "+30 Range", 1,
			[StatModifier.create_range_boost(30.0)])
	]

	# Level 2 talents
	mustard_talents[2] = [
		Talent.create_stat_talent("Cutting Edge", "+7 Damage", 2,
			[StatModifier.create_damage_boost(7.0)]),
		Talent.create_stat_talent("Rapid Fire", "+0.7 Fire Rate", 2,
			[_create_fire_rate_boost(0.7)]),
		Talent.create_stat_talent("Extended Range", "+50 Range", 2,
			[StatModifier.create_range_boost(50.0)])
	]

	# Level 3 talents
	mustard_talents[3] = [
		Talent.create_stat_talent("Razor Sharp", "+11 Damage", 3,
			[StatModifier.create_damage_boost(11.0)]),
		Talent.create_stat_talent("Mustard Storm", "+1.0 Fire Rate", 3,
			[_create_fire_rate_boost(1.0)]),
		Talent.create_stat_talent("Sniper Range", "+80 Range", 3,
			[StatModifier.create_range_boost(80.0)])
	]

	return mustard_talents

func _create_teriyaki_talents():
	var teriyaki_talents = {}
	teriyaki_talents[2] = [
		Talent.create_effect_talent(
			"Ancient Marinade",
			"Each hit on same enemy +20% damage (max 5 stacks)",
			2,
			[_create_damage_stacking()]
		),
		Talent.create_effect_talent(
			"Sticky Glaze",
			"25% chance to create damage pools that grow over time",
			2,
			[_create_glaze_pools()]
		),
		Talent.create_effect_talent(
			"Sweet Caramelization",
			"Enemies hit 3+ times become brittle (+50% damage taken)",
			2,
			[_create_caramelization()]
		)
	]

func _create_mini_volcano_trigger():
	var trigger = TriggerEffectResource.new()
	trigger.trigger_name = "mini_volcano"
	trigger.trigger_type = TriggerEffectResource.TriggerType.ON_SHOT_COUNT
	trigger.effect_name = "create_mini_volcano"
	trigger.trigger_condition["interval"] = 3
	trigger.effect_parameters["damage"] = 15.0
	trigger.effect_parameters["radius"] = 60.0
	return trigger

func _create_volcanic_collapsing_rings() -> SpecialEffectResource:
	var effect = SpecialEffectResource.new()
	effect.effect_name = "volcanic_ring_collapsing"  # Note: matches VolcanicRingAction expectations
	effect.effect_type = SpecialEffectResource.EffectType.ON_HIT_EFFECT
	effect.set_parameter("ring_count", 1)
	effect.set_parameter("collapse_speed", 1.5)
	return effect

func _create_molten_pools_effect() -> SpecialEffectResource:
	var molten_effect = SpecialEffectResource.new()
	molten_effect.effect_name = "volcanic_ring_molten_pools"
	molten_effect.effect_type = SpecialEffectResource.EffectType.ON_HIT_EFFECT
	molten_effect.parameters = {
		"damage_multiplier": 0.3,
		"pool_radius": 45.0,
		"pool_duration": 4.0,
		"tick_rate": 0.5
	}
	return molten_effect

func _create_damage_stacking() -> SpecialEffectResource:
	var effect = SpecialEffectResource.new()
	effect.effect_name = "damage_stacking"
	effect.effect_type = SpecialEffectResource.EffectType.ON_HIT_EFFECT
	effect.set_parameter("damage_per_stack", 0.2)  # +20% per stack
	effect.set_parameter("max_stacks", 5)
	return effect

func _create_glaze_pools() -> SpecialEffectResource:
	var effect = SpecialEffectResource.new()
	effect.effect_name = "glaze_pools"
	effect.effect_type = SpecialEffectResource.EffectType.ON_HIT_EFFECT
	effect.set_parameter("chance", 0.25)
	effect.set_parameter("initial_radius", 60.0)
	effect.set_parameter("growth_rate", 5.0)  # +5 pixels per second
	effect.set_parameter("duration", 12.0)
	return effect

func _create_caramelization() -> SpecialEffectResource:
	var effect = SpecialEffectResource.new()
	effect.effect_name = "caramelization"
	effect.effect_type = SpecialEffectResource.EffectType.ON_HIT_EFFECT
	effect.set_parameter("hits_required", 3)
	effect.set_parameter("damage_bonus", 0.5)  # +50% damage taken
	effect.set_parameter("duration", 8.0)
	return effect

# Helper functions using existing StatModifier
func _create_fire_rate_boost(amount: float) -> StatModifier:
	var mod = StatModifier.new()
	mod.stat_name = "fire_rate"
	mod.mode = StatModifier.ModifierMode.ADD
	mod.add = amount
	return mod

func _create_projectile_boost(amount: int) -> StatModifier:
	var mod = StatModifier.new()
	mod.stat_name = "projectile_count"
	mod.mode = StatModifier.ModifierMode.ADD
	mod.add = float(amount)
	return mod

func _create_effect_chance_boost(amount: float) -> StatModifier:
	var mod = StatModifier.new()
	mod.stat_name = "effect_chance"
	mod.mode = StatModifier.ModifierMode.ADD
	mod.add = amount
	return mod

# Public API functions
func get_talents_for_level(sauce_name: String, level: int, bottle: ImprovedBaseSauceBottle = null) -> Array[Talent]:
	# If no bottle provided or no pools exist, fall back to fixed trees
	if not bottle or not talent_pools.has(sauce_name):
		print("📚 Using fixed tree for %s level %d" % [sauce_name, level])
		return _get_fixed_tree_talents(sauce_name, level)

	print("🧠 Smart selection for %s level %d" % [sauce_name, level])

	# Get available talent pool
	var available_talents = _get_available_talents_for_bottle(sauce_name, level, bottle)

	if available_talents.size() < 3:
		print("⚠️ Warning: Only %d talents available, falling back to fixed tree" % available_talents.size())
		return _get_fixed_tree_talents(sauce_name, level)

	# Smart selection with medium coherence
	return _select_smart_talents(available_talents, bottle, 3)


func _get_default_talents(level: int) -> Array[Talent]:
	return [
		Talent.create_stat_talent("More Damage", "+3 damage", level,
			[StatModifier.create_damage_boost(3.0)]),
		Talent.create_stat_talent("Faster Shooting", "+0.2 fire rate", level,
			[_create_fire_rate_boost(0.2)]),
		Talent.create_stat_talent("Longer Range", "+20 range", level,
			[StatModifier.create_range_boost(20.0)])
	] as Array[Talent]

func get_talent_by_choice(sauce_name: String, level: int, choice: int, bottle = null) -> Talent:
	var talents = get_talents_for_level(sauce_name, level, bottle)
	if choice >= 1 and choice <= talents.size():
		var talent = talents[choice - 1]
		print("Retrieved talent: %s for choice %d" % [talent.talent_name, choice])
		return talent

	print("❌ Invalid talent choice: %d for %s level %d" % [choice, sauce_name, level])
	return null

# Aura effect management
func apply_aura_effect(source_bottle: ImprovedBaseSauceBottle, talent: Talent):
	print("Applying aura effect: %s" % talent.talent_name)
	# Implement specific aura effects here

func remove_aura_effect(source_bottle: ImprovedBaseSauceBottle, talent: Talent):
	print("Removing aura effect: %s" % talent.talent_name)
	# Implement aura removal here

func get_talent_tier(level: int) -> TalentTier:
	if level <= 3:
		return TalentTier.FOUNDATION
	elif level <= 6:
		return TalentTier.SPECIALIZATION
	else:
		return TalentTier.LEGENDARY

func _get_fixed_tree_talents(sauce_name: String, level: int) -> Array[Talent]:
	"""Fallback to original fixed tree system"""
	if talent_trees.has(sauce_name) and talent_trees[sauce_name].has(level):
		var talents_untyped = talent_trees[sauce_name][level]
		var typed_talents: Array[Talent] = []
		for t in talents_untyped:
			typed_talents.append(t)
		return typed_talents
	return _get_default_talents(level)

func _get_available_talents_for_bottle(sauce_name: String, level: int, bottle: ImprovedBaseSauceBottle) -> Array[Talent]:
	"""Get all talents available for this bottle (filter by tier and exclude owned)"""
	var pool = talent_pools.get(sauce_name, [])
	var available: Array[Talent] = []
	var tier = get_talent_tier(level)

	for talent in pool:
		# Filter by tier (foundation/specialization/legendary)
		var talent_tier = get_talent_tier(talent.level_required)
		if talent_tier != tier:
			continue

		# Exclude talents bottle already has
		if _bottle_has_talent(bottle, talent.talent_name):
			continue

		available.append(talent)

	print("🎯 %d available talents for tier %s" % [available.size(), TalentTier.keys()[tier]])
	return available

func _select_smart_talents(available_talents: Array[Talent], bottle: ImprovedBaseSauceBottle, count: int) -> Array[Talent]:
	"""Use smart selection with 40% coherence to pick talents"""
	var selected: Array[Talent] = []
	var bottle_themes = _analyze_bottle_themes(bottle)

	print("📊 Bottle theme analysis: %s" % str(bottle_themes))

	for i in range(count):
		var talent = _pick_next_talent(available_talents, selected, bottle_themes)
		if talent:
			selected.append(talent)
			available_talents.erase(talent)  # Don't pick same talent twice

	# Fill remaining slots if we didn't get enough
	while selected.size() < count and available_talents.size() > 0:
		var random_talent = available_talents[randi() % available_talents.size()]
		selected.append(random_talent)
		available_talents.erase(random_talent)
	var talent_names = []
	for t in selected:
		talent_names.append(t.talent_name)
	print("✨ Selected talents: %s" % str(talent_names))
	#print("✨ Selected talents: %s" % [t.talent_name for t in selected])
	return selected

func _analyze_bottle_themes(bottle: ImprovedBaseSauceBottle) -> Dictionary:
	"""Analyze bottle's existing talents to determine build themes"""
	var theme_counts = {}

	# Initialize all theme counts
	for theme in TalentTheme.values():
		theme_counts[theme] = 0

	# Count themes from existing talents
	for talent in bottle.active_talents:
		var theme = TalentTheme.DAMAGE  # Default theme
		if "talent_theme" in talent:
			theme = talent.talent_theme
		theme_counts[theme] += 1

	return theme_counts

func _pick_next_talent(available: Array[Talent], already_selected: Array[Talent], bottle_themes: Dictionary) -> Talent:
	"""Pick one talent using coherence rules"""

	# Get themes already selected this round
	var selected_themes = {}
	for theme in TalentTheme.values():
		selected_themes[theme] = 0
	for talent in already_selected:
		var theme = TalentTheme.DAMAGE  # Default theme
		if "talent_theme" in talent:
			theme = talent.talent_theme
		selected_themes[theme] += 1

	# Find dominant bottle theme
	var dominant_theme = TalentTheme.DAMAGE
	var max_count = 0
	for theme in bottle_themes:
		if bottle_themes[theme] > max_count:
			max_count = bottle_themes[theme]
			dominant_theme = theme

	# Apply coherence (40% chance to prefer dominant theme)
	if randf() < COHERENCE_CHANCE and max_count > 0:
		# Try to find talent matching dominant theme
		var matching_talents = available.filter(func(t):
			var theme = TalentTheme.DAMAGE
			if "talent_theme" in t:
				theme = t.talent_theme
			return theme == dominant_theme
		)
		if matching_talents.size() > 0 and selected_themes[dominant_theme] < MAX_SAME_THEME:
			print("🎯 Coherence: Picking %s theme talent" % TalentTheme.keys()[dominant_theme])
			return matching_talents[randi() % matching_talents.size()]

	# Ensure variety - never pick more than 2 of same theme
	var valid_talents = available.filter(func(t):
		var theme = TalentTheme.DAMAGE
		if "talent_theme" in t:
			theme = t.talent_theme
		return selected_themes[theme] < MAX_SAME_THEME
	)

	if valid_talents.size() == 0:
		# Emergency fallback
		return available[randi() % available.size()]

	print("🎲 Random selection from %d valid talents" % valid_talents.size())
	return valid_talents[randi() % valid_talents.size()]

func _bottle_has_talent(bottle: ImprovedBaseSauceBottle, talent_name: String) -> bool:
	"""Check if bottle already has this talent"""
	for talent in bottle.active_talents:
		if talent.talent_name == talent_name:
			return true
	return false
