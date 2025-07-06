extends CharacterBody2D

signal died(xp_amount: int)
@onready var player = get_node("/root/Game/Player")
@onready var health_bar_container = $HealthBarContainer
@onready var sprite = $Sprite2D
@onready var health_bar = $HealthBarContainer/HealthBar

var health_bar_timer = 0.0
var health_bar_duration = 3.0

var base_xp_reward = 5
var base_health = 30
var base_damage = 10
var base_speed = 18.0
var max_health = 0

var damage = 5
var xp_on_kill = 5
var move_speed = 18.0
var health = 30

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
					take_damage(effect.intensity * 5.0)
					effect.timer = 0.0
					#create_burn_visual()
			"poison":
				if effect.timer >= 0.5: # Damage every half second
					take_damage(effect.intensity * 3.0)
					effect.timer = 0.0
					#create_poison_visual()
		
		# Remove expired effects
		if effect.timer >= effect.duration:
			effects_to_remove.append(effect_name)
	
	# Clean up expired effects
	for effect_name in effects_to_remove:
		remove_status_effect(effect_name)

func apply_status_effect(effect_name: String, duration: float, intensity: float):
	active_effects[effect_name] = {
		"duration": duration,
		"intensity": intensity,
		"timer": 0.0
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
	var style = StyleBoxFlat.new()
	style.bg_color = Color.RED
	#health_bar.add_theme_stylebox_override("fill", style)
	var bg_style = StyleBoxFlat.new()
	bg_style.bg_color = Color.BLACK
	#health_bar.add_theme_stylebox_override("background", bg_style)
	#health_bar_container.position = Vector2(-25, -40)

func scale_to_player_level():
	var base_scale = 1.0 + (PlayerStats.level - 1)
	var health_scale = base_scale * 0.15
	var speed_scale = base_scale * 0.02
	var xp_scale = base_scale * 0.10
	var damage_scale = base_scale * 0.4
	
	health = base_health + (base_health * health_scale)
	max_health = health
	move_speed = base_speed + (base_speed * speed_scale)
	xp_on_kill = base_xp_reward + (base_xp_reward * xp_scale)
	damage = base_damage + (base_damage * damage_scale)
	

func _physics_process(delta: float) -> void:
	var direction = global_position.direction_to(player.global_position)
	velocity = direction * move_speed
	move_and_slide()

func take_damage(damage: int):
	health -= damage
	health_bar.value = health
	health_bar_container.visible = true
	health_bar_timer = health_bar_duration
	if health <= 0:
		queue_free()
		emit_signal("died", xp_on_kill)
