extends Node

func create_chain_visual(start_pos: Vector2, end_pos: Vector2, color: Color):
	var line = Line2D.new()
	line.add_point(start_pos)
	line.add_point(end_pos)
	line.width = 3.0
	line.default_color = color
	line.default_color.a = 0.8

	var scene = get_tree().current_scene
	scene.add_child(line)

	var tween = scene.create_tween()
	tween.tween_property(line, "modulate:a", 0.0, 0.2)
	tween.tween_callback(line.queue_free)

func create_explosion_visual(position: Vector2, radius: float, color: Color):
	# Create a TextureRect with a circle texture
	var explosion_circle = TextureRect.new()

	# Create a circle texture programmatically
	var image = Image.create(int(radius * 2), int(radius * 2), false, Image.FORMAT_RGBA8)
	var center = Vector2(radius, radius)

	for x in range(int(radius * 2)):
		for y in range(int(radius * 2)):
			var distance = Vector2(x, y).distance_to(center)
			if distance <= radius:
				var alpha = 1.0 - (distance / radius)  # Fade from center
				image.set_pixel(x, y, Color(1.0, 0.5, 0.0, alpha * 0.3))

	var texture = ImageTexture.new()
	texture.set_image(image)
	explosion_circle.texture = texture
	explosion_circle.position = position - Vector2(radius, radius)

	get_tree().current_scene.add_child(explosion_circle)

	var tween = get_tree().create_tween()
	tween.tween_property(explosion_circle, "modulate:a", 0.0, 0.3)
	tween.tween_callback(explosion_circle.queue_free)

func create_quantum_collapse_effect(projectile: Area2D):
	# Create a visual effect for the quantum collapse
	for i in range(10):
		var particle = Sprite2D.new()
		particle.texture = projectile.sprite.texture
		particle.scale = projectile.sprite.scale * 0.3
		particle.modulate = projectile.modulate
		particle.modulate.a = 0.6
		particle.position = Vector2.ZERO
		projectile.add_child(particle)

		# Animate the particle
		var direction = Vector2.from_angle(randf() * TAU)
		var distance = randf_range(20, 60)
		var duration = randf_range(0.3, 0.5)

		var tween = projectile.create_tween()
		tween.parallel().tween_property(particle, "position", direction * distance, duration)
		tween.parallel().tween_property(particle, "modulate:a", 0.0, duration)
		tween.parallel().tween_property(particle, "scale", Vector2.ZERO, duration)
		tween.tween_callback(particle.queue_free)

func create_quantum_hit_effect(hit_position: Vector2, color: Color):
	# Create a small quantum ripple at hit position
	var effect = ColorRect.new()
	effect.size = Vector2(20, 20)
	effect.position = hit_position - Vector2(10, 10)
	effect.color = color
	effect.color.a = 0.5

	get_tree().current_scene.add_child(effect)

	var tween = get_tree().create_tween()
	tween.parallel().tween_property(effect, "scale", Vector2(2, 2), 0.3)
	tween.parallel().tween_property(effect, "modulate:a", 0.0, 0.3)
	tween.tween_callback(effect.queue_free)

func create_tornado(position: Vector2, duration: float, intensity: float, damage: float, sauce_color: Color):
	# Create the tornado node
	var tornado = Area2D.new()
	tornado.global_position = position
	tornado.collision_layer = 0
	tornado.collision_mask = 2  # Same as projectiles - detect enemies

	# Add collision shape
	var collision = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = 12.0 * intensity  # Small tornado
	collision.shape = shape
	tornado.add_child(collision)

	# Add visual effect
	var visual = create_tornado_visual(intensity, sauce_color)
	tornado.add_child(visual)

	# Set up the tornado behavior
	tornado.set_script(preload("res://Scenes/tornado_effect.gd"))
	tornado.setup(duration, intensity, damage)  # 30% of projectile damage per pull

	# Defer adding to scene to avoid physics conflicts
	call_deferred("_add_tornado_to_scene", tornado, duration)

func _add_tornado_to_scene(tornado: Area2D, duration: float):
	# Add to scene
	get_tree().current_scene.add_child(tornado)

	# Clean up after duration
	get_tree().create_timer(duration).timeout.connect(
		func():
			if is_instance_valid(tornado):
				tornado.queue_free()
	)

func create_tornado_visual(intensity: float, sauce_color: Color) -> Node2D:
	var visual_container = Node2D.new()

	for i in range(12):
		var line = Line2D.new()
		line.width = 4.0
		line.default_color = sauce_color
		line.default_color.a = 0.6

		var angle_offset = i * PI / 6.0
		var radius = 12.0 * intensity
		for j in range(8):
			var angle = angle_offset + j * 0.6
			var point_radius = radius * (1.0 - j / 8.0)
			var point = Vector2(cos(angle) * point_radius, sin(angle) * point_radius)
			line.add_point(point)

		visual_container.add_child(line)

		var tween = line.create_tween()
		tween.set_loops()
		tween.tween_method(line.set_rotation, 0.0, TAU, 0.5)

	var center_circle = Line2D.new()
	center_circle.width = 3.0
	center_circle.default_color = sauce_color
	for i in range(17):
		var angle = i * TAU / 16.0
		center_circle.add_point(Vector2(cos(angle) * 5, sin(angle) * 5))
	visual_container.add_child(center_circle)

	return visual_container
