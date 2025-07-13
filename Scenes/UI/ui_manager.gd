# Scenes/UI/ui_manager.gd
extends Control

@onready var game_ui = $GameUI
@onready var menu_ui = $MenuUI

@onready var inventory_button = $GameUI/InventoryButton
@onready var xp_bar = $GameUI/XPBar
@onready var xp_label = $GameUI/XPText
@onready var current_level = $GameUI/Level
const INVENTORY = preload("res://Scenes/UI/inventory.tscn")
const LEVEL_UP_MENU = preload("res://Scenes/UI/level_up.tscn")
const UPGRADE_CHOICE_MENU = preload("res://Scenes/UI/upgrade_choice_menu.tscn")

func _ready() -> void:
	inventory_button.pressed.connect(_on_inventory_pressed)
	PlayerStats.xp_changed.connect(update_xp_display)
	PlayerStats.leveled_up.connect(_on_level_up)
	if current_level:
		current_level.text = "%d" % PlayerStats.level
	update_xp_display(PlayerStats.xp, PlayerStats.xp_to_next)

	# DIRECT CONNECTION to InventoryManager - No separate singletons!
	InventoryManager.bottle_leveled_up.connect(_on_bottle_leveled_up)
	print("UI Manager connected directly to InventoryManager")

func _on_inventory_pressed():
	get_tree().paused = true
	var inventory = INVENTORY.instantiate()
	menu_ui.add_child(inventory)

func update_xp_display(current_xp: int, max_xp: int):
	if xp_bar:
		xp_bar.max_value = max_xp
		xp_bar.value = current_xp

	if xp_label:
		xp_label.text = str(current_xp) + "/" + str(max_xp)

func _on_bottle_leveled_up(bottle_id: String, sauce_name: String, level: int):
	print("UI Manager: %s leveled up to %d" % [sauce_name, level])

	var upgrade_menu = UPGRADE_CHOICE_MENU.instantiate()
	menu_ui.add_child(upgrade_menu)
	upgrade_menu.setup(sauce_name, level)
	# FIX: Use lambda to get the parameters in the right order
	upgrade_menu.upgrade_selected.connect(func(choice_number): _on_upgrade_chosen(bottle_id, choice_number))

func _on_upgrade_chosen(bottle_id: String, choice_number: int):
	print("UI Manager: Forwarding choice %d for bottle %s" % [choice_number, bottle_id])
	# DIRECT CALL to InventoryManager - No separate singletons!
	InventoryManager.apply_upgrade_choice(bottle_id, choice_number)

func _on_level_up(level: int):
	var level_up_menu =  LEVEL_UP_MENU.instantiate()
	get_tree().paused = true
	menu_ui.add_child(level_up_menu)
	if current_level:
		current_level.text = "%d" % level
