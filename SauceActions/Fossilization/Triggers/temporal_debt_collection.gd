# SauceActions/Fossilization/Triggers/temporal_debt_collection.gd
class_name TemporalDebtCollectionTrigger
extends BaseTriggerAction

func _init():
	trigger_name = "temporal_debt_collection"
	trigger_description = "Every second without fossilizing, gain +5% fossilization chance. Resets on successful fossilization."

func execute_trigger(source_bottle: ImprovedBaseSauceBottle, trigger_data: EnhancedTriggerData) -> void:
	# If we're here, it means fossilization was successful - reset everything
	#print("🕰️ Temporal Debt: Fossilization successful! Resetting bonus...")
	_reset_debt_bonus(source_bottle)

func should_trigger(source_bottle: ImprovedBaseSauceBottle, trigger_data: EnhancedTriggerData) -> bool:
	# Initialize timer if it doesn't exist yet
	if not source_bottle.get_node_or_null("TemporalDebtTimer"):
		var bonus_per_second = trigger_data.effect_parameters.get("bonus_per_second", 0.05)
		_create_debt_timer(source_bottle, bonus_per_second)
		#print("🕰️ Temporal Debt: Initialized for bottle %s" % source_bottle.sauce_data.sauce_name)

	# Check if this hit caused fossilization
	var hit_enemy = trigger_data.effect_parameters.get("hit_enemy")
	if hit_enemy and is_instance_valid(hit_enemy):
		return _did_hit_cause_fossilization(hit_enemy)

	return false

func _did_hit_cause_fossilization(enemy: Node2D) -> bool:
	"""Check if the enemy is now fossilized (meaning this hit caused it)"""
	if enemy.has_method("get_total_stack_count"):
		return enemy.get_total_stack_count("fossilize") > 0
	return false

func _reset_debt_bonus(source_bottle: ImprovedBaseSauceBottle):
	"""Reset the fossilization chance bonus and restart the debt timer"""
	# Remove existing debt bonus modifiers
	_remove_existing_debt_modifiers(source_bottle)

	# Reset the debt timer
	_restart_debt_timer(source_bottle)

	#print("🕰️ Temporal Debt: Bonus reset to 0%, timer restarted")

func _remove_existing_debt_modifiers(source_bottle: ImprovedBaseSauceBottle):
	"""Remove any existing Temporal Debt chance modifiers"""
	var modifiers_to_remove = []

	for modifier in source_bottle.stat_modifier_history:
		if modifier.has_meta("temporal_debt_bonus"):
			modifiers_to_remove.append(modifier)

	for modifier in modifiers_to_remove:
		source_bottle.stat_modifier_history.erase(modifier)

	# Recalculate stats without the debt bonus
	source_bottle.recalculate_all_effective_stats()

func _restart_debt_timer(source_bottle: ImprovedBaseSauceBottle):
	"""Restart the debt accumulation timer"""
	var debt_timer = source_bottle.get_node_or_null("TemporalDebtTimer")
	if debt_timer:
		debt_timer.start()  # Restart existing timer
		#print("🕰️ Temporal Debt: Timer restarted")

func _create_debt_timer(source_bottle: ImprovedBaseSauceBottle, bonus_per_second: float):
	"""Create a new debt accumulation timer"""
	var debt_timer = Timer.new()
	debt_timer.name = "TemporalDebtTimer"
	debt_timer.wait_time = 1.0  # 1 second intervals
	debt_timer.timeout.connect(_on_debt_timer_timeout.bind(source_bottle, bonus_per_second))
	debt_timer.autostart = true
	source_bottle.add_child(debt_timer)

	#print("🕰️ Temporal Debt: Timer created and started")

func _on_debt_timer_timeout(source_bottle: ImprovedBaseSauceBottle, bonus_per_second: float):
	"""Called every second to increase fossilization chance"""
	if not is_instance_valid(source_bottle):
		return

	# Increase fossilization chance
	_add_debt_bonus(source_bottle, bonus_per_second)

func _add_debt_bonus(source_bottle: ImprovedBaseSauceBottle, bonus_amount: float):
	"""Add fossilization chance bonus"""
	# Create new chance modifier - adds 5% each tick
	var chance_modifier = StatModifier.new()
	chance_modifier.stat_name = "effect_chance"
	chance_modifier.mode = StatModifier.ModifierMode.ADD
	chance_modifier.add = bonus_amount  # +5% each tick
	chance_modifier.set_meta("temporal_debt_bonus", true)

	# Apply to bottle (stacks with existing modifiers)
	source_bottle.stat_modifier_history.append(chance_modifier)
	source_bottle.recalculate_all_effective_stats()

	#print("🕰️ Temporal Debt: +%.0f%% chance bonus added" % [bonus_amount * 100])
