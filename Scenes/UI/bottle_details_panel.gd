# Scenes/UI/bottle_details_panel.gd
class_name BottleDetailsPanel
extends Control

@onready var bottle_name = $VBox/BottleName
@onready var bottle_level = $VBox/BottleLevel
@onready var bottle_sprite = $VBox/SpriteContainer/BottleSprite
@onready var damage_label = $VBox/StatsContainer/DamageLabel
@onready var fire_rate_label = $VBox/StatsContainer/FireRateLabel
@onready var range_label = $VBox/StatsContainer/RangeLabel
@onready var xp_bar = $VBox/XPContainer/XPBar
@onready var xp_label = $VBox/XPContainer/XPLabel
@onready var upgrades_container = $VBox/UpgradesContainer
@onready var upgrades_list = $VBox/UpgradesContainer/UpgradesList

const BOTTLE_TEXTURE = preload("res://Assets/Sprites/Bottles/basebottle.png")

var current_bottle: ImprovedBaseSauceBottle = null

func _ready():
	hide()
	# Connect to talent system for auto-refresh
	if InventoryManager:
		InventoryManager.talent_applied.connect(_on_talent_applied)
		InventoryManager.talent_removed.connect(_on_talent_removed)
		InventoryManager.bottle_respecced.connect(_on_bottle_respecced)

func _on_talent_applied(bottle: ImprovedBaseSauceBottle, talent: Talent):
	# Refresh display if this is the currently shown bottle
	if current_bottle and bottle.bottle_id == current_bottle.bottle_id:
		print("Refreshing bottle details after talent applied: %s" % talent.talent_name)
		show_bottle_details(bottle)

func _on_talent_removed(bottle: ImprovedBaseSauceBottle, talent: Talent):
	# Refresh display if this is the currently shown bottle
	if current_bottle and bottle.bottle_id == current_bottle.bottle_id:
		print("Refreshing bottle details after talent removed: %s" % talent.talent_name)
		show_bottle_details(bottle)

func _on_bottle_respecced(bottle: ImprovedBaseSauceBottle):
	# Refresh display if this is the currently shown bottle
	if current_bottle and bottle.bottle_id == current_bottle.bottle_id:
		print("Refreshing bottle details after respec")
		show_bottle_details(bottle)

func show_bottle_details(bottle: ImprovedBaseSauceBottle):
	if not bottle or not bottle.sauce_data:
		hide()
		return

	current_bottle = bottle
	var sauce_data = bottle.sauce_data

	# Basic info
	bottle_name.text = sauce_data.sauce_name
	bottle_level.text = "Level %d" % bottle.current_level

	# Sprite with color
	bottle_sprite.texture = BOTTLE_TEXTURE
	bottle_sprite.modulate = sauce_data.sauce_color

	# Current stats (accounting for level scaling AND talent modifiers)
	var current_damage = sauce_data.get_current_damage(bottle.current_level)
	var current_fire_rate = sauce_data.get_current_fire_rate(bottle.current_level)
	var current_range = sauce_data.get_current_range(bottle.current_level)

	# Apply talent modifiers for display (if methods exist)
	if bottle.has_method("get_modified_damage"):
		current_damage = bottle.get_modified_damage(current_damage)
	if bottle.has_method("get_modified_fire_rate"):
		current_fire_rate = bottle.get_modified_fire_rate(current_fire_rate)
	if bottle.has_method("get_modified_range"):
		current_range = bottle.get_modified_range(current_range)

	damage_label.text = "Damage: %.1f" % bottle.effective_damage
	fire_rate_label.text = "Fire Rate: %.1f/sec" % current_fire_rate
	range_label.text = "Range: %.0f" % current_range

	# XP Progress
	if bottle.current_level < bottle.max_level:
		xp_bar.max_value = bottle.xp_to_next_level
		xp_bar.value = bottle.current_xp
		xp_label.text = "%d / %d XP" % [bottle.current_xp, bottle.xp_to_next_level]
		xp_bar.visible = true
		xp_label.visible = true
	else:
		xp_bar.visible = false
		xp_label.text = "MAX LEVEL"
		xp_label.visible = true

	# Show upgrades
	update_upgrades_display()

	show()

func update_upgrades_display():
	# Clear existing upgrade labels
	for child in upgrades_list.get_children():
		child.queue_free()

	if current_bottle and current_bottle.chosen_upgrades.size() > 0:
		upgrades_container.visible = true

		# Add title for upgrades section
		var title_label = Label.new()
		title_label.text = "Applied Talents:"
		title_label.add_theme_color_override("font_color", Color.YELLOW)
		title_label.add_theme_font_size_override("font_size", 14)
		upgrades_list.add_child(title_label)

		# Add each upgrade
		for upgrade in current_bottle.chosen_upgrades:
			var upgrade_label = Label.new()
			upgrade_label.text = "• " + upgrade
			upgrade_label.add_theme_color_override("font_color", Color.LIGHT_GREEN)
			upgrade_label.add_theme_font_size_override("font_size", 12)
			upgrade_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			upgrades_list.add_child(upgrade_label)

		# Add talent summary (if method exists)
		if current_bottle.has_method("get_talent_summary"):
			var summary = current_bottle.get_talent_summary()
			if summary["active_talents"] > 0:
				var summary_label = Label.new()
				summary_label.text = "\nTalent Summary:"
				summary_label.add_theme_color_override("font_color", Color.CYAN)
				summary_label.add_theme_font_size_override("font_size", 12)
				upgrades_list.add_child(summary_label)

				var stats_label = Label.new()
				var stats_text = "• Active Talents: %d\n• Stat Modifiers: %d\n• Special Effects: %d" % [
					summary["active_talents"],
					summary.get("stat_modifiers", 0),
					summary.get("special_effects", 0)
				]
				stats_label.text = stats_text
				stats_label.add_theme_color_override("font_color", Color.LIGHT_BLUE)
				stats_label.add_theme_font_size_override("font_size", 10)
				upgrades_list.add_child(stats_label)
	else:
		upgrades_container.visible = false

func hide_details():
	hide()
	current_bottle = null
