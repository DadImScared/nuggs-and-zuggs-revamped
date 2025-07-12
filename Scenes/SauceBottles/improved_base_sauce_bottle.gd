class_name ImprovedBaseSauceBottle
extends Area2D

signal leveled_up(bottle_id: String, new_level: int, sauce_name: String)

@export var sauce_data: BaseSauceResource
@onready var shoot_timer = $ShootingTimer
@onready var detection_area = $CollisionShape2D
@onready var bottle_sprites = $BottleSprites
@onready var bottle_base = $BottleSprites/BottleBase
@onready var the_tip = $BottleSprites/TheTip
@onready var shooting_point = $BottleSprites/TheTip/ShootingPoint
@onready var animation_player = $AnimationPlayer

var enemies_in_range = []
var current_target = null
var update_timer = 0.0
var update_interval = 0.1
const SAUCE = preload("res://Scenes/sauce_projectile.tscn")

# Animation timing variables
var is_shooting = false
var squeeze_duration = 0.1
var recovery_duration = 0.06

# Leveling system
var current_level: int = 1
var current_xp: int = 0
var xp_to_next_level: int = 25
var max_level: int = 10

var bottle_id: String = ""
var chosen_upgrades: Array[String] = []

func _ready() -> void:
	var sauce_name = sauce_data.sauce_name if sauce_data else "UnknownSauce"
	bottle_id = "%s_%d" % [sauce_name, get_instance_id()]
	print("🍼 Created improved bottle with ID: %s" % bottle_id)

	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	setup_shoot_timer()
	if sauce_data:
		setup_bottle()

func setup_bottle():
	# Apply sauce color to both base and tip
	if bottle_base and bottle_sprites:
		bottle_sprites.modulate = sauce_data.sauce_color
	update_detection_range()

func update_detection_range():
	if detection_area and detection_area.shape and sauce_data:
		var current_range = sauce_data.get_current_range(current_level)
		detection_area.shape.radius = current_range

func _physics_process(delta: float) -> void:
	update_timer += delta
	if update_timer >= update_interval:
		update_timer = 0.0
		if enemies_in_range.size() > 1:
			update_closest_target()

	# Rotate the whole bottle sprites group to face target
	if current_target and is_instance_valid(current_target):
		if bottle_sprites:
			# Calculate direction from bottle to target
			var direction = current_target.global_position - global_position
			# Set rotation to point toward target
			bottle_sprites.rotation = direction.angle()

func _on_body_entered(body):
	if body.name != "Player":
		enemies_in_range.append(body)
	update_closest_target()

func _on_body_exited(body):
	enemies_in_range.erase(body)
	update_closest_target()

func shoot():
	if not current_target or not sauce_data or is_shooting:
		return

	is_shooting = true

	# Play squeeze animation and handle firing
	await squeeze_and_fire()

	is_shooting = false

func squeeze_and_fire() -> void:
	"""Play squeeze animation and fire projectile with tip flash"""

	# Play squeeze animation if available
	if animation_player and animation_player.has_animation("squeeze"):
		animation_player.play("squeeze")

	# Fire projectile at peak compression
	var fire_delay = squeeze_duration * 0.8
	get_tree().create_timer(fire_delay).timeout.connect(fire_projectile_with_flash)

	# Wait for animation to complete
	await get_tree().create_timer(squeeze_duration + recovery_duration).timeout

func fire_projectile_with_flash() -> void:
	"""Create projectile and flash the tip"""

	# Check if target is still valid
	if not current_target or not is_instance_valid(current_target):
		print("❌ No valid target when firing!")
		return

	# Create and launch projectile
	var new_sauce = SAUCE.instantiate()
	get_tree().current_scene.add_child(new_sauce)
	new_sauce.scale = scale

	# Use the tip's shooting point for accurate positioning
	var shoot_position = shooting_point.global_position if shooting_point else global_position
	var target_direction = shoot_position.direction_to(current_target.global_position)

	new_sauce.launch(
		shoot_position,
		target_direction,
		sauce_data,
		current_level,
		bottle_id
	)

	# Flash just the tip for muzzle flash
	create_tip_flash()

func create_tip_flash() -> void:
	"""Flash only the tip part for muzzle flash effect"""
	if not the_tip:
		print("❌ No tip found for flash!")
		return

	# Scale flash - this works great!
	var scale_tween = create_tween()
	var original_scale = the_tip.scale

	scale_tween.tween_property(the_tip, "scale", original_scale * 1.3, 0.05)
	scale_tween.tween_property(the_tip, "scale", original_scale, 0.15)

# Fast version for rapid fire weapons
func shoot_quick():
	"""Ultra-fast squeeze for high fire rate weapons"""
	if not current_target or not sauce_data:
		return

	# Play animation if available
	if animation_player and animation_player.has_animation("squeeze"):
		animation_player.play("squeeze")

	# Fire almost immediately
	get_tree().create_timer(0.03).timeout.connect(fire_projectile_with_flash)

func update_closest_target():
	# Clean up invalid enemies first
	var valid_enemies = []
	for enemy in enemies_in_range:
		if is_instance_valid(enemy):
			valid_enemies.append(enemy)
	enemies_in_range = valid_enemies

	if enemies_in_range.size() == 0:
		current_target = null
		return

	var closest = enemies_in_range[0]
	var closest_dist = global_position.distance_to(closest.global_position)

	for enemy in enemies_in_range:
		if is_instance_valid(enemy):
			var dist = global_position.distance_to(enemy.global_position)
			if dist < closest_dist:
				closest_dist = dist
				closest = enemy

	current_target = closest

func _on_shoot_timer_timeout():
	# Choose animation based on fire rate
	var fire_rate = sauce_data.get_current_fire_rate(current_level) if sauce_data else 1.0

	if fire_rate >= 4.0:
		shoot_quick()  # Very fast weapons
	else:
		shoot()  # Normal squeeze animation

func setup_shoot_timer():
	if not shoot_timer:
		shoot_timer = Timer.new()
		add_child(shoot_timer)
	shoot_timer.timeout.connect(_on_shoot_timer_timeout)
	update_fire_rate()

func update_fire_rate():
	if sauce_data and shoot_timer:
		var current_fire_rate = sauce_data.get_current_fire_rate(current_level)
		shoot_timer.wait_time = 1.0 / current_fire_rate

func gain_xp(amount: int):
	if current_level >= max_level:
		return

	current_xp += amount
	while current_xp >= xp_to_next_level and current_level < max_level:
		level_up()

func level_up():
	current_level += 1
	current_xp -= xp_to_next_level
	xp_to_next_level = int(xp_to_next_level * 1.4)

	update_fire_rate()
	update_detection_range()
	leveled_up.emit(bottle_id, current_level, sauce_data.sauce_name)
	create_level_up_effect()

func create_level_up_effect():
	"""Level up effect that flashes both base and tip"""
	var base_tween = create_tween()
	var tip_tween = create_tween()

	if bottle_base:
		var original_base_scale = bottle_base.scale
		base_tween.tween_property(bottle_base, "scale", original_base_scale * 1.3, 0.2)
		base_tween.tween_property(bottle_base, "scale", original_base_scale, 0.2)

	if the_tip:
		var original_tip_modulate = the_tip.modulate
		tip_tween.tween_property(the_tip, "modulate", Color.GOLD, 0.2)
		tip_tween.tween_property(the_tip, "modulate", original_tip_modulate, 0.2)

func get_level_info() -> Dictionary:
	return {
		"level": current_level,
		"xp": current_xp,
		"xp_to_next": xp_to_next_level,
		"upgrades": chosen_upgrades.duplicate()
	}

# Utility functions for external access
func get_bottle_base() -> Node2D:
	return bottle_base

func get_tip() -> Node2D:
	return the_tip

func set_tip_color(color: Color):
	"""Set tip color independently from base"""
	if the_tip:
		the_tip.modulate = color

func set_base_color(color: Color):
	"""Set base color independently from tip"""
	if bottle_base:
		bottle_base.modulate = color
