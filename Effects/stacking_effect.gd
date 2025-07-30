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


func apply_mark(enemy: Node2D, mark_name: String, source_bottle: Node, duration: float = 5.0, enhanced_params: Dictionary = {}):
	"""Apply a mark for death trigger detection - handles enhancements directly"""
	if not enemy or not is_instance_valid(enemy) or not source_bottle:
		DebugControl.debug_status("⚠️ apply_mark: Invalid parameters")
		return

	# Mark-specific base parameters (no damage, no ticking)
	var mark_params = {
		"duration": duration,
		"tick_interval": 0.0,     # Marks never tick
		"tick_damage": 0.0,       # Marks never deal damage
		"max_stacks": 1,          # Default 1 stack, but talents can increase
		"stack_value": 1.0,
	}

	# Merge with any provided enhanced params
	for key in enhanced_params:
		mark_params[key] = enhanced_params[key]

	# Get talent enhancements for the mark_name specifically
	if source_bottle and source_bottle.has_method("get_enhanced_trigger_data"):
		var enhanced_data = source_bottle.get_enhanced_trigger_data(mark_name)
		if enhanced_data and enhanced_data.effect_parameters.size() > 0:
			# Apply talent enhancements to mark parameters
			mark_params["duration"] = enhanced_data.effect_parameters.get("duration", mark_params["duration"])
			mark_params["max_stacks"] = enhanced_data.effect_parameters.get("max_stacks", mark_params["max_stacks"])
			mark_params["stack_value"] = enhanced_data.effect_parameters.get("stack_value", mark_params["stack_value"])

			# Apply multipliers if present
			if enhanced_data.effect_parameters.has("duration_multiplier"):
				mark_params["duration"] *= enhanced_data.effect_parameters["duration_multiplier"]

			DebugControl.debug_status("🎯 Enhanced mark %s with talents" % mark_name)

	# Apply mark directly using stacking system with the mark_name
	if enemy.has_method("apply_stacking_effect"):
		var mark_applied = enemy.apply_stacking_effect(
			mark_name,                    # Use mark name, not self.effect_name
			mark_params["stack_value"],
			mark_params["max_stacks"],
			source_bottle.bottle_id,
			mark_params["duration"],
			{
				"tick_interval": 0.0,     # Marks never tick
				"tick_damage": 0.0,       # Marks never deal damage
				"tick_effect": null,      # No tick effects
				"visual_cleanup": null,   # No visual cleanup (marks are invisible)
				"immediate_effect": null  # No immediate visual effects
			}
		)

		if mark_applied > 0:
			DebugControl.debug_status("🎯 Applied %s mark: %d stacks, %.1fs duration" % [mark_name, mark_applied, mark_params["duration"]])
		else:
			DebugControl.debug_status("⚠️ Failed to apply %s mark (at max stacks)" % mark_name)
	else:
		DebugControl.debug_status("⚠️ Enemy doesn't support stacking effects for marks")

func apply_from_talent(
	enemy: Node2D,
	source_bottle: Node,
	stack_count: int = 1,
	enhanced_params: Dictionary = {}
):
	"""Apply effect with base parameters or enhanced parameters"""
	if not enemy or not is_instance_valid(enemy):
		DebugControl.debug_status("⚠️ %s.apply_from_talent: Invalid parameters" % effect_name)
		return

	if enhanced_params.size() > 0:
		# Use provided enhanced parameters directly
		var burn_params = {
			"duration": enhanced_params.get("duration", base_duration),
			"tick_interval": enhanced_params.get("tick_interval", base_tick_interval),
			"damage": enhanced_params.get("tick_damage", base_tick_damage),
			"max_stacks": enhanced_params.get("max_stacks", base_max_stacks),
			"stack_value": enhanced_params.get("stack_value", base_stack_value),
			"stacks": stack_count,
			"immediate_effect": enhanced_params.get("immediate_effect", null)
		}

		# Apply with enhanced parameters - no further enhancement needed
		_apply_with_enhanced_params(enemy, source_bottle, burn_params)

		# Add cold visuals if this is a cold effect
		if effect_name == "cold":
			_update_cold_visuals(enemy)

		DebugControl.debug_status("🔥 Applied %s with enhanced params: %.1f damage/tick" % [effect_name, burn_params["damage"]])
		return

	# ENHANCED: Try to fetch enhanced params from bottle (existing logic)
	if source_bottle and source_bottle.has_method("get_enhanced_trigger_data"):
		var enhanced_data = source_bottle.get_enhanced_trigger_data(effect_name)
		if enhanced_data and enhanced_data.effect_parameters.size() > 0:
			# Apply enhancements to parameters
			var params = {
				"duration": enhanced_data.effect_parameters.get("duration", base_duration),
				"tick_interval": enhanced_data.effect_parameters.get("tick_interval", base_tick_interval),
				"damage": enhanced_data.effect_parameters.get("tick_damage", base_tick_damage),
				"max_stacks": enhanced_data.effect_parameters.get("max_stacks", base_max_stacks),
				"stack_value": enhanced_data.effect_parameters.get("stack_value", base_stack_value),
				"stacks": stack_count
			}

			_apply_with_enhanced_params(enemy, source_bottle, params)

			# Add cold visuals if this is a cold effect
			if effect_name == "cold":
				_update_cold_visuals(enemy)

			DebugControl.debug_status("🔥 Applied %s with bottle enhancements: %.1f damage/tick" % [effect_name, params["damage"]])
			return

	# Fallback: Use base parameters without enhancements
	var base_params = {
		"duration": base_duration,
		"tick_interval": base_tick_interval,
		"damage": base_tick_damage,
		"max_stacks": base_max_stacks,
		"stack_value": base_stack_value,
		"stacks": stack_count
	}

	_apply_with_enhanced_params(enemy, source_bottle, base_params)

	# Add cold visuals if this is a cold effect
	if effect_name == "cold":
		_update_cold_visuals(enemy)

	DebugControl.debug_status("🔥 Applied %s with base params: %.1f damage/tick" % [effect_name, base_params["damage"]])

func _apply_with_enhanced_params(enemy: Node2D, source_bottle: Node, params: Dictionary):
	"""Apply the effect using enhanced parameters - no further enhancement needed"""

	# Create effect callbacks based on enhanced parameters
	var visual_cleanup = _create_visual_cleanup(enemy)
	var immediate_effect = params.get("immediate_effect", _create_immediate_effect(enemy, base_color, params))
	#var tick_effect = _create_tick_effect(enemy, params["damage"], base_color, source_bottle)
	var tick_effect = null

	if params.get("damage", 0.0) > 1.0:
		tick_effect = _create_tick_effect(enemy, params["damage"], base_color, source_bottle)

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

	DebugControl.debug_status("✨ Applied %s: %d stacks, %.1f damage/tick, %.1fs duration" % [
		effect_name,
		params["stacks"],
		params["damage"],
		params["duration"]
	])

# Legacy direct application function (for non-talent usage)
func apply_to_enemy(enemy: Node2D, source_bottle: Node, stack_count: int = 1):
	"""Apply effect directly without enhancements (legacy)"""
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

# Cold visual effects - called whenever cold is applied
func _update_cold_visuals(enemy: Node2D):
	"""Update cold visuals based on current stack count"""
	if not enemy or not is_instance_valid(enemy):
		return

	var total_stacks = enemy.get_total_stack_count("cold")
	var sprite = _get_enemy_sprite(enemy)

	# Progressive visual effects based on stack count
	if total_stacks >= 6:
		# FROZEN SOLID - Deep blue + ice shell
		if sprite:
			sprite.modulate = Color(0.6, 0.8, 1.0)
			if sprite.has_method("set_speed_scale"):
				sprite.speed_scale = 0
		_create_freeze_animation(enemy)

	elif total_stacks >= 4:
		# NEARLY FROZEN - Getting blue + frost particles
		if sprite:
			sprite.modulate = Color(0.7, 0.85, 1.0)
			if sprite.has_method("set_speed_scale"):
				sprite.speed_scale = 0.2
		_create_frost_buildup(enemy)

	elif total_stacks >= 2:
		# CHILLED - Light blue tint
		if sprite:
			sprite.modulate = Color(0.8, 0.9, 1.0)
			if sprite.has_method("set_speed_scale"):
				sprite.speed_scale = 0.5

	elif total_stacks >= 1:
		# SLIGHTLY COLD - Very light blue
		if sprite:
			sprite.modulate = Color(0.9, 0.95, 1.0)
			if sprite.has_method("set_speed_scale"):
				sprite.speed_scale = 0.8

func _get_enemy_sprite(enemy: Node) -> Node:
	"""Safely get sprite from any enemy type"""
	var sprite_names = ["animated_sprite", "Sprite", "Sprite2D", "AnimatedSprite2D"]

	for sprite_name in sprite_names:
		var sprite = enemy.get_node_or_null(sprite_name)
		if sprite:
			return sprite

	# Also try property access safely
	if enemy.get("animated_sprite"):
		return enemy.get("animated_sprite")

	for child in enemy.get_children():
		if child is Sprite2D or child is AnimatedSprite2D:
			return child

	return null

func _create_freeze_animation(enemy: Node):
	"""Create ice shell effect for fully frozen enemies"""
	if enemy.get_node_or_null("IceEffect"):
		return  # Already has ice effect

	var ice_shell = CPUParticles2D.new()
	ice_shell.name = "IceEffect"
	enemy.add_child(ice_shell)
	ice_shell.position = Vector2.ZERO

	ice_shell.emitting = true
	ice_shell.amount = 20
	ice_shell.lifetime = 99999.0
	ice_shell.one_shot = false
	ice_shell.explosiveness = 0.0

	ice_shell.spread = 360.0
	ice_shell.initial_velocity_min = 8.0
	ice_shell.initial_velocity_max = 12.0
	ice_shell.gravity = Vector2.ZERO
	ice_shell.scale_amount_min = 0.6
	ice_shell.scale_amount_max = 1.0
	ice_shell.color = Color(0.9, 0.95, 1.0, 0.7)

func _create_frost_buildup(enemy: Node):
	"""Create frost particles for nearly frozen enemies"""
	if enemy.get_node_or_null("FrostEffect"):
		return  # Already has frost effect

	var frost_effect = CPUParticles2D.new()
	frost_effect.name = "FrostEffect"
	enemy.add_child(frost_effect)
	frost_effect.position = Vector2.ZERO

	frost_effect.emitting = true
	frost_effect.amount = 8
	frost_effect.lifetime = 1.5
	frost_effect.one_shot = false
	frost_effect.explosiveness = 0.3

	frost_effect.spread = 360.0
	frost_effect.initial_velocity_min = 15.0
	frost_effect.initial_velocity_max = 25.0
	frost_effect.gravity = Vector2(0, 30)
	frost_effect.scale_amount_min = 0.4
	frost_effect.scale_amount_max = 0.7
	frost_effect.color = Color(0.8, 0.9, 1.0, 0.6)

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

func _create_tick_effect(enemy: Node2D, tick_damage: float, color: Color, source_bottle: Node):
	if tick_damage <= 0.1:
			return null
	return func():
		if not is_instance_valid(enemy):
			return

		var total_stacks = enemy.get_total_stack_count(effect_name)
		var damage = tick_damage * total_stacks  # tick_damage is already enhanced
		var bottle_id = source_bottle.bottle_id if source_bottle else effect_name

		# Apply damage - no further enhancement needed
		enemy.take_damage_from_source(damage, bottle_id)
		if enemy.has_method("_execute_dot_tick_trigger"):
			enemy._execute_dot_tick_trigger(bottle_id, effect_name, damage)

		DebugControl.debug_combat("🔥 %s tick: %.1f damage (%d stacks)" % [effect_name.capitalize(), damage, total_stacks])

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
