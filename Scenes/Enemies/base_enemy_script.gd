# Scenes/Enemies/base_enemy_script.gd
extends CharacterBody2D

signal died(xp_amount: int, damage_sources: Dictionary)
signal debuff_xp_earned(bottle_id: String, xp_amount: int)

@onready var player = get_node("/root/Game/Player")
@onready var health_bar_container = $HealthBarContainer
@onready var health_bar = $HealthBarContainer/HealthBar
@onready var animated_sprite = $AnimatedSprite2D

var external_velocity_override: bool = false
var external_velocity: Vector2 = Vector2.ZERO

var health_bar_timer = 0.0
var health_bar_duration = 3.0

var base_xp_reward = 5
var base_health = 100
var base_damage = 10
var base_speed = 18.0
var max_health = 0

var damage = 10
var xp_on_kill = 5
var move_speed = 18.0
var health = 100

# Damage tracking for XP distribution
var damage_sources: Dictionary = {}
var total_damage_taken: float = 0.0

# Debuff XP tracking
var debuff_periodic_timer: float = 0.0
var debuff_periodic_interval: float = 1.0
var debuff_xp_per_tick: int = 2

var active_effects = {}
var original_speed: float
var is_marked: bool = false
var mark_damage_multiplier: float = 1.0
var has_shield: bool = false
var shield_health: float = 0.0

var is_playing_hit_animation = false
var enemy_resource: BaseEnemyResource
var stacking_effects = {}

func _ready() -> void:
	if animated_sprite:
		animated_sprite.connect("animation_finished", _on_animation_finished)
		animated_sprite.play("move")

	scale_to_player_level()
	setup_health_bar()
	setup_default_stats()
	original_speed = move_speed

	if enemy_resource:
		setup_from_resource()

func setup_from_resource():
	if not enemy_resource:
		return

	# Set base stats from resource
	health = enemy_resource.base_health
	max_health = health
	move_speed = enemy_resource.base_speed
	damage = enemy_resource.base_damage
	xp_on_kill = enemy_resource.base_xp_reward

	# Scale stats to player level
	scale_to_player_level()

	# Apply scale modifier from resource
	scale = Vector2.ONE * enemy_resource.scale_modifier

	# Apply color if we have one and the resource wants us to
	if enemy_resource.apply_color_tint:
		animated_sprite.modulate = enemy_resource.enemy_color

	# Set animation speed if we have animations
	if animated_sprite:
		animated_sprite.speed_scale = enemy_resource.animation_speed_multiplier

	print("%s stats - Health: %d, Speed: %.1f, Damage: %.1f, Scale: %.3f" % [enemy_resource.enemy_name, health, move_speed, damage, enemy_resource.scale_modifier])

func setup_default_stats():
	# Fallback stats
	health = 30
	max_health = health
	move_speed = 18.0
	damage = 10
	xp_on_kill = 5

func set_enemy_resource(resource: BaseEnemyResource):
	enemy_resource = resource
	if is_inside_tree():
		setup_from_resource()

func setup_health_bar():
	health_bar.max_value = max_health
	health_bar.value = health

func _process(delta):
	# Handle health bar visibility
	if health_bar_timer > 0:
		health_bar_timer -= delta
		if health_bar_timer <= 0:
			health_bar_container.visible = false

	process_status_effects(delta)
	process_debuff_periodic_xp(delta)
	_process_stacking_effects(delta)  # Process stacking effects

func _physics_process(delta: float) -> void:
	if external_velocity_override:
		velocity = external_velocity
		external_velocity_override = false
	else:
		if player and is_instance_valid(player):
			var direction = global_position.direction_to(player.global_position)
			velocity = direction * move_speed

			# Make enemy face the direction it's moving
			if direction.length() > 0:
				if direction.x < 0:
					animated_sprite.flip_h = true
				else:
					animated_sprite.flip_h = false
				animated_sprite.rotation = 0

	move_and_slide()

func _process_death_triggers():
	"""Process ON_ENEMY_DEATH triggers for all bottles that contributed damage"""
	# Create death event data
	var death_data = {
		"enemy_position": global_position,
		"enemy_health": max_health,
		"damage_sources": damage_sources,
		"killed_enemy": self
	}

	# Notify all bottles that damaged this enemy about the death
	for bottle_id in damage_sources.keys():
		var bottle = InventoryManager.get_bottle_by_id(bottle_id)
		if bottle:
			# Execute any ON_ENEMY_DEATH triggers on this bottle
			TriggerActionManager.execute_event_trigger(
				bottle,
				TriggerEffectResource.TriggerType.ON_ENEMY_DEATH,
				death_data
			)
			print("💀 Processing death triggers for bottle: %s" % bottle.sauce_data.sauce_name)

func process_status_effects(delta: float):
	var effects_to_remove = []

	for effect_name in active_effects.keys():
		var effect = active_effects[effect_name]
		effect.timer += delta
		var bottle_id = effect.get("source_bottle_id", "unknown")

		# Apply enemy-specific resistances to ALL DOT effects
		match effect_name:
			"burn":
				if effect.timer >= 1.0:
					var resistance = enemy_resource.burn_resistance if enemy_resource else 1.0
					var burn_damage = effect.intensity * 5.0 * resistance
					var source_id = effect.get("source_bottle_id", "unknown")
					take_damage_from_source(burn_damage, source_id)
					effect.timer = 0.0
			"poison":
				if effect.timer >= 0.5:
					var resistance = enemy_resource.poison_resistance if enemy_resource else 1.0
					var poison_damage = effect.intensity * 3.0 * resistance
					var source_id = effect.get("source_bottle_id", "unknown")
					take_damage_from_source(poison_damage, source_id)
					effect.timer = 0.0
			"infect":
				effect.tick_timer = effect.get("tick_timer", 0.0) + delta
				if effect.tick_timer >= 0.5:
					effect.tick_timer = 0.0
					var infect_damage = effect.intensity * 2.0
					var source_id = effect.get("source_bottle_id", "unknown")
					take_damage_from_source(infect_damage, source_id)
			_:
				take_damage_from_source(effect.intensity, bottle_id)

		_execute_dot_tick_trigger(bottle_id, effect_name, effect.intensity * 2.0)
		# Remove expired effects
		if effect.timer >= effect.duration:
			effects_to_remove.append(effect_name)

	# Clean up expired effects
	for effect_name in effects_to_remove:
		remove_status_effect(effect_name)

func process_debuff_periodic_xp(delta: float):
	debuff_periodic_timer += delta
	if debuff_periodic_timer >= debuff_periodic_interval:
		debuff_periodic_timer = 0.0

		# Give XP only to pure debuffs (not DOTs)
		for effect_name in active_effects.keys():
			var effect = active_effects[effect_name]
			if is_pure_debuff_effect(effect_name) and effect.has("source_bottle_id"):
				var bottle_id = effect.source_bottle_id
				debuff_xp_earned.emit(bottle_id, debuff_xp_per_tick)

func is_pure_debuff_effect(effect_name: String) -> bool:
	return effect_name in ["slow", "freeze", "sticky"]

func is_dot_effect(effect_name: String) -> bool:
	return effect_name in ["burn", "poison", "infect"]

func is_debuff_effect(effect_name: String) -> bool:
	return is_pure_debuff_effect(effect_name) or is_dot_effect(effect_name)

func apply_status_effect(effect_name: String, duration: float, intensity: float, source_bottle_id: String = "unknown", cleanup_callback: Callable = Callable()):
	# Apply enemy resistances
	var source_bottle = InventoryManager.get_bottle_by_id(source_bottle_id)
	var actual_intensity = intensity
	var actual_duration = duration
	var spread_radius = 120

	if effect_name == "infect":
		if not "total_infections_this_run" in PlayerStats:
			PlayerStats.total_infections_this_run = 0

		PlayerStats.total_infections_this_run += 1
		print("🦠 Infection applied! Total this run: %d" % PlayerStats.total_infections_this_run)

	if source_bottle and source_bottle.special_effects:
		for effect in source_bottle.special_effects:
			# Persistent Strain - duration boost
			if effect.effect_name == "infection_duration_boost":
				var duration_multiplier = effect.get_parameter("duration_multiplier", 1.5)
				actual_duration = duration * duration_multiplier
				print("🦠 Persistent Strain: Duration %.1fs → %.1fs" % [duration, actual_duration])

			# Enhanced Transmission - radius boost
			elif effect.effect_name == "infection_radius_boost":
				var radius_multiplier = effect.get_parameter("radius_multiplier", 1.5)
				spread_radius = spread_radius * radius_multiplier
				print("🦠 Enhanced Transmission: Spread radius %.0f → %.0f" % [120.0, spread_radius])

	if enemy_resource:
		match effect_name:
			"slow":
				actual_intensity *= (2.0 - enemy_resource.slow_resistance)
				actual_duration *= (2.0 - enemy_resource.slow_resistance)
			"freeze":
				actual_intensity *= (2.0 - enemy_resource.freeze_resistance)
				actual_duration *= (2.0 - enemy_resource.freeze_resistance)
			"burn":
				actual_intensity *= enemy_resource.burn_resistance
				actual_duration *= (2.0 - enemy_resource.burn_resistance)
			"poison":
				actual_intensity *= enemy_resource.poison_resistance
				actual_duration *= (2.0 - enemy_resource.poison_resistance)

	active_effects[effect_name] = {
		"duration": actual_duration,
		"intensity": actual_intensity,
		"timer": 0.0,
		"source_bottle_id": source_bottle_id,
		"spread_radius": spread_radius,
		"cleanup": cleanup_callback  # Store cleanup callback
	}

	# Apply immediate visual/movement effects
	match effect_name:
		"slow":
			move_speed = original_speed * (1.0 - actual_intensity * 0.5)
			animated_sprite.modulate = Color(0.7, 0.7, 1.0) # Blue tint
		"freeze":
			move_speed = 0
			animated_sprite.modulate = Color(0.8, 0.8, 1.0) # Light blue tint
		"sticky":
			move_speed = original_speed * 0.2
			animated_sprite.modulate = Color(1.0, 1.0, 0.6) # Yellow tint
		"burn":
			animated_sprite.modulate = Color(1.2, 0.8, 0.8) # Red tint
		"poison":
			animated_sprite.modulate = Color(0.8, 1.0, 0.8) # Green tint
		"infect":
			active_effects[effect_name]["tick_timer"] = 0.0
			animated_sprite.modulate = Color(0.8, 1.2, 0.8) # Bright green

func remove_status_effect(effect_name: String):
	if effect_name in active_effects:
		# Execute cleanup if it exists
		var effect_data = active_effects[effect_name]
		if effect_data.has("cleanup") and effect_data.cleanup.is_valid():
			effect_data.cleanup.call()
			print("🧹 Executed cleanup for: %s" % effect_name)

		# Existing removal logic
		match effect_name:
			"slow":
				move_speed = original_speed
			"freeze":
				move_speed = original_speed
			"sticky":
				move_speed = original_speed

		active_effects.erase(effect_name)

		# Reset visual effects if no other effects remain
		if active_effects.is_empty():
			if animated_sprite and enemy_resource and enemy_resource.apply_color_tint:
				animated_sprite.modulate = enemy_resource.enemy_color
			elif animated_sprite:
				animated_sprite.modulate = Color.WHITE

# ENHANCED: Stacking system with cleanup support
func apply_stacking_effect(effect_name: String, base_value: float, max_stacks: int, source_bottle_id: String, duration: float = 10.0, effect_data: Dictionary = {}) -> int:
	"""
	Universal stacking system with per-bottle tracking and cleanup support
	Returns current stack count after application
	"""
	# Create unique effect key: effect_name + bottle_id
	var unique_effect_key = effect_name + "_" + source_bottle_id

	# Initialize effect if it doesn't exist
	if not stacking_effects.has(unique_effect_key):
		stacking_effects[unique_effect_key] = {
			"stacks": 0,
			"base_value": base_value,
			"max_stacks": max_stacks,
			"source_bottle_id": source_bottle_id,
			"effect_type": effect_name,
			"duration": duration,
			"timer": 0.0,
			"effect_data": effect_data  # Store cleanup and other data
		}

	var effect = stacking_effects[unique_effect_key]

	# Add stack (up to max)
	effect.stacks = min(effect.stacks + 1, max_stacks)
	effect.timer = 0.0  # Reset duration
	effect.base_value = max(effect.base_value, base_value)  # Use highest base value

	# Update effect_data if provided
	if not effect_data.is_empty():
		effect.effect_data = effect_data

	# Apply the stacking effect
	_apply_stack_behavior(effect.effect_type, effect, source_bottle_id)

	print("📈 %s gained %s stack %d/%d from bottle %s (%.1f base value)" % [
		name, effect_name, effect.stacks, max_stacks, source_bottle_id, base_value
	])

	return effect.stacks

func _process_stacking_effects(delta: float):
	"""Process stacking effect timers and tick effects"""
	var effects_to_remove = []

	for effect_key in stacking_effects.keys():
		var effect = stacking_effects[effect_key]
		effect.timer += delta

		# GENERIC: Handle tick effects if provided
		if effect.has("effect_data") and effect.effect_data.has("tick_effect"):
			var tick_effect = effect.effect_data.tick_effect
			var tick_interval = effect.effect_data.get("tick_interval", 1.0)  # Default 1 second

			# Initialize tick timer if not exists
			if not effect.has("tick_timer"):
				effect.tick_timer = 0.0

			effect.tick_timer += delta

			# Execute tick effect
			if effect.tick_timer >= tick_interval and tick_effect.is_valid():
				tick_effect.call()
				effect.tick_timer = 0.0  # Reset tick timer

		# Remove if expired
		if effect.timer >= effect.duration:
			_cleanup_stack_behavior(effect.effect_type, effect, effect.source_bottle_id)
			effects_to_remove.append(effect_key)

	# Clean up expired effects
	for effect_key in effects_to_remove:
		stacking_effects.erase(effect_key)

func _cleanup_stack_behavior(effect_name: String, effect_data: Dictionary, source_bottle_id: String):
	"""Clean up when stacking effect expires - fully generic"""

	# GENERIC: Handle visual cleanup for any stacking effect
	if effect_data.has("effect_data") and effect_data.effect_data.has("visual_cleanup"):
		var visual_cleanup = effect_data.effect_data.visual_cleanup
		if visual_cleanup.is_valid():
			# Only run visual cleanup when this is the LAST stack
			if get_total_stack_count(effect_name) == 1:  # About to become 0
				visual_cleanup.call()
				print("🧹 Executed visual cleanup for: %s" % effect_name)

	# GENERIC: Handle mechanical cleanup if provided
	if effect_data.has("effect_data") and effect_data.effect_data.has("mechanical_cleanup"):
		var mechanical_cleanup = effect_data.effect_data.mechanical_cleanup
		if mechanical_cleanup.is_valid():
			mechanical_cleanup.call()
			print("🧹 Executed mechanical cleanup for: %s" % effect_name)

# Rest of your existing functions...
func scale_to_player_level():
	if PlayerStats.level < 2:
		max_health = base_health
		return
	var base_scale = 1.0 + (PlayerStats.level - 1)
	var health_scale = base_scale * 1.1
	var speed_scale = base_scale * 0.02
	var xp_scale = base_scale * 0.10
	var damage_scale = base_scale * 0.4

	health = base_health + (base_health * health_scale)
	max_health = health
	move_speed = base_speed + (base_speed * speed_scale)
	xp_on_kill = base_xp_reward + (base_xp_reward * xp_scale)
	damage = base_damage + (base_damage * damage_scale)

func take_damage_from_source(damage_amount: float, source_bottle_id: String):
	"""Enhanced damage function that applies stacking multipliers"""
	var actual_damage = damage_amount

	# Apply resistances from enemy resource
	if enemy_resource:
		if "burn" in str(source_bottle_id).to_lower():
			actual_damage *= enemy_resource.burn_resistance
		elif "poison" in str(source_bottle_id).to_lower():
			actual_damage *= enemy_resource.poison_resistance

	# Apply vulnerability stacking from all bottles
	if has_meta("vulnerability_multiplier"):
		var old_damage = actual_damage
		actual_damage *= get_meta("vulnerability_multiplier")
		print("💀 Vulnerability: %.1f → %.1f damage" % [old_damage, actual_damage])

	# Apply damage amplification stacking from all bottles
	if has_meta("damage_amplification"):
		var bonus_damage = actual_damage * get_meta("damage_amplification")
		actual_damage += bonus_damage
		print("⚡ Amplified: +%.1f bonus damage" % bonus_damage)

	# Rest of existing damage logic...
	health -= actual_damage
	health_bar.value = health
	health_bar_container.visible = true
	health_bar_timer = health_bar_duration

	# Track damage for XP distribution
	if not damage_sources.has(source_bottle_id):
		damage_sources[source_bottle_id] = 0.0
	damage_sources[source_bottle_id] += actual_damage
	total_damage_taken += actual_damage

	# Play hit animation
	play_hit_animation()

	if health <= 0:
		if "infect" in active_effects:
			spread_infection_on_death()
		_process_death_triggers()
		var enemy_name = enemy_resource.enemy_name if enemy_resource else "Enemy"
		print("%s died! Took %.1f total damage" % [enemy_name, total_damage_taken])
		queue_free()
		emit_signal("died", xp_on_kill, damage_sources)

# Helper functions for stacking system
func get_total_stack_count(effect_name: String) -> int:
	"""Get total stack count across all bottles for an effect type"""
	var total_stacks = 0
	for key in stacking_effects.keys():
		if key.begins_with(effect_name + "_"):
			total_stacks += stacking_effects[key].stacks
	return total_stacks

func get_total_stacked_value(effect_name: String) -> float:
	"""Get total stacked value across all bottles for an effect type"""
	var total_value = 0.0
	for key in stacking_effects.keys():
		if key.begins_with(effect_name + "_"):
			var effect = stacking_effects[key]
			total_value += effect.base_value * effect.stacks
	return total_value

# Include all your other existing functions...
func _apply_stack_behavior(effect_name: String, effect_data: Dictionary, source_bottle_id: String):
	"""Apply immediate effects when stacks are added - fully generic"""

	# GENERIC: Call immediate effect callback if provided
	if effect_data.has("effect_data") and effect_data.effect_data.has("immediate_effect"):
		var immediate_effect = effect_data.effect_data.immediate_effect
		if immediate_effect.is_valid():
			immediate_effect.call()
			print("⚡ Applied immediate effect for: %s" % effect_name)

func _apply_generic_stacking(effect_name: String, stacked_value: float, effect_data: Dictionary, source_bottle_id: String):
	pass  # Can be empty now

func apply_external_velocity(new_velocity: Vector2):
	external_velocity = new_velocity
	external_velocity_override = true

func take_damage(damage_amount: float):
	take_damage_from_source(damage_amount, "unknown")

func play_hit_animation():
	if not animated_sprite or is_playing_hit_animation:
		return

	is_playing_hit_animation = true
	var hit_anim = enemy_resource.hit_animation_name if enemy_resource else "hit"
	if animated_sprite.sprite_frames and animated_sprite.sprite_frames.has_animation(hit_anim):
		animated_sprite.play(hit_anim)

func _on_animation_finished():
	var current_animation = animated_sprite.animation
	var hit_anim = enemy_resource.hit_animation_name if enemy_resource else "hit"

	if current_animation == hit_anim:
		is_playing_hit_animation = false
		var move_anim = enemy_resource.move_animation_name if enemy_resource else "move"
		if animated_sprite.sprite_frames and animated_sprite.sprite_frames.has_animation(move_anim):
			animated_sprite.play(move_anim)

func spread_infection_on_death():
	var infection_radius = 60.0
	var nearby_enemies = get_nearby_enemies_for_infection(infection_radius)
	var infection_effect = active_effects["infect"]

	for nearby_enemy in nearby_enemies:
		if nearby_enemy != self and nearby_enemy.has_method("apply_status_effect"):
			if not ("infect" in nearby_enemy.active_effects):
				nearby_enemy.apply_status_effect(
					"infect",
					infection_effect.duration,
					infection_effect.intensity,
					infection_effect.get("source_bottle_id", "unknown")
				)

func get_nearby_enemies_for_infection(radius: float) -> Array[Node2D]:
	var enemies: Array[Node2D] = []
	var bodies = get_tree().get_nodes_in_group("enemies")

	for body in bodies:
		if body != self and body.global_position.distance_to(global_position) <= radius:
			enemies.append(body)

	return enemies

func _execute_dot_tick_trigger(source_bottle_id: String, dot_type: String, damage_dealt: float):
	"""Execute DOT tick triggers when DOT effects deal damage"""
	var source_bottle = InventoryManager.get_bottle_by_id(source_bottle_id)
	if source_bottle:
		TriggerActionManager.execute_dot_tick_trigger(source_bottle, self, dot_type, damage_dealt)

# XP Distribution helper functions
func get_pure_debuff_sources() -> Array[String]:
	var debuff_sources: Array[String] = []
	for effect_name in active_effects.keys():
		if is_pure_debuff_effect(effect_name):
			var source_id = active_effects[effect_name].get("source_bottle_id", "")
			if source_id != "" and source_id not in debuff_sources:
				debuff_sources.append(source_id)
	return debuff_sources

func get_dot_debuff_sources() -> Array[String]:
	var dot_sources: Array[String] = []
	for effect_name in active_effects.keys():
		if is_dot_effect(effect_name):
			var source_id = active_effects[effect_name].get("source_bottle_id", "")
			if source_id != "" and source_id not in dot_sources:
				dot_sources.append(source_id)
	return dot_sources

func get_all_debuff_sources() -> Array[String]:
	var all_sources: Array[String] = []
	for effect_name in active_effects.keys():
		if is_debuff_effect(effect_name):
			var source_id = active_effects[effect_name].get("source_bottle_id", "")
			if source_id != "" and source_id not in all_sources:
				all_sources.append(source_id)
	return all_sources

func has_any_visual_effects() -> bool:
	"""Check if enemy has any effects that should maintain visual changes"""
	return not active_effects.is_empty() or not stacking_effects.is_empty()
