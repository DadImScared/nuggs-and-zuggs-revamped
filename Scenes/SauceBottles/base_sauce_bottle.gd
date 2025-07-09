class_name BaseSauceBottle
extends Area2D

signal leveled_up(bottle_id: String, new_level: int, sauce_name: String)

@export var sauce_data: BaseSauceResource
@onready var shoot_timer = $ShootingTimer
@onready var detection_area = $CollisionShape2D
@onready var sprite = $Sprite2D

var enemies_in_range = []
var current_target = null
var update_timer = 0.0
var update_interval = 0.1
const SAUCE = preload("res://Scenes/sauce_projectile.tscn")

# Leveling system
var current_level: int = 1
var current_xp: int = 0
var xp_to_next_level: int = 25
var max_level: int = 10

# Unique identifier for this bottle instance
var bottle_id: String = ""

# Chosen upgrades for this bottle
var chosen_upgrades: Array[String] = []

func _ready() -> void:
	# Generate unique ID for this bottle instance - ensure it's never empty
	var sauce_name = sauce_data.sauce_name if sauce_data else "UnknownSauce"
	bottle_id = "%s_%d" % [sauce_name, get_instance_id()]
	print("Created bottle with ID: %s" % bottle_id)

	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	setup_shoot_timer()
	if sauce_data:
		setup_bottle()

func setup_bottle():
	modulate = sauce_data.sauce_color
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

	if current_target and is_instance_valid(current_target):
		look_at(current_target.global_position)

func _on_body_entered(body):
	if body.name != "Player":
		enemies_in_range.append(body)
	update_closest_target()

func _on_body_exited(body):
	enemies_in_range.erase(body)
	update_closest_target()

func shoot():
	if not current_target or not sauce_data:
		return

	var new_sauce = SAUCE.instantiate()
	get_tree().current_scene.add_child(new_sauce)
	new_sauce.scale = scale
	var shoot_position = %ShootingPoint.global_position
	var target_direction = shoot_position.direction_to(current_target.global_position)

	# Use current level stats and pass bottle ID
	print("Shooting from bottle ID: %s" % bottle_id)
	new_sauce.launch(
		shoot_position,
		target_direction,
		sauce_data,
		current_level,
		bottle_id
	)

func update_closest_target():
	if enemies_in_range.size() == 0:
		current_target = null
		return

	var closest = enemies_in_range[0]
	var closest_dist = global_position.distance_to(closest.global_position)

	for enemy in enemies_in_range:
		if not is_instance_valid(enemy):
			continue
		var dist = global_position.distance_to(enemy.global_position)
		if dist < closest_dist:
			closest_dist = dist
			closest = enemy

	current_target = closest

func _on_shoot_timer_timeout():
	shoot()

func setup_shoot_timer():
	# Create timer only once
	if not shoot_timer:
		shoot_timer = Timer.new()
		add_child(shoot_timer)
	shoot_timer.timeout.connect(_on_shoot_timer_timeout)

	# Update timer speed based on current level (this can happen multiple times)
	update_fire_rate()

func update_fire_rate():
	if sauce_data and shoot_timer:
		var current_fire_rate = sauce_data.get_current_fire_rate(current_level)
		shoot_timer.wait_time = 1.0 / current_fire_rate

# Leveling system functions
func show_upgrade_menu():
	var upgrade_menu = preload("res://Scenes/UI/upgrade_choice_menu.tscn").instantiate()
	get_tree().current_scene.add_child(upgrade_menu)
	upgrade_menu.setup(sauce_data.sauce_name, current_level)
	upgrade_menu.upgrade_selected.connect(_on_upgrade_chosen)

func _on_upgrade_chosen(choice_number: int):
	print("%s chose upgrade %d" % [sauce_data.sauce_name, choice_number])

func gain_xp(amount: int):
	if current_level >= max_level:
		return

	current_xp += amount
	print("%s gained %d XP (%d/%d)" % [sauce_data.sauce_name, amount, current_xp, xp_to_next_level])

	while current_xp >= xp_to_next_level and current_level < max_level:
		level_up()

func level_up():
	current_level += 1
	current_xp -= xp_to_next_level
	xp_to_next_level = int(xp_to_next_level * 1.4) # 40% more XP needed each level

	print("%s leveled up to level %d!" % [sauce_data.sauce_name, current_level])

	# Update stats based on new level
	update_fire_rate() # Just update fire rate, don't recreate timer
	update_detection_range() # Update range

	#show_upgrade_menu()
	# Emit signal for potential upgrade choices
	leveled_up.emit(bottle_id, current_level, sauce_data.sauce_name)

	# Visual feedback
	create_level_up_effect()

func create_level_up_effect():
	# Simple visual feedback for level up
	var tween = create_tween()
	var original_scale = scale
	tween.tween_property(self, "scale", original_scale * 1.3, 0.2)
	tween.tween_property(self, "scale", original_scale, 0.2)

	# Flash effect
	var flash_tween = create_tween()
	flash_tween.tween_property(self, "modulate", Color.WHITE, 0.1)
	flash_tween.tween_property(self, "modulate", sauce_data.sauce_color, 0.1)

func get_level_info() -> Dictionary:
	return {
		"level": current_level,
		"xp": current_xp,
		"xp_to_next": xp_to_next_level,
		"upgrades": chosen_upgrades.duplicate()
	}
