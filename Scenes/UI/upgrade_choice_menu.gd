# Scenes/UI/upgrade_choice_menu.gd
extends Control

signal talent_selected(choice_number: int)

@onready var sauce_info = $CenterPanel/MainContainer/SauceInfoLabel
@onready var button1 = $CenterPanel/MainContainer/ChoicesContainer/Choice1/Button1
@onready var button2 = $CenterPanel/MainContainer/ChoicesContainer/Choice2/Button2
@onready var button3 = $CenterPanel/MainContainer/ChoicesContainer/Choice3/Button3
@onready var desc1 = $CenterPanel/MainContainer/ChoicesContainer/Choice1/Description1
@onready var desc2 = $CenterPanel/MainContainer/ChoicesContainer/Choice2/Description2
@onready var desc3 = $CenterPanel/MainContainer/ChoicesContainer/Choice3/Description3

# Add these if you have preview labels in your scene
@onready var preview1 = $CenterPanel/MainContainer/ChoicesContainer/Choice1/Preview1
@onready var preview2 = $CenterPanel/MainContainer/ChoicesContainer/Choice2/Preview2
@onready var preview3 = $CenterPanel/MainContainer/ChoicesContainer/Choice3/Preview3

var current_level: int = 1
var current_sauce: String = ""

func _ready():
	get_tree().paused = true

	# Connect button signals
	button1.pressed.connect(_on_choice_1)
	button2.pressed.connect(_on_choice_2)
	button3.pressed.connect(_on_choice_3)

	# Connect hover effects for better UX
	button1.mouse_entered.connect(_on_button_mouse_entered.bind(button1, 1))
	button1.mouse_exited.connect(_on_button_mouse_exited.bind(button1))
	button2.mouse_entered.connect(_on_button_mouse_entered.bind(button2, 2))
	button2.mouse_exited.connect(_on_button_mouse_exited.bind(button2))
	button3.mouse_entered.connect(_on_button_mouse_entered.bind(button3, 3))
	button3.mouse_exited.connect(_on_button_mouse_exited.bind(button3))

func setup_with_talents(sauce_name: String, level: int):
	current_level = level
	current_sauce = sauce_name
	sauce_info.text = "%s reached Level %d!" % [sauce_name, level]

	# Get talents for this specific level
	var talents = TalentManager.get_talents_for_level(sauce_name, level)
	print("Setting up upgrade menu with %d talents for %s level %d" % [talents.size(), sauce_name, level])

	if talents.size() >= 1:
		_setup_choice_button(button1, desc1, preview1, talents[0])
		button1.visible = true
	else:
		button1.visible = false

	if talents.size() >= 2:
		_setup_choice_button(button2, desc2, preview2, talents[1])
		button2.visible = true
	else:
		button2.visible = false

	if talents.size() >= 3:
		_setup_choice_button(button3, desc3, preview3, talents[2])
		button3.visible = true
	else:
		button3.visible = false

func _setup_choice_button(button: Button, desc_label: Label, preview_label: Label, talent: Talent):
	# Set button text and description
	button.text = talent.talent_name
	desc_label.text = talent.description

	# Set detailed preview if preview label exists
	if preview_label:
		preview_label.text = talent.get_preview_text()

	# Color code by talent type
	_style_button_by_type(button, talent.talent_type)

	# Add rarity indicator for high-level talents
	if talent.level_required >= 8:
		button.modulate = Color.GOLD
		button.add_theme_color_override("font_color", Color.BLACK)
	elif talent.level_required >= 6:
		button.modulate = Color.PURPLE
		button.add_theme_color_override("font_color", Color.WHITE)
	elif talent.level_required >= 4:
		button.modulate = Color.ORANGE
		button.add_theme_color_override("font_color", Color.BLACK)

func _style_button_by_type(button: Button, talent_type: Talent.TalentType):
	# Color code buttons by talent type with subtle overlay
	var base_color = Color.WHITE
	match talent_type:
		Talent.TalentType.STAT_MODIFIER:
			base_color = Color.LIGHT_BLUE  # Stats = Blue
		Talent.TalentType.SPECIAL_EFFECT:
			base_color = Color.LIGHT_GREEN  # Effects = Green
		Talent.TalentType.TRIGGER_EFFECT:
			base_color = Color.ORANGE  # Triggers = Orange
		Talent.TalentType.PASSIVE_AURA:
			base_color = Color.PURPLE  # Auras = Purple
		Talent.TalentType.TRANSFORMATION:
			base_color = Color.GOLD  # Transformations = Gold

	# Apply subtle tint (don't override rarity colors)
	if talent_type != Talent.TalentType.TRANSFORMATION:  # Gold is already set for transformations
		button.modulate = base_color.lerp(Color.WHITE, 0.7)

func _on_choice_1():
	print("Chose talent 1: Level %d %s" % [current_level, current_sauce])
	talent_selected.emit(1)
	_close_menu()

func _on_choice_2():
	print("Chose talent 2: Level %d %s" % [current_level, current_sauce])
	talent_selected.emit(2)
	_close_menu()

func _on_choice_3():
	print("Chose talent 3: Level %d %s" % [current_level, current_sauce])
	talent_selected.emit(3)
	_close_menu()

func _close_menu():
	get_tree().paused = false
	queue_free()

# Hover effects for better UX
func _on_button_mouse_entered(button: Button, talent_index: int):
	# Highlight effect when hovering
	button.scale = Vector2(1.05, 1.05)

	# Could show additional tooltip info here
	var talent = TalentManager.get_talent_by_choice(current_sauce, current_level, talent_index)
	if talent:
		print("Hovering over: %s" % talent.talent_name)

func _on_button_mouse_exited(button: Button):
	# Remove highlight
	button.scale = Vector2.ONE

# Legacy setup function for backwards compatibility
func setup(sauce_name: String, level: int):
	# Call the new talent-based setup
	setup_with_talents(sauce_name, level)
