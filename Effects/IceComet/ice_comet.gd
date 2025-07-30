# Effects/IceComet/ice_comet.gd
class_name IceComet
extends Area2D

var damage: float
var target_position: Vector2
var velocity: Vector2
var impact_radius: float
var source_bottle_id: String
var source_bottle: ImprovedBaseSauceBottle  # Reference to the bottle that created this comet

# Visual components (created programmatically)
var comet_sprite: Sprite2D
var comet_trail: CPUParticles2D
var collision_shape: CollisionShape2D

# Movement properties
var gravity_strength: float = 200.0  # Reduced gravity
var initial_speed: float = 150.0     # Slower speed
var spin_speed: float = 90.0         # Slower spin

func _init():
	# Create components immediately
	_create_components()

func _create_components():
	"""Create all child components programmatically"""
	# Create collision shape
	collision_shape = CollisionShape2D.new()
	add_child(collision_shape)

	# Create comet sprite
	comet_sprite = Sprite2D.new()
	add_child(comet_sprite)

	# Create particle trail
	comet_trail = CPUParticles2D.new()
	add_child(comet_trail)

func _ready():
	# Set up collision detection
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)

func setup_ice_comet(start_pos: Vector2, target_pos: Vector2, comet_damage: float, radius: float, bottle_id: String, bottle: ImprovedBaseSauceBottle = null):
	"""Initialize ice comet with specified parameters"""
	global_position = start_pos
	target_position = target_pos
	damage = comet_damage
	impact_radius = radius
	source_bottle_id = bottle_id
	source_bottle = bottle  # Store bottle reference for frozen comets talent

	# Calculate proper trajectory to hit the target
	var distance_to_target = start_pos.distance_to(target_pos)
	var time_to_target = distance_to_target / initial_speed

	# Calculate velocity needed to reach target considering gravity
	var horizontal_velocity = (target_pos - start_pos) / time_to_target

	# Adjust for gravity - we need upward velocity to counteract gravity over time
	var gravity_compensation = gravity_strength * time_to_target * 0.5
	horizontal_velocity.y -= gravity_compensation

	velocity = horizontal_velocity

	# Set up visual components
	_setup_visuals()

func _setup_visuals():
	"""Set up comet sprite and trail effects"""

	# Create comet sprite
	if comet_sprite:
		if not comet_sprite.texture:
			comet_sprite.texture = _create_comet_texture()
		comet_sprite.scale = Vector2(2.0, 2.0)  # Much bigger for testing
		comet_sprite.modulate = Color(1.0, 1.0, 1.0, 1.0)  # Fully opaque white
		comet_sprite.z_index = 100  # Make sure it's on top

	# Set up particle trail
	if comet_trail:
		comet_trail.texture = _create_trail_particle_texture()
		comet_trail.emitting = true
		comet_trail.amount = 30
		comet_trail.lifetime = 1.0
		comet_trail.direction = -velocity.normalized()  # Trail behind movement
		comet_trail.spread = 20.0
		comet_trail.initial_velocity_min = 50.0
		comet_trail.initial_velocity_max = 100.0
		comet_trail.scale_amount_min = 0.3
		comet_trail.scale_amount_max = 0.7
		comet_trail.color = Color(0.7, 0.85, 1.0, 0.6)  # Light blue trail

	# Set up collision
	if collision_shape:
		var circle_shape = CircleShape2D.new()
		circle_shape.radius = 8.0  # Small collision for the comet itself
		collision_shape.shape = circle_shape

func _create_comet_texture() -> ImageTexture:
	"""Create a glowing ice comet texture"""
	var size = 24
	var image = Image.create(size, size, false, Image.FORMAT_RGBA8)
	var center = Vector2(size/2, size/2)
	var max_radius = size / 2.0

	for x in range(size):
		for y in range(size):
			var pos = Vector2(x, y)
			var distance = center.distance_to(pos)

			if distance <= max_radius:
				var normalized_dist = distance / max_radius

				# Create glowing ice ball effect
				var alpha = 1.0 - normalized_dist

				# Bright center
				if normalized_dist < 0.3:
					alpha = 1.0
				# Glowing edge
				elif normalized_dist < 0.7:
					alpha = 0.8 - (normalized_dist - 0.3) * 2.0
				# Soft outer glow
				else:
					alpha = 0.3 - (normalized_dist - 0.7) * 1.0

				alpha = max(0, alpha)

				# Icy blue-white color
				image.set_pixel(x, y, Color(0.9, 0.95, 1.0, alpha))

	var texture = ImageTexture.new()
	texture.set_image(image)
	return texture

func _create_trail_particle_texture() -> ImageTexture:
	"""Create small ice particle texture for the trail"""
	var size = 6
	var image = Image.create(size, size, false, Image.FORMAT_RGBA8)
	var center = Vector2(size/2, size/2)

	for x in range(size):
		for y in range(size):
			var pos = Vector2(x, y)
			var distance = center.distance_to(pos)

			if distance <= 2.5:
				var alpha = 1.0 - (distance / 2.5)
				image.set_pixel(x, y, Color(1.0, 1.0, 1.0, alpha))

	var texture = ImageTexture.new()
	texture.set_image(image)
	return texture

func _process(delta: float):
	# Apply gravity to velocity
	velocity.y += gravity_strength * delta

	# Move the comet
	global_position += velocity * delta

	# Rotate the comet sprite for visual effect
	if comet_sprite:
		comet_sprite.rotation_degrees += spin_speed * delta

	# Update trail direction
	if comet_trail:
		comet_trail.direction = -velocity.normalized()

	# Check if we're close to target position (impact detection)
	var distance_to_target = global_position.distance_to(target_position)
	if distance_to_target < 50.0:  # Hit if within 50 pixels of target
		_impact_ground()
		return

	# Check if we've gone too far or hit the ground (safety bounds)
	if global_position.y > target_position.y + 200 or global_position.distance_to(target_position) > 1000:
		_impact_ground()

func _on_body_entered(body: Node2D):
	"""Handle collision with enemies or environment"""
	if body.is_in_group("enemies"):
		_impact_enemy(body)
	else:
		_impact_ground()

func _on_area_entered(area: Area2D):
	"""Handle collision with area-based enemies"""
	if area.is_in_group("enemies"):
		_impact_enemy(area)

func _impact_enemy(enemy: Node2D):
	"""Handle direct hit on an enemy"""
	# Deal direct damage
	if enemy.has_method("take_damage_from_source"):
		enemy.take_damage_from_source(damage, source_bottle_id)

	# Check for frozen comets talent and apply cold
	_check_and_apply_cold(enemy)

	# Create impact explosion
	_create_impact_explosion()

func _impact_ground():
	"""Handle impact with ground or timeout"""
	# Create impact explosion
	_create_impact_explosion()

func _create_impact_explosion():
	"""Create ice explosion effect and area damage"""

	# Deal area damage to nearby enemies
	_deal_area_damage()

	# Create visual explosion effect
	_create_explosion_visual()

	# Create ice shards flying out
	_create_ice_shards()

	# Remove the comet
	queue_free()

func _deal_area_damage():
	"""Deal damage to all enemies in impact radius"""
	var enemies_in_area = []
	var all_enemies = get_tree().get_nodes_in_group("enemies")
	for enemy in all_enemies:
		if is_instance_valid(enemy) and global_position.distance_to(enemy.global_position) <= impact_radius:
			enemies_in_area.append(enemy)

			# Deal area damage
			if enemy.has_method("take_damage_from_source"):
				enemy.take_damage_from_source(damage * 0.7, source_bottle_id)  # 70% damage for area effect

			# Check for frozen comets talent and apply cold
			_check_and_apply_cold(enemy)

func _check_and_apply_cold(enemy: Node2D):
	"""Check if bottle has frozen comets talent and apply cold stacks"""
	if not source_bottle or not enemy or not is_instance_valid(enemy):
		return

	# Check if the bottle has the frozen comets trigger effect
	var has_frozen_comets = false
	for trigger_effect in source_bottle.trigger_effects:
		if trigger_effect.trigger_name == "frozen_comets":
			has_frozen_comets = true

			# Get cold parameters from talent
			var cold_stacks = trigger_effect.effect_parameters.get("cold_stacks", 2)
			var cold_duration = trigger_effect.effect_parameters.get("cold_duration", 4.0)

			# Apply cold using the Effects system
			if Effects and Effects.cold:
				var cold_params = {
					"duration": cold_duration,
					"tick_interval": 0.0,
					"tick_damage": 0.0,
					"max_stacks": 6,
					"stack_value": 1.0,
					"slow_per_stack": 0.15,
					"freeze_threshold": 6,
					"cold_color": Color(0.7, 0.9, 1.0, 0.8)
				}

				Effects.cold.apply_from_talent(enemy, source_bottle, cold_stacks, cold_params)
				DebugControl.debug_status("❄️ Frozen Comet applied %d cold stacks to enemy" % cold_stacks)
			break

func _create_explosion_visual():
	"""Create visual explosion effect at impact point"""
	# Create explosion sprite
	var explosion = Sprite2D.new()
	explosion.texture = _create_explosion_texture()
	explosion.global_position = global_position
	explosion.modulate = Color(0.8, 0.9, 1.0, 0.3)  # Much more transparent
	explosion.z_index = 50

	# Add to scene
	get_parent().add_child(explosion)

	# Animate explosion with fade out and removal
	var tween = create_tween()
	tween.parallel().tween_property(explosion, "scale", Vector2(1.5, 1.5), 0.5)
	tween.parallel().tween_property(explosion, "modulate:a", 0.0, 2.0)  # Fade out over 2 seconds
	tween.tween_callback(explosion.queue_free)

func _create_explosion_texture() -> ImageTexture:
	"""Create explosion texture"""
	var size = 64
	var image = Image.create(size, size, false, Image.FORMAT_RGBA8)
	var center = Vector2(size/2, size/2)
	var max_radius = size / 2.0

	for x in range(size):
		for y in range(size):
			var pos = Vector2(x, y)
			var distance = center.distance_to(pos)

			if distance <= max_radius:
				var normalized_dist = distance / max_radius

				# Much more transparent like frost zones
				var alpha = (1.0 - normalized_dist) * 0.15  # Very transparent

				# Inner core (barely visible)
				if normalized_dist < 0.7:
					alpha = (1.0 - normalized_dist * 0.7) * 0.2

				# Center highlight (subtle)
				if normalized_dist < 0.3:
					alpha = (1.0 - normalized_dist) * 0.25

				# Add some noise for explosion texture
				var noise = sin(x * 0.8) * cos(y * 0.8) * 0.05
				alpha = max(0, alpha + noise)

				image.set_pixel(x, y, Color(0.7, 0.9, 1.0, alpha))

	var texture = ImageTexture.new()
	texture.set_image(image)
	return texture

func _create_ice_shards():
	"""Create flying ice shards from impact point"""
	var shard_count = 8

	for i in range(shard_count):
		var angle = (i * 360.0 / shard_count) + randf_range(-20, 20)  # Random spread
		var shard_direction = Vector2.from_angle(deg_to_rad(angle))

		# Create simple ice shard particle
		var shard = CPUParticles2D.new()
		shard.global_position = global_position
		shard.emitting = true
		shard.amount = 3
		shard.lifetime = 0.8
		shard.one_shot = true
		shard.direction = shard_direction
		shard.spread = 15.0
		shard.initial_velocity_min = 100.0
		shard.initial_velocity_max = 200.0
		shard.gravity = Vector2(0, 200)
		shard.scale_amount_min = 0.5
		shard.scale_amount_max = 1.0
		shard.color = Color(0.9, 0.95, 1.0, 0.8)

		# Add to scene
		get_parent().add_child(shard)

		# Remove after animation
		get_tree().create_timer(1.0).timeout.connect(shard.queue_free)
