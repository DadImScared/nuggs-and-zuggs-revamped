# SauceActions/Infection/Triggers/infectious_momentum.gd
class_name InfectiousMomentumTrigger
extends BaseTriggerAction

# Store momentum data on the trigger itself
var momentum_stacks: int = 0
var stack_timers: Array = []
var speed_boost_per_stack: float = 0.03
var max_stacks: int = 10

func _init():
	trigger_name = "infectious_momentum"
	trigger_description = "Each enemy killed while infected increases movement speed by 3% for 12 seconds (stacks up to 30%)"

func execute_trigger(source_bottle: ImprovedBaseSauceBottle, trigger_data: TriggerEffectResource) -> void:
	speed_boost_per_stack = trigger_data.effect_parameters.get("speed_boost_per_stack", 0.03)  # 3%
	var duration = trigger_data.effect_parameters.get("duration", 12.0)  # 12 seconds
	max_stacks = trigger_data.effect_parameters.get("max_stacks", 10)  # Max 30% (10 stacks)

	# Check if the killed enemy was infected
	var killed_enemy = trigger_data.effect_parameters.event_data.killed_enemy
	if not killed_enemy or not _was_enemy_infected(killed_enemy):
		return  # Only proc on infected enemy deaths

	# Add speed stack
	_add_momentum_stack(duration)

	print("🏃 Infectious Momentum: Speed stack added! Current stacks: %d" % momentum_stacks)
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

func _add_momentum_stack(duration: float):
	"""Add a speed stack and increase player speed"""
	# Don't exceed max stacks
	if momentum_stacks >= max_stacks:
		print("🏃 Infectious Momentum: Max stacks reached (%d)" % max_stacks)
		return

	# Add new stack
	momentum_stacks += 1
	PlayerStats.speed += PlayerStats.speed * speed_boost_per_stack
	# Increase player speed
	#var player = _get_player()
	#if player:
		#PlayerStats.speed += PlayerStats.speed * speed_boost_per_stack
		#print("🏃 Player speed increased to: %.1f" % player.speed)

	# Create timer for this stack
	var stack_timer = Timer.new()
	stack_timer.wait_time = duration
	stack_timer.one_shot = true
	stack_timer.timeout.connect(_remove_momentum_stack)

	# Add timer to scene and track it
	var scene = Engine.get_main_loop().current_scene
	scene.add_child(stack_timer)
	stack_timers.append(stack_timer)
	stack_timer.start()

	print("🏃 Infectious Momentum: Added stack %d/%d (%.1f%% speed boost)" % [
		momentum_stacks,
		max_stacks,
		momentum_stacks * speed_boost_per_stack * 100
	])

func _remove_momentum_stack():
	"""Remove one speed stack when timer expires"""
	if momentum_stacks > 0:
		momentum_stacks -= 1

		# Decrease player speed
		PlayerStats.speed -= PlayerStats.speed * speed_boost_per_stack / (1.0 + speed_boost_per_stack)
		#var player = _get_player()
		#if player:
			#player.speed -= player.speed * speed_boost_per_stack / (1.0 + speed_boost_per_stack)
			#print("🏃 Player speed decreased to: %.1f" % player.speed)

		# Remove the expired timer from tracking
		for i in range(stack_timers.size()):
			if not is_instance_valid(stack_timers[i]):
				stack_timers.remove_at(i)
				break

		print("🏃 Infectious Momentum: Stack expired. Current stacks: %d" % momentum_stacks)

func _get_player() -> Node:
	"""Get the player node"""
	var players = Engine.get_main_loop().current_scene.get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		return players[0]
	return null

func get_current_stacks() -> int:
	"""Get current number of infectious momentum stacks"""
	return momentum_stacks

func get_current_speed_bonus() -> float:
	"""Get current speed bonus from momentum stacks"""
	return momentum_stacks * speed_boost_per_stack

# Static helper functions for other systems to access momentum
static func get_momentum_stacks() -> int:
	"""Static function to get current momentum stacks from anywhere"""
	var manager = Engine.get_main_loop().get_nodes_in_group("trigger_managers")[0] if Engine.get_main_loop().get_nodes_in_group("trigger_managers").size() > 0 else null
	if not manager:
		return 0

	var momentum_trigger = manager.trigger_actions.get("infectious_momentum")
	if momentum_trigger:
		return momentum_trigger.get_current_stacks()
	return 0

static func get_momentum_speed_bonus() -> float:
	"""Get current speed bonus from momentum stacks"""
	var manager = Engine.get_main_loop().get_nodes_in_group("trigger_managers")[0] if Engine.get_main_loop().get_nodes_in_group("trigger_managers").size() > 0 else null
	if not manager:
		return 0.0

	var momentum_trigger = manager.trigger_actions.get("infectious_momentum")
	if momentum_trigger:
		return momentum_trigger.get_current_speed_bonus()
	return 0.0
