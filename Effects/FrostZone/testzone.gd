# FrostZoneTest.gd
# Attach this to a Node2D and run the scene to see the frost zone in action
extends Node2D

func _ready():
	# Create a frost zone for testing
	_create_test_frost_zone()

func _create_test_frost_zone():
	"""Create a test frost zone to see the visual effect"""

	# Load the frost zone scene
	var frost_zone_scene = preload("res://Effects/FrostZone/frost_zone.tscn")
	var frost_zone = frost_zone_scene.instantiate()

	# Add it to the scene
	add_child(frost_zone)

	# Set it up with test parameters
	frost_zone.setup_frost_zone(
		Vector2(400, 300),  # Position (center of screen)
		25.0,               # Tick damage
		80.0,               # Radius
		8.0,                # Duration (8 seconds)
		0.5,                # Tick interval
		"test_bottle"       # Source bottle ID
	)

	print("❄️ Test Frost Zone created at center of screen!")
	print("❄️ It will last 8 seconds and show the visual effect")

func _input(event):
	"""Press SPACE to create another frost zone at mouse position"""
	if event.is_action_pressed("ui_accept"):  # Spacebar
		var mouse_pos = get_global_mouse_position()
		_create_frost_zone_at_position(mouse_pos)

func _create_frost_zone_at_position(pos: Vector2):
	"""Create a frost zone at the specified position"""
	var frost_zone_scene = preload("res://Effects/FrostZone/frost_zone.tscn")
	var frost_zone = frost_zone_scene.instantiate()
	add_child(frost_zone)

	# Randomize parameters for variety
	var radius = randf_range(60, 120)
	var duration = randf_range(5, 10)

	frost_zone.setup_frost_zone(
		pos,
		25.0,
		radius,
		duration,
		0.5,
		"test_bottle"
	)

	print("❄️ Created frost zone at %s (radius: %.1f, duration: %.1f)" % [pos, radius, duration])
