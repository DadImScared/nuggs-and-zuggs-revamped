# Effects/stacking_effect.gd
class_name StackingEffect
extends Resource

# Stacking effect properties
@export var effect_name: String = ""
@export var base_duration: float = 5.0
@export var base_tick_interval: float = 0.5
@export var base_tick_damage: float = 5.0
@export var base_max_stacks: int = 8
@export var base_stack_value: float = 1.0
@export var base_color: Color = Color.RED

# NEW: Talent-aware application function
func apply_from_talent(
	enemy: Node2D,
	source_bottle: Node,
	stack_count: int = 1,
	override_params: Dictionary = {}
):
	"""
	Apply this effect through the talent system to get all enhancements.
	Finds the matching trigger on the bottle and executes it with all talent bonuses.

	Args:
		enemy: Target to apply effect to
		source_bottle: Source bottle (needed for talent enhancements)
		stack_count: Number of stacks to apply
		override_params: Optional parameters to override (duration_multiplier, etc.)
	"""
	if not enemy or not is_instance_valid(enemy) or not source_bottle:
		DebugControl.debug_status("⚠️ %s.apply_from_talent: Invalid parameters" % effect_name)
		return

	# Find matching trigger on the source bottle
	var matching_trigger = null
	for trigger in source_bottle.trigger_effects:
		if trigger.trigger_name == effect_name:
			matching_trigger = trigger
			break

	if not matching_trigger:
		DebugControl.debug_status("⚠️ %s.apply_from_talent: No %s trigger found on bottle" % [effect_name, effect_name])
		# Fallback to direct application
		apply_to_enemy(enemy, source_bottle, stack_count)
		return

	# Execute trigger with all talent enhancements
	if effect_name in TriggerActionManager.trigger_actions:
		var action = TriggerActionManager.trigger_actions[effect_name]
		var enhanced_data = action.apply_enhancements(source_bottle, matching_trigger)

		# Add effect context
		enhanced_data.effect_parameters["hit_enemy"] = enemy
		enhanced_data.effect_parameters[effect_name + "_stacks"] = stack_count

		# Apply any override parameters (for custom effects)
		for key in override_params:
			enhanced_data.effect_parameters[key] = override_params[key]

		# Execute the enhanced trigger
		action.execute_trigger(source_bottle, enhanced_data)

		DebugControl.debug_status("✨ %s.apply_from_talent: Applied %d %s stacks with talents" % [effect_name, stack_count, effect_name])
		return
	else:
		DebugControl.debug_status("⚠️ %s.apply_from_talent: %s action not found in TriggerActionManager" % [effect_name, effect_name])
		# Fallback to direct application
		apply_to_enemy(enemy, source_bottle, stack_count)

# Existing methods
func get_duration() -> float:
	return base_duration

func get_tick_interval() -> float:
	return base_tick_interval

func get_tick_damage() -> float:
	return base_tick_damage

func get_max_stacks() -> int:
	return base_max_stacks

func get_stack_value() -> float:
	return base_stack_value

func get_color() -> Color:
	return base_color

func apply_to_enemy(enemy: Node2D, source_bottle: Node, stacks_to_apply: int = 1):
	"""Direct application method (legacy/fallback)"""
	if not enemy or not is_instance_valid(enemy):
		return

	# Create effect callbacks
	var visual_cleanup = _create_visual_cleanup(enemy)
	var immediate_effect = _create_immediate_effect(enemy)
	var tick_effect = _create_tick_effect(enemy, source_bottle)

	# Apply stacks
	for i in range(stacks_to_apply):
		if enemy.has_method("apply_stacking_effect"):
			enemy.apply_stacking_effect(
				effect_name,
				get_stack_value(),
				get_max_stacks(),
				source_bottle.bottle_id if source_bottle and source_bottle.has_method("bottle_id") else effect_name,
				get_duration(),
				{
					"visual_cleanup": visual_cleanup,
					"immediate_effect": immediate_effect,
					"tick_effect": tick_effect,
					"tick_interval": get_tick_interval()
				}
			)

	DebugControl.debug_status("🔥 %s: Applied %d stacks directly" % [effect_name, stacks_to_apply])

# Visual effect methods (override these for specific effects)
func _create_visual_cleanup(enemy: Node2D) -> Callable:
	"""Override this for effect-specific cleanup"""
	return func():
		var overlay = enemy.get_node_or_null(effect_name.capitalize() + "Overlay")
		if overlay and is_instance_valid(overlay):
			overlay.queue_free()

func _create_immediate_effect(enemy: Node2D) -> Callable:
	"""Override this for effect-specific immediate visuals"""
	return func():
		if not is_instance_valid(enemy):
			return

		# Generic overlay creation
		if enemy.get_total_stack_count(effect_name) == 1:
			var overlay = ColorRect.new()
			overlay.size = Vector2(28, 28)
			overlay.position = Vector2(-14, -14)
			overlay.color = get_color()
			overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
			overlay.name = effect_name.capitalize() + "Overlay"
			enemy.add_child(overlay)

			var tween = overlay.create_tween()
			tween.set_loops()
			tween.tween_property(overlay, "modulate:a", 0.4, 0.3)
			tween.tween_property(overlay, "modulate:a", 0.8, 0.3)

func _create_tick_effect(enemy: Node2D, source_bottle: Node) -> Callable:
	"""Override this for effect-specific tick behavior"""
	print("CREATING enhanced tick effect")
	return func():
		print("ENHANCED TICK RUNNING!")
		if not is_instance_valid(enemy):
			return
		print("after validation tick running enhanced")
		var total_stacks = enemy.get_total_stack_count(effect_name)
		var damage = get_tick_damage() * total_stacks
		var bottle_id = source_bottle.bottle_id if source_bottle and source_bottle.has_method("bottle_id") else effect_name
		enemy.take_damage_from_source(damage, bottle_id)

		DebugControl.debug_combat("🔥 %s tick: %.1f damage (%d stacks)" % [effect_name, damage, total_stacks])
		_create_particle(enemy.global_position)

func _create_particle(position: Vector2):
	"""Create tick particle effect"""
	var particle = ColorRect.new()
	particle.size = Vector2(6, 6)
	particle.color = get_color()
	particle.position = position + Vector2(randf_range(-8, 8), randf_range(-8, 8))

	var scene = Engine.get_main_loop().current_scene
	scene.add_child(particle)

	var tween = particle.create_tween()
	tween.parallel().tween_property(particle, "position", particle.position + Vector2(randf_range(-16, 16), -24), 0.8)
	tween.parallel().tween_property(particle, "modulate:a", 0.0, 0.8)
	tween.tween_callback(particle.queue_free)
