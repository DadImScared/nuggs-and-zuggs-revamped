extends Area2D
class_name Snowball

signal snowball_exploded(position: Vector2, radius: float, damage: float)

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var explosion_timer: Timer = $ExplosionTimer
@onready var trail_particles: CPUParticles2D = $TrailParticles

var damage: float = 25.0
var splash_radius: float = 200.0
var splash_damage_multiplier: float = 0.5
var speed: float = 400.0
var target_position: Vector2
var direction: Vector2
var has_exploded: bool = false

func _ready():
	# Set up collision detection
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)

	# Set up explosion timer as fallback
	explosion_timer.wait_time = 3.0
	explosion_timer.one_shot = true
	explosion_timer.timeout.connect(_explode)
	explosion_timer.start()

	# Start spinning animation
	if animated_sprite:
		animated_sprite.play("spin")

	# Set up trail particles
	_setup_trail_particles()

func initialize(spawn_pos: Vector2, target_pos: Vector2, dmg: float, radius: float, splash_mult: float):
	global_position = spawn_pos
	target_position = target_pos
	damage = dmg
	splash_radius = radius
	splash_damage_multiplier = splash_mult

	direction = (target_position - global_position).normalized()

func _setup_trail_particles():
	"""Set up the trailing particle effect as snowball flies"""
	if not trail_particles:
		return

	trail_particles.emitting = true
	trail_particles.amount = 15
	trail_particles.lifetime = 0.8
	trail_particles.one_shot = false

	# Snow trail properties
	trail_particles.spread = 25.0
	trail_particles.initial_velocity_min = 20.0
	trail_particles.initial_velocity_max = 50.0
	trail_particles.gravity = Vector2(0, 30)
	trail_particles.scale_amount_min = 0.3
	trail_particles.scale_amount_max = 0.8

	# Light blue/white particles
	trail_particles.color = Color(0.9, 0.95, 1.0, 0.8)

func _process(delta):
	if has_exploded:
		return

	# Move towards target
	global_position += direction * speed * delta

	# Check if we've reached the target area
	if global_position.distance_to(target_position) < 20.0:
		_explode()

func _on_body_entered(body):
	if has_exploded:
		return

	# Hit an enemy or obstacle
	if body.has_method("take_damage"):
		_explode()

func _on_area_entered(area):
	if has_exploded:
		return

	# Hit another projectile or area
	if area != self and area.has_method("take_damage"):
		_explode()

func _explode():
	if has_exploded:
		return

	has_exploded = true

	# Stop movement and trail particles
	set_process(false)
	if trail_particles:
		trail_particles.emitting = false

	# Emit signal for splash damage calculation
	snowball_exploded.emit(global_position, splash_radius, damage * splash_damage_multiplier)

	# Create gentle explosion particles instead of bright flash
	_create_explosion_particles()

	# Hide collision and sprite
	collision_shape.disabled = true
	animated_sprite.visible = false

	# Wait for particles to finish
	await get_tree().create_timer(1.5).timeout
	queue_free()

func _create_explosion_particles():
	"""Create gentle snow explosion particles instead of flashbang"""
	var explosion_particles = CPUParticles2D.new()
	add_child(explosion_particles)

	explosion_particles.emitting = true
	explosion_particles.amount = 30
	explosion_particles.lifetime = 1.2
	explosion_particles.one_shot = true
	explosion_particles.explosiveness = 1.0

	# Gentle snow explosion
	explosion_particles.spread = 45.0
	explosion_particles.initial_velocity_min = 80.0
	explosion_particles.initial_velocity_max = 150.0
	explosion_particles.gravity = Vector2(0, 60)
	explosion_particles.scale_amount_min = 0.5
	explosion_particles.scale_amount_max = 1.5

	# Soft white/blue colors - no bright flash!
	explosion_particles.color = Color(0.85, 0.9, 1.0, 0.9)

	# No more flashbang indicator - just particles!
