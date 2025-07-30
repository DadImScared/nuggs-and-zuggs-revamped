# Effects/IcePrism/test_ice_prism.gd
extends Node2D

const ICE_PRISM_SCENE = preload("res://Effects/IcePrism/ice_prism.tscn")
const TRAINING_DUMMY = preload("res://Scenes/TestingGrounds/training_dummy.tscn")

var test_dummies: Array[Node2D] = []
var active_prisms: Array[Node2D] = []

func _ready():
	_setup_test_environment()
	_setup_ui()
	_setup_camera()

func _setup_camera():
	"""Set up camera for better view of the test"""
	var camera = Camera2D.new()
	camera.zoom = Vector2(2.0, 2.0)  # 2x zoom
	camera.position = get_viewport().get_visible_rect().get_center()
	add_child(camera)

func _setup_test_environment():
	"""Create test dummies in a circle for testing"""
	var dummy_count = 8
	var circle_radius = 60.0  # Much closer
	var center = get_viewport().get_visible_rect().get_center()

	for i in range(dummy_count):
		var angle = i * (PI * 2 / dummy_count)
		var position = center + Vector2(circle_radius, 0).rotated(angle)

		var dummy = TRAINING_DUMMY.instantiate()
		dummy.global_position = position
		add_child(dummy)
		test_dummies.append(dummy)

		# Add to enemies group for targeting
		dummy.add_to_group("enemies")

func _setup_ui():
	"""Create simple UI for testing"""
	var ui_container = Control.new()
	ui_container.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	ui_container.position = Vector2(20, 20)
	add_child(ui_container)

	var instructions = Label.new()
	instructions.text = "ICE PRISM TEST\n\n[SPACE] - Create Ice Prism at mouse\n[C] - Clear all prisms\n[R] - Reset dummies"
	instructions.add_theme_font_size_override("font_size", 14)
	ui_container.add_child(instructions)

func _input(event):
	if event.is_action_pressed("ui_accept"):  # Space key
		_create_test_prism_at_mouse()
	elif event.is_action_pressed("ui_cancel"):  # Escape key
		_clear_all_prisms()
	elif event.is_action_pressed("ui_select"):  # Enter key
		_reset_test_dummies()

func _create_test_prism_at_mouse():
	"""Create an ice prism at the mouse position"""
	var mouse_pos = get_global_mouse_position()

	# Find nearest dummy to "convert" to prism
	var nearest_dummy = _find_nearest_dummy(mouse_pos)
	if not nearest_dummy:
		print("No dummy found to convert to prism")
		return

	# Create ice prism
	var ice_prism = ICE_PRISM_SCENE.instantiate()
	add_child(ice_prism)

	# Initialize with test parameters
	ice_prism.initialize(
		nearest_dummy,           # target enemy
		25.0,                   # beam damage
		70.0,                   # beam length (shorter)
		90.0,                   # rotation speed (degrees/sec)
		8.0,                    # duration
		8.0,                    # beam width (smaller)
		"test_bottle"           # bottle ID
	)

	# Create activation effect
	ice_prism.create_activation_effect()

	active_prisms.append(ice_prism)

	print("Created ice prism at: ", nearest_dummy.global_position)

func _find_nearest_dummy(position: Vector2) -> Node2D:
	"""Find the nearest dummy to the given position"""
	var nearest_dummy = null
	var nearest_distance = INF

	for dummy in test_dummies:
		if not is_instance_valid(dummy):
			continue

		var distance = position.distance_to(dummy.global_position)
		if distance < nearest_distance:
			nearest_distance = distance
			nearest_dummy = dummy

	return nearest_dummy

func _clear_all_prisms():
	"""Remove all active prisms"""
	for prism in active_prisms:
		if is_instance_valid(prism):
			prism.queue_free()

	active_prisms.clear()

	# Restore dummy movement
	for dummy in test_dummies:
		if is_instance_valid(dummy):
			if dummy.has_method("set_movement_disabled"):
				dummy.set_movement_disabled(false)
			elif dummy.has_meta("original_move_speed"):
				dummy.move_speed = dummy.get_meta("original_move_speed")
				dummy.remove_meta("original_move_speed")

	print("Cleared all prisms")

func _reset_test_dummies():
	"""Reset all test dummies to original positions"""
	_clear_all_prisms()

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
	"""Clean up finished prisms"""
	for i in range(active_prisms.size() - 1, -1, -1):
		if not is_instance_valid(active_prisms[i]):
			active_prisms.remove_at(i)
