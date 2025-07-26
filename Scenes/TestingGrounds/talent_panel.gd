# Scenes/TestingGrounds/TalentPanel.gd
extends Panel

@onready var bottle_selector = $VBox/BottleSelector/BottleDropdown
@onready var sauce_selector = $VBox/SauceSelector/SauceDropdown
@onready var talent_list = $VBox/TalentList/ScrollContainer/TalentVbox
@onready var selected_bottle_info = $VBox/SelectedBottleInfo/InfoLabel
@onready var apply_button = $VBox/ApplyButton
@onready var clear_button = $VBox/ClearButton

# References
var current_bottles: Array[ImprovedBaseSauceBottle] = []
var selected_bottle: ImprovedBaseSauceBottle
var selected_talent: Talent
var available_talents: Dictionary = {}  # sauce_name -> Array[Talent]

signal talent_applied(bottle: ImprovedBaseSauceBottle, talent: Talent)

func _ready():
	print("=== TalentPanel Node Debug ===")
	print("bottle_selector: ", bottle_selector)
	print("sauce_selector: ", sauce_selector)
	print("talent_list: ", talent_list)
	print("selected_bottle_info: ", selected_bottle_info)
	print("apply_button: ", apply_button)
	print("clear_button: ", clear_button)
	print("==============================")

	# Debug ScrollContainer
	if talent_list and talent_list.get_parent():
		var scroll_container = talent_list.get_parent()
		print("ScrollContainer size: %s" % scroll_container.size)
		print("ScrollContainer visible: %s" % scroll_container.visible)

	setup_ui()
	refresh_bottle_list()
	setup_sauce_talents()

func setup_ui():
	"""Initialize UI components"""

	# Bottle selector
	bottle_selector.item_selected.connect(_on_bottle_selected)

	# Sauce selector
	sauce_selector.item_selected.connect(_on_sauce_selected)

	# Apply/Clear buttons
	apply_button.pressed.connect(_on_apply_talent)
	apply_button.disabled = true
	clear_button.pressed.connect(_on_clear_bottle_talents)

	print("🎨 Talent Panel initialized")

func setup_sauce_talents():
	"""Load all available talents from each sauce"""
	available_talents.clear()

	print("=== DEBUG: TalentManager.talent_pools ===")
	print("talent_pools keys: ", TalentManager.talent_pools.keys())
	for key in TalentManager.talent_pools.keys():
		print("  %s: %d talents" % [key, TalentManager.talent_pools[key].size()])
	print("=======================================")

	# Get talents from TalentManager's talent_pools
	if TalentManager.talent_pools.has("Hot Sauce"):
		available_talents["Hot Sauce"] = TalentManager.talent_pools["Hot Sauce"]
		print("✅ Loaded Hot Sauce: %d talents" % available_talents["Hot Sauce"].size())
	else:
		print("❌ No Hot Sauce in talent_pools")

	if TalentManager.talent_pools.has("Prehistoric Pesto"):
		available_talents["Prehistoric Pesto"] = TalentManager.talent_pools["Prehistoric Pesto"]
		print("✅ Loaded Prehistoric Pesto: %d talents" % available_talents["Prehistoric Pesto"].size())
	else:
		print("❌ No Prehistoric Pesto in talent_pools")

	if TalentManager.talent_pools.has("Archaean Apple Butter"):
		available_talents["Archaean Apple Butter"] = TalentManager.talent_pools["Archaean Apple Butter"]
		print("✅ Loaded Archaean Apple Butter: %d talents" % available_talents["Archaean Apple Butter"].size())
	else:
		print("❌ No Archaean Apple Butter in talent_pools")

	# Shared talents
	available_talents["Shared"] = _get_shared_talents()
	print("✅ Loaded Shared: %d talents" % available_talents["Shared"].size())

	# Populate sauce dropdown
	sauce_selector.clear()
	for sauce_name in available_talents.keys():
		sauce_selector.add_item(sauce_name)

	print("🎯 Loaded talents for %d sauce types" % available_talents.size())

func _get_shared_talents() -> Array[Talent]:
	"""Get all shared/cross-sauce talents"""
	var shared_talents: Array[Talent] = []

	# Add Fossil Fuel talent
	shared_talents.append(SharedTalents.fossil_fuel_talent())

	# Add other shared talents as they're created
	# shared_talents.append(SharedTalents.extinction_event_talent())
	# shared_talents.append(SharedTalents.primordial_soup_talent())

	return shared_talents

func refresh_bottle_list():
	"""Refresh the list of available bottles"""
	current_bottles.clear()
	bottle_selector.clear()

	# Get equipped bottles
	var equipped_bottles = InventoryManager.get_equipped_bottles()
	for bottle in equipped_bottles:
		if bottle:
			current_bottles.append(bottle)
			var bottle_name = "%s (Equipped)" % bottle.sauce_data.sauce_name
			bottle_selector.add_item(bottle_name)

	# Get storage bottles - access storage array directly
	for i in range(InventoryManager.storage.size()):
		var bottle = InventoryManager.storage[i]
		if bottle:
			current_bottles.append(bottle)
			var bottle_name = "%s (Storage)" % bottle.sauce_data.sauce_name
			bottle_selector.add_item(bottle_name)

	print("🍶 Found %d bottles for talent testing" % current_bottles.size())

func _on_bottle_selected(index: int):
	"""Handle bottle selection"""
	if index >= 0 and index < current_bottles.size():
		selected_bottle = current_bottles[index]
		_update_bottle_info()
		_check_can_apply()
	else:
		selected_bottle = null
		selected_bottle_info.text = "No bottle selected"

func _on_sauce_selected(index: int):
	"""Handle sauce type selection - populate talent list"""
	var sauce_names = available_talents.keys()
	if index >= 0 and index < sauce_names.size():
		var sauce_name = sauce_names[index]
		_populate_talent_list(sauce_name)

func _populate_talent_list(sauce_name: String):
	"""Populate the talent list for selected sauce"""
	print("=== DEBUG: Populating talents for %s ===" % sauce_name)
	print("available_talents keys: ", available_talents.keys())
	print("available_talents[%s] size: %d" % [sauce_name, available_talents.get(sauce_name, []).size()])

	# Clear existing talent buttons
	for child in talent_list.get_children():
		child.queue_free()

	selected_talent = null

	if not sauce_name in available_talents:
		print("❌ %s not found in available_talents" % sauce_name)
		return

	var talents = available_talents[sauce_name]
	print("📋 Found %d talents for %s" % [talents.size(), sauce_name])

	for i in range(talents.size()):
		var talent = talents[i]
		print("  %d. %s (Level %d)" % [i+1, talent.talent_name, talent.level_required])

		var talent_button = Button.new()
		talent_button.text = "%s (Lv %d)" % [talent.talent_name, talent.level_required]
		talent_button.tooltip_text = talent.description
		talent_button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		talent_button.custom_minimum_size = Vector2(200, 50)

		# Style the button to make it visible
		talent_button.add_theme_color_override("font_color", Color.YELLOW)
		talent_button.add_theme_color_override("font_color_hover", Color.WHITE)

		# Connect button
		talent_button.pressed.connect(_on_talent_selected.bind(talent))

		# Add directly to talent_list
		talent_list.add_child(talent_button)

	print("🎨 Added %d talent buttons to list" % talent_list.get_child_count())

func _on_talent_selected(talent: Talent):
	"""Handle talent selection"""
	selected_talent = talent

	# Highlight selected talent button
	for button in talent_list.get_children():
		button.modulate = Color.WHITE

	# Find and highlight the selected button
	for button in talent_list.get_children():
		if button.text == talent.talent_name:
			button.modulate = Color.YELLOW
			break

	print("🎯 Selected talent: %s" % talent.talent_name)
	_check_can_apply()

func _check_can_apply():
	"""Check if talent can be applied to selected bottle"""
	var can_apply = selected_bottle != null and selected_talent != null
	apply_button.disabled = not can_apply

	if can_apply:
		apply_button.text = "Apply '%s' to %s" % [selected_talent.talent_name, selected_bottle.sauce_data.sauce_name]
	else:
		apply_button.text = "Select Bottle and Talent"

func _update_bottle_info():
	"""Update the selected bottle information display"""
	if not selected_bottle:
		selected_bottle_info.text = "No bottle selected"
		return

	var info_text = ""
	info_text += "Bottle: %s\n" % selected_bottle.sauce_data.sauce_name
	info_text += "Level: %d\n" % selected_bottle.current_level
	info_text += "Active Talents: %d\n" % selected_bottle.active_talents.size()

	# List current talents
	if selected_bottle.active_talents.size() > 0:
		info_text += "\nCurrent Talents:\n"
		for talent in selected_bottle.active_talents:
			info_text += "• %s\n" % talent.talent_name

	# List trigger effects
	if selected_bottle.trigger_effects.size() > 0:
		info_text += "\nTrigger Effects:\n"
		for trigger in selected_bottle.trigger_effects:
			var enhances_text = ""
			if trigger.enhances.size() > 0:
				enhances_text = " (enhances: %s)" % ", ".join(trigger.enhances)
			info_text += "• %s%s\n" % [trigger.trigger_name, enhances_text]

	selected_bottle_info.text = info_text

func _on_apply_talent():
	"""Apply selected talent to selected bottle"""
	if not selected_bottle or not selected_talent:
		return

	print("🎨 Applying talent '%s' to bottle '%s'" % [selected_talent.talent_name, selected_bottle.sauce_data.sauce_name])

	# Apply the talent using InventoryManager
	InventoryManager.apply_specific_talent(selected_bottle.bottle_id, selected_talent)

	# Update bottle info display
	_update_bottle_info()

	# Emit signal for testing grounds
	talent_applied.emit(selected_talent.talent_name, selected_bottle.sauce_data.sauce_name)

	print("✅ Talent applied successfully!")

func _on_clear_bottle_talents():
	"""Clear all talents from selected bottle"""
	if not selected_bottle:
		return

	print("🗑️ Clearing all talents from bottle '%s'" % selected_bottle.sauce_data.sauce_name)

	# Clear talents
	selected_bottle.active_talents.clear()
	selected_bottle.trigger_effects.clear()

	# Reset bottle stats
	selected_bottle.recalculate_all_effective_stats()

	# Refresh trigger actions
	TriggerActionManager.refresh_active_triggers(selected_bottle)

	# Update display
	_update_bottle_info()

	print("🗑️ All talents cleared from bottle")

# Utility functions for testing grounds integration
func get_selected_bottle() -> ImprovedBaseSauceBottle:
	"""Get currently selected bottle"""
	return selected_bottle

func select_bottle_by_name(bottle_name: String) -> bool:
	"""Select a bottle by its sauce name"""
	for i in range(current_bottles.size()):
		if current_bottles[i].sauce_data.sauce_name == bottle_name:
			bottle_selector.selected = i
			_on_bottle_selected(i)
			return true
	return false

func apply_talent_by_name(sauce_name: String, talent_name: String) -> bool:
	"""Apply a specific talent by name"""
	if not sauce_name in available_talents:
		return false

	var talents = available_talents[sauce_name]
	for talent in talents:
		if talent.talent_name == talent_name:
			selected_talent = talent
			_on_apply_talent()
			return true
	return false

# Testing shortcuts
func quick_test_fossil_fuel():
	"""Quickly apply fossil fuel to first Hot Sauce bottle"""
	# Find first Hot Sauce bottle
	for bottle in current_bottles:
		if bottle.sauce_data.sauce_name == "Hot Sauce":
			selected_bottle = bottle
			break

	if not selected_bottle:
		print("❌ No Hot Sauce bottle found for Fossil Fuel test")
		return false

	# Apply Fossil Fuel talent
	return apply_talent_by_name("Shared", "Fossil Fuel")

func quick_test_fossilization():
	"""Quickly apply fossilization to first Apple Butter bottle"""
	# Find first Apple Butter bottle
	for bottle in current_bottles:
		if "Apple Butter" in bottle.sauce_data.sauce_name:
			selected_bottle = bottle
			break

	if not selected_bottle:
		print("❌ No Apple Butter bottle found for Fossilization test")
		return false

	# Apply a fossilization talent
	return apply_talent_by_name("Archaean Apple Butter", "Sedimentary Layers")
