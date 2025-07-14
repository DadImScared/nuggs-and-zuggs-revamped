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

	# Connect to new talent signals
	InventoryManager.talent_applied.connect(_on_talent_applied)
	InventoryManager.talent_removed.connect(_on_talent_removed)
	InventoryManager.bottle_respecced.connect(_on_bottle_respecced)

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
	upgrade_menu.setup_with_talents(sauce_name, level)
	upgrade_menu.talent_selected.connect(_on_talent_chosen.bind(bottle_id, level))

func _on_talent_chosen(bottle_id: String, level: int, choice_number: int):
	print("UI Manager: Forwarding level %d talent choice %d for bottle %s" % [level, choice_number, bottle_id])
	InventoryManager.apply_talent_choice_with_level(bottle_id, level, choice_number)

func _on_level_up(level: int):
	var level_up_menu = LEVEL_UP_MENU.instantiate()
	get_tree().paused = true
	menu_ui.add_child(level_up_menu)
	if current_level:
		current_level.text = "%d" % level

# Talent system feedback
func _on_talent_applied(bottle: ImprovedBaseSauceBottle, talent: Talent):
	# Show talent application feedback
	var feedback_text = "Talent Applied: %s" % talent.talent_name
	_show_talent_notification(feedback_text, Color.GOLD)

func _on_talent_removed(bottle: ImprovedBaseSauceBottle, talent: Talent):
	var feedback_text = "Talent Removed: %s" % talent.talent_name
	_show_talent_notification(feedback_text, Color.ORANGE)

func _on_bottle_respecced(bottle: ImprovedBaseSauceBottle):
	var feedback_text = "%s Respecced!" % bottle.sauce_data.sauce_name
	_show_talent_notification(feedback_text, Color.PURPLE)

func _show_talent_notification(text: String, color: Color = Color.WHITE):
	# Enhanced notification system
	var notification = Label.new()
	notification.text = text
	notification.add_theme_color_override("font_color", color)
	notification.add_theme_font_size_override("font_size", 20)
	notification.position = Vector2(20, 120)
	game_ui.add_child(notification)

	# Notification animation
	var tween = create_tween()
	tween.tween_property(notification, "position", Vector2(20, 100), 3.0)
	tween.parallel().tween_property(notification, "modulate:a", 0.0, 3.0)
	tween.tween_callback(notification.queue_free)

	print("📢 %s" % text)
