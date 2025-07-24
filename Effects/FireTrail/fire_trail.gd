# Effects/FireTrail/fire_trail.gd
extends Area2D

# Trail properties
var source_bottle: Node
var trail_width: float = 60.0
var trail_duration: float = 5.0
var tick_damage: float = 8.0
var tick_interval: float = 0.3
var trail_color: Color = Color(1.0, 0.3, 0.0, 0.6)

# Internal state
var lifetime_timer: float = 0.0
var tick_timer: float = 0.0
var enemies_in_trail: Array[Node2D] = []

# Components
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var visual_effect: Node2D = $VisualEffect

func _ready():
	print("🔥 Fire Trail segment _ready() called")

	# Setup collision detection for enemies
	collision_layer = 0  # Don't collide with anything
	collision_mask = 0   # We'll detect enemies manually

	# Connect area signals for optimization (optional)
	body_entered.connect(_on_enemy_entered)
	body_exited.connect(_on_enemy_exited)
	area_entered.connect(_on_area_entered)
	area_exited.connect(_on_area_exited)

func setup_trail(bottle: Node, width: float, duration: float, damage: float, interval: float, color: Color):
	"""Initialize the fire trail segment with its properties"""
	print("🔥 Fire Trail setup_trail() called")
	print("  Width: %.0f, Duration: %.1fs, Damage: %.1f" % [width, duration, damage])

	source_bottle = bottle
	trail_width = width
	trail_duration = duration
	tick_damage = damage
	tick_interval = interval
	trail_color = color

	# Setup collision shape to match width
	if collision_shape:
		var circle_shape = CircleShape2D.new()
		circle_shape.radius = trail_width / 2.0
		collision_shape.shape = circle_shape
		print("🔥 Fire Trail collision radius set to %.0f" % (trail_width / 2.0))

	# Create visual effects
	_create_visual_effects()

func _create_visual_effects():
	"""Create the burning trail visual effect"""
	print("🔥 Creating fire trail visual effects")

	# Create flame particles along the trail width
	var particle_count = int(trail_width / 10)  # One particle per 10 pixels
	particle_count = max(4, min(particle_count, 12))  # Between 4-12 particles

	for i in range(particle_count):
		var particle = ColorRect.new()
		particle.size = Vector2(8, 8)
		particle.color = trail_color

		# Random position within the trail width
		var angle = randf() * 2 * PI
		var distance = randf() * (trail_width / 2.0) * 0.9  # Keep within 90% of radius
		var offset = Vector2(cos(angle), sin(angle)) * distance

		particle.position = offset - particle.size / 2  # Center the particle
		add_child(particle)

		# Animate the particle (flickering fire effect)
		var tween = create_tween()
		tween.set_loops()
		tween.tween_property(particle, "modulate:a", 0.2, randf_range(0.4, 0.8))
		tween.tween_property(particle, "modulate:a", 0.8, randf_range(0.4, 0.8))

	print("🔥 Created %d fire trail particles" % particle_count)

func _process(delta):
	# Update timers
	lifetime_timer += delta
	tick_timer += delta

	# Check if trail should expire
	if lifetime_timer >= trail_duration:
		_destroy_trail()
		return

	# Damage enemies in trail
	if tick_timer >= tick_interval:
		tick_timer = 0.0
		_damage_enemies_in_trail()

func _damage_enemies_in_trail():
	"""Damage all enemies currently in the fire trail"""
	# Find enemies in the trail area
	var current_enemies = _get_enemies_in_area()

	if current_enemies.size() == 0:
		return

	var bottle_id = source_bottle.bottle_id if source_bottle and source_bottle.has_method("bottle_id") else "fire_trail"

	for enemy in current_enemies:
		if is_instance_valid(enemy):
			if enemy.has_method("take_damage_from_source"):
				enemy.take_damage_from_source(tick_damage, bottle_id)
			elif enemy.has_method("take_damage"):
				enemy.take_damage(tick_damage)

			# Create damage visual
			_create_damage_visual(enemy.global_position)

	print("🔥 Fire Trail damaged %d enemies for %.1f damage each" % [current_enemies.size(), tick_damage])

func _get_enemies_in_area() -> Array[Node2D]:
	"""Get all enemies currently in the fire trail area"""
	var enemies: Array[Node2D] = []

	# Get all enemy nodes
	var all_nodes = Engine.get_main_loop().current_scene.get_children()
	var all_enemies = []
	_find_enemies_recursive(all_nodes, all_enemies)

	# Check which ones are in range
	for enemy in all_enemies:
		if is_instance_valid(enemy):
			var distance = global_position.distance_to(enemy.global_position)
			if distance <= trail_width / 2.0:
				enemies.append(enemy)

	return enemies

func _find_enemies_recursive(nodes: Array, enemies: Array):
	"""Recursively find all enemy nodes"""
	for node in nodes:
		if node.is_in_group("enemies"):
			enemies.append(node)
		if node.get_child_count() > 0:
			_find_enemies_recursive(node.get_children(), enemies)

func _create_damage_visual(position: Vector2):
	"""Create a small visual effect when damaging enemies"""
	var damage_particle = ColorRect.new()
	damage_particle.size = Vector2(6, 6)
	damage_particle.color = Color.YELLOW
	damage_particle.global_position = position + Vector2(randf_range(-8, 8), randf_range(-8, 8))

	# Add to scene
	var scene = Engine.get_main_loop().current_scene
	scene.add_child(damage_particle)

	# Animate and remove
	var tween = damage_particle.create_tween()
	tween.parallel().tween_property(damage_particle, "position", damage_particle.position + Vector2(0, -15), 0.4)
	tween.parallel().tween_property(damage_particle, "modulate:a", 0.0, 0.4)
	tween.tween_callback(damage_particle.queue_free)

func _destroy_trail():
	"""Remove the fire trail and clean up"""
	print("🔥 Fire Trail expired after %.1fs" % lifetime_timer)

	# Create destruction visual effect
	for i in range(8):
		var spark = ColorRect.new()
		spark.size = Vector2(4, 4)
		spark.color = Color.ORANGE
		spark.position = Vector2(randf_range(-trail_width/2, trail_width/2), randf_range(-trail_width/2, trail_width/2))
		add_child(spark)

		var tween = spark.create_tween()
		var direction = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()
		tween.parallel().tween_property(spark, "position", spark.position + direction * 30, 0.6)
		tween.parallel().tween_property(spark, "modulate:a", 0.0, 0.6)

	# Remove after visual effect
	var cleanup_timer = Timer.new()
	cleanup_timer.wait_time = 0.8
	cleanup_timer.one_shot = true
	cleanup_timer.timeout.connect(queue_free)
	add_child(cleanup_timer)
	cleanup_timer.start()

# Signal handlers for optimization (if we want to use collision detection later)
func _on_enemy_entered(body):
	if body.is_in_group("enemies") and body not in enemies_in_trail:
		enemies_in_trail.append(body)

func _on_enemy_exited(body):
	if body in enemies_in_trail:
		enemies_in_trail.erase(body)

func _on_area_entered(area):
	if area.is_in_group("enemies") and area not in enemies_in_trail:
		enemies_in_trail.append(area)

func _on_area_exited(area):
	if area in enemies_in_trail:
		enemies_in_trail.erase(area)
