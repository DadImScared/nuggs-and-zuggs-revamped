# Singletons/talent_effect_manager.gd
# Add to AutoLoad as TalentEffectManager

extends Node

# Global effect tracking
var permanent_damage_fields: Array[Node2D] = []
var mega_puddles: Array[Node2D] = []
var active_transformations: Dictionary = {}

func create_mini_volcano(position: Vector2, damage: float, radius: float, source_bottle_id: String):
	# Create a smaller volcanic ring at the bottle's position
	var mini_ring = preload("res://Effects/MiniVolcanoRing/volcanic_ring.tscn").instantiate()
	mini_ring.global_position = position
	mini_ring.setup_ring(damage, radius, 2.0, source_bottle_id)  # 2 second duration
	mini_ring.modulate = Color(1.0, 0.8, 0.2, 0.9)  # Smaller, more yellow tint
	mini_ring.scale = Vector2(0.7, 0.7)  # Make it visually smaller
	get_tree().current_scene.add_child(mini_ring)

func create_tsunami_wave(origin: Vector2, damage: float):
	print("🌊 CREATING TSUNAMI WAVE! 🌊")

	# Create visual wave effect
	_create_tsunami_visual(origin)

	# Damage all enemies on screen
	var enemies = get_tree().get_nodes_in_group("enemies")
	for enemy in enemies:
		if enemy.has_method("take_damage_from_source"):
			enemy.take_damage_from_source(damage, "tsunami")
		elif enemy.has_method("take_damage"):
			enemy.take_damage(damage)

	# Screen shake and effects
	create_screen_shake(3.0, 1.5)
	_create_splash_particles(origin)

func _create_tsunami_visual(origin: Vector2):
	# Create expanding wave visual
	var wave = ColorRect.new()
	wave.size = Vector2(50, 50)
	wave.color = Color.BLUE
	wave.modulate.a = 0.7
	wave.global_position = origin - wave.size/2
	get_tree().current_scene.add_child(wave)

	var tween = create_tween()
	tween.parallel().tween_property(wave, "size", Vector2(2000, 100), 1.0)
	tween.parallel().tween_property(wave, "global_position", origin - Vector2(1000, 50), 1.0)
	tween.parallel().tween_property(wave, "modulate:a", 0.0, 1.0)
	tween.tween_callback(wave.queue_free)

func transform_arena(source_bottle: ImprovedBaseSauceBottle):
	print("🔥 ARENA TRANSFORMATION ACTIVATED! 🔥")

	# Change arena background/theme
	var arena = get_tree().get_first_node_in_group("arena")
	if arena and arena.has_method("transform_to_ketchup_arena"):
		arena.transform_to_ketchup_arena()

	# Create permanent damage field
	create_permanent_damage_field(source_bottle.sauce_data.damage * 0.1)

	# Visual transformation
	_transform_arena_visuals()

func transform_arena_to_ketchup_hell(source_bottle: ImprovedBaseSauceBottle):
	print("💀 TOMATO APOCALYPSE! THE END TIMES! 💀")

	# Ultimate arena transformation
	transform_arena(source_bottle)

	# Create multiple permanent damage fields
	for i in range(5):
		var offset = Vector2(randf_range(-500, 500), randf_range(-500, 500))
		create_permanent_damage_field(source_bottle.sauce_data.damage * 0.2, offset)

	# Change music/atmosphere
	_trigger_apocalypse_atmosphere()

func _transform_arena_visuals():
	# Change background color
	var camera = get_viewport().get_camera_2d()
	if camera:
		camera.modulate = Color(1.2, 0.8, 0.8)  # Reddish tint

	# Add visual effects
	_create_arena_particle_effects()

func _trigger_apocalypse_atmosphere():
	# Screen effects
	create_screen_shake(1.0, 999.0)  # Permanent slight shake

	# Visual effects
	var screen = ColorRect.new()
	screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	screen.color = Color.RED
	screen.modulate.a = 0.2
	get_tree().current_scene.add_child(screen)

func create_permanent_damage_field(damage_per_second: float, offset: Vector2 = Vector2.ZERO):
	var damage_field = Node2D.new()
	damage_field.name = "PermanentDamageField"
	damage_field.global_position = offset
	get_tree().current_scene.add_child(damage_field)
	permanent_damage_fields.append(damage_field)

	# Create timer for damage ticks
	var timer = Timer.new()
	timer.wait_time = 0.5
	timer.timeout.connect(_damage_field_tick.bind(damage_per_second))
	damage_field.add_child(timer)
	timer.start()

	# Visual indicator
	_create_damage_field_visual(damage_field, offset)

	print("Permanent damage field created! %.1f DPS to all enemies" % damage_per_second)

func _damage_field_tick(damage: float):
	var enemies = get_tree().get_nodes_in_group("enemies")
	for enemy in enemies:
		if enemy.has_method("take_damage"):
			enemy.take_damage(damage)

func _create_damage_field_visual(field: Node2D, position: Vector2):
	# Create subtle visual indicator
	var indicator = ColorRect.new()
	indicator.size = Vector2(2000, 2000)  # Cover whole screen
	indicator.color = Color.RED
	indicator.modulate.a = 0.05
	indicator.position = position - indicator.size/2
	field.add_child(indicator)

	# Pulsing effect
	var tween = create_tween()
	tween.set_loops()
	tween.tween_property(indicator, "modulate:a", 0.1, 1.0)
	tween.tween_property(indicator, "modulate:a", 0.05, 1.0)

func activate_god_mode(bottle: ImprovedBaseSauceBottle, duration: float = 30.0):
	print("⚡ GOD MODE ACTIVATED! ⚡")

	# Store original stats
	var original_stats = {
		"damage": bottle.sauce_data.damage,
		"fire_rate": bottle.sauce_data.fire_rate,
		"range": bottle.sauce_data.range
	}

	# Make stats infinite
	bottle.sauce_data.damage = 999999
	bottle.sauce_data.fire_rate = 50.0
	bottle.sauce_data.range = 2000.0

	# Visual effects
	create_god_mode_aura(bottle)

	# Track transformation
	active_transformations[bottle.bottle_id] = {
		"type": "god_mode",
		"original_stats": original_stats,
		"end_time": Time.get_unix_time_from_system() + duration
	}

	# Restore after duration
	get_tree().create_timer(duration).timeout.connect(func():
		_end_god_mode(bottle, original_stats)
	)

func _end_god_mode(bottle: ImprovedBaseSauceBottle, original_stats: Dictionary):
	if is_instance_valid(bottle):
		bottle.sauce_data.damage = original_stats.damage
		bottle.sauce_data.fire_rate = original_stats.fire_rate
		bottle.sauce_data.range = original_stats.range

		if active_transformations.has(bottle.bottle_id):
			active_transformations.erase(bottle.bottle_id)

		print("God Mode ended for %s" % bottle.bottle_id)

func create_god_mode_aura(bottle: ImprovedBaseSauceBottle):
	# Create golden aura around bottle
	var aura = ColorRect.new()
	aura.size = Vector2(120, 120)
	aura.color = Color.GOLD
	aura.modulate.a = 0.4
	bottle.add_child(aura)
	aura.position = -aura.size/2

	# Pulsing effect
	var tween = create_tween()
	tween.set_loops()
	tween.tween_property(aura, "modulate:a", 0.8, 0.3)
	tween.tween_property(aura, "modulate:a", 0.4, 0.3)
	tween.parallel().tween_property(aura, "rotation", TAU, 2.0)

func create_eternal_flood_mode(bottle: ImprovedBaseSauceBottle):
	print("🌊 ETERNAL FLOOD ACTIVATED! 🌊")

	# All puddles become permanent and stack
	active_transformations[bottle.bottle_id] = {
		"type": "eternal_flood",
		"puddle_stacks": {}
	}

func create_damage_puddle(position: Vector2, damage: float, duration: float = 5.0, eternal: bool = false):
	var puddle = _create_puddle_visual(position)

	# Set up damage area
	var area = Area2D.new()
	area.global_position = position
	get_tree().current_scene.add_child(area)

	var collision = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = 50.0
	collision.shape = shape
	area.add_child(collision)

	# Damage timer
	var timer = Timer.new()
	timer.wait_time = 0.5
	timer.timeout.connect(_puddle_damage_tick.bind(area, damage))
	area.add_child(timer)
	timer.start()

	# Handle eternal puddles
	if eternal:
		mega_puddles.append(area)
		_setup_eternal_puddle(area, damage)
	else:
		# Normal puddle cleanup
		get_tree().create_timer(duration).timeout.connect(func():
			if is_instance_valid(area):
				area.queue_free()
			if is_instance_valid(puddle):
				puddle.queue_free()
		)

func _create_puddle_visual(position: Vector2) -> Node2D:
	var puddle_visual = ColorRect.new()
	puddle_visual.size = Vector2(100, 100)
	puddle_visual.color = Color.RED
	puddle_visual.modulate.a = 0.6
	puddle_visual.global_position = position - puddle_visual.size/2
	get_tree().current_scene.add_child(puddle_visual)
	return puddle_visual

func _setup_eternal_puddle(area: Area2D, base_damage: float):
	# Eternal puddles grow and stack damage
	var growth_timer = Timer.new()
	growth_timer.wait_time = 2.0
	growth_timer.timeout.connect(_grow_eternal_puddle.bind(area, base_damage))
	area.add_child(growth_timer)
	growth_timer.start()

func _grow_eternal_puddle(area: Area2D, base_damage: float):
	if not is_instance_valid(area):
		return

	# Increase size and damage
	var collision = area.get_child(0) as CollisionShape2D
	if collision and collision.shape:
		var shape = collision.shape as CircleShape2D
		shape.radius *= 1.1  # Grow by 10%

		# Increase damage
		var timer = area.get_child(1) as Timer
		if timer:
			timer.timeout.disconnect(_puddle_damage_tick)
			timer.timeout.connect(_puddle_damage_tick.bind(area, base_damage * 1.1))

func _puddle_damage_tick(area: Area2D, damage: float):
	if not is_instance_valid(area):
		return

	var enemies = area.get_overlapping_bodies()
	for enemy in enemies:
		if enemy.is_in_group("enemies") and enemy.has_method("take_damage"):
			enemy.take_damage(damage)

func create_poison_cloud(position: Vector2, damage: float, radius: float = 100.0):
	var cloud = _create_cloud_visual(position, radius)

	# Set up damage area
	var area = Area2D.new()
	area.global_position = position
	get_tree().current_scene.add_child(area)

	var collision = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = radius
	collision.shape = shape
	area.add_child(collision)

	# Poison application timer
	var timer = Timer.new()
	timer.wait_time = 1.0
	timer.timeout.connect(_poison_cloud_tick.bind(area, damage))
	area.add_child(timer)
	timer.start()

	# Cloud duration
	get_tree().create_timer(8.0).timeout.connect(func():
		if is_instance_valid(area):
			area.queue_free()
		if is_instance_valid(cloud):
			cloud.queue_free()
	)

func _create_cloud_visual(position: Vector2, radius: float) -> Node2D:
	var cloud_visual = ColorRect.new()
	cloud_visual.size = Vector2(radius * 2, radius * 2)
	cloud_visual.color = Color.GREEN
	cloud_visual.modulate.a = 0.3
	cloud_visual.global_position = position - cloud_visual.size/2
	get_tree().current_scene.add_child(cloud_visual)

	# Swirling animation
	var tween = create_tween()
	tween.set_loops()
	tween.tween_property(cloud_visual, "rotation", TAU, 3.0)

	return cloud_visual

func _poison_cloud_tick(area: Area2D, damage: float):
	if not is_instance_valid(area):
		return

	var enemies = area.get_overlapping_bodies()
	for enemy in enemies:
		if enemy.is_in_group("enemies") and enemy.has_method("apply_poison"):
			enemy.apply_poison(damage, 3.0)

func create_screen_shake(intensity: float, duration: float):
	# Enhanced screen shake implementation
	var camera = get_viewport().get_camera_2d()
	if not camera:
		return

	var original_pos = camera.global_position
	var shake_timer = 0.0
	var shake_tween = create_tween()

	while shake_timer < duration:
		var shake_offset = Vector2(
			randf_range(-intensity, intensity),
			randf_range(-intensity, intensity)
		)
		shake_tween.tween_property(camera, "global_position", original_pos + shake_offset, 1.0/60.0)
		shake_timer += 1.0/60.0

	shake_tween.tween_property(camera, "global_position", original_pos, 0.1)

func _create_splash_particles(origin: Vector2):
	# Simple particle effect for tsunami
	for i in range(20):
		var particle = ColorRect.new()
		particle.size = Vector2(10, 10)
		particle.color = Color.CYAN
		particle.global_position = origin
		get_tree().current_scene.add_child(particle)

		var direction = Vector2.RIGHT.rotated(randf() * TAU)
		var distance = randf_range(100, 300)

		var tween = create_tween()
		tween.tween_property(particle, "global_position", origin + direction * distance, 1.0)
		tween.parallel().tween_property(particle, "modulate:a", 0.0, 1.0)
		tween.tween_callback(particle.queue_free)

func _create_arena_particle_effects():
	# Ambient ketchup particles
	var particle_timer = Timer.new()
	particle_timer.wait_time = 0.5
	particle_timer.timeout.connect(_spawn_ambient_particles)
	add_child(particle_timer)
	particle_timer.start()

func _spawn_ambient_particles():
	var particle = ColorRect.new()
	particle.size = Vector2(5, 5)
	particle.color = Color.RED
	particle.global_position = Vector2(
		randf_range(-500, 500),
		randf_range(-500, 500)
	)
	get_tree().current_scene.add_child(particle)

	var tween = create_tween()
	tween.tween_property(particle, "global_position", particle.global_position + Vector2(0, 100), 3.0)
	tween.parallel().tween_property(particle, "modulate:a", 0.0, 3.0)
	tween.tween_callback(particle.queue_free)

# Utility functions
func cleanup_permanent_effects():
	"""Clean up all permanent effects when run ends"""
	for field in permanent_damage_fields:
		if is_instance_valid(field):
			field.queue_free()
	permanent_damage_fields.clear()

	for puddle in mega_puddles:
		if is_instance_valid(puddle):
			puddle.queue_free()
	mega_puddles.clear()

	active_transformations.clear()

func get_active_transformation_count() -> int:
	return active_transformations.size()

func is_transformation_active(bottle_id: String, transformation_type: String) -> bool:
	if active_transformations.has(bottle_id):
		return active_transformations[bottle_id].type == transformation_type
	return false
