class_name BaseTriggerAction
extends Resource

# Base properties
@export var trigger_name: String
@export var trigger_description: String
var original_trigger_data: TriggerEffectResource

func store_original_trigger_data(trigger_data: TriggerEffectResource):
	"""Store the original trigger data so we can reapply enhancements later"""
	original_trigger_data = trigger_data.duplicate()

func refresh_enhancements(bottle: ImprovedBaseSauceBottle, base_trigger_data: TriggerEffectResource) -> void:
	pass
	#print("⚠️ Trigger %s doesn't implement refresh_enhancements()" % trigger_name)

# Virtual method that child classes should override to report if they're active
func is_active() -> bool:
	return false

# Main method that child classes implement
func execute_trigger(source_bottle: ImprovedBaseSauceBottle, trigger_data: EnhancedTriggerData) -> void:
	push_error("execute_trigger() must be implemented by child class")

# Check if trigger condition is met
func should_trigger(source_bottle: ImprovedBaseSauceBottle, trigger_data: EnhancedTriggerData) -> bool:
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
func update_trigger_timing(source_bottle: ImprovedBaseSauceBottle, trigger_data: EnhancedTriggerData) -> void:
	if trigger_data.trigger_type == TriggerEffectResource.TriggerType.ON_TIMER:
		var current_time = Time.get_ticks_msec() / 1000.0
		source_bottle.last_trigger_times[trigger_name] = current_time

# Debug logging
func log_trigger_executed(source_bottle: ImprovedBaseSauceBottle, trigger_data: EnhancedTriggerData) -> void:
	pass
	#print("⚡ %s trigger executed for bottle %s" % [trigger_name, source_bottle.bottle_id])

# Utility functions
func get_enemies_in_radius(center: Vector2, radius: float) -> Array[Node2D]:
	var enemies: Array[Node2D] = []
	var all_enemies = Engine.get_main_loop().current_scene.get_tree().get_nodes_in_group("enemies")

	for enemy in all_enemies:
		if is_instance_valid(enemy) and center.distance_to(enemy.global_position) <= radius:
			enemies.append(enemy)

	return enemies

func should_trigger_on_dot_tick(source_bottle: ImprovedBaseSauceBottle, trigger_data: EnhancedTriggerData, affected_enemy: Node2D, dot_type: String, damage_dealt: float) -> bool:
	"""Check if ON_DOT_TICK trigger should activate for this specific DOT tick"""

	# Only process ON_DOT_TICK triggers
	if trigger_data.trigger_type != TriggerEffectResource.TriggerType.ON_DOT_TICK:
		return false

	# Check for DOT type filter if specified
	var target_dot_types = trigger_data.trigger_condition.get("dot_types", [])
	if target_dot_types.size() > 0 and dot_type not in target_dot_types:
		return false

	# Check for random chance if specified
	var chance = trigger_data.trigger_condition.get("chance", 1.0)  # Default 100% if no chance specified
	if randf() > chance:
		return false

	# Check for minimum damage threshold if specified
	var min_damage = trigger_data.trigger_condition.get("min_damage", 0.0)
	if damage_dealt < min_damage:
		return false

	return true  # All conditions met

func should_trigger_on_hit(source_bottle: ImprovedBaseSauceBottle, trigger_data: EnhancedTriggerData, hit_enemy: Node2D, projectile: Area2D = null) -> bool:
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

func apply_enhancements(bottle: ImprovedBaseSauceBottle, base_trigger_data: TriggerEffectResource) -> EnhancedTriggerData:
	"""Generic enhancement system with source tracking"""
	var enhanced_data = EnhancedTriggerData.new(base_trigger_data)

	#print("🔍 Looking for enhancements for: %s" % trigger_name)
	#print("🔍 Bottle has %d total trigger effects:" % bottle.trigger_effects.size())

	for i in range(bottle.trigger_effects.size()):
		var trigger_effect = bottle.trigger_effects[i]
		#print("  [%d] %s - enhances: %s" % [i, trigger_effect.trigger_name, str(trigger_effect.enhances)])

	# Find all enhancements that target this trigger
	var enhancements_applied = 0
	for trigger_effect in bottle.trigger_effects:
		if trigger_effect.enhances.size() > 0 and trigger_name in trigger_effect.enhances:
			apply_single_enhancement_with_tracking(enhanced_data, trigger_effect)
			enhancements_applied += 1
			#print("🔧 Enhancement: %s applied to %s" % [trigger_effect.trigger_name, trigger_name])

	#if enhancements_applied > 0:
		#print("✨ %s enhanced with %d bonuses" % [trigger_name, enhancements_applied])
		#print(enhanced_data.get_tooltip_text())  # Show detailed breakdown

	return enhanced_data

func apply_single_enhancement_with_tracking(enhanced_data: EnhancedTriggerData, enhancement: TriggerEffectResource):
	"""Apply enhancement with full source tracking"""
	var params = enhancement.effect_parameters
	var enhancement_name = enhancement.trigger_name.replace("_", " ").capitalize()

	for param_key in params.keys():
		var param_value = params[param_key]

		# Handle multipliers
		if param_key.ends_with("_multiplier"):
			var base_key = param_key.replace("_multiplier", "")
			apply_multiplier_with_tracking(enhanced_data, base_key, param_value, enhancement_name)

		# Handle direct additions
		else:
			apply_direct_with_tracking(enhanced_data, param_key, param_value, enhancement_name)

func apply_multiplier_with_tracking(enhanced_data: EnhancedTriggerData, base_key: String, multiplier: float, enhancement_name: String):
	#print("🔍 Looking for parameter: %s" % base_key)
	#print("🔍 trigger_condition keys: %s" % str(enhanced_data.trigger_condition.keys()))
	#print("🔍 effect_parameters keys: %s" % str(enhanced_data.effect_parameters.keys()))

	var current_value = get_parameter_value_from_enhanced(enhanced_data, base_key)
	#print("🔍 Found value for %s: %s" % [base_key, str(current_value)])

	if current_value != null:
		#print("✅ Applying multiplier")
		var new_value = current_value * multiplier
		set_parameter_value_in_enhanced(enhanced_data, base_key, new_value)
		enhanced_data.add_enhancement_source(base_key, enhancement_name, "multiply", multiplier, new_value)
		#print("  🔢 %s: %.2f → %.2f (×%.2f from %s)" % [base_key.capitalize(), current_value, new_value, multiplier, enhancement_name])

		#print("❌ Parameter %s not found!" % base_key)

func apply_direct_with_tracking(enhanced_data: EnhancedTriggerData, param_key: String, param_value, enhancement_name: String):
	"""Add parameter with source tracking - handles different data types properly"""

	# Check if this parameter already exists in the base trigger
	var existing_value = get_parameter_value_from_enhanced(enhanced_data, param_key)

	if existing_value != null:
		# Parameter exists - handle different data types
		if param_value is bool:
			# For booleans, use OR logic (true if either is true)
			var new_value = existing_value or param_value
			set_parameter_value_in_enhanced(enhanced_data, param_key, new_value)
			enhanced_data.add_enhancement_source(param_key, enhancement_name, "enable", param_value, new_value)
			#print("  🔘 %s: %s → %s (enabled by %s)" % [param_key.capitalize(), str(existing_value), str(new_value), enhancement_name])
		elif param_value is Color:
			# For colors, replace with new color
			set_parameter_value_in_enhanced(enhanced_data, param_key, param_value)
			enhanced_data.add_enhancement_source(param_key, enhancement_name, "set", param_value, param_value)
			#print("  🎨 %s: %s (color set by %s)" % [param_key.capitalize(), str(param_value), enhancement_name])
		elif param_value is String:
			# For strings, replace with new string
			set_parameter_value_in_enhanced(enhanced_data, param_key, param_value)
			enhanced_data.add_enhancement_source(param_key, enhancement_name, "set", param_value, param_value)
			#print("  📝 %s: %s (text set by %s)" % [param_key.capitalize(), str(param_value), enhancement_name])
		elif param_value is float or param_value is int:
			# For numbers, ADD to existing value
			var new_value = existing_value + param_value
			set_parameter_value_in_enhanced(enhanced_data, param_key, new_value)
			enhanced_data.add_enhancement_source(param_key, enhancement_name, "add", param_value, new_value)
			#print("  ➕ %s: %.2f → %.2f (+%.2f from %s)" % [param_key.capitalize(), existing_value, new_value, param_value, enhancement_name])
		else:
			# For unknown types, replace with new value
			set_parameter_value_in_enhanced(enhanced_data, param_key, param_value)
			enhanced_data.add_enhancement_source(param_key, enhancement_name, "set", param_value, param_value)
			#print("  ⚡ %s: %s (replaced by %s)" % [param_key.capitalize(), str(param_value), enhancement_name])
	else:
		# Parameter doesn't exist - SET it as new parameter
		enhanced_data.effect_parameters[param_key] = param_value
		enhanced_data.add_enhancement_source(param_key, enhancement_name, "set", param_value, param_value)
		#print("  ✨ Added %s: %s (from %s)" % [param_key.capitalize(), str(param_value), enhancement_name])

func get_parameter_value_from_enhanced(enhanced_data: EnhancedTriggerData, key: String):
	"""Get parameter value from enhanced data"""
	if enhanced_data.trigger_condition.has(key):
		return enhanced_data.trigger_condition[key]
	elif enhanced_data.effect_parameters.has(key):
		return enhanced_data.effect_parameters[key]
	else:
		return null

func set_parameter_value_in_enhanced(enhanced_data: EnhancedTriggerData, key: String, value):
	"""Set parameter value in enhanced data"""
	if enhanced_data.trigger_condition.has(key):
		enhanced_data.trigger_condition[key] = value
	else:
		enhanced_data.effect_parameters[key] = value
