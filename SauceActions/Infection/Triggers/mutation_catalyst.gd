# SauceActions/Infection/Triggers/mutation_catalyst.gd
class_name MutationCatalystTrigger
extends BaseTriggerAction

func _init():
	trigger_name = "mutation_catalyst"
	trigger_description = "Each enemy infected has 10% chance to permanently increase infection damage by 0.1% for the rest of the run"

func execute_trigger(source_bottle: ImprovedBaseSauceBottle, trigger_data: EnhancedTriggerData) -> void:
	# Get parameters from trigger data
	var damage_boost_percent = trigger_data.effect_parameters.get("damage_boost_percent", 0.001)  # 0.1% = 0.001

	# The triggering enemy is passed via effect_parameters by TriggerActionManager
	var triggering_enemy = trigger_data.effect_parameters.get("dot_enemy")
	if not triggering_enemy or not is_instance_valid(triggering_enemy):
		#print("⚠️ Mutation Catalyst: No valid triggering enemy")
		return

	#print("🧬 Mutation Catalyst: Triggered from infection tick - permanently boosting damage!")

	# Create permanent damage modifier using existing StatModifier system
	var damage_modifier = StatModifier.new()
	damage_modifier.stat_name = "damage"
	damage_modifier.mode = StatModifier.ModifierMode.MULTIPLY
	damage_modifier.multiply = 1.0 + damage_boost_percent  # 1.001 = +0.1% damage

	# Add to bottle's permanent stat modifier history
	source_bottle.stat_modifier_history.append(damage_modifier)

	# Recalculate effective stats to apply the new modifier immediately
	source_bottle.recalculate_all_effective_stats()

	#print("🧬 Mutation Catalyst: Applied +%.3f%% permanent damage boost. Total modifiers: %d" % [damage_boost_percent * 100, source_bottle.stat_modifier_history.size()])

	# Log for debugging
	log_trigger_executed(source_bottle, trigger_data)
