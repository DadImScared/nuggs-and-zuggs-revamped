class_name BaseTriggerAction
extends Resource

# Base properties
@export var trigger_name: String
@export var trigger_description: String

# Main method that child classes implement
func execute_trigger(source_bottle: ImprovedBaseSauceBottle, trigger_data: TriggerEffectResource) -> void:
	push_error("execute_trigger() must be implemented by child class")

# Check if trigger condition is met
func should_trigger(source_bottle: ImprovedBaseSauceBottle, trigger_data: TriggerEffectResource) -> bool:
	match trigger_data.trigger_type:
		TriggerEffectResource.TriggerType.ON_SHOT_COUNT:
			var interval = trigger_data.trigger_condition.get("interval", 5)
			return source_bottle.shot_counter % interval == 0
		TriggerEffectResource.TriggerType.ON_TIMER:
			var cooldown = trigger_data.trigger_condition.get("cooldown", 10.0)
			var last_time = source_bottle.last_trigger_times.get(trigger_name, 0.0)
			var current_time = Time.get_ticks_msec() / 1000.0
			return current_time - last_time >= cooldown
		TriggerEffectResource.TriggerType.ON_RANDOM_CHANCE:
			var chance = trigger_data.trigger_condition.get("chance", 0.1)
			return randf() < chance
		TriggerEffectResource.TriggerType.ON_CRITICAL_HIT:
			# This would be checked when crit happens
			return false
		TriggerEffectResource.TriggerType.ON_ENEMY_DEATH:
			# This would be checked when enemy dies
			return false
		TriggerEffectResource.TriggerType.ON_LOW_HEALTH:
			var health_threshold = trigger_data.trigger_condition.get("health_threshold", 0.25)
			return PlayerStats.health / PlayerStats.max_health <= health_threshold
		TriggerEffectResource.TriggerType.ON_HIT:
			return false
			#return should_trigger_on_hit(source_bottle, trigger_data)
	return false

# Update trigger timing for timer-based triggers
func update_trigger_timing(source_bottle: ImprovedBaseSauceBottle, trigger_data: TriggerEffectResource) -> void:
	if trigger_data.trigger_type == TriggerEffectResource.TriggerType.ON_TIMER:
		var current_time = Time.get_ticks_msec() / 1000.0
		source_bottle.last_trigger_times[trigger_name] = current_time

# Debug logging
func log_trigger_executed(source_bottle: ImprovedBaseSauceBottle, trigger_data: TriggerEffectResource) -> void:
	print("⚡ %s trigger executed for bottle %s" % [trigger_name, source_bottle.bottle_id])

# Utility functions
func get_enemies_in_radius(center: Vector2, radius: float) -> Array[Node2D]:
	var enemies: Array[Node2D] = []
	var all_enemies = Engine.get_main_loop().current_scene.get_tree().get_nodes_in_group("enemies")

	for enemy in all_enemies:
		if is_instance_valid(enemy) and center.distance_to(enemy.global_position) <= radius:
			enemies.append(enemy)

	return enemies

func should_trigger_on_hit(source_bottle: ImprovedBaseSauceBottle, trigger_data: TriggerEffectResource, hit_enemy: Node2D, projectile: Area2D = null) -> bool:
	"""Check if ON_HIT trigger should activate for this specific hit"""

	# Default implementation - child classes can override for specific conditions
	match trigger_data.trigger_type:
		TriggerEffectResource.TriggerType.ON_HIT:
			# Check for random chance if specified
			var chance = trigger_data.trigger_condition.get("chance", 1.0)  # Default 100% if no chance specified
			if randf() > chance:
				return false

			# Check for enemy type conditions if specified
			var target_infected_only = trigger_data.trigger_condition.get("target_infected_only", false)
			if target_infected_only:
				return _is_enemy_infected(hit_enemy)

			return true  # No special conditions, always trigger on hit

	return false

func _is_enemy_infected(enemy: Node2D) -> bool:
	"""Helper to check if enemy is infected"""
	if not is_instance_valid(enemy):
		return false

	if enemy.has_method("has_status_effect"):
		return enemy.has_status_effect("infect")
	elif "active_effects" in enemy:
		return "infect" in enemy.active_effects

	return false
