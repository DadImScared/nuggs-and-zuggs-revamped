# Effects/IcePrism/ice_prism.gd
extends Node2D

# Ice Prism properties
var beam_damage: float = 15.0
var beam_length: float = 80.0
var rotation_speed: float = 90.0  # degrees per second
var duration: float = 6.0
var beam_width: float = 8.0
var bottle_id: String = ""

# Internal components
var beam_areas: Array[Area2D] = []
var damage_timer: Timer
var duration_timer: Timer
var rotation_tween: Tween
var target_enemy: Node2D = null

# Visual components
var core_visual: ColorRect
var beam_visuals: Array[Node2D] = []

func _ready():
	# Initialize the ice prism effect
	# _create_prism_core()  # Commented out - no core visual
	_create_rotating_beams()
	_setup_timers()
	_start_rotation()

func initialize(enemy: Node2D, damage: float, length: float, rot_speed: float, prism_duration: float, width: float, source_bottle_id: String):
	"""Initialize the ice prism with parameters"""
	target_enemy = enemy
	beam_damage = damage
	beam_length = length
	rotation_speed = rot_speed
	duration = prism_duration
	beam_width = width
	bottle_id = source_bottle_id

	# Position at enemy location
	if target_enemy:
		global_position = target_enemy.global_position

		# Stop the enemy from moving
		if target_enemy.has_method("set_movement_disabled"):
			target_enemy.set_movement_disabled(true)
		elif "move_speed" in target_enemy:
			target_enemy.set_meta("original_move_speed", target_enemy.move_speed)
			target_enemy.move_speed = 0

func _create_prism_core():
	"""Create the central ice crystal visual"""
	core_visual = ColorRect.new()
	core_visual.size = Vector2(16, 16)
	core_visual.position = Vector2(-8, -8)
	core_visual.color = Color(0.8, 0.9, 1.0, 0.9)
	core_visual.rotation = deg_to_rad(45)  # Diamond shape

	add_child(core_visual)

	# Pulsing glow effect
	var pulse_tween = create_tween()
	pulse_tween.set_loops()
	pulse_tween.tween_property(core_visual, "modulate", Color(1.2, 1.2, 1.5, 1.0), 0.5)
	pulse_tween.tween_property(core_visual, "modulate", Color(0.8, 0.9, 1.0, 0.9), 0.5)

func _create_rotating_beams():
	"""Create three rotating damage beams in triangle pattern"""
	var beam_angles = [0, 120, 240]

	for i in range(3):
		# Create damage area
		var beam_area = _create_beam_damage_area(beam_angles[i])
		beam_areas.append(beam_area)
		add_child(beam_area)

		# Create visual beam
		var beam_visual = _create_beam_visual(beam_angles[i])
		beam_visuals.append(beam_visual)
		add_child(beam_visual)

func _create_beam_damage_area(angle_degrees: float) -> Area2D:
	"""Create damage area for a single beam"""
	var beam_area = Area2D.new()
	beam_area.name = "PrismBeam_" + str(angle_degrees)

	# Position and rotate
	beam_area.rotation = deg_to_rad(angle_degrees)

	# Create collision shape (rectangle extending from center)
	var collision_shape = CollisionShape2D.new()
	var rect_shape = RectangleShape2D.new()
	rect_shape.size = Vector2(beam_length, beam_width)
	collision_shape.shape = rect_shape
	collision_shape.position = Vector2(beam_length / 2, 0)  # Offset so beam extends from center

	beam_area.add_child(collision_shape)

	# Set collision layers/masks to detect enemies (layer 2)
	beam_area.collision_layer = 0  # This area doesn't need to be detected
	beam_area.collision_mask = 2   # Detect things on layer 2 (enemies)

	# Make sure area can detect bodies
	beam_area.monitoring = true
	beam_area.monitorable = false

	# Store metadata
	beam_area.set_meta("beam_damage", beam_damage)
	beam_area.set_meta("bottle_id", bottle_id)

	return beam_area

func _create_beam_visual(angle_degrees: float) -> Node2D:
	"""Create visual representation of a beam made of crystal shards"""
	var beam_container = Node2D.new()
	beam_container.rotation = deg_to_rad(angle_degrees)

	# Create crystal shards along the beam length
	var shard_count = 8
	var shard_spacing = beam_length / shard_count

	for i in range(shard_count):
		var shard = _create_crystal_shard()
		shard.position = Vector2(i * shard_spacing + shard_spacing/2, 0)
		beam_container.add_child(shard)

		# Each shard rotates at slightly different speed
		var rotate_tween = create_tween()
		rotate_tween.set_loops()
		var rotation_speed = 2.0 + (i * 0.3)  # Vary speed per shard
		rotate_tween.tween_property(shard, "rotation", PI * 2, rotation_speed)

	return beam_container

func _create_crystal_shard() -> Node2D:
	"""Create a single crystal shard visual"""
	var shard_container = Node2D.new()

	# Create diamond shape using a rotated ColorRect
	var diamond = ColorRect.new()
	diamond.size = Vector2(6, 6)
	diamond.position = Vector2(-3, -3)  # Center it
	diamond.color = Color(0.7, 0.9, 1.0, 0.8)
	diamond.rotation = deg_to_rad(45)  # Make it diamond shaped

	# Add a subtle glow effect with a larger, more transparent diamond behind
	var glow = ColorRect.new()
	glow.size = Vector2(8, 8)
	glow.position = Vector2(-4, -4)
	glow.color = Color(0.8, 0.95, 1.0, 0.3)
	glow.rotation = deg_to_rad(45)

	shard_container.add_child(glow)
	shard_container.add_child(diamond)

	# Add subtle scale pulsing
	var pulse_tween = create_tween()
	pulse_tween.set_loops()
	pulse_tween.tween_property(diamond, "scale", Vector2(1.2, 1.2), 0.4)
	pulse_tween.tween_property(diamond, "scale", Vector2(1.0, 1.0), 0.4)

	return shard_container

func _setup_timers():
	"""Setup damage and duration timers"""
	# Damage tick timer
	damage_timer = Timer.new()
	damage_timer.wait_time = 0.1  # 10 times per second
	damage_timer.timeout.connect(_on_damage_tick)
	add_child(damage_timer)

	# Duration timer
	duration_timer = Timer.new()
	duration_timer.wait_time = duration
	duration_timer.one_shot = true
	duration_timer.timeout.connect(_on_duration_end)
	add_child(duration_timer)

func _start_rotation():
	"""Start the rotation animation"""
	rotation_tween = create_tween()
	rotation_tween.set_loops()
	rotation_tween.tween_property(self, "rotation", deg_to_rad(360), 360.0 / rotation_speed)

	# Start timers
	damage_timer.start()
	duration_timer.start()

func _on_damage_tick():
	"""Deal damage to enemies touching the rotating beams"""
	for beam_area in beam_areas:
		if not is_instance_valid(beam_area):
			continue

		var bodies = beam_area.get_overlapping_bodies()
		for body in bodies:
			if body.is_in_group("enemies") and body.has_method("take_damage_from_source"):
				# Deal reduced damage since this ticks frequently
				body.take_damage_from_source(beam_damage * 0.1, bottle_id)

				# Visual feedback for hit
				_create_beam_hit_effect(body.global_position)

func _on_duration_end():
	"""Clean up the prism effect"""
	# Restore enemy movement
	if is_instance_valid(target_enemy):
		if target_enemy.has_method("set_movement_disabled"):
			target_enemy.set_movement_disabled(false)
		elif target_enemy.has_meta("original_move_speed"):
			target_enemy.move_speed = target_enemy.get_meta("original_move_speed")
			target_enemy.remove_meta("original_move_speed")

	# Fade out effect
	var fade_tween = create_tween()
	fade_tween.tween_property(self, "modulate:a", 0.0, 0.3)
	fade_tween.tween_callback(queue_free)

func _create_beam_hit_effect(position: Vector2):
	"""Create small ice particle effect when beam hits enemy"""
	var particle = ColorRect.new()
	particle.size = Vector2(4, 4)
	particle.position = to_local(position) - Vector2(2, 2)
	particle.color = Color(0.9, 0.95, 1.0, 1.0)

	add_child(particle)

	# Quick sparkle effect
	var tween = create_tween()
	tween.parallel().tween_property(particle, "scale", Vector2(2.0, 2.0), 0.2)
	tween.parallel().tween_property(particle, "modulate:a", 0.0, 0.2)
	tween.tween_callback(particle.queue_free)

func create_activation_effect():
	"""Create effect when prism first activates"""
	# Flash effect
	var flash = ColorRect.new()
	flash.size = Vector2(40, 40)
	flash.position = Vector2(-20, -20)
	flash.color = Color(0.8, 0.9, 1.0, 0.8)

	add_child(flash)

	var flash_tween = create_tween()
	flash_tween.parallel().tween_property(flash, "scale", Vector2(2.0, 2.0), 0.3)
	flash_tween.parallel().tween_property(flash, "modulate:a", 0.0, 0.3)
	flash_tween.tween_callback(flash.queue_free)

	# Create expanding ice ring
	_create_expanding_ice_ring(60.0, 0.5)

func _create_expanding_ice_ring(max_radius: float, ring_duration: float):
	"""Create an expanding ice ring effect"""
	var ring = ColorRect.new()
	ring.color = Color(0.7, 0.9, 1.0, 0.6)
	ring.size = Vector2(10, 10)
	ring.position = Vector2(-5, -5)

	add_child(ring)

	var tween = create_tween()
	tween.parallel().tween_property(ring, "size", Vector2(max_radius * 2, max_radius * 2), ring_duration)
	tween.parallel().tween_property(ring, "position", Vector2(-max_radius, -max_radius), ring_duration)
	tween.parallel().tween_property(ring, "modulate:a", 0.0, ring_duration)
	tween.tween_callback(ring.queue_free)
