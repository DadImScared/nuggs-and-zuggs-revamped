extends Area2D

# Basic projectile properties
var velocity: Vector2
var start_position: Vector2
var max_range: float = 300.0
var sauce_damage: float = 10.0
var sauce_resource: BaseSauceResource
var acceleration: float = 0.0
var projectile_behavior: ProjectileBehavior

# Level and source tracking
var source_bottle_id: String = ""
var sauce_level: int = 1
var source_bottle: ImprovedBaseSauceBottle = null

# Enhanced talent variables
var damage_multiplier: float = 1.0
var is_critical_hit: bool = false
var pierce_damage_bonus: float = 0.0
var pierce_hits: int = 0
var infinite_pierce: bool = false
var on_hit_effects: Array[Dictionary] = []

# Homing behavior
var is_homing: bool = false
var homing_target: Node2D = null
var homing_turn_speed: float = 0.05

# Bouncing behavior
var is_bouncing: bool = false
var max_bounces: int = 0
var bounces_remaining: int = 0
var bounce_range: float = 200.0
var bounced_enemies: Array[Node2D] = []

var effect_chance: float = -1.0
var effect_intensity: float = -1.0

#func _ready():
	#body_entered.connect(_on_body_entered)

func launch(start_pos: Vector2, direction: Vector2, sauce: BaseSauceResource, level: int = 1, bottle_id: String = "", bottle: ImprovedBaseSauceBottle = null):
	global_position = start_pos
	start_position = start_pos
	sauce_level = level
	sauce_resource = sauce
	source_bottle_id = bottle_id
	source_bottle = bottle

	# Use level-modified stats
	velocity = direction.normalized() * sauce.projectile_speed
	max_range = sauce.get_current_range(sauce_level)
	rotation = direction.angle() + deg_to_rad(90)
	sauce_damage = source_bottle.effective_damage
	#sauce_damage = sauce.get_current_damage(sauce_level)
	modulate = sauce.sauce_color

	projectile_behavior = ProjectileBehaviorFactory.create_behavior(sauce_resource)

func add_on_hit_effect(effect_type: String, effect_data: Dictionary):
	"""Add an effect that triggers when this projectile hits an enemy"""
	on_hit_effects.append({"type": effect_type, "data": effect_data})

func make_homing(turn_speed: float = 0.05):
	"""Make this projectile home in on enemies"""
	is_homing = true
	homing_turn_speed = turn_speed
	_find_homing_target()

func setup_bouncing(max_bounces: int, bounce_range: float):
	"""Set up bouncing behavior"""
	is_bouncing = true
	self.max_bounces = max_bounces
	bounces_remaining = max_bounces
	self.bounce_range = bounce_range

func _find_homing_target():
	"""Find the nearest enemy for homing"""
	var enemies = get_tree().get_nodes_in_group("enemies")
	if enemies.size() == 0:
		return

	var nearest = enemies[0]
	var nearest_distance = global_position.distance_to(nearest.global_position)

	for enemy in enemies:
		var distance = global_position.distance_to(enemy.global_position)
		if distance < nearest_distance:
			nearest = enemy
			nearest_distance = distance

	homing_target = nearest

func _process(delta):
	# Original movement code
	velocity += velocity.normalized() * acceleration * delta

	# Add homing behavior
	if is_homing and is_instance_valid(homing_target):
		var direction_to_target = global_position.direction_to(homing_target.global_position)
		velocity = velocity.lerp(direction_to_target * velocity.length(), homing_turn_speed)
		rotation = velocity.angle()

	# Apply movement
	global_position += velocity * delta

	# Check max range
	if global_position.distance_to(start_position) > max_range:
		queue_free()

func _on_body_entered(body):
	if body.is_in_group("enemies"):
		handle_enemy_hit(body)

func handle_enemy_hit(enemy: Node2D):
	"""Enhanced hit handling with talent effects"""
	# Skip if already bounced off this enemy
	if enemy in bounced_enemies:
		return

	# Calculate enhanced damage
	var final_damage = source_bottle.effective_damage * damage_multiplier

	# Add pierce bonus damage
	if pierce_hits > 0 and pierce_damage_bonus > 0:
		final_damage += final_damage * (pierce_damage_bonus * pierce_hits)
		print("Pierce bonus: +%.0f%% (hit #%d)" % [pierce_damage_bonus * pierce_hits * 100, pierce_hits + 1])

	# Deal damage
	if enemy.has_method("take_damage_from_source"):
		enemy.take_damage_from_source(final_damage, source_bottle_id)
	elif enemy.has_method("take_damage"):
		enemy.take_damage(final_damage, source_bottle_id)

	# Trigger system integration
	if source_bottle:
		TriggerActionManager.execute_hit_trigger(source_bottle, enemy, self)

	# Apply on-hit effects (talents)
	_apply_on_hit_effects(enemy)

	# Visual effects
	if is_critical_hit:
		_create_crit_effect(enemy.global_position)

	# Handle bouncing
	if is_bouncing and bounces_remaining > 0:
		bounced_enemies.append(enemy)
		_attempt_bounce(enemy)
		return  # Don't destroy yet if bouncing

	# Handle pierce logic
	if sauce_resource.pierce_count > 0 or infinite_pierce:
		pierce_hits += 1

		if not infinite_pierce:
			sauce_resource.pierce_count -= 1

		# Only destroy if no more pierces and not bouncing
		if sauce_resource.pierce_count <= 0 and not infinite_pierce:
			_finalize_projectile(enemy)
	else:
		# Normal projectile destruction
		_finalize_projectile(enemy)

func _finalize_projectile(enemy: Node2D):
	"""Apply final effects and destroy projectile"""
	# Apply sauce effects on final hit
	SauceEffectManager.apply_effect(
		self, enemy, sauce_resource,
		sauce_level, source_bottle_id, effect_chance,
		effect_intensity, source_bottle
		)

	var should_destroy = projectile_behavior.handle_hit(self, enemy)
	if should_destroy:
		queue_free()

func _attempt_bounce(hit_enemy: Node2D):
	"""Try to bounce to another nearby enemy"""
	var nearby_enemies = get_tree().get_nodes_in_group("enemies")
	var valid_targets: Array[Node2D] = []

	# Find enemies within bounce range that we haven't hit
	for enemy in nearby_enemies:
		if enemy != hit_enemy and enemy not in bounced_enemies:
			var distance = hit_enemy.global_position.distance_to(enemy.global_position)
			if distance <= bounce_range:
				valid_targets.append(enemy)

	if valid_targets.size() > 0:
		# Bounce to nearest valid target
		var target = valid_targets[0]
		var nearest_distance = hit_enemy.global_position.distance_to(target.global_position)

		for enemy in valid_targets:
			var distance = hit_enemy.global_position.distance_to(enemy.global_position)
			if distance < nearest_distance:
				target = enemy
				nearest_distance = distance

		# Redirect projectile
		var direction_to_target = global_position.direction_to(target.global_position)
		velocity = direction_to_target * velocity.length()
		rotation = velocity.angle()

		bounces_remaining -= 1
		print("Bounced! %d bounces remaining" % bounces_remaining)

		# Visual effect for bounce
		_create_bounce_effect(global_position)
	else:
		# No valid targets, stop bouncing
		bounces_remaining = 0
		is_bouncing = false
		_finalize_projectile(hit_enemy)

func _apply_on_hit_effects(enemy: Node2D):
	"""Apply all on-hit effects to the enemy"""
	for effect in on_hit_effects:
		var effect_type = effect.type
		var effect_data = effect.data

		match effect_type:
			"slow":
				if enemy.has_method("apply_slow"):
					enemy.apply_slow(effect_data.strength, effect_data.duration)
			"vulnerability":
				if enemy.has_method("apply_vulnerability"):
					enemy.apply_vulnerability(effect_data.bonus, effect_data.duration)
			"create_puddle":
				TalentEffectManager.create_damage_puddle(
					enemy.global_position,
					effect_data.damage,
					effect_data.duration
				)
			"enhanced_puddle":
				var eternal = effect_data.get("eternal", false)
				TalentEffectManager.create_damage_puddle(
					enemy.global_position,
					effect_data.get("damage", sauce_damage * 0.5),
					effect_data.get("duration", 5.0),
					eternal
				)
			"poison_cloud":
				TalentEffectManager.create_poison_cloud(
					enemy.global_position,
					effect_data.damage,
					effect_data.get("radius", 100.0)
				)
			"explosion":
				_create_explosion_effect(enemy.global_position, effect_data)

func _create_explosion_effect(position: Vector2, effect_data: Dictionary):
	"""Create explosion effect from talent"""
	var radius = effect_data.get("radius", 100.0)
	var damage = sauce_damage * effect_data.get("damage_multiplier", 1.5)

	# Visual explosion
	var explosion = ColorRect.new()
	explosion.size = Vector2(radius * 2, radius * 2)
	explosion.color = Color.ORANGE
	explosion.global_position = position - explosion.size/2
	get_tree().current_scene.add_child(explosion)

	var tween = create_tween()
	tween.tween_property(explosion, "scale", Vector2(2, 2), 0.3)
	tween.parallel().tween_property(explosion, "modulate:a", 0.0, 0.3)
	tween.tween_callback(explosion.queue_free)

	# Damage nearby enemies
	var enemies = get_tree().get_nodes_in_group("enemies")
	for enemy in enemies:
		var distance = position.distance_to(enemy.global_position)
		if distance <= radius:
			var damage_multiplier_falloff = 1.0 - (distance / radius)  # Falloff
			var final_damage = damage * damage_multiplier_falloff

			if enemy.has_method("take_damage_from_source"):
				enemy.take_damage_from_source(final_damage, source_bottle_id)
			elif enemy.has_method("take_damage"):
				enemy.take_damage(final_damage)

func _create_crit_effect(position: Vector2):
	"""Enhanced critical hit visual effect"""
	var crit_label = Label.new()
	crit_label.text = "CRIT!"
	crit_label.add_theme_color_override("font_color", Color.YELLOW)
	crit_label.add_theme_font_size_override("font_size", 32)
	crit_label.global_position = position
	get_tree().current_scene.add_child(crit_label)

	# Enhanced crit animation
	var tween = create_tween()
	tween.tween_property(crit_label, "global_position", position + Vector2(0, -100), 2.0)
	tween.parallel().tween_property(crit_label, "scale", Vector2(2.5, 2.5), 0.5)
	tween.parallel().tween_property(crit_label, "modulate:a", 0.0, 2.0)
	tween.tween_callback(crit_label.queue_free)

	# Crit particles
	_create_crit_particles(position)

func _create_crit_particles(position: Vector2):
	"""Create particle effect for critical hits"""
	for i in range(8):
		var particle = ColorRect.new()
		particle.size = Vector2(8, 8)
		particle.color = Color.YELLOW
		particle.global_position = position
		get_tree().current_scene.add_child(particle)

		var direction = Vector2.RIGHT.rotated(i * TAU / 8)
		var distance = randf_range(30, 80)

		var tween = create_tween()
		tween.tween_property(particle, "global_position", position + direction * distance, 1.0)
		tween.parallel().tween_property(particle, "modulate:a", 0.0, 1.0)
		tween.tween_callback(particle.queue_free)

func _create_bounce_effect(position: Vector2):
	"""Visual effect for projectile bouncing"""
	var bounce_effect = ColorRect.new()
	bounce_effect.size = Vector2(20, 20)
	bounce_effect.color = Color.CYAN
	bounce_effect.global_position = position - bounce_effect.size/2
	get_tree().current_scene.add_child(bounce_effect)

	var tween = create_tween()
	tween.tween_property(bounce_effect, "scale", Vector2(3, 3), 0.3)
	tween.parallel().tween_property(bounce_effect, "modulate:a", 0.0, 0.3)
	tween.tween_callback(bounce_effect.queue_free)

# Override get_scaled_damage to include all multipliers
func get_scaled_damage() -> float:
	return sauce_damage * damage_multiplier
	var base_scale = 1.0 + (PlayerStats.level - 1)
	var damage_scale = base_scale * 0.1
	var leveled_damage = sauce_resource.get_current_damage(sauce_level)

	# Apply all damage multipliers
	var final_damage = (leveled_damage + (leveled_damage * damage_scale)) * damage_multiplier

	return final_damage

# Debug function
func debug_print_projectile_info():
	print("=== Projectile Debug ===")
	print("Damage Multiplier: %.2f" % damage_multiplier)
	print("Is Critical: %s" % is_critical_hit)
	print("Pierce Hits: %d (bonus: %.1f%%)" % [pierce_hits, pierce_damage_bonus * 100])
	print("Infinite Pierce: %s" % infinite_pierce)
	print("Is Homing: %s" % is_homing)
	print("Is Bouncing: %s (remaining: %d)" % [is_bouncing, bounces_remaining])
	print("On-Hit Effects: %d" % on_hit_effects.size())
	for effect in on_hit_effects:
		print("  - %s" % effect.type)
	print("=======================")

# Cleanup when projectile is destroyed
func _exit_tree():
	# Clean up any references
	if homing_target:
		homing_target = null
	bounced_enemies.clear()
	on_hit_effects.clear()
