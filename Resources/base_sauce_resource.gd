class_name BaseSauceResource
extends Resource

# how this works is you create a new resource that inherits from this
# it will then create a tres file and you set the values there

@export var sauce_name: String = "Ketchup"
@export var damage: float = 10.0
@export var fire_rate: float = 1.0 # shots per second
@export var projectile_speed: float = 300.0
@export var range: float = 60.0
@export var projectile_count: int = 1
@export var spread_angle: float = 0.0 # in degrees
@export var sauce_color: Color = Color.RED
@export var description = "Grandpa’s secret recipe…\n but he won’t say whose grandpa."

# Special effect system
@export var special_effect_type: SpecialEffectType = SpecialEffectType.NONE
@export var effect_chance: float = 0.0 # 0.0 to 1.0
@export var effect_duration: float = 0.0
@export var effect_intensity: float = 1.0
@export var synergy_tags: Array[String] = [] # For synergy system

# Level scaling - how much each stat improves per level
@export var damage_per_level: float = 2.0
@export var fire_rate_per_level: float = 0.1
@export var range_per_level: float = 5.0
@export var effect_chance_per_level: float = 0.02
@export var effect_intensity_per_level: float = 0.05

enum SpecialEffectType {
	NONE,
	BURN,           # Fire damage over time
	SLOW,           # Reduce enemy speed
	STICKY,         # Enemies stick together/to ground
	CHAIN,          # Projectile jumps to nearby enemies
	EXPLODE,        # Area damage on impact
	PIERCE,         # Goes through enemies
	POISON,         # Damage over time + health reduction
	FREEZE,         # Stop enemy movement
	BOUNCE,         # Projectile bounces off walls
	HEAL,           # Heal player on hit
	MULTIPLY,       # Projectile splits on impact
	MAGNETIZE,      # Attracts nearby enemies
	SHIELD_BREAK,   # Ignores enemy shields
	LEECH,          # Steal health from enemies
	CURSE,          # Reduce enemy damage/stats
	LIGHTNING,      # Chain lightning effect
	CHAOS,          # Random effect each shot
	GROWTH,         # Damage increases over distance
	RICOCHET,       # Bounces between enemies
	MARK,           # Mark enemies for bonus damage
	QUANTUM,
	TORNADO,
	INFECT
}

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

func get_current_projectile_speed(level: int = 1) -> float:
	return projectile_speed # Could add scaling later if needed

func get_current_projectile_count(level: int = 1) -> int:
	return projectile_count # Could add scaling later if needed
