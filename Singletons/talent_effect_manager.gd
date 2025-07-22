# Singletons/talent_effect_manager.gd
# Add to AutoLoad as TalentEffectManager

extends Node

# Global effect tracking
var permanent_damage_fields: Array[Node2D] = []
var mega_puddles: Array[Node2D] = []
var active_transformations: Dictionary = {}

func create_mini_volcano(position: Vector2, damage: float, radius: float, source_bottle_id: String):
	"""Create a smaller volcanic ring at the bottle's position"""
	var mini_ring = preload("res://Effects/MiniVolcanoRing/volcanic_ring.tscn").instantiate()
	mini_ring.global_position = position
	mini_ring.setup_ring(damage, radius, 2.0, source_bottle_id)  # 2 second duration
	mini_ring.modulate = Color(1.0, 0.8, 0.2, 0.9)  # Smaller, more yellow tint
	mini_ring.scale = Vector2(0.7, 0.7)  # Make it visually smaller
	get_tree().current_scene.add_child(mini_ring)

func create_tsunami_wave(origin: Vector2, damage: float):
	"""Create massive tsunami wave effect"""
	#print("🌊 CREATING TSUNAMI WAVE! 🌊")

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
	"""Create expanding wave visual"""
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
	"""Transform arena with permanent effects"""
	#print("🔥 ARENA TRANSFORMATION ACTIVATED! 🔥")

	# Change arena background/theme
	var arena = get_tree().get_first_node_in_group("arena")
	if arena and arena.has_method("transform_to_ketchup_arena"):
		arena.transform_to_ketchup_arena()

	# Create permanent damage field
	create_permanent_damage_field(source_bottle.sauce_data.damage * 0.1)

	# Visual transformation
	_transform_arena_visuals()

func transform_arena_to_ketchup_hell(source_bottle: ImprovedBaseSauceBottle):
	"""Transform arena to tomato apocalypse"""
	#print("💀 TOMATO APOCALYPSE! THE END TIMES! 💀")

	# All puddles become permanent and stack
	active_transformations[source_bottle.bottle_id] = {
		"type": "eternal_flood",
		"puddle_stacks": {}
	}

func create_damage_puddle(position: Vector2, damage: float, duration: float = 5.0, eternal: bool = false):
	"""Create damage puddle with safe timer handling"""
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

	# Damage timer with metadata - SAFE approach
	var timer = Timer.new()
	timer.wait_time = 0.5
	timer.set_meta("target_area", area)
	timer.set_meta("damage_amount", damage)
	timer.timeout.connect(_on_puddle_damage_timer.bind(timer))
	area.add_child(timer)
	timer.start()

	# Handle eternal puddles
	if eternal:
		mega_puddles.append(area)
		_setup_eternal_puddle(area, damage)
	else:
		# Normal puddle cleanup with safe timer
		var cleanup_timer = get_tree().create_timer(duration)
		cleanup_timer.timeout.connect(_cleanup_puddle.bind(area, puddle))

func _on_puddle_damage_timer(timer: Timer):
	"""Handle puddle damage timer safely"""
	if not is_instance_valid(timer):
		return

	var area = timer.get_meta("target_area", null)
	var damage = timer.get_meta("damage_amount", 0.0)

	_puddle_damage_tick(area, damage)

func _cleanup_puddle(area: Area2D, puddle: Node2D):
	"""Clean up puddle safely"""
	if is_instance_valid(area):
		area.queue_free()
	if is_instance_valid(puddle):
		puddle.queue_free()

func _create_puddle_visual(position: Vector2) -> Node2D:
	"""Create visual puddle effect"""
	var puddle_visual = ColorRect.new()
	puddle_visual.size = Vector2(100, 100)
	puddle_visual.color = Color.RED
	puddle_visual.modulate.a = 0.6
	puddle_visual.global_position = position - puddle_visual.size/2
	get_tree().current_scene.add_child(puddle_visual)
	return puddle_visual

func _setup_eternal_puddle(area: Area2D, base_damage: float):
	"""Eternal puddles grow and stack damage - FIXED signal binding"""
	var growth_timer = Timer.new()
	growth_timer.wait_time = 2.0

	# Store data in metadata instead of binding parameters
	growth_timer.set_meta("target_area", area)
	growth_timer.set_meta("base_damage", base_damage)

	# Simple signal connection
	growth_timer.timeout.connect(_on_eternal_puddle_timer.bind(growth_timer))
	area.add_child(growth_timer)
	growth_timer.start()

func _on_eternal_puddle_timer(timer: Timer):
	"""Handle eternal puddle growth timer safely"""
	if not is_instance_valid(timer):
		return

	var area = timer.get_meta("target_area", null)
	var base_damage = timer.get_meta("base_damage", 0.0)

	_grow_eternal_puddle(area, base_damage)

func _grow_eternal_puddle(area: Area2D, base_damage: float):
	"""Grow eternal puddle safely"""
	if not is_instance_valid(area):
		return

	# Increase size and damage
	var collision = area.get_child(0) as CollisionShape2D
	if collision and collision.shape:
		var shape = collision.shape as CircleShape2D
		shape.radius *= 1.1  # Grow by 10%

		# Update damage timer safely
		var damage_timer = area.get_child(1) as Timer
		if damage_timer:
			# Update metadata instead of reconnecting signal
			damage_timer.set_meta("damage_amount", base_damage * 1.1)

func _puddle_damage_tick(area: Area2D, damage: float):
	"""Handle puddle damage tick"""
	if not is_instance_valid(area):
		return

	var enemies = area.get_overlapping_bodies()
	for enemy in enemies:
		if enemy.is_in_group("enemies") and enemy.has_method("take_damage"):
			enemy.take_damage(damage)

func create_poison_cloud(position: Vector2, damage: float, radius: float = 100.0):
	"""Create poison cloud with safe timer handling"""
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

	# Poison application timer with metadata
	var timer = Timer.new()
	timer.wait_time = 1.0
	timer.set_meta("target_area", area)
	timer.set_meta("damage_amount", damage)
	timer.timeout.connect(_on_poison_cloud_timer.bind(timer))
	area.add_child(timer)
	timer.start()

	# Cloud duration with safe cleanup
	var cleanup_timer = get_tree().create_timer(8.0)
	cleanup_timer.timeout.connect(_cleanup_poison_cloud.bind(area, cloud))

func _on_poison_cloud_timer(timer: Timer):
	"""Handle poison cloud timer safely"""
	if not is_instance_valid(timer):
		return

	var area = timer.get_meta("target_area", null)
	var damage = timer.get_meta("damage_amount", 0.0)

	_poison_cloud_tick(area, damage)

func _cleanup_poison_cloud(area: Area2D, cloud: Node2D):
	"""Clean up poison cloud safely"""
	if is_instance_valid(area):
		area.queue_free()
	if is_instance_valid(cloud):
		cloud.queue_free()

func _create_cloud_visual(position: Vector2, radius: float) -> Node2D:
	"""Create visual cloud effect"""
	var cloud_visual = ColorRect.new()
	cloud_visual.size = Vector2(radius * 2, radius * 2)
	cloud_visual.color = Color(0.5, 1.0, 0.5, 0.4)
	cloud_visual.global_position = position - cloud_visual.size/2
	get_tree().current_scene.add_child(cloud_visual)

	# Add swirling animation
	var tween = cloud_visual.create_tween()
	tween.set_loops()
	tween.tween_property(cloud_visual, "rotation", TAU, 4.0)

	return cloud_visual

func _poison_cloud_tick(area: Area2D, damage: float):
	"""Handle poison cloud damage tick"""
	if not is_instance_valid(area):
		return

	var enemies = area.get_overlapping_bodies()
	for enemy in enemies:
		if enemy.is_in_group("enemies") and enemy.has_method("apply_status_effect"):
			enemy.apply_status_effect("poison", 3.0, damage * 0.5)

func create_permanent_damage_field(damage_per_second: float):
	"""Create permanent damage field covering entire arena"""
	var field_area = Area2D.new()
	field_area.global_position = Vector2.ZERO
	get_tree().current_scene.add_child(field_area)

	# Large collision covering entire screen
	var collision = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(2000, 2000)
	collision.shape = shape
	field_area.add_child(collision)

	# Damage timer with metadata
	var timer = Timer.new()
	timer.wait_time = 1.0
	timer.set_meta("target_area", field_area)
	timer.set_meta("damage_amount", damage_per_second)
	timer.timeout.connect(_on_permanent_field_timer.bind(timer))
	field_area.add_child(timer)
	timer.start()

	permanent_damage_fields.append(field_area)
	#print("🔥 Permanent damage field created: %.1f DPS" % damage_per_second)

func _on_permanent_field_timer(timer: Timer):
	"""Handle permanent field damage timer safely"""
	if not is_instance_valid(timer):
		return

	var area = timer.get_meta("target_area", null)
	var damage = timer.get_meta("damage_amount", 0.0)

	_permanent_field_damage_tick(area, damage)

func _permanent_field_damage_tick(area: Area2D, damage: float):
	"""Handle permanent field damage tick"""
	if not is_instance_valid(area):
		return

	var enemies = area.get_overlapping_bodies()
	for enemy in enemies:
		if enemy.is_in_group("enemies") and enemy.has_method("take_damage"):
			enemy.take_damage(damage)

func create_screen_shake(intensity: float, duration: float):
	"""Create screen shake effect"""
	var camera = get_tree().get_first_node_in_group("camera")
	if not camera:
		return

	var shake_timer = Timer.new()
	shake_timer.wait_time = 0.05
	shake_timer.set_meta("shake_intensity", intensity)
	shake_timer.set_meta("remaining_time", duration)
	shake_timer.set_meta("target_camera", camera)
	shake_timer.set_meta("original_position", camera.global_position)
	shake_timer.timeout.connect(_on_shake_timer.bind(shake_timer))
	camera.add_child(shake_timer)
	shake_timer.start()

func _on_shake_timer(timer: Timer):
	"""Handle screen shake timer safely"""
	if not is_instance_valid(timer):
		return

	var camera = timer.get_meta("target_camera", null)
	var intensity = timer.get_meta("shake_intensity", 0.0)
	var remaining_time = timer.get_meta("remaining_time", 0.0)
	var original_pos = timer.get_meta("original_position", Vector2.ZERO)

	if not is_instance_valid(camera):
		timer.queue_free()
		return

	remaining_time -= timer.wait_time
	timer.set_meta("remaining_time", remaining_time)

	if remaining_time <= 0:
		camera.global_position = original_pos
		timer.queue_free()
		return

	# Apply shake
	var shake_offset = Vector2(
		randf_range(-intensity, intensity),
		randf_range(-intensity, intensity)
	)
	camera.global_position = original_pos + shake_offset

func _create_splash_particles(position: Vector2):
	"""Create splash particle effects"""
	for i in range(10):
		var particle = ColorRect.new()
		particle.size = Vector2(4, 4)
		particle.color = Color.BLUE
		particle.global_position = position + Vector2(randf_range(-20, 20), randf_range(-20, 20))
		get_tree().current_scene.add_child(particle)

		# Animate particle
		var tween = particle.create_tween()
		var random_direction = Vector2(randf_range(-100, 100), randf_range(-100, 100))
		tween.parallel().tween_property(particle, "global_position", position + random_direction, 1.0)
		tween.parallel().tween_property(particle, "modulate:a", 0.0, 1.0)
		tween.tween_callback(particle.queue_free)

func _transform_arena_visuals():
	"""Apply visual transformation to arena"""
	var arena = get_tree().get_first_node_in_group("arena")
	if arena:
		var tween = arena.create_tween()
		tween.tween_property(arena, "modulate", Color.RED, 2.0)

# Debug and utility functions
func cleanup_all_effects():
	"""Clean up all temporary effects"""
	for field in permanent_damage_fields:
		if is_instance_valid(field):
			field.queue_free()
	permanent_damage_fields.clear()

	for puddle in mega_puddles:
		if is_instance_valid(puddle):
			puddle.queue_free()
	mega_puddles.clear()

	active_transformations.clear()
	#print("🧹 All talent effects cleaned up")

func get_active_effects_count() -> Dictionary:
	"""Get count of active effects for debugging"""
	return {
		"permanent_fields": permanent_damage_fields.size(),
		"mega_puddles": mega_puddles.size(),
		"transformations": active_transformations.size()
	}

func get_enemies_in_radius_for_infection(position: Vector2, radius: float, source_bottle: ImprovedBaseSauceBottle) -> Array:
	"""Get enemies in radius specifically for infection spreading - automatically applies Enhanced Transmission"""
	var enhanced_radius = radius

	# Check for Enhanced Transmission talent on the source bottle
	if source_bottle and source_bottle.special_effects:
		for effect in source_bottle.special_effects:
			if effect.effect_name == "enhanced_transmission":
				var radius_multiplier = effect.get_parameter("radius_multiplier", 1.5)
				enhanced_radius = radius * radius_multiplier
				#print("🦠 Enhanced Transmission: Infection spread radius %.0f → %.0f" % [radius, enhanced_radius])
				break

	# Find all enemies in the enhanced radius
	var enemies_in_radius = []
	var all_enemies = get_tree().get_nodes_in_group("enemies")

	for enemy in all_enemies:
		if is_instance_valid(enemy) and position.distance_to(enemy.global_position) <= enhanced_radius:
			enemies_in_radius.append(enemy)

	return enemies_in_radius
