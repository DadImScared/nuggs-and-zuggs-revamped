extends Node

func apply_effect(projectile: Area2D, enemy: Node2D, sauce_resource: BaseSauceResource):
	if not sauce_resource or sauce_resource.special_effect_type == BaseSauceResource.SpecialEffectType.NONE:
		return

	# Check if effect triggers
	if randf() > sauce_resource.effect_chance:
		return

	match sauce_resource.special_effect_type:
		BaseSauceResource.SpecialEffectType.TORNADO:
			_apply_tornado_effect(projectile, enemy, sauce_resource)
		BaseSauceResource.SpecialEffectType.BURN:
			_apply_burn_effect(enemy, sauce_resource)
		BaseSauceResource.SpecialEffectType.SLOW:
			_apply_slow_effect(enemy, sauce_resource)
		BaseSauceResource.SpecialEffectType.STICKY:
			_apply_sticky_effect(enemy, sauce_resource)
		BaseSauceResource.SpecialEffectType.POISON:
			_apply_poison_effect(enemy, sauce_resource)
		BaseSauceResource.SpecialEffectType.FREEZE:
			_apply_freeze_effect(enemy, sauce_resource)
		BaseSauceResource.SpecialEffectType.CHAIN:
			_apply_chain_effect(projectile, enemy, sauce_resource)
		BaseSauceResource.SpecialEffectType.EXPLODE:
			_apply_explosion_effect(projectile, enemy, sauce_resource)
		BaseSauceResource.SpecialEffectType.HEAL:
			_apply_heal_effect(sauce_resource)
		BaseSauceResource.SpecialEffectType.MULTIPLY:
			_apply_multiply_effect(projectile, enemy, sauce_resource)
		BaseSauceResource.SpecialEffectType.MAGNETIZE:
			_apply_magnetize_effect(enemy, sauce_resource)
		BaseSauceResource.SpecialEffectType.SHIELD_BREAK:
			_apply_shield_break_effect(enemy, sauce_resource)
		BaseSauceResource.SpecialEffectType.LEECH:
			_apply_leech_effect(projectile, sauce_resource)
		BaseSauceResource.SpecialEffectType.LIGHTNING:
			_apply_lightning_effect(projectile, enemy, sauce_resource)
		BaseSauceResource.SpecialEffectType.CHAOS:
			_apply_chaos_effect(projectile, enemy, sauce_resource)
		BaseSauceResource.SpecialEffectType.MARK:
			_apply_mark_effect(enemy, sauce_resource)

func _apply_tornado_effect(projectile: Area2D, enemy: Node2D, sauce_resource: BaseSauceResource):
	VisualEffectManager.create_tornado(
		enemy.global_position,
		sauce_resource.effect_duration,
		sauce_resource.effect_intensity,
		projectile.get_scaled_damage() * 0.3,  # 30% of projectile damage per pull
		sauce_resource.sauce_color
	)

# Status effect applications
func _apply_burn_effect(enemy: Node2D, sauce_resource: BaseSauceResource):
	if enemy.has_method("apply_status_effect"):
		enemy.apply_status_effect("burn", sauce_resource.effect_duration, sauce_resource.effect_intensity)

func _apply_slow_effect(enemy: Node2D, sauce_resource: BaseSauceResource):
	if enemy.has_method("apply_status_effect"):
		enemy.apply_status_effect("slow", sauce_resource.effect_duration, sauce_resource.effect_intensity)

func _apply_sticky_effect(enemy: Node2D, sauce_resource: BaseSauceResource):
	if enemy.has_method("apply_status_effect"):
		enemy.apply_status_effect("sticky", sauce_resource.effect_duration, sauce_resource.effect_intensity)

func _apply_poison_effect(enemy: Node2D, sauce_resource: BaseSauceResource):
	if enemy.has_method("apply_status_effect"):
		enemy.apply_status_effect("poison", sauce_resource.effect_duration, sauce_resource.effect_intensity)

func _apply_freeze_effect(enemy: Node2D, sauce_resource: BaseSauceResource):
	if enemy.has_method("apply_status_effect"):
		enemy.apply_status_effect("freeze", sauce_resource.effect_duration, sauce_resource.effect_intensity)

# Area effects
func _apply_chain_effect(projectile: Area2D, enemy: Node2D, sauce_resource: BaseSauceResource):
	var chain_distance = 60.0
	var max_chains = int(sauce_resource.effect_intensity)
	var chain_targets = []
	var nearby_enemies = _get_nearby_enemies(enemy, chain_distance)

	var chains_used = 0
	for nearby_enemy in nearby_enemies:
		if nearby_enemy != enemy and nearby_enemy not in chain_targets:
			chain_targets.append(nearby_enemy)
			if nearby_enemy.has_method("take_damage"):
				nearby_enemy.take_damage(projectile.get_scaled_damage() * 0.6)

			VisualEffectManager.create_chain_visual(
				enemy.global_position,
				nearby_enemy.global_position,
				sauce_resource.sauce_color
			)

			chains_used += 1
			if chains_used >= max_chains:
				break

func _apply_explosion_effect(projectile: Area2D, enemy: Node2D, sauce_resource: BaseSauceResource):
	var explosion_radius = 15.0 * sauce_resource.effect_intensity
	var nearby_enemies = _get_nearby_enemies(enemy, explosion_radius)

	for nearby_enemy in nearby_enemies:
		if nearby_enemy != enemy and nearby_enemy.has_method("take_damage"):
			var distance = enemy.global_position.distance_to(nearby_enemy.global_position)
			var damage_multiplier = 1.0 - (distance / explosion_radius)
			nearby_enemy.take_damage(projectile.get_scaled_damage() * damage_multiplier * 0.7)

	VisualEffectManager.create_explosion_visual(enemy.global_position, explosion_radius, sauce_resource.sauce_color)

# Special utility effects
func _apply_heal_effect(sauce_resource: BaseSauceResource):
	if PlayerStats.has_method("heal"):
		PlayerStats.heal(sauce_resource.damage * 0.2)

func _apply_multiply_effect(projectile: Area2D, enemy: Node2D, sauce_resource: BaseSauceResource):
	var split_count = int(sauce_resource.effect_intensity)
	for i in range(split_count):
		var split_projectile = projectile.duplicate()
		projectile.get_tree().current_scene.add_child(split_projectile)

		var angle_offset = (i - split_count/2.0) * 45.0
		var new_direction = Vector2.RIGHT.rotated(projectile.rotation + deg_to_rad(angle_offset))

		split_projectile.launch(
			projectile.global_position,
			new_direction,
			sauce_resource
		)

func _apply_magnetize_effect(enemy: Node2D, sauce_resource: BaseSauceResource):
	var nearby_enemies = _get_nearby_enemies(enemy, 300.0)
	for nearby_enemy in nearby_enemies:
		if nearby_enemy != enemy and nearby_enemy.has_method("apply_pull_force"):
			nearby_enemy.apply_pull_force(enemy.global_position, sauce_resource.effect_intensity * 500.0)

func _apply_shield_break_effect(enemy: Node2D, sauce_resource: BaseSauceResource):
	if enemy.has_method("break_shield"):
		enemy.break_shield()

func _apply_leech_effect(projectile: Area2D, sauce_resource: BaseSauceResource):
	if PlayerStats.has_method("heal"):
		PlayerStats.heal(projectile.get_scaled_damage() * 0.15)

func _apply_lightning_effect(projectile: Area2D, enemy: Node2D, sauce_resource: BaseSauceResource):
	var chain_distance = 250.0
	var chain_count = int(sauce_resource.effect_intensity)
	var current_target = enemy

	for i in range(chain_count):
		var next_enemies = _get_nearby_enemies(current_target, chain_distance)
		if next_enemies.is_empty():
			break

		var next_target = next_enemies[0]
		if next_target.has_method("take_damage"):
			next_target.take_damage(projectile.get_scaled_damage() * 0.5)

		VisualEffectManager.create_chain_visual(
			current_target.global_position,
			next_target.global_position,
			sauce_resource.sauce_color
		)
		current_target = next_target

func _apply_chaos_effect(projectile: Area2D, enemy: Node2D, sauce_resource: BaseSauceResource):
	var chaos_effects = [
		BaseSauceResource.SpecialEffectType.BURN,
		BaseSauceResource.SpecialEffectType.SLOW,
		BaseSauceResource.SpecialEffectType.FREEZE,
		BaseSauceResource.SpecialEffectType.EXPLODE,
		BaseSauceResource.SpecialEffectType.CHAIN,
		BaseSauceResource.SpecialEffectType.POISON,
		BaseSauceResource.SpecialEffectType.TORNADO
	]

	var original_effect = sauce_resource.special_effect_type
	sauce_resource.special_effect_type = chaos_effects[randi() % chaos_effects.size()]
	apply_effect(projectile, enemy, sauce_resource)
	sauce_resource.special_effect_type = original_effect

func _apply_mark_effect(enemy: Node2D, sauce_resource: BaseSauceResource):
	if enemy.has_method("apply_mark"):
		enemy.apply_mark(sauce_resource.effect_duration, sauce_resource.effect_intensity)

func _get_nearby_enemies(center_enemy: Node2D, radius: float) -> Array[Node2D]:
	var enemies: Array[Node2D] = []
	var bodies = center_enemy.get_tree().get_nodes_in_group("enemies")

	for body in bodies:
		if body != center_enemy and body.global_position.distance_to(center_enemy.global_position) <= radius:
			enemies.append(body)

	return enemies
