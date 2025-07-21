class_name AmberCrystal
extends Area2D

# Crystal parameters
@export var pulse_radius: float = 150.0
@export var pulse_interval: float = 1.0
@export var total_duration: float = 5.0
@export var spread_fossilize_chance: float = 0.5
@export var base_damage: float = 1.0

# Internal state
var pulse_count: int = 0
var max_pulses: int = 5

# References
var collision_shape: CollisionShape2D
var sprite: Sprite2D
var pulse_timer: Timer
var source_bottle: ImprovedBaseSauceBottle  # The bottle that created this crystal

# Create a BaseAmberTrigger instance to handle fossilization
var amber_trigger: BaseAmberTrigger

func _ready():
	# Create the amber trigger helper first
	amber_trigger = BaseAmberTrigger.new()

	# Defer ALL setup to avoid physics query conflicts and ensure proper order
	setup_everything_deferred.call_deferred()

func setup_everything_deferred():
	"""Set up everything after physics queries are done"""
	setup_crystal()
	setup_timers()
	create_pulse_visual_feedback()

func setup_crystal():
	# Get references to child nodes
	sprite = get_node_or_null("Sprite2D")
	collision_shape = get_node_or_null("CollisionShape2D")
	pulse_timer = get_node_or_null("Timer")

	# Debug logging
	print("💎 Crystal setup - Found children:")
	for child in get_children():
		print("💎   - %s (%s)" % [child.name, child.get_class()])

	# Set up collision shape for pulse detection
	if collision_shape:
		var circle_shape = CircleShape2D.new()
		circle_shape.radius = pulse_radius
		collision_shape.shape = circle_shape

	# Set collision layers - crystal should not interfere with gameplay
	collision_layer = 0  # Crystal doesn't collide with anything
	collision_mask = 0   # Crystal doesn't detect through collision

	# Initial crystal appearance
	if sprite:
		sprite.modulate = Color(1.0, 0.8, 0.3, 0.8)  # Amber color
		sprite.scale = Vector2(0.5, 0.5)  # Start smaller

		# Gentle growth animation
		var tween = create_tween()
		tween.tween_property(sprite, "scale", Vector2(1.0, 1.0), 0.3)
		tween.parallel().tween_property(sprite, "modulate:a", 1.0, 0.3)

func setup_timers():
	# Try to get timer reference again
	if not pulse_timer:
		pulse_timer = get_node_or_null("Timer")

	# Configure existing pulse timer
	if pulse_timer:
		pulse_timer.wait_time = pulse_interval
		pulse_timer.one_shot = false  # Make sure it repeats!
		pulse_timer.autostart = false  # Don't autostart
		pulse_timer.timeout.connect(_on_pulse_timer_timeout)
		pulse_timer.start()  # Manually start
		print("💎 Pulse timer configured: %.1fs interval, repeating, starting now" % pulse_interval)
	else:
		print("💎 ERROR: No pulse timer found in scene!")
		print("💎 Available children:")
		for child in get_children():
			print("💎   - %s (%s)" % [child.name, child.get_class()])

		# Create a timer manually as fallback
		print("💎 Creating timer manually as fallback")
		pulse_timer = Timer.new()
		pulse_timer.name = "ManualPulseTimer"
		pulse_timer.wait_time = pulse_interval
		pulse_timer.one_shot = false
		pulse_timer.timeout.connect(_on_pulse_timer_timeout)
		add_child(pulse_timer)
		pulse_timer.start()
		print("💎 Manual timer created and started")

	# Create lifetime timer for auto-destruction
	var lifetime_timer = Timer.new()
	lifetime_timer.wait_time = total_duration
	lifetime_timer.timeout.connect(_on_lifetime_expired)
	lifetime_timer.one_shot = true
	lifetime_timer.autostart = true
	add_child(lifetime_timer)

	print("💎 Amber Crystal spawned - will pulse %d times over %.1f seconds" % [max_pulses, total_duration])

func _on_pulse_timer_timeout():
	pulse_count += 1
	print("💎 Pulse timer triggered - pulse %d/%d" % [pulse_count, max_pulses])

	execute_pulse()

	# Stop pulsing if we've reached max pulses
	if pulse_count >= max_pulses:
		pulse_timer.stop()
		print("💎 Crystal completed all %d pulses - timer stopped" % max_pulses)

func execute_pulse():
	print("💎 Crystal pulse %d/%d - detecting enemies in %.0fpx radius" % [pulse_count, max_pulses, pulse_radius])

	# Get nearby enemies using the amber trigger's method (uses scene tree, not collision)
	var nearby_enemies = amber_trigger.get_nearby_enemies(global_position, pulse_radius)

	if nearby_enemies.is_empty():
		print("💎 No enemies in pulse range")
		return

	print("💎 Pulse hitting %d enemies" % nearby_enemies.size())

	# Apply effects to each enemy
	for enemy in nearby_enemies:
		if not is_instance_valid(enemy):
			continue

		apply_pulse_effects(enemy)

	# Visual pulse effect
	create_pulse_visual()

func apply_pulse_effects(enemy: Node):
	# Always apply damage to ALL enemies in range
	var damage = calculate_pulse_damage()

	# Use a special damage source that gives no XP
	var damage_source = "amber_crystal_no_xp"

	if enemy.has_method("take_damage_from_source"):
		enemy.take_damage_from_source(damage, damage_source)
	elif enemy.has_method("take_damage"):
		enemy.take_damage(damage)

	print("💎 Applied %.1f damage to enemy from %s (no XP)" % [damage, damage_source])

	# ALWAYS attempt fossilization (regardless of existing stacks)
	if randf() < spread_fossilize_chance:
		apply_fossilization_to_enemy(enemy)
		print("💎 Fossilization applied!")
	else:
		print("💎 Fossilization chance missed (%.1f%%)" % (spread_fossilize_chance * 100))

func calculate_pulse_damage() -> float:
	# Crystal does reduced damage (6% of bottle damage) - gives no XP due to special source
	var bottle_damage = source_bottle.effective_damage if source_bottle else base_damage
	return bottle_damage * 0.01  # 6% of bottle's damage

func apply_fossilization_to_enemy(enemy: Node):
	print("💎 Applying fossilization to enemy")

	# Create trigger data for the fossilization
	var fossilize_trigger_resource = TriggerEffectResource.new()
	fossilize_trigger_resource.trigger_name = "fossilize"
	fossilize_trigger_resource.trigger_type = TriggerEffectResource.TriggerType.ON_HIT
	fossilize_trigger_resource.effect_parameters["duration"] = 2.5
	fossilize_trigger_resource.effect_parameters["tick_damage"] = 6.0
	fossilize_trigger_resource.effect_parameters["amber_color"] = Color(1.0, 0.8, 0.3, 0.6)
	fossilize_trigger_resource.effect_parameters["max_stacks"] = 1
	fossilize_trigger_resource.effect_parameters["stack_value"] = 0.8

	# Create EnhancedTriggerData
	var fossilize_trigger_data = EnhancedTriggerData.new(fossilize_trigger_resource)

	# Use the actual source bottle if available, otherwise create minimal bottle
	var bottle_to_use = source_bottle
	if not bottle_to_use:
		bottle_to_use = ImprovedBaseSauceBottle.new()
		bottle_to_use.bottle_id = "amber_crystal"

	# Use the amber trigger's fossilization method
	amber_trigger.apply_fossilization_to_enemy(enemy, bottle_to_use, fossilize_trigger_data, 1)

func create_pulse_visual():
	# Create expanding ring visual effect
	var pulse_ring = ColorRect.new()
	pulse_ring.size = Vector2(pulse_radius * 2, pulse_radius * 2)
	pulse_ring.position = Vector2(-pulse_radius, -pulse_radius)
	pulse_ring.color = Color(1.0, 0.8, 0.3, 0.3)  # Translucent amber
	pulse_ring.mouse_filter = Control.MOUSE_FILTER_IGNORE

	add_child(pulse_ring)

	# Animate the pulse
	var tween = create_tween()
	tween.parallel().tween_property(pulse_ring, "modulate:a", 0.0, 0.5)
	tween.parallel().tween_property(pulse_ring, "scale", Vector2(1.2, 1.2), 0.5)
	tween.tween_callback(pulse_ring.queue_free)

	# Crystal pulse animation
	if sprite:
		var crystal_tween = create_tween()
		crystal_tween.tween_property(sprite, "scale", Vector2(1.1, 1.1), 0.1)
		crystal_tween.tween_property(sprite, "scale", Vector2(1.0, 1.0), 0.1)

func create_pulse_visual_feedback():
	# Subtle ambient glow/pulsing for the crystal itself
	if sprite:
		var ambient_tween = create_tween()
		ambient_tween.set_loops()
		ambient_tween.tween_property(sprite, "modulate", Color(1.2, 1.0, 0.5, 1.0), 1.0)
		ambient_tween.tween_property(sprite, "modulate", Color(1.0, 0.8, 0.3, 1.0), 1.0)

func _on_lifetime_expired():
	print("💎 Crystal lifetime expired - destroying")
	create_destruction_effect()
	queue_free()

func create_destruction_effect():
	# Final burst effect when crystal disappears
	if sprite:
		var final_tween = create_tween()
		final_tween.parallel().tween_property(sprite, "scale", Vector2(1.5, 1.5), 0.3)
		final_tween.parallel().tween_property(sprite, "modulate:a", 0.0, 0.3)

	# Spawn amber particles using the amber trigger's method
	amber_trigger.create_fossilization_particles(global_position, Color(1.0, 0.8, 0.3))

# Public interface for talent enhancements
func enhance_fossilization_chance(bonus: float):
	spread_fossilize_chance = min(spread_fossilize_chance + bonus, 1.0)
	print("💎 Crystal fossilization chance enhanced to %.1f%%" % (spread_fossilize_chance * 100))

func enhance_damage_multiplier(multiplier: float):
	base_damage *= multiplier
	print("💎 Crystal damage enhanced by %.1fx" % multiplier)
