# SauceActions/Burn/Triggers/base_burn.gd
class_name BaseBurnTrigger
extends BaseTriggerAction

# Burn constants
const DEFAULT_BURN_COLOR = Color(1.2, 0.6, 0.3, 0.8)  # Orange-red fire color
const DEFAULT_BURN_DURATION = 3.0
const DEFAULT_STACK_VALUE = 1.0  # Base burn intensity per stack
const DEFAULT_TICK_DAMAGE = 5.0  # Damage per stack per tick
const DEFAULT_TICK_INTERVAL = 0.5  # Burn ticks every 0.5 seconds
const DEFAULT_MAX_STACKS = 8  # Hot sauce can stack up to 8 burns

func _init() -> void:
	trigger_name = "burn"
	trigger_description = "Applies burning damage over time that stacks"

func execute_trigger(bottle: ImprovedBaseSauceBottle, data: EnhancedTriggerData):
	var enemy = data.effect_parameters.hit_enemy

	if not enemy or not is_instance_valid(enemy):
		DebugControl.debug_status("⚠️ Burn: No valid enemy to burn")
		return

	# Read parameters from trigger effect resource
	var duration = data.effect_parameters.get("duration", DEFAULT_BURN_DURATION)
	var burn_color = data.effect_parameters.get("burn_color", DEFAULT_BURN_COLOR)
	var max_stacks = data.effect_parameters.get("max_stacks", DEFAULT_MAX_STACKS)
	var stack_value = data.effect_parameters.get("stack_value", DEFAULT_STACK_VALUE)
	var tick_damage = data.effect_parameters.get("tick_damage", DEFAULT_TICK_DAMAGE)
	var tick_interval = data.effect_parameters.get("tick_interval", DEFAULT_TICK_INTERVAL)

	# Create all effect callbacks
	var visual_cleanup = Callable()
	var mechanical_cleanup = Callable()
	var immediate_effect = Callable()
	var tick_effect = Callable()

	# Visual effects - only on first stack
	if enemy.has_method("get_total_stack_count") and enemy.get_total_stack_count("burn") == 0:
		_create_burn_visual_effects(enemy, burn_color)

		visual_cleanup = func():
			_remove_burn_visual_effects(enemy)
			DebugControl.debug_status("🔥 All burn stacks removed - fire effects extinguished")

	# Immediate effect - runs every time a burn stack is added
	immediate_effect = func():
		if not is_instance_valid(enemy):
			return

		var current_stacks = enemy.get_total_stack_count("burn")
		var total_burn_intensity = enemy.get_total_stacked_value("burn")

		# Update burn visual intensity based on stacks
		_update_burn_intensity(enemy, current_stacks, burn_color)

		DebugControl.debug_status("🔥 Burn applied: %d stacks (%.1f total intensity)" % [current_stacks, total_burn_intensity])

	# Tick effect - deals damage over time based on total stacks
	tick_effect = func():
		if not is_instance_valid(enemy):
			return

		var total_stacks = enemy.get_total_stack_count("burn")
		var damage = tick_damage * total_stacks
		enemy.take_damage_from_source(damage, bottle.bottle_id)

		# Create small fire particle on tick
		_create_burn_tick_particle(enemy.global_position, burn_color)

		DebugControl.debug_combat("🔥 Burn tick: %.1f damage (%d stacks)" % [damage, total_stacks])

	# Mechanical cleanup - runs when individual stacks expire
	mechanical_cleanup = func():
		if not is_instance_valid(enemy):
			return

		var remaining_stacks = enemy.get_total_stack_count("burn")
		if remaining_stacks > 0:
			_update_burn_intensity(enemy, remaining_stacks, burn_color)
			DebugControl.debug_status("🔥 Burn stack expired: %d stacks remaining" % remaining_stacks)
		else:
			DebugControl.debug_status("🔥 All burn stacks expired - enemy no longer burning")

	# Apply stacking burn effect
	var stacks_applied = enemy.apply_stacking_effect(
		"burn",
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

	# Log successful application
	var total_stacks = enemy.get_total_stack_count("burn")
	DebugControl.debug_status("🔥 Burn applied! Stack %d/%d (%d total stacks)" % [
		stacks_applied,
		max_stacks,
		total_stacks
	])

func _create_burn_visual_effects(enemy: Node2D, burn_color: Color):
	"""Create initial burn visual effects"""
	# Create fire overlay
	var fire_overlay = ColorRect.new()
	fire_overlay.size = Vector2(28, 28)
	fire_overlay.position = Vector2(-14, -14)
	fire_overlay.color = burn_color
	fire_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fire_overlay.name = "BurnOverlay"

	# Add to enemy
	enemy.add_child(fire_overlay)

	# Create flickering animation
	var tween = fire_overlay.create_tween()
	tween.set_loops()
	tween.tween_property(fire_overlay, "modulate:a", 0.4, 0.3)
	tween.tween_property(fire_overlay, "modulate:a", 0.8, 0.3)

func _update_burn_intensity(enemy: Node2D, stack_count: int, burn_color: Color):
	"""Update burn visual intensity based on stack count"""
	var burn_overlay = enemy.get_node_or_null("BurnOverlay")
	if burn_overlay:
		# Increase intensity with more stacks
		var intensity = min(1.0, 0.4 + (stack_count * 0.1))
		burn_overlay.modulate = Color(burn_color.r, burn_color.g, burn_color.b, intensity)

		# Scale slightly with stacks for visual feedback
		var scale = 1.0 + (stack_count * 0.05)
		burn_overlay.scale = Vector2(scale, scale)

func _remove_burn_visual_effects(enemy: Node2D):
	"""Remove all burn visual effects"""
	var burn_overlay = enemy.get_node_or_null("BurnOverlay")
	if burn_overlay and is_instance_valid(burn_overlay):
		burn_overlay.queue_free()

func _create_burn_tick_particle(position: Vector2, burn_color: Color):
	"""Create small fire particle when burn ticks"""
	var particle = ColorRect.new()
	particle.size = Vector2(6, 6)
	particle.color = burn_color
	particle.position = position + Vector2(randf_range(-8, 8), randf_range(-8, 8))

	# Add to scene
	var scene = Engine.get_main_loop().current_scene
	scene.add_child(particle)

	# Animate upward and fade out
	var tween = particle.create_tween()
	tween.parallel().tween_property(particle, "position", particle.position + Vector2(randf_range(-16, 16), -24), 0.8)
	tween.parallel().tween_property(particle, "modulate:a", 0.0, 0.8)
	tween.tween_callback(particle.queue_free)
