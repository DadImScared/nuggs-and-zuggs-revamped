# Scenes/UI/main_menu.gd
extends Control

# UI References
@onready var title_label = $CenterContainer/MainContainer/TitleContainer/GameTitle
@onready var subtitle_label = $CenterContainer/MainContainer/TitleContainer/Subtitle
@onready var start_button = $CenterContainer/MainContainer/ButtonContainer/StartButton
@onready var options_button = $CenterContainer/MainContainer/ButtonContainer/OptionsButton
@onready var quit_button = $CenterContainer/MainContainer/ButtonContainer/QuitButton
@onready var version_label = $VersionLabel
@onready var animation_player = $AnimationPlayer

# Background effects
@onready var floating_sauces = $BackgroundEffects/FloatingSauces

# Audio (if you have audio system)
# @onready var menu_music = $AudioStreamPlayer

# Game constants
const GAME_VERSION = "Alpha 0.1"
const MAIN_GAME_SCENE = "res://Scenes/main.tscn"
const OPTIONS_SCENE = "res://Scenes/UI/options_menu.tscn"

func _ready():
	# Initialize menu
	_setup_ui()
	_connect_signals()
	_start_background_effects()

	# Play intro animation
	if animation_player:
		animation_player.play("menu_intro")

	# Focus start button for keyboard navigation
	start_button.grab_focus()

func _setup_ui():
	"""Setup initial UI state"""
	# Set game title
	if title_label:
		title_label.text = "NUGGS AND ZUGGS"

	if subtitle_label:
		subtitle_label.text = "Survive the Geological Flavor Apocalypse!"

	# Set version
	if version_label:
		version_label.text = "v" + GAME_VERSION

	# Setup kitchen background image
	_setup_kitchen_background()

	# Setup button hover effects
	_setup_button_hover_effects()

func _setup_kitchen_background():
	"""Setup kitchen background image"""
	var background = get_node("Background")
	if background:
		# Try to load kitchen background image
		var kitchen_texture = load("res://Assets/Sprites/Backgrounds/kitchen_background.png")
		if kitchen_texture:
			# Convert ColorRect to TextureRect for image
			var texture_rect = TextureRect.new()
			texture_rect.texture = kitchen_texture
			texture_rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
			texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
			texture_rect.anchors_preset = Control.PRESET_FULL_RECT

			# Replace the brown ColorRect with our kitchen image
			background.get_parent().add_child(texture_rect)
			background.get_parent().move_child(texture_rect, 0)  # Move to back
			background.queue_free()
		else:
			print("Kitchen background image not found, using fallback brown")
			# Keep the existing brown background as fallback

func _connect_signals():
	"""Connect all button signals"""
	start_button.pressed.connect(_on_start_pressed)
	options_button.pressed.connect(_on_options_pressed)
	quit_button.pressed.connect(_on_quit_pressed)

	# Hover effects
	start_button.mouse_entered.connect(_on_button_hover.bind(start_button))
	options_button.mouse_entered.connect(_on_button_hover.bind(options_button))
	quit_button.mouse_entered.connect(_on_button_hover.bind(quit_button))

	start_button.mouse_exited.connect(_on_button_unhover.bind(start_button))
	options_button.mouse_exited.connect(_on_button_unhover.bind(options_button))
	quit_button.mouse_exited.connect(_on_button_unhover.bind(quit_button))

func _setup_button_hover_effects():
	"""Setup hover animations for buttons"""
	for button in [start_button, options_button, quit_button]:
		if button:
			button.pivot_offset = button.size / 2

func _start_background_effects():
	"""Start background visual effects"""
	# Start floating sauce animations
	_animate_floating_sauces()

	# Start floating nugget animations
	_animate_floating_nuggets()

	# Start floating utensil animations
	_animate_floating_utensils()

# SAUCE BOTTLE FUNCTIONS
func _animate_floating_sauces():
	"""Animate floating sauce bottles in background"""
	if not floating_sauces:
		return

	# MAXIMUM BOTTLES - spawn initial batch
	for i in range(50):  # Way more initial bottles!
		_create_floating_sauce(i)

	# Create timer to continuously spawn new ones RAPIDLY
	var spawn_timer = Timer.new()
	spawn_timer.wait_time = randf_range(0.2, 0.8)  # MUCH faster spawning!
	spawn_timer.timeout.connect(_spawn_random_bottle)
	floating_sauces.add_child(spawn_timer)
	spawn_timer.start()

func _create_floating_sauce(index: int):
	"""Create a single floating sauce bottle"""
	var sauce_sprite = Sprite2D.new()

	# Load base bottle texture
	var texture = load("res://Assets/Sprites/Bottles/basebottle.png")
	if texture:
		sauce_sprite.texture = texture
	else:
		print("Warning: Could not load bottle texture!")
		return

	# Sauce colors with themed names!
	var sauce_colors = [
		Color("#FF4444"),  # Triassic Ketchup
		Color("#FFD700"),  # Jurassic Mustard
		Color("#44AA44"),  # Cretaceous Relish
		Color("#8B4513"),  # Permian BBQ
		Color("#FF8C00"),  # Devonian Buffalo
		Color("#9932CC"),  # Cambrian Ranch
		Color("#DC143C"),  # Ordovician Hot Sauce
		Color("#32CD32"),  # Silurian Pesto
		Color("#FF69B4"),  # Paleozoic Pink Sauce
		Color("#00CED1")   # Mesozoic Mayo
	]

	# Apply random sauce color
	sauce_sprite.modulate = sauce_colors[randi() % sauce_colors.size()]
	sauce_sprite.modulate.a = randf_range(0.4, 0.7)

	# More dramatic size variety
	sauce_sprite.scale = Vector2.ONE * randf_range(0.15, 0.8)
	sauce_sprite.rotation = randf_range(0, TAU)

	# Random spawn position - some from edges, some from anywhere
	if randi() % 3 == 0:  # 1/3 chance spawn from screen edge
		var edge = randi() % 4
		match edge:
			0: # Left edge
				sauce_sprite.position = Vector2(-100, randf_range(0, get_viewport().get_visible_rect().size.y))
			1: # Right edge
				sauce_sprite.position = Vector2(get_viewport().get_visible_rect().size.x + 100, randf_range(0, get_viewport().get_visible_rect().size.y))
			2: # Top edge
				sauce_sprite.position = Vector2(randf_range(0, get_viewport().get_visible_rect().size.x), -100)
			3: # Bottom edge
				sauce_sprite.position = Vector2(randf_range(0, get_viewport().get_visible_rect().size.x), get_viewport().get_visible_rect().size.y + 100)
	else:
		# Spawn anywhere on screen
		sauce_sprite.position = Vector2(
			randf_range(-200, get_viewport().get_visible_rect().size.x + 200),
			randf_range(-100, get_viewport().get_visible_rect().size.y + 100)
		)

	floating_sauces.add_child(sauce_sprite)

	# Start invisible and fade in smoothly
	sauce_sprite.modulate.a = 0.0
	var final_alpha = randf_range(0.4, 0.7)

	# Slow drifting animation
	var tween = create_tween()

	# Bind tween to the sprite so it gets cleaned up automatically
	tween.bind_node(sauce_sprite)

	# Fade in first
	tween.parallel().tween_property(sauce_sprite, "modulate:a", final_alpha, 1.5)

	var duration = randf_range(15.0, 30.0)  # Much longer lifespan!
	var drift_distance = randf_range(150, 400)
	var end_pos = sauce_sprite.position + Vector2(
		randf_range(-drift_distance, drift_distance),
		randf_range(-drift_distance/2, drift_distance/2)
	)

	tween.parallel().tween_property(sauce_sprite, "position", end_pos, duration)
	tween.parallel().tween_property(sauce_sprite, "rotation",
		sauce_sprite.rotation + randf_range(-PI, PI), duration)

	# Subtle alpha pulsing after fade-in, then fade out at end
	tween.parallel().tween_property(sauce_sprite, "modulate:a",
		randf_range(0.2, 0.8), duration / 2)
	tween.parallel().tween_property(sauce_sprite, "modulate:a",
		randf_range(0.3, 0.6), duration / 2)

	# Fade out smoothly before removal
	tween.tween_property(sauce_sprite, "modulate:a", 0.0, 2.0)

	# When tween finishes, remove the sprite
	tween.tween_callback(sauce_sprite.queue_free)

func _spawn_random_bottle():
	"""Continuously spawn new bottles"""
	_create_floating_sauce(randi())

	# Clean up old bottles that drifted off screen
	_cleanup_old_items()

	# Restart timer with BALANCED interval for steady flow
	var timers = floating_sauces.get_children().filter(func(child): return child is Timer)
	if timers.size() > 0:
		var timer = timers[0]
		timer.wait_time = randf_range(0.3, 0.8)  # Balanced for steady stream
		timer.start()

# DINO NUGGET FUNCTIONS
func _animate_floating_nuggets():
	"""Animate floating dino nuggets in background"""
	if not floating_sauces:  # Use same container
		return

	# Spawn TONS of initial nuggets
	for i in range(35):  # Way more nuggets!
		_create_floating_nugget(i)

	# Create timer for spawning new nuggets FAST
	var nugget_timer = Timer.new()
	nugget_timer.wait_time = randf_range(0.5, 1.5)  # Much faster nugget spawning!
	nugget_timer.timeout.connect(_spawn_random_nugget)
	floating_sauces.add_child(nugget_timer)
	nugget_timer.start()

func _create_floating_nugget(index: int):
	"""Create a single floating dino nugget"""
	var nugget_sprite = Sprite2D.new()

	# Load nugget texture
	var nugget_textures = [
		"res://Assets/Sprites/Player/bronto.png",
		"res://Assets/Sprites/Player/dinotrex.png",
		"res://Assets/Sprites/Player/ptero.png",
		"res://Assets/Sprites/Player/stego.png"
	]

	var texture_path = nugget_textures[randi() % nugget_textures.size()]
	var texture = load(texture_path)
	if texture:
		nugget_sprite.texture = texture
	else:
		print("Warning: Could not load nugget texture: ", texture_path)
		return

	# Golden brown nugget colors (cooked nugget vibes)
	var nugget_colors = [
		Color("#D4A574"),  # Classic golden brown
		Color("#C8956D"),  # Slightly darker brown
		Color("#E6B885"),  # Light golden
		Color("#B8946A"),  # Deep fried brown
		Color("#F4D03F")   # Extra crispy golden
	]

	# Apply nugget coloring
	nugget_sprite.modulate = nugget_colors[randi() % nugget_colors.size()]
	nugget_sprite.modulate.a = randf_range(0.5, 0.8)

	# Nuggets are bigger than sauce bottles
	nugget_sprite.scale = Vector2.ONE * randf_range(0.3, 1.0)
	nugget_sprite.rotation = randf_range(0, TAU)

	# Spawn positioning
	if randi() % 4 == 0:  # 1/4 chance spawn from edge
		var edge = randi() % 4
		match edge:
			0: # Left edge
				nugget_sprite.position = Vector2(-150, randf_range(0, get_viewport().get_visible_rect().size.y))
			1: # Right edge
				nugget_sprite.position = Vector2(get_viewport().get_visible_rect().size.x + 150, randf_range(0, get_viewport().get_visible_rect().size.y))
			2: # Top edge
				nugget_sprite.position = Vector2(randf_range(0, get_viewport().get_visible_rect().size.x), -150)
			3: # Bottom edge
				nugget_sprite.position = Vector2(randf_range(0, get_viewport().get_visible_rect().size.x), get_viewport().get_visible_rect().size.y + 150)
	else:
		# Spawn anywhere on screen
		nugget_sprite.position = Vector2(
			randf_range(-250, get_viewport().get_visible_rect().size.x + 250),
			randf_range(-150, get_viewport().get_visible_rect().size.y + 150)
		)

	floating_sauces.add_child(nugget_sprite)

	# Start invisible and fade in smoothly
	nugget_sprite.modulate.a = 0.0
	var final_alpha = randf_range(0.5, 0.8)

	# Nuggets move slower and live longer
	var tween = create_tween()

	# Bind tween to the sprite so it gets cleaned up automatically
	tween.bind_node(nugget_sprite)

	# Fade in first
	tween.parallel().tween_property(nugget_sprite, "modulate:a", final_alpha, 2.0)

	var duration = randf_range(20.0, 45.0)
	var drift_distance = randf_range(100, 250)
	var end_pos = nugget_sprite.position + Vector2(
		randf_range(-drift_distance, drift_distance),
		randf_range(-drift_distance/3, drift_distance/3)
	)

	tween.parallel().tween_property(nugget_sprite, "position", end_pos, duration)
	tween.parallel().tween_property(nugget_sprite, "rotation",
		nugget_sprite.rotation + randf_range(-PI/2, PI/2), duration)

	# Subtle size pulsing (like they're "breathing"), then fade out
	tween.parallel().tween_property(nugget_sprite, "scale",
		nugget_sprite.scale * randf_range(0.9, 1.1), duration / 3)
	tween.parallel().tween_property(nugget_sprite, "scale",
		nugget_sprite.scale * randf_range(0.95, 1.05), duration / 3)

	# Fade out smoothly before removal
	tween.tween_property(nugget_sprite, "modulate:a", 0.0, 2.5)

	# When tween finishes, remove the sprite
	tween.tween_callback(nugget_sprite.queue_free)

func _spawn_random_nugget():
	"""Continuously spawn new nuggets"""
	_create_floating_nugget(randi())

	# Clean up old items
	_cleanup_old_items()

	# Restart timer with BALANCED interval for steady flow
	var timers = floating_sauces.get_children().filter(func(child): return child is Timer)
	if timers.size() > 1:
		var nugget_timer = timers[1]
		nugget_timer.wait_time = randf_range(0.5, 1.2)  # Balanced nugget flow
		nugget_timer.start()

# KITCHEN UTENSIL FUNCTIONS
func _animate_floating_utensils():
	"""Animate floating kitchen utensils in background"""
	if not floating_sauces:
		return

	# Spawn LOTS of initial utensils
	for i in range(25):  # Way more utensils!
		_create_floating_utensil(i)

	# Create timer for spawning new utensils FREQUENTLY
	var utensil_timer = Timer.new()
	utensil_timer.wait_time = randf_range(0.8, 2.0)  # Much faster utensil spawning!
	utensil_timer.timeout.connect(_spawn_random_utensil)
	floating_sauces.add_child(utensil_timer)
	utensil_timer.start()

func _create_floating_utensil(index: int):
	"""Create a single floating kitchen utensil"""
	var utensil_sprite = Sprite2D.new()

	# Load utensil textures
	var utensil_textures = [
		"res://Assets/Sprites/Items/Fork.png",
		"res://Assets/Sprites/Items/Knife.png",
		"res://Assets/Sprites/Items/Plate.png",
		"res://Assets/Sprites/Items/Spoon.png"
	]

	var texture_path = utensil_textures[randi() % utensil_textures.size()]
	var texture = load(texture_path)
	if texture:
		utensil_sprite.texture = texture
	else:
		# Fallback to bottle texture if utensils don't exist yet
		var fallback_texture = load("res://Assets/Sprites/Bottles/basebottle.png")
		if fallback_texture:
			utensil_sprite.texture = fallback_texture
		else:
			print("Warning: Could not load utensil or fallback texture")
			return

	# Metallic colors for utensils
	var utensil_colors = [
		Color("#C0C0C0"),  # Silver
		Color("#A9A9A9"),  # Dark gray
		Color("#DCDCDC"),  # Gainsboro
		Color("#B0C4DE"),  # Light steel blue
		Color("#F5F5F5")   # White smoke
	]

	# Apply metallic coloring
	utensil_sprite.modulate = utensil_colors[randi() % utensil_colors.size()]
	utensil_sprite.modulate.a = randf_range(0.6, 0.9)  # More opaque than bottles

	# Utensils are bigger - more prominent than bottles
	utensil_sprite.scale = Vector2.ONE * randf_range(0.8, 1.4)  # Much bigger!
	utensil_sprite.rotation = randf_range(0, TAU)

	# Spawn positioning - back to random spawning since we're using fade-in
	if randi() % 3 == 0:  # 1/3 chance spawn from screen edge
		var edge = randi() % 4
		var screen_size = get_viewport().get_visible_rect().size
		match edge:
			0: # Left edge
				utensil_sprite.position = Vector2(-120, randf_range(0, screen_size.y))
			1: # Right edge
				utensil_sprite.position = Vector2(screen_size.x + 120, randf_range(0, screen_size.y))
			2: # Top edge
				utensil_sprite.position = Vector2(randf_range(0, screen_size.x), -120)
			3: # Bottom edge
				utensil_sprite.position = Vector2(randf_range(0, screen_size.x), screen_size.y + 120)
	else:
		# Spawn anywhere on screen
		utensil_sprite.position = Vector2(
			randf_range(-200, get_viewport().get_visible_rect().size.x + 200),
			randf_range(-120, get_viewport().get_visible_rect().size.y + 120)
		)

	floating_sauces.add_child(utensil_sprite)

	# Start invisible and fade in smoothly
	utensil_sprite.modulate.a = 0.0
	var final_alpha = randf_range(0.6, 0.9)

	# Utensils move more rigidly/mechanically
	var tween = create_tween()

	# Bind tween to the sprite so it gets cleaned up automatically
	tween.bind_node(utensil_sprite)

	# Fade in first
	tween.parallel().tween_property(utensil_sprite, "modulate:a", final_alpha, 1.8)

	var duration = randf_range(12.0, 25.0)  # Medium lifespan
	var drift_distance = randf_range(80, 200)  # Less drift than bottles
	var end_pos = utensil_sprite.position + Vector2(
		randf_range(-drift_distance, drift_distance),
		randf_range(-drift_distance/4, drift_distance/4)  # Very little vertical movement
	)

	tween.parallel().tween_property(utensil_sprite, "position", end_pos, duration)
	tween.parallel().tween_property(utensil_sprite, "rotation",
		utensil_sprite.rotation + randf_range(-PI/3, PI/3), duration)  # Less spinning than nuggets

	# Occasional metallic "glint" effect
	if randi() % 3 == 0:  # 1/3 chance for glint
		tween.parallel().tween_property(utensil_sprite, "modulate:a", 1.0, 0.3)
		tween.parallel().tween_property(utensil_sprite, "modulate:a", final_alpha, 0.3)

	# Fade out smoothly before removal
	tween.tween_property(utensil_sprite, "modulate:a", 0.0, 2.0)

	# When tween finishes, remove the sprite
	tween.tween_callback(utensil_sprite.queue_free)

func _spawn_random_utensil():
	"""Continuously spawn new utensils"""
	_create_floating_utensil(randi())

	# Clean up old items
	_cleanup_old_items()

	# Restart timer with BALANCED spawning for steady flow
	var timers = floating_sauces.get_children().filter(func(child): return child is Timer)
	if timers.size() > 2:  # We now have 3 timers: bottles, nuggets, utensils
		var utensil_timer = timers[2]
		utensil_timer.wait_time = randf_range(0.8, 1.8)  # Balanced utensil flow
		utensil_timer.start()

# CLEANUP FUNCTION
func _cleanup_old_items():
	"""Remove items that have drifted too far off screen"""
	var screen_size = get_viewport().get_visible_rect().size
	var buffer = 300

	for child in floating_sauces.get_children():
		if child is Sprite2D:
			var pos = child.position
			if (pos.x < -buffer or pos.x > screen_size.x + buffer or
				pos.y < -buffer or pos.y > screen_size.y + buffer):
				child.queue_free()

# Button Actions
func _on_start_pressed():
	"""Start the game"""
	print("Starting Nuggs and Zuggs!")

	# Play button sound if available
	_play_button_sound()

	# Transition to game
	_transition_to_scene(MAIN_GAME_SCENE)

func _on_options_pressed():
	"""Open options menu"""
	print("Opening options menu")
	_play_button_sound()

	# For now, just show a simple message
	var dialog = AcceptDialog.new()
	dialog.dialog_text = "Options menu coming soon!\n\nFeatures planned:\n• Audio settings\n• Display options\n• Control remapping\n• Accessibility options"
	dialog.title = "Options"
	add_child(dialog)
	dialog.popup_centered()
	dialog.confirmed.connect(dialog.queue_free)

func _on_quit_pressed():
	"""Quit the game"""
	print("Quitting game...")
	_play_button_sound()

	# Add quit confirmation dialog
	var dialog = ConfirmationDialog.new()
	dialog.dialog_text = "Are you sure you want to quit the Nuggs and Zuggs adventure?"
	dialog.title = "Quit Game"
	add_child(dialog)
	dialog.popup_centered()
	dialog.confirmed.connect(_quit_confirmed)
	dialog.canceled.connect(dialog.queue_free)

func _quit_confirmed():
	"""Actually quit after confirmation"""
	get_tree().quit()

# Visual Effects
func _on_button_hover(button: Button):
	"""Handle button hover effect"""
	var tween = create_tween()
	tween.parallel().tween_property(button, "scale", Vector2.ONE * 1.1, 0.1)
	tween.parallel().tween_property(button, "modulate", Color.YELLOW, 0.1)

func _on_button_unhover(button: Button):
	"""Handle button unhover effect"""
	var tween = create_tween()
	tween.parallel().tween_property(button, "scale", Vector2.ONE, 0.1)
	tween.parallel().tween_property(button, "modulate", Color.WHITE, 0.1)

func _play_button_sound():
	"""Play button click sound"""
	# Implement when you have audio system
	pass

func _transition_to_scene(scene_path: String):
	"""Transition to another scene with effect"""
	# Simple fade transition for now
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.3)
	tween.tween_callback(func(): get_tree().change_scene_to_file(scene_path))

# Input handling
func _input(event):
	"""Handle input events"""
	if event.is_action_pressed("ui_accept"):
		# Enter key starts game
		_on_start_pressed()
	elif event.is_action_pressed("ui_cancel"):
		# Escape key quits
		_on_quit_pressed()

# Debug functions
func _unhandled_key_input(event):
	"""Handle debug keys"""
	if OS.is_debug_build():
		if event.pressed and event.keycode == KEY_F1:
			# F1 for debug info
			print("=== MAIN MENU DEBUG ===")
			print("Game Version: ", GAME_VERSION)
			print("Available scenes: ")
			print("  Main Game: ", MAIN_GAME_SCENE)
			print("  Options: ", OPTIONS_SCENE)
