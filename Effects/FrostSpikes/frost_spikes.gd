# Effects/FrostSpikes/frost_spikes.gd
extends Node2D

# Frost Spikes properties
var damage: float = 20.0
var cold_stacks: int = 2
var spike_size: float = 60.0
var apply_cold: bool = true
var speed: float = 45.0
var bottle_id: String = ""
var target_position: Vector2
var spike_count: int = 6
var spike_spacing: float = 60.0

# Visual and collision components
var spikes: Array[Node2D] = []
var spike_areas: Array[Area2D] = []
var emergence_timer: float = 0.0
var current_spike_index: int = 0
var is_active: bool = false

func _ready():
	print("🗡️ Frost Spikes scene ready")

func initialize(spike_damage: float, target_pos: Vector2, spike_stacks: int,
			   spike_size_param: float, apply_cold_param: bool,
			   spike_speed: float, source_bottle_id: String):
	"""Initialize and start the frost spikes effect"""
	damage = spike_damage
	target_position = target_pos
	cold_stacks = spike_stacks
	spike_size = spike_size_param
	apply_cold = apply_cold_param
	speed = spike_speed
	bottle_id = source_bottle_id

	print("🗡️ Frost Spikes - From: %s To: %s" % [global_position, target_position])

	# Calculate and create spikes
	calculate_spike_trail()
	create_spike_structures()
	start_spike_emergence()

func calculate_spike_trail():
	"""Calculate positions for spikes along the trail"""
	var start_pos = global_position
	var total_distance = start_pos.distance_to(target_position)

	# Reasonable spike count based on distance
	spike_count = clamp(int(total_distance / spike_spacing), 3, 8)
	print("🗡️ Creating %d spikes over %.0f units" % [spike_count, total_distance])

func create_spike_structures():
	"""Create all spike structures"""
	var start_pos = global_position
	var direction = (target_position - start_pos).normalized()

	for i in range(spike_count):
		var spike_distance = (i + 1) * spike_spacing
		var spike_pos = start_pos + direction * spike_distance

		# Vary spike heights
		var height_mult = [1.0, 0.7, 1.2, 0.8, 1.1, 0.6, 0.9, 1.3][i % 8]
		var spike_node = create_single_spike(spike_pos, height_mult, i)
		spikes.append(spike_node)

func create_single_spike(pos: Vector2, height_mult: float, spike_index: int) -> Node2D:
	"""Create a single crystalline spike"""
	var spike_container = Node2D.new()
	spike_container.name = "Spike_%d" % spike_index
	spike_container.global_position = pos
	spike_container.modulate.a = 0.0  # Start invisible
	add_child(spike_container)

	# Create crystal visual
	var spike_visual = create_crystal_visual(height_mult)
	spike_container.add_child(spike_visual)

	# Create collision area
	var spike_area = create_spike_collision(height_mult)
	spike_container.add_child(spike_area)
	spike_areas.append(spike_area)

	return spike_container

func create_crystal_visual(height_mult: float) -> Node2D:
	"""Create ice crystal visual using reliable ColorRect approach"""
	var visual_container = Node2D.new()
	visual_container.name = "CrystalVisual"

	var spike_height = spike_size * height_mult
	var base_width = spike_height * 0.4

	# Main crystal body
	var main_crystal = ColorRect.new()
	main_crystal.size = Vector2(base_width, spike_height)
	main_crystal.position = Vector2(-base_width/2, -spike_height)
	main_crystal.color = Color(0.7, 0.9, 1.0, 0.8)  # Ice blue
	visual_container.add_child(main_crystal)

	# Crystal tip
	var tip_width = base_width * 0.6
	var tip_height = spike_height * 0.25
	var tip = ColorRect.new()
	tip.size = Vector2(tip_width, tip_height)
	tip.position = Vector2(-tip_width/2, -spike_height - tip_height)
	tip.color = Color(0.8, 0.95, 1.0, 0.9)
	visual_container.add_child(tip)

	# Left side crystal
	var left_side = ColorRect.new()
	left_side.size = Vector2(base_width * 0.3, spike_height * 0.6)
	left_side.position = Vector2(-base_width * 0.8, -spike_height * 0.8)
	left_side.color = Color(0.6, 0.8, 0.95, 0.7)
	left_side.rotation = -0.2
	visual_container.add_child(left_side)

	# Right side crystal
	var right_side = ColorRect.new()
	right_side.size = Vector2(base_width * 0.3, spike_height * 0.6)
	right_side.position = Vector2(base_width * 0.5, -spike_height * 0.8)
	right_side.color = Color(0.6, 0.8, 0.95, 0.7)
	right_side.rotation = 0.2
	visual_container.add_child(right_side)

	# Highlight lines using Line2D (properly positioned)
	var highlight = Line2D.new()
	highlight.width = 2.0
	highlight.default_color = Color(1.0, 1.0, 1.0, 0.8)
	highlight.add_point(Vector2(0, -spike_height - tip_height))  # Top
	highlight.add_point(Vector2(0, 0))  # Bottom
	visual_container.add_child(highlight)

	# Ice particles
	var particles = create_ice_particles(base_width)
	visual_container.add_child(particles)

	return visual_container

func create_ice_particles(base_width: float) -> CPUParticles2D:
	"""Create ice particles around spike base"""
	var particles = CPUParticles2D.new()
	particles.name = "IceParticles"

	# Particle settings
	particles.emitting = false  # Start when spike emerges
	particles.amount = 10
	particles.lifetime = 1.0
	particles.one_shot = true
	particles.explosiveness = 0.8

	# Emission shape
	particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	particles.emission_sphere_radius = base_width

	# Movement
	particles.spread = 360.0
	particles.initial_velocity_min = 20.0
	particles.initial_velocity_max = 40.0
	particles.gravity = Vector2(0, 30)

	# Appearance
	particles.scale_amount_min = 0.3
	particles.scale_amount_max = 0.6
	particles.color = Color(0.8, 0.95, 1.0, 0.8)

	return particles

func create_spike_collision(height_mult: float) -> Area2D:
	"""Create collision area for damage detection"""
	var area = Area2D.new()
	area.name = "SpikeCollision"
	area.collision_layer = 0
	area.collision_mask = 1 << 1  # Enemy layer

	# Collision shape - much bigger to hit enemies between spikes
	var collision_shape = CollisionShape2D.new()
	var rect_shape = RectangleShape2D.new()
	# Make collision wider and taller to cover more area
	rect_shape.size = Vector2(spike_size * 1.2, spike_size * height_mult * 1.4)
	collision_shape.shape = rect_shape
	collision_shape.position = Vector2(0, -spike_size * height_mult * 0.7)
	area.add_child(collision_shape)

	# Connect signals
	area.body_entered.connect(_on_spike_hit_enemy)
	area.area_entered.connect(_on_spike_hit_enemy)

	return area

func start_spike_emergence():
	"""Start sequential spike emergence"""
	print("🗡️ Starting spike emergence")
	is_active = true
	current_spike_index = 0
	emergence_timer = 0.0
	set_process(true)

func _process(delta):
	"""Handle spike emergence timing"""
	if not is_active or current_spike_index >= spikes.size():
		if current_spike_index >= spikes.size():
			# All spikes emerged, start cleanup timer
			call_deferred("_schedule_cleanup")
		set_process(false)
		return

	emergence_timer += delta
	var emergence_interval = 1.0 / speed

	if emergence_timer >= emergence_interval:
		emerge_next_spike()
		emergence_timer = 0.0
		current_spike_index += 1

func emerge_next_spike():
	"""Make the next spike emerge"""
	if current_spike_index >= spikes.size():
		return

	var spike = spikes[current_spike_index]
	if not is_instance_valid(spike):
		return

	print("🗡️ Emerging spike %d" % current_spike_index)

	# Start particles
	var particles = spike.get_node("CrystalVisual/IceParticles")
	if particles:
		particles.emitting = true

	# Emergence animation
	spike.scale = Vector2(0.2, 0.2)
	spike.position.y += 15  # Start below ground

	var emerge_tween = create_tween()
	emerge_tween.set_parallel(true)
	emerge_tween.set_ease(Tween.EASE_OUT)
	emerge_tween.set_trans(Tween.TRANS_BACK)

	# Animate emergence
	emerge_tween.tween_property(spike, "modulate:a", 1.0, 0.3)
	emerge_tween.tween_property(spike, "scale", Vector2(1.0, 1.0), 0.4)
	emerge_tween.tween_property(spike, "position:y", spike.position.y - 15, 0.3)

func _schedule_cleanup():
	"""Schedule cleanup after all spikes have emerged"""
	await get_tree().create_timer(2.5).timeout
	if is_instance_valid(self):
		cleanup_spikes()

func _on_spike_hit_enemy(body: Node):
	"""Handle spike hitting enemy"""
	if not body or not is_instance_valid(body):
		return

	if not body.is_in_group("enemies"):
		return

	# Prevent rapid repeated hits
	if body.has_meta("last_spike_hit_time"):
		var last_hit = body.get_meta("last_spike_hit_time")
		if Time.get_ticks_msec() - last_hit < 200:
			return

	body.set_meta("last_spike_hit_time", Time.get_ticks_msec())

	print("🗡️ Spike hit %s for %.0f damage" % [body.name, damage])

	# Apply damage
	if body.has_method("take_damage_from_source"):
		body.take_damage_from_source(damage, bottle_id)

	# Apply cold effect
	if apply_cold and Effects and Effects.cold:
		var cold_params = {
			"duration": 4.0,
			"slow_per_stack": 0.15,
			"max_stacks": 6,
			"stack_value": cold_stacks
		}
		Effects.cold.apply_from_talent(body, null, cold_stacks, cold_params)

	# Hit effect
	create_hit_effect(body.global_position)

func create_hit_effect(hit_position: Vector2):
	"""Create visual effect when spike hits enemy"""
	var hit_particles = CPUParticles2D.new()
	get_tree().current_scene.add_child(hit_particles)
	hit_particles.global_position = hit_position

	# Ice shard burst
	hit_particles.emitting = true
	hit_particles.amount = 12
	hit_particles.lifetime = 0.6
	hit_particles.one_shot = true
	hit_particles.explosiveness = 1.0
	hit_particles.spread = 360.0
	hit_particles.initial_velocity_min = 30.0
	hit_particles.initial_velocity_max = 60.0
	hit_particles.gravity = Vector2(0, 40)
	hit_particles.color = Color(0.9, 0.95, 1.0, 1.0)

	# Cleanup after effect
	await get_tree().create_timer(0.8).timeout
	if is_instance_valid(hit_particles):
		hit_particles.queue_free()

func cleanup_spikes():
	"""Clean up the frost spikes effect"""
	print("🗡️ Cleaning up frost spikes")
	is_active = false
	set_process(false)

	# Fade out
	var fade_tween = create_tween()
	fade_tween.tween_property(self, "modulate:a", 0.0, 1.0)
	fade_tween.tween_callback(queue_free)
