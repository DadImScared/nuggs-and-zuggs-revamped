# Scenes/amber_crystal.gd
class_name AmberCrystal
extends Area2D

# Crystal parameters
@export var pulse_radius: float = 150.0
@export var pulse_interval: float = 1.0
@export var total_duration: float = 5.0
@export var spread_fossilize_chance: float = 0.5
@export var base_damage: float = 5.0  # Fixed flat damage per pulse
@export var xp_contribution_multiplier: float = 0.1  # Only 10% XP credit

# Internal state
var pulse_count: int = 0
var max_pulses: int = 5
var crystal_id: String  # Unique ID for debugging
var enemies_hit_this_crystal: Dictionary = {}  # Track enemies to prevent multiple hits

# References
var collision_shape: CollisionShape2D
var sprite: Sprite2D
var pulse_timer: Timer
var source_bottle: ImprovedBaseSauceBottle  # The bottle that created this crystal

# Create a BaseAmberTrigger instance to handle fossilization
var amber_trigger: BaseAmberTrigger

func _ready():
	# Generate unique ID for this crystal
	crystal_id = "Crystal_" + str(randi())
	print("💎 [%s] Crystal _ready() called" % crystal_id)

	# Create the amber trigger helper first
	amber_trigger = BaseAmberTrigger.new()

	# Calculate actual max pulses based on duration and interval
	max_pulses = int(total_duration / pulse_interval)

	# Defer ALL setup to avoid physics query conflicts and ensure proper order
	setup_everything_deferred.call_deferred()

func setup_everything_deferred():
	"""Set up everything after physics queries are done"""
	print("💎 [%s] Setting up crystal systems" % crystal_id)
	setup_crystal()
	setup_timers()
	create_pulse_visual_feedback()

func setup_crystal():
	# Get references to child nodes
	sprite = get_node_or_null("Sprite2D")
	collision_shape = get_node_or_null("CollisionShape2D")
	pulse_timer = get_node_or_null("Timer")

	# Debug logging
	print("💎 [%s] Crystal setup - Found children:" % crystal_id)
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
	print("💎 [%s] Setting up timers..." % crystal_id)

	# Try to get timer reference again
	if not pulse_timer:
		pulse_timer = get_node_or_null("Timer")

	# Configure existing pulse timer
	if pulse_timer:
		# Disconnect any existing connections to prevent duplicates
		if pulse_timer.timeout.is_connected(_on_pulse_timer_timeout):
			pulse_timer.timeout.disconnect(_on_pulse_timer_timeout)

		pulse_timer.wait_time = pulse_interval
		pulse_timer.one_shot = false  # Make sure it repeats!
		pulse_timer.autostart = false  # Don't autostart
		pulse_timer.timeout.connect(_on_pulse_timer_timeout)
		pulse_timer.start()  # Manually start
		print("💎 [%s] Pulse timer configured: %.1fs interval, repeating, will pulse %d times" % [crystal_id, pulse_interval, max_pulses])
	else:
		print("💎 [%s] ERROR: No pulse timer found in scene!" % crystal_id)
		print("💎 Available children:")
		for child in get_children():
			print("💎   - %s (%s)" % [child.name, child.get_class()])

		# Create a timer manually as fallback
		print("💎 [%s] Creating timer manually as fallback" % crystal_id)
		pulse_timer = Timer.new()
		pulse_timer.name = "ManualPulseTimer"
		pulse_timer.wait_time = pulse_interval
		pulse_timer.one_shot = false
		pulse_timer.timeout.connect(_on_pulse_timer_timeout)
		add_child(pulse_timer)
		pulse_timer.start()
		print("💎 [%s] Manual timer created and started" % crystal_id)

	# Create lifetime timer for auto-destruction
	var lifetime_timer = Timer.new()
	lifetime_timer.wait_time = total_duration
	lifetime_timer.timeout.connect(_on_lifetime_expired)
	lifetime_timer.one_shot = true
	lifetime_timer.autostart = true
	add_child(lifetime_timer)

	print("💎 [%s] Amber Crystal spawned - will pulse up to %d times over %.1f seconds" % [crystal_id, max_pulses, total_duration])

func _on_pulse_timer_timeout():
	# Check if we've reached max pulses
	if pulse_count >= max_pulses:
		pulse_timer.stop()
		print("💎 [%s] Reached max pulses (%d) - stopping timer" % [crystal_id, max_pulses])
		return

	pulse_count += 1
	print("💎 [%s] === PULSE %d/%d STARTING ===" % [crystal_id, pulse_count, max_pulses])

	execute_pulse()

func execute_pulse():
	print("💎 [%s] Crystal pulse %d/%d - detecting enemies in %.0fpx radius" % [crystal_id, pulse_count, max_pulses, pulse_radius])

	# Get nearby enemies using the amber trigger's method (uses scene tree, not collision)
	var nearby_enemies = amber_trigger.get_nearby_enemies(global_position, pulse_radius)

	if nearby_enemies.is_empty():
		print("💎 [%s] No enemies in pulse range" % crystal_id)
		return

	print("💎 [%s] Pulse hitting %d enemies" % [crystal_id, nearby_enemies.size()])

	# Apply effects to each enemy
	var enemies_damaged = 0
	for i in range(nearby_enemies.size()):
		var enemy = nearby_enemies[i]
		if not is_instance_valid(enemy):
			continue

		# Check if we've already hit this enemy with this crystal
		var enemy_id = enemy.get_instance_id()
		if enemies_hit_this_crystal.has(enemy_id):
			print("💎 [%s] Enemy already hit by this crystal - skipping" % crystal_id)
			continue

		print("💎 [%s] [%d/%d] Processing enemy at position %s" % [crystal_id, i+1, nearby_enemies.size(), str(enemy.global_position)])
		apply_pulse_effects(enemy)
		enemies_damaged += 1

		# Mark this enemy as hit by this crystal
		enemies_hit_this_crystal[enemy_id] = true

	# Visual pulse effect
	create_pulse_visual()
	print("💎 [%s] === PULSE %d/%d COMPLETED - Damaged %d enemies ===" % [crystal_id, pulse_count, max_pulses, enemies_damaged])

func apply_pulse_effects(enemy: Node):
	# Apply fixed damage instead of percentage based
	var damage = calculate_pulse_damage()

	print("💎 [%s] Applying %.1f damage to enemy" % [crystal_id, damage])

	# Apply damage with reduced XP contribution
	if enemy.has_method("apply_damage"):
		enemy.apply_damage(damage)

		# Give partial XP credit to the source bottle
		if source_bottle and enemy.has_method("register_damage_source"):
			var xp_credit = damage * xp_contribution_multiplier
			enemy.register_damage_source(source_bottle, xp_credit)
			print("💎 [%s] Registered %.1f XP credit (%.0f%% of damage)" % [crystal_id, xp_credit, xp_contribution_multiplier * 100])
	elif enemy.has_method("take_damage"):
		enemy.take_damage(damage)

	# Roll for fossilization
	if randf() < spread_fossilize_chance:
		apply_fossilization_to_enemy(enemy)
		print("💎 [%s] Fossilization triggered (%.1f%% chance)" % [crystal_id, spread_fossilize_chance * 100])

func calculate_pulse_damage() -> float:
	# Crystal does flat damage, not percentage based
	# This prevents scaling issues with high damage bottles
	return base_damage

func apply_fossilization_to_enemy(enemy: Node):
	print("💎 [%s] Applying fossilization to enemy" % crystal_id)

	# Create trigger data for the fossilization
	var fossilize_trigger_resource = TriggerEffectResource.new()
	fossilize_trigger_resource.trigger_name = "fossilize"
	fossilize_trigger_resource.trigger_type = TriggerEffectResource.TriggerType.ON_HIT
	fossilize_trigger_resource.effect_parameters["duration"] = 2.5
	fossilize_trigger_resource.effect_parameters["tick_damage"] = 3.0  # Reduced tick damage
	fossilize_trigger_resource.effect_parameters["amber_color"] = Color(1.0, 0.8, 0.3, 0.6)
	fossilize_trigger_resource.effect_parameters["max_stacks"] = 1  # Only one stack from crystals
	fossilize_trigger_resource.effect_parameters["trigger_source"] = "amber_crystal"

	# Create EnhancedTriggerData
	var fossilize_trigger_data = EnhancedTriggerData.new(fossilize_trigger_resource)

	# Use the actual source bottle if available, otherwise create minimal bottle
	var bottle_to_use = source_bottle
	if not bottle_to_use:
		bottle_to_use = ImprovedBaseSauceBottle.new()
		bottle_to_use.bottle_id = "amber_crystal"
		bottle_to_use.base_damage = base_damage
		bottle_to_use.effective_damage = base_damage

	# Use the amber trigger's fossilization method
	amber_trigger.apply_fossilization_to_enemy(enemy, bottle_to_use, fossilize_trigger_data, 1)

	print("💎 [%s] Fossilization applied using BaseAmberTrigger" % crystal_id)

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
	# Subtle ambient pulsing for the crystal itself
	if sprite:
		var ambient_tween = create_tween()
		ambient_tween.set_loops()
		ambient_tween.tween_property(sprite, "modulate", Color(1.2, 1.0, 0.5, 1.0), 1.0)
		ambient_tween.tween_property(sprite, "modulate", Color(1.0, 0.8, 0.3, 1.0), 1.0)

func _on_lifetime_expired():
	print("💎 [%s] Crystal lifetime expired - destroying" % crystal_id)
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
	print("💎 [%s] Crystal fossilization chance enhanced to %.1f%%" % [crystal_id, spread_fossilize_chance * 100])

func enhance_damage_multiplier(multiplier: float):
	base_damage *= multiplier
	print("💎 [%s] Crystal damage enhanced by %.1fx to %.1f" % [crystal_id, multiplier, base_damage])
