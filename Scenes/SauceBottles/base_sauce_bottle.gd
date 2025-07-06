class_name BaseSauceBottle
extends Area2D

@export var sauce_data: BaseSauceResource
@onready var shoot_timer = $ShootingTimer
@onready var detection_area = $CollisionShape2D
@onready var sprite = $Sprite2D

var enemies_in_range = []
var current_target = null
var update_timer = 0.0
var update_interval = 0.1
const SAUCE = preload("res://Scenes/sauce_projectile.tscn")

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	setup_shoot_timer()
	if sauce_data:
		setup_bottle()

func setup_bottle():
	modulate = sauce_data.sauce_color

func _physics_process(delta: float) -> void:
	#var enemies_in_range = get_overlapping_bodies()
	#if enemies_in_range.size() > 0:
		#look_at(enemies_in_range.front().global_position)
			# Timer-based target updates for when enemies move around
	update_timer += delta
	if update_timer >= update_interval:
		update_timer = 0.0
		#update_closest_target()
		if enemies_in_range.size() > 1:  # Only recalculate if multiple enemies
			update_closest_target()

	# Always face the current target
	if current_target and is_instance_valid(current_target):
		#print("face")
		#var old_pos = global_position
		look_at(current_target.global_position)
		#global_position = old_pos

func _on_body_entered(body):
	if body.name != "Player":
		enemies_in_range.append(body)
	update_closest_target()

func _on_body_exited(body):
	enemies_in_range.erase(body)
	update_closest_target()

func shoot():
	if not current_target:
		return

	var new_sauce = SAUCE.instantiate()
	get_tree().current_scene.add_child(new_sauce)
	new_sauce.scale = scale
	var shoot_position = %ShootingPoint.global_position
	var target_direction = shoot_position.direction_to(current_target.global_position)
	new_sauce.launch(
		shoot_position,
		target_direction,
		sauce_data
	)

func update_closest_target():
	if enemies_in_range.size() == 0:
		current_target = null
		return

	var closest = enemies_in_range[0]
	var closest_dist = global_position.distance_to(closest.global_position)

	for enemy in enemies_in_range:
		var dist = global_position.distance_to(enemy.global_position)
		if dist < closest_dist:
			closest_dist = dist
			closest = enemy

	current_target = closest
	#look_at(current_target.global_position)

func _on_shoot_timer_timeout():
	shoot()

func setup_shoot_timer():
	# Create timer if it doesn't exist
	if not shoot_timer:
		shoot_timer = Timer.new()
		add_child(shoot_timer)

	# Configure timer based on fire rate
	shoot_timer.wait_time = 1.0 / sauce_data.fire_rate
	shoot_timer.timeout.connect(_on_shoot_timer_timeout)
