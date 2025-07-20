class_name FossilizeTrigger
extends BaseTriggerAction

func _init() -> void:
	trigger_name = "fossilize"
	trigger_description = "15% chance to fossilize enemies in amber on hit"

func execute_trigger(bottle: ImprovedBaseSauceBottle, data: EnhancedTriggerData):
	var enemy = data.effect_parameters.hit_enemy
	var projectile = data.effect_parameters.get("projectile", null)

	if not enemy or not is_instance_valid(enemy):
		print("⚠️ Fossilize: No valid enemy to fossilize")
		return

	# Create fossilize callback
	var my_callback = func(context: StatusEffectApplier.EffectContext):
		var cb_enemy = context.enemy
		var original_speed = cb_enemy.move_speed
		var original_color = cb_enemy.modulate
		var amber_color = Color(1.0, 0.8, 0.3, 0.6)
		cb_enemy.modulate = amber_color

		# Apply effect
		cb_enemy.move_speed *= 0.1

		var amber_shell = _create_amber_shell(cb_enemy, amber_color, context.duration)

		# Create fossilization particles
		_create_fossilization_effects(cb_enemy.global_position, amber_color)

		# Create cleanup
		var cleanup = func():
			if is_instance_valid(cb_enemy):
				cb_enemy.move_speed = original_speed
				cb_enemy.modulate = original_color
			if is_instance_valid(amber_shell):
				amber_shell.queue_free()
				print("🔶 Removed amber shell")

		# Create status effect with cleanup
		print(cb_enemy.name, " cb -enemy ---------------------")
		cb_enemy.apply_status_effect("fossilize", context.duration, context.intensity, context.get_bottle_id(), cleanup)

	# Apply the fossilize effect using the callback system
	SauceEffectManager.apply_custom_effect(
		projectile,
		enemy,
		bottle,
		my_callback,
		bottle.effective_effect_intensity,  # custom intensity
		bottle.sauce_data.effect_duration   # custom duration
	)

# Keep all your existing helper functions unchanged
func _create_amber_effect(enemy: Node2D, amber_color: Color, duration: float):
	"""Create the amber coating visual effect"""
	if not enemy.has_method("get_sprite"):
		return

	var sprite = enemy.get_sprite()
	if not sprite:
		return

	# Store original modulate to restore later
	var original_modulate = sprite.modulate
	enemy.set_meta("original_modulate", original_modulate)

	# Apply amber tint
	sprite.modulate = amber_color

	# Create amber shell effect
	_create_amber_shell(enemy, amber_color, duration)

	# Set up timer to remove effect
	_setup_amber_removal_timer(enemy, sprite, original_modulate, duration)

func _create_amber_shell(enemy: Node2D, amber_color: Color, duration: float):
	"""Create an amber shell overlay around the enemy"""
	var amber_shell = ColorRect.new()
	amber_shell.size = Vector2(32, 32)
	amber_shell.position = Vector2(-16, -16)
	amber_shell.color = amber_color
	amber_shell.mouse_filter = Control.MOUSE_FILTER_IGNORE
	amber_shell.scale = Vector2(1.2, 1.2)

	enemy.add_child(amber_shell)
	amber_shell.name = "AmberShell"

	# Add pulsing effect
	var tween = amber_shell.create_tween()
	tween.set_loops()
	tween.tween_property(amber_shell, "modulate:a", 0.3, 0.5)
	tween.tween_property(amber_shell, "modulate:a", 0.8, 0.5)

func _setup_amber_removal_timer(enemy: Node2D, sprite: Node2D, original_modulate: Color, duration: float):
	"""Set up timer to remove amber effect after duration"""
	var timer = Timer.new()
	timer.wait_time = duration
	timer.one_shot = true

	timer.set_meta("target_enemy", enemy)
	timer.set_meta("target_sprite", sprite)
	timer.set_meta("original_modulate", original_modulate)

	timer.timeout.connect(_on_amber_timer_timeout.bind(timer))

	enemy.add_child(timer)
	timer.start()

func _on_amber_timer_timeout(timer: Timer):
	"""Clean up amber effect when timer expires"""
	if not is_instance_valid(timer):
		return

	var enemy = timer.get_meta("target_enemy", null)
	var sprite = timer.get_meta("target_sprite", null)
	var original_modulate = timer.get_meta("original_modulate", Color.WHITE)

	# Restore original appearance
	if is_instance_valid(sprite):
		sprite.modulate = original_modulate

	# Remove amber shell
	if is_instance_valid(enemy):
		var amber_shell = enemy.get_node_or_null("AmberShell")
		if amber_shell:
			amber_shell.queue_free()

	timer.queue_free()
	print("🔶 Amber effect removed")

func _create_fossilization_effects(position: Vector2, amber_color: Color):
	"""Create particle effects for fossilization"""
	for i in range(8):
		var particle = ColorRect.new()
		particle.size = Vector2(4, 4)
		particle.color = amber_color
		particle.position = position + Vector2(randf_range(-16, 16), randf_range(-16, 16))

		var scene = Engine.get_main_loop().current_scene
		scene.add_child(particle)

		var tween = particle.create_tween()
		tween.parallel().tween_property(particle, "position", particle.position + Vector2(randf_range(-32, 32), randf_range(-32, 32)), 0.5)
		tween.parallel().tween_property(particle, "modulate:a", 0.0, 0.5)
		tween.tween_callback(particle.queue_free)
