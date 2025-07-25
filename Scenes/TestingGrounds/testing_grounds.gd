# Scenes/TestingGrounds/testing_grounds.gd
extends Node2D

# UI References
@onready var testing_panel = $UI/TestingPanel
@onready var dps_display = $UI/DPSDisplay
@onready var dps_label = $UI/DPSDisplay/DPSLabel
@onready var total_damage_label = $UI/DPSDisplay/TotalDamageLabel
@onready var time_label = $UI/DPSDisplay/TimeLabel
@onready var talent_panel = $UI/TalentPanel

# Dummy references
var solo_dummy: Node2D
var pack_dummies: Array[Node2D] = []
var all_dummies: Array[Node2D] = []

# DPS tracking
var dps_update_timer: float = 0.0
var dps_update_interval: float = 0.1  # Update 10x per second

func _ready():
	setup_testing_dummies()
	setup_ui_controls()
	print("🎯 Testing Grounds ready!")

func setup_testing_dummies():
	"""Create training dummies in testing formation"""
	var dummy_scene = preload("res://Scenes/TestingGrounds/training_dummy.tscn")

	# Solo dummy (left side)
	solo_dummy = dummy_scene.instantiate()
	solo_dummy.global_position = Vector2(-200, 0)
	solo_dummy.dummy_name = "Solo Target"
	add_child(solo_dummy)
	all_dummies.append(solo_dummy)

	# Pack of 3 dummies (right side, clustered for area effects)
	var pack_positions = [
		Vector2(150, -40),   # Top
		Vector2(200, 20),    # Bottom right
		Vector2(100, 20)     # Bottom left
	]

	for i in range(3):
		var dummy = dummy_scene.instantiate()
		dummy.global_position = pack_positions[i]
		dummy.dummy_name = "Pack #%d" % (i + 1)
		add_child(dummy)
		pack_dummies.append(dummy)
		all_dummies.append(dummy)

	# Connect damage signals for DPS tracking
	for dummy in all_dummies:
		dummy.damage_dealt.connect(_on_dummy_damage_dealt)

	print("✅ Created %d training dummies" % all_dummies.size())

func setup_ui_controls():
	"""Setup the testing UI controls"""

	# Connect talent panel
	if talent_panel:
		talent_panel.talent_applied.connect(_on_talent_applied)

	# XP Toggle
	var xp_toggle = CheckBox.new()
	xp_toggle.text = "Enable XP Gain"
	xp_toggle.toggled.connect(_on_xp_toggle)
	testing_panel.add_child(xp_toggle)

	# Damage multiplier
	var damage_container = HBoxContainer.new()
	var damage_label = Label.new()
	damage_label.text = "Damage ×"
	damage_container.add_child(damage_label)

	var damage_slider = HSlider.new()
	damage_slider.min_value = 0.1
	damage_slider.max_value = 10.0
	damage_slider.step = 0.1
	damage_slider.value = 1.0
	damage_slider.custom_minimum_size.x = 150
	damage_slider.value_changed.connect(_on_damage_multiplier_changed)
	damage_container.add_child(damage_slider)

	var damage_value_label = Label.new()
	damage_value_label.text = "1.0"
	damage_container.add_child(damage_value_label)
	testing_panel.add_child(damage_container)

	# Store reference for updating
	damage_slider.set_meta("value_label", damage_value_label)

	# Reset button
	var reset_button = Button.new()
	reset_button.text = "Reset All Dummies"
	reset_button.pressed.connect(_on_reset_all_dummies)
	testing_panel.add_child(reset_button)

	# DPS Reset button
	var dps_reset_button = Button.new()
	dps_reset_button.text = "Reset DPS Counter"
	dps_reset_button.pressed.connect(_on_reset_dps)
	testing_panel.add_child(dps_reset_button)

	# Manual effect buttons
	var effects_label = Label.new()
	effects_label.text = "Apply Effects:"
	testing_panel.add_child(effects_label)

	var effects_container = HBoxContainer.new()

	var fossil_button = Button.new()
	fossil_button.text = "Fossilize All"
	fossil_button.pressed.connect(func(): _apply_effect_to_all("fossilize"))
	effects_container.add_child(fossil_button)

	var burn_button = Button.new()
	burn_button.text = "Burn All"
	burn_button.pressed.connect(func(): _apply_effect_to_all("burn"))
	effects_container.add_child(burn_button)

	var infect_button = Button.new()
	infect_button.text = "Infect All"
	infect_button.pressed.connect(func(): _apply_effect_to_all("infect"))
	effects_container.add_child(infect_button)

	testing_panel.add_child(effects_container)

	# Testing scenario buttons
	var scenarios_label = Label.new()
	scenarios_label.text = "Test Scenarios:"
	testing_panel.add_child(scenarios_label)

	var scenarios_container = HBoxContainer.new()

	var fossil_fuel_button = Button.new()
	fossil_fuel_button.text = "Test Fossil Fuel"
	fossil_fuel_button.pressed.connect(_test_fossil_fuel_scenario)
	scenarios_container.add_child(fossil_fuel_button)

	var area_test_button = Button.new()
	area_test_button.text = "Test Area Effects"
	area_test_button.pressed.connect(_test_area_effects_scenario)
	scenarios_container.add_child(area_test_button)

	testing_panel.add_child(scenarios_container)

	# Add quick test buttons that use the talent panel
	var quick_tests_label = Label.new()
	quick_tests_label.text = "Quick Tests:"
	testing_panel.add_child(quick_tests_label)

	var quick_tests_container = HBoxContainer.new()

	var fossil_fuel_quick = Button.new()
	fossil_fuel_quick.text = "Quick Fossil Fuel"
	fossil_fuel_quick.pressed.connect(_quick_fossil_fuel_test)
	quick_tests_container.add_child(fossil_fuel_quick)

	var fossilization_quick = Button.new()
	fossilization_quick.text = "Quick Fossilization"
	fossilization_quick.pressed.connect(_quick_fossilization_test)
	quick_tests_container.add_child(fossilization_quick)

	testing_panel.add_child(quick_tests_container)

func _process(delta: float):
	"""Update DPS display"""
	dps_update_timer += delta

	if dps_update_timer >= dps_update_interval:
		_update_dps_display()
		dps_update_timer = 0.0

func _update_dps_display():
	"""Update the DPS display with current stats"""
	var total_dps: float = 0.0
	var total_damage: float = 0.0
	var max_time: float = 0.0

	# Aggregate stats from all dummies
	for dummy in all_dummies:
		var stats = dummy.get_damage_stats()
		total_dps += stats.dps
		total_damage += stats.total_damage
		max_time = max(max_time, stats.elapsed_time)

	# Update labels
	if dps_label:
		dps_label.text = "DPS: %.1f" % total_dps
	if total_damage_label:
		total_damage_label.text = "Total: %.0f" % total_damage
	if time_label:
		time_label.text = "Time: %.1fs" % max_time

# Event handlers
func _on_xp_toggle(enabled: bool):
	"""Toggle XP gain for all dummies"""
	for dummy in all_dummies:
		dummy.xp_enabled = enabled
	print("🎯 XP gain %s" % ("enabled" if enabled else "disabled"))

func _on_damage_multiplier_changed(value: float):
	"""Change damage multiplier for all dummies"""
	for dummy in all_dummies:
		dummy.damage_multiplier = value

	# Update the value label
	var slider = get_viewport().gui_get_focus_owner()
	if slider and slider.has_meta("value_label"):
		var label = slider.get_meta("value_label")
		label.text = "%.1f" % value

	print("⚔️ Damage multiplier set to %.1fx" % value)

func _on_reset_all_dummies():
	"""Reset all dummies to full health"""
	for dummy in all_dummies:
		dummy.reset_dummy()
	print("🔄 All dummies reset")

func _on_reset_dps():
	"""Reset DPS tracking for all dummies"""
	for dummy in all_dummies:
		dummy.total_damage_taken = 0.0
		dummy.damage_start_time = 0.0
		dummy.last_damage_time = 0.0
		dummy.damage_sources.clear()
	print("📊 DPS counters reset")

func _on_dummy_damage_dealt(amount: float, source: String):
	"""Handle damage dealt to any dummy"""
	# This is called whenever any dummy takes damage
	# DPS display is updated in _process()
	pass

func _apply_effect_to_all(effect_name: String):
	"""Apply an effect to all dummies"""
	for dummy in all_dummies:
		dummy.apply_manual_effect(effect_name, 1)
	print("🧪 Applied %s to all dummies" % effect_name)

# Talent Panel Integration
func _on_talent_applied(bottle: ImprovedBaseSauceBottle, talent: Talent):
	"""Handle talent application from the talent panel"""
	print("🎨 Talent '%s' applied to %s" % [talent.talent_name, bottle.sauce_data.sauce_name])

	# Update any displays that show bottle info
	_update_bottle_displays()

func _update_bottle_displays():
	"""Update any displays that show current bottle states"""
	# Refresh talent panel bottle list
	if talent_panel:
		talent_panel.refresh_bottle_list()

func _quick_fossil_fuel_test():
	"""Quick test for fossil fuel functionality"""
	if talent_panel and talent_panel.quick_test_fossil_fuel():
		print("🔥 Fossil Fuel applied! Now test on fossilized enemies.")
		# Apply fossilization to solo dummy for immediate testing
		if solo_dummy:
			solo_dummy.apply_manual_effect("fossilize", 1)
			print("🔶 Solo dummy fossilized for testing")
	else:
		print("❌ Could not apply Fossil Fuel (need Hot Sauce bottle)")

func _quick_fossilization_test():
	"""Quick test for fossilization functionality"""
	if talent_panel and talent_panel.quick_test_fossilization():
		print("🔶 Fossilization talent applied! Test on dummies.")
	else:
		print("❌ Could not apply fossilization talent (need Apple Butter bottle)")

# Testing scenarios
func _test_fossil_fuel_scenario():
	"""Test fossil fuel burn multiplier"""
	print("🧪 Testing Fossil Fuel scenario...")

	# Apply fossilization to solo dummy
	solo_dummy.apply_manual_effect("fossilize", 1)

	# Wait a moment, then apply burn
	await get_tree().create_timer(0.5).timeout
	solo_dummy.apply_manual_effect("burn", 1)

	print("🔬 Solo dummy should take 2x burn damage while fossilized")
	print("💡 Watch the damage numbers - should see 50 instead of 25 per stack!")

func _test_area_effects_scenario():
	"""Test area effects on the pack"""
	print("🧪 Testing area effects scenario...")

	# Apply infection to center dummy (should spread)
	if pack_dummies.size() > 0:
		pack_dummies[0].apply_manual_effect("infect", 2)

	print("🔬 Pack should demonstrate infection spreading")
	print("💡 Watch for infection chains between nearby dummies!")

func _test_complete_fossil_fuel_scenario():
	"""Complete fossil fuel test with talent application"""
	print("🧪 Running complete Fossil Fuel scenario...")

	# 1. Apply Fossil Fuel talent to Hot Sauce bottle
	if talent_panel:
		var success = talent_panel.quick_test_fossil_fuel()
		if not success:
			print("❌ Cannot test Fossil Fuel - no Hot Sauce bottle available")
			return

	# 2. Apply fossilization to solo dummy
	if solo_dummy:
		solo_dummy.apply_manual_effect("fossilize", 1)
		print("🔶 Solo dummy fossilized")

	# 3. Instructions for manual testing
	print("🔬 Complete test setup:")
	print("  1. ✅ Fossil Fuel talent applied to Hot Sauce bottle")
	print("  2. ✅ Solo dummy fossilized")
	print("  3. 🎯 Now shoot the fossilized dummy with Hot Sauce")
	print("  4. 👀 Watch for 2x burn damage (50 instead of 25 per stack)")

# Utility functions for advanced testing
func get_solo_dummy() -> Node2D:
	"""Get reference to solo dummy for specific tests"""
	return solo_dummy

func get_pack_dummies() -> Array[Node2D]:
	"""Get references to pack dummies for area effect tests"""
	return pack_dummies

func spawn_additional_dummy(position: Vector2, name: String = "Extra Dummy") -> Node2D:
	"""Spawn an additional dummy for custom tests"""
	var dummy_scene = preload("res://Scenes/TestingGrounds/training_dummy.tscn")
	var dummy = dummy_scene.instantiate()
	dummy.global_position = position
	dummy.dummy_name = name
	dummy.damage_dealt.connect(_on_dummy_damage_dealt)
	add_child(dummy)
	all_dummies.append(dummy)
	return dummy

# Input handling for testing shortcuts
func _input(event):
	"""Handle input for testing shortcuts"""
	if event.is_action_pressed("ui_accept"):  # Enter key
		_test_complete_fossil_fuel_scenario()
	elif event.is_action_pressed("ui_cancel"):  # Escape key
		_on_reset_all_dummies()
