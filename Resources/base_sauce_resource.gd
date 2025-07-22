class_name BaseSauceResource
extends Resource

@export var sauce_name: String
@export var description: String
@export var icon: Texture2D
@export var geological_period: String

# Base stats
@export var damage: float = 25.0
@export var fire_rate: float = 1.0
@export var range: float = 200.0
@export var projectile_count: int = 1
@export var projectile_speed: float = 300.0
@export var pierce_count: int = 0
@export var base_radius: float = 120.0

# Effect properties
@export var effect_chance: float = 0.1
@export var effect_intensity: float = 1.0
@export var effect_duration: float = 3.0

# Projectile and visual settings
@export var projectile_scene: PackedScene
@export var projectile_behavior: ProjectileBehavior
@export var orbit_speed: float = 2.0
@export var orbit_distance: float = 50.0
@export var sauce_color: Color = Color.RED

# Special effect type
@export var special_effect_type: SpecialEffectType = SpecialEffectType.NONE

# Level scaling factors (how much each stat improves per level)
@export var damage_per_level: float = 5.0
@export var fire_rate_per_level: float = 0.1
@export var range_per_level: float = 10.0
@export var effect_chance_per_level: float = 0.05
@export var effect_intensity_per_level: float = 0.1
@export var radius_per_level: float = 2

enum SpecialEffectType {
	NONE,
	BURN,           # Fire damage over time
	POISON,         # Damage over time + health reduction
	SLOW,           # Reduce enemy speed
	FREEZE,         # Stop enemy movement
	STICKY,         # Enemies stick together/to ground
	EXPLODE,        # Area damage on impact
	CHAIN,          # Projectile jumps to nearby enemies
	HEAL,           # Heal player on hit
	MULTIPLY,       # Projectile splits on impact
	MAGNETIZE,      # Attracts nearby enemies
	SHIELD_BREAK,   # Ignores enemy shields
	LEECH,          # Steal health from enemies
	LIGHTNING,      # Chain lightning effect
	TORNADO,        # Spawns a tornado that moves around
	INFECT,         # Spreads infection between enemies
	PIERCE,         # Goes through enemies (for behavior factory)
	BOUNCE,         # Projectile bounces off walls/enemies
	QUANTUM,        # Quantum effects
	CURSE,          # Reduce enemy damage/stats
	CHAOS,          # Random effect each shot
	GROWTH,         # Damage increases over distance
	RICOCHET,       # Bounces between enemies
	MARK,       	# Mark enemies for bonus damage,
	GLAZE_POOL,     # Creates growing damage zones
	CARAMELIZE,     # Makes enemies brittle (bonus damage)
	FERMENT,     	# Effects that improve over time,
	VOLCANIC_RING,	# Creates expanding damage rings,
	FOSSILIZE,      # Freezes enemies in amber (Apple Butter)
}

func get_current_effect_radius(level):
	return base_radius + (radius_per_level * (level - 1))

# Get current stats with level modifiers applied
func get_current_damage(level: int = 1) -> float:
	return damage + (damage_per_level * (level - 1))

func get_current_fire_rate(level: int = 1) -> float:
	return fire_rate + (fire_rate_per_level * (level - 1))

func get_current_range(level: int = 1) -> float:
	return range + (range_per_level * (level - 1))

func get_current_effect_chance(level: int = 1) -> float:
	return min(1.0, effect_chance + (effect_chance_per_level * (level - 1)))

func get_current_effect_intensity(level: int = 1) -> float:
	return effect_intensity + (effect_intensity_per_level * (level - 1))

# Utility functions
func get_display_name() -> String:
	return sauce_name

func get_effect_description() -> String:
	match special_effect_type:
		SpecialEffectType.BURN:
			return "Burns enemies for damage over time"
		SpecialEffectType.POISON:
			return "Poisons enemies, dealing damage and spreading"
		SpecialEffectType.SLOW:
			return "Slows enemy movement speed"
		SpecialEffectType.FREEZE:
			return "Freezes enemies in place temporarily"
		SpecialEffectType.STICKY:
			return "Makes enemies stick to the ground"
		SpecialEffectType.EXPLODE:
			return "Explodes on impact, damaging nearby enemies"
		SpecialEffectType.CHAIN:
			return "Chains between nearby enemies"
		SpecialEffectType.HEAL:
			return "Heals the player on hit"
		SpecialEffectType.MULTIPLY:
			return "Creates additional projectiles"
		SpecialEffectType.MAGNETIZE:
			return "Pulls enemies toward the impact point"
		SpecialEffectType.SHIELD_BREAK:
			return "Breaks through enemy shields"
		SpecialEffectType.LEECH:
			return "Steals health from enemies"
		SpecialEffectType.LIGHTNING:
			return "Creates chain lightning between enemies"
		SpecialEffectType.TORNADO:
			return "Spawns a tornado that moves around"
		SpecialEffectType.INFECT:
			return "Spreads infection between enemies"
		SpecialEffectType.PIERCE:
			return "Goes through multiple enemies"
		SpecialEffectType.BOUNCE:
			return "Bounces off walls and enemies"
		SpecialEffectType.QUANTUM:
			return "Quantum phase effects"
		SpecialEffectType.CURSE:
			return "Reduces enemy damage and stats"
		SpecialEffectType.CHAOS:
			return "Random effect each shot"
		SpecialEffectType.GROWTH:
			return "Damage increases over distance"
		SpecialEffectType.RICOCHET:
			return "Bounces between enemies"
		SpecialEffectType.MARK:
			return "Marks enemies for bonus damage"
		_:
			return "No special effect"

# Stats summary for UI
func get_stats_summary(level: int = 1) -> Dictionary:
	return {
		"damage": get_current_damage(level),
		"fire_rate": get_current_fire_rate(level),
		"range": get_current_range(level),
		"projectile_count": projectile_count,
		"pierce_count": pierce_count,
		"effect_chance": get_current_effect_chance(level),
		"effect_intensity": get_current_effect_intensity(level),
		"effect_type": SpecialEffectType.keys()[special_effect_type]
	}

# Create a duplicate with independent stats (for bottle instances)
func duplicate_for_bottle() -> BaseSauceResource:
	var duplicated = duplicate()
	return duplicated
