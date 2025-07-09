extends Control

signal upgrade_selected(choice_number: int)

@onready var sauce_info = $CenterPanel/MainContainer/SauceInfoLabel
@onready var button1 = $CenterPanel/MainContainer/ChoicesContainer/Choice1/Button1
@onready var button2 = $CenterPanel/MainContainer/ChoicesContainer/Choice2/Button2
@onready var button3 = $CenterPanel/MainContainer/ChoicesContainer/Choice3/Button3
@onready var desc1 = $CenterPanel/MainContainer/ChoicesContainer/Choice1/Description1
@onready var desc2 = $CenterPanel/MainContainer/ChoicesContainer/Choice2/Description2
@onready var desc3 = $CenterPanel/MainContainer/ChoicesContainer/Choice3/Description3

func _ready():
	get_tree().paused = true

	# Connect button signals
	button1.pressed.connect(_on_choice_1)
	button2.pressed.connect(_on_choice_2)
	button3.pressed.connect(_on_choice_3)

func setup(sauce_name: String, level: int):
	sauce_info.text = "%s reached Level %d" % [sauce_name, level]

	# Set upgrade options based on sauce type
	match sauce_name:
		"Ketchup":
			button1.text = "Thick & Chunky"
			desc1.text = "+5 Damage\nGrandpa got heavy-handed"

			button2.text = "Double Squirt"
			desc2.text = "+1 Projectile\nTwo pumps better than one"

			button3.text = "Fast Food"
			desc3.text = "+0.3 Fire Rate\nWaiting is for restaurants"

		"Prehistoric Pesto":
			button1.text = "Viral Load"
			desc1.text = "+30% Effect Chance\nSpreads like gossip"

			button2.text = "Rapid Mutation"
			desc2.text = "+0.5 Fire Rate\nEvolution doesn't wait"

			button3.text = "Toxic Herbs"
			desc3.text = "+3 Damage\nSurvived the meteor"

		_:
			button1.text = "More Damage"
			desc1.text = "+3 Damage"

			button2.text = "Faster Shooting"
			desc2.text = "+0.2 Fire Rate"

			button3.text = "Longer Range"
			desc3.text = "+20 Range"

func _on_choice_1():
	print("Chose upgrade 1")
	upgrade_selected.emit(1)
	_close_menu()

func _on_choice_2():
	print("Chose upgrade 2")
	upgrade_selected.emit(2)
	_close_menu()

func _on_choice_3():
	print("Chose upgrade 3")
	upgrade_selected.emit(3)
	_close_menu()

func _close_menu():
	get_tree().paused = false
	queue_free()
