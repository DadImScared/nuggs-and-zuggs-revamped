extends CharacterBody2D

signal died(xp_amount: int, damage_sources: Dictionary)
@onready var player = get_node("/root/Game/Player")
@onready var health_bar_container = $HealthBarContainer
@onready var sprite = $Sprite2D
@onready var health_bar = $HealthBarContainer/HealthBar

var external_velocity_override: bool = false
var external_velocity: Vector2 = Vector2.ZERO

var health_bar_timer = 0.0
var health_bar_duration = 3.0

var base_xp_reward = 5
var base_health = 30
var base_damage = 10
var base_speed = 18.0
var max_health = 0

var damage = 5
var xp_on_kill = 5
var move_speed = 25.0
var health = 30

# Damage tracking for XP distribution
var damage_sources: Dictionary = {} # bottle_id -> damage_dealt
var total_damage_taken: float = 0.0

var active_effects = {}
var original_speed: float
var is_marked: bool = false
var mark_damage_multiplier: float = 1.0
var has_shield: bool = false
var shield_health: float = 0.0

func _ready() -> void:
	scale_to_player_level()
	setup_health_bar()
	original_speed = move_speed # Store original speed for status effects

func _process(delta):
	# Handle health bar visibility timer
	if health_bar_timer > 0:
		health_bar_timer -= delta
		if health_bar_timer <= 0:
			health_bar_container.visible = false
	process_status_effects(delta)

func process_status_effects(delta: float):
	var effects_to_remove = []

	for effect_name in active_effects.keys():
		var effect = active_effects[effect_name]
		effect.timer += delta

		# Apply continuous effects
		match effect_name:
			"burn":
				if effect.timer >= 1.0: # Damage every second
					var burn_damage = effect.intensity * 5.0
					var source_id = effect.get("source_bottle_id", "unknown")
					take_damage_from_source(burn_damage, source_id)
					effect.timer = 0.0
			"poison":
				if effect.timer >= 0.5: # Damage every half second
					var poison_damage = effect.intensity * 3.0
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

		# Remove expired effects
		if effect.timer >= effect.duration:
			effects_to_remove.append(effect_name)

	# Clean up expired effects
	for effect_name in effects_to_remove:
		remove_status_effect(effect_name)

func apply_status_effect(effect_name: String, duration: float, intensity: float, source_bottle_id: String = "unknown", cb = Callable()):
	#print("source bottle id ", source_bottle_id, "effect name", effect_name)
	active_effects[effect_name] = {
		"duration": duration,
		"intensity": intensity,
		"timer": 0.0,
		"source_bottle_id": source_bottle_id
	}

	# Apply immediate effects
	match effect_name:
		"slow":
			move_speed = original_speed * (1.0 - intensity * 0.5)
			sprite.modulate = Color(0.7, 0.7, 1.0) # Blue tint
		"freeze":
			move_speed = 0
			sprite.modulate = Color(0.8, 0.8, 1.0) # Light blue tint
		"sticky":
			move_speed = original_speed * 0.2
			sprite.modulate = Color(1.0, 1.0, 0.6) # Yellow tint
		"burn":
			sprite.modulate = Color(1.2, 0.8, 0.8) # Red tint
		"poison":
			sprite.modulate = Color(0.8, 1.0, 0.8) # Green tint
		"infect":
			active_effects[effect_name]["tick_timer"] = 0.0
			sprite.modulate = Color(0.8, 1.2, 0.8)

func remove_status_effect(effect_name: String):
	active_effects.erase(effect_name)

	# Remove effect consequences
	match effect_name:
		"slow", "freeze", "sticky":
			move_speed = original_speed
		"burn", "poison":
			pass # Visual effects will fade naturally

	if active_effects.is_empty():
		sprite.modulate = Color(0.981, 0, 0.106)

func setup_health_bar():
	health_bar.max_value = max_health
	health_bar.value = health

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

func _physics_process(delta: float) -> void:
	if external_velocity_override:
		velocity = external_velocity
		external_velocity_override = false
	else:
		var direction = global_position.direction_to(player.global_position)
		velocity = direction * move_speed
		#global_position += direction * move_speed * delta

	move_and_slide()

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

				if "color" in infection_effect:
					nearby_enemy.active_effects["infect"]["color"] = infection_effect.color

				var color = infection_effect.get("color", Color.GREEN)
				VisualEffectManager.create_infection_spread_visual(
					global_position,
					nearby_enemy.global_position,
					color
				)

func get_nearby_enemies_for_infection(radius: float) -> Array[Node2D]:
	var enemies: Array[Node2D] = []
	var bodies = get_tree().get_nodes_in_group("enemies")

	for body in bodies:
		if body != self and body.global_position.distance_to(global_position) <= radius:
			enemies.append(body)

	return enemies

func apply_external_velocity(new_velocity: Vector2):
	external_velocity = new_velocity
	external_velocity_override = true

# New damage tracking functions
func take_damage_from_source(damage_amount: float, source_bottle_id: String):
	health -= damage_amount
	health_bar.value = health
	health_bar_container.visible = true
	health_bar_timer = health_bar_duration

	# Track damage for XP distribution
	if not damage_sources.has(source_bottle_id):
		damage_sources[source_bottle_id] = 0.0
	damage_sources[source_bottle_id] += damage_amount
	total_damage_taken += damage_amount

	if health <= 0:
		if "infect" in active_effects:
			spread_infection_on_death()

		queue_free()
		emit_signal("died", xp_on_kill, damage_sources)

# Fallback for old take_damage calls
func take_damage(damage: int):
	take_damage_from_source(damage, "unknown")
