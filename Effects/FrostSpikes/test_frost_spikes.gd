# Effects/FrostSpikes/test_frost_spikes.gd
extends Node2D

const FROST_SPIKES_SCENE = preload("res://Effects/FrostSpikes/frost_spikes.tscn")
const TRAINING_DUMMY = preload("res://Scenes/TestingGrounds/training_dummy.tscn")

var test_dummies: Array[Node2D] = []
var active_spike_systems: Array[Node2D] = []
var bottle_position: Vector2
var test_camera: Camera2D

func _ready():
	_setup_camera()
	_setup_test_environment()
	_setup_ui()

func _setup_camera():
	"""Set up camera for better view of the test"""
	test_camera = Camera2D.new()
	test_camera.zoom = Vector2(1.2, 1.2)  # Light zoom
	test_camera.global_position = Vector2.ZERO
	test_camera.enabled = true
	add_child(test_camera)
	test_camera.make_current()

	print("📷 Test camera ready")

func _setup_test_environment():
	"""Create test dummies and bottle position for testing"""
	# Use simple coordinates around origin
	var center = Vector2.ZERO

	# Set bottle position (left side, simple coordinates)
	bottle_position = Vector2(-120, 0)
	_create_bottle_indicator()

	# Create dummies in simple positions
	_create_dummy_line(center, 80.0, 4)  # Line of dummies
	_create_scattered_dummies(center, 100.0, 5)  # Scattered around

	print("🎯 Test environment set up - bottle at %s" % bottle_position)

func _create_bottle_indicator():
	"""Create a visual indicator for the bottle position"""
	var bottle_visual = ColorRect.new()
	bottle_visual.size = Vector2(20, 20)
	bottle_visual.position = bottle_position - Vector2(10, 10)
	bottle_visual.color = Color(0.8, 0.4, 0.2, 1.0)  # More visible
	bottle_visual.z_index = 10
	add_child(bottle_visual)

	var bottle_label = Label.new()
	bottle_label.text = "BOTTLE"
	bottle_label.position = bottle_position + Vector2(-20, 25)
	bottle_label.add_theme_font_size_override("font_size", 12)
	bottle_label.add_theme_color_override("font_color", Color.YELLOW)
	bottle_label.z_index = 10
	add_child(bottle_label)

func _create_dummy_line(center: Vector2, distance: float, count: int):
	"""Create a line of dummies at specified distance"""
	var start_y = center.y - (count - 1) * 25

	for i in range(count):
		var position = Vector2(center.x + distance, start_y + i * 50)
		_create_dummy_at_position(position)

func _create_scattered_dummies(center: Vector2, min_distance: float, count: int):
	"""Create randomly scattered dummies"""
	for i in range(count):
		var random_angle = randf() * PI * 2
		var random_distance = min_distance + randf() * 80
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

	# Hide the dummy labels for cleaner test visuals
	_hide_dummy_labels(dummy)

	print("🎯 Created dummy at %s" % position)

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
	ui_container.z_index = 100  # Make sure UI is on top
	add_child(ui_container)

	var instructions = Label.new()
	instructions.text = "FROST SPIKES TEST\n\n[CLICK] - Spike trail to mouse\n[C] - Clear all effects\n[R] - Reset dummies\n\n[1] - Light spikes (15 dmg)\n[2] - Medium spikes (25 dmg)\n[3] - Heavy spikes (40 dmg)\n[4] - Rapid spikes\n[5] - Slow spikes\n\nMouse coords shown below"
	instructions.add_theme_font_size_override("font_size", 12)
	instructions.add_theme_color_override("font_color", Color.WHITE)
	ui_container.add_child(instructions)

	# Add status display
	var status_label = Label.new()
	status_label.name = "StatusLabel"
	status_label.position = Vector2(0, 260)
	status_label.add_theme_font_size_override("font_size", 11)
	status_label.add_theme_color_override("font_color", Color(0.8, 0.9, 1.0))
	ui_container.add_child(status_label)

	# Add mouse position display
	var mouse_label = Label.new()
	mouse_label.name = "MouseLabel"
	mouse_label.position = Vector2(0, 320)
	mouse_label.add_theme_font_size_override("font_size", 10)
	mouse_label.add_theme_color_override("font_color", Color.CYAN)
	ui_container.add_child(mouse_label)

func _process(_delta):
	"""Update UI and clean up finished effects"""
	_update_mouse_display()
	_cleanup_finished_effects()

func _update_mouse_display():
	"""Update mouse position display for debugging"""
	var ui_container = get_node_or_null("Control")
	if ui_container:
		var mouse_label = ui_container.get_node_or_null("MouseLabel")
		if mouse_label:
			var mouse_pos = get_global_mouse_position()
			mouse_label.text = "Mouse: %s\nBottle: %s" % [mouse_pos, bottle_position]

func _cleanup_finished_effects():
	"""Clean up finished effects and update status"""
	var initial_count = active_spike_systems.size()

	for i in range(active_spike_systems.size() - 1, -1, -1):
		if not is_instance_valid(active_spike_systems[i]):
			active_spike_systems.remove_at(i)

	# Update status if count changed
	if active_spike_systems.size() != initial_count:
		_update_status_display()

func _input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var target_pos = get_global_mouse_position()
		print("🖱️ Mouse clicked at: %s" % target_pos)
		_create_test_frost_spikes(25.0, target_pos, 2, 60.0, true, 45.0)
	elif event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_1:
				var target_pos = get_global_mouse_position()
				_create_test_frost_spikes(15.0, target_pos, 1, 45.0, true, 35.0)  # Light
			KEY_2:
				var target_pos = get_global_mouse_position()
				_create_test_frost_spikes(25.0, target_pos, 2, 60.0, true, 45.0)  # Medium
			KEY_3:
				var target_pos = get_global_mouse_position()
				_create_test_frost_spikes(40.0, target_pos, 3, 75.0, true, 50.0)  # Heavy
			KEY_4:
				var target_pos = get_global_mouse_position()
				_create_test_frost_spikes(20.0, target_pos, 2, 50.0, true, 80.0)  # Rapid
			KEY_5:
				var target_pos = get_global_mouse_position()
				_create_test_frost_spikes(30.0, target_pos, 2, 70.0, true, 25.0)  # Slow
			KEY_C:
				_clear_all_effects()
			KEY_R:
				_reset_test_dummies()

func _create_test_frost_spikes(damage: float, target_pos: Vector2, stacks: int,
							  size: float, cold: bool, spike_speed: float):
	"""Create a frost spikes trail from bottle to target position"""

	print("🗡️ Creating frost spikes:")
	print("  From: %s" % bottle_position)
	print("  To: %s" % target_pos)
	print("  Distance: %.1f" % bottle_position.distance_to(target_pos))

	# Create frost spikes effect
	var spike_system = FROST_SPIKES_SCENE.instantiate()
	add_child(spike_system)
	spike_system.global_position = bottle_position

	# Initialize with test parameters
	spike_system.initialize(
		damage,          # damage per spike
		target_pos,      # target position
		stacks,          # cold stacks to apply
		size,            # spike size
		cold,            # apply cold effect
		spike_speed,     # emergence speed
		"test_bottle"    # bottle ID
	)

	active_spike_systems.append(spike_system)
	_update_status_display()

	print("✅ Frost spikes created and initialized")

func _update_status_display():
	"""Update the status display with current counts"""
	var ui_container = get_node_or_null("Control")
	if ui_container:
		var status_label = ui_container.get_node_or_null("StatusLabel")
		if status_label:
			status_label.text = "Active Spike Systems: %d\nDummies: %d" % [active_spike_systems.size(), test_dummies.size()]

func _clear_all_effects():
	"""Remove all active frost spike effects"""
	for spike_system in active_spike_systems:
		if is_instance_valid(spike_system):
			spike_system.queue_free()

	active_spike_systems.clear()
	_update_status_display()
	print("🧹 Cleared all frost spike effects")

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

func _exit_tree():
	"""Clean up when exiting"""
	_clear_all_effects()
