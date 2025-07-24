# SauceActions/Burn/Triggers/chain_ignition_action.gd
class_name ChainIgnitionAction
extends BaseTriggerAction

func _init():
	trigger_name = "chain_ignition"
	trigger_description = "Burning enemies spread fire to nearby enemies"

func execute_trigger(source_bottle: Node, trigger_data: EnhancedTriggerData):
	"""Execute chain ignition spread"""
	var params = trigger_data.effect_parameters
	var burning_enemy = params.get("dot_enemy")

	if not burning_enemy or not is_instance_valid(burning_enemy):
		return

	# Find nearby enemies
	var spread_radius = params.get("spread_radius", 100.0)
	var max_targets = params.get("max_targets", 3)
	var spread_burn_stacks = params.get("spread_burn_stacks", 1)

	var nearby_enemies = _find_nearby_enemies(burning_enemy, spread_radius, max_targets)

	if nearby_enemies.is_empty():
		return

	for enemy in nearby_enemies:
		# Make sure we have the actual enemy node, not a child sprite
		var actual_enemy = enemy
		if enemy is AnimatedSprite2D:
			actual_enemy = enemy.get_parent()

		# Apply burn using the effect system
		Effects.burn.apply_from_talent(
			actual_enemy,
			source_bottle,
			spread_burn_stacks
		)

		# Visual effect for spread
		_create_ignition_chain_visual(burning_enemy, actual_enemy)

func _find_nearby_enemies(center_enemy: Node2D, radius: float, max_count: int) -> Array:
	"""Find enemies within radius that aren't already burning"""
	var nearby_enemies = []

	# Use the enemies group to find actual enemy nodes
	var all_enemies = Engine.get_main_loop().current_scene.get_tree().get_nodes_in_group("enemies")
	var center_pos = center_enemy.global_position

	for enemy in all_enemies:
		if not is_instance_valid(enemy) or enemy == center_enemy:
			continue

		# Skip if already burning (to prevent immediate re-spread)
		if enemy.has_method("get_total_stack_count") and enemy.get_total_stack_count("burn") > 0:
			continue

		var distance = center_pos.distance_to(enemy.global_position)
		if distance <= radius:
			nearby_enemies.append(enemy)

		if nearby_enemies.size() >= max_count:
			break

	return nearby_enemies

func _create_ignition_chain_visual(from_enemy: Node2D, to_enemy: Node2D):
	"""Create visual effect showing fire spreading between enemies"""
	var main_scene = Engine.get_main_loop().current_scene
	if not main_scene:
		return

	# Create a simple particle that travels from source to target
	var chain_particle = ColorRect.new()
	chain_particle.size = Vector2(8, 8)
	chain_particle.color = Color.ORANGE_RED
	chain_particle.position = from_enemy.global_position - chain_particle.size / 2

	main_scene.add_child(chain_particle)

	# Animate the particle movement
	var tween = chain_particle.create_tween()
	tween.tween_property(chain_particle, "position", to_enemy.global_position - chain_particle.size / 2, 0.4)
	tween.tween_callback(chain_particle.queue_free)

	# Fade out as it travels
	var fade_tween = chain_particle.create_tween()
	fade_tween.parallel().tween_property(chain_particle, "modulate:a", 0.0, 0.4)
