extends Node

# NEW: Effect callback registry for custom effects
var effect_callbacks: Dictionary = {}

# NEW: Initialize callback system
func _ready():
	_register_effect_callbacks()

# NEW: Register custom effect callbacks
func _register_effect_callbacks():
	"""Register custom effect callbacks - effects not registered here use legacy system"""
	# Example: Replace burn with enhanced version
	# effect_callbacks[BaseSauceResource.SpecialEffectType.BURN] = StatusEffectApplier.EffectCallbacks.enhanced_burn_effect

	# Add custom effects here as you create them
	# effect_callbacks[BaseSauceResource.SpecialEffectType.CUSTOM_1] = my_custom_callback

func apply_effect(
	projectile: Area2D, enemy: Node2D, sauce_resource: BaseSauceResource,
	sauce_level: int = 1, source_bottle_id: String = "unknown",
	effective_chance: float = -1.0, effective_intensity: float = -1.0,
	source_bottle: ImprovedBaseSauceBottle = null
):
	if not sauce_resource or sauce_resource.special_effect_type == BaseSauceResource.SpecialEffectType.NONE:
		return

	# Use provided effective values or fall back to base resource
	var current_effect_chance: float
	var current_effect_intensity: float

	if source_bottle:
		# Use bottle's effective stats (includes talents!)
		current_effect_chance = source_bottle.effective_effect_chance
		current_effect_intensity = source_bottle.effective_effect_intensity
	else:
		# Fallback for projectiles without bottle reference
		current_effect_chance = sauce_resource.get_current_effect_chance(sauce_level)
		current_effect_intensity = sauce_resource.get_current_effect_intensity(sauce_level)

	# Check if effect triggers using effective chance
	if randf() > current_effect_chance:
		return

	# NEW: Check if we have a custom callback for this effect
	var effect_type = sauce_resource.special_effect_type
	if effect_callbacks.has(effect_type):
		#print("🆕 Using custom callback for: %s" % BaseSauceResource.SpecialEffectType.keys()[effect_type])

		# Create context and use callback system
		var context = StatusEffectApplier.EffectContext.new(
			projectile, enemy, source_bottle,
			sauce_resource.effect_duration, current_effect_intensity
		)

		var callback = effect_callbacks[effect_type]
		StatusEffectApplier.apply_effect_with_callback(context, callback)
		return

	# Try modular sauce action system first
	var handled_by_modular = SauceActionManager.apply_sauce_action(
		sauce_resource.special_effect_type,
		projectile,
		enemy,
		source_bottle
	)

	if handled_by_modular:
		#print("✅ Sauce action handled by modular system: %s" % BaseSauceResource.SpecialEffectType.keys()[sauce_resource.special_effect_type])
		return

	# FALLBACK: Use your existing legacy effect system
	#print("⚠️ Using legacy effect system for: %s" % BaseSauceResource.SpecialEffectType.keys()[sauce_resource.special_effect_type])

	match sauce_resource.special_effect_type:
		BaseSauceResource.SpecialEffectType.TORNADO:
			_apply_tornado_effect(projectile, enemy, sauce_resource, sauce_level, source_bottle_id)
		BaseSauceResource.SpecialEffectType.INFECT:
			_apply_infect_effect(enemy, sauce_resource, sauce_level, source_bottle_id, current_effect_intensity)
		BaseSauceResource.SpecialEffectType.BURN:
			_apply_burn_effect(enemy, sauce_resource, sauce_level, source_bottle_id)
		BaseSauceResource.SpecialEffectType.SLOW:
			_apply_slow_effect(enemy, sauce_resource, sauce_level, source_bottle_id)
		BaseSauceResource.SpecialEffectType.STICKY:
			_apply_sticky_effect(enemy, sauce_resource, sauce_level, source_bottle_id)
		BaseSauceResource.SpecialEffectType.POISON:
			_apply_poison_effect(enemy, sauce_resource, sauce_level, source_bottle_id)
		BaseSauceResource.SpecialEffectType.FREEZE:
			pass
			#_apply_freeze_effect(enemy, sauce_resource, sauce_level, source_bottle_id)
		BaseSauceResource.SpecialEffectType.CHAIN:
			_apply_chain_effect(projectile, enemy, sauce_resource, sauce_level, source_bottle_id)
		BaseSauceResource.SpecialEffectType.EXPLODE:
			_apply_explosion_effect(projectile, enemy, sauce_resource, sauce_level, source_bottle_id)
		BaseSauceResource.SpecialEffectType.HEAL:
			_apply_heal_effect(sauce_resource, sauce_level)
		BaseSauceResource.SpecialEffectType.MULTIPLY:
			_apply_multiply_effect(projectile, enemy, sauce_resource, sauce_level, source_bottle_id)
		BaseSauceResource.SpecialEffectType.MAGNETIZE:
			_apply_magnetize_effect(enemy, sauce_resource, sauce_level, source_bottle_id)
		BaseSauceResource.SpecialEffectType.SHIELD_BREAK:
			_apply_shield_break_effect(enemy, sauce_resource, sauce_level, source_bottle_id)
		BaseSauceResource.SpecialEffectType.LEECH:
			_apply_leech_effect(projectile, sauce_resource, sauce_level)
		BaseSauceResource.SpecialEffectType.LIGHTNING:
			_apply_lightning_effect(projectile, enemy, sauce_resource, sauce_level, source_bottle_id)
		BaseSauceResource.SpecialEffectType.CHAOS:
			_apply_chaos_effect(projectile, enemy, sauce_resource, sauce_level, source_bottle_id)
		BaseSauceResource.SpecialEffectType.MARK:
			_apply_mark_effect(enemy, sauce_resource, sauce_level, source_bottle_id)
		BaseSauceResource.SpecialEffectType.VOLCANIC_RING:
			_apply_volcanic_ring_effect(projectile, enemy, source_bottle)

# NEW: Utility functions for the callback system
func register_custom_effect(effect_type: BaseSauceResource.SpecialEffectType, callback: Callable):
	"""Register a custom effect callback - will override legacy behavior for that effect"""
	effect_callbacks[effect_type] = callback
	#print("🆕 Registered custom callback for: ", BaseSauceResource.SpecialEffectType.keys()[effect_type])

func apply_custom_effect(
	projectile: Area2D,
	enemy: Node2D,
	source_bottle: Node,
	custom_callback: Callable,
	override_intensity: float = -1.0,
	override_duration: float = -1.0
):
	"""Apply a custom effect directly"""
	var sauce_resource = source_bottle.sauce_data if source_bottle else null
	if not sauce_resource:
		return

	var intensity = override_intensity if override_intensity >= 0 else sauce_resource.get_current_effect_intensity(1)
	var duration = override_duration if override_duration >= 0 else sauce_resource.effect_duration

	var context = StatusEffectApplier.EffectContext.new(
		projectile, enemy, source_bottle, duration, intensity
	)

	StatusEffectApplier.apply_effect_with_callback(context, custom_callback)

# ALL YOUR EXISTING LEGACY FUNCTIONS STAY THE SAME BELOW THIS LINE
# No changes needed to any of your existing effect functions

func _apply_volcanic_ring_effect(projectile, enemy, bottle: ImprovedBaseSauceBottle):
	var effect_intensity = bottle.effective_effect_intensity
	var ring_damage = bottle.effective_damage * 0.6
	var ring_position = enemy.global_position
	var ring_duration = bottle.sauce_data.effect_duration
	var max_radius = 120.0 + (effect_intensity * 30.0)

	var ring = preload("res://Effects/MiniVolcanoRing/volcanic_ring.tscn").instantiate()
	ring.global_position = ring_position
	ring.setup_ring(ring_damage, max_radius, ring_duration, bottle.bottle_id)
	get_tree().current_scene.add_child(ring)

	#print("🌋 Volcanic ring created at %s with %.1f damage and %.0f max radius" % [ring_position, ring_damage, max_radius])

func _apply_tornado_effect(projectile: Area2D, enemy: Node2D, sauce_resource: BaseSauceResource, sauce_level: int, source_bottle_id: String):
	var current_intensity = sauce_resource.get_current_effect_intensity(sauce_level)
	VisualEffectManager.create_tornado(
		enemy.global_position,
		sauce_resource.effect_duration,
		current_intensity,
		projectile.get_scaled_damage() * 0.3,
		sauce_resource.sauce_color
	)

func _apply_infect_effect(enemy: Node2D, sauce_resource: BaseSauceResource, sauce_level: int, source_bottle_id: String, effect_intensity):
	var current_intensity = sauce_resource.get_current_effect_intensity(sauce_level)
	if enemy.has_method("apply_status_effect"):
		enemy.apply_status_effect("infect", sauce_resource.effect_duration, effect_intensity, source_bottle_id)
		if "infect" in enemy.active_effects:
			enemy.active_effects["infect"]["color"] = sauce_resource.sauce_color

# Status effect applications with leveled intensity
func _apply_burn_effect(enemy: Node2D, sauce_resource: BaseSauceResource, sauce_level: int, source_bottle_id: String):
	var current_intensity = sauce_resource.get_current_effect_intensity(sauce_level)
	if enemy.has_method("apply_status_effect"):
		enemy.apply_status_effect("burn", sauce_resource.effect_duration, current_intensity, source_bottle_id)

func _apply_slow_effect(enemy: Node2D, sauce_resource: BaseSauceResource, sauce_level: int, source_bottle_id: String):
	var current_intensity = sauce_resource.get_current_effect_intensity(sauce_level)
	if enemy.has_method("apply_status_effect"):
		enemy.apply_status_effect("slow", sauce_resource.effect_duration, current_intensity, source_bottle_id)

func _apply_sticky_effect(enemy: Node2D, sauce_resource: BaseSauceResource, sauce_level: int, source_bottle_id: String):
	var current_intensity = sauce_resource.get_current_effect_intensity(sauce_level)
	if enemy.has_method("apply_status_effect"):
		enemy.apply_status_effect("sticky", sauce_resource.effect_duration, current_intensity, source_bottle_id)

func _apply_poison_effect(enemy: Node2D, sauce_resource: BaseSauceResource, sauce_level: int, source_bottle_id: String):
	var current_intensity = sauce_resource.get_current_effect_intensity(sauce_level)
	if enemy.has_method("apply_status_effect"):
		enemy.apply_status_effect("poison", sauce_resource.effect_duration, current_intensity, source_bottle_id)

func _apply_freeze_effect(enemy: Node2D, sauce_resource: BaseSauceResource, sauce_level: int, source_bottle_id: String):
	var current_intensity = sauce_resource.get_current_effect_intensity(sauce_level)
	if enemy.has_method("apply_status_effect"):
		enemy.apply_status_effect("freeze", sauce_resource.effect_duration, current_intensity, source_bottle_id)

# Area effects with source attribution
func _apply_chain_effect(projectile: Area2D, enemy: Node2D, sauce_resource: BaseSauceResource, sauce_level: int, source_bottle_id: String):
	var chain_distance = 60.0
	var current_intensity = sauce_resource.get_current_effect_intensity(sauce_level)
	var max_chains = int(current_intensity)
	var chain_targets = []
	var nearby_enemies = _get_nearby_enemies(enemy, chain_distance)

	var chains_used = 0
	for nearby_enemy in nearby_enemies:
		if nearby_enemy != enemy and nearby_enemy not in chain_targets:
			chain_targets.append(nearby_enemy)
			if nearby_enemy.has_method("take_damage_from_source"):
				nearby_enemy.take_damage_from_source(projectile.get_scaled_damage() * 0.6, source_bottle_id)
			elif nearby_enemy.has_method("take_damage"):
				nearby_enemy.take_damage(projectile.get_scaled_damage() * 0.6)

			VisualEffectManager.create_chain_visual(
				enemy.global_position,
				nearby_enemy.global_position,
				sauce_resource.sauce_color
			)

			chains_used += 1
			if chains_used >= max_chains:
				break

func _apply_explosion_effect(projectile: Area2D, enemy: Node2D, sauce_resource: BaseSauceResource, sauce_level: int, source_bottle_id: String):
	var current_intensity = sauce_resource.get_current_effect_intensity(sauce_level)
	var explosion_radius = 15.0 * current_intensity
	var nearby_enemies = _get_nearby_enemies(enemy, explosion_radius)

	for nearby_enemy in nearby_enemies:
		if nearby_enemy != enemy:
			if nearby_enemy.has_method("take_damage_from_source"):
				var distance = enemy.global_position.distance_to(nearby_enemy.global_position)
				var damage_multiplier = 1.0 - (distance / explosion_radius)
				nearby_enemy.take_damage_from_source(projectile.get_scaled_damage() * damage_multiplier * 0.7, source_bottle_id)
			elif nearby_enemy.has_method("take_damage"):
				var distance = enemy.global_position.distance_to(nearby_enemy.global_position)
				var damage_multiplier = 1.0 - (distance / explosion_radius)
				nearby_enemy.take_damage(projectile.get_scaled_damage() * damage_multiplier * 0.7)

	VisualEffectManager.create_explosion_visual(enemy.global_position, explosion_radius, sauce_resource.sauce_color)

# Special utility effects
func _apply_heal_effect(sauce_resource: BaseSauceResource, sauce_level: int):
	if PlayerStats.has_method("heal"):
		var heal_amount = sauce_resource.get_current_damage(sauce_level) * 0.2
		PlayerStats.heal(heal_amount)

func _apply_multiply_effect(projectile: Area2D, enemy: Node2D, sauce_resource: BaseSauceResource, sauce_level: int, source_bottle_id: String):
	var current_intensity = sauce_resource.get_current_effect_intensity(sauce_level)
	var split_count = int(current_intensity)
	for i in range(split_count):
		var split_projectile = projectile.duplicate()
		projectile.get_tree().current_scene.add_child(split_projectile)

		var angle_offset = (i - split_count/2.0) * 45.0
		var new_direction = Vector2.RIGHT.rotated(projectile.rotation + deg_to_rad(angle_offset))

		split_projectile.launch(
			projectile.global_position,
			new_direction,
			sauce_resource,
			sauce_level,
			source_bottle_id
		)

func _apply_magnetize_effect(enemy: Node2D, sauce_resource: BaseSauceResource, sauce_level: int, source_bottle_id: String):
	var current_intensity = sauce_resource.get_current_effect_intensity(sauce_level)
	var nearby_enemies = _get_nearby_enemies(enemy, 300.0)
	for nearby_enemy in nearby_enemies:
		if nearby_enemy != enemy and nearby_enemy.has_method("apply_pull_force"):
			nearby_enemy.apply_pull_force(enemy.global_position, current_intensity * 500.0)

func _apply_shield_break_effect(enemy: Node2D, sauce_resource: BaseSauceResource, sauce_level: int, source_bottle_id: String):
	if enemy.has_method("break_shield"):
		enemy.break_shield()

func _apply_leech_effect(projectile: Area2D, sauce_resource: BaseSauceResource, sauce_level: int):
	if PlayerStats.has_method("heal"):
		PlayerStats.heal(projectile.get_scaled_damage() * 0.15)

func _apply_lightning_effect(projectile: Area2D, enemy: Node2D, sauce_resource: BaseSauceResource, sauce_level: int, source_bottle_id: String):
	var chain_distance = 250.0
	var current_intensity = sauce_resource.get_current_effect_intensity(sauce_level)
	var chain_count = int(current_intensity)
	var current_target = enemy

	for i in range(chain_count):
		var next_enemies = _get_nearby_enemies(current_target, chain_distance)
		if next_enemies.is_empty():
			break

		var next_target = next_enemies[0]
		if next_target.has_method("take_damage_from_source"):
			next_target.take_damage_from_source(projectile.get_scaled_damage() * 0.5, source_bottle_id)
		elif next_target.has_method("take_damage"):
			next_target.take_damage(projectile.get_scaled_damage() * 0.5)

		VisualEffectManager.create_chain_visual(
			current_target.global_position,
			next_target.global_position,
			sauce_resource.sauce_color
		)
		current_target = next_target

func _apply_chaos_effect(projectile: Area2D, enemy: Node2D, sauce_resource: BaseSauceResource, sauce_level: int, source_bottle_id: String):
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
	apply_effect(projectile, enemy, sauce_resource, sauce_level, source_bottle_id)
	sauce_resource.special_effect_type = original_effect

func _apply_mark_effect(enemy: Node2D, sauce_resource: BaseSauceResource, sauce_level: int, source_bottle_id: String):
	var current_intensity = sauce_resource.get_current_effect_intensity(sauce_level)
	if enemy.has_method("apply_mark"):
		enemy.apply_mark(sauce_resource.effect_duration, current_intensity)

func _get_nearby_enemies(center_enemy: Node2D, radius: float) -> Array[Node2D]:
	var enemies: Array[Node2D] = []
	var bodies = center_enemy.get_tree().get_nodes_in_group("enemies")

	for body in bodies:
		if body != center_enemy and body.global_position.distance_to(center_enemy.global_position) <= radius:
			enemies.append(body)

	return enemies
