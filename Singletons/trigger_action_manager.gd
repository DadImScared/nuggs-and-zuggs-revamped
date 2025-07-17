# Singletons/trigger_action_manager.gd
# Add this to AutoLoad as "TriggerActionManager"

extends Node

# Registry of trigger action classes
var trigger_actions: Dictionary = {}

func _ready():
	_register_trigger_actions()

func _register_trigger_actions():
	"""Automatically register all trigger action classes"""
	print("🔍 Auto-discovering trigger actions...")

	var total_registered = 0

	# Auto-discover all sauce folders in SauceActions
	var sauce_paths = _discover_sauce_action_folders()
	for path in sauce_paths:
		var registered_count = _register_triggers_from_path(path)
		total_registered += registered_count

	# Also check global triggers folder
	var global_registered = _register_triggers_from_path("res://TriggerActions/Global/")
	total_registered += global_registered

	print("✅ Auto-registered %d trigger actions" % total_registered)

#func _register_trigger_actions():
	#"""Register all trigger action classes"""
	#trigger_actions["infection_tsunami"] = InfectionTsunamiTrigger.new()
	#trigger_actions["double_dose"] = DoubleDoseTrigger.new()
	#trigger_actions["viral_frenzy"] = ViralFrenzyTrigger.new()
	#trigger_actions["viral_relay"] = ViralRelayTrigger.new()
	##trigger_actions["burst_fire"] = BurstFireTriggerAction.new()
	##trigger_actions["mini_volcano"] = MiniVolcanoTriggerAction.new()
#
	## TODO: Add more trigger actions as they're created
	## trigger_actions["tsunami_wave"] = TsunamiWaveTriggerAction.new()
	## trigger_actions["chain_burst"] = ChainBurstTriggerAction.new()
	## trigger_actions["perfect_shots"] = PerfectShotsTriggerAction.new()
	## trigger_actions["death_explosion"] = DeathExplosionTriggerAction.new()
#
	#print("TriggerActionManager: Registered %d trigger actions" % trigger_actions.size())

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

func execute_dot_tick_trigger(source_bottle: ImprovedBaseSauceBottle, affected_enemy: Node2D, dot_type: String, damage_dealt: float):
	"""Execute triggers when a DOT effect deals damage"""
	for trigger_effect in source_bottle.trigger_effects:
		if trigger_effect.trigger_type == TriggerEffectResource.TriggerType.ON_DOT_TICK:
			var trigger_name = trigger_effect.trigger_name

			if trigger_name in trigger_actions:
				var action = trigger_actions[trigger_name]

				# Check if this specific DOT tick should trigger the effect
				if action.should_trigger_on_dot_tick(source_bottle, trigger_effect, affected_enemy, dot_type, damage_dealt):
					# Pass DOT context to the trigger
					trigger_effect.effect_parameters["dot_enemy"] = affected_enemy
					trigger_effect.effect_parameters["dot_type"] = dot_type
					trigger_effect.effect_parameters["dot_damage"] = damage_dealt

					# Execute the trigger
					action.execute_trigger(source_bottle, trigger_effect)
					action.update_trigger_timing(source_bottle, trigger_effect)
			else:
				print("⚠️ No trigger action registered for DOT tick trigger: %s" % trigger_name)

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

func _discover_sauce_action_folders() -> Array[String]:
	"""Discover all Triggers folders in SauceActions directory"""
	var trigger_paths: Array[String] = []
	var dir = DirAccess.open("res://SauceActions/")

	if not dir:
		print("⚠️ SauceActions directory not found")
		return trigger_paths

	dir.list_dir_begin()
	var folder_name = dir.get_next()

	while folder_name != "":
		if dir.current_is_dir() and not folder_name.begins_with("."):
			# Check if this sauce folder has a Triggers subfolder
			var triggers_path = "res://SauceActions/" + folder_name + "/Triggers/"
			var triggers_dir = DirAccess.open(triggers_path)
			if triggers_dir:
				trigger_paths.append(triggers_path)
				print("  📁 Found triggers folder: %s" % triggers_path)

		folder_name = dir.get_next()

	dir.list_dir_end()
	return trigger_paths

func _register_triggers_from_path(path: String) -> int:
	"""Register all trigger files from a specific path"""
	var dir = DirAccess.open(path)
	if not dir:
		# Path doesn't exist, skip silently
		return 0

	var registered_count = 0
	dir.list_dir_begin()
	var file_name = dir.get_next()

	while file_name != "":
		# Look for .gd files (now any .gd file in Triggers folder is a trigger)
		if file_name.ends_with(".gd"):
			var success = _register_trigger_from_file(path + file_name)
			if success:
				registered_count += 1

		file_name = dir.get_next()

	dir.list_dir_end()
	return registered_count

func _register_trigger_from_file(file_path: String) -> bool:
	"""Register a single trigger from file path"""
	# Load the script
	var script = load(file_path)
	if not script:
		print("⚠️ Failed to load trigger script: %s" % file_path)
		return false

	# Create instance
	var trigger_instance = script.new()
	if not trigger_instance:
		print("⚠️ Failed to instantiate trigger: %s" % file_path)
		return false

	# Check if it's a valid trigger (has trigger_name)
	if not trigger_instance.has_method("execute_trigger"):
		print("⚠️ Invalid trigger (no execute_trigger method): %s" % file_path)
		return false

	# Register using the trigger_name
	var trigger_name = trigger_instance.trigger_name
	if trigger_name == "":
		print("⚠️ Trigger has empty name: %s" % file_path)
		return false

	trigger_actions[trigger_name] = trigger_instance
	print("  ✅ Registered: %s from %s" % [trigger_name, file_path])
	return true
