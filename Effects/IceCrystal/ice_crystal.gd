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

	# Make the sprite look like a proper ice spike
	if sprite:
		sprite.modulate = Color(0.8, 0.9, 1.0, 0.9)  # Light blue ice color
		sprite.scale = Vector2(3.0, 8.0)  # Tall ice spike shape

		# Add glow effect
		sprite.material = CanvasItemMaterial.new()
		sprite.material.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD

		print("🧊 Ice crystal sprite setup: scale=%s" % sprite.scale)
	else:
		print("❌ No sprite found in ice crystal!")

	# Reasonable crystal size
	scale = Vector2(4.0, 4.0)

	# Remove the debug circle and add ice particles instead
	_create_ice_particles()

	print("🧊 Ice crystal setup complete - proper ice spike!")

func _create_ice_particles():
	"""Create ice particle effects around the crystal"""
	# Create small ice shards around the main spike
	for i in range(6):
		var shard = ColorRect.new()
		shard.size = Vector2(2, 6)
		shard.color = Color(0.7, 0.8, 1.0, 0.7)

		# Position shards around the main spike
		var angle = (TAU / 6) * i
		var distance = randf_range(8, 15)
		shard.position = Vector2.from_angle(angle) * distance
		shard.rotation = angle + deg_to_rad(90)  # Point outward

		add_child(shard)

		# Subtle sparkle animation
		var tween = shard.create_tween()
		tween.set_loops()
		tween.tween_property(shard, "modulate:a", 0.4, 0.5)
		tween.tween_property(shard, "modulate:a", 0.8, 0.5)

func _animate_emergence():
	"""Animate ice crystal emerging from ground"""
	if not sprite:
		print("❌ No sprite for emergence animation!")
		return

	print("🧊 Starting ice emergence animation")

	# Start buried and emerge upward
	sprite.scale = Vector2(3.0, 0.1)  # Start very flat
	sprite.position.y = 20  # Start below ground

	# Create emergence tween
	var tween = create_tween()
	tween.set_parallel(true)

	# Grow upward like ice forming
	tween.tween_property(sprite, "scale", Vector2(3.5, 9.0), 0.3)  # Overshoot height
	tween.tween_property(sprite, "scale", Vector2(3.0, 8.0), 0.1).set_delay(0.3)  # Settle

	# Emerge from ground
	tween.tween_property(sprite, "position", Vector2(0, 0), 0.4)

	# Slight crystal formation sound effect (visual)
	tween.tween_callback(_create_formation_particles).set_delay(0.2)

	print("🧊 Ice emergence animation started!")

func _create_formation_particles():
	"""Create particles when ice crystal forms"""
	for i in range(8):
		var particle = ColorRect.new()
		particle.size = Vector2(1, 1)
		particle.color = Color.WHITE
		particle.position = Vector2(randf_range(-15, 15), randf_range(-10, 10))

		add_child(particle)

		# Sparkle and fade
		var tween = particle.create_tween()
		tween.parallel().tween_property(particle, "position",
			particle.position + Vector2(randf_range(-20, 20), randf_range(-30, -10)), 0.6)
		tween.parallel().tween_property(particle, "modulate:a", 0.0, 0.6)
		tween.tween_callback(particle.queue_free)

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
