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
	EXPLOSIVE,     # AOE/explosive effects
	CHAOS,         # Random/unpredictable effects
	DEFENSIVE,
	BURN,
	FOSSILIZE
}

func _ready():
	_initialize_talent_trees()
	_initialize_talent_pools()
	print("TalentManager initialized with %d sauce talent trees" % talent_trees.size())

func _initialize_talent_trees():
	"""Initialize the fixed talent trees (legacy system)"""
	talent_trees["Mustard"] = _create_mustard_talents()
	talent_trees["Teriyaki"] = _create_teriyaki_talents()

func _initialize_talent_pools():
	"""Initialize the new pooled talent system"""
	# Hot Sauce
	var hot_sauce_tree = HotSauceTalents.new()
	talent_pools["Hot Sauce"] = hot_sauce_tree.build_talent_pool()

	# Prehistoric Pesto
	var pesto_tree = PrehistoricPestoTalents.new()
	talent_pools["Prehistoric Pesto"] = pesto_tree.build_talent_pool()

	# Archaean Apple Butter
	var apple_butter_tree = ArchaeanAppleButterTalents.new()
	talent_pools["Archaean Apple Butter"] = apple_butter_tree.build_talent_pool()

	print("🎯 Talent pools initialized:")
	for sauce_name in talent_pools:
		print("  %s: %d talents" % [sauce_name, talent_pools[sauce_name].size()])

func get_talents_for_level(sauce_name: String, level: int, bottle: ImprovedBaseSauceBottle) -> Array[Talent]:
	"""Alias for get_talents_for_bottle for backward compatibility"""
	return get_talents_for_bottle(sauce_name, level, bottle)

func get_talents_for_bottle(sauce_name: String, level: int, bottle: ImprovedBaseSauceBottle) -> Array[Talent]:
	"""NEW: Get 3 smart-selected talents for bottle upgrade"""

	# Check if we have a talent pool for this sauce
	if talent_pools.has(sauce_name):
		var available_talents = _get_available_talents_for_bottle(sauce_name, level, bottle)

		if available_talents.size() >= 3:
			return _select_smart_talents(available_talents, bottle, 3)
		elif available_talents.size() > 0:
			# Not enough talents, return what we have
			print("⚠️ Only %d talents available for %s level %d" % [available_talents.size(), sauce_name, level])
			return available_talents
		else:
			print("⚠️ No talents available for %s level %d" % [sauce_name, level])
			return _get_fallback_talents(sauce_name, level)

	# Fallback to old system
	print("⚠️ No talent pool for %s, using legacy system" % sauce_name)
	return _get_talents_legacy(sauce_name, level)

func get_talent_by_choice(sauce_name: String, level: int, choice_number: int, bottle: ImprovedBaseSauceBottle = null) -> Talent:
	"""Get specific talent by choice number (for UI/selection)"""
	# This is used by the UI when player picks a talent
	# We need to maintain the same talents that were shown
	# For now, return from legacy system or implement caching
	return _get_talent_by_choice_legacy(sauce_name, level, choice_number)

func get_talent_tier(level: int) -> TalentTier:
	"""Determine talent tier based on bottle level"""
	if level <= 3:
		return TalentTier.FOUNDATION
	elif level <= 6:
		return TalentTier.SPECIALIZATION
	else:
		return TalentTier.LEGENDARY

# NEW SMART SELECTION SYSTEM
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
	return selected

func _analyze_bottle_themes(bottle: ImprovedBaseSauceBottle) -> Dictionary:
	"""Analyze bottle's existing talents to determine build themes"""
	var theme_counts = {}

	# Initialize all theme counts
	for theme in TalentTheme.values():
		theme_counts[theme] = 0

	# Count themes from existing talents (NEW: supports multiple themes)
	for talent in bottle.active_talents:
		var themes = talent.get_all_themes()  # Use new method
		for theme in themes:
			theme_counts[theme] += 1

	return theme_counts

func _pick_next_talent(available: Array[Talent], already_selected: Array[Talent], bottle_themes: Dictionary) -> Talent:
	"""Pick one talent using coherence rules"""

	# Get themes already selected this round (NEW: supports multiple themes)
	var selected_themes = {}
	for theme in TalentTheme.values():
		selected_themes[theme] = 0
	for talent in already_selected:
		var themes = talent.get_all_themes()  # Use new method
		for theme in themes:
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
		# Try to find talent matching dominant theme (NEW: uses has_theme)
		var matching_talents = available.filter(func(t):
			return t.has_theme(dominant_theme)
		)
		if matching_talents.size() > 0 and selected_themes[dominant_theme] < MAX_SAME_THEME:
			print("🎯 Coherence: Picking %s theme talent" % TalentTheme.keys()[dominant_theme])
			return matching_talents[randi() % matching_talents.size()]

	# Ensure variety - never pick more than 2 of same theme (NEW: uses primary theme)
	var valid_talents = available.filter(func(t):
		var primary_theme = t.get_primary_theme()
		return selected_themes[primary_theme] < MAX_SAME_THEME
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

# LEGACY SYSTEM SUPPORT
func _get_talents_legacy(sauce_name: String, level: int) -> Array[Talent]:
	"""Fallback to original fixed tree system"""
	if talent_trees.has(sauce_name) and talent_trees[sauce_name].has(level):
		var talents_untyped = talent_trees[sauce_name][level]
		var typed_talents: Array[Talent] = []
		for t in talents_untyped:
			typed_talents.append(t)
		return typed_talents
	return _get_default_talents(level)

func _get_talent_by_choice_legacy(sauce_name: String, level: int, choice_number: int) -> Talent:
	"""Legacy talent selection by choice number"""
	if talent_trees.has(sauce_name) and talent_trees[sauce_name].has(level):
		var talents = talent_trees[sauce_name][level]
		if choice_number < talents.size():
			return talents[choice_number]
	return null

func _get_fallback_talents(sauce_name: String, level: int) -> Array[Talent]:
	"""Emergency fallback talents"""
	return _get_default_talents(level)

func _get_default_talents(level: int) -> Array[Talent]:
	"""Default talents when nothing else is available"""
	var defaults: Array[Talent] = []

	defaults.append(Talent.create_stat_talent(
		"Emergency Boost",
		"+5 Damage",
		level,
		[StatModifier.create_damage_boost(5.0)],
		TalentTheme.DAMAGE
	))

	defaults.append(Talent.create_stat_talent(
		"Quick Fix",
		"+0.3 Fire Rate",
		level,
		[_create_fire_rate_boost(0.3)],
		TalentTheme.UTILITY
	))

	defaults.append(Talent.create_stat_talent(
		"Range Extender",
		"+25 Range",
		level,
		[StatModifier.create_range_boost(25.0)],
		TalentTheme.UTILITY
	))

	return defaults

# LEGACY TALENT TREES (Mustard/Teriyaki)
func _create_mustard_talents():
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
	return teriyaki_talents

# UTILITY FUNCTIONS
func _create_fire_rate_boost(amount: float) -> StatModifier:
	var modifier = StatModifier.new()
	modifier.stat_name = "fire_rate"
	modifier.mode = StatModifier.ModifierMode.ADD
	modifier.add = amount
	return modifier

func _create_damage_stacking() -> SpecialEffectResource:
	var effect = SpecialEffectResource.new()
	effect.effect_name = "damage_stacking"
	effect.effect_type = SpecialEffectResource.EffectType.ON_HIT_EFFECT
	return effect

func _create_glaze_pools() -> SpecialEffectResource:
	var effect = SpecialEffectResource.new()
	effect.effect_name = "glaze_pools"
	effect.effect_type = SpecialEffectResource.EffectType.ON_HIT_EFFECT
	return effect

func _create_caramelization() -> SpecialEffectResource:
	var effect = SpecialEffectResource.new()
	effect.effect_name = "caramelization"
	effect.effect_type = SpecialEffectResource.EffectType.ON_HIT_EFFECT
	return effect

func get_theme_name(theme: TalentTheme) -> String:
	"""Get display name for theme"""
	return TalentTheme.keys()[theme].capitalize()
