# Effects/FrostNova/frost_nova.gd
extends Node2D

# Frost Nova properties
var damage: float = 40.0
var radius: float = 80.0
var duration: float = 1.5
var cold_stacks: int = 1
var bottle_id: String = ""

# Visual components
var ring_particles: CPUParticles2D
var burst_particles: CPUParticles2D
var expanding_ring: Node2D

func _ready():
	print("❄️ Frost Nova scene ready, waiting for initialization...")

func initialize(nova_damage: float, nova_radius: float, apply_cold_stacks: int, source_bottle_id: String):
	"""Initialize and start the frost nova effect"""
	damage = nova_damage
	radius = nova_radius
	cold_stacks = apply_cold_stacks
	bottle_id = source_bottle_id

	print("❄️ Initializing Frost Nova - damage: %.0f, radius: %.0f, stacks: %d" % [damage, radius, cold_stacks])

	# Create all visual effects
	create_expanding_ring()
	create_particle_effects()

	# Start the frost nova sequence
	start_frost_nova()

func create_expanding_ring():
	"""Create the expanding circular ring indicator"""
	expanding_ring = Node2D.new()
	expanding_ring.name = "ExpandingRing"
	add_child(expanding_ring)

	# Create multiple Line2D circles for a ring effect
	for i in range(3):
		var circle = Line2D.new()
		circle.width = 1.5
		circle.default_color = Color(0.4, 0.7, 1.0, 0.4 - i * 0.1)
		circle.antialiased = true

		# Generate circle points
		var points = PackedVector2Array()
		var segments = 32
		var circle_radius = 6.0 + i * 1.5

		for j in range(segments + 1):
			var angle = j * (PI * 2) / segments
			var point = Vector2(cos(angle) * circle_radius, sin(angle) * circle_radius)
			points.append(point)

		circle.points = points
		expanding_ring.add_child(circle)

	print("✅ Created expanding ring with %d circles" % expanding_ring.get_child_count())

func create_particle_effects():
	"""Create the particle effects for the frost nova"""
	# Create ring particles
	ring_particles = CPUParticles2D.new()
	ring_particles.name = "RingParticles"
	add_child(ring_particles)

	# Configure ring particles
	ring_particles.emitting = false
	ring_particles.amount = 30
	ring_particles.lifetime = 1.2
	ring_particles.one_shot = true
	ring_particles.explosiveness = 0.9

	# Ring expansion pattern
	ring_particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	ring_particles.emission_sphere_radius = 8.0
	ring_particles.spread = 360.0
	ring_particles.initial_velocity_min = radius * 0.6
	ring_particles.initial_velocity_max = radius * 0.8
	ring_particles.gravity = Vector2.ZERO
	ring_particles.linear_accel_min = -40.0
	ring_particles.linear_accel_max = -60.0

	# Appearance
	ring_particles.scale_amount_min = 0.5
	ring_particles.scale_amount_max = 0.8
	ring_particles.color = Color(0.6, 0.85, 1.0, 0.9)

	# Create center burst particles
	burst_particles = CPUParticles2D.new()
	burst_particles.name = "BurstParticles"
	add_child(burst_particles)

	# Configure burst particles
	burst_particles.emitting = false
	burst_particles.amount = 12
	burst_particles.lifetime = 0.8
	burst_particles.one_shot = true
	burst_particles.explosiveness = 1.0

	# Upward burst pattern
	burst_particles.spread = 45.0
	burst_particles.direction = Vector2.UP
	burst_particles.initial_velocity_min = 40.0
	burst_particles.initial_velocity_max = 70.0
	burst_particles.gravity = Vector2(0, 50)
	burst_particles.scale_amount_min = 0.3
	burst_particles.scale_amount_max = 0.6
	burst_particles.color = Color(0.7, 0.9, 1.0, 1.0)

	print("✅ Created particle effects: ring and burst")

func start_frost_nova():
	"""Start the frost nova effect sequence"""
	print("❄️ Starting Frost Nova at position: %s" % global_position)

	# Create initial flash
	create_activation_flash()

	# Start ring expansion animation
	if expanding_ring:
		var tween = create_tween()
		tween.set_ease(Tween.EASE_OUT)
		tween.set_trans(Tween.TRANS_CUBIC)
		tween.parallel().tween_property(expanding_ring, "scale", Vector2(radius / 8.0, radius / 8.0), duration)
		tween.parallel().tween_property(expanding_ring, "modulate:a", 0.0, duration * 0.8)

	# Start particle effects with timing
	start_particles()

	# Apply damage and effects
	apply_frost_nova_effects()

	# Clean up after duration
	cleanup_after_duration()

func create_activation_flash():
	"""Create circular activation flash"""
	var flash_container = Node2D.new()
	flash_container.name = "ActivationFlash"
	add_child(flash_container)

	# Create a simple circular flash using Line2D
	var flash_circle = Line2D.new()
	flash_circle.width = 2.0
	flash_circle.default_color = Color(0.8, 0.95, 1.0, 0.7)
	flash_circle.antialiased = true

	# Generate circle points
	var points = PackedVector2Array()
	var segments = 16
	var flash_radius = 8.0

	for i in range(segments + 1):
		var angle = i * (PI * 2) / segments
		var point = Vector2(cos(angle) * flash_radius, sin(angle) * flash_radius)
		points.append(point)

	flash_circle.points = points
	flash_container.add_child(flash_circle)

	# Animate the flash
	var flash_tween = create_tween()
	flash_tween.set_ease(Tween.EASE_OUT)
	flash_tween.parallel().tween_property(flash_container, "scale", Vector2(2.0, 2.0), 0.3)
	flash_tween.parallel().tween_property(flash_container, "modulate:a", 0.0, 0.3)
	flash_tween.tween_callback(flash_container.queue_free)

func start_particles():
	"""Start the particle effects with proper timing"""
	# Start ring particles first
	await get_tree().create_timer(0.1).timeout
	if ring_particles:
		ring_particles.emitting = true
		print("✅ Ring particles started")

	# Start burst particles slightly after
	await get_tree().create_timer(0.05).timeout
	if burst_particles:
		burst_particles.emitting = true
		print("✅ Burst particles started")

func apply_frost_nova_effects():
	"""Apply damage and cold effects to enemies"""
	# Wait for the right moment (when expansion is visible)
	await get_tree().create_timer(0.4).timeout

	var affected_enemies = find_enemies_in_radius()
	print("❄️ Frost Nova affecting %d enemies" % affected_enemies.size())

	# Create screen shake
	create_screen_shake()

	for enemy in affected_enemies:
		if not is_instance_valid(enemy):
			continue

		# Apply damage
		if enemy.has_method("take_damage_from_source"):
			enemy.take_damage_from_source(damage, bottle_id)
			print("❄️ Dealt %.0f damage to %s" % [damage, enemy.name])

		# Apply cold effect using proper Effects system
		if Effects and Effects.cold:
			var cold_params = {
				"duration": 5.0,
				"tick_interval": 0.0,
				"tick_damage": 0.0,
				"max_stacks": 6,
				"stack_value": 1.0,
				"slow_per_stack": 0.15,
				"freeze_threshold": 6,
				"cold_color": Color(0.7, 0.9, 1.0, 0.8)
			}

			Effects.cold.apply_from_talent(enemy, null, cold_stacks, cold_params)
			print("❄️ Applied %d cold stacks to %s" % [cold_stacks, enemy.name])

		# Create hit effect
		create_enemy_hit_effect(enemy.global_position)

func find_enemies_in_radius() -> Array:
	"""Find all enemies within the frost nova radius"""
	var enemies_in_range = []

	# Use physics query first (for collision layer 2)
	var space_state = get_world_2d().direct_space_state
	var circle_query = PhysicsShapeQueryParameters2D.new()
	var circle_shape = CircleShape2D.new()
	circle_shape.radius = radius
	circle_query.shape = circle_shape
	circle_query.transform = Transform2D(0, global_position)
	circle_query.collision_mask = 1 << 1  # Layer 2
	circle_query.collide_with_areas = true
	circle_query.collide_with_bodies = true

	var intersections = space_state.intersect_shape(circle_query)
	print("🔍 Physics found %d potential targets" % intersections.size())

	for intersection in intersections:
		var collider = intersection.collider
		if is_instance_valid(collider) and collider.is_in_group("enemies"):
			enemies_in_range.append(collider)

	# Fallback: manual distance check
	if enemies_in_range.size() == 0:
		var all_enemies = get_tree().get_nodes_in_group("enemies")
		for enemy in all_enemies:
			if is_instance_valid(enemy):
				var distance = global_position.distance_to(enemy.global_position)
				if distance <= radius:
					enemies_in_range.append(enemy)

	return enemies_in_range

func create_enemy_hit_effect(position: Vector2):
	"""Create small hit effect at enemy position"""
	var hit_particles = CPUParticles2D.new()
	add_child(hit_particles)
	hit_particles.global_position = position

	# Configure hit particles
	hit_particles.emitting = true
	hit_particles.amount = 6
	hit_particles.lifetime = 0.6
	hit_particles.one_shot = true
	hit_particles.explosiveness = 1.0

	# Small upward burst
	hit_particles.spread = 120.0
	hit_particles.direction = Vector2.UP
	hit_particles.initial_velocity_min = 20.0
	hit_particles.initial_velocity_max = 40.0
	hit_particles.gravity = Vector2(0, 30)
	hit_particles.scale_amount_min = 0.2
	hit_particles.scale_amount_max = 0.4
	hit_particles.color = Color(0.9, 0.95, 1.0, 1.0)

	# Clean up after effect
	await get_tree().create_timer(0.8).timeout
	if is_instance_valid(hit_particles):
		hit_particles.queue_free()

func create_screen_shake():
	"""Create subtle screen shake effect"""
	var camera = get_viewport().get_camera_2d()
	if not camera:
		return

	var original_offset = camera.offset
	var shake_tween = create_tween()

	# Small shake sequence
	shake_tween.tween_property(camera, "offset", original_offset + Vector2(2, 1), 0.05)
	shake_tween.tween_property(camera, "offset", original_offset + Vector2(-1, -2), 0.05)
	shake_tween.tween_property(camera, "offset", original_offset + Vector2(1, 1), 0.05)
	shake_tween.tween_property(camera, "offset", original_offset, 0.1)

func cleanup_after_duration():
	"""Clean up the frost nova after its duration"""
	await get_tree().create_timer(duration + 0.5).timeout
	print("❄️ Frost Nova cleanup")
	queue_free()

func create_activation_effect():
	"""Create activation effect for testing"""
	create_activation_flash()
