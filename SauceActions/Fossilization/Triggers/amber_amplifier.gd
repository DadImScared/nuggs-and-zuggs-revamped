# SauceActions/Fossilization/Triggers/amber_amplifier.gd
class_name AmberAmplifierTrigger
extends BaseTriggerAction

func _init():
	trigger_name = "amber_amplifier"
	trigger_description = "+20% damage per fossilized enemy within 400px (max +200%)"

func execute_trigger(source_bottle: ImprovedBaseSauceBottle, trigger_data: EnhancedTriggerData) -> void:
	# Count fossilized enemies within range
	var fossilized_count = _count_nearby_fossilized_enemies(source_bottle, trigger_data)

	# Apply damage bonus based on count
	_apply_damage_bonus(source_bottle, fossilized_count, trigger_data)

func _count_nearby_fossilized_enemies(source_bottle: ImprovedBaseSauceBottle, trigger_data: EnhancedTriggerData) -> int:
	"""Count fossilized enemies within detection range of this bottle"""
	var count = 0
	var bottle_position = source_bottle.global_position
	var detection_range = trigger_data.effect_parameters.get("radius", 400.0)

	var all_enemies = Engine.get_main_loop().current_scene.get_tree().get_nodes_in_group("enemies")

	for enemy in all_enemies:
		if is_instance_valid(enemy):
			var distance = bottle_position.distance_to(enemy.global_position)
			if distance <= detection_range and _is_enemy_fossilized(enemy):
				count += 1

	# Cap at maximum for balance
	var max_enemies = trigger_data.effect_parameters.get("max_enemies", 10)
	return min(count, max_enemies)

func _apply_damage_bonus(source_bottle: ImprovedBaseSauceBottle, fossilized_count: int, trigger_data: EnhancedTriggerData):
	"""Apply the damage bonus based on nearby fossilized enemy count"""
	# Get damage per enemy from trigger parameters
	var damage_per_enemy = trigger_data.effect_parameters.get("damage_per_enemy", 0.20)

	# Calculate bonus
	var damage_bonus = fossilized_count * damage_per_enemy
	var total_multiplier = 1.0 + damage_bonus

	# Remove any existing Amber Amplifier modifiers
	_remove_existing_amplifier_modifiers(source_bottle)

	# Create new damage modifier
	var damage_modifier = StatModifier.new()
	damage_modifier.stat_name = "damage"
	damage_modifier.mode = StatModifier.ModifierMode.MULTIPLY
	damage_modifier.multiply = total_multiplier
	damage_modifier.set_meta("amber_amplifier_bonus", true)

	# Apply to bottle
	source_bottle.stat_modifier_history.append(damage_modifier)
	source_bottle.recalculate_all_effective_stats()

	#print("🔶 Amber Amplifier: %d nearby fossilized enemies = %.0f%% damage bonus" % [fossilized_count, damage_bonus * 100])

func _remove_existing_amplifier_modifiers(source_bottle: ImprovedBaseSauceBottle):
	"""Remove any existing Amber Amplifier damage modifiers"""
	var modifiers_to_remove = []

	for modifier in source_bottle.stat_modifier_history:
		if modifier.has_meta("amber_amplifier_bonus"):
			modifiers_to_remove.append(modifier)

	for modifier in modifiers_to_remove:
		source_bottle.stat_modifier_history.erase(modifier)



func _is_enemy_fossilized(enemy: Node2D) -> bool:
	"""Check if an enemy is currently fossilized using the stacking system"""
	if enemy.has_method("get_total_stack_count"):
		return enemy.get_total_stack_count("fossilize") > 0
	return false

# Override should_trigger to activate on fossilization hits
func should_trigger(source_bottle: ImprovedBaseSauceBottle, trigger_data: EnhancedTriggerData) -> bool:
	# Always trigger when called - this runs on successful fossilizations
	return true
