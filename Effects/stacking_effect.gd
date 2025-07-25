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

# Enhanced application function with generic parameter system
func apply_from_talent(
	enemy: Node2D,
	source_bottle: Node,
	stack_count: int = 1,
	override_params: Dictionary = {}
):
	"""
	Apply this effect with all talent enhancements using generic parameter system.

	Args:
		enemy: Target to apply effect to
		source_bottle: Source bottle (needed for talent enhancements)
		stack_count: Number of stacks to apply
		override_params: Optional parameters to override
	"""
	if not enemy or not is_instance_valid(enemy) or not source_bottle:
		DebugControl.debug_status("⚠️ %s.apply_from_talent: Invalid parameters" % effect_name)
		return

	# Start with base parameters
	var enhanced_params = {
		"duration": base_duration,
		"tick_interval": base_tick_interval,
		"damage": base_tick_damage,
		"max_stacks": base_max_stacks,
		"stack_value": base_stack_value,
		"stacks": stack_count
	}

	# Apply override parameters first
	for key in override_params:
		enhanced_params[key] = override_params[key]

	# Apply all enhancements from the bottle's trigger effects
	if source_bottle and source_bottle.has_method("get") and source_bottle.trigger_effects:
		for trigger in source_bottle.trigger_effects:
			if effect_name in trigger.enhances:
				# Check if trigger conditions are met
				if _evaluate_trigger_conditions(trigger, enemy):
					# Apply parameter enhancements generically
					for param_name in trigger.effect_parameters:
						if param_name in enhanced_params:
							var old_value = enhanced_params[param_name]
							enhanced_params[param_name] += trigger.effect_parameters[param_name]
							DebugControl.debug_status("🔥 %s enhanced %s: %.1f → %.1f (+%.1f)" % [
								trigger.trigger_name,
								param_name,
								old_value,
								enhanced_params[param_name],
								trigger.effect_parameters[param_name]
							])

	# Apply the effect using enhanced parameters
	_apply_with_enhanced_params(enemy, source_bottle, enhanced_params)

	DebugControl.debug_status("✨ Applied %s: %d stacks, %.1f damage/tick, %.1fs duration" % [
		effect_name,
		enhanced_params["stacks"],
		enhanced_params["damage"],
		enhanced_params["duration"]
	])

func _apply_with_enhanced_params(enemy: Node2D, source_bottle: Node, params: Dictionary):
	"""Apply the effect using enhanced parameters"""

	# Create effect callbacks based on enhanced parameters
	var visual_cleanup = _create_visual_cleanup(enemy)
	var immediate_effect = _create_immediate_effect(enemy, base_color, params)
	var tick_effect = _create_tick_effect(enemy, params["damage"], base_color, source_bottle)

	# Apply all stacks at once with stack count
	var stacks_to_apply = params.get("stacks", 1)
	if enemy.has_method("apply_stacking_effect"):
		enemy.apply_stacking_effect(
			effect_name,
			params["stack_value"],
			params["max_stacks"],
			source_bottle.bottle_id if source_bottle else effect_name,
			params["duration"],
			{
				"visual_cleanup": visual_cleanup,
				"immediate_effect": immediate_effect,
				"tick_effect": tick_effect,
				"tick_interval": params["tick_interval"],
				"stack_count": stacks_to_apply
			}
		)

func _evaluate_trigger_conditions(trigger: TriggerEffectResource, enemy: Node2D) -> bool:
	"""Check if trigger conditions are met for this enemy"""

	# Check if target has ALL required effects
	if trigger.trigger_condition.has("has_effects"):
		var required_effects = trigger.trigger_condition["has_effects"]
		for effect in required_effects:
			if not _enemy_has_effect(enemy, effect):
				DebugControl.debug_status("🔥 %s condition failed: enemy missing %s" % [trigger.trigger_name, effect])
				return false
		DebugControl.debug_status("🔥 %s condition met: enemy has all required effects %s" % [trigger.trigger_name, str(required_effects)])
		return true

	# Check if target has ANY of the specified effects
	if trigger.trigger_condition.has("has_any_effects"):
		var possible_effects = trigger.trigger_condition["has_any_effects"]
		for effect in possible_effects:
			if _enemy_has_effect(enemy, effect):
				DebugControl.debug_status("🔥 %s condition met: enemy has %s" % [trigger.trigger_name, effect])
				return true
		DebugControl.debug_status("🔥 %s condition failed: enemy has none of %s" % [trigger.trigger_name, str(possible_effects)])
		return false

	# Check minimum health threshold
	if trigger.trigger_condition.has("target_health_below"):
		var threshold = trigger.trigger_condition["target_health_below"]
		if enemy.has_method("get_health_percentage"):
			var health_pct = enemy.get_health_percentage()
			var meets_condition = health_pct < threshold
			DebugControl.debug_status("🔥 %s health condition: %.1f%% < %.1f%% = %s" % [trigger.trigger_name, health_pct * 100, threshold * 100, meets_condition])
			return meets_condition
		return false

	# Check maximum health threshold
	if trigger.trigger_condition.has("target_health_above"):
		var threshold = trigger.trigger_condition["target_health_above"]
		if enemy.has_method("get_health_percentage"):
			var health_pct = enemy.get_health_percentage()
			var meets_condition = health_pct > threshold
			DebugControl.debug_status("🔥 %s health condition: %.1f%% > %.1f%% = %s" % [trigger.trigger_name, health_pct * 100, threshold * 100, meets_condition])
			return meets_condition
		return false

	# No conditions = always applies
	DebugControl.debug_status("🔥 %s has no conditions, always applies" % trigger.trigger_name)
	return true

func _enemy_has_effect(enemy: Node2D, effect_name: String) -> bool:
	"""Check if enemy has a specific effect"""
	if enemy.has_method("get_total_stack_count"):
		return enemy.get_total_stack_count(effect_name) > 0
	elif enemy.has_method("has_status_effect"):
		return enemy.has_status_effect(effect_name)
	return false

# Legacy direct application function (for non-talent usage)
func apply_to_enemy(enemy: Node2D, source_bottle: Node, stack_count: int = 1):
	"""Apply effect directly without talent enhancements (legacy)"""
	if not enemy or not is_instance_valid(enemy):
		return

	# Use base parameters without enhancements
	var base_params = {
		"duration": base_duration,
		"tick_interval": base_tick_interval,
		"damage": base_tick_damage,
		"max_stacks": base_max_stacks,
		"stack_value": base_stack_value,
		"stacks": stack_count
	}

	_apply_with_enhanced_params(enemy, source_bottle, base_params)

# Helper methods to create callbacks
func _create_visual_cleanup(enemy: Node2D) -> Callable:
	return func():
		var overlay = enemy.get_node_or_null(effect_name.capitalize() + "Overlay")
		if overlay and is_instance_valid(overlay):
			overlay.queue_free()

func _create_immediate_effect(enemy: Node2D, color: Color, params: Dictionary) -> Callable:
	return func():
		if not is_instance_valid(enemy):
			return

		var overlay_name = effect_name.capitalize() + "Overlay"

		# Create visual on first stack
		if enemy.get_total_stack_count(effect_name) == 1:
			var effect_overlay = ColorRect.new()
			effect_overlay.size = Vector2(28, 28)
			effect_overlay.position = Vector2(-14, -14)
			effect_overlay.color = color
			effect_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
			effect_overlay.name = overlay_name
			enemy.add_child(effect_overlay)

			var tween = effect_overlay.create_tween()
			tween.set_loops()
			tween.tween_property(effect_overlay, "modulate:a", 0.4, 0.3)
			tween.tween_property(effect_overlay, "modulate:a", 0.8, 0.3)

		# Update intensity based on stacks
		var effect_overlay = enemy.get_node_or_null(overlay_name)
		if effect_overlay:
			var stack_count = enemy.get_total_stack_count(effect_name)
			var intensity = min(1.0, 0.4 + (stack_count * 0.1))
			effect_overlay.modulate = Color(color.r, color.g, color.b, intensity)
			var scale = 1.0 + (stack_count * 0.05)
			effect_overlay.scale = Vector2(scale, scale)

func _create_tick_effect(enemy: Node2D, tick_damage: float, color: Color, source_bottle: Node) -> Callable:
	return func():
		if not is_instance_valid(enemy):
			return

		var total_stacks = enemy.get_total_stack_count(effect_name)
		var damage = tick_damage * total_stacks
		var bottle_id = source_bottle.bottle_id if source_bottle else effect_name

		# Apply damage with talent enhancements
		var final_damage = _calculate_enhanced_damage(enemy, source_bottle, damage)
		enemy.take_damage_from_source(final_damage, bottle_id)

		DebugControl.debug_combat("🔥 %s tick: %.1f damage (%d stacks)" % [effect_name.capitalize(), final_damage, total_stacks])

		# Create tick particle
		var particle = ColorRect.new()
		particle.size = Vector2(6, 6)
		particle.color = color
		particle.position = enemy.global_position + Vector2(randf_range(-8, 8), randf_range(-8, 8))

		var scene = Engine.get_main_loop().current_scene
		scene.add_child(particle)

		var tween = particle.create_tween()
		tween.parallel().tween_property(particle, "position", particle.position + Vector2(randf_range(-16, 16), -24), 0.8)
		tween.parallel().tween_property(particle, "modulate:a", 0.0, 0.8)
		tween.tween_callback(particle.queue_free)

func _calculate_enhanced_damage(enemy: Node2D, source_bottle: Node, base_damage: float) -> float:
	"""Calculate damage with all talent enhancements applied"""
	var final_damage = base_damage

	# Apply damage enhancements from bottle's trigger effects
	if source_bottle and source_bottle.trigger_effects:
		for trigger in source_bottle.trigger_effects:
			if effect_name in trigger.enhances:
				# Check if trigger conditions are met for damage enhancement
				if _evaluate_trigger_conditions(trigger, enemy):
					# Apply damage parameter enhancement
					if trigger.effect_parameters.has("damage"):
						var old_damage = final_damage
						final_damage += trigger.effect_parameters["damage"]
						DebugControl.debug_status("🔥 %s damage enhanced: %.1f → %.1f (+%.1f)" % [
							trigger.trigger_name, old_damage, final_damage, trigger.effect_parameters["damage"]
						])

	return final_damage
