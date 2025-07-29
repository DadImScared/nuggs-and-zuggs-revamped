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

	# Set up explosion timer as fallback - longer for machine snowballs
	var timeout_duration = 3.0 if has_meta("machine_snowball") else 3.0
	explosion_timer.wait_time = timeout_duration
	explosion_timer.one_shot = true
	explosion_timer.timeout.connect(_timeout_destroy)  # Changed from _explode to _timeout_destroy
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

	# Check if we've reached the target area - but only for regular snowballs
	if not has_meta("machine_snowball") and global_position.distance_to(target_position) < 20.0:
		_explode()

func _on_body_entered(body):
	if has_exploded:
		return

	# Check if this is a machine snowball (pierces through enemies)
	if has_meta("machine_snowball"):
		# Machine snowballs pierce - just apply damage but don't explode
		if body.has_method("take_damage_from_source"):
			var source_bottle = get_meta("source_bottle") if has_meta("source_bottle") else null
			var bottle_id = source_bottle.bottle_id if source_bottle else "machine_snowball"
			body.take_damage_from_source(damage, bottle_id)

			# Apply cold effects directly to pierced enemy
			if source_bottle:
				_apply_machine_cold_to_enemy(body, source_bottle)

			# Create small hit effect but don't explode
			_create_pierce_effect(body.global_position)
		return  # Don't explode, keep flying

	# Regular snowballs explode on hit
	if body.has_method("take_damage"):
		_explode()

func _on_area_entered(area):
	if has_exploded:
		return

	# Machine snowballs pierce through other projectiles too
	if has_meta("machine_snowball"):
		return  # Just keep flying

	# Regular snowballs explode when hitting other areas
	if area != self and area.has_method("take_damage"):
		_explode()

func _timeout_destroy():
	"""Machine snowballs just disappear after timeout, regular snowballs explode"""
	if has_meta("machine_snowball"):
		# Machine snowballs just fade away
		_fade_away()
	else:
		# Regular snowballs explode at target
		_explode()

func _fade_away():
	"""Fade away machine snowballs without explosion"""
	if has_exploded:
		return

	has_exploded = true
	set_process(false)

	if trail_particles:
		trail_particles.emitting = false

	# Fade out visually
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.5)
	tween.tween_callback(queue_free)

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

	# Defer collision and visual changes to avoid physics conflicts
	call_deferred("_disable_collision_and_visuals")

	# Queue for removal after particles finish
	call_deferred("_cleanup_snowball")

func _disable_collision_and_visuals():
	"""Safely disable collision and hide sprite after physics processing"""
	if collision_shape:
		collision_shape.disabled = true
	if animated_sprite:
		animated_sprite.visible = false

func _cleanup_snowball():
	"""Clean up the snowball after explosion"""
	await get_tree().create_timer(1.5).timeout
	if is_instance_valid(self):
		queue_free()

func _apply_machine_cold_to_enemy(enemy: Node, source_bottle: Node):
	"""Apply cold stacks to enemy hit by machine snowball pierce"""
	if not enemy or not is_instance_valid(enemy):
		return

	# Cold parameters for machine snowballs (lighter than regular)
	var cold_stacks = 1  # Only 1 stack per pierce
	var enhanced_params = {
		"duration": 2.0,  # Shorter duration
		"tick_interval": 0.0,
		"tick_damage": 0.0,
		"max_stacks": 6,
		"stack_value": 1.0,
		"slow_per_stack": 0.15,
		"freeze_threshold": 6,
		"cold_color": Color(0.7, 0.9, 1.0, 0.8),
		"tick_effect": null
	}

	# Use the Effects system to apply cold
	if Effects and Effects.cold:
		Effects.cold.apply_from_talent(enemy, source_bottle, cold_stacks, enhanced_params)

func _create_pierce_effect(hit_position: Vector2):
	"""Create small visual effect when machine snowball pierces an enemy"""
	var pierce_particles = CPUParticles2D.new()
	get_tree().current_scene.add_child(pierce_particles)

	pierce_particles.global_position = hit_position
	pierce_particles.emitting = true
	pierce_particles.amount = 8
	pierce_particles.lifetime = 0.4
	pierce_particles.one_shot = true
	pierce_particles.explosiveness = 1.0

	# Small puff effect
	pierce_particles.spread = 60.0
	pierce_particles.initial_velocity_min = 30.0
	pierce_particles.initial_velocity_max = 60.0
	pierce_particles.color = Color(0.8, 0.9, 1.0, 0.8)

	# Clean up quickly
	await get_tree().create_timer(0.5).timeout
	if is_instance_valid(pierce_particles):
		pierce_particles.queue_free()

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
