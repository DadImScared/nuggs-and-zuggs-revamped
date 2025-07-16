# SauceActions/infection/infection_visuals.gd
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
	var particles = CPUParticles2D.new()
	particles.emitting = true
	particles.amount = 15
	particles.lifetime = 1.2
	particles.explosiveness = 1.0
	particles.direction = (to_pos - from_pos).normalized()
	particles.initial_velocity_min = 80.0
	particles.initial_velocity_max = 150.0
	particles.scale_amount_min = 0.4
	particles.scale_amount_max = 1.0
	particles.color = color
	particles.global_position = from_pos

	# Add to scene first
	Engine.get_main_loop().current_scene.add_child(particles)

	# Auto cleanup timer - add after adding to scene
	var timer = Timer.new()
	timer.wait_time = 1.5
	timer.one_shot = true
	timer.timeout.connect(func(): particles.queue_free())
	particles.add_child(timer)
	timer.start()

static func create_mutation_visual(enemy_pos: Vector2, color: Color):
	"""Create visual effect for mutating infection"""
	var mutation_effect = ColorRect.new()
	mutation_effect.color = Color(color.r, color.g, color.b, 0.6)
	mutation_effect.size = Vector2(40, 40)
	mutation_effect.position = enemy_pos - Vector2(20, 20)

	# Add to scene first
	Engine.get_main_loop().current_scene.add_child(mutation_effect)

	# Pulsing mutation effect
	var tween = mutation_effect.create_tween()
	tween.set_loops()
	tween.tween_property(mutation_effect, "scale", Vector2(1.3, 1.3), 0.4)
	tween.tween_property(mutation_effect, "scale", Vector2(1.0, 1.0), 0.4)

	# Auto cleanup timer - add after adding to scene
	var cleanup_timer = Timer.new()
	cleanup_timer.wait_time = 2.0
	cleanup_timer.one_shot = true
	cleanup_timer.timeout.connect(func(): mutation_effect.queue_free())
	mutation_effect.add_child(cleanup_timer)
	cleanup_timer.start()

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
	cleanup_timer.start()  # Now it can start because it's in the scene tree

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
