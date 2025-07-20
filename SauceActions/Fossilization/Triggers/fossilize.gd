# SauceActions/Fossilization/Triggers/fossilize.gd
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

	# Read parameters from trigger effect resource
	var duration = data.effect_parameters.get("duration", 2.5)
	var amber_color = data.effect_parameters.get("amber_color", Color(1.0, 0.8, 0.3, 0.6))
	var max_stacks = data.effect_parameters.get("max_stacks", 1)
	var stack_value = data.effect_parameters.get("stack_value", 0.15)
	var tick_damage = data.effect_parameters.get("tick_damage", 8.0)  # Damage per tick per stack
	var tick_interval = data.effect_parameters.get("tick_interval", 1.0)  # Every 1 second

	# Create all effect callbacks
	var visual_cleanup = Callable()
	var mechanical_cleanup = Callable()
	var immediate_effect = Callable()
	var tick_effect = Callable()

	# Visual effects - only on first stack
	if enemy.has_method("get_total_stack_count") and enemy.get_total_stack_count("fossilize") == 0:
		var amber_shell = _create_amber_shell(enemy, amber_color)
		_create_fossilization_particles(enemy.global_position, amber_color)

		visual_cleanup = func():
			if is_instance_valid(amber_shell):
				amber_shell.queue_free()
			print("🔶 All fossilize stacks removed - amber shell destroyed")

	# Immediate effect - runs every time a stack is added
	immediate_effect = func():
		if not is_instance_valid(enemy):
			return

		var total_slow = enemy.get_total_stacked_value("fossilize")
		var slow_multiplier = 1.0 - total_slow
		enemy.move_speed = enemy.base_speed * max(slow_multiplier, 0.1)

		var current_stacks = enemy.get_total_stack_count("fossilize")
		print("🔶 Fossilize: %d stacks, %.0f%% speed reduction" % [current_stacks, total_slow * 100])

	# Tick effect - deals damage over time based on stacks
	tick_effect = func():
		if not is_instance_valid(enemy):
			return

		var total_stacks = enemy.get_total_stack_count("fossilize")
		var damage = tick_damage * total_stacks
		enemy.take_damage_from_source(damage, bottle.bottle_id)
		print("🔶 Fossilize tick: %.1f damage (%d stacks)" % [damage, total_stacks])

	# Mechanical cleanup - runs when individual stacks expire
	mechanical_cleanup = func():
		if not is_instance_valid(enemy):
			return

		var remaining_slow = enemy.get_total_stacked_value("fossilize")
		if remaining_slow > 0:
			var slow_multiplier = 1.0 - remaining_slow
			enemy.move_speed = enemy.original_speed * max(slow_multiplier, 0.1)
			print("🔶 Fossilize stack expired: %.0f%% speed reduction remaining" % (remaining_slow * 100))
		else:
			enemy.move_speed = enemy.original_speed
			print("🔶 All fossilize stacks expired - speed fully restored")

	# Apply stacking fossilize effect with DOT
	var stacks_applied = enemy.apply_stacking_effect(
		"fossilize",
		stack_value,
		max_stacks,
		bottle.bottle_id,
		duration,
		{
			"visual_cleanup": visual_cleanup,
			"mechanical_cleanup": mechanical_cleanup,
			"immediate_effect": immediate_effect,
			"tick_effect": tick_effect,
			"tick_interval": tick_interval
		}
	)

	# Log the application
	var total_slow_percent = enemy.get_total_stacked_value("fossilize") * 100
	print("🔶 Fossilize applied! Stack %d/%d (%.0f%% total slow)" % [
		stacks_applied,
		max_stacks,
		total_slow_percent
	])

func _create_amber_shell(enemy: Node2D, amber_color: Color) -> Node:
	"""Create amber shell overlay around the enemy"""
	var amber_shell = ColorRect.new()
	amber_shell.size = Vector2(32, 32)
	amber_shell.position = Vector2(-16, -16)
	amber_shell.color = amber_color
	amber_shell.mouse_filter = Control.MOUSE_FILTER_IGNORE
	amber_shell.scale = Vector2(1.2, 1.2)
	amber_shell.name = "AmberShell"

	# Add to enemy
	enemy.add_child(amber_shell)

	# Create pulsing animation
	var tween = amber_shell.create_tween()
	tween.set_loops()
	tween.tween_property(amber_shell, "modulate:a", 0.3, 0.5)
	tween.tween_property(amber_shell, "modulate:a", 0.8, 0.5)

	return amber_shell

func _create_fossilization_particles(position: Vector2, amber_color: Color):
	"""Create particle effects when fossilization occurs"""
	for i in range(8):
		var particle = ColorRect.new()
		particle.size = Vector2(4, 4)
		particle.color = amber_color
		particle.position = position + Vector2(randf_range(-16, 16), randf_range(-16, 16))

		# Add to scene
		var scene = Engine.get_main_loop().current_scene
		scene.add_child(particle)

		# Animate and auto-cleanup
		var tween = particle.create_tween()
		tween.parallel().tween_property(particle, "position", particle.position + Vector2(randf_range(-32, 32), randf_range(-32, 32)), 0.5)
		tween.parallel().tween_property(particle, "modulate:a", 0.0, 0.5)
		tween.tween_callback(particle.queue_free)
