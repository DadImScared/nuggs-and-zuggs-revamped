# Singletons/SauceActionManager.gd
# Add this to AutoLoad as "SauceActionManager"

extends Node

# Registry of action classes
var action_classes: Dictionary = {}

func _ready():
	_register_action_classes()

func _register_action_classes():
	"""Register all modular action classes"""
	action_classes[BaseSauceResource.SpecialEffectType.VOLCANIC_RING] = VolcanicRingAction.new()

	# TODO: Add other actions as they're migrated to modular system
	# action_classes[BaseSauceResource.SpecialEffectType.BURN] = BurnAction.new()
	# action_classes[BaseSauceResource.SpecialEffectType.POISON] = PoisonAction.new()
	# action_classes[BaseSauceResource.SpecialEffectType.CHAIN] = ChainAction.new()

	print("SauceActionManager: Registered %d modular actions" % action_classes.size())

func apply_sauce_action(
	action_type: BaseSauceResource.SpecialEffectType,
	projectile: Area2D,
	enemy: Node2D,
	source_bottle: ImprovedBaseSauceBottle
) -> bool:
	"""Try to apply action using modular system. Returns true if handled."""

	if action_type in action_classes:
		var action_instance = action_classes[action_type]
		action_instance.apply_action(projectile, enemy, source_bottle)
		return true

	# Action not migrated to modular system yet
	return false

func get_action_description(action_type: BaseSauceResource.SpecialEffectType) -> String:
	"""Get description for an action type"""
	if action_type in action_classes:
		return action_classes[action_type].action_description
	return "Action description not available"

func is_action_modular(action_type: BaseSauceResource.SpecialEffectType) -> bool:
	"""Check if an action has been migrated to the modular system"""
	return action_type in action_classes

# Debug function
func debug_print_registered_actions():
	print("=== Modular Sauce Actions ===")
	for action_type in action_classes:
		var action = action_classes[action_type]
		print("  %s: %s" % [BaseSauceResource.SpecialEffectType.keys()[action_type], action.action_name])
	print("=============================")
