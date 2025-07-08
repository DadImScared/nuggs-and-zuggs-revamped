extends Area2D

var velocity = Vector2.ZERO
var sauce_damage: float
var max_range: float = 1200
var start_position: Vector2
var sauce_resource: BaseSauceResource

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

func launch(start_pos: Vector2, direction: Vector2, sauce: BaseSauceResource):
	global_position = start_pos
	start_position = start_pos
	velocity = direction.normalized() * sauce.projectile_speed
	max_range = sauce.range
	rotation = direction.angle()
	sauce_damage = sauce.damage
	modulate = sauce.sauce_color
	sauce_resource = sauce

	projectile_behavior = ProjectileBehaviorFactory.create_behavior(sauce_resource)

func handle_enemy_hit(enemy: Node2D):
	SauceEffectManager.apply_effect(self, enemy, sauce_resource)

	var should_destroy = projectile_behavior.handle_hit(self, enemy)

	if should_destroy:
		queue_free()

func get_scaled_damage() -> float:
	var base_scale = 1.0 + (PlayerStats.level - 1)
	var damage_scale = base_scale * 0.1
	return sauce_damage + (sauce_damage * damage_scale)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("enemies"):
		handle_enemy_hit(body)
