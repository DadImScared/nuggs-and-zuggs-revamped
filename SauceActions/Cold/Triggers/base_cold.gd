# SauceActions/Cold/Triggers/base_cold.gd
class_name ColdTrigger
extends BaseTriggerAction

func _init() -> void:
	trigger_name = "cold"
	trigger_description = "Apply stacking cold effect that progressively chills enemies until frozen solid"

func execute_trigger(bottle: ImprovedBaseSauceBottle, data: EnhancedTriggerData):
	var enemy = data.effect_parameters.hit_enemy

	if not enemy or not is_instance_valid(enemy):
		return

	# Get cold parameters from trigger data (like Hot Sauce does)
	var stack_count = data.effect_parameters.get("stack_value", 1)
	var enhanced_params = {
		"duration": data.effect_parameters.get("duration", 5.0),
		"tick_interval": 0.0,  # No ticking for cold
		"tick_damage": 0.0,    # No tick damage for cold
		"max_stacks": data.effect_parameters.get("max_stacks", 6),
		"stack_value": data.effect_parameters.get("stack_value", 1.0),
		"slow_per_stack": data.effect_parameters.get("slow_per_stack", 0.15),
		"freeze_threshold": data.effect_parameters.get("freeze_threshold", 6),
		"cold_color": data.effect_parameters.get("cold_color", Color(0.7, 0.9, 1.0, 0.8)),
		"tick_effect": null,
		## Add immediate effect callback for freeze animation
		#"immediate_effect": _create_cold_immediate_effect(enemy, bottle)
	}

	# Use the Effects system like Hot Sauce does
	Effects.cold.apply_from_talent(enemy, bottle, stack_count, enhanced_params)

	DebugControl.debug_status("🧊 Cold applied via Effects system! Stacks: %d" % stack_count)

func _create_cold_immediate_effect(enemy: Node, source_bottle: Node) -> Callable:
	"""Create the immediate effect callback that handles freeze animation"""
	return func():
		if not is_instance_valid(enemy):
			return

		var total_stacks = enemy.get_total_stack_count("cold")
		var total_cold_value = enemy.get_total_stacked_value("cold")
		var slow_per_stack = 0.15
		var freeze_threshold = 6
		# Calculate movement speed reduction
		var slow_multiplier = 1.0 - (total_cold_value * slow_per_stack)

		# Progressive cold effects based on stack count
		if total_stacks >= freeze_threshold:
			# FULLY FROZEN at 6 stacks
			enemy.move_speed = 0
			if enemy.animated_sprite:
				enemy.animated_sprite.speed_scale = 0  # Stop animation completely
				enemy.animated_sprite.modulate = Color(0.6, 0.8, 1.0)  # Deep ice blue

			# Create dramatic freeze animation
			_create_freeze_animation(enemy)
			DebugControl.debug_status("❄️ FROZEN SOLID! Enemy completely frozen (%d stacks)" % total_stacks)

		elif total_stacks >= 4:
			# NEARLY FROZEN at 4-5 stacks - very slow with ice forming
			enemy.move_speed = enemy.original_speed * max(slow_multiplier, 0.05)  # Almost stopped
			if enemy.animated_sprite:
				enemy.animated_sprite.speed_scale = 0.2  # Very slow animation
				enemy.animated_sprite.modulate = Color(0.7, 0.85, 1.0)  # Getting blue

			# Create frost buildup effect
			_create_frost_buildup(enemy)
			DebugControl.debug_status("🧊 Frost building up... (%d stacks)" % total_stacks)

		elif total_stacks >= 2:
			# CHILLED at 2-3 stacks - slowed with cold tint
			enemy.move_speed = enemy.original_speed * max(slow_multiplier, 0.3)
			if enemy.animated_sprite:
				enemy.animated_sprite.speed_scale = max(slow_multiplier, 0.5)
				enemy.animated_sprite.modulate = Color(0.8, 0.9, 1.0)  # Light blue

			DebugControl.debug_status("❄️ Enemy chilled (%d stacks)" % total_stacks)
		else:
			# SLIGHTLY COLD at 1 stack - barely slowed
			enemy.move_speed = enemy.original_speed * max(slow_multiplier, 0.7)
			if enemy.animated_sprite:
				enemy.animated_sprite.speed_scale = max(slow_multiplier, 0.8)
				enemy.animated_sprite.modulate = Color(0.9, 0.95, 1.0)  # Very light blue

func _create_freeze_animation(enemy: Node):
	"""Create dramatic freeze animation when enemy hits 6 stacks"""
	if not enemy or not is_instance_valid(enemy):
		return

	var freeze_position = enemy.global_position
	var scene_root = Engine.get_main_loop().current_scene
	if not scene_root:
		return

	# Remove any existing ice effects first
	var old_ice = enemy.get_node_or_null("IceEffect")
	if old_ice:
		old_ice.queue_free()

	# Create ice crystal shell around enemy
	var ice_shell = CPUParticles2D.new()
	ice_shell.name = "IceEffect"
	enemy.add_child(ice_shell)
	ice_shell.position = Vector2.ZERO  # Relative to enemy

	ice_shell.emitting = true
	ice_shell.amount = 25
	ice_shell.lifetime = 99999.0  # Persist until unfrozen
	ice_shell.one_shot = false
	ice_shell.explosiveness = 0.0

	# Create ice crystal shell effect
	ice_shell.spread = 360.0
	ice_shell.initial_velocity_min = 5.0
	ice_shell.initial_velocity_max = 15.0
	ice_shell.gravity = Vector2.ZERO
	ice_shell.scale_amount_min = 0.5
	ice_shell.scale_amount_max = 1.2
	ice_shell.color = Color(0.9, 0.95, 1.0, 0.8)

	# Create pulsing freeze effect
	var tween = ice_shell.create_tween()
	tween.set_loops()
	tween.tween_property(ice_shell, "scale", Vector2(1.2, 1.2), 1.0)
	tween.tween_property(ice_shell, "scale", Vector2(1.0, 1.0), 1.0)

	# Freeze burst effect (one-time)
	var freeze_burst = CPUParticles2D.new()
	scene_root.add_child(freeze_burst)
	freeze_burst.global_position = freeze_position
	freeze_burst.emitting = true
	freeze_burst.amount = 20
	freeze_burst.lifetime = 1.0
	freeze_burst.one_shot = true
	freeze_burst.explosiveness = 1.0

	# Ice crystal burst
	freeze_burst.spread = 360.0
	freeze_burst.initial_velocity_min = 80.0
	freeze_burst.initial_velocity_max = 120.0
	freeze_burst.gravity = Vector2(0, 50)
	freeze_burst.scale_amount_min = 0.8
	freeze_burst.scale_amount_max = 1.5
	freeze_burst.color = Color(0.8, 0.9, 1.0, 0.9)

	# Cleanup burst effect
	await scene_root.get_tree().create_timer(2.0).timeout
	if is_instance_valid(freeze_burst):
		freeze_burst.queue_free()

func _create_frost_buildup(enemy: Node):
	"""Create frost effect for 4-5 stacks (almost frozen)"""
	if not enemy or not is_instance_valid(enemy):
		return

	# Remove old frost effects
	var old_frost = enemy.get_node_or_null("FrostEffect")
	if old_frost:
		old_frost.queue_free()

	# Create light frost effect
	var frost_effect = CPUParticles2D.new()
	frost_effect.name = "FrostEffect"
	enemy.add_child(frost_effect)
	frost_effect.position = Vector2.ZERO

	frost_effect.emitting = true
	frost_effect.amount = 10
	frost_effect.lifetime = 2.0
	frost_effect.one_shot = false
	frost_effect.explosiveness = 0.2

	# Light frost particles
	frost_effect.spread = 360.0
	frost_effect.initial_velocity_min = 10.0
	frost_effect.initial_velocity_max = 20.0
	frost_effect.gravity = Vector2(0, 20)
	frost_effect.scale_amount_min = 0.3
	frost_effect.scale_amount_max = 0.8
	frost_effect.color = Color(0.8, 0.9, 1.0, 0.6)

func _get_enemy_sprite(enemy: Node) -> Node:
	"""Get the sprite node from enemy (works for different enemy types)"""
	# Try different common sprite names
	var sprite_names = ["animated_sprite", "Sprite", "Sprite2D", "AnimatedSprite2D"]

	for sprite_name in sprite_names:
		var sprite = enemy.get_node_or_null(sprite_name)
		if sprite:
			return sprite

	# Fallback: look for any Sprite2D or AnimatedSprite2D child
	for child in enemy.get_children():
		if child is Sprite2D or child is AnimatedSprite2D:
			return child

	return null
