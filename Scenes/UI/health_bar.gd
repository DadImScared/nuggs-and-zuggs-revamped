# Scenes/UI/health_bar.gd
class_name HealthBar
extends Control

@onready var bar: ProgressBar = $Bar
@onready var hide_timer: Timer = $HideTimer
@onready var background: ColorRect = $Background

@export var show_duration: float = 3.0

func _ready():
	# Debug: Check if nodes exist
	if not bar:
		#print("ERROR: Bar node not found! Check scene structure.")
		return
	if not hide_timer:
		#print("ERROR: HideTimer node not found! Check scene structure.")
		return
	if not background:
		#print("ERROR: Background node not found! Check scene structure.")
		return

	visible = false
	hide_timer.wait_time = show_duration
	setup_styling()

func setup_styling():
	if not background or not bar:
		#print("ERROR: Cannot setup styling - nodes missing")
		return

	# Create a border background
	background.color = Color(0.2, 0.2, 0.2, 0.8)  # Dark gray background

	# Add a border to the background
	var border_style = StyleBoxFlat.new()
	border_style.bg_color = Color(0.2, 0.2, 0.2, 0.8)  # Dark gray fill
	border_style.border_width_left = 1
	border_style.border_width_right = 1
	border_style.border_width_top = 1
	border_style.border_width_bottom = 1
	border_style.border_color = Color.BLACK  # Black border
	background.add_theme_stylebox_override("normal", border_style)

func initialize(max_hp: float, current_hp: float):
	"""Initialize health bar - position is already set in scene"""
	if not bar:
		#print("ERROR: Cannot initialize - Bar node missing")
		return

	bar.max_value = max_hp
	bar.value = current_hp
	update_color()  # Set initial color

func update_health(current_hp: float):
	"""Update health and show bar"""
	if not bar:
		return

	bar.value = current_hp
	update_color()  # Update color based on health
	show_bar()

func show_bar():
	"""Show bar for the specified duration"""
	visible = true
	hide_timer.stop()
	hide_timer.start()

func update_color():
	"""Change color based on health percentage"""
	if not bar:
		return

	var health_percent = bar.value / bar.max_value
	var new_color: Color

	if health_percent > 0.7:
		new_color = Color.GREEN
	elif health_percent > 0.3:
		new_color = Color.YELLOW
	else:
		new_color = Color.RED

	# Update the progress bar color
	var style_box = StyleBoxFlat.new()
	style_box.bg_color = new_color
	bar.add_theme_stylebox_override("fill", style_box)

func _on_hide_timer_timeout():
	"""Hide bar when timer expires - connect this signal in the scene"""
	visible = false
