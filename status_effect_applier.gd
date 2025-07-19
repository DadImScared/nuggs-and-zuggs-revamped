# StatusEffectApplier.gd
# Generic system for applying status effects with custom callbacks
class_name StatusEffectApplier

# Simplified effect context - no redundant data
class EffectContext:
	var projectile: Area2D
	var enemy: Node2D
	var source_bottle: Node  # Contains sauce_resource, level, bottle_id
	var duration: float      # May be modified by talents
	var intensity: float     # May be modified by talents

	func _init(proj: Area2D, target: Node2D, bottle: Node, dur: float, inten: float):
		projectile = proj
		enemy = target
		source_bottle = bottle
		duration = dur
		intensity = inten

	# Convenience accessors for bottle data
	func get_sauce_resource() -> BaseSauceResource:
		return source_bottle.sauce_data if source_bottle else null

	func get_sauce_level() -> int:
		return source_bottle.sauce_level if source_bottle else 1

	func get_bottle_id() -> String:
		return source_bottle.bottle_id if source_bottle else "unknown"

	func get_sauce_color() -> Color:
		var sauce = get_sauce_resource()
		return sauce.sauce_color if sauce else Color.WHITE

# Function signature for effect callbacks
# Callable should take: (context: EffectContext) -> void
static func apply_effect_with_callback(context: EffectContext, custom_callback: Callable = Callable()) -> void:
	"""Apply an effect using either default method or custom callback"""

	if custom_callback.is_valid():
		# Use custom callback for specialized behavior
		custom_callback.call(context)
	else:
		# Fall back to standard status effect application
		_apply_default_status_effect(context)

static func _apply_default_status_effect(context: EffectContext) -> void:
	"""Default status effect application - figures out effect name from enum"""
	if not context.enemy.has_method("apply_status_effect"):
		return

	var sauce_resource = context.get_sauce_resource()
	if not sauce_resource:
		return

	var effect_name = _enum_to_effect_name(sauce_resource.special_effect_type)
	if effect_name != "unknown":
		context.enemy.apply_status_effect(
			effect_name,
			context.duration,
			context.intensity,
			context.get_bottle_id()
		)

static func _enum_to_effect_name(effect_type: BaseSauceResource.SpecialEffectType) -> String:
	"""Simple enum to string conversion - only for default effects"""
	match effect_type:
		BaseSauceResource.SpecialEffectType.BURN: return "burn"
		BaseSauceResource.SpecialEffectType.SLOW: return "slow"
		BaseSauceResource.SpecialEffectType.FREEZE: return "freeze"
		BaseSauceResource.SpecialEffectType.POISON: return "poison"
		BaseSauceResource.SpecialEffectType.STICKY: return "sticky"
		BaseSauceResource.SpecialEffectType.INFECT: return "infect"
		BaseSauceResource.SpecialEffectType.MARK: return "mark"
		_: return "unknown"

# Pre-built callbacks for common effect types
class EffectCallbacks:

	# Burn effect with DOT scaling
	static func burn_effect(context: StatusEffectApplier.EffectContext) -> void:
		if context.enemy.has_method("apply_status_effect"):
			context.enemy.apply_status_effect("burn", context.duration, context.intensity, context.get_bottle_id())

			# Apply burn visual if enemy supports it
			if context.enemy.has_property("active_effects") and "burn" in context.enemy.active_effects:
				context.enemy.active_effects["burn"]["color"] = context.get_sauce_color()

	# Infection with mutation support
	static func infection_effect(context: StatusEffectApplier.EffectContext) -> void:
		if not context.enemy.has_method("apply_status_effect"):
			return

		var final_intensity = context.intensity

		# Check for mutation stacking talent
		if TalentManager and TalentManager.has_talent("infection_mutation"):
			if context.enemy.has_method("has_status_effect") and context.enemy.has_status_effect("infect"):
				final_intensity *= 1.5  # 50% more damage when stacking

		context.enemy.apply_status_effect("infect", context.duration, final_intensity, context.get_bottle_id())

		# Set infection color
		if context.enemy.has_property("active_effects") and "infect" in context.enemy.active_effects:
			context.enemy.active_effects["infect"]["color"] = context.get_sauce_color()

	# Area damage effect (explosion)
	static func explosion_effect(context: StatusEffectApplier.EffectContext) -> void:
		var radius = 15.0 * context.intensity
		var damage = context.projectile.get_scaled_damage() * 0.7 if context.projectile.has_method("get_scaled_damage") else context.intensity * 0.7

		var nearby_enemies = _get_nearby_enemies(context.enemy, radius)
		for nearby_enemy in nearby_enemies:
			if nearby_enemy != context.enemy:
				var distance = context.enemy.global_position.distance_to(nearby_enemy.global_position)
				var falloff = 1.0 - (distance / radius)
				var final_damage = damage * falloff

				if nearby_enemy.has_method("take_damage_from_source"):
					nearby_enemy.take_damage_from_source(final_damage, context.get_bottle_id())
				elif nearby_enemy.has_method("take_damage"):
					nearby_enemy.take_damage(final_damage)

		# Create explosion visual
		VisualEffectManager.create_explosion_visual(context.enemy.global_position, radius, context.get_sauce_color())

	# Chain effect callback
	static func chain_effect(context: StatusEffectApplier.EffectContext) -> void:
		var chain_distance = 60.0
		var max_chains = int(context.intensity)
		var damage = context.projectile.get_scaled_damage() * 0.6 if context.projectile.has_method("get_scaled_damage") else context.intensity * 0.6

		var nearby_enemies = _get_nearby_enemies(context.enemy, chain_distance)
		var chains_used = 0

		for nearby_enemy in nearby_enemies:
			if nearby_enemy != context.enemy and chains_used < max_chains:
				if nearby_enemy.has_method("take_damage_from_source"):
					nearby_enemy.take_damage_from_source(damage, context.get_bottle_id())
				elif nearby_enemy.has_method("take_damage"):
					nearby_enemy.take_damage(damage)

				# Create visual chain
				VisualEffectManager.create_chain_visual(
					context.enemy.global_position,
					nearby_enemy.global_position,
					context.get_sauce_color()
				)

				chains_used += 1

	# Helper function to get nearby enemies
	static func _get_nearby_enemies(center_enemy: Node2D, radius: float) -> Array[Node2D]:
		var enemies: Array[Node2D] = []
		var bodies = center_enemy.get_tree().get_nodes_in_group("enemies")

		for body in bodies:
			if body != center_enemy and body.global_position.distance_to(center_enemy.global_position) <= radius:
				enemies.append(body)

		return enemies
