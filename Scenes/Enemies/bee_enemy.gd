# Scenes/Enemies/bee_enemy.gd
extends CharacterBody2D

signal died(xp_amount: int, damage_sources: Dictionary)
signal debuff_xp_earned(bottle_id: String, xp_amount: int)

@onready var player = get_node("/root/Game/Player")
@onready var health_bar_container = $HealthBarContainer
@onready var animated_sprite = $AnimatedSprite2D
@onready var health_bar = $HealthBarContainer/HealthBar

# Enemy resource - this defines what type of enemy this is
var enemy_resource: BaseEnemyResource

# Current stats (calculated from resource + player level)
var max_health = 0
var damage = 5
var xp_on_kill = 5
var move_speed = 18.0
var health = 30

# Movement and effects
var external_velocity_override: bool = false
var external_velocity: Vector2 = Vector2.ZERO
var health_bar_timer = 0.0
var health_bar_duration = 3.0
var damage_sources: Dictionary = {}
var total_damage_taken: float = 0.0
var debuff_periodic_timer: float = 0.0
var debuff_periodic_interval: float = 1.0
var debuff_xp_per_tick: int = 2
var active_effects = {}
var original_speed: float
var is_marked: bool = false
var mark_damage_multiplier: float = 1.0
var has_shield: bool = false
var shield_health: float = 0.0

# Animation state
var is_playing_hit_animation: bool = false

func _ready() -> void:
	if not enemy_resource:
		#print("Warning: No enemy resource set for bee!")
		setup_default_stats()
	else:
		#print("Setting up bee enemy: %s" % enemy_resource.enemy_name)
		setup_from_resource()

	setup_health_bar()
	original_speed = move_speed

	# Start with move animation
	if animated_sprite:
		animated_sprite.play("move")
		animated_sprite.animation_finished.connect(_on_animation_finished)
		#print("Started bee move animation")

func setup_from_resource():
	var player_level = PlayerStats.level if PlayerStats else 1

	# Calculate stats from the resource
	health = enemy_resource.get_scaled_health(player_level)
	max_health = health
	move_speed = enemy_resource.get_scaled_speed(player_level)
	damage = enemy_resource.get_scaled_damage(player_level)
	xp_on_kill = enemy_resource.get_scaled_xp_reward(player_level)

	# Apply visual settings from resource
	#scale = Vector2.ONE * enemy_resource.scale_modifier
	scale = Vector2(0.17, 0.17)
	animated_sprite.modulate = enemy_resource.enemy_color

	# Set animation speed if we have animations
	if animated_sprite:
		animated_sprite.speed_scale = enemy_resource.animation_speed_multiplier

	#print("Bee stats - Health: %d, Speed: %.1f, Damage: %.1f" % [health, move_speed, damage])

func setup_default_stats():
	# Fallback bee stats
	health = 20
	max_health = health
	move_speed = 25.0  # Bees are fast
	damage = 8
	xp_on_kill = 7

	# Set a default yellow color for bees
	if animated_sprite:
		animated_sprite.modulate = Color(1.0, 0.8, 0.2)  # Bee yellow

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

func _physics_process(delta: float) -> void:
	if external_velocity_override:
		velocity = external_velocity
		external_velocity_override = false
	else:
		var direction = global_position.direction_to(player.global_position)
		velocity = direction * move_speed

		# Make bee face the direction it's moving without breaking animation
		if direction.length() > 0:
			# Simple horizontal flipping - no rotation issues
			if direction.x < 0:
				animated_sprite.flip_h = true
			else:
				animated_sprite.flip_h = false

			# Keep rotation at 0 to avoid animation conflicts
			animated_sprite.rotation = 0

	move_and_slide()

func take_damage_from_source(damage_amount: float, source_bottle_id: String):
	# Apply resistances from the bee resource
	var actual_damage = damage_amount
	if enemy_resource:
		# Bees are weak to fire (burn_resistance > 1.0 means more damage)
		if "burn" in str(source_bottle_id).to_lower():
			actual_damage *= enemy_resource.burn_resistance

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
		#print("Bee died! XP reward: %d" % xp_on_kill)
		queue_free()
		emit_signal("died", xp_on_kill, damage_sources)

func play_hit_animation():
	if not animated_sprite or is_playing_hit_animation:
		return

	#print("Playing bee hit animation")
	is_playing_hit_animation = true
	animated_sprite.play("hit")

func _on_animation_finished():
	var current_animation = animated_sprite.animation
	#print("Animation finished: %s" % current_animation)

	if current_animation == "hit":
		is_playing_hit_animation = false
		animated_sprite.play("move")  # Return to move animation
		#print("Returning to move animation")

func take_damage(damage_amount: float):
	take_damage_from_source(damage_amount, "unknown")

# Simplified status effects for now
func process_status_effects(delta: float):
	var effects_to_remove = []

	for effect_name in active_effects.keys():
		var effect = active_effects[effect_name]
		effect.timer += delta

		# Apply bee-specific resistances
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

func apply_status_effect(effect_name: String, duration: float, intensity: float, source_bottle_id: String = "unknown", cb = Callable()):
	# Apply bee resistances
	var actual_intensity = intensity
	var actual_duration = duration

	if enemy_resource:
		match effect_name:
			"slow":
				actual_intensity *= (2.0 - enemy_resource.slow_resistance)
				actual_duration *= (2.0 - enemy_resource.slow_resistance)
			"freeze":
				actual_intensity *= (2.0 - enemy_resource.freeze_resistance)
				actual_duration *= (2.0 - enemy_resource.freeze_resistance)

	active_effects[effect_name] = {
		"duration": actual_duration,
		"intensity": actual_intensity,
		"timer": 0.0,
		"source_bottle_id": source_bottle_id
	}

	# Apply immediate visual effects
	match effect_name:
		"slow":
			move_speed = original_speed * (1.0 - actual_intensity * 0.5)
			animated_sprite.modulate = Color(0.7, 0.7, 1.0)  # Blue tint
		"freeze":
			move_speed = 0
			animated_sprite.modulate = Color(0.8, 0.8, 1.0)  # Light blue
			# Pause animation
			animated_sprite.speed_scale = 0
		"burn":
			animated_sprite.modulate = Color(1.2, 0.8, 0.8)  # Red tint
		"poison":
			animated_sprite.modulate = Color(0.8, 1.0, 0.8)  # Green tint

func remove_status_effect(effect_name: String):
	active_effects.erase(effect_name)

	# Restore normal behavior
	match effect_name:
		"slow", "freeze":
			move_speed = original_speed
			# Restore animation speed
			if animated_sprite and enemy_resource:
				animated_sprite.speed_scale = enemy_resource.animation_speed_multiplier

	# Restore normal color if no effects remain
	if active_effects.is_empty():
		if enemy_resource:
			animated_sprite.modulate = enemy_resource.enemy_color
		else:
			animated_sprite.modulate = Color(1.0, 0.8, 0.2)  # Default bee yellow

func apply_external_velocity(new_velocity: Vector2):
	external_velocity = new_velocity
	external_velocity_override = true
