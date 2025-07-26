# Scenes/TestingGrounds/training_dummy.gd
extends CharacterBody2D

@onready var health_bar = $HealthBar
@onready var name_label = $NameLabel
@onready var effect_display = $EffectDisplay
@onready var damage_numbers = $DamageNumbers

# Dummy properties
var dummy_name: String = "Training Dummy"
var max_health: float = 10000.0
var health: float = 1000.0
var base_speed: float = 0.0  # Stationary
var move_speed: float = 0.0
var original_speed: float = 0.0

# Testing controls
var xp_enabled: bool = false
var damage_multiplier: float = 1.0
var invulnerable: bool = false

# Effects tracking (same interface as real enemies)
var active_effects: Dictionary = {}
var stacking_effects: Dictionary = {}
var damage_sources: Dictionary = {}

# Stack indicator system
var stack_indicator_container: Control
var stack_indicators: Dictionary = {}  # Track individual stack displays

# DPS tracking
var total_damage_taken: float = 0.0
var damage_start_time: float = 0.0
var last_damage_time: float = 0.0

# Signals
signal damage_dealt(amount: float, source: String)
signal effect_applied(effect_name: String, stacks: int)

func _ready():
	setup_dummy()
	_setup_stack_indicator()
	add_to_group("enemies")  # So bottles can target this
	add_to_group("training_dummies")

func setup_dummy():
	"""Initialize the training dummy"""
	health = max_health
	original_speed = base_speed
	move_speed = base_speed

	# Set up name
	if name_label:
		name_label.text = dummy_name

	# Set up health bar
	if health_bar:
		health_bar.max_value = max_health
		health_bar.value = health

	print("🎯 %s ready for testing" % dummy_name)

func _setup_stack_indicator():
	"""Create the stack indicator UI container"""
	# Create container for stack indicators
	stack_indicator_container = Control.new()
	stack_indicator_container.name = "StackIndicatorContainer"
	add_child(stack_indicator_container)

	# Position above the enemy (adjust Y offset as needed)
	stack_indicator_container.position = Vector2(0, -60)
	stack_indicator_container.z_index = 10  # Above other UI elements

# Combat interface (matches real enemies)
func take_damage_from_source(damage_amount: float, source_bottle_id: String):
	"""Take damage and track DPS"""
	if invulnerable:
		return

	var actual_damage = damage_amount * damage_multiplier
	health -= actual_damage

	# DPS tracking
	_track_damage(actual_damage, str(source_bottle_id))

	# Track damage sources
	if not damage_sources.has(source_bottle_id):
		damage_sources[source_bottle_id] = 0.0
	damage_sources[source_bottle_id] += actual_damage

	# Visual feedback
	_show_damage_number(actual_damage)
	_flash_damage()
	_update_health_bar()

	# Award XP if enabled
	if xp_enabled and actual_damage > 0:
		print("xp ------------------")
		var xp_amount = max(1, int(actual_damage * 0.1))
		PlayerStats.gain_xp(xp_amount)

	# Emit for DPS counter
	damage_dealt.emit(actual_damage, str(source_bottle_id))

	# Handle death
	if health <= 0:
		_handle_death()

# ADD THIS METHOD - This is what was missing!
func _execute_dot_tick_trigger(source_bottle_id: String, dot_type: String, damage_dealt: float):
	"""Execute DOT tick triggers when DOT effects deal damage"""
	var source_bottle = InventoryManager.get_bottle_by_id(source_bottle_id)
	if source_bottle:
		TriggerActionManager.execute_dot_tick_trigger(source_bottle, self, dot_type, damage_dealt)

func _track_damage(damage: float, source: String):
	"""Track damage for DPS calculations"""
	var current_time = Time.get_time_dict_from_system().get("unix", 0)

	# Start timer on first damage
	if total_damage_taken == 0:
		damage_start_time = current_time

	total_damage_taken += damage
	last_damage_time = current_time

func get_dps() -> float:
	"""Calculate current DPS"""
	if total_damage_taken == 0:
		return 0.0

	var current_time = Time.get_time_dict_from_system().get("unix", 0)
	var elapsed_time = current_time - damage_start_time

	if elapsed_time <= 0:
		return 0.0

	return total_damage_taken / elapsed_time

func get_damage_stats() -> Dictionary:
	"""Get comprehensive damage statistics"""
	var current_time = Time.get_time_dict_from_system().get("unix", 0)
	var elapsed_time = current_time - damage_start_time if total_damage_taken > 0 else 0

	return {
		"total_damage": total_damage_taken,
		"dps": get_dps(),
		"elapsed_time": elapsed_time,
		"damage_sources": damage_sources.duplicate()
	}

func _show_damage_number(damage: float):
	"""Show floating damage number"""
	var damage_label = Label.new()
	damage_label.text = "%.0f" % damage
	damage_label.modulate = Color.YELLOW
	damage_label.position = Vector2(randf_range(-20, 20), -30)

	if damage_numbers:
		damage_numbers.add_child(damage_label)
	else:
		add_child(damage_label)

	# Animate floating up and fade out
	var tween = create_tween()
	tween.parallel().tween_property(damage_label, "position", damage_label.position + Vector2(0, -40), 1.0)
	tween.parallel().tween_property(damage_label, "modulate:a", 0.0, 1.0)
	tween.tween_callback(damage_label.queue_free)

func _flash_damage():
	"""Flash red when taking damage"""
	if not has_node("Sprite"):
		return

	var sprite = get_node("Sprite")
	var original_color = sprite.color if sprite.has_method("color") else sprite.modulate

	if sprite.has_method("color"):
		sprite.color = Color.RED
		var tween = create_tween()
		tween.tween_property(sprite, "color", original_color, 0.2)
	else:
		sprite.modulate = Color.RED
		var tween = create_tween()
		tween.tween_property(sprite, "modulate", original_color, 0.2)

func _update_health_bar():
	"""Update health bar display"""
	if not health_bar:
		return

	health_bar.value = health

	# Color code health bar
	var health_percent = health / max_health
	if health_percent <= 0.2:
		health_bar.modulate = Color.RED
	elif health_percent <= 0.5:
		health_bar.modulate = Color.YELLOW
	else:
		health_bar.modulate = Color.GREEN

func _handle_death():
	"""Handle dummy death and respawn"""
	print("💀 %s destroyed! Respawning in 3 seconds..." % dummy_name)

	# Visual death state
	modulate = Color(0.5, 0.5, 0.5, 0.7)

	# Auto-respawn
	await get_tree().create_timer(3.0).timeout
	reset_dummy()

# Stacking effects system (compatible with your trigger system)
func apply_stacking_effect(
	effect_name: String,
	stack_value: float,
	max_stacks: int,
	source_id: String,
	duration: float,
	callbacks: Dictionary
):
	"""Apply stacking effect - same interface as real enemies"""
	if not stacking_effects.has(effect_name):
		stacking_effects[effect_name] = []

	# Check if we're at max stacks
	if stacking_effects[effect_name].size() >= max_stacks:
		print("⚠️ %s at max stacks (%d/%d)" % [effect_name, stacking_effects[effect_name].size(), max_stacks])
		return stacking_effects[effect_name].size()

	# Add new stack with proper start time
	var new_stack = {
		"value": stack_value,
		"source_id": source_id,
		"duration": duration,
		"timer": 0.0,
		"callbacks": callbacks,
		"start_time": Time.get_time_dict_from_system().get("unix", 0)
	}

	stacking_effects[effect_name].append(new_stack)

	# MATCH BASE ENEMY: Reset timer for ALL stacks when new stack is added
	for stack in stacking_effects[effect_name]:
		stack.timer = 0.0  # Refresh duration for entire effect
		if stack.has("tick_timer"):
			stack.tick_timer = 0.0  # Also reset tick timers

	# Execute immediate effect
	if callbacks.has("immediate_effect"):
		var immediate_callable = callbacks.immediate_effect
		if immediate_callable and immediate_callable.is_valid():
			immediate_callable.call()

	# Update stack indicator instead of text display
	_update_stack_indicator(effect_name)

	# Emit signal
	var stack_count = get_total_stack_count(effect_name)
	effect_applied.emit(effect_name, stack_count)

	print("🧪 %s: Applied %s (now %d stacks, duration refreshed to %.1fs)" % [dummy_name, effect_name, stack_count, duration])
	return stack_count

func get_total_stack_count(effect_name: String) -> int:
	"""Get total stacks of an effect"""
	if stacking_effects.has(effect_name):
		return stacking_effects[effect_name].size()
	return 0

func get_total_stacked_value(effect_name: String) -> float:
	"""Get total value of all stacks"""
	if not stacking_effects.has(effect_name):
		return 0.0

	var total = 0.0
	for stack in stacking_effects[effect_name]:
		total += stack.value
	return total

func _get_contributing_bottles(effect_name: String) -> Array:
	"""Get unique bottle IDs contributing to this effect"""
	if not stacking_effects.has(effect_name):
		return []

	var unique_bottles = []
	for stack in stacking_effects[effect_name]:
		if not unique_bottles.has(stack.source_id):
			unique_bottles.append(stack.source_id)

	return unique_bottles

func reset_dummy():
	"""Reset dummy to initial state"""
	health = max_health
	active_effects.clear()
	stacking_effects.clear()
	damage_sources.clear()

	# Reset DPS tracking
	total_damage_taken = 0.0
	damage_start_time = 0.0
	last_damage_time = 0.0

	# Reset visuals
	modulate = Color.WHITE

	# Clear all stack indicators
	for indicator in stack_indicators.values():
		if is_instance_valid(indicator):
			indicator.queue_free()
	stack_indicators.clear()

	_update_health_bar()
	_update_effect_display()

	print("🔄 %s reset to full health" % dummy_name)

func apply_manual_effect(effect_name: String, stacks: int = 1):
	"""Manually apply an effect for testing"""
	match effect_name:
		"burn":
			# Apply burn using Effects system
			for i in range(stacks):
				Effects.burn.apply_from_talent(self, null, 1)
		"fossilize":
			# Apply fossilization if available
			if Effects.has("fossilize"):
				for i in range(stacks):
					Effects.fossilize.apply_from_talent(self, null, 1)
		"infect":
			# Apply infection if available
			if Effects.has("infect"):
				for i in range(stacks):
					Effects.infect.apply_from_talent(self, null, 1)

	print("🧪 Manually applied %dx %s to %s" % [stacks, effect_name, dummy_name])

# Process effects over time
func _process(delta: float):
	_process_stacking_effects(delta)

func _process_stacking_effects(delta: float):
	"""Process stacking effects with proper tick intervals - matches base enemy approach"""
	for effect_name in stacking_effects.keys():
		var stacks = stacking_effects[effect_name]
		var expired_stacks = []

		for i in range(stacks.size()):
			var stack = stacks[i]

			# Increment timer using delta (matches base enemy)
			stack.timer += delta

			# Handle tick effects
			if stack.callbacks.has("tick_effect") and stack.callbacks.has("tick_interval"):
				# Initialize tick timer if not exists
				if not stack.has("tick_timer"):
					stack.tick_timer = 0.0

				stack.tick_timer += delta
				var tick_interval = stack.callbacks.tick_interval

				if stack.tick_timer >= tick_interval:
					var tick_callable = stack.callbacks.tick_effect
					if tick_callable and tick_callable.is_valid():
						tick_callable.call()
					stack.tick_timer = 0.0

			# Check expiration using delta timer (matches base enemy)
			if stack.timer >= stack.duration:
				expired_stacks.append(i)

		# Remove expired stacks (in reverse order)
		expired_stacks.reverse()
		for i in expired_stacks:
			var expired_stack = stacks[i]

			# Safely call visual cleanup with validation
			if expired_stack.callbacks.has("visual_cleanup"):
				var cleanup_callable = expired_stack.callbacks.visual_cleanup
				if cleanup_callable and cleanup_callable.is_valid():
					cleanup_callable.call()

			stacks.remove_at(i)

		# Clean up empty effect
		if stacks.is_empty():
			stacking_effects.erase(effect_name)
			_update_stack_indicator(effect_name)  # Update to remove indicator

# === STACK INDICATOR SYSTEM ===
func _update_stack_indicator(effect_name: String):
	"""Update or create stack indicator for a specific effect"""
	var total_stacks = get_total_stack_count(effect_name)
	var contributing_bottles = len(_get_contributing_bottles(effect_name))

	if total_stacks > 0:
		_create_or_update_stack_display(effect_name, total_stacks, contributing_bottles)
	else:
		_remove_stack_display(effect_name)

	# Reposition all indicators
	_reposition_stack_indicators()

func _create_or_update_stack_display(effect_name: String, total_stacks: int, bottle_count: int):
	"""Create or update the visual display for a stack type"""
	var indicator_key = effect_name

	# Create new indicator if it doesn't exist
	if not stack_indicators.has(indicator_key):
		var stack_display = _create_stack_display_node(effect_name)
		stack_indicator_container.add_child(stack_display)
		stack_indicators[indicator_key] = stack_display

	var display_node = stack_indicators[indicator_key]

	# Update the display
	_update_stack_display_content(display_node, effect_name, total_stacks, bottle_count)

func _create_stack_display_node(effect_name: String) -> Control:
	"""Create the visual node for a stack indicator"""
	var container = Control.new()
	container.name = effect_name + "_indicator"

	# Background panel
	var bg_panel = ColorRect.new()
	bg_panel.name = "Background"
	bg_panel.size = Vector2(45, 25)
	bg_panel.color = _get_effect_color(effect_name)
	bg_panel.modulate.a = 0.8
	container.add_child(bg_panel)

	# Stack count label
	var stack_label = Label.new()
	stack_label.name = "StackLabel"
	stack_label.text = "0"
	stack_label.add_theme_font_size_override("font_size", 14)
	stack_label.add_theme_color_override("font_color", Color.WHITE)
	stack_label.add_theme_color_override("font_shadow_color", Color.BLACK)
	stack_label.add_theme_constant_override("shadow_offset_x", 1)
	stack_label.add_theme_constant_override("shadow_offset_y", 1)
	stack_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stack_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	stack_label.size = Vector2(45, 20)
	container.add_child(stack_label)

	# Bottle count label (small, top-right)
	var bottle_label = Label.new()
	bottle_label.name = "BottleLabel"
	bottle_label.text = "1"
	bottle_label.add_theme_font_size_override("font_size", 10)
	bottle_label.add_theme_color_override("font_color", Color.YELLOW)
	bottle_label.add_theme_color_override("font_shadow_color", Color.BLACK)
	bottle_label.add_theme_constant_override("shadow_offset_x", 1)
	bottle_label.add_theme_constant_override("shadow_offset_y", 1)
	bottle_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	bottle_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	bottle_label.position = Vector2(30, -5)
	bottle_label.size = Vector2(15, 10)
	container.add_child(bottle_label)

	return container

func _update_stack_display_content(display_node: Control, effect_name: String, total_stacks: int, bottle_count: int):
	"""Update the content of an existing stack display"""
	var stack_label = display_node.get_node("StackLabel")
	var bottle_label = display_node.get_node("BottleLabel")
	var bg_panel = display_node.get_node("Background")

	# Update stack count
	stack_label.text = str(total_stacks)

	# Update bottle count
	bottle_label.text = str(bottle_count)

	# Update background intensity based on stack count
	var base_color = _get_effect_color(effect_name)
	var intensity = min(1.0, total_stacks / 10.0)  # Max intensity at 10 stacks
	bg_panel.color = base_color.lerp(Color.WHITE, intensity * 0.3)

	# Pulse effect for high stacks
	if total_stacks >= 8:
		var tween = bg_panel.create_tween()
		tween.set_loops()
		tween.tween_property(bg_panel, "modulate:a", 0.6, 0.5)
		tween.tween_property(bg_panel, "modulate:a", 1.0, 0.5)

func _get_effect_color(effect_name: String) -> Color:
	"""Get color for different effect types"""
	match effect_name:
		"mutation_infection":
			return Color.MAGENTA
		"stacking_burn":
			return Color.RED
		"vulnerability_mark":
			return Color.ORANGE
		"slow_buildup":
			return Color.BLUE
		"damage_amplification":
			return Color.YELLOW
		"explosive_stacks":
			return Color(1.0, 0.5, 0.0)  # Orange-red
		"burn":
			return Color.RED
		"fossilize":
			return Color(0.6, 0.4, 0.2)  # Brown
		"infect":
			return Color.GREEN
		_:
			return Color.WHITE

func _remove_stack_display(effect_name: String):
	"""Remove stack indicator when stacks reach 0"""
	var indicator_key = effect_name
	if stack_indicators.has(indicator_key):
		var display_node = stack_indicators[indicator_key]
		display_node.queue_free()
		stack_indicators.erase(indicator_key)

func _reposition_stack_indicators():
	"""Arrange multiple stack indicators in a row"""
	var x_offset = 0
	var spacing = 50  # Space between indicators

	for effect_name in stack_indicators.keys():
		var display_node = stack_indicators[effect_name]
		display_node.position.x = x_offset
		x_offset += spacing

	# Center the entire group
	if stack_indicators.size() > 0:
		var total_width = (stack_indicators.size() - 1) * spacing + 45
		var center_offset = -total_width / 2
		for effect_name in stack_indicators.keys():
			var display_node = stack_indicators[effect_name]
			display_node.position.x += center_offset

# Legacy text-based display (keep for backwards compatibility)
func _update_effect_display():
	"""Update visual effect display - now just clears the text since we use indicators"""
	if not effect_display:
		return

	# Clear the text display since we're using visual indicators now
	effect_display.text = ""
