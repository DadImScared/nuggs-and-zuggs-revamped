extends Area2D

var velocity = Vector2.ZERO
var sauce_damage: float
var max_range: float = 1200
var start_position: Vector2
var sauce_resource: BaseSauceResource

# Leveling and source tracking
var sauce_level: int = 1
var source_bottle_id: String = ""

var has_pierced: Array = []
var bounce_count: int = 0
var max_bounces: int = 3

var projectile_behavior: ProjectileBehavior
@onready var sprite = $Sprite2D

func _ready() -> void:
	pass

func _physics_process(delta: float) -> void:
	global_position += velocity * delta

	if start_position.distance_to(global_position) > max_range:
		queue_free()

func launch(start_pos: Vector2, direction: Vector2, sauce: BaseSauceResource, level = 1, bottle_id = ""):
	global_position = start_pos
	start_position = start_pos
	sauce_level = level
	source_bottle_id = bottle_id
	velocity = direction.normalized() * sauce.get_current_projectile_speed(sauce_level)
	max_range = sauce.get_current_range(sauce_level)
	rotation = direction.angle()
	sauce_damage = sauce.get_current_damage(sauce_level)
	modulate = sauce.sauce_color
	sauce_resource = sauce

	projectile_behavior = ProjectileBehaviorFactory.create_behavior(sauce_resource)

func handle_enemy_hit(enemy: Node2D):
	if enemy.has_method("take_damage_from_source"):
		enemy.take_damage_from_source(get_scaled_damage(), source_bottle_id)
	elif enemy.has_method("take_damage"):
		enemy.take_damage(get_scaled_damage())
	SauceEffectManager.apply_effect(self, enemy, sauce_resource, sauce_level, source_bottle_id)

	var should_destroy = projectile_behavior.handle_hit(self, enemy)

	if should_destroy:
		queue_free()

func get_scaled_damage() -> float:
	# Base damage from leveled sauce
	var base_damage = sauce_resource.get_current_damage(sauce_level)

	# Additional scaling from player level
	var player_scale = 1.0 + (PlayerStats.level - 1) * 0.1

	return base_damage * player_scale

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("enemies"):
		handle_enemy_hit(body)
