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
