# Singletons/trigger_action_manager.gd
# Add this to AutoLoad as "TriggerActionManager"

extends Node

# Registry of trigger action classes
var trigger_actions: Dictionary = {}

func _ready():
	_register_trigger_actions()

func _register_trigger_actions():
	"""Register all trigger action classes"""
	trigger_actions["infection_tsunami"] = InfectionTsunamiTrigger.new()
	trigger_actions["double_dose"] = DoubleDoseTrigger.new()
	#trigger_actions["burst_fire"] = BurstFireTriggerAction.new()
	#trigger_actions["mini_volcano"] = MiniVolcanoTriggerAction.new()

	# TODO: Add more trigger actions as they're created
	# trigger_actions["tsunami_wave"] = TsunamiWaveTriggerAction.new()
	# trigger_actions["chain_burst"] = ChainBurstTriggerAction.new()
	# trigger_actions["perfect_shots"] = PerfectShotsTriggerAction.new()
	# trigger_actions["death_explosion"] = DeathExplosionTriggerAction.new()

	print("TriggerActionManager: Registered %d trigger actions" % trigger_actions.size())

func process_trigger_effects(source_bottle: ImprovedBaseSauceBottle) -> void:
	"""Process all trigger effects for a bottle - called from bottle's _check_trigger_effects()"""
	for trigger_effect in source_bottle.trigger_effects:
		var trigger_name = trigger_effect.trigger_name

		if trigger_name in trigger_actions:
			var action = trigger_actions[trigger_name]

			# Check if trigger condition is met
			if action.should_trigger(source_bottle, trigger_effect):
				# Execute the trigger
				action.execute_trigger(source_bottle, trigger_effect)

				# Update timing for timer-based triggers
				action.update_trigger_timing(source_bottle, trigger_effect)
		else:
			print("⚠️ No trigger action registered for: %s" % trigger_name)

func execute_hit_trigger(source_bottle: ImprovedBaseSauceBottle, hit_enemy: Node2D, projectile: Area2D = null):
	"""Execute triggers based on hitting an enemy"""
	for trigger_effect in source_bottle.trigger_effects:
		if trigger_effect.trigger_type == TriggerEffectResource.TriggerType.ON_HIT:
			var trigger_name = trigger_effect.trigger_name

			if trigger_name in trigger_actions:
				var action = trigger_actions[trigger_name]

				# Check if this specific hit should trigger the effect
				if action.should_trigger_on_hit(source_bottle, trigger_effect, hit_enemy, projectile):
					# Add hit context to trigger data
					trigger_effect.effect_parameters["hit_enemy"] = hit_enemy
					trigger_effect.effect_parameters["hit_projectile"] = projectile

					# Execute the trigger
					action.execute_trigger(source_bottle, trigger_effect)
					action.update_trigger_timing(source_bottle, trigger_effect)
			else:
				print("⚠️ No trigger action registered for hit trigger: %s" % trigger_name)

func execute_event_trigger(source_bottle: ImprovedBaseSauceBottle, event_type: TriggerEffectResource.TriggerType, event_data: Dictionary = {}):
	"""Execute triggers based on events (crit, death, etc.)"""
	for trigger_effect in source_bottle.trigger_effects:
		if trigger_effect.trigger_type == event_type:
			var trigger_name = trigger_effect.trigger_name

			if trigger_name in trigger_actions:
				var action = trigger_actions[trigger_name]
				action.execute_trigger(source_bottle, trigger_effect)
				action.update_trigger_timing(source_bottle, trigger_effect)

func get_trigger_description(trigger_name: String) -> String:
	"""Get description for a trigger action"""
	if trigger_name in trigger_actions:
		return trigger_actions[trigger_name].trigger_description
	return "Trigger description not available"

func is_trigger_registered(trigger_name: String) -> bool:
	"""Check if a trigger has been registered"""
	return trigger_name in trigger_actions

# Debug function
func debug_print_registered_triggers():
	print("=== Trigger Actions ===")
	for trigger_name in trigger_actions:
		var action = trigger_actions[trigger_name]
		print("  %s: %s" % [trigger_name, action.trigger_description])
	print("========================")
