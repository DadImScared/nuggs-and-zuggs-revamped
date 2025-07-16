# Resources/SauceActions/BaseSauceAction.gd
class_name BaseSauceAction
extends Resource

# Base properties
@export var action_name: String
@export var action_description: String

# Main method that child classes implement - SIMPLIFIED!
func apply_action(projectile: Area2D, enemy: Node2D, source_bottle: ImprovedBaseSauceBottle) -> void:
	push_error("apply_action() must be implemented by child class")

# Read talent modifications from bottle.special_effects
func get_talent_modifications(source_bottle: ImprovedBaseSauceBottle) -> Array[SpecialEffectResource]:
	var modifications: Array[SpecialEffectResource] = []

	if not source_bottle:
		return modifications

	# Get all talent effects that start with our action name
	var prefix = action_name + "_"

	for talent_effect in source_bottle.special_effects:
		if talent_effect.effect_name.begins_with(prefix):
			modifications.append(talent_effect)

	return modifications

# Debug logging
func log_action_applied(enemy: Node2D, modifications: Array) -> void:
	var mod_names = modifications.map(func(mod): return mod.effect_name)
	print("🔥 %s action applied to %s with %d talent modifications: %s" %
		[action_name, enemy.name, modifications.size(), str(mod_names)])

# Utility to get enemies in radius
func get_enemies_in_radius(center: Vector2, radius: float) -> Array[Node2D]:
	var enemies = []
	var all_enemies = Engine.get_main_loop().current_scene.get_tree().get_nodes_in_group("enemies")

	for enemy in all_enemies:
		if is_instance_valid(enemy) and center.distance_to(enemy.global_position) <= radius:
			enemies.append(enemy)

	return enemies
