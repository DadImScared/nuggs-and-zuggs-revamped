# SauceActions/Infection/visuals.gd
class_name InfectionVisuals
extends RefCounted

# Static class for all infection visual effects
# Called by InfectionAction to create visual effects

static func create_infection_spread_visual(from_pos: Vector2, to_pos: Vector2, color: Color):
	"""Create visual effect for infection spreading between enemies"""
	var line = Line2D.new()
	line.width = 2.0  # Thinner starting width
	line.default_color = color
	line.add_point(Vector2.ZERO)
	line.add_point(to_pos - from_pos)
	line.global_position = from_pos

	# Add pulsing animation with thinner max width
	var tween = line.create_tween()
	tween.set_parallel(true)
	tween.tween_property(line, "modulate:a", 0.0, 0.5)
	tween.tween_property(line, "width", 4.0, 0.3)  # Thinner max width
	tween.tween_callback(func(): line.queue_free()).set_delay(0.5)

	Engine.get_main_loop().current_scene.add_child(line)

static func create_infection_wave_visual(epicenter: Vector2, target: Vector2, color: Color, radius: float):
	"""Create visual effect for epidemic wave spreading"""
	var wave_circle = ColorRect.new()
	wave_circle.color = Color(color.r, color.g, color.b, 0.3)
	wave_circle.size = Vector2(radius * 2, radius * 2)
	wave_circle.position = epicenter - Vector2(radius, radius)

	# Create expanding circle effect
	var tween = wave_circle.create_tween()
	tween.set_parallel(true)
	tween.tween_property(wave_circle, "size", Vector2(radius * 4, radius * 4), 0.8)
	tween.tween_property(wave_circle, "position", epicenter - Vector2(radius * 2, radius * 2), 0.8)
	tween.tween_property(wave_circle, "modulate:a", 0.0, 0.8)
	tween.tween_callback(func(): wave_circle.queue_free()).set_delay(0.8)

	Engine.get_main_loop().current_scene.add_child(wave_circle)

static func create_pandemic_spread_visual(from_pos: Vector2, to_pos: Vector2, color: Color):
	"""Create special visual for pandemic-level infection spread"""
	# Create 15 particles that travel from source to target
	for i in range(15):
		var particle = ColorRect.new()
		particle.size = Vector2(4, 4)
		particle.color = color
		particle.global_position = from_pos + Vector2(randf_range(-10, 10), randf_range(-10, 10))
		Engine.get_main_loop().current_scene.add_child(particle)

		# Travel to target with some randomness
		var target_offset = Vector2(randf_range(-20, 20), randf_range(-20, 20))
		var travel_time = randf_range(0.8, 1.4)

		var tween = particle.create_tween()
		tween.set_parallel(true)

		# Movement
		tween.tween_property(particle, "global_position", to_pos + target_offset, travel_time)

		# Scale animation
		tween.tween_property(particle, "scale", Vector2(1.5, 1.5), travel_time * 0.3)
		tween.tween_property(particle, "scale", Vector2(0.5, 0.5), travel_time * 0.7).set_delay(travel_time * 0.3)

		# Fade out
		tween.tween_property(particle, "modulate:a", 0.0, travel_time)
		tween.tween_callback(particle.queue_free)

static func create_mutation_visual(enemy_pos: Vector2, color: Color):
	"""Create visual effect for mutating infection"""
	print("🧬 MUTATION VISUAL CALLED at position: ", enemy_pos)

	# Create one simple circle like before, but with sauce color
	var circle = ColorRect.new()
	circle.size = Vector2(60, 60)
	circle.color = Color(color.r, color.g, color.b + 0.4, 0.8)  # Sauce color with more blue
	circle.global_position = enemy_pos - Vector2(30, 30)  # Center it
	circle.z_index = 1000

	# Add to scene
	var scene = Engine.get_main_loop().current_scene
	scene.add_child(circle)
	print("🧬 Added circle at: ", circle.global_position)

	# Simple fade out over 3 seconds
	var tween = circle.create_tween()
	tween.tween_property(circle, "modulate:a", 0.0, 3.0)
	tween.tween_callback(circle.queue_free)

	print("🧬 Circle created - should fade out over 3 seconds")

static func _create_dna_helix_effect(enemy_pos: Vector2, color: Color):
	"""Create secondary helix pattern for enhanced mutation visual"""
	# Create 6 smaller helix particles with better spread - SLOWER
	for i in range(6):
		var helix_particle = ColorRect.new()
		helix_particle.size = Vector2(randf_range(2, 5), randf_range(2, 5))
		helix_particle.color = Color(
			clamp(color.r + randf_range(0.2, 0.5), 0.0, 1.0),
			clamp(color.g + randf_range(0.2, 0.5), 0.0, 1.0),
			clamp(color.b + randf_range(0.2, 0.5), 0.0, 1.0),
			randf_range(0.7, 1.0)
		)

		# Start particles around the enemy in a smaller circle
		var base_angle = i * TAU / 6
		var start_radius = randf_range(5, 10)
		helix_particle.global_position = enemy_pos + Vector2.RIGHT.rotated(base_angle) * start_radius

		Engine.get_main_loop().current_scene.add_child(helix_particle)

		# Create helix movement with better pattern - MUCH SLOWER
		var duration = randf_range(2.5, 3.5)  # Was 1.2-1.8, now 2.5-3.5
		var helix_rotations = randf_range(1.0, 2.0)  # Reduced from 2.0-4.0 for smoother motion
		var max_radius = randf_range(20, 35)

		var tween = helix_particle.create_tween()
		tween.set_parallel(true)

		# Helix spiral movement with vertical oscillation - slower
		tween.tween_method(
			func(progress):
				var helix_angle = base_angle + (progress * TAU * helix_rotations)
				var current_radius = start_radius + (progress * (max_radius - start_radius))
				var height_offset = sin(progress * TAU * 3) * 10.0  # Slower vertical (was 8), more pronounced (was 8.0)
				var pos = enemy_pos + Vector2.RIGHT.rotated(helix_angle) * current_radius + Vector2(0, height_offset)
				helix_particle.global_position = pos,
			0.0, 1.0, duration
		)

		# Scale pulse with more variation - slower with longer hold
		var max_scale = randf_range(1.2, 2.0)
		var scale_up_time = duration * 0.3
		var scale_hold_time = duration * 0.5
		var scale_down_time = duration * 0.2

		tween.tween_property(helix_particle, "scale", Vector2(max_scale, max_scale), scale_up_time)
		tween.tween_property(helix_particle, "scale", Vector2(max_scale, max_scale), scale_hold_time).set_delay(scale_up_time)
		tween.tween_property(helix_particle, "scale", Vector2(0.1, 0.1), scale_down_time).set_delay(scale_up_time + scale_hold_time)

		# Much slower rotation for more organic feel
		tween.tween_property(helix_particle, "rotation", randf_range(-TAU, TAU), duration)

		# Delayed fade out - stays visible much longer
		tween.tween_property(helix_particle, "modulate:a", 1.0, duration * 0.8)  # Stay bright longer
		tween.tween_property(helix_particle, "modulate:a", 0.0, duration * 0.2).set_delay(duration * 0.8)  # Quick fade at end
		tween.tween_callback(helix_particle.queue_free)

static func create_toxic_strain_visual(enemy_pos: Vector2):
	"""Create visual effect for toxic strain infection"""
	var toxic_effect = ColorRect.new()
	toxic_effect.color = Color(0.2, 0.8, 0.2, 0.4)  # Toxic green
	toxic_effect.size = Vector2(50, 50)
	toxic_effect.position = enemy_pos - Vector2(25, 25)

	# Add to scene first
	Engine.get_main_loop().current_scene.add_child(toxic_effect)

	# Bubbling toxic effect
	var tween = toxic_effect.create_tween()
	tween.set_loops()
	tween.tween_property(toxic_effect, "scale", Vector2(1.2, 1.2), 0.3)
	tween.tween_property(toxic_effect, "scale", Vector2(0.8, 0.8), 0.3)
	tween.tween_property(toxic_effect, "modulate:a", 0.8, 0.3)
	tween.tween_property(toxic_effect, "modulate:a", 0.3, 0.3)

	# Auto cleanup timer - add after adding to scene
	var cleanup_timer = Timer.new()
	cleanup_timer.wait_time = 3.0
	cleanup_timer.one_shot = true
	cleanup_timer.timeout.connect(func(): toxic_effect.queue_free())
	toxic_effect.add_child(cleanup_timer)
	cleanup_timer.start()

static func create_epidemic_start_visual(epicenter: Vector2, color: Color):
	"""Create visual effect when epidemic starts"""
	var start_burst = ColorRect.new()
	start_burst.color = Color(color.r, color.g, color.b, 0.8)
	start_burst.size = Vector2(30, 30)
	start_burst.position = epicenter - Vector2(15, 15)

	# Burst expansion effect
	var tween = start_burst.create_tween()
	tween.set_parallel(true)
	tween.tween_property(start_burst, "size", Vector2(120, 120), 0.6)
	tween.tween_property(start_burst, "position", epicenter - Vector2(60, 60), 0.6)
	tween.tween_property(start_burst, "modulate:a", 0.0, 0.6)
	tween.tween_callback(func(): start_burst.queue_free()).set_delay(0.6)

	Engine.get_main_loop().current_scene.add_child(start_burst)

static func create_infection_death_spread_visual(from_pos: Vector2, to_pos: Vector2, color: Color):
	"""Create visual for infection spreading when enemy dies"""
	# Similar to regular spread but with death-specific styling
	var death_line = Line2D.new()
	death_line.width = 2.0  # Same thin starting width
	death_line.default_color = Color(color.r * 0.8, color.g * 0.8, color.b * 0.8, 0.9)
	death_line.add_point(Vector2.ZERO)
	death_line.add_point(to_pos - from_pos)
	death_line.global_position = from_pos

	# Death spread has different animation - more urgent but same thickness
	var tween = death_line.create_tween()
	tween.set_parallel(true)
	tween.tween_property(death_line, "modulate:a", 0.0, 0.3)
	tween.tween_property(death_line, "width", 4.0, 0.2)  # Same max width as regular spread
	tween.tween_callback(func(): death_line.queue_free()).set_delay(0.3)

	Engine.get_main_loop().current_scene.add_child(death_line)
