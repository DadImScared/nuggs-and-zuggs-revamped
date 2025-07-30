# Effects/OrbRotation/orb_rotation.gd
extends Node2D

# Orb Rotation properties
var damage: float = 15.0
var rotation_speed: float = 45.0  # degrees per second
var orb_count: int = 3
var apply_cold: bool = false
var cold_stacks: int = 1
var orb_size: float = 45.0
var knockback_enabled: bool = true
var knockback_force: float = 30.0
var bottle_id: String = ""
var duration: float = 10.0  # How long the orbs last
var follow_target: Node2D = null  # What to orbit around (player, etc.)

# Visual and collision components
var orbs: Array[Node2D] = []
var orb_areas: Array[Area2D] = []
var rotation_angle: float = 0.0
var orbit_radius: float = 60.0

func _ready():
	print("⚪ Orb Rotation scene ready, waiting for initialization...")

func initialize(orb_damage: float, speed: float, num_orbs: int, orb_size_param: float,
			   apply_cold_param: bool, cold_stacks_param: int, knockback: bool,
			   knockback_force_param: float, source_bottle_id: String, follow_target_param: Node2D = null):
	"""Initialize and start the orb rotation effect"""
	damage = orb_damage
	rotation_speed = speed
	orb_count = num_orbs
	orb_size = orb_size_param
	apply_cold = apply_cold_param
	cold_stacks = cold_stacks_param
	knockback_enabled = knockback
	knockback_force = knockback_force_param
	bottle_id = source_bottle_id
	follow_target = follow_target_param

	# If following a target, parent to them so we move together
	if follow_target:
		# Reparent to the target
		var current_parent = get_parent()
		current_parent.remove_child(self)
		follow_target.add_child(self)
		position = Vector2.ZERO  # Reset position relative to target
		print("⚪ Orbs will follow target: %s" % follow_target.name)
	else:
		print("⚪ Orbs will stay at fixed position: %s" % global_position)

	print("⚪ Initializing Orb Rotation - damage: %.0f, speed: %.0f°/s, orbs: %d" % [damage, rotation_speed, orb_count])

	# Create all orbs
	create_rotating_orbs()

	# Start the rotation effect
	start_orb_rotation()

func create_rotating_orbs():
	"""Create the rotating orbs around the center point"""
	for i in range(orb_count):
		var angle_offset = (360.0 / orb_count) * i
		create_single_orb(angle_offset)

	print("✅ Created %d rotating orbs" % orbs.size())

func create_single_orb(angle_offset: float) -> Node2D:
	"""Create a single orb with visual and collision components"""
	var orb_container = Node2D.new()
	orb_container.name = "Orb_%d" % orbs.size()
	add_child(orb_container)

	# Create visual orb using particles for ice effect
	var orb_visual = create_orb_visual()
	orb_container.add_child(orb_visual)

	# Create collision area for damage detection
	var orb_area = create_orb_collision()
	orb_container.add_child(orb_area)

	# Store references
	orbs.append(orb_container)
	orb_areas.append(orb_area)

	# Set initial position based on angle offset
	var initial_angle = deg_to_rad(angle_offset)
	var initial_pos = Vector2(cos(initial_angle) * orbit_radius, sin(initial_angle) * orbit_radius)
	orb_container.position = initial_pos

	return orb_container

func create_orb_visual() -> Node2D:
	"""Create the visual representation of an orb"""
	var visual_container = Node2D.new()
	visual_container.name = "OrbVisual"

	# Create core orb using circular lines
	var orb_core = create_circular_orb()
	visual_container.add_child(orb_core)

	# Create trailing particles
	var trail_particles = create_orb_particles()
	visual_container.add_child(trail_particles)

	return visual_container

func create_circular_orb() -> Node2D:
	"""Create a circular orb using Line2D"""
	var orb_container = Node2D.new()
	orb_container.name = "OrbCore"

	# Create multiple concentric circles for depth
	for i in range(3):
		var circle = Line2D.new()
		circle.width = 2.0 - i * 0.3
		circle.default_color = Color(0.6 + i * 0.1, 0.8 + i * 0.05, 1.0, 0.8 - i * 0.2)
		circle.antialiased = true

		# Generate circle points
		var points = PackedVector2Array()
		var segments = 16
		var circle_radius = (orb_size / 2) - i * 3

		for j in range(segments + 1):
			var angle = j * (PI * 2) / segments
			var point = Vector2(cos(angle) * circle_radius, sin(angle) * circle_radius)
			points.append(point)

		circle.points = points
		orb_container.add_child(circle)

	# Add pulsing animation
	var pulse_tween = create_tween()
	pulse_tween.set_loops()
	pulse_tween.tween_property(orb_container, "scale", Vector2(1.2, 1.2), 0.8)
	pulse_tween.tween_property(orb_container, "scale", Vector2(1.0, 1.0), 0.8)

	return orb_container

func create_orb_particles() -> CPUParticles2D:
	"""Create trailing particles for the orb"""
	var particles = CPUParticles2D.new()
	particles.name = "OrbTrail"

	# Configure trail particles
	particles.emitting = true
	particles.amount = 8
	particles.lifetime = 0.5
	particles.one_shot = false
	particles.explosiveness = 0.0

	# Small trailing effect
	particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	particles.emission_sphere_radius = orb_size / 4
	particles.spread = 360.0
	particles.initial_velocity_min = 5.0
	particles.initial_velocity_max = 15.0
	particles.gravity = Vector2.ZERO
	particles.linear_accel_min = -10.0
	particles.linear_accel_max = -20.0

	# Ice crystal appearance
	particles.scale_amount_min = 0.2
	particles.scale_amount_max = 0.4
	particles.color = Color(0.7, 0.9, 1.0, 0.6)

	return particles

func create_orb_collision() -> Area2D:
	"""Create collision area for orb damage detection"""
	var area = Area2D.new()
	area.name = "OrbCollision"
	area.collision_layer = 0  # Don't collide with anything
	area.collision_mask = 1 << 1  # Detect layer 2 (enemies)

	# Create circular collision shape
	var collision_shape = CollisionShape2D.new()
	var circle_shape = CircleShape2D.new()
	circle_shape.radius = orb_size / 2
	collision_shape.shape = circle_shape
	area.add_child(collision_shape)

	# Connect collision signals
	area.body_entered.connect(_on_orb_hit_enemy)
	area.area_entered.connect(_on_orb_hit_enemy)

	return area

func start_orb_rotation():
	"""Start the orb rotation effect"""
	print("⚪ Starting Orb Rotation at position: %s" % global_position)

	# Create activation effect
	create_activation_effect()

	# Start rotation process
	set_process(true)

	# Set duration timer
	await get_tree().create_timer(duration).timeout
	cleanup_orbs()

func _process(delta):
	"""Update orb positions each frame"""
	if orbs.size() == 0:
		return

	# Update rotation angle
	rotation_angle += rotation_speed * delta
	if rotation_angle >= 360.0:
		rotation_angle -= 360.0

	# Update each orb position
	for i in range(orbs.size()):
		if not is_instance_valid(orbs[i]):
			continue

		var orb = orbs[i]
		var angle_offset = (360.0 / orb_count) * i
		var current_angle = deg_to_rad(rotation_angle + angle_offset)
		var new_position = Vector2(cos(current_angle) * orbit_radius, sin(current_angle) * orbit_radius)
		orb.position = new_position

func _on_orb_hit_enemy(body: Node):
	"""Handle orb collision with enemy"""
	if not body or not is_instance_valid(body):
		return

	if not body.is_in_group("enemies"):
		return

	# Check if we already hit this enemy recently (prevent spam)
	var hit_key = "%s_%s" % [body.get_instance_id(), Time.get_ticks_msec()]
	if body.has_meta("last_orb_hit"):
		var last_hit = body.get_meta("last_orb_hit")
		if Time.get_ticks_msec() - last_hit < 200:  # 200ms cooldown per enemy
			return

	body.set_meta("last_orb_hit", Time.get_ticks_msec())

	print("⚪ Orb hit enemy: %s" % body.name)

	# Apply damage
	if body.has_method("take_damage_from_source"):
		body.take_damage_from_source(damage, bottle_id)
		print("⚪ Dealt %.0f damage to %s" % [damage, body.name])

	# Apply cold effect if enabled
	if apply_cold and Effects and Effects.cold:
		var cold_params = {
			"duration": 3.0,
			"tick_interval": 0.0,
			"tick_damage": 0.0,
			"max_stacks": 6,
			"stack_value": 1.0,
			"slow_per_stack": 0.15,
			"freeze_threshold": 6,
			"cold_color": Color(0.7, 0.9, 1.0, 0.8)
		}

		Effects.cold.apply_from_talent(body, null, cold_stacks, cold_params)
		print("⚪ Applied %d cold stacks to %s" % [cold_stacks, body.name])

	# Apply knockback if enabled
	if knockback_enabled:
		apply_knockback_to_enemy(body)

	# Create hit effect
	create_orb_hit_effect(body.global_position)

func apply_knockback_to_enemy(enemy: Node):
	"""Apply knockback force to the enemy"""
	if not enemy.has_method("apply_knockback") and not "velocity" in enemy and not "move_speed" in enemy:
		return

	# Calculate knockback direction (away from orb hit point)
	var knockback_direction = (enemy.global_position - global_position).normalized()

	if enemy.has_method("apply_knockback"):
		enemy.apply_knockback(knockback_direction * knockback_force)
		print("⚪ Applied knockback to %s" % enemy.name)
	elif "velocity" in enemy:
		enemy.velocity += knockback_direction * knockback_force
	elif "position" in enemy:
		# Simple position-based knockback
		var knockback_tween = create_tween()
		var current_pos = enemy.global_position
		var target_pos = current_pos + knockback_direction * (knockback_force / 2)
		knockback_tween.tween_property(enemy, "global_position", target_pos, 0.2)

func create_orb_hit_effect(position: Vector2):
	"""Create hit effect when orb strikes enemy"""
	var hit_particles = CPUParticles2D.new()
	add_child(hit_particles)
	hit_particles.global_position = position

	# Configure hit particles
	hit_particles.emitting = true
	hit_particles.amount = 8
	hit_particles.lifetime = 0.4
	hit_particles.one_shot = true
	hit_particles.explosiveness = 1.0

	# Burst pattern
	hit_particles.spread = 360.0
	hit_particles.initial_velocity_min = 20.0
	hit_particles.initial_velocity_max = 40.0
	hit_particles.gravity = Vector2.ZERO
	hit_particles.linear_accel_min = -30.0
	hit_particles.linear_accel_max = -50.0
	hit_particles.scale_amount_min = 0.2
	hit_particles.scale_amount_max = 0.5
	hit_particles.color = Color(0.8, 0.95, 1.0, 1.0)

	# Clean up hit effect
	await get_tree().create_timer(0.6).timeout
	if is_instance_valid(hit_particles):
		hit_particles.queue_free()

func create_activation_effect():
	"""Create activation effect when orbs first appear"""
	var flash_container = Node2D.new()
	flash_container.name = "ActivationFlash"
	add_child(flash_container)

	# Create expanding circle flash
	var flash_circle = Line2D.new()
	flash_circle.width = 3.0
	flash_circle.default_color = Color(0.7, 0.9, 1.0, 0.8)
	flash_circle.antialiased = true

	# Generate circle points
	var points = PackedVector2Array()
	var segments = 24
	var flash_radius = 20.0

	for i in range(segments + 1):
		var angle = i * (PI * 2) / segments
		var point = Vector2(cos(angle) * flash_radius, sin(angle) * flash_radius)
		points.append(point)

	flash_circle.points = points
	flash_container.add_child(flash_circle)

	# Animate the flash
	var flash_tween = create_tween()
	flash_tween.set_ease(Tween.EASE_OUT)
	flash_tween.parallel().tween_property(flash_container, "scale", Vector2(3.0, 3.0), 0.5)
	flash_tween.parallel().tween_property(flash_container, "modulate:a", 0.0, 0.5)
	flash_tween.tween_callback(flash_container.queue_free)

func cleanup_orbs():
	"""Clean up the orb rotation effect"""
	print("⚪ Orb Rotation cleanup")
	set_process(false)

	# Fade out effect
	var fade_tween = create_tween()
	fade_tween.tween_property(self, "modulate:a", 0.0, 0.5)
	fade_tween.tween_callback(queue_free)
