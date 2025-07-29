# Effects/FrostZone/frost_zone.gd
class_name FrostZone
extends Area2D

var tick_damage: float
var zone_radius: float
var zone_duration: float
var tick_interval: float
var source_bottle_id: String

var tick_timer: float = 0.0
var zone_timer: float = 0.0
var enemies_in_zone: Array[Node2D] = []

# Components (will be found from scene)
@onready var frost_sprite: Sprite2D = $FrostSprite
@onready var frost_particles: CPUParticles2D = $FrostParticles
@onready var collision_shape: CollisionShape2D = $CollisionShape

func _ready():

	# Set up collision detection
	body_entered.connect(_on_enemy_entered)
	body_exited.connect(_on_enemy_exited)
	area_entered.connect(_on_area_entered)
	area_exited.connect(_on_area_exited)


func setup_frost_zone(position: Vector2, damage: float, radius: float, duration: float, interval: float, bottle_id: String):
	"""Initialize frost zone with specified parameters"""
	global_position = position
	tick_damage = damage
	zone_radius = radius
	zone_duration = duration
	tick_interval = interval
	source_bottle_id = bottle_id

	# Make sure it appears above everything else
	z_index = 100
	z_as_relative = false

	# Set up collision shape
	if collision_shape and collision_shape.shape is CircleShape2D:
		var circle_shape = collision_shape.shape as CircleShape2D
		circle_shape.radius = radius

	# Set up frost sprite
	if frost_sprite:
		# Create a nice ice circle texture if none exists
		if not frost_sprite.texture:
			frost_sprite.texture = _create_ice_circle_texture(int(radius * 2.5))

		# Scale sprite to match radius - balanced scaling
		var scale_factor = radius / 30.0  # Middle ground between 20 and 40
		frost_sprite.scale = Vector2(scale_factor, scale_factor)

		# Make sure sprite is visible
		frost_sprite.z_index = 50

	# Set up particles to match radius (don't set emission_rate_hz - that's set in scene)
	if frost_particles:
		# Adjust particle count based on radius
		var particle_count = int(radius / 2)  # More particles for bigger zones
		frost_particles.amount = max(20, min(100, particle_count))

		# Make particles look like snow programmatically
		frost_particles.texture = _create_snowflake_texture()
		frost_particles.scale_amount_min = 0.1
		frost_particles.scale_amount_max = 0.4
		frost_particles.color = Color(0.9, 0.95, 1.0, 0.8)  # Light blue-white

		# Create swirling blizzard effect
		frost_particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
		frost_particles.emission_sphere_radius = radius * 0.4  # Much smaller - emit from inside
		frost_particles.direction = Vector2(1, 0)  # Start with horizontal direction
		frost_particles.spread = 360.0  # All directions
		frost_particles.initial_velocity_min = 30.0  # Faster initial speed for swirling
		frost_particles.initial_velocity_max = 50.0

		# Try different approach for swirling - use velocity curves if available
		if frost_particles.has_method("set_param"):
			# Use parameter curves for swirling motion
			frost_particles.set_param(CPUParticles2D.PARAM_ANGULAR_VELOCITY, 90.0)
			frost_particles.set_param(CPUParticles2D.PARAM_ORBIT_VELOCITY, 1.0)  # Orbital motion
		else:
			# Fallback to basic properties
			frost_particles.angular_velocity_min = -120.0
			frost_particles.angular_velocity_max = 120.0

		# Reduced gravity for more floating effect
		frost_particles.gravity = Vector2(0, 10)  # Very light gravity

		# Longer lifetime for swirling effect
		frost_particles.lifetime = 3.0

		# Try to add some randomness to make it look more natural
		frost_particles.lifetime_randomness = 0.5

		# Make sure particles are visible
		frost_particles.z_index = 60

	#print("❄️ Frost Zone: Setup complete at %s (z_index: %d)" % [position, z_index])

func _create_ice_circle_texture(size: int) -> ImageTexture:
	"""Create a nice looking ice circle texture"""
	size = max(size, 64)  # Reasonable minimum size
	var image = Image.create(size, size, false, Image.FORMAT_RGBA8)
	var center = Vector2(size/2, size/2)
	var max_radius = size / 2.0

	for x in range(size):
		for y in range(size):
			var pos = Vector2(x, y)
			var distance = center.distance_to(pos)

			if distance <= max_radius:
				# Create ice effect with multiple layers - MUCH more transparent
				var normalized_dist = distance / max_radius

				# Outer glow (very subtle)
				var alpha = (1.0 - normalized_dist) * 0.1  # Was 0.4, now 0.1

				# Inner core (barely visible)
				if normalized_dist < 0.7:
					alpha = (1.0 - normalized_dist * 0.7) * 0.15  # Was 0.7, now 0.15

				# Center highlight (subtle)
				if normalized_dist < 0.3:
					alpha = (1.0 - normalized_dist) * 0.2  # Was 0.9, now 0.2

				# Add some noise for ice texture
				var noise = sin(x * 0.5) * cos(y * 0.5) * 0.05  # Reduced noise
				alpha = max(0, alpha + noise)

				# Nice ice blue color with very low alpha
				image.set_pixel(x, y, Color(0.5, 0.8, 1.0, alpha))  # Much more transparent

	var texture = ImageTexture.new()
	texture.set_image(image)
	return texture

func _create_snowflake_texture() -> ImageTexture:
	"""Create a simple snowflake/dot texture for particles"""
	var size = 8
	var image = Image.create(size, size, false, Image.FORMAT_RGBA8)
	var center = Vector2(size/2, size/2)

	# Create a simple circle/dot
	for x in range(size):
		for y in range(size):
			var pos = Vector2(x, y)
			var distance = center.distance_to(pos)

			if distance <= 3.0:  # Small circle
				var alpha = 1.0 - (distance / 3.0)  # Fade to edges
				image.set_pixel(x, y, Color(1.0, 1.0, 1.0, alpha))

	var texture = ImageTexture.new()
	texture.set_image(image)
	return texture

func _process(delta: float):
	# Update timers
	tick_timer += delta
	zone_timer += delta

	# Check for damage tick
	if tick_timer >= tick_interval:
		_damage_enemies_in_zone()
		tick_timer = 0.0

	# Check for zone expiration
	if zone_timer >= zone_duration:
		_expire_zone()

func _damage_enemies_in_zone():
	"""Deal damage to all enemies currently in the frost zone"""
	var valid_enemies: Array[Node2D] = []

	for enemy in enemies_in_zone:
		if is_instance_valid(enemy):
			# Deal damage
			if enemy.has_method("take_damage_from_source"):
				enemy.take_damage_from_source(tick_damage, source_bottle_id)

			# Apply frost visual effect (optional)
			_apply_frost_effect(enemy)

			valid_enemies.append(enemy)

	# Clean up invalid enemies
	enemies_in_zone = valid_enemies

	if enemies_in_zone.size() > 0:
		#print("❄️ Frost Zone: Damaged %d enemies for %.1f damage" % [enemies_in_zone.size(), tick_damage])
		pass

func _apply_frost_effect(enemy: Node2D):
	"""Apply visual frost effect to enemy (optional)"""
	if enemy.has_node("Sprite2D"):
		var sprite = enemy.get_node("Sprite2D")
		# Briefly tint the enemy blue
		var tween = create_tween()
		tween.tween_property(sprite, "modulate", Color(0.7, 0.8, 1.2), 0.1)
		tween.tween_property(sprite, "modulate", Color.WHITE, 0.3)

func _on_enemy_entered(body: Node2D):
	"""Handle enemy entering frost zone"""
	if body.is_in_group("enemies") and body not in enemies_in_zone:
		enemies_in_zone.append(body)
		#print("❄️ Frost Zone: Enemy entered zone")

func _on_enemy_exited(body: Node2D):
	"""Handle enemy leaving frost zone"""
	if body in enemies_in_zone:
		enemies_in_zone.erase(body)
		#print("❄️ Frost Zone: Enemy left zone")

func _on_area_entered(area: Area2D):
	"""Handle area/enemy entering frost zone (for enemies that are Area2D)"""
	if area.is_in_group("enemies") and area not in enemies_in_zone:
		enemies_in_zone.append(area)

func _on_area_exited(area: Area2D):
	"""Handle area/enemy leaving frost zone"""
	if area in enemies_in_zone:
		enemies_in_zone.erase(area)

func _expire_zone():
	"""Clean up and remove the frost zone"""
	#print("❄️ Frost Zone: Expired after %.1f seconds" % zone_duration)

	# Stop particles
	if frost_particles:
		frost_particles.emitting = false

	# Fade out effect
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color.TRANSPARENT, 0.5)
	tween.tween_callback(queue_free)
