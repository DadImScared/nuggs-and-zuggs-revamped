# Effects/BurnEffect.gd
class_name BurnEffect
extends Resource

# BASE PARAMETERS - Exportable for easy tuning in the editor
@export var base_duration: float = 3.0
@export var base_tick_interval: float = 0.5
@export var base_tick_damage: float = 5.0
@export var base_max_stacks: int = 8
@export var base_stack_value: float = 1.0
@export var base_burn_color: Color = Color(1.2, 0.6, 0.3, 0.8)

# TALENT MULTIPLIERS - Modified by talent system
static var duration_multiplier: float = 1.0
static var tick_interval_multiplier: float = 1.0
static var tick_damage_multiplier: float = 1.0
static var max_stacks_bonus: int = 0
static var stack_value_multiplier: float = 1.0

# GLOBAL INSTANCE - Set this in your game initialization
static var global_instance: BurnEffect = null

# Initialize the global instance (call this once at game start)
static func initialize():
	if not global_instance:
		global_instance = BurnEffect.new()
		DebugControl.debug_status("🔥 BurnEffect initialized with tunable parameters")

# Talent system calls these to buff ALL burns globally
static func apply_slow_burn():
	"""Slow Burn talent - affects ALL burns everywhere"""
	duration_multiplier *= 1.5
	tick_interval_multiplier *= 1.3
	DebugControl.debug_status("🔥 Slow Burn applied globally! All burns now last 50% longer")

static func apply_intense_heat():
	"""Intense Heat talent - affects ALL burns everywhere"""
	tick_damage_multiplier *= 2.0
	duration_multiplier *= 0.7
	DebugControl.debug_status("🔥 Intense Heat applied globally! All burns now deal double damage")

static func apply_infernal_stacks():
	"""Infernal Stacks talent - affects ALL burns everywhere"""
	max_stacks_bonus += 4
	DebugControl.debug_status("🔥 Infernal Stacks applied globally! All burns can now stack to %d" % get_final_max_stacks())

# Get final values after all talent buffs
static func get_final_duration() -> float:
	if not global_instance: initialize()
	return global_instance.base_duration * duration_multiplier

static func get_final_tick_interval() -> float:
	if not global_instance: initialize()
	return global_instance.base_tick_interval * tick_interval_multiplier

static func get_final_tick_damage() -> float:
	if not global_instance: initialize()
	return global_instance.base_tick_damage * tick_damage_multiplier

static func get_final_max_stacks() -> int:
	if not global_instance: initialize()
	return global_instance.base_max_stacks + max_stacks_bonus

static func get_final_stack_value() -> float:
	if not global_instance: initialize()
	return global_instance.base_stack_value * stack_value_multiplier

static func get_final_burn_color() -> Color:
	if not global_instance: initialize()
	return global_instance.base_burn_color

# Apply burn using current global parameters
static func apply_burn_to_enemy(enemy: Node2D, source_bottle: Node, stacks_to_apply: int = 1):
	"""Apply burn using current global burn parameters"""
	if not enemy or not is_instance_valid(enemy):
		return

	if not global_instance: initialize()

	# Use current global values (affected by all talents)
	var final_duration = get_final_duration()
	var final_tick_interval = get_final_tick_interval()
	var final_tick_damage = get_final_tick_damage()
	var final_max_stacks = get_final_max_stacks()
	var final_stack_value = get_final_stack_value()
	var burn_color = get_final_burn_color()

	# Create effect callbacks
	var visual_cleanup = _create_visual_cleanup(enemy)
	var immediate_effect = _create_immediate_effect(enemy, burn_color)
	var tick_effect = _create_tick_effect(enemy, final_tick_damage, burn_color, source_bottle)

	# Apply each stack using global parameters
	for i in range(stacks_to_apply):
		if enemy.has_method("apply_stacking_effect"):
			enemy.apply_stacking_effect(
				"burn",
				final_stack_value,
				final_max_stacks,
				source_bottle.bottle_id if source_bottle and source_bottle.has_method("bottle_id") else "burn",
				final_duration,  # Uses global duration (includes Slow Burn!)
				{
					"visual_cleanup": visual_cleanup,
					"immediate_effect": immediate_effect,
					"tick_effect": tick_effect,
					"tick_interval": final_tick_interval  # Uses global interval (includes Slow Burn!)
				}
			)

	DebugControl.debug_status("🔥 BurnEffect: Applied %d burn stacks (%.1fs duration, %.2fs interval, %.1f damage)" % [
		stacks_to_apply, final_duration, final_tick_interval, final_tick_damage
	])

# Helper methods to create callbacks
static func _create_visual_cleanup(enemy: Node2D) -> Callable:
	return func():
		var burn_overlay = enemy.get_node_or_null("BurnOverlay")
		if burn_overlay and is_instance_valid(burn_overlay):
			burn_overlay.queue_free()

static func _create_immediate_effect(enemy: Node2D, burn_color: Color) -> Callable:
	return func():
		if not is_instance_valid(enemy):
			return

		# Create visual on first stack
		if enemy.get_total_stack_count("burn") == 1:
			var fire_overlay = ColorRect.new()
			fire_overlay.size = Vector2(28, 28)
			fire_overlay.position = Vector2(-14, -14)
			fire_overlay.color = burn_color
			fire_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
			fire_overlay.name = "BurnOverlay"
			enemy.add_child(fire_overlay)

			var tween = fire_overlay.create_tween()
			tween.set_loops()
			tween.tween_property(fire_overlay, "modulate:a", 0.4, 0.3)
			tween.tween_property(fire_overlay, "modulate:a", 0.8, 0.3)

		# Update intensity based on stacks
		var burn_overlay = enemy.get_node_or_null("BurnOverlay")
		if burn_overlay:
			var stack_count = enemy.get_total_stack_count("burn")
			var intensity = min(1.0, 0.4 + (stack_count * 0.1))
			burn_overlay.modulate = Color(burn_color.r, burn_color.g, burn_color.b, intensity)
			var scale = 1.0 + (stack_count * 0.05)
			burn_overlay.scale = Vector2(scale, scale)

static func _create_tick_effect(enemy: Node2D, tick_damage: float, burn_color: Color, source_bottle: Node) -> Callable:
	return func():
		if not is_instance_valid(enemy):
			return

		var total_stacks = enemy.get_total_stack_count("burn")
		var damage = tick_damage * total_stacks
		var bottle_id = source_bottle.bottle_id if source_bottle and source_bottle.has_method("bottle_id") else "burn"
		enemy.take_damage_from_source(damage, bottle_id)

		DebugControl.debug_combat("🔥 Burn tick: %.1f damage (%d stacks)" % [damage, total_stacks])

		# Create tick particle
		var particle = ColorRect.new()
		particle.size = Vector2(6, 6)
		particle.color = burn_color
		particle.position = enemy.global_position + Vector2(randf_range(-8, 8), randf_range(-8, 8))

		var scene = Engine.get_main_loop().current_scene
		scene.add_child(particle)

		var tween = particle.create_tween()
		tween.parallel().tween_property(particle, "position", particle.position + Vector2(randf_range(-16, 16), -24), 0.8)
		tween.parallel().tween_property(particle, "modulate:a", 0.0, 0.8)
		tween.tween_callback(particle.queue_free)
