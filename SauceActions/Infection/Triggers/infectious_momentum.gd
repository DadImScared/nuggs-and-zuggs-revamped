# SauceActions/Infection/Triggers/infectious_momentum.gd
class_name InfectiousMomentumTrigger
extends BaseTriggerAction

func _init():
	trigger_name = "infectious_momentum"
	trigger_description = "Each enemy killed while infected increases movement speed by 3% for 12 seconds (stacks up to 30%)"

func execute_trigger(source_bottle: ImprovedBaseSauceBottle, trigger_data: EnhancedTriggerData) -> void:
	"""Execute Infectious Momentum using the new buff system"""

	# Get parameters from trigger data
	var speed_bonus = trigger_data.effect_parameters.get("speed_boost_per_stack", 0.03)  # 3% default
	var duration = trigger_data.effect_parameters.get("duration", 12.0)       # 12 seconds
	var max_stacks = trigger_data.effect_parameters.get("max_stacks", 10)     # 10 stacks max
	var source = "Infectious Momentum"

	# Check if the killed enemy was infected
	var event_data = trigger_data.effect_parameters.get("event_data", {})
	var killed_enemy = event_data.get("killed_enemy")

	if not killed_enemy or not _was_enemy_infected(killed_enemy):
		return  # Only proc on infected enemy deaths

	# Use the NEW buff system to add movement speed buff
	var success = PlayerStats.add_movement_speed_buff(speed_bonus, duration, source, max_stacks)

	if success:
		var current_stacks = PlayerStats.get_buff_count_from_source(PlayerStats.BuffType.MOVEMENT_SPEED, source)
		#print("🏃 Infectious Momentum! Stack %d/%d (+%.1f%% speed for %.1fs)" % [
			#current_stacks, max_stacks, speed_bonus * 100, duration
		#])
	#else:
		#print("🚫 Infectious Momentum at max stacks")

	log_trigger_executed(source_bottle, trigger_data)

func _was_enemy_infected(enemy: Node2D) -> bool:
	"""Check if enemy was infected when it died"""
	if not is_instance_valid(enemy):
		return false

	# Check if enemy had infection effect
	if enemy.has_method("has_status_effect"):
		return enemy.has_status_effect("infect")
	elif "active_effects" in enemy:
		return "infect" in enemy.active_effects

	return false

# Static helper functions updated to use buff system
static func get_momentum_stacks() -> int:
	"""Get current momentum stacks using new buff system"""
	return PlayerStats.get_buff_count_from_source(PlayerStats.BuffType.MOVEMENT_SPEED, "Infectious Momentum")

static func get_momentum_speed_bonus() -> float:
	"""Get current speed bonus from momentum stacks using new buff system"""
	var stacks = get_momentum_stacks()
	return stacks * 0.03  # 3% per stack
