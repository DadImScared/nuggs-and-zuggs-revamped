# Effects/OrbRotation/test_orb_rotation.gd
extends Node2D

const ORB_ROTATION_SCENE = preload("res://Effects/OrbRotation/orb_rotation.tscn")
const TRAINING_DUMMY = preload("res://Scenes/TestingGrounds/training_dummy.tscn")

var test_dummies: Array[Node2D] = []
var active_orb_systems: Array[Node2D] = []

func _ready():
	_setup_test_environment()
	_setup_ui()
	_setup_camera()

func _setup_camera():
	"""Set up camera for better view of the test"""
	var camera = Camera2D.new()
	camera.zoom = Vector2(2.0, 2.0)  # 2x zoom to see orb details
	camera.position = get_viewport().get_visible_rect().get_center()
	add_child(camera)

func _setup_test_environment():
	"""Create test dummies in various patterns for testing"""
	var center = get_viewport().get_visible_rect().get_center()

	# Create a circle of dummies around the center
	_create_dummy_circle(center, 80.0, 8)

	# Create some scattered dummies for orb interaction
	_create_scattered_dummies(center, 150.0, 6)

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
	var nodes_to_hide = ["Label", "NameLabel", "DummyLabel", "UI", "HUD", "InfoLabel"]

	for node_name in nodes_to_hide:
		var label_node = dummy.get_node_or_null(node_name)
		if label_node:
			label_node.visible = false

	_hide_labels_recursive(dummy)

func _hide_labels_recursive(node: Node):
	"""Recursively hide all Label nodes in the dummy"""
	for child in node.get_children():
		if child is Label:
			child.visible = false
		elif child is Control:
			child.visible = false
		else:
			_hide_labels_recursive(child)

func _setup_ui():
	"""Create simple UI for testing"""
	var ui_container = Control.new()
	ui_container.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	ui_container.position = Vector2(20, 20)
	add_child(ui_container)

	var instructions = Label.new()
	instructions.text = "ORB ROTATION TEST\n\n[SPACE] - Default orbs at mouse\n[C] - Clear all effects\n[R] - Reset dummies\n\n[1] - 3 Small orbs (15 dmg, slow)\n[2] - 5 Medium orbs (25 dmg, normal)\n[3] - 7 Large orbs (35 dmg, fast)\n[4] - Cold orbs (apply freeze)\n\nClick anywhere to create effect!"
	instructions.add_theme_font_size_override("font_size", 12)
	instructions.add_theme_color_override("font_color", Color.WHITE)
	ui_container.add_child(instructions)

	# Add status display
	var status_label = Label.new()
	status_label.name = "StatusLabel"
	status_label.position = Vector2(0, 220)
	status_label.text = "Active Orb Systems: 0\nDummies: %d" % test_dummies.size()
	status_label.add_theme_font_size_override("font_size", 11)
	status_label.add_theme_color_override("font_color", Color(0.8, 0.9, 1.0))
	ui_container.add_child(status_label)

func _input(event):
	if event.is_action_pressed("ui_accept"):  # Space key
		_create_test_orb_rotation(15.0, 45.0, 3, 45.0, false, 1, true, 30.0)
	elif event.is_action_pressed("ui_cancel"):  # Escape key
		_clear_all_effects()
	elif event.is_action_pressed("ui_select"):  # Enter key
		_reset_test_dummies()
	elif event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_1:
				_create_test_orb_rotation(15.0, 30.0, 3, 35.0, false, 1, true, 25.0)  # Small & slow
			KEY_2:
				_create_test_orb_rotation(25.0, 45.0, 5, 45.0, false, 1, true, 30.0)  # Medium
			KEY_3:
				_create_test_orb_rotation(35.0, 60.0, 7, 55.0, false, 1, true, 40.0)  # Large & fast
			KEY_4:
				_create_test_orb_rotation(20.0, 40.0, 4, 40.0, true, 2, true, 35.0)   # Cold orbs

func _create_test_orb_rotation(damage: float, speed: float, orbs: int, size: float,
							  cold: bool, stacks: int, knockback: bool, force: float):
	"""Create an orb rotation system at the mouse position"""
	var mouse_pos = get_global_mouse_position()

	# Create orb rotation effect
	var orb_system = ORB_ROTATION_SCENE.instantiate()
	add_child(orb_system)
	orb_system.global_position = mouse_pos

	# Initialize with test parameters (no follow target = fixed position)
	orb_system.initialize(
		damage,          # damage per hit
		speed,           # rotation speed (degrees/sec)
		orbs,            # number of orbs
		size,            # orb size
		cold,            # apply cold effect
		stacks,          # cold stacks to apply
		knockback,       # knockback enabled
		force,           # knockback force
		"test_bottle",   # bottle ID
		null             # no follow target = stay at mouse position
	)

	active_orb_systems.append(orb_system)
	_update_status_display()

	var cold_text = " + COLD" if cold else ""
	print("⚪ Created orb rotation at: %s (%d orbs, %.0f dmg, %.0f°/s%s)" % [mouse_pos, orbs, damage, speed, cold_text])

func _update_status_display():
	"""Update the status display with current counts"""
	var ui_container = get_node_or_null("Control")
	if ui_container:
		var status_label = ui_container.get_node_or_null("StatusLabel")
		if status_label:
			status_label.text = "Active Orb Systems: %d\nDummies: %d" % [active_orb_systems.size(), test_dummies.size()]

func _clear_all_effects():
	"""Remove all active orb rotation effects"""
	for orb_system in active_orb_systems:
		if is_instance_valid(orb_system):
			orb_system.queue_free()

	active_orb_systems.clear()
	_update_status_display()
	print("🧹 Cleared all orb rotation effects")

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
	_update_status_display()

	print("🔄 Reset test environment")

func _process(_delta):
	"""Clean up finished effects and update status"""
	var initial_count = active_orb_systems.size()

	for i in range(active_orb_systems.size() - 1, -1, -1):
		if not is_instance_valid(active_orb_systems[i]):
			active_orb_systems.remove_at(i)

	# Update status if count changed
	if active_orb_systems.size() != initial_count:
		_update_status_display()

func _exit_tree():
	"""Clean up when exiting"""
	_clear_all_effects()
