# Effects/FrostNova/test_frost_nova.gd
extends Node2D

const FROST_NOVA_SCENE = preload("res://Effects/FrostNova/frost_nova.tscn")
const TRAINING_DUMMY = preload("res://Scenes/TestingGrounds/training_dummy.tscn")

var test_dummies: Array[Node2D] = []
var active_novas: Array[Node2D] = []

func _ready():
	_setup_test_environment()
	_setup_ui()
	_setup_camera()

func _setup_camera():
	"""Set up camera for better view of the test"""
	var camera = Camera2D.new()
	camera.zoom = Vector2(2.5, 2.5)  # Increased zoom to see effects better
	camera.position = get_viewport().get_visible_rect().get_center()
	add_child(camera)

func _setup_test_environment():
	"""Create test dummies in various patterns for testing"""
	var center = get_viewport().get_visible_rect().get_center()

	# Create a circle of dummies
	_create_dummy_circle(center, 60.0, 8)

	# Create some scattered dummies
	_create_scattered_dummies(center, 120.0, 6)

func _create_dummy_circle(center: Vector2, circle_radius: float, count: int):
	"""Create dummies in a circle pattern"""
	for i in range(count):
		var angle = i * (PI * 2 / count)
		var position = center + Vector2(circle_radius, 0).rotated(angle)
		_create_dummy_at_position(position)

func _create_scattered_dummies(center: Vector2, scatter_radius: float, count: int):
	"""Create randomly scattered dummies"""
	for i in range(count):
		var random_angle = randf() * PI * 2
		var random_distance = randf() * scatter_radius
		var position = center + Vector2(random_distance, 0).rotated(random_angle)
		_create_dummy_at_position(position)

func _create_dummy_at_position(position: Vector2):
	"""Create a single dummy at the specified position"""
	var dummy = TRAINING_DUMMY.instantiate()
	dummy.global_position = position
	add_child(dummy)
	test_dummies.append(dummy)

	# Add to enemies group for targeting
	dummy.add_to_group("enemies")

	# Hide the dummy name/label for cleaner test visuals
	_hide_dummy_labels(dummy)

func _hide_dummy_labels(dummy: Node2D):
	"""Hide name labels and UI elements from training dummies"""
	# Look for common label/UI node names and hide them
	var nodes_to_hide = ["Label", "NameLabel", "DummyLabel", "UI", "HUD", "InfoLabel"]

	for node_name in nodes_to_hide:
		var label_node = dummy.get_node_or_null(node_name)
		if label_node:
			label_node.visible = false

	# Also check children recursively for any Labels
	_hide_labels_recursive(dummy)

func _hide_labels_recursive(node: Node):
	"""Recursively hide all Label nodes in the dummy"""
	for child in node.get_children():
		if child is Label:
			child.visible = false
		elif child is Control:
			# Hide any UI controls that might contain text
			child.visible = false
		else:
			# Continue searching in children
			_hide_labels_recursive(child)

func _setup_ui():
	"""Create simple UI for testing"""
	var ui_container = Control.new()
	ui_container.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	ui_container.position = Vector2(20, 20)
	add_child(ui_container)

	var instructions = Label.new()
	instructions.text = "FROST NOVA TEST\n\n[SPACE] - Default Frost Nova at mouse\n[C] - Clear all effects\n[R] - Reset dummies\n\n[1] - Small (40 dmg, 60 radius)\n[2] - Medium (60 dmg, 80 radius)\n[3] - Large (80 dmg, 120 radius)\n\nClick anywhere to create effect!"
	instructions.add_theme_font_size_override("font_size", 12)
	instructions.add_theme_color_override("font_color", Color.WHITE)
	ui_container.add_child(instructions)

	# Add status display
	var status_label = Label.new()
	status_label.name = "StatusLabel"
	status_label.position = Vector2(0, 180)
	status_label.text = "Active Effects: 0\nDummies: %d" % test_dummies.size()
	status_label.add_theme_font_size_override("font_size", 11)
	status_label.add_theme_color_override("font_color", Color(0.8, 0.9, 1.0))
	ui_container.add_child(status_label)

func _input(event):
	if event.is_action_pressed("ui_accept"):  # Space key
		_create_test_frost_nova(40.0, 80.0, 1)
	elif event.is_action_pressed("ui_cancel"):  # Escape key
		_clear_all_effects()
	elif event.is_action_pressed("ui_select"):  # Enter key
		_reset_test_dummies()
	elif event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_1:
				_create_test_frost_nova(40.0, 60.0, 1)  # Small
			KEY_2:
				_create_test_frost_nova(60.0, 80.0, 2)  # Medium
			KEY_3:
				_create_test_frost_nova(80.0, 120.0, 3)  # Large

func _create_test_frost_nova(damage: float, radius: float, stacks: int):
	"""Create a frost nova at the mouse position"""
	var mouse_pos = get_global_mouse_position()

	# Create frost nova effect
	var frost_nova = FROST_NOVA_SCENE.instantiate()
	add_child(frost_nova)
	frost_nova.global_position = mouse_pos

	# Initialize with test parameters
	frost_nova.initialize(
		damage,          # damage
		radius,          # radius
		stacks,          # cold stacks to apply
		"test_bottle"    # bottle ID
	)

	# Create activation effect
	frost_nova.create_activation_effect()

	active_novas.append(frost_nova)

	_update_status_display()

	print("🧊 Created frost nova at: %s (damage: %.0f, radius: %.0f, stacks: %d)" % [mouse_pos, damage, radius, stacks])

func _update_status_display():
	"""Update the status display with current counts"""
	var ui_container = get_node_or_null("Control")
	if ui_container:
		var status_label = ui_container.get_node_or_null("StatusLabel")
		if status_label:
			status_label.text = "Active Effects: %d\nDummies: %d" % [active_novas.size(), test_dummies.size()]

func _clear_all_effects():
	"""Remove all active frost nova effects"""
	for nova in active_novas:
		if is_instance_valid(nova):
			nova.queue_free()

	active_novas.clear()
	print("Cleared all frost nova effects")

func _reset_test_dummies():
	"""Reset all test dummies to original positions"""
	_clear_all_effects()

	# Remove existing dummies
	for dummy in test_dummies:
		if is_instance_valid(dummy):
			dummy.queue_free()

	test_dummies.clear()

	# Recreate dummies
	await get_tree().process_frame  # Wait one frame for cleanup
	_setup_test_environment()

	print("Reset test environment")

func _process(_delta):
	"""Clean up finished effects"""
	for i in range(active_novas.size() - 1, -1, -1):
		if not is_instance_valid(active_novas[i]):
			active_novas.remove_at(i)

func _exit_tree():
	"""Clean up when exiting"""
	_clear_all_effects()
