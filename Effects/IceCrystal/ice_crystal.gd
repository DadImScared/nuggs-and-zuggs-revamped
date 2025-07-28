# Scenes/Effects/ice_crystal.gd
class_name IceCrystal
extends Area2D

@onready var sprite = $Sprite2D
@onready var collision = $CollisionShape2D
@onready var lifetime_timer = $LifetimeTimer

var damage: float = 15.0
var source_bottle_id: String = ""
var has_hit_enemies: Array[Node2D] = []

signal crystal_shattered

func _ready():
	# Set up collision detection
	body_entered.connect(_on_body_entered)

	# Set up lifetime timer
	lifetime_timer.wait_time = 0.8  # Crystals last 0.8 seconds
	lifetime_timer.one_shot = true
	lifetime_timer.timeout.connect(_shatter_crystal)
	lifetime_timer.start()

	# Create emergence animation
	_animate_emergence()

	print("🧊 Ice crystal created with %.1f damage" % damage)

func setup_crystal(crystal_damage: float, bottle_id: String, crystal_color: Color = Color.CYAN):
	"""Initialize the ice crystal with damage and source"""
	damage = crystal_damage
	source_bottle_id = bottle_id

	# Apply color to sprite
	if sprite:
		sprite.modulate = crystal_color

func _animate_emergence():
	"""Animate ice crystal emerging from ground"""
	if not sprite:
		return

	# Start small and grow
	sprite.scale = Vector2.ZERO

	# Create emergence tween
	var tween = create_tween()
	tween.set_parallel(true)

	# Scale up with slight overshoot
	tween.tween_property(sprite, "scale", Vector2(1.2, 1.2), 0.15)
	tween.tween_property(sprite, "scale", Vector2(1.0, 1.0), 0.1).set_delay(0.15)

	# Slight rotation for dynamic feel
	tween.tween_property(sprite, "rotation", deg_to_rad(randf_range(-10, 10)), 0.25)

	# Add slight position offset for impact effect
	var original_pos = global_position
	global_position += Vector2(randf_range(-5, 5), randf_range(-5, 5))
	tween.tween_property(self, "global_position", original_pos, 0.2)

func _on_body_entered(body: Node2D):
	"""Handle enemy collision with ice crystal"""
	if not body.is_in_group("enemies"):
		return

	# Prevent hitting the same enemy multiple times
	if body in has_hit_enemies:
		return

	has_hit_enemies.append(body)

	# Deal damage to enemy
	if body.has_method("take_damage_from_source"):
		body.take_damage_from_source(damage, source_bottle_id)
		print("🧊 Ice crystal hit %s for %.1f damage" % [body.name, damage])

	# Create hit effect
	_create_hit_effect(body.global_position)

	# Small crystal doesn't shatter on hit, can hit multiple enemies
	# Only shatters when lifetime expires

func _shatter_crystal():
	"""Shatter the ice crystal with visual effect"""
	_create_shatter_effect()
	crystal_shattered.emit()

	# Brief delay for shatter effect, then cleanup
	await get_tree().create_timer(0.2).timeout
	queue_free()

func _create_hit_effect(hit_position: Vector2):
	"""Create particle effect when crystal hits enemy"""
	# Create small ice particles
	for i in range(5):
		var particle = ColorRect.new()
		particle.size = Vector2(3, 3)
		particle.color = Color.CYAN
		particle.global_position = hit_position + Vector2(randf_range(-10, 10), randf_range(-10, 10))
		get_tree().current_scene.add_child(particle)

		# Animate particle
		var tween = particle.create_tween()
		tween.set_parallel(true)
		tween.tween_property(particle, "global_position",
			particle.global_position + Vector2(randf_range(-20, 20), randf_range(-20, 20)), 0.3)
		tween.tween_property(particle, "modulate:a", 0.0, 0.3)
		tween.tween_callback(particle.queue_free)

func _create_shatter_effect():
	"""Create shatter effect when crystal expires"""
	# Create shatter particles around crystal
	for i in range(8):
		var shard = ColorRect.new()
		shard.size = Vector2(4, 4)
		shard.color = Color.LIGHT_BLUE
		shard.global_position = global_position
		get_tree().current_scene.add_child(shard)

		# Random shard direction
		var direction = Vector2.from_angle(randf() * TAU)
		var distance = randf_range(15, 35)

		var tween = shard.create_tween()
		tween.set_parallel(true)
		tween.tween_property(shard, "global_position",
			global_position + direction * distance, 0.4)
		tween.tween_property(shard, "modulate:a", 0.0, 0.4)
		tween.tween_property(shard, "rotation", randf_range(-TAU, TAU), 0.4)
		tween.tween_callback(shard.queue_free)

	print("🧊 Ice crystal shattered!")

# Optional: Add physics for more dynamic crystals
func add_physics_body():
	"""Convert to RigidBody2D for physics-based crystals"""
	# This would be for more advanced ice crystal behavior
	# Like crystals that can be pushed around or affected by explosions
	pass
