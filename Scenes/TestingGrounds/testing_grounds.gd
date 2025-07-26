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
	setup_testing_camera()
	setup_testing_dummies()
	setup_ui_controls()
	print("🎯 Testing Grounds ready!")

func setup_testing_camera():
	"""Setup dedicated testing camera with better zoom"""
	# Disable player camera for testing
	var player = get_node("Player")
	if player:
		var player_camera = player.get_node("Camera2D")
		if player_camera:
			player_camera.enabled = false

	# Create testing camera
	var testing_camera = Camera2D.new()
	testing_camera.name = "TestingCamera"
	testing_camera.zoom = Vector2(3.0, 3.0)
	testing_camera.enabled = true
	add_child(testing_camera)
	testing_camera.make_current()

	print("📷 Testing camera activated (zoomed out for better view)")

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

	# Store reference for updating
	damage_slider.value_changed.connect(func(value): damage_value_label.text = "%.1f" % value)

	testing_panel.add_child(damage_container)

	# Reset button
	var reset_button = Button.new()
	reset_button.text = "Reset All Dummies"
	reset_button.pressed.connect(_on_reset_all_dummies)
	testing_panel.add_child(reset_button)

	# Effect testing buttons
	var effect_container = HBoxContainer.new()

	var burn_button = Button.new()
	burn_button.text = "Apply Burn"
	burn_button.pressed.connect(func(): _apply_effect_to_all("burn", 3))
	effect_container.add_child(burn_button)

	var fossilize_button = Button.new()
	fossilize_button.text = "Apply Fossilize"
	fossilize_button.pressed.connect(func(): _apply_effect_to_all("fossilize", 2))
	effect_container.add_child(fossilize_button)

	var infect_button = Button.new()
	infect_button.text = "Apply Infect"
	infect_button.pressed.connect(func(): _apply_effect_to_all("infect", 4))
	effect_container.add_child(infect_button)

	testing_panel.add_child(effect_container)

	# Testing scenario buttons
	var scenario_container = VBoxContainer.new()
	var scenario_label = Label.new()
	scenario_label.text = "Testing Scenarios:"
	scenario_container.add_child(scenario_label)

	var fossil_fuel_button = Button.new()
	fossil_fuel_button.text = "Test Fossil Fuel"
	fossil_fuel_button.pressed.connect(_test_complete_fossil_fuel_scenario)
	scenario_container.add_child(fossil_fuel_button)

	var area_effects_button = Button.new()
	area_effects_button.text = "Test Area Effects"
	area_effects_button.pressed.connect(_test_area_effects_scenario)
	scenario_container.add_child(area_effects_button)

	testing_panel.add_child(scenario_container)

# Event handlers
func _on_xp_toggle(enabled: bool):
	"""Toggle XP gain for all dummies"""
	for dummy in all_dummies:
		dummy.xp_enabled = enabled
	print("🎓 XP gain %s for all dummies" % ("enabled" if enabled else "disabled"))

func _on_damage_multiplier_changed(value: float):
	"""Change damage multiplier for all dummies"""
	for dummy in all_dummies:
		dummy.damage_multiplier = value
	print("⚔️ Damage multiplier set to %.1fx" % value)

func _on_reset_all_dummies():
	"""Reset all dummies to full health and clear effects"""
	for dummy in all_dummies:
		dummy.reset_dummy()
	print("🔄 All dummies reset")

func _apply_effect_to_all(effect_name: String, stacks: int):
	"""Apply an effect to all dummies for testing"""
	for dummy in all_dummies:
		dummy.apply_manual_effect(effect_name, stacks)
	print("🧪 Applied %dx %s to all dummies" % [stacks, effect_name])

func _on_dummy_damage_dealt(amount: float, source: String):
	"""Handle damage dealt signal from dummies"""
	# This gets called whenever any dummy takes damage
	# Used for aggregate DPS tracking if needed

func _on_talent_applied(talent_name: String, bottle_name: String):
	"""Handle talent application from talent panel"""
	print("✨ Talent applied: %s to %s" % [talent_name, bottle_name])

# DPS Display Updates
func _process(delta: float):
	"""Update DPS display"""
	dps_update_timer += delta

	if dps_update_timer >= dps_update_interval:
		_update_dps_display()
		dps_update_timer = 0.0

func _update_dps_display():
	"""Update the DPS display with current stats"""
	if not solo_dummy or not is_instance_valid(solo_dummy):
		return

	var stats = solo_dummy.get_damage_stats()

	if dps_label:
		dps_label.text = "DPS: %.1f" % stats.dps

	if total_damage_label:
		total_damage_label.text = "Total: %.0f" % stats.total_damage

	if time_label:
		time_label.text = "Time: %.1fs" % stats.elapsed_time

# Talent testing functions
func _test_fossil_fuel_talent():
	"""Test applying Fossil Fuel talent"""
	print("🧪 Testing Fossil Fuel talent application...")

	if talent_panel and talent_panel.has_method("apply_talent_to_bottle"):
		var success = talent_panel.apply_talent_to_bottle("Fossil Fuel", "Hot Sauce")
		if success:
			print("✅ Fossil Fuel applied to Hot Sauce bottle")
			print("🔬 Now apply fossilization to dummy, then test burn damage")
			print("💡 Should see 2x burn damage on fossilized targets")
		else:
			print("❌ Could not apply Fossil Fuel talent")
	else:
		print("❌ Talent panel not available for testing")

func _test_fossilization_talent():
	"""Test applying Fossilization talent"""
	print("🧪 Testing Fossilization talent application...")

	if talent_panel and talent_panel.has_method("apply_talent_to_bottle"):
		var success = talent_panel.apply_talent_to_bottle("Fossilization", "Apple Butter")
		if success:
			print("✅ Fossilization applied to Apple Butter bottle")
			print("🔬 Apple Butter projectiles should now fossilize targets on hit")
			print("💡 Test on dummies.")
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
