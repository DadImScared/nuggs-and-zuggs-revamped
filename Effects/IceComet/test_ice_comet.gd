# IceCometTest.gd
# Attach this to a Node2D and run the scene to test ice comets
extends Node2D

func _ready():
	print("☄️ Ice Comet Test Scene - Press SPACE to launch single comet, ENTER for barrage!")

func _input(event):
	"""Controls for testing ice comets"""
	if event.is_action_pressed("ui_accept"):  # Spacebar
		_launch_single_comet()
	elif event.is_action_pressed("ui_select"):  # Enter
		_launch_comet_barrage()

func _launch_single_comet():
	"""Launch a single ice comet at center screen or fixed position"""
	# Use center of screen as fallback if mouse doesn't work
	var target_pos = get_global_mouse_position()

	# Fallback to screen center if mouse position is (0,0) or invalid
	if target_pos == Vector2.ZERO:
		target_pos = Vector2(400, 300)  # Center-ish position

	var start_pos = target_pos + Vector2(randf_range(-200, 200), -400)  # Start above and to the side

	print("🎯 Mouse position: %s, Target: %s, Start: %s" % [get_global_mouse_position(), target_pos, start_pos])

	_create_ice_comet(start_pos, target_pos, 50.0, 80.0, "test_bottle")

	print("☄️ Launched single comet targeting %s" % target_pos)

func _launch_comet_barrage():
	"""Launch multiple ice comets in a barrage pattern"""
	# Use center of screen as fallback
	var target_pos = get_global_mouse_position()

	# Fallback to screen center if mouse doesn't work
	if target_pos == Vector2.ZERO:
		target_pos = Vector2(400, 300)

	print("🎯 Barrage targeting: %s" % target_pos)

	var comet_count = 5

	for i in range(comet_count):
		# Random positions above the target
		var start_offset = Vector2(randf_range(-300, 300), randf_range(-500, -300))
		var start_pos = target_pos + start_offset

		# Slight random spread around target
		var target_offset = Vector2(randf_range(-40, 40), randf_range(-40, 40))
		var final_target = target_pos + target_offset

		# Stagger the timing
		var delay = i * 0.2
		get_tree().create_timer(delay).timeout.connect(_create_ice_comet.bind(start_pos, final_target, 35.0, 60.0, "test_bottle"))

	print("☄️ Launched barrage of %d comets targeting %s" % [comet_count, target_pos])

func _create_ice_comet(start_pos: Vector2, target_pos: Vector2, damage: float, radius: float, bottle_id: String):
	"""Create a single ice comet"""

	# Load the ice comet scene (we'll need to create this)
	var ice_comet = IceComet.new()

	# Set up the comet
	ice_comet.setup_ice_comet(start_pos, target_pos, damage, radius, bottle_id)

	# Add to scene
	add_child(ice_comet)
