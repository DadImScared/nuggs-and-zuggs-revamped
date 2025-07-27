# SauceActions/Slow/Triggers/slow.gd
class_name SlowTrigger
extends BaseTriggerAction

func _init() -> void:
	trigger_name = "slow"
	trigger_description = "Apply stacking slow effect that reduces movement speed"

func execute_trigger(bottle: ImprovedBaseSauceBottle, data: EnhancedTriggerData):
	var enemy = data.effect_parameters.hit_enemy

	if not enemy or not is_instance_valid(enemy):
		return

	# Get slow parameters from trigger data
	var duration = data.effect_parameters.get("duration", 4.0)
	var max_stacks = data.effect_parameters.get("max_stacks", 5)
	var stack_value = data.effect_parameters.get("stack_value", 1.0)
	var slow_per_stack = data.effect_parameters.get("slow_per_stack", 0.2)  # 20% per stack
	var freeze_threshold = data.effect_parameters.get("freeze_threshold", 5)
	var slow_color = data.effect_parameters.get("slow_color", Color(0.7, 0.7, 1.0, 0.8))

	# Visual cleanup - runs when individual stacks expire
	var visual_cleanup = func():
		if not is_instance_valid(enemy):
			return

		var total_stacks = enemy.get_total_stack_count("slow")
		if total_stacks == 0:
			# Remove blue tint when all slow stacks are gone
			if enemy.animated_sprite:
				enemy.animated_sprite.modulate = Color.WHITE
			# Remove any ice effects
			var ice_effect = enemy.get_node_or_null("IceEffect")
			if ice_effect:
				ice_effect.queue_free()

	# Immediate effect - runs when stack is applied (calculates movement speed)
	var immediate_effect = func():
		if not is_instance_valid(enemy):
			return

		var total_stacks = enemy.get_total_stack_count("slow")
		var total_slow_value = enemy.get_total_stacked_value("slow")

		# Calculate movement speed reduction
		var slow_multiplier = 1.0 - (total_slow_value * slow_per_stack)

		# Check if frozen (at freeze threshold)
		if total_stacks >= freeze_threshold:
			enemy.move_speed = 0  # Completely frozen
			if enemy.animated_sprite:
				enemy.animated_sprite.modulate = Color(0.8, 0.8, 1.0)  # Light blue frozen tint
				enemy.animated_sprite.speed_scale = 0  # Stop animation
			_create_ice_effect(enemy)
			DebugControl.debug_status("🧊 Enemy frozen! (%d stacks)" % total_stacks)
		else:
			# Apply slow (ensure minimum speed)
			enemy.move_speed = enemy.original_speed * max(slow_multiplier, 0.1)
			if enemy.animated_sprite:
				enemy.animated_sprite.modulate = slow_color
				enemy.animated_sprite.speed_scale = max(slow_multiplier, 0.3)  # Slow animation
			DebugControl.debug_status("❄️ Enemy slowed: %.0f%% speed (%d stacks)" % [slow_multiplier * 100, total_stacks])

	# Mechanical cleanup - runs when individual stacks expire
	var mechanical_cleanup = func():
		if not is_instance_valid(enemy):
			return

		var remaining_stacks = enemy.get_total_stack_count("slow")
		var remaining_slow_value = enemy.get_total_stacked_value("slow")

		if remaining_stacks > 0:
			# Recalculate speed with remaining stacks
			var slow_multiplier = 1.0 - (remaining_slow_value * slow_per_stack)

			if remaining_stacks >= freeze_threshold:
				enemy.move_speed = 0  # Still frozen
			else:
				enemy.move_speed = enemy.original_speed * max(slow_multiplier, 0.1)
				# Unfreeze if below threshold
				if enemy.animated_sprite:
					enemy.animated_sprite.speed_scale = max(slow_multiplier, 0.3)
				var ice_effect = enemy.get_node_or_null("IceEffect")
				if ice_effect:
					ice_effect.queue_free()
		else:
			# All stacks gone, restore full speed
			enemy.move_speed = enemy.original_speed
			if enemy.animated_sprite:
				enemy.animated_sprite.speed_scale = 1.0

	# Apply stacking slow effect
	var stacks_applied = enemy.apply_stacking_effect(
		"slow",
		stack_value,
		max_stacks,
		bottle.bottle_id,
		duration,
		{
			"visual_cleanup": visual_cleanup,
			"mechanical_cleanup": mechanical_cleanup,
			"immediate_effect": immediate_effect,
			"tick_interval": 0.0  # No ticking - instant debuff only
		}
	)

	# Create visual effects
	_create_slow_particles(enemy.global_position, slow_color)

	DebugControl.debug_status("❄️ Slow applied! Stack %d/%d" % [stacks_applied, max_stacks])

func _create_ice_effect(enemy: Node2D):
	"""Create ice crystal effect around frozen enemy"""
	var existing_ice = enemy.get_node_or_null("IceEffect")
	if existing_ice:
		return  # Already has ice effect

	var ice_effect = ColorRect.new()
	ice_effect.size = Vector2(36, 36)
	ice_effect.position = Vector2(-18, -18)
	ice_effect.color = Color(0.8, 0.9, 1.0, 0.6)
	ice_effect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ice_effect.name = "IceEffect"

	# Add to enemy
	enemy.add_child(ice_effect)

	# Create sparkle animation
	var tween = ice_effect.create_tween()
	tween.set_loops()
	tween.tween_property(ice_effect, "modulate:a", 0.3, 0.8)
	tween.tween_property(ice_effect, "modulate:a", 0.8, 0.8)

func _create_slow_particles(position: Vector2, slow_color: Color):
	"""Create particle effects when slow is applied"""
	for i in range(6):
		var particle = ColorRect.new()
		particle.size = Vector2(3, 3)
		particle.color = slow_color
		particle.position = position + Vector2(randf_range(-12, 12), randf_range(-12, 12))

		# Add to scene
		var scene = Engine.get_main_loop().current_scene
		if scene:
			scene.add_child(particle)

			# Animate and auto-cleanup
			var tween = particle.create_tween()
			tween.parallel().tween_property(particle, "position", particle.position + Vector2(randf_range(-20, 20), randf_range(-20, 20)), 0.8)
			tween.parallel().tween_property(particle, "modulate:a", 0.0, 0.8)
			tween.tween_callback(particle.queue_free)
