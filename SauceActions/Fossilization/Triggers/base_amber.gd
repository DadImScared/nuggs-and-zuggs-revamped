# SauceActions/Fossilization/base_amber_trigger.gd
class_name BaseAmberTrigger
extends BaseTriggerAction

# Shared amber/fossilization constants
const DEFAULT_AMBER_COLOR = Color(1.0, 0.8, 0.3, 0.6)
const DEFAULT_FOSSILIZE_DURATION = 2.5
const DEFAULT_STACK_VALUE = 0.8  # 80% slow
const DEFAULT_TICK_DAMAGE = 6.0
const DEFAULT_TICK_INTERVAL = 1.0

func should_trigger_on_hit(source_bottle: ImprovedBaseSauceBottle, trigger_data: EnhancedTriggerData, hit_enemy: Node2D, projectile: Area2D = null) -> bool:
	# Only trigger on hits against fossilized enemies
	if hit_enemy and is_instance_valid(hit_enemy):
		return is_enemy_fossilized(hit_enemy)  # Use base class method
	return false

# Shared fossilization methods
func is_enemy_fossilized(enemy: Node2D) -> bool:
	"""Check if enemy is currently fossilized using modern stacking system"""
	if enemy.has_method("get_total_stack_count"):
		return enemy.get_total_stack_count("fossilize") > 0
	return false

func apply_fossilization_to_enemy(enemy: Node2D, source_bottle: ImprovedBaseSauceBottle,
	trigger_data: EnhancedTriggerData, stack_count: int = 1):
	"""Apply fossilization effect to enemy using modern direct stacking system"""

	# Extract parameters from trigger data
	var duration = trigger_data.effect_parameters.get("duration", DEFAULT_FOSSILIZE_DURATION)
	var tick_damage = trigger_data.effect_parameters.get("tick_damage", DEFAULT_TICK_DAMAGE)
	var amber_color = trigger_data.effect_parameters.get("amber_color", DEFAULT_AMBER_COLOR)

	# Smart stack calculation based on trigger data
	var effective_stacks = _calculate_smart_stacks(stack_count, enemy, trigger_data)

	# Use direct enemy stacking method
	if enemy.has_method("apply_stacking_effect"):
		# Get max stacks from trigger data, default to 5
		var max_stacks = trigger_data.effect_parameters.get("max_stacks", 5)

		# Apply stacking effect - this adds 1 stack each time, up to max_stacks
		enemy.apply_stacking_effect(
			"fossilize",              # effect_name (String)
			DEFAULT_STACK_VALUE,      # base_value (float) - 0.8 for 80% slow per stack
			max_stacks,               # max_stacks (int) - maximum allowed stacks
			source_bottle.bottle_id,  # source_bottle_id (String)
			duration,                 # duration (float)
			{                         # effect_data (Dictionary)
				"amber_color": amber_color,
				"visual_cleanup": func(): remove_amber_shell(enemy),
				"immediate_effect": func(): create_amber_shell_on_enemy(enemy, amber_color),
				"tick_effect": func(): apply_fossilization_tick_damage(enemy, tick_damage, source_bottle.bottle_id),
				"tick_interval": DEFAULT_TICK_INTERVAL,
				"mechanical_cleanup": func(): remove_amber_shell(enemy),
				"trigger_data": trigger_data
			}
		)

func create_amber_shell_on_enemy(enemy: Node2D, amber_color: Color = DEFAULT_AMBER_COLOR):
	"""Add amber visual to newly fossilized enemy"""
	if enemy.has_node("AmberShell"):
		return

	var amber_shell = ColorRect.new()
	amber_shell.size = Vector2(32, 32)
	amber_shell.position = Vector2(-16, -16)
	amber_shell.color = amber_color
	amber_shell.mouse_filter = Control.MOUSE_FILTER_IGNORE
	amber_shell.scale = Vector2(1.2, 1.2)
	amber_shell.name = "AmberShell"
	enemy.add_child(amber_shell)

	# Pulsing animation
	var tween = amber_shell.create_tween()
	tween.set_loops()
	tween.tween_property(amber_shell, "modulate:a", 0.3, 0.5)
	tween.tween_property(amber_shell, "modulate:a", 0.8, 0.5)

func remove_amber_shell(enemy: Node2D):
	"""Remove amber shell when fossilization ends"""
	if enemy.has_node("AmberShell"):
		enemy.get_node("AmberShell").queue_free()

func apply_fossilization_tick_damage(enemy: Node2D, damage: float, source_id: String):
	"""Apply tick damage from fossilization"""
	if enemy.has_method("take_damage_from_source"):
		enemy.take_damage_from_source(damage, source_id)
	elif enemy.has_method("take_damage"):
		enemy.take_damage(damage)

func create_fossilization_particles(position: Vector2, amber_color: Color = DEFAULT_AMBER_COLOR):
	"""Create amber particle effects"""
	for i in range(8):
		var particle = ColorRect.new()
		particle.size = Vector2(4, 4)
		particle.color = amber_color
		particle.position = position + Vector2(randf_range(-16, 16), randf_range(-16, 16))
		Engine.get_main_loop().current_scene.add_child(particle)

		var tween = particle.create_tween()
		tween.parallel().tween_property(particle, "position", particle.position + Vector2(randf_range(-32, 32), randf_range(-32, 32)), 0.5)
		tween.parallel().tween_property(particle, "modulate:a", 0.0, 0.5)
		tween.tween_callback(particle.queue_free)

func get_nearby_enemies(center_position: Vector2, radius: float) -> Array[Node2D]:
	"""Get all enemies within radius"""
	var enemies: Array[Node2D] = []
	var all_enemies = Engine.get_main_loop().current_scene.get_tree().get_nodes_in_group("enemies")

	for enemy in all_enemies:
		if is_instance_valid(enemy):
			var distance = center_position.distance_to(enemy.global_position)
			if distance <= radius:
				enemies.append(enemy)

	return enemies

func _calculate_smart_stacks(base_stacks: int, enemy: Node2D, trigger_data: EnhancedTriggerData) -> int:
	"""Calculate smart stack count based on trigger data and enemy state"""
	var final_stacks = base_stacks

	# Context-based stack modifications from trigger data
	var trigger_source = trigger_data.effect_parameters.get("trigger_source", "")
	match trigger_source:
		"overflow_explosion":
			# Overflow explosions are weaker, apply fewer stacks
			final_stacks = max(1, base_stacks - 1)
		"seeker_hit":
			# Seekers are precise, apply full stacks
			final_stacks = base_stacks
		"cascade_spread":
			# Cascade spreads are progressive, stack based on distance
			var distance_factor = trigger_data.effect_parameters.get("distance_factor", 1.0)
			final_stacks = max(1, int(base_stacks * distance_factor))
		_:
			# Default behavior
			final_stacks = base_stacks

	# Enemy-based smart adjustments
	if enemy.has_method("get_total_stack_count"):
		var current_stacks = enemy.get_total_stack_count("fossilize")

		# If enemy is already heavily fossilized, reduce additional stacks
		if current_stacks >= 3:
			final_stacks = max(1, final_stacks - 1)
			trigger_data.effect_parameters["reduced_stacks"] = true

		# Don't exceed reasonable stack limits
		var max_total_stacks = trigger_data.effect_parameters.get("max_stacks", 5)
		if current_stacks + final_stacks > max_total_stacks:
			final_stacks = max(0, max_total_stacks - current_stacks)

	return final_stacks
