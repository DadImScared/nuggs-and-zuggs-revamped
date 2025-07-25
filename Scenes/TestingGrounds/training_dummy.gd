# Scenes/TestingGrounds/training_dummy.gd
extends CharacterBody2D

@onready var health_bar = $HealthBar
@onready var name_label = $NameLabel
@onready var effect_display = $EffectDisplay
@onready var damage_numbers = $DamageNumbers

# Dummy properties
var dummy_name: String = "Training Dummy"
var max_health: float = 1000.0
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

# DPS tracking
var total_damage_taken: float = 0.0
var damage_start_time: float = 0.0
var last_damage_time: float = 0.0

# Signals
signal damage_dealt(amount: float, source: String)
signal effect_applied(effect_name: String, stacks: int)

func _ready():
	setup_dummy()
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

	# Add new stack
	var new_stack = {
		"value": stack_value,
		"source_id": source_id,
		"duration": duration,
		"timer": 0.0,
		"callbacks": callbacks
	}

	stacking_effects[effect_name].append(new_stack)

	# Enforce max stacks
	while stacking_effects[effect_name].size() > max_stacks:
		var removed_stack = stacking_effects[effect_name].pop_front()
		# Call cleanup if stack expired
		if removed_stack.callbacks.has("mechanical_cleanup"):
			removed_stack.callbacks.mechanical_cleanup.call()

	# Execute immediate effect
	if callbacks.has("immediate_effect"):
		callbacks.immediate_effect.call()

	_update_effect_display()

	# Emit signal
	var stack_count = get_total_stack_count(effect_name)
	effect_applied.emit(effect_name, stack_count)

	print("🧪 %s: Applied %s (now %d stacks)" % [dummy_name, effect_name, stack_count])

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

func _update_effect_display():
	"""Update visual effect display"""
	if not effect_display:
		return

	var effect_text = ""

	# Show stacking effects with counts
	for effect_name in stacking_effects:
		var stacks = stacking_effects[effect_name].size()
		if stacks > 0:
			var display_name = effect_name.capitalize()
			effect_text += "%s×%d " % [display_name, stacks]

	effect_display.text = effect_text.strip_edges()

# Testing utility functions
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
	"""Process stacking effects with proper tick intervals"""
	for effect_name in stacking_effects.keys():
		var stacks = stacking_effects[effect_name]
		var expired_stacks = []

		for i in range(stacks.size()):
			var stack = stacks[i]

			# Handle tick effects
			if stack.callbacks.has("tick_effect") and stack.callbacks.has("tick_interval"):
				stack.timer += delta
				var tick_interval = stack.callbacks.tick_interval

				if stack.timer >= tick_interval:
					stack.callbacks.tick_effect.call()
					stack.timer = 0.0

			# Check expiration (separate from tick timer)
			var elapsed_time = Time.get_time_dict_from_system().get("unix", 0) - stack.get("start_time", 0)
			if elapsed_time >= stack.duration:
				expired_stacks.append(i)

		# Remove expired stacks (in reverse order)
		expired_stacks.reverse()
		for i in expired_stacks:
			var expired_stack = stacks[i]
			if expired_stack.callbacks.has("visual_cleanup"):
				expired_stack.callbacks.visual_cleanup.call()
			stacks.remove_at(i)

		# Clean up empty effect
		if stacks.is_empty():
			stacking_effects.erase(effect_name)
			_update_effect_display()
