class_name PlagueBearerTrigger
extends BaseTriggerAction

# Reference to the visual node (created when trigger activates)
var visual_node: PlagueBearerVisualNode
var infection_timer: Timer
var is_trigger_active: bool = false
var current_bottle: ImprovedBaseSauceBottle
var current_trigger_data: EnhancedTriggerData

func _init() -> void:
	trigger_name = "plague_bearer"
	trigger_description = "Enemies within 50 units have 10% chance per second to get infected"

func is_active() -> bool:
	return is_trigger_active

func refresh_enhancements(bottle: ImprovedBaseSauceBottle, base_trigger_data: TriggerEffectResource) -> void:
	if not is_trigger_active:
		print("⚠️ Trying to refresh inactive Plague Bearer")
		return

	print("🔄 Refreshing Plague Bearer enhancements")
	store_original_trigger_data(base_trigger_data)
	# Reapply enhancements with current bottle state
	var enhanced_data = apply_enhancements(bottle, original_trigger_data)
	var old_radius = current_trigger_data.trigger_condition.get("radius", 50.0)
	var new_radius = enhanced_data.trigger_condition.get("radius", 50.0)
	print(new_radius, " new radius----------")
	# Update stored data
	current_trigger_data = enhanced_data

	# Update visual if radius changed
	if visual_node and is_instance_valid(visual_node) and abs(old_radius - new_radius) > 0.1:
		print("🔄 Updating visual radius: %.0f → %.0f" % [old_radius, new_radius])
		visual_node.update_radius(new_radius)
		visual_node.queue_redraw()

	print("🔄 Plague Bearer refresh complete - radius: %.0f, chance: %.1f%%" % [
		new_radius,
		enhanced_data.trigger_condition.get("chance", 0.1) * 100
	])

func execute_trigger(bottle: ImprovedBaseSauceBottle, trigger_data: EnhancedTriggerData):
	if not is_trigger_active:
		activate_plague_bearer(bottle, trigger_data)

func activate_plague_bearer(bottle: ImprovedBaseSauceBottle, trigger_data: EnhancedTriggerData):
	is_trigger_active = true
	current_bottle = bottle

	# Store original data for future refreshes
	#store_original_trigger_data(trigger_data)

	# Apply enhancements
	var enhanced_data = trigger_data
	current_trigger_data = enhanced_data

	# ... rest of existing activate logic stays the same ...

	var radius = enhanced_data.trigger_condition.get("radius", 50.0)
	var chance = enhanced_data.trigger_condition.get("chance", 0.1)

	# Create visual with enhanced radius
	visual_node = PlagueBearerVisualNode.new()
	var player = Engine.get_main_loop().current_scene.get_node("Player")
	if player:
		player.add_child(visual_node)
		visual_node.position = Vector2.ZERO
	else:
		var scene = Engine.get_main_loop().current_scene
		scene.add_child(visual_node)
		visual_node.global_position = bottle.global_position

	visual_node.setup_visual(radius)

	# Create infection timer
	infection_timer = Timer.new()
	var scene = Engine.get_main_loop().current_scene
	scene.add_child(infection_timer)
	infection_timer.wait_time = 1.0
	infection_timer.timeout.connect(_on_infection_timer_timeout)
	infection_timer.start()

	print("🦠 Plague Bearer: Activated with %.0f radius, %.1f%% chance" % [radius, chance * 100])

func _on_infection_timer_timeout():
	if not current_bottle or not current_trigger_data or not is_instance_valid(visual_node):
		deactivate_plague_bearer()
		return

	# Get player position for infection logic
	var player = Engine.get_main_loop().current_scene.get_node("Player")
	var center_position = player.global_position if player else current_bottle.global_position

	# Use the enhanced values from current_trigger_data
	var infection_radius = current_trigger_data.trigger_condition.get("radius", 50.0)
	var infection_chance = current_trigger_data.trigger_condition.get("chance", 0.1)

	var enemies = get_enemies_in_radius(center_position, infection_radius)
	var infections_this_tick = 0

	for enemy in enemies:
		# Apply slow effect if the talent has it
		if current_trigger_data.effect_parameters.has("slow_strength"):
			var slow_strength = current_trigger_data.effect_parameters.get("slow_strength", 0.3)
			var slow_duration = current_trigger_data.effect_parameters.get("slow_duration", 2.0)

			if enemy.has_method("apply_status_effect"):
				enemy.apply_status_effect(
					"slow",
					slow_duration,
					slow_strength,
					current_bottle.bottle_id + "_slow"
				)

		# Try to infect uninfected enemies
		if "infect" not in enemy.active_effects and randf() < infection_chance:
			if enemy.has_method("apply_status_effect"):
				enemy.apply_status_effect(
					"infect",
					current_trigger_data.effect_parameters.get("duration", 4.0),
					current_bottle.effective_effect_intensity or 0.2,
					current_bottle.bottle_id
				)

				# Show visual infection burst
				if enemy.has_method("get_global_position"):
					visual_node.show_infection_burst(enemy.get_global_position())

				infections_this_tick += 1

	# Update visual intensity based on infection activity
	visual_node.set_infection_intensity(min(infections_this_tick / 3.0, 1.0))

	if infections_this_tick > 0:
		print("🦠 Plague Bearer: Infected %d enemies this tick (%.0f radius, %.1f%% chance)" % [infections_this_tick, infection_radius, infection_chance * 100])

func deactivate_plague_bearer():
	is_trigger_active = false

	if infection_timer and is_instance_valid(infection_timer):
		infection_timer.queue_free()
		infection_timer = null

	if visual_node and is_instance_valid(visual_node):
		visual_node.queue_free()
		visual_node = null

	current_bottle = null
	current_trigger_data = null
	print("🦠 Plague Bearer: Deactivated")

func get_enemies_in_radius(center: Vector2, radius: float) -> Array:
	var enemies = []
	var all_enemies = Engine.get_main_loop().current_scene.get_tree().get_nodes_in_group("enemies")

	for enemy in all_enemies:
		if is_instance_valid(enemy) and enemy.has_method("get_global_position"):
			var distance = center.distance_to(enemy.get_global_position())
			if distance <= radius and enemy.has_method("apply_status_effect"):
				enemies.append(enemy)

	return enemies

# Override base class methods
func should_trigger(source_bottle: ImprovedBaseSauceBottle, trigger_data: EnhancedTriggerData) -> bool:
	# Only trigger once to activate the ongoing effect
	return not is_trigger_active

func update_trigger_timing(source_bottle: ImprovedBaseSauceBottle, trigger_data: EnhancedTriggerData) -> void:
	# Mark as triggered so it doesn't trigger again
	source_bottle.last_trigger_times[trigger_name] = Time.get_ticks_msec() / 1000.0

# Clean up when trigger is removed
func cleanup():
	deactivate_plague_bearer()

# Check if bottle has talents that enhance plague bearer
func check_for_plague_bearer_enhancements(bottle: ImprovedBaseSauceBottle, base_trigger_data: TriggerEffectResource) -> TriggerEffectResource:
	# Create a copy of the base trigger data to modify
	var enhanced_data = TriggerEffectResource.new()
	enhanced_data.trigger_name = base_trigger_data.trigger_name
	enhanced_data.trigger_type = base_trigger_data.trigger_type
	enhanced_data.trigger_condition = base_trigger_data.trigger_condition.duplicate()
	enhanced_data.effect_parameters = base_trigger_data.effect_parameters.duplicate()

	# Get base values
	var base_radius = enhanced_data.trigger_condition.get("radius", 50.0)
	var base_chance = enhanced_data.trigger_condition.get("chance", 0.1)

	# Check for enhancement talents by looking at bottle's talents
	var has_virulent_aura = bottle_has_talent(bottle, "virulent_aura")
	var has_contagious_miasma = bottle_has_talent(bottle, "contagious_miasma")
	var has_pandemic_zone = bottle_has_talent(bottle, "pandemic_zone")
	var has_plague_lord = bottle_has_talent(bottle, "plague_lord")

	# Apply enhancements
	if has_virulent_aura:
		enhanced_data.trigger_condition["radius"] = base_radius * 1.5  # +50% radius
		print("🦠 Virulent Aura: Radius increased to %.0f" % enhanced_data.trigger_condition["radius"])

	if has_contagious_miasma:
		enhanced_data.trigger_condition["chance"] = base_chance * 1.5  # +50% chance
		print("🦠 Contagious Miasma: Chance increased to %.1f%%" % (enhanced_data.trigger_condition["chance"] * 100))

	if has_pandemic_zone:
		enhanced_data.trigger_condition["radius"] = base_radius * 2.0  # +100% radius
		enhanced_data.trigger_condition["chance"] = base_chance * 1.5  # +50% chance
		print("🦠 Pandemic Zone: Radius doubled, chance increased!")

	if has_plague_lord:
		enhanced_data.effect_parameters["slow_strength"] = 0.4  # 40% slow
		enhanced_data.effect_parameters["slow_duration"] = 2.0  # 2 seconds
		print("🦠 Plague Lord: Added 40% slow effect")

	return enhanced_data

# Helper function to check if bottle has a specific talent
func bottle_has_talent(bottle: ImprovedBaseSauceBottle, talent_name: String) -> bool:
	# Check trigger effects for the talent
	for trigger_effect in bottle.trigger_effects:
		if trigger_effect.trigger_name == talent_name:
			return true

	# Check special effects for the talent
	for special_effect in bottle.special_effects:
		if special_effect.effect_name == talent_name:
			return true

	# Check stat modifiers for the talent (if they have names)
	for stat_modifier in bottle.stat_modifier_history:
		if stat_modifier.has_method("get_talent_name") and stat_modifier.get_talent_name() == talent_name:
			return true

	return false

# =============================================================================
# VISUAL NODE CLASS - Handles all visual effects
# =============================================================================

class PlagueBearerVisualNode extends Node2D:
	# Visual components
	var infection_particles: GPUParticles2D
	var miasma_effect: GPUParticles2D
	var pulse_tween: Tween

	# Visual properties
	var radius: float = 50.0
	var pulse_intensity: float = 0.0
	var is_active: bool = false

	func setup_visual(effect_radius: float):
		radius = effect_radius
		setup_particles()
		setup_tween()
		activate_visual()

	func setup_particles():
		# Setup infection particles
		infection_particles = GPUParticles2D.new()
		add_child(infection_particles)

		var material = ParticleProcessMaterial.new()
		material.direction = Vector3(0, -1, 0)
		material.initial_velocity_min = 20.0
		material.initial_velocity_max = 40.0
		material.gravity = Vector3(0, 0, 0)
		material.scale_min = 0.1
		material.scale_max = 0.3
		material.color_ramp = create_infection_color_ramp()
		material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_RING
		material.emission_ring_radius = radius * 0.8
		material.emission_ring_inner_radius = radius * 0.2

		infection_particles.process_material = material
		infection_particles.amount = 100
		infection_particles.lifetime = 3.0
		infection_particles.emitting = false

		# Setup miasma effect
		miasma_effect = GPUParticles2D.new()
		add_child(miasma_effect)
		miasma_effect.z_index = -1

		var miasma_material = ParticleProcessMaterial.new()
		miasma_material.direction = Vector3(0, 0, 0)
		miasma_material.initial_velocity_min = 5.0
		miasma_material.initial_velocity_max = 15.0
		miasma_material.gravity = Vector3(0, 0, 0)
		miasma_material.scale_min = 0.5
		miasma_material.scale_max = 1.2
		miasma_material.color_ramp = create_miasma_color_ramp()
		miasma_material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
		miasma_material.emission_sphere_radius = radius

		miasma_effect.process_material = miasma_material
		miasma_effect.amount = 50
		miasma_effect.lifetime = 4.0
		miasma_effect.emitting = false

	func setup_tween():
		pulse_tween = create_tween()

	func create_infection_color_ramp() -> Gradient:
		var gradient = Gradient.new()
		gradient.add_point(0.0, Color(0.2, 0.8, 0.2, 0.0))  # Transparent green
		gradient.add_point(0.3, Color(0.8, 0.8, 0.2, 0.6))  # Yellow-green
		gradient.add_point(0.7, Color(0.8, 0.4, 0.2, 0.8))  # Orange
		gradient.add_point(1.0, Color(0.6, 0.2, 0.2, 0.0))  # Transparent red
		return gradient

	func create_miasma_color_ramp() -> Gradient:
		var gradient = Gradient.new()
		gradient.add_point(0.0, Color(0.2, 0.4, 0.2, 0.0))  # Transparent dark green
		gradient.add_point(0.5, Color(0.4, 0.6, 0.2, 0.3))  # Semi-transparent sickly green
		gradient.add_point(1.0, Color(0.3, 0.3, 0.2, 0.0))  # Transparent brown
		return gradient

	func _draw():
		if not is_active:
			return

		# Draw pulsing radius circle with higher visibility
		var circle_color = Color(0.4, 0.8, 0.2, 0.6 + pulse_intensity * 0.4)  # More visible
		var circle_width = 3.0 + pulse_intensity * 3.0  # Thicker

		# Draw outer circle
		draw_arc(Vector2.ZERO, radius, 0, TAU, 64, circle_color, circle_width)

		# Draw inner infection zone with filled circle
		var inner_color = Color(0.6, 0.8, 0.2, 0.3 + pulse_intensity * 0.2)  # More visible
		draw_circle(Vector2.ZERO, radius * 0.7, inner_color)

		# Add additional visual rings for better visibility
		var mid_color = Color(0.5, 0.7, 0.3, 0.4 + pulse_intensity * 0.3)  # More visible
		draw_arc(Vector2.ZERO, radius * 0.5, 0, TAU, 32, mid_color, 2.0)

	func activate_visual():
		is_active = true
		infection_particles.emitting = true
		miasma_effect.emitting = true
		start_pulse_animation()
		queue_redraw()
		print("🎨 Visual activated with radius: ", radius)

	func deactivate_visual():
		is_active = false
		infection_particles.emitting = false
		miasma_effect.emitting = false
		stop_pulse_animation()
		queue_redraw()

	func start_pulse_animation():
		if pulse_tween:
			pulse_tween.kill()

		pulse_tween.tween_method(
			_update_pulse_intensity,
			0.0,
			1.0,
			0.8
		)
		pulse_tween.tween_callback(_pulse_reverse)

	func _pulse_reverse():
		pulse_tween.tween_method(
			_update_pulse_intensity,
			1.0,
			0.0,
			0.8
		)
		pulse_tween.tween_callback(_pulse_loop)

	func _pulse_loop():
		if is_active:
			start_pulse_animation()

	func _update_pulse_intensity(value: float):
		pulse_intensity = value
		queue_redraw()

	func stop_pulse_animation():
		if pulse_tween:
			pulse_tween.kill()
		pulse_intensity = 0.0

	func show_infection_burst(position: Vector2):
		# Create a burst effect at the infection point
		var burst_particles = GPUParticles2D.new()
		get_tree().current_scene.add_child(burst_particles)
		burst_particles.global_position = position

		var material = ParticleProcessMaterial.new()
		material.direction = Vector3(0, -1, 0)
		material.initial_velocity_min = 30.0
		material.initial_velocity_max = 60.0
		material.gravity = Vector3(0, 0, 0)
		material.scale_min = 0.2
		material.scale_max = 0.5
		material.color_ramp = create_infection_color_ramp()
		material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
		material.emission_sphere_radius = 10.0

		burst_particles.process_material = material
		burst_particles.amount = 20
		burst_particles.lifetime = 1.5
		burst_particles.emitting = true
		burst_particles.one_shot = true

		# Clean up after emission
		var cleanup_timer = Timer.new()
		get_tree().current_scene.add_child(cleanup_timer)
		cleanup_timer.wait_time = 2.0
		cleanup_timer.one_shot = true
		cleanup_timer.timeout.connect(func():
			burst_particles.queue_free()
			cleanup_timer.queue_free()
		)
		cleanup_timer.start()

	func set_infection_intensity(intensity: float):
		var clamped_intensity = clamp(intensity, 0.0, 1.0)

		if infection_particles:
			infection_particles.amount = int(50 + clamped_intensity * 100)

		if miasma_effect:
			miasma_effect.amount = int(25 + clamped_intensity * 50)

		# Adjust overall opacity
		modulate.a = 0.5 + clamped_intensity * 0.5

	func update_radius(new_radius: float):
		if radius != new_radius:
			radius = new_radius

			# Update particle emission shapes
			if infection_particles and infection_particles.process_material:
				infection_particles.process_material.emission_ring_radius = radius * 0.8
				infection_particles.process_material.emission_ring_inner_radius = radius * 0.2

			if miasma_effect and miasma_effect.process_material:
				miasma_effect.process_material.emission_sphere_radius = radius

			# Redraw circles with new radius
			queue_redraw()
			print("🎨 Plague Bearer visual radius updated to: ", radius)
