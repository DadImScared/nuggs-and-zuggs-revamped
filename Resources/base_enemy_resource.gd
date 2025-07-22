
class_name BaseEnemyResource
extends Resource

# Basic identity
@export var enemy_name: String = "Basic Enemy"
@export var enemy_type: String = "basic"

# Core stats that scale with player level
@export var base_health: float = 30.0
@export var base_damage: float = 10.0
@export var base_speed: float = 18.0
@export var base_xp_reward: int = 5

# Visual appearance
@export var enemy_color: Color = Color.RED
@export var scale_modifier: float = 1.0
@export var apply_color_tint: bool = false

# How likely this enemy is to spawn (higher = more common)
@export var spawn_weight: int = 100
@export var scene_path: String = "res://Scenes/enemy.tscn"

# Animation settings - we'll use these with AnimationPlayer
@export var animation_speed_multiplier: float = 1.0
@export var move_animation_name: String = "move"
@export var hit_animation_name: String = "hit"

# How resistant this enemy is to different effects (1.0 = normal, 0.5 = takes half effect)
@export var burn_resistance: float = 1.0
@export var poison_resistance: float = 1.0
@export var freeze_resistance: float = 1.0
@export var slow_resistance: float = 1.0

# These functions calculate scaled stats based on player level
func get_scaled_health(player_level: int) -> float:
	if player_level < 2:
		return base_health
	var scale_factor = 1.0 + (player_level - 1) * 0.25
	return base_health * scale_factor

func get_scaled_damage(player_level: int) -> float:
	if player_level < 2:
		return base_damage
	var scale_factor = 1.0 + (player_level - 1) * 0.1
	return base_damage * scale_factor

func get_scaled_speed(player_level: int) -> float:
	if player_level < 2:
		return base_speed
	var scale_factor = 1.0 + (player_level - 1) * 0.02
	return base_speed * scale_factor

func get_scaled_xp_reward(player_level: int) -> int:
	if player_level < 2:
		return base_xp_reward
	var scale_factor = 1.0 + (player_level - 1) * 0.10
	return int(base_xp_reward * scale_factor)
