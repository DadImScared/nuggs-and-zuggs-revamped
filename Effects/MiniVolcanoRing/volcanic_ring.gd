# Effects/VolcanicRing.gd
extends Node2D

var ring_damage: float = 0.0
var max_radius: float = 120.0
var duration: float = 3.0
var source_bottle_id: String = ""

var current_radius: float = 0.0
var elapsed_time: float = 0.0
var expansion_speed: float = 0.0

# Ring properties
var ring_thickness: float = 15.0
var damage_interval: float = 0.2  # Damage every 0.2 seconds
var last_damage_time: float = 0.0

# Visual component
var ring_visual: Node2D

func _ready():
	# Set up physics
	z_index = 1  # Above ground, below UI

	# Create simple visual ring
	_create_simple_ring_visual()

func _create_simple_ring_visual():
	# Create a simple circle using Line2D
	var line = Line2D.new()
	line.width = 8.0
	line.default_color = Color(1.0, 0.5, 0.0, 0.8)  # Orange
	line.antialiased = true

	# Create circle points
	var points = []
	var segments = 32
	for i in range(segments + 1):
		var angle = (i * TAU) / segments
		var point = Vector2(cos(angle), sin(angle)) * 60.0  # Base radius
		points.append(point)

	for point in points:
		line.add_point(point)

	add_child(line)
	ring_visual = line

func setup_ring(damage: float, radius: float, ring_duration: float, bottle_id: String):
	ring_damage = damage
	max_radius = radius
	duration = ring_duration
	source_bottle_id = bottle_id
	expansion_speed = max_radius / duration

	print("🌋 Ring setup: %.1f damage, %.0f radius, %.1f duration" % [damage, radius, ring_duration])

func _process(delta):
	elapsed_time += delta

	# Expand the ring
	current_radius = min(expansion_speed * elapsed_time, max_radius)

	# Update visual scale
	if ring_visual:
		var scale_factor = current_radius / 60.0  # Base radius was 60
		ring_visual.scale = Vector2(scale_factor, scale_factor)

		# Fade out as ring expands
		var alpha = 1.0 - (elapsed_time / duration) * 0.5
		ring_visual.modulate.a = alpha

	# Apply damage at intervals
	if elapsed_time - last_damage_time >= damage_interval:
		_apply_ring_damage()
		last_damage_time = elapsed_time

	# Remove when duration expires
	if elapsed_time >= duration:
		_fade_out_and_destroy()

func _apply_ring_damage():
	# Get ring boundaries for damage
	var inner_radius = max(0.0, current_radius - ring_thickness)
	var outer_radius = current_radius

	# Find enemies in the ring
	var enemies_in_ring = _get_enemies_in_ring_area(inner_radius, outer_radius)

	# Apply damage to enemies in the ring
	for enemy in enemies_in_ring:
		if enemy.has_method("take_damage_from_source"):
			print("enemy take ddamag effrom source ------------- ", ring_damage * damage_interval)
			enemy.take_damage_from_source(ring_damage * damage_interval, source_bottle_id)
		elif enemy.has_method("take_damage"):
			enemy.take_damage(ring_damage * damage_interval, source_bottle_id)

func _get_enemies_in_ring_area(inner_radius: float, outer_radius: float) -> Array:
	var enemies_in_ring = []
	var all_enemies = get_tree().get_nodes_in_group("enemies")

	for enemy in all_enemies:
		if not is_instance_valid(enemy):
			continue

		var distance = global_position.distance_to(enemy.global_position)
		if distance >= inner_radius and distance <= outer_radius:
			enemies_in_ring.append(enemy)

	return enemies_in_ring

func _fade_out_and_destroy():
	# Create fade out tween
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.5)
	tween.tween_callback(queue_free)
