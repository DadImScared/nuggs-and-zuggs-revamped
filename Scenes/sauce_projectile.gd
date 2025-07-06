extends Area2D

var velocity = Vector2(0, 0)
var sauce_damage
var lifetime
var max_range = 1200
var start_position: Vector2

var sauce_resource: BaseSauceResource
var has_pierced = []
var bounce_count: int = 0
var max_bounces: int = 3
var chain_targets: Array[Node] = []
var growth_multiplier: float = 1.0

# Quantum-specific variables
var quantum_positions = []
var quantum_active = false
var quantum_collapse_timer = 0.0
var quantum_states = 3
var quantum_visuals = []  # Store visual representations
var base_modulate: Color
var has_collapsed = false

@onready var sprite = $Sprite2D

func _ready() -> void:
	base_modulate = modulate

func initialize_quantum_states():
	quantum_active = true
	quantum_states = int(sauce_resource.effect_intensity)

	for i in range(quantum_states):
		quantum_positions.append({
			"offset": Vector2.ZERO,
			"phase": i * (PI * 2.0 / quantum_states),
			"visible": true,
			"amplitude": 100.0,  # Increased for visibility
			"frequency": 3.0,   # Slower for clarity
			"existence_probability": randf()
		})

	# Create visual duplicates
	for i in range(quantum_states - 1):  # -1 because we skip the main
		var quantum_visual = Sprite2D.new()
		quantum_visual.texture = sprite.texture
		quantum_visual.modulate = sauce_resource.sauce_color
		quantum_visual.modulate.a = 0.7  # More visible
		quantum_visual.scale = sprite.scale  # Slightly smaller
		add_child(quantum_visual)
		quantum_visuals.append(quantum_visual)

		# Debug print
		print("Created quantum visual ", i)

func update_quantum_states(delta: float):
	# Update each quantum state
	for i in range(quantum_positions.size()):
		var state = quantum_positions[i]

		# Calculate oscillating position
		var oscillation = sin(quantum_collapse_timer * state.frequency + state.phase)
		state.offset = Vector2(
			cos(state.phase) * oscillation * state.amplitude,
			sin(state.phase) * oscillation * state.amplitude
		)

		# Randomly flicker existence
		if randf() < 0.05:  # 5% chance per frame
			state.visible = randf() < 0.7  # 70% chance to exist
			state.existence_probability = randf()

		# Update visual if it exists
		if i > 0 and i - 1 < quantum_visuals.size():
			var visual = quantum_visuals[i - 1]
			visual.position = state.offset
			visual.visible = state.visible

			# Quantum flickering effect
			var flicker = sin(quantum_collapse_timer * 20.0) * 0.2 + 0.8
			visual.modulate.a = 0.3 * flicker * state.existence_probability

			# Slight color shift for quantum effect
			var hue_shift = sin(quantum_collapse_timer * 5.0 + state.phase) * 0.1
			visual.modulate.h += hue_shift

func apply_quantum_effect(enemy: Node2D):
	if not quantum_active or has_collapsed:
		return

	has_collapsed = true

	# Determine which quantum state was "real"
	var total_probability = 0.0
	for state in quantum_positions:
		if state.visible:
			total_probability += state.existence_probability

	var random_value = randf() * total_probability
	var accumulated = 0.0
	var chosen_state = 0

	for i in range(quantum_positions.size()):
		if quantum_positions[i].visible:
			accumulated += quantum_positions[i].existence_probability
			if random_value <= accumulated:
				chosen_state = i
				break

	# Collapse to the chosen state
	collapse_quantum_state(chosen_state, enemy)

func collapse_quantum_state(chosen_state: int, enemy: Node2D):
	# Visual collapse effect
	create_quantum_collapse_effect()

	## Teleport to the chosen quantum position
	#if chosen_state > 0:
		#global_position += quantum_positions[chosen_state].offset

	# Multiple hit chance based on quantum superposition
	var superposition_hits = 0
	for i in range(quantum_positions.size()):
		if i != chosen_state and quantum_positions[i].visible:
			if randf() < quantum_positions[i].existence_probability * 0.5:
				superposition_hits += 1

	# Apply damage for superposition hits
	if superposition_hits > 0 and enemy.has_method("take_damage"):
		for i in range(superposition_hits):
			# Delayed damage to simulate quantum collapse
			get_tree().create_timer(0.1 * i).timeout.connect(
				func():
					if is_instance_valid(enemy):
						enemy.take_damage(get_scaled_damage() * 0.5)
						create_quantum_hit_effect(enemy.global_position)
			)

	# Clean up quantum visuals
	for visual in quantum_visuals:
		visual.queue_free()
	quantum_visuals.clear()
	quantum_active = false

func create_quantum_collapse_effect():
	# Create a visual effect for the quantum collapse
	for i in range(10):
		var particle = Sprite2D.new()
		particle.texture = sprite.texture
		particle.scale = sprite.scale * 0.3
		particle.modulate = modulate
		particle.modulate.a = 0.6
		particle.position = Vector2.ZERO
		add_child(particle)

		# Animate the particle
		var direction = Vector2.from_angle(randf() * TAU)
		var distance = randf_range(20, 60)
		var duration = randf_range(0.3, 0.5)

		var tween = create_tween()
		tween.parallel().tween_property(particle, "position", direction * distance, duration)
		tween.parallel().tween_property(particle, "modulate:a", 0.0, duration)
		tween.parallel().tween_property(particle, "scale", Vector2.ZERO, duration)
		tween.tween_callback(particle.queue_free)

func create_quantum_hit_effect(hit_position: Vector2):
	# Create a small quantum ripple at hit position
	var effect = Sprite2D.new()
	effect.texture = sprite.texture
	effect.global_position = hit_position
	effect.scale = Vector2.ZERO
	effect.modulate = modulate
	effect.modulate.a = 0.5
	get_tree().current_scene.add_child(effect)

	var tween = create_tween()
	tween.parallel().tween_property(effect, "scale", Vector2.ONE * 2, 0.3)
	tween.parallel().tween_property(effect, "modulate:a", 0.0, 0.3)
	tween.tween_callback(effect.queue_free)

func _physics_process(delta: float) -> void:
		# Update quantum states if active
	if quantum_active and not has_collapsed:
		quantum_collapse_timer += delta
		update_quantum_states(delta)
	global_position += velocity * delta

	if start_position.distance_to(global_position) > max_range:
		queue_free()

func launch(start_pos, direction, sauce: BaseSauceResource):

	global_position = start_pos
	start_position = start_pos
	velocity = direction.normalized() * sauce.projectile_speed
	max_range = sauce.range
	rotation = direction.angle()
	sauce_damage = sauce.damage
	modulate = sauce.sauce_color
	sauce_resource = sauce
	#direction = Vector2.RIGHT.rotated(rotation).normalized()

	if sauce_resource and sauce_resource.special_effect_type == BaseSauceResource.SpecialEffectType.QUANTUM:
		initialize_quantum_states()

func handle_enemy_hit(enemy: Node2D):
	if sauce_resource and sauce_resource.special_effect_type == BaseSauceResource.SpecialEffectType.QUANTUM:
		apply_quantum_effect(enemy)
	# Check for pierce effect
	if sauce_resource and sauce_resource.special_effect_type == BaseSauceResource.SpecialEffectType.PIERCE:
		if enemy in has_pierced:
			return # Already hit this enemy
		has_pierced.append(enemy)

		# Don't destroy projectile, let it continue
		if enemy.has_method("take_damage"):
			enemy.take_damage(get_scaled_damage())
		apply_special_effects(enemy)
		return

	# Normal behavior - destroy projectile and deal damage
	if enemy.has_method("take_damage"):
		enemy.take_damage(get_scaled_damage())

	# Apply special effects before destroying
	apply_special_effects(enemy)

	# Check if we should destroy the projectile
	if not sauce_resource or (sauce_resource.special_effect_type != BaseSauceResource.SpecialEffectType.PIERCE and sauce_resource.special_effect_type != BaseSauceResource.SpecialEffectType.QUANTUM):
		queue_free()

func apply_special_effects(enemy: Node2D):
	if not sauce_resource or sauce_resource.special_effect_type == BaseSauceResource.SpecialEffectType.NONE:
		return

	match sauce_resource.special_effect_type:
		BaseSauceResource.SpecialEffectType.QUANTUM:
			apply_quantum_effect(enemy)
		BaseSauceResource.SpecialEffectType.BURN:
			apply_burn_effect(enemy)
		BaseSauceResource.SpecialEffectType.SLOW:
			apply_slow_effect(enemy)
		BaseSauceResource.SpecialEffectType.STICKY:
			apply_sticky_effect(enemy)
		BaseSauceResource.SpecialEffectType.CHAIN:
			apply_chain_effect(enemy)
		BaseSauceResource.SpecialEffectType.EXPLODE:
			apply_explosion_effect(enemy)
		BaseSauceResource.SpecialEffectType.POISON:
			apply_poison_effect(enemy)
		BaseSauceResource.SpecialEffectType.FREEZE:
			apply_freeze_effect(enemy)
		BaseSauceResource.SpecialEffectType.HEAL:
			apply_heal_effect()
		BaseSauceResource.SpecialEffectType.MULTIPLY:
			apply_multiply_effect(enemy)
		BaseSauceResource.SpecialEffectType.MAGNETIZE:
			apply_magnetize_effect(enemy)
		BaseSauceResource.SpecialEffectType.SHIELD_BREAK:
			apply_shield_break_effect(enemy)
		BaseSauceResource.SpecialEffectType.LEECH:
			apply_leech_effect(enemy)
		BaseSauceResource.SpecialEffectType.LIGHTNING:
			apply_lightning_effect(enemy)
		BaseSauceResource.SpecialEffectType.CHAOS:
			apply_chaos_effect(enemy)
		BaseSauceResource.SpecialEffectType.MARK:
			apply_mark_effect(enemy)

func apply_burn_effect(enemy: Node2D):
	if enemy.has_method("apply_status_effect"):
		enemy.apply_status_effect("burn", sauce_resource.effect_duration, sauce_resource.effect_intensity)
	#create_burn_particles(enemy.global_position)

func apply_slow_effect(enemy: Node2D):
	if enemy.has_method("apply_status_effect"):
		enemy.apply_status_effect("slow", sauce_resource.effect_duration, sauce_resource.effect_intensity)

func apply_sticky_effect(enemy: Node2D):
	if enemy.has_method("apply_status_effect"):
		enemy.apply_status_effect("sticky", sauce_resource.effect_duration, sauce_resource.effect_intensity)

func apply_chain_effect(enemy: Node2D):
	# Check if chain effect triggers based on effect_chance
	if randf() > sauce_resource.effect_chance:
		return  # Chain didn't trigger

	var chain_distance = 60.0  # Distance to search for chain targets
	var max_chains = int(sauce_resource.effect_intensity)  # Max number of chains
	var chains_used = 0

	var nearby_enemies = get_nearby_enemies(enemy, chain_distance)
	for nearby_enemy in nearby_enemies:
		if nearby_enemy != enemy and nearby_enemy not in chain_targets:
			chain_targets.append(nearby_enemy)
			if nearby_enemy.has_method("take_damage"):
				nearby_enemy.take_damage(get_scaled_damage() * 0.6) # Reduced chain damage

			chains_used += 1
			if chains_used >= max_chains:
				break  # Hit the chain limit, stop chaining

			create_chain_visual(enemy.global_position, nearby_enemy.global_position)

func create_chain_visual(start_pos: Vector2, end_pos: Vector2):
	# Create a line between the two positions
	var line = Line2D.new()
	line.add_point(start_pos)
	line.add_point(end_pos)
	line.width = 3.0
	#line.default_color = Color(1.0, 1.0, 0.0, 0.8)  # Yellow lightning color
	line.default_color = sauce_resource.sauce_color
	line.default_color.a = 0.8

	# Add to scene
	get_tree().current_scene.add_child(line)

	# Animate and remove
	var tween = get_tree().create_tween()
	tween.tween_property(line, "modulate:a", 0.0, 0.2)  # Fade out quickly
	tween.tween_callback(line.queue_free)

func apply_explosion_effect(enemy: Node2D):
	var explosion_radius = 15.0 * sauce_resource.effect_intensity
	var nearby_enemies = get_nearby_enemies(enemy, explosion_radius)

	for nearby_enemy in nearby_enemies:
		if nearby_enemy != enemy and nearby_enemy.has_method("take_damage"):
			var distance = enemy.global_position.distance_to(nearby_enemy.global_position)
			var damage_multiplier = 1.0 - (distance / explosion_radius)
			nearby_enemy.take_damage(get_scaled_damage() * damage_multiplier * 0.7)

	create_explosion_visual(enemy.global_position, explosion_radius)

func create_explosion_visual(position: Vector2, radius: float):
	# Create a TextureRect with a circle texture
	var explosion_circle = TextureRect.new()

	# Create a circle texture programmatically
	var image = Image.create(int(radius * 2), int(radius * 2), false, Image.FORMAT_RGBA8)
	var center = Vector2(radius, radius)

	for x in range(int(radius * 2)):
		for y in range(int(radius * 2)):
			var distance = Vector2(x, y).distance_to(center)
			if distance <= radius:
				var alpha = 1.0 - (distance / radius)  # Fade from center
				image.set_pixel(x, y, Color(1.0, 0.5, 0.0, alpha * 0.3))

	var texture = ImageTexture.new()
	texture.set_image(image)
	explosion_circle.texture = texture
	explosion_circle.position = position - Vector2(radius, radius)

	get_tree().current_scene.add_child(explosion_circle)

	var tween = get_tree().create_tween()
	tween.tween_property(explosion_circle, "modulate:a", 0.0, 0.3)
	tween.tween_callback(explosion_circle.queue_free)

func apply_poison_effect(enemy: Node2D):
	if enemy.has_method("apply_status_effect"):
		enemy.apply_status_effect("poison", sauce_resource.effect_duration, sauce_resource.effect_intensity)

func apply_freeze_effect(enemy: Node2D):
	if enemy.has_method("apply_status_effect"):
		enemy.apply_status_effect("freeze", sauce_resource.effect_duration, sauce_resource.effect_intensity)

func apply_heal_effect():
	if PlayerStats.has_method("heal"):
		PlayerStats.heal(sauce_damage * 0.2) # Heal for 20% of damage dealt

func apply_multiply_effect(enemy: Node2D):
	var split_count = int(sauce_resource.effect_intensity)
	for i in range(split_count):
		var split_projectile = duplicate()
		get_tree().current_scene.add_child(split_projectile)

		var angle_offset = (i - split_count/2.0) * 45.0 # Spread projectiles
		var new_direction = Vector2.RIGHT.rotated(rotation + deg_to_rad(angle_offset))

		split_projectile.launch(
			global_position,
			new_direction,
			sauce_damage * 0.5, # Reduced damage for splits
			velocity.length() * 0.8, # Slightly slower
			modulate,
			sauce_resource
		)

func apply_magnetize_effect(enemy: Node2D):
	var nearby_enemies = get_nearby_enemies(enemy, 300.0)
	for nearby_enemy in nearby_enemies:
		if nearby_enemy != enemy and nearby_enemy.has_method("apply_pull_force"):
			nearby_enemy.apply_pull_force(enemy.global_position, sauce_resource.effect_intensity * 500.0)

func apply_shield_break_effect(enemy: Node2D):
	if enemy.has_method("break_shield"):
		enemy.break_shield()

func apply_leech_effect(enemy: Node2D):
	if PlayerStats.has_method("heal"):
		PlayerStats.heal(get_scaled_damage() * 0.15) # Heal for 15% of damage dealt

func apply_lightning_effect(enemy: Node2D):
	var chain_distance = 250.0
	var chain_count = int(sauce_resource.effect_intensity)
	var current_target = enemy

	for i in range(chain_count):
		var next_enemies = get_nearby_enemies(current_target, chain_distance)
		if next_enemies.is_empty():
			break

		var next_target = next_enemies[0]
		if next_target.has_method("take_damage"):
			next_target.take_damage(get_scaled_damage() * 0.5)

		#create_lightning_visual(current_target.global_position, next_target.global_position)
		current_target = next_target

func apply_chaos_effect(enemy: Node2D):
	var chaos_effects = [
		BaseSauceResource.SpecialEffectType.BURN,
		BaseSauceResource.SpecialEffectType.SLOW,
		BaseSauceResource.SpecialEffectType.FREEZE,
		BaseSauceResource.SpecialEffectType.EXPLODE,
		BaseSauceResource.SpecialEffectType.CHAIN,
		BaseSauceResource.SpecialEffectType.POISON
	]

	var original_effect = sauce_resource.special_effect_type
	sauce_resource.special_effect_type = chaos_effects[randi() % chaos_effects.size()]
	apply_special_effects(enemy)
	sauce_resource.special_effect_type = original_effect

func apply_mark_effect(enemy: Node2D):
	if enemy.has_method("apply_mark"):
		enemy.apply_mark(sauce_resource.effect_duration, sauce_resource.effect_intensity)

# Helper functions
func get_nearby_enemies(center_enemy: Node2D, radius: float) -> Array[Node2D]:
	var enemies: Array[Node2D] = []
	var bodies = get_tree().get_nodes_in_group("enemies")

	for body in bodies:
		if body != center_enemy and body.global_position.distance_to(center_enemy.global_position) <= radius:
			enemies.append(body)

	return enemies

func bounce_off_wall(wall: Node2D):
	# Simple bounce logic - reverse velocity components based on wall normal
	var collision_normal = (global_position - wall.global_position).normalized()
	velocity = velocity.bounce(collision_normal)
	rotation = velocity.angle()

func find_and_target_nearest_enemy():
	var nearest_enemy = null
	var nearest_distance = INF

	for body in get_tree().get_nodes_in_group("enemies"):
		var distance = global_position.distance_to(body.global_position)
		if distance < nearest_distance:
			nearest_distance = distance
			nearest_enemy = body

	if nearest_enemy:
		var direction = (nearest_enemy.global_position - global_position).normalized()
		velocity = direction * velocity.length()
		rotation = direction.angle()

func get_scaled_damage():
	var base_scale = 1.0 + (PlayerStats.level - 1)
	var damage_scale = base_scale * 0.1
	return sauce_damage + (sauce_damage * damage_scale)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("enemies"):
		handle_enemy_hit(body)
